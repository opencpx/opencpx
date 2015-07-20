package VSAP::Server::Modules::vsap::files::compress;

use 5.008004;
use strict;
use warnings;
use Cwd qw(cwd abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path diskspace_availability);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::user::messages;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 CANT_OPEN_PATH     => 102,
                 COMPRESS_FAILED    => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_FILE       => 106,
                 INVALID_TARGET     => 107,
                 INVALID_NAME       => 108,
                 INVALID_TYPE       => 109,
                 REQUEST_QUEUED     => 250,
               );

# path to the zip/tar executables....  (LINUX)          (FreeBSD)
our $ZIP_PATH = (-e "/usr/bin/zip") ? "/usr/bin/zip" : "/usr/local/bin/zip";
our $TAR_PATH = (-e "/bin/tar")     ? "/bin/tar"     : "/usr/bin/tar";

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get source directory where files are homed
    my $source = $xmlobj->child('source') ? $xmlobj->child('source')->value : '';
    my $sourceuser = ($xmlobj->child('source_user') && $xmlobj->child('source_user')->value) ?
                      $xmlobj->child('source_user')->value : $vsap->{username};

    # get all non-empty file paths to add to archive
    my @paths = ($xmlobj->children('path') ?
                 grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('path') : () );

    # get target directory
    my $targetdir = $xmlobj->child('target') ?
                    $xmlobj->child('target')->value : '';
    my $targetuser = $xmlobj->child('target_user') ?
                     $xmlobj->child('target_user')->value : $vsap->{username};

    # get the filename
    my $filename = $xmlobj->child('target_name') ?
                   $xmlobj->child('target_name')->value : '';

    # get the archive_type
    my $archive_type = $xmlobj->child('type') ?
                       $xmlobj->child('type')->value : '';

    # get remove source option
    my $remove_sources = $xmlobj->child('remove_sources') ?
                         $xmlobj->child('remove_sources')->value : '';

    unless ($source) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source directory required");
        return;
    }

    if ($#paths == -1) {
        $vsap->error($_ERR{'INVALID_FILE'} => "source files required");
        return;
    }

    unless ($targetdir) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    $filename =~ s/\.(tar|taz|tbz|tbz2|tgz|zip)$//i;
    unless ($filename) {
        $vsap->error($_ERR{'INVALID_NAME'} => "compressed file name required");
        return;
    }

    unless ($archive_type) {
        $vsap->error($_ERR{'INVALID_TYPE'} => "compressed file type required");
        return;
    }

    if ($archive_type !~ /^(tar|taz|tbz|tbz2|tgz|zip)$/i) {
        # unknown or unsupported format
        $vsap->error($_ERR{'INVALID_TYPE'} => "unsupported/invalid archive type");
        return;
    }

    # fix up the path
    $source = "/" . $source unless ($source =~ m{^/});  # prepend with /
    $source = canonpath($source);

    # the goal is to build to targetdir/filename.archive_type
    $filename .= "." . $archive_type;
    my $target = canonpath(catfile($targetdir, $filename));

    # get config object and site prefs
    my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
    my $siteprefs = $co->siteprefs;
    my $lfm = ($siteprefs->{'limited-file-manager'}) ? 1 : 0;  ## chroot file manager for server admin

    # get list of valid paths for user
    my $validuser;
    my @ulist = ();
    if ($vsap->{server_admin}) {
        # add all non-system users to user list (including self)
        @ulist = keys %{$co->users()};
        # add apache run user
        push(@ulist, $VSAP::Server::Modules::vsap::globals::APACHE_RUN_USER);
    }
    else {
        # add any endusers to list
        @ulist = keys %{$co->users(admin => $vsap->{username})};
        # add self to list
        push(@ulist, $vsap->{username});
    }
    my %valid_paths = ();
    foreach $validuser (@ulist) {
        $valid_paths{$validuser} = abs_path((getpwnam($validuser))[7]);
    }

    # build full source path
    my $fullsource = $source;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$sourceuser})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown source user: $sourceuser");
            return;
        }
        $fullsource = canonpath(catfile($valid_paths{$sourceuser}, $source));
    }
    if (-l "$fullsource") {
        # we don't want to abs_path a link
        my($linkname, $linkpath) = fileparse($fullsource);
        $linkpath = abs_path($linkpath) || sanitize_path($linkpath);
        $fullsource = canonpath(catfile($linkpath, $linkname));
    }
    else {
        $fullsource = decode_utf8(abs_path($fullsource)) || sanitize_path($fullsource);
    }

    # check authorization to access source path
    my $authorized = 0;
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if (($fullsource =~ m#^\Q$valid_path\E/# ) ||
            ($fullsource eq $valid_path) || ($valid_path eq "/")) {
            $authorized = 1;
            last;
        }
    }
    unless ($vsap->{server_admin} || $authorized) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fullsource");
        return;
    }

    # step through file paths and make them relative to source directory
    my ($index);
    for ($index=0; $index<=$#paths; $index++) {
        $paths[$index] =~ s#^\Q$source\E(/|$)##;
        $paths[$index] = "." if ($paths[$index] eq "");
    }

    # check all source file paths
    my $source_total_size = 0;
    my ($file, $fullpath, $source_euid, $source_egid, $size, %source_paths);
    foreach $file (@paths) {
        # build full source path
        $fullpath = canonpath(catfile($fullsource, $file));
        if (-l "$fullpath") {
            # we don't want to abs_path a link
            my($linkname, $linkpath) = fileparse($fullpath);
            $linkpath = abs_path($linkpath) || sanitize_path($linkpath);
            $fullpath = canonpath(catfile($linkpath, $linkname));
        }
        else {
            $fullpath = decode_utf8(abs_path($fullpath)) || sanitize_path($fullpath);
        }
        # check authorization to access source path
        my $authorized = 0;
        my $parentuser = "";
        foreach $validuser (keys(%valid_paths)) {
            my $valid_path = $valid_paths{$validuser};
            if (($fullpath =~ m#^\Q$valid_path\E/# ) ||
                ($fullpath eq $valid_path) || ($valid_path eq "/")) {
                $parentuser = $validuser;
                $authorized = 1;
                last;
            }
        }
        unless ($vsap->{server_admin} || $authorized) {
            $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fullpath");
            return;
        }
        # does the source exist?
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            if (-e $fullpath || -l $fullpath) {
                ($size) = (lstat($fullpath))[7];
                if ($vsap->{server_admin}) {
                    $source_euid = 0;  # give plenty of rope
                    $source_egid = 0;
                }
                else {
                    # set effective uid/gid to default values
                    if ($parentuser) {
                        ($source_euid, $source_egid) = (getpwnam($parentuser))[2,3];
                    }
                    else {
                        $source_euid = $vsap->{uid};
                        $source_egid = $vsap->{gid};
                    }
                    # vsap user can only manipulate files owned by self or by
                    # subusers, even if the file is in a valid file space
                    my ($owner_uid, $owner_gid) = (lstat($fullpath))[4,5];
                    my ($owner_username) = getpwuid($owner_uid);
                    if (exists($valid_paths{$owner_username})) {
                        $source_euid = $owner_uid;
                        $source_egid = $owner_gid;
                    }
                }
            }
            else {
                $vsap->error($_ERR{'CANT_OPEN_PATH'} => "can't open path: $fullpath");
                return;
            }
        }
        $source_paths{$file}->{'fullpath'} = $fullpath;
        $source_paths{$file}->{'euid'} = $source_euid;
        $source_paths{$file}->{'egid'} = $source_egid;
        $source_paths{$file}->{'size'} = $size;
        $source_total_size += $size;
    }

    # build full target path
    my $fulltarget = $target;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$targetuser})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown target user: $targetuser");
            return;
        }
        $fulltarget = canonpath(catfile($valid_paths{$targetuser}, $target));
    }
    if (-l "$fulltarget") {
        # we don't want to abs_path a link
        my($linkname, $linkpath) = fileparse($fulltarget);
        $linkpath = abs_path($linkpath) || sanitize_path($linkpath);
        $fulltarget = canonpath(catfile($linkpath, $linkname));
    }
    else {
        $fulltarget = decode_utf8(abs_path($fulltarget)) || sanitize_path($fulltarget);
    }

    # check authorization to access target path
    $authorized = 0;
    my $parentuser = "";
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if (($fulltarget =~ m#^\Q$valid_path\E/# ) ||
            ($fulltarget eq $valid_path) || ($valid_path eq "/")) {
            $parentuser = $validuser;
            $authorized = 1;
            last;
        }
    }
    unless ($vsap->{server_admin} || $authorized) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fulltarget");
        return;
    }

    # figure out who is going to own the target
    my ($target_euid, $target_egid);
    if ($vsap->{server_admin}) {
        # set to be the uid of the parent directory
        my $parentpath = $fulltarget;
        $parentpath =~ s/[^\/]+$//g;
        $parentpath =~ s/\/+$//g;
        $parentpath = '/' unless ($parentpath);
        while (!(-e $parentpath) && ($parentpath ne "")) {
            $parentpath =~ s/[^\/]+$//g;
            $parentpath =~ s/\/+$//g;
            $parentpath = '/' unless ($parentpath);
        }
        ($target_euid, $target_egid) = (lstat($parentpath))[4,5];
    }
    else {
        if ($parentuser) {
            ($target_euid, $target_egid) = (getpwnam($parentuser))[2,3];
        }
        else {
            $target_euid = $vsap->{uid};
            $target_egid = $vsap->{gid};
        }
    }

    # check quota and fail if no room
    unless(diskspace_availability($target_euid, $target_egid))
    {
            $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error creating compressed file: quota exceeded");
            return;
    }

    # make sure parent of target exists before attempting to build archive
    my ($ftname, $ftpath);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        ($ftname, $ftpath) = fileparse($fulltarget);
        $ftpath =~ s/\/+$//g;
        $ftpath = '/' unless ($ftpath);
        unless (-e $ftpath) {
            system('mkdir', '-p', '--', $ftpath)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'COMPRESS_FAILED'} => "cannot mkdir '$ftpath' (exitcode $exit)");
                  return;
              };
        }
    }

    # figure out who is going to execute the commands (effective_uid)
    my ($effective_uid, $effective_gid);
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $effective_uid = 0;
        $effective_gid = 0;
    }
    else {
        $effective_uid = $target_euid;  # default
        $effective_gid = $target_egid;  # default
        foreach $file (@paths) {
            $source_euid = $source_paths{$file}->{'euid'};
            $source_egid = $source_paths{$file}->{'egid'};
            if (($source_euid != $target_euid) ||
                ($source_egid != $target_egid)) {
                # need to be super user
                $effective_uid = $effective_gid = 0;
                last;
            }
        }
    }

    # build archive command
    my (@command);
    if ($archive_type =~ /^zip$/i) {
        push(@command, $ZIP_PATH);
        push(@command, '-UN=u');  ## force zip to store UTF-8 as native
        push(@command, '-r');
        push(@command, '-q');
        push(@command, '-y');
        push(@command, $fulltarget);
        my @safe_paths = map { './' . $_ } @paths;
        for ($index=0; $index<=$#safe_paths; $index++) {
            $safe_paths[$index] = canonpath($safe_paths[$index]);
        }
        push(@command, @safe_paths);
    }
    elsif ($archive_type =~ /^(tar|taz|tbz|tbz2|tgz)$/i) {
        push(@command, $TAR_PATH);
        push(@command, '-c');
        if ($archive_type =~ /^taz$/i) {
            push(@command, '-Z');
        }
        elsif ($archive_type =~ /^(tbz|tbz2)$/i) {
            push(@command, '-j');
        }
        elsif ($archive_type =~ /^tgz$/i) {
            push(@command, '-z');
        }
        push(@command, '-f');
        push(@command, $fulltarget);
        push(@command, '--');
        my @safe_paths = map { './' . $_ } @paths;
        for ($index=0; $index<=$#safe_paths; $index++) {
            $safe_paths[$index] = canonpath($safe_paths[$index]);
        }
        push(@command, @safe_paths);
    }

    my $error_status = 0;   ## 0 = happy ... !0 = !happy

    # fork here to compress the file(s)... wait for child if the size of the
    # source files seems too large (>200MB), otherwise queue message (BUG21365)
    my $size_threshold = 200 * 1024 * 1024;
  FORK: {
        my $pid;
        if ($pid = fork) {
            # parent
            if ($source_total_size > $size_threshold ) {
                VSAP::Server::Modules::vsap::user::messages::_queue_add($vsap->{username}, $pid, $$, "FILE_COMPRESS",
                                                                        ( 'target_filename' => $target ,
                                                                          'source_size' => $source_total_size ) );
                $vsap->error( $_ERR{REQUEST_QUEUED} => "request to compress file queued." );
                $error_status = 250;
                # child is not waited for
            }
            else {
                waitpid($pid, 0);  # the parent waits for the child to finish
            }
        }
        elsif (defined $pid) {
            # child
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                # cross your fingers, build archive, and hope for the best
                my $oldpath = cwd();
                chdir($fullsource) || warn("can't chdir to $fullsource: $!");
                my $command = join(" ", @command);
                system(@command)
                  and do {
                      my $exit = ($? >> 8);
                      if ($exit) {
                          chdir($oldpath);
                          $vsap->error($_ERR{'COMPRESS_FAILED'} => "cannot build '$fullpath' (exitcode $exit)");
                          if ($source_total_size > $size_threshold ) {
                              VSAP::Server::Modules::vsap::user::messages::_queue_update($vsap->{username}, $$,
                                                                                         ( 'fail' => 'yes', 'exitcode' => $exit ) );
                          }
                          $error_status = 103;
                      }
                  };
                # chown compressed file
                chown($target_euid, $target_egid, $fulltarget) ||
                    warn("chown() failed on $fulltarget: $!");
                chdir($oldpath);
                # remove sources (if necessary)
                if ($remove_sources) {
                    foreach $file (keys(%source_paths)) {
                        if ((-d $source_paths{$file}->{'fullpath'}) && (!(-l $source_paths{$file}->{'fullpath'}))) {
                            system('rm', '-rf', $source_paths{$file}->{'fullpath'})
                              and do {
                                  my $exit = ($? >> 8);
                                  warn("remove command (rm -rf $source_paths{$file}->{'fullpath'}) failed: $!") if ($exit);
                              };
                        }
                        else {
                            unlink($source_paths{$file}->{'fullpath'});
                        }
                    }
                }
            }
            if ($source_total_size > $size_threshold ) {
                VSAP::Server::Modules::vsap::user::messages::_job_complete($vsap->{username}, $$);
            }
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} created archive '$fullpath'");
            exit;  # child dies
        }
        else {
            # fork failure
            sleep(5);
            redo FORK;
        }
    }

    return if ( $error_status != 0 );

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:compress');
    $root_node->appendTextChild(target => $target);
    $root_node->appendTextChild(target_user => $targetuser);
    $root_node->appendTextChild(status => "ok");

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::compress - VSAP module to compress one or
more files

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::compress;

