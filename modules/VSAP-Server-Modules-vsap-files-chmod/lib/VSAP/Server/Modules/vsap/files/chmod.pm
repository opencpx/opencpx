package VSAP::Server::Modules::vsap::files::chmod;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::files qw(sanitize_path mode_octal mode_symbolic);
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED          => 100,
                 INVALID_PATH            => 101,
                 CANT_OPEN_PATH          => 102,
                 CHMOD_FAILED            => 103,
                 RECURSION_FAILED        => 104,
                 INVALID_USER            => 105,
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
    my $recurse_X = $xmlobj->child('recurse_X') ?
                    $xmlobj->child('recurse_X')->value : '';

    unless ($path) {
        $vsap->error($_ERR{'INVALID_PATH'} => "path undefined");
        return;
    }

    # fix up the path
    $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
    $path = canonpath($path);

    # if setting new mode, get new user/group/world perms
    my ($new_ubits, $new_gbits, $new_wbits);
    my $new_mode = $xmlobj->child('mode') ? $xmlobj->child('mode') : '';
    if ($new_mode) {
        $new_ubits = $new_mode->child('owner') ? $new_mode->child('owner') : '';
        $new_gbits = $new_mode->child('group') ? $new_mode->child('group') : '';
        $new_wbits = $new_mode->child('world') ? $new_mode->child('world') : '';
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
                # give plenty of rope
                $effective_uid = 0;
                $effective_gid = 0;
            }
            else {
                # set effective uid to default value
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

    # set/get mode
    my $fmode = 0;    # absolute representation of new mode
    my $smode = "";   # symbolic representation of new mode
    my $status = "";
    my $recurse_option_valid = "";
    my ($owner_pwnam, $owner_grnam);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_uid;
        local $> = $effective_uid;
        # set the new mode (if applicable)
        if ($new_mode) {
            if ($new_ubits) {
                $fmode |= ( $new_ubits->child('setuid')  && $new_ubits->child('setuid')->value  ? 04000 : 0 );
                $fmode |= ( $new_ubits->child('read')    && $new_ubits->child('read')->value    ?  0400 : 0 );
                $fmode |= ( $new_ubits->child('write')   && $new_ubits->child('write')->value   ?  0200 : 0 );
                $fmode |= ( $new_ubits->child('execute') && $new_ubits->child('execute')->value ?  0100 : 0 );
                $smode .= "u";
                $smode .= ( $new_ubits->child('setuid')  && $new_ubits->child('setgid')->value  ) ? "+s" : "-s";
                $smode .= ( $new_ubits->child('read')    && $new_ubits->child('read')->value    ) ? "+r" : "-r";
                $smode .= ( $new_ubits->child('write')   && $new_ubits->child('write')->value   ) ? "+w" : "-w";
                $smode .= ( $new_ubits->child('execute') && $new_ubits->child('execute')->value ) ? "+x" : "-x";
            }
            else {
                $smode .= "u-rwx";
            }
            $smode .= ",";
            if ($new_gbits) {
                $fmode |= ( $new_gbits->child('setgid')  && $new_gbits->child('setgid')->value  ? 02000 : 0 );
                $fmode |= ( $new_gbits->child('read')    && $new_gbits->child('read')->value    ?   040 : 0 );
                $fmode |= ( $new_gbits->child('write')   && $new_gbits->child('write')->value   ?   020 : 0 );
                $fmode |= ( $new_gbits->child('execute') && $new_gbits->child('execute')->value ?   010 : 0 );
                $smode .= "g";
                $smode .= ( $new_gbits->child('setgid')  && $new_gbits->child('setgid')->value  ) ? "+s" : "-s";
                $smode .= ( $new_gbits->child('read')    && $new_gbits->child('read')->value    ) ? "+r" : "-r";
                $smode .= ( $new_gbits->child('write')   && $new_gbits->child('write')->value   ) ? "+w" : "-w";
                $smode .= ( $new_gbits->child('execute') && $new_gbits->child('execute')->value ) ? "+x" : "-x";
            }
            else {
                $smode .= "g-rwx";
            }
            $smode .= ",";
            if ($new_wbits) {
                $fmode |= ( $new_wbits->child('sticky')  && $new_wbits->child('sticky')->value  ? 01000 : 0 );
                $fmode |= ( $new_wbits->child('read')    && $new_wbits->child('read')->value    ?    04 : 0 );
                $fmode |= ( $new_wbits->child('write')   && $new_wbits->child('write')->value   ?    02 : 0 );
                $fmode |= ( $new_wbits->child('execute') && $new_wbits->child('execute')->value ?    01 : 0 );
                $smode .= "o";
                $smode .= ( $new_wbits->child('sticky')  && $new_wbits->child('sticky')->value  ) ? "+t" : "-t";
                $smode .= ( $new_wbits->child('read')    && $new_wbits->child('read')->value    ) ? "+r" : "-r";
                $smode .= ( $new_wbits->child('write')   && $new_wbits->child('write')->value   ) ? "+w" : "-w";
                $smode .= ( $new_wbits->child('execute') && $new_wbits->child('execute')->value ) ? "+x" : "-x";
            }
            else {
                $smode .= "o-rwx";
            }
            if (-l $fullpath) {
                # use system chmod on symlinks
                system('chmod', '-h', $fmode, $fullpath)
                  and do {
                      my $exit = ($? >> 8);
                      $vsap->error($_ERR{'CHMOD_FAILED'} => "cannot chmod '$fullpath' (exitcode $exit)");
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed (exitcode $exit)");
                      return;
                  };
            }
            elsif ($recurse) {
                # use system chmod for recursion
                $smode =~ s/\+x/\+X/g if ($recurse_X);
                system('chmod', '-R', $smode, $fullpath)
                  and do {
                      my $exit = ($? >> 8);
                      $vsap->error($_ERR{'RECURSION_FAILED'} => "cannot recursive chmod '$fullpath' (exitcode $exit)");
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed (exitcode $exit)");
                      return;
                  };
            }
            else {
                # use perl built-in chmod
                chmod($fmode, $fullpath)
                  or do {
                      $vsap->error($_ERR{'CHMOD_FAILED'} => "cannot chmod '$fullpath' ($!)");
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed ($!)");
                      return;
                  };
            }
            my $octal_mode = mode_octal($fmode);
            VSAP::Server::Modules::vsap::logger::log_message("$user changed mode for '$fullpath' to $octal_mode");
            $status = "ok";
        }
        # get the current mode and ownership of the path
        my ($owner_uid, $owner_gid);
        ($fmode, $owner_uid, $owner_gid) = (lstat($fullpath))[2,4,5];
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

    # create dom and append basic info
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:chmod');
    $root_node->appendTextChild(path => $path);
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(owner => $owner_pwnam);
    $root_node->appendTextChild(group => $owner_grnam);
    $root_node->appendTextChild(status => $status) if ($status);
    if ($recurse_option_valid) {
        $root_node->appendTextChild(recurse_option_valid => $recurse_option_valid);
    }

    # append basic mode info
    my $mode_node = $root_node->appendChild($dom->createElement('mode'));
    my $owner_node = $mode_node->appendChild($dom->createElement('owner'));
    $owner_node->appendTextChild(read    => ($fmode &  0400 ? 1 : 0));
    $owner_node->appendTextChild(write   => ($fmode &  0200 ? 1 : 0));
    $owner_node->appendTextChild(execute => ($fmode &  0100 ? 1 : 0));
    my $group_node = $mode_node->appendChild($dom->createElement('group'));
    $group_node->appendTextChild(read    => ($fmode &   040 ? 1 : 0));
    $group_node->appendTextChild(write   => ($fmode &   020 ? 1 : 0));
    $group_node->appendTextChild(execute => ($fmode &   010 ? 1 : 0));
    my $world_node = $mode_node->appendChild($dom->createElement('world'));
    $world_node->appendTextChild(read    => ($fmode &    04 ? 1 : 0));
    $world_node->appendTextChild(write   => ($fmode &    02 ? 1 : 0));
    $world_node->appendTextChild(execute => ($fmode &    01 ? 1 : 0));

    # add 'special' mode info
    $owner_node->appendTextChild(setuid  => ($fmode & 04000 ? 1 : 0));
    $group_node->appendTextChild(setgid  => ($fmode & 02000 ? 1 : 0));
    $world_node->appendTextChild(sticky  => ($fmode & 01000 ? 1 : 0));

    # add text child for both symbolic and octal representation of mode
    my $octal_mode = mode_octal($fmode);
    $root_node->appendTextChild(octal_mode => $octal_mode);
    my $symbolic_mode = mode_symbolic($fmode);
    $root_node->appendTextChild(symbolic_mode => $symbolic_mode);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::chmod - VSAP module to modify file mode

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::chmod;

=head1 DESCRIPTION

The VSAP chmod module allows users to view and modify the file mode bits of
a single file.

To view the file mode bits of a file, you need to specify a path name and
an optional user name:

  <vsap type="files:chmod">
    <path>path name</path>
    <user>user name</user>
  </vsap>

System Administrators should use the full path name of a file and need
not ever include the optional user name in a file mode query.  Domain
Administrators should use the "virtual path name" of a file, i.e. the
path name without prepending the home directory where the file resides.
If the file is homed in a one of the Domain Administrator's End Users'
file spaces, then the optional '<user>' node should be used.  End Users
will also need to use the "virtual path name" to a file; no '<user>'
specification is required, as the authenticated user name is presumed.

Consider the following examples:

=over 2

A query made by a System Administator on a system file.

    <vsap type="files:chmod">
      <path>/usr/bin/f77</path>
    </vsap>

A query made by a Domain Administrator or End User on a file homed
in their own home directory.

    <vsap type="files:chmod">
      <path>/mystuff/photos/my_cats.jpg</path>
    </vsap>

A query made by a Domain Administrator on a file homed in the
directory space of an End User.

    <vsap type="files:chmod">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
    </vsap>

=back

If the path name is accessible (see NOTES), information about the file
mode bits and ownership will be returned.  If the path name is a
directory and is a candidate for a recursive modify mode action, a
boolean value (0|1) will be returned as the value for the
'<recurse_option_valid>' node.

The following example generically represents the structure of a typical
response from a query:

  <vsap type="files:chmod">
    <path>path name</path>
    <user>user name</user>
    <owner>file owner name</owner>
    <group>file owner group</group>
    <recurse_option_valid>0|1</recurse_option_valid>
    <mode>
      <owner>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <setuid>0|1</setuid>
      </owner>
      <group>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <setgid>0|1</setgid>
      </group>
      <world>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <sticky>0|1</sticky>
      </world>
    </mode>
  </vsap>

To set (i.e. modify) the file mode bits for a file, the new file mode
need simply be coupled with the path name and (optional) user name.
Specify the new file mode using a '<mode>' node with appropriately
populated nested '<owner>', '<group>', and '<world>' subnodes.

If the path name represents a directory, then you may also (optionally)
specify whether or not the action should be recursive by including a
'<recurse>' node with a value set to 1.

The following template represents a the generic form of a request to
change the file mode bits for a file:

  <vsap type="files:chmod">
    <path>path name</path>
    <user>user name</user>
    <recurse>0|1</recurse>
    <mode>
      <owner>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <setuid>0|1</setuid>
      </owner>
      <group>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <setgid>0|1</setgid>
      </group>
      <world>
        <read>0|1</read>
        <write>0|1</write>
        <execute>0|1</execute>
        <sticky>0|1</sticky>
      </world>
    </mode>
  </vsap>

If the file is accessible (see NOTES), the file mode bits will be updated
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

chmod(1)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

