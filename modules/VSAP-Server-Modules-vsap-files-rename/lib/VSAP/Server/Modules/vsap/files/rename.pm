package VSAP::Server::Modules::vsap::files::rename;

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
                 RENAME_FAILED      => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_NAME       => 106,
                 INVALID_TARGET     => 107,
                 TARGET_EXISTS      => 108,
               );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get source path (and user)
    my $source = $xmlobj->child('source') ?
                 $xmlobj->child('source')->value : '';
    my $sourceuser = ($xmlobj->child('source_user') && $xmlobj->child('source_user')->value) ?
                      $xmlobj->child('source_user')->value : $vsap->{username};

    # get target directory (and user)
    my $targetdir = $xmlobj->child('target') ?
                    $xmlobj->child('target')->value : '';
    my $targetuser = ($xmlobj->child('target_user') && $xmlobj->child('target_user')->value) ?
                      $xmlobj->child('target_user')->value : $vsap->{username};

    # get the new filename
    my $newfilename = $xmlobj->child('target_name') ?
                      $xmlobj->child('target_name')->value : '';

    unless ($source) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source path required");
        return;
    }

    unless ($targetdir) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    unless ($newfilename) {
        $vsap->error($_ERR{'INVALID_NAME'} => "shortcut link name required");
        return;
    }

    # the goal is rename(source, targetdir/newfilename)
    my $target = canonpath(catfile($targetdir, $newfilename));

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
    my $fullpath = $source;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$sourceuser})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown source user: $sourceuser");
            return;
        }
        $fullpath = canonpath(catfile($valid_paths{$sourceuser}, $source));
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

    # if source and target are identical then return error
    if ($fulltarget eq $fullpath) {
        $vsap->error($_ERR{'RENAME_FAILED'} => "target ($fulltarget) must differ from source ($fullpath)");
        return;
    }

    # check authorization to access source path
    my $authorized = 0;
    my $parentuser = "";
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if ($fullpath eq $valid_path) {
            # can't rename home directories
            $vsap->error($_ERR{'INVALID_PATH'} => "invalid path: $fullpath");
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

    # check authorization to access target path
    $authorized = 0;
    $parentuser = "";
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

    # does the source and/or target exist?
    my ($source_euid, $source_egid, $size);
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
        if (-e $fulltarget || -l $fulltarget) {
            $vsap->error($_ERR{'TARGET_EXISTS'} => "target exits: $fulltarget");
            return;
        }
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

    # if changing ownership, check quota and fail if no room
    my ($new_disk_space_requirements) = 0;
    if ($source_euid != $target_euid) {
        # this will become chown'd to the owner of the target directory
        $new_disk_space_requirements = $size;
    }
    if ($new_disk_space_requirements) {
        # get quota/usage for owner of the target directory
        unless(diskspace_availability($target_euid, $target_egid, $new_disk_space_requirements))
        {
                $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error renaming file: quota exceeded");
                return;
        }
    }

    # make sure parent of target exists before attempting to rename
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        my ($ftname, $ftpath) = fileparse($fulltarget);
        unless (-e $ftpath) {
            system('mkdir', '-p', '--', $ftpath)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'RENAME_FAILED'} => "cannot mkdir '$ftpath' (exitcode $exit)");
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
        if (($source_euid != $target_euid) ||
            ($source_egid != $target_egid)) {
            # need to be super user
            $effective_uid = $effective_gid = 0;
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:rename');

    # rename path to target
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        # cross your fingers, rename, and hope for the best
        rename($fullpath, $fulltarget)
          or do {
              $vsap->error($_ERR{'RENAME_FAILED'} => "move '$fullpath' to '$fulltarget' failed: $!");
              VSAP::Server::Modules::vsap::logger::log_error("move '$fullpath' to '$fulltarget' failed: $!");
              return;
          };
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} renamed '$fullpath' to '$fulltarget'");
        # chown to the target path's owner
        chown($target_euid, $target_egid, $fulltarget) ||
            warn("chown() failed on $fulltarget: $!");
    }

    # build virtualtargetpath from full target
    my $vtp = $fulltarget;
    if (!$vsap->{server_admin} || $lfm) {
        $vtp =~ s#^\Q$valid_paths{$targetuser}\E(/|$)#/#;
    }

    $root_node->appendTextChild(source => $source);
    $root_node->appendTextChild(source_user => $sourceuser);
    $root_node->appendTextChild(target => $vtp);
    $root_node->appendTextChild(target_user => $targetuser);
    $root_node->appendTextChild(status => "ok");

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::rename - VSAP module to rename a
single file

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::rename;

=head1 DESCRIPTION

The VSAP rename module allows users to rename (and optionally move) one
source file.

To rename a file, you need to specify the source directory or file, an
optional  source user name, a target directory path name, an optional
target user name, and a target file name.

The following template represents the generic form of a request to rename
a file:

  <vsap type="files:rename">
    <source>path name for source directory or file</source>
    <source_user>user name</source_user>
    <target>target directory path name</target>
    <target_user>target directory user name</target_user>
    <target_name>target file name</target_name>
  </vsap>

System Administrators should use the full path name to the source
directory of file and need not ever include the optional source user
name.  Domain Administrators should use the "virtual path name" as the
source path, i.e. the path name without prepending the home directory
where the source resides.  If the source file is homed in one of the
Domain Administrator's End Users' file spaces, then the '<source_user>'
node should be used.  End Users will also need to use "virtual path
names" for source files; no '<source_user>' specification is required,
as the authenticated user name is presumed.

The target directory is the directory where the source files will be
copied.  System Administrators should use the full path name to the
target directory and need not ever include the optional target user
name.  Domain Administrators should use the "virtual path name" for the
target directory and the '<target_user>' node if required (per the same
methodology of the source directory specification).  End Users will also
need to use a "virtual path name" to a file; no '<target_user>'
specification is required, as the authenticated user name is presumed.

The target name is the new file name to be used for the rename request.

Consider the following examples:

=over 2

A request made by a System Administrator to rename a single system file:

    <vsap type="files:rename">
      <source>/var/log/maillog.0.gz</source>
      <target>/var/log</target>
      <target_name>maillog.yesterday.gz</target_name>
    </vsap>

A request made by a Domain Administrator or End User to rename a file
homed in their own home directory:

    <vsap type="files:rename">
      <source>/mystuff/photos/my_goldfish.jpg</source>
      <target>/mystuff/photos</target>
      <target_name>my_dead_goldfish.jpg</target>
    </vsap>

A request made by a Domain Administrator to rename a file homed in
the directory space of an End User:

    <vsap type="files:rename">
      <source_user>scott</source_user>
      <source>/www/data/ode_to_tabasco.html</source>
      <target_user>scott</target_user>
      <target>/www/data</target>
      <target_name>tabasco_haiku.html</target_name>
    </vsap>

=back

If the source file is valid and the target directory is accessible (see
NOTES), the source file will be renamed using the new filename.
Successful requests to create shortcuts will be indicated by the return
'<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to
the file system, therefore the validity of the path name is only
determined whether it exists or not.  However, End Users are restricted
access (or 'jailed') to their own home directory tree.  Domain
Administrators are likewise restricted, but to the home directory trees
of themselves and their end users.  Any attempts at access to files that
are located outside of these valid directories will be denied and an
error will be returned.

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