=head1 DESCRIPTION

The VSAP compress module allows users to compress one or more files into a
compact archive.

To create a compressed archive, you need to specify a source directory,
an optional source user name, a list of paths to files in the source
directory heirarchy (specified using path names relative to the source
directory), a target directory path name, an optional target user name,
and the target archive's filename and type.

The following template represents the generic form of a query to create
a compressed file archive:

  <vsap type="files:compress">
    <source>source directory path name</source>
    <source_user>user name</source_user>
    <path>file name</path>
    <path>file name</path>
    <path>file name</path>
    <path>file name</path>
    <path>file name</path>
    <target>target archive directory path name</target>
    <target_user>target archive directory user name</target_user>
    <target_name>target archive file name</target_name>
    <type>target archive file type</type>
  </vsap>

System Administrators should use the full path name to the source
directory and need not ever include the optional source user name.
Domain Administrators should use the "virtual path name" for the source
directory, i.e. the path name without prepending the home directory
where the file resides.  If the file is homed in a one of the Domain
Administrator's End Users' file spaces, then the '<source_user>' node
should be used.  End Users will also need to use a "virtual path name"
to a file; no '<source_user>' specification is required, as the
authenticated user name is presumed.

All of the file names that will be included in the archive should be
specified using a '<path>' node.  Only files that are part of the
source directory file heirarchy may be included in the list of files.
You must specify the path relative to the source directory.

