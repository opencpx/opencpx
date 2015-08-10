package VSAP::Server::Modules::vsap::files::chown;

use 5.008004;
use strict;
use warnings;

use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::files qw(sanitize_path);
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED          => 100,
                 INVALID_PATH            => 101,
                 CANT_OPEN_PATH          => 102,
                 CHOWN_FAILED            => 103,
                 RECURSION_FAILED        => 104,
                 INVALID_USER            => 105,
                 INVALID_OWNER           => 106,
                 INVALID_GROUP           => 107,
               );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $path = $xmlobj->child('path') ? $xmlobj->child('path')->value : '';
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};
    my $recurse = $xmlobj->child('recurse') ?
                  $xmlobj->child('recurse')->value : '';

    unless ($path) {
        $vsap->error($_ERR{'INVALID_PATH'} => "path undefined");
        return;
    }

    # fix up the path
    $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
    $path = canonpath($path);

    # if setting new ownership, get new user/group definition
    my ($set_ownership, $new_owner, $new_group, $new_uid, $new_gid);
    $new_owner = $xmlobj->child('owner') ?
                 $xmlobj->child('owner')->value : '';
    $new_group = $xmlobj->child('group') ?
                 $xmlobj->child('group')->value : '';
    if ($new_owner || $new_group) {
        unless ($new_owner) {
            $vsap->error($_ERR{'INVALID_OWNER'} => "new owner undefined");
            return;
        }
        unless ($new_group) {
            $vsap->error($_ERR{'INVALID_GROUP'} => "new group undefined");
            return;
        }
        $new_uid = -1;
        $new_uid = getpwnam($new_owner);
        if ($new_uid < 0) {
            $vsap->error($_ERR{'INVALID_OWNER'} => "unknown new owner: $new_owner");
            return;
        }
        $new_gid = -1;
        $new_gid = getgrnam($new_group);
        if ($new_gid < 0) {
            $vsap->error($_ERR{'INVALID_GROUP'} => "unknown new group: $new_group");
            return;
        }
        $set_ownership = 1;
    }

    # get config object and site prefs
    my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
    my $siteprefs = $co->siteprefs;
    my $lfm = ($siteprefs->{'limited-file-manager'}) ? 1 : 0;  ## chroot file manager for server admin

    # get list of valid paths for user
    my ($validuser, $validgroup);
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

    # if setting new ownership, new user:group must be valid
    if ($set_ownership) {
        unless ($vsap->{server_admin}) {
            # check user
            unless (exists($valid_paths{$new_owner})) {
                # user not found in authorized list
                $vsap->error($_ERR{'INVALID_OWNER'} => "invalid new owner: $new_owner");
                return;
            }
            # check group
            my $valid = 0;
            foreach $validuser (@ulist) {
                my ($gid) = (getpwnam($validuser))[3];
                $validgroup = getgrgid($gid);
                if ($validgroup eq $new_group) {
                    $valid = 1;
                    last;
                }
            }
            if ($co->domain_admin) {
                $valid = 1 if ($new_group eq $VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP);
            }
            # check any other secondary group
            my ($gname, $gpass, $gid, $gmembers);
            while (($gname, $gpass, $gid, $gmembers) = getgrent()) {
                next if ($gname eq "ftp");
                next if ($gname eq "imap");
                next if ($gname eq "pop");
                next if ($gname eq "mailgrp");
                foreach $validuser (@ulist) {
                    $valid = 1 if ($gmembers =~ /\b$validuser\b/);
                }
            }
            unless ($valid) {
                # user not found in authorized list
                $vsap->error($_ERR{'INVALID_GROUP'} => "invalid new group: $new_group");
                return;
            }
        }
    }

    # build full path
    my $fullpath = $path;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$user})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown user: $user");
            return;
        }
        $fullpath = canonpath(catfile($valid_paths{$user}, $path));
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

    # check authorization to access path
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

    # does the path exist?
    my ($effective_uid, $effective_gid);
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath || -l $fullpath) {
            if ($vsap->{server_admin}) {
                $effective_uid = 0;  # give plenty of rope
                $effective_gid = 0;
            }
            else {
                # set effective uid/gid to default values
                if ($parentuser) {
                    ($effective_uid, $effective_gid) = (getpwnam($parentuser))[2,3];
                }
                else {
                    $effective_uid = $vsap->{uid};
                    $effective_gid = $vsap->{gid};
                }
                # vsap user can only manipulate files owned by self or by
                # subusers, even if the file is in a valid file space
                my ($owner_uid, $owner_gid) = (lstat($fullpath))[4,5];
                my ($owner_username) = getpwuid($owner_uid);
                if (exists($valid_paths{$owner_username})) {
                    $effective_uid = $owner_uid;
                    $effective_gid = $owner_gid;
                }
            }
        }
        else {
            $vsap->error($_ERR{'CANT_OPEN_PATH'} => "can't open path: $fullpath");
            return;
        }
    }

    if ($set_ownership) {
        # if (effective_uid != new_uid) or (effective_gid != new_gid), then
        # we will need to run the chown command as the super user.  the auth
        # checks above will ensure that nothing bad comes of this.
        if (($effective_uid != $new_uid) || ($effective_gid != $new_gid)) {
            $effective_uid = 0;
            $effective_gid = 0;
        }
    }

    # get/set file ownership
    my ($owner_pwnam, $owner_grnam);
    my $status = "";
    my $recurse_option_valid = "";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        # set the new ownership (if applicable)
        if ($set_ownership) {
            if (-l $fullpath) {
                # use system chown on symlinks
                system('chown', '-h', "$new_uid:$new_gid", $fullpath)
                  and do {
                      my $exit = ($? >> 8);
                      $vsap->error($_ERR{'CHOWN_FAILED'} => "cannot chown '$fullpath' (exitcode $exit)");
                      VSAP::Server::Modules::vsap::logger::log_error("cannot chown '$fullpath' (exitcode $exit)");
                      return;
                  };
            }
            elsif ($recurse) {
                # use system chown for recursion
                system('chown', '-R', "$new_uid:$new_gid", $fullpath)
                  and do {
                      my $exit = ($? >> 8);
                      $vsap->error($_ERR{'RECURSION_FAILED'} => "cannot chown '$fullpath' (exitcode $exit)");
                      VSAP::Server::Modules::vsap::logger::log_error("cannot chown '$fullpath' (exitcode $exit)");
                      return;
                  };
            }
            else {
                # use perl built-in chown
                chown($new_uid, $new_gid, $fullpath)
                  or do {
                      $vsap->error($_ERR{'CHOWN_FAILED'} => "cannot chown '$fullpath' ($!)");
                      VSAP::Server::Modules::vsap::logger::log_error("cannot chown '$fullpath' ($!)");
                      return;
                  };
            }
            $status = "ok";
        }
        # get the current ownership of the path
        my ($owner_uid, $owner_gid) = (lstat($fullpath))[4,5];
        $owner_pwnam = getpwuid($owner_uid);
        $owner_grnam = getgrgid($owner_gid);
        # options
        if ((-d $fullpath) && (!(-l $fullpath))) {
            my @files = ();
            use bytes;
            if (opendir(DIR, $fullpath)) {
                @files = readdir(DIR);
                closedir(DIR);
            }
            no bytes;
            $recurse_option_valid = "yes" if ($#files > 1);
        }
    }
    if ($set_ownership) {
        # log what was done
        VSAP::Server::Modules::vsap::logger::log_message("$user changed ownership for '$fullpath' to $owner_pwnam:$owner_grnam");
    }

    # set up the ownership options hashes (ownernames and groupnames)
    my (%ownernames, %groupnames);
    %ownernames = %groupnames = ();
    if ($vsap->{server_admin} && !$lfm) {
        # load 'em up!
        setpwent();
        setgrent();
        while ($validuser = getpwent()) {
            $ownernames{$validuser} = "dau!";
        }
        while ($validgroup = getgrent()) {
            $groupnames{$validgroup} = "dau!";
        }
        endpwent();
        endgrent();
    }
    else {
        # walk through users in the list returned from vsap::config
        foreach $validuser (@ulist) {
            $ownernames{$validuser} = "dau!";
            my ($gid) = (getpwnam($validuser))[3];
            $validgroup = getgrgid($gid);
            $groupnames{$validgroup} = "dau!";
        }
        # get any other secondary group
        my ($gname, $gpass, $gid, $gmembers);
        while (($gname, $gpass, $gid, $gmembers) = getgrent()) {
            next if ($gname eq "ftp");
            next if ($gname eq "imap");
            next if ($gname eq "pop");
            next if ($gname eq "mailgrp");
            foreach $validuser (@ulist) {
                if ($gmembers =~ /\b$validuser\b/) {
                    $groupnames{$gname} = "dau!";
                }
            }
        }
        # if domain admin
        if ($co->domain_admin) {
            my $apache_group = $VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP;
            $groupnames{$apache_group} = "dau!";
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:chown');

    $root_node->appendTextChild(path => $path);
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(owner => $owner_pwnam);
    $root_node->appendTextChild(group => $owner_grnam);
    $root_node->appendTextChild(status => $status) if ($status);
    if ($recurse_option_valid) {
        $root_node->appendTextChild(recurse_option_valid => $recurse_option_valid);
    }

    my $oo_node  = $root_node->appendChild($dom->createElement('ownership_options'));
    my $users_node  = $oo_node->appendChild($dom->createElement('ownernames'));
    foreach $validuser (keys(%ownernames)) {
        $users_node->appendTextChild(owner => $validuser);
    }
    my $groups_node = $oo_node->appendChild($dom->createElement('groupnames'));
    foreach $validgroup (keys(%groupnames)) {
        $groups_node->appendTextChild(group => $validgroup);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::chown - VSAP module to modify file ownership

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::chown;

=head1 DESCRIPTION

The VSAP chown module allows users to view and modify the file ownership of
a single file.

To view the current ownership of a file, you need to specify a path name and
an optional user name:

  <vsap type="files:chown">
    <path>path name</path>
    <user>user name</user>
  </vsap>

System Administrators should use the full path name of a file and need
not ever include the optional user name in a file ownership query.  Domain
Administrators should use the "virtual path name" of a file, i.e. the
path name without prepending the home directory where the file resides.
If the file is homed in a one of the Domain Administrator's End Users'
file spaces, then the optional '<user>' node should be used.  End Users
will also need to use a "virtual path name" to a file; no '<user>'
specification is required, as the authenticated user name is presumed.

Consider the following examples:

=over 2

A query made by a System Administator on a system file.

    <vsap type="files:chown">
      <path>/usr/bin/f77</path>
    </vsap>

A query made by a Domain Administrator or End User on a file homed
in their own home directory.

    <vsap type="files:chown">
      <path>/mystuff/photos/my_cats.jpg</path>
    </vsap>

A query made by a Domain Administrator on a file homed in the
directory space of an End User.

    <vsap type="files:chown">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
    </vsap>

=back

If the path name is accessible (see NOTES), information about the file
ownership will be returned.  A list of eligible user names and group
names is also appended to a '<ownership_options>' node.  These lists
are considered to be the 'valid' subset of user names and group names
that the authenticated user is allowed to specify in a change ownership
request.  If the path name is a directory and is a candidate for a
recursive modify ownership action, a boolean value (0|1) will be
returned as the value for the '<recurse_option_valid>' node.

The following example generically represents the structure of a typical
response from a query:

  <vsap type="files:chown">
    <path>path name</path>
    <user>user name</user>
    <owner>file owner name</owner>
    <group>file owner group</group>
    <recurse_option_valid>0|1</recurse_option_valid>
    <ownership_options>
      <ownernames>
        <owner>user name</owner>
        <owner>user name</owner>
        <owner>user name</owner>
        <owner>user name</owner>
      </ownernames>
      <groupnames>
        <group>group name</group>
        <group>group name</group>
        <group>group name</group>
        <group>group name</group>
      </groupnames>
    </ownership_options>
  </vsap>

To set (i.e. modify) the file ownership for a file, the new file
ownership need simply be coupled with the path name and (optional) user
name.  Specify the new file ownership using the '<owner>' and '<group>'
nodes.

If the path name represents a directory, then you may also (optionally)
specify whether or not the action should be recursive by including a
'<recurse>' node with a value set to 1.

The following template represents a the generic form of a query to
change the file mode bits for a file:

  <vsap type="files:chown">
    <path>path name</path>
    <user>user name</user>
    <recurse>0|1</recurse>
    <owner>user name</owner>
    <group>group name</group>
  </vsap>

If the file is accessible (see NOTES), the file ownership will be updated
or an error will be returned.   A successful update will be indicated by
the return '<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to the
file system, therefore the validity of the path name is only determined
whether it exists or not.  However, End Users are restricted access (or
'jailed') to their own home directory tree.  Domain Administrators are
likewise restricted, but to the home directory trees of themselves and
their end users.  Any attempts to get information about or modify
properties of files that are located outside of these valid directories
will be denied and an error will be returned.

=head1 SEE ALSO

chgrp(1), chown(8)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

