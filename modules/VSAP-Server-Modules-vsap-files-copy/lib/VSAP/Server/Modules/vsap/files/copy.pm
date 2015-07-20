package VSAP::Server::Modules::vsap::files::copy;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path diskspace_availability);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 CANT_OPEN_PATH     => 102,
                 COPY_FAILED        => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_NAME       => 106,
                 INVALID_TARGET     => 107,
                 TARGET_EXISTS      => 108,
                 COPY_LOOP          => 109,
                 MKDIR_FAILED       => 110,
               );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get all non-empty source paths
    my @sources = ($xmlobj->children('source') ?
                   grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('source') : () );
    my $sourceuser = ($xmlobj->child('source_user') && $xmlobj->child('source_user')->value) ?
                      $xmlobj->child('source_user')->value : $vsap->{username};

    # get target directory (multiple source) or target path (single source)
    my $target = $xmlobj->child('target') ?
                 $xmlobj->child('target')->value : '';
    my $targetuser = ($xmlobj->child('target_user') && $xmlobj->child('target_user')->value) ?
                      $xmlobj->child('target_user')->value : $vsap->{username};
    my $targetname = $xmlobj->child('target_name') ?
                     $xmlobj->child('target_name')->value : '';

    if ($#sources == -1) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source paths required");
        return;
    }

    unless ($target) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    # target name is only valid if copying a single source
    if (($#sources > 0) && ($targetname)) {
        $vsap->error($_ERR{'INVALID_NAME'} => "target name only valid if copying one source");
        return;
    }

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

    # check all paths
    my ($path, $fullpath, $source_euid, $source_egid, %source_paths);
    for $path (@sources) {
        # fix up the path
        $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
        $path = canonpath($path);
        # build full source path
        $fullpath = $path;
        if (!$vsap->{server_admin} || $lfm) {
            # rebuild chroot'd paths
            unless (defined($valid_paths{$sourceuser})) {
                $vsap->error($_ERR{'INVALID_USER'} => "unknown source user: $sourceuser");
                return;
            }
            $fullpath = canonpath(catfile($valid_paths{$sourceuser}, $path));
        }
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
            if ($fullpath eq $valid_path) {
                # can't delete home directories
                $vsap->error($_ERR{'INVALID_PATH'} => "invalid path: $path");
                return;
            }
            if (($fullpath =~ m#^\Q$valid_path\E/# ) || ($valid_path eq "/")) {
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
                if ($vsap->{server_admin}) {
                    # give plenty of rope
                    $source_euid = 0;
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
        $source_paths{$path}->{'fullpath'} = $fullpath;
        $source_paths{$path}->{'euid'} = $source_euid;
        $source_paths{$path}->{'egid'} = $source_egid;
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
    if ($targetname) {
        # append user-specified target name to fulltarget
        $fulltarget = canonpath(catfile($fulltarget, $targetname));
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
    my $authorized = 0;
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

    # do a quota check and fail if there isn't enough room
    my ($new_disk_space_requirements) = 0;
    for $path (keys(%source_paths)) {
        # this will become chown'd to the owner of the target directory
        my ($size) = (lstat($source_paths{$path}->{'fullpath'}))[7];
        $new_disk_space_requirements += $size;
    }
    # get quota/usage for owner of the target directory
    unless(diskspace_availability($target_euid, $target_egid, $new_disk_space_requirements))
    {
            $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error copying file: quota exceeded");
            return;
    }

    # if the target doesn't exist; we need to create it before we attempt
    # to copy anything into it.
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        my ($ftname, $ftpath);
        if ($targetname) {
            ($ftname, $ftpath) = fileparse($fulltarget);
        }
        else {
            $ftpath = $fulltarget;
        }
        if (-e $ftpath) {
            # if fulltargetpath exists; it must be a directory
            unless (-d $ftpath) {
                $vsap->error($_ERR{'TARGET_EXISTS'} => "target exists: $ftpath");
                return;
            }
        }
        else {
            # target directory does not exist; create it
            system('mkdir', '-p', '--', $ftpath)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'MKDIR_FAILED'} => "cannot mkdir '$ftpath' (exitcode $exit)");
                  return;
              };
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:copy');

    # copy all paths to target directory
    my $success_node = "";
    my $failure_node = "";
    my ($path_node, $mesg);
    my ($effective_uid, $effective_gid);
    for $path (keys(%source_paths)) {
        $fullpath = $source_paths{$path}->{'fullpath'};
        $source_euid = $source_paths{$path}->{'euid'};
        $source_egid = $source_paths{$path}->{'egid'};
        # figure out who is going to execute the command for this path
        if ($vsap->{server_admin}) {
            # give plenty of rope
            $effective_uid = 0;
            $effective_gid = 0;
        }
        else {
            $effective_uid = $target_euid;  # default
            $effective_gid = $target_egid;  # default
            if (($source_euid != $target_euid) || ($source_egid != $target_egid)) {
                # need to be super user
                $effective_uid = $effective_gid = 0;
            }
        }
      EFFECTIVE: {
            local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
            local $) = $effective_gid;
            local $> = $effective_uid;
            # check to see if the target filename exists
            my $fulltargetpath = "";
            if ($targetname) {
                # we appended targetname above when building fulltarget
                $fulltargetpath = $fulltarget;
            }
            else {
                my ($sourcename) = (fileparse($fullpath))[0];
                $fulltargetpath = canonpath(catfile($fulltarget, $sourcename));
            }
            if (-e $fulltargetpath) {
                if ($targetname) {
                    # if copying single source to single target, target must not exist
                    $vsap->error($_ERR{'TARGET_EXISTS'} => "target exists: $fulltargetpath");
                    return;
                }
                else {
                    # build a fulltargetpath that is unique using the "_copy" designation
                    my $index = 1;
                    while (-e $fulltargetpath) {
                        my ($ftname, $ftpath, $ftsuffix) = fileparse($fulltargetpath, '\..*');
                        if ($index == 1) {
                            $ftname = $ftname . "_copy";
                        }
                        else {
                            $ftname =~ s/_[0-9]+$//;
                            $ftname =~ s/_copy$//g;
                            $ftname .= "_copy_$index";
                        }
                        $ftname .= $ftsuffix if ($ftsuffix);
                        $fulltargetpath = catfile($ftpath, $ftname);
                        $index++;
                    }
                }
            }
            # now that we fulltargetpath, build virtualtargetpath
            my $vtp = $fulltargetpath;
            if (!$vsap->{server_admin} || $lfm) {
                $vtp =~ s#^\Q$valid_paths{$targetuser}\E(/|$)#/#;
            }
            # check for a recursive copy loop
            if ($fulltargetpath =~ m#^\Q$fullpath\E(/|$)#) {
                unless ($failure_node) {
                    $failure_node = $root_node->appendChild($dom->createElement('failure'));
                }
                $path_node = $failure_node->appendChild($dom->createElement('path'));
                $path_node->appendTextChild(source => $path);
                $path_node->appendTextChild(target => $vtp);
                $path_node->appendTextChild(code => $_ERR{'COPY_LOOP'});
                $path_node->appendTextChild(mesg => "Error: copy loop detected");
                next;
            }
            # cross your fingers, copy, and hope for the best
            system('cp', '-Rpf', '--', $fullpath, $fulltargetpath)
              and do {
                  my $exit = ($? >> 8);
                  $mesg = "copy '$path' to '$target' failed (exitcode $exit)";
                  warn($mesg);
                  VSAP::Server::Modules::vsap::logger::log_error($mesg);
                  unless ($failure_node) {
                      $failure_node = $root_node->appendChild($dom->createElement('failure'));
                  }
                  $path_node = $failure_node->appendChild($dom->createElement('path'));
                  $path_node->appendTextChild(source => $path);
                  $path_node->appendTextChild(target => $vtp);
                  $path_node->appendTextChild(code => $_ERR{'COPY_FAILED'});
                  $path_node->appendTextChild(mesg => $mesg);
                  next;
              };
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} copied '$fullpath' to '$fulltargetpath'");
            # chown to the target path's owner
            chown($target_euid, $target_egid, $fulltargetpath) ||
                warn("chown failed for $fulltargetpath: $!");
            # add path to success node
            unless ($success_node) {
                $success_node = $root_node->appendChild($dom->createElement('success'));
            }
            $path_node = $success_node->appendChild($dom->createElement('path'));
            $path_node->appendTextChild(source => $path);
            $path_node->appendTextChild(target => $vtp);
        }
    }

    # add users to dom
    $root_node->appendTextChild(source_user => $sourceuser);
    $root_node->appendTextChild(target_user => $targetuser);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::copy - VSAP module to copy one or
more files to a new location

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::copy;

=head1 DESCRIPTION

The VSAP copy module allows users to copy one or more source files to a
new target destination.

To copy source files to a new destination, you need to specify a list of
one or more source directories or files, an optional source user name, a
target directory path name, an optional target user name, and an
optional target file name.

The following template represents the generic form of a request to copy
files:

  <vsap type="files:copy">
    <source>path name for source directory or file</source>
    <source>path name for source directory or file</source>
    <source>path name for source directory or file</source>
    <source>path name for source directory or file</source>
    <source_user>user name</source_user>
    <target>target directory path name</target>
    <target_user>target directory user name</target_user>
    <target_name>target file name</target_name>
  </vsap>

System Administrators should use the full path name to the files
included in the source list and need not ever include the optional
source user name.  Domain Administrators should use the "virtual path
names" in the source list, i.e. the path names without prepending the
home directory where the sources reside.  If the source file is homed
in one of the Domain Administrator's End Users' file spaces, then
the '<source_user>' node should be used.  End Users will also need to
use "virtual path names" for source files; no '<source_user>'
specification is required, as the authenticated user name is presumed.

The target directory is the directory where the source files will be
copied.  System Administrators should use the full path name to the
target directory and need not ever include the optional target user
name.  Domain Administrators should use the "virtual path name" for the
target directory and the '<target_user>' node if required (per the same
methodology of the source directory specification).  End Users will also
need to use a "virtual path name" to a file; no '<target_user>'
specification is required, as the authenticated user name is presumed.

The optional target name can be specified only when copying a single
source file to new destination.  If a target name exists, the single
file will be copied to the new destination and then renamed to the
target name specified.  The target name should not be specified when
copying multiple files.

Consider the following examples:

=over 2

A request made by a System Administrator to copy a single system file:

    <vsap type="files:copy">
      <source>/usr/local/apache/conf/httpd.conf</source>
      <target>/usr/local/apache/conf</target>
      <target_name>httpd.conf.bak</target_name>
    </vsap>

A request made by a Domain Administrator or End User to copy files homed
in their own home directory:

    <vsap type="files:copy">
      <source>/mystuff/photos/my_cats.jpg</source>
      <source>/mystuff/photos/my_dogs.jpg</source>
      <source>/mystuff/photos/my_gerbils.jpg</source>
      <target>/pets/photos</target>
    </vsap>

A request made by a Domain Administrator to copy files homed from the
directory space of one End User to the home directory space of another
End User:

    <vsap type="files:copy">
      <source_user>scott</source_user>
      <source>/www/data/ode_to_tabasco.html</source>
      <source>/www/data/my_life_as_a_tabasco_pepper.html</source>
      <source>/www/data/tabasco_bottle.jpg</source>
      <target_user>ryan</target_user>
      <target>/poetry/tabasco</target>
    </vsap>

=back

If the source file or files are valid and the target directory is
accessible (see NOTES), the source file (or files) will be copied to the
new destination.  Successful requests to copy files will be indicated in
the return '<success>' node; whereas, failed requests to copy files
will be appended to the '<failure>' node.  It is possible that some
files may be copied successfully while others fail.

The following illustrates the basic form of the data returned from a
copy file request:

  <vsap type="files:copy">
    <source_user>user name</source_user>
    <target_user>target directory user name</target_user>
    <success>
      <path>
         <source>source path name</source>
         <target>target path name</target>
      </path>
      <path>
         <source>source path name</source>
         <target>target path name</target>
      </path>
      <path>
        .
        .
        .
      </path>
    </success>
    <failure>
      <path>
         <source>source path name</source>
         <target>target path name</target>
         <code>system exit code</code>
         <mesg>description of failure</mesg>
      </path>
      <path>
         <source>source path name</source>
         <target>target path name</target>
         <code>system exit code</code>
         <mesg>description of failure</mesg>
      </path>
      <path>
        .
        .
        .
      </path>
    </failure>
  </vsap>

Path names returned for requests made by System Administrators will be
the fully qualfied system path names.  "Virtual path names" will be
returned for requests made by Domain Administrators and End Users.

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

cp(1)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