The target directory is the directory where the new archive will be
built.  System Administrators should use the full path name to the
target directory and need not ever include the optional target user
name.  Domain Administrators should use the "virtual path name" for the
target directory and the '<target_user>' node if required (per the same
methodology of the source directory specification).  End Users will also
need to use a "virtual path name" to a file; no '<target_user>'
specification is required, as the authenticated user name is presumed.

The target name is the file name of the new archive that will be
created.  A file name extension (e.g. '.zip') can be specified but it is
optional; as an appropriate file name extension will be appended to the
file name depending on the archive type.

The archive type can be any one of the following:

	tar
		A "tar" archive.

	taz
		A compressed "tar" archive using adaptive
		Lempel-Ziv coding.

	tbz
	tbz2
		A compressed "tar" archive using the
		Burrows-Wheeler block sorting text
		compression algorithm and Huffman coding.

	tgz
		A compressed "tar" archive using Lempel-Ziv
		coding (LZ77).

	zip
		A "zip" archive.

Consider the following examples:

=over 2

A request made by a System Administrator to archive some system files:

    <vsap type="files:compress">
      <source>/var/log</source>
      <path>maillog</path>
      <path>messages</path>
      <path>wtmp</path>
      <target>/root</target>
      <target_name>logs</target_name>
      <type>tar</type>
    </vsap>

