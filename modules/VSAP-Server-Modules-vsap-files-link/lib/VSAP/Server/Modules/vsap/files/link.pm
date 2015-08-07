package VSAP::Server::Modules::vsap::files::link;

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
                 LINK_FAILED        => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_LINKNAME   => 106,
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
    my $source = $xmlobj->child('source') ? $xmlobj->child('source')->value : '';
    my $sourceuser = ($xmlobj->child('source_user') && $xmlobj->child('source_user')->value) ?
                      $xmlobj->child('source_user')->value : $vsap->{username};

    # get target directory (and user)
    my $targetdir = $xmlobj->child('target') ?
                    $xmlobj->child('target')->value : '';
    my $targetuser = ($xmlobj->child('target_user') && $xmlobj->child('target_user')->value) ?
                      $xmlobj->child('target_user')->value : $vsap->{username};

    # get the target link name
    my $shortcutname = $xmlobj->child('target_name') ?
                       $xmlobj->child('target_name')->value : '';

    # build link using absolute paths?
    my $use_absolute_paths = $xmlobj->child('use_absolute_paths') ?
                             $xmlobj->child('use_absolute_paths')->value : '';

    unless ($source) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source path required");
        return;
    }

    unless ($targetdir) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    unless ($shortcutname) {
        $vsap->error($_ERR{'INVALID_LINKNAME'} => "shortcut link name required");
        return;
    }

    # the goal is symlink(source, targetdir/shortcutname)
    my $target = canonpath(catfile($targetdir, $shortcutname));

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
        $vsap->error($_ERR{'LINK_FAILED'} => "target ($fulltarget) must differ from source ($fullpath)");
        return;
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
    my ($source_euid, $source_egid);
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath || -l $fullpath) {
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


    # if user is over quota, create symlink will fail
    unless(diskspace_availability($target_euid, $target_egid))
    {
            $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error creating symlink: quota exceeded");
            return;
    }

    # make sure parent of target exists before attempting to make link
  EFFECTIVE: {
        local $> = $target_euid;
        my ($ftname, $ftpath) = fileparse($fulltarget);
        unless (-e $ftpath) {
            system('mkdir', '-p', '--', $ftpath)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'LINK_FAILED'} => "cannot mkdir '$ftpath' (exitcode $exit)");
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
        if (($source_euid != $target_euid) || ($source_egid != $target_egid)) {
            # need to be super user
            $effective_uid = $effective_gid = 0;
        }
    }

    # build the final source link source and destination paths
    my ($linkpath, $linkname);
    if ($use_absolute_paths) {
        $linkpath = $fullpath;
    }
    else {
        # make linkpath relative to where link will be created
        my($sname, $spath) = fileparse($fullpath);
        my($tname, $tpath) = fileparse($fulltarget);
        my @subdirs = ();
        my ($subdir, $index);
        my $basepath = $spath;
        while ($basepath) {
            if ($tpath =~ s#^\Q$basepath\E##) {
                my $dotdotcnt = $tpath =~ tr#/#/#;
                $linkpath = "../" x $dotdotcnt;
                for ($index=$#subdirs; $index>=0; $index--) {
                    $linkpath .= $subdirs[$index] . "/";
                }
                $linkpath .= $sname;
                last;
            }
            chop($basepath);
            ($subdir, $basepath) = fileparse($basepath);
            push(@subdirs, $subdir);
        }
    }
    $linkname = $fulltarget;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:link');

    # create symlink (target) to existing file (path)
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        # cross your fingers, invoke symlink(), and hope for the best
        symlink($linkpath, $linkname)
          or do {
              $vsap->error($_ERR{'LINK_FAILED'} => "symlink('$fullpath','$fulltarget') failed: $!");
              VSAP::Server::Modules::vsap::logger::log_error("symlink('$fullpath','$fulltarget') failed: $!");
              return;
          };
        # chown to the target path's owner
        system('chown', '-h', "$target_euid:$target_egid", $fulltarget)
          and do {
              my $exit = ($? >> 8);
              warn "cannot chown '$fulltarget' (exitcode $exit)";
          };
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} created symlink $linkname pointing to $linkpath");
    }

    # build virtualtargetpath from full target
    my $vtp = $fulltarget;
    if (!$vsap->{server_admin} || $lfm) {
        $vtp =~ s#^\Q$valid_paths{$targetuser}\E(/|$)#/#;
    }

    $root_node->appendTextChild(path => $source);
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

VSAP::Server::Modules::vsap::files::link - VSAP module to create symlinks

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::link;

=head1 DESCRIPTION

The VSAP link module allows users to create a symbolic link (or
"shortcut") in one part of the file system to a file that is located in
a different part of the file system.

To create a new shortcut to a file, you need to specify the source file
(or directory), an optional source user name, a target directory path
name, an optional target user name, and a target shortcut name.  You may
also specify whether to use absolute or relative path names when
building the target shortcut.

The following template represents the generic form of a request to
create a shortcut:

  <vsap type="files:link">
    <source>path name for source directory or file</source>
    <source_user>user name</source_user>
    <target>target directory path name</target>
    <target_user>target directory user name</target_user>
    <target_name>shortcut file name</target_name>
    <use_absolute_paths>0|1</use_absolute_paths>
  </vsap>

System Administrators should use the full path name to the source file
and need not ever include the optional source user name.  Domain
Administrators should use the "virtual path name" for the source file,
i.e. the path name without prepending the home directory where the
source resides.  If the source file is homed in one of the Domain
Administrator's End Users' file spaces, then the '<source_user>' node
should be used.  End Users will also need to use a "virtual path name"
for the source file; no '<source_user>' specification is required, as
the authenticated user name is presumed.

The target directory is the directory where the shortcut to the source
file will be located.  System Administrators should use the full path
name to the target directory and need not ever include the optional
target user name.  Domain Administrators should use the "virtual path
name" for the target directory and the '<target_user>' node if required
(per the same methodology of the source directory specification).  End
Users will also need to use a "virtual path name" to a file; no
'<target_user>' specification is required, as the authenticated user
name is presumed.  The target name is the name of the new shortcut.

Consider the following examples:

=over 2

A request made by a System Administrator to create a shortcut to a
system file:

    <vsap type="files:link">
      <source>/usr/local/apache</source>
      <target>/</target>
      <target_name>www</target_name>
    </vsap>

A request made by a Domain Administrator or End User to create a
shortcut to a file homed in their own home directory.

    <vsap type="files:link">
      <source>/mystuff/photos/my_cats.jpg</source>
      <target>/pets</target>
      <target_name>cats.jpg</target_name>
    </vsap>

A request made by a Domain Administrator to create a shortcut to a file
homed in the directory space of an End User in a directory elsewhere in
the End User's directory space.

    <vsap type="files:copy">
      <source_user>scott</source_user>
      <source>/www/data/ode_to_tabasco.html</source>
      <target_user>scott</target_user>
      <target>/poetry</target>
      <target_name>tabasco_haiku.html</target_name>
    </vsap>

=back

If the source file is valid and the target directory is accessible (see
NOTES), the shortcut will be created in the target directory using the
target name.  Successful requests to create shortcuts will be indicated
by the return '<status>' node.

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

ln(1)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