A request made by a Domain Administrator or End User to archive files
homed in their own home directory.

    <vsap type="files:compress">
      <source>/mystuff/photos</source>
      <path>my_cats.jpg</path>
      <path>my_dogs.jpg</path>
      <path>my_gerbils.jpg</path>
      <target>/archives</target>
      <target_name>my_stuff</target_name>
      <type>zip</type>
    </vsap>

A request made by a Domain Administrator to archive files homed in the
directory space of an End User.

    <vsap type="files:compress">
      <source_user>scott</source_user>
      <source>/www/data</source>
      <path>ode_to_tabasco.html</path>
      <path>my_life_as_a_tabasco_pepper.html</path>
      <path>tabasco_bottle.jpg</path>
      <target_user>scott</target_user>
      <target>/disaster_recovery/tabasco</target>
      <target_name>content</target_name>
      <type>tgz</type>
    </vsap>

=back

If the source directory and the source files are valid, and the target
directory is accessible (see NOTES), the new archive will be created or
an error will be returned.  A successful request will be indicated by
the return '<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to
the file system, therefore the validity of the path name is only
determined whether it exists or not.  However, End Users are restricted
access (or 'jailed') to their own home directory tree.  Domain
Administrators are likewise restricted, but to the home directory trees
of themselves and their end users.  Any attempts at access to files that
are located outside of these valid directories will be denied and an
error will be returned.

=head1 SEE ALSO

bzip2(1), compress(1), tar(1), zip(1L)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

