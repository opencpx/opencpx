package VSAP::Server::Modules::vsap::files::mkdir;

use 5.008004;
use strict;
use warnings;

use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path diskspace_availability);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.01';

our %_ERR    = ( NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 PATH_EXISTS        => 102,
                 MKDIR_FAILED       => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
               );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get directory path (and user)
    my $path = $xmlobj->child('path') ? $xmlobj->child('path')->value : '';
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};

    unless ($path) {
        $vsap->error($_ERR{'INVALID_PATH'} => "full directory path required");
        return;
    }

    # fix up the path
    $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
    $path = canonpath($path);

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

    # build full directory path
    my $fullpath = $path;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$user})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown user: $user");
            return;
        }
        $fullpath = canonpath(catfile($valid_paths{$user}, $path));
    }
    $fullpath = decode_utf8(abs_path($fullpath)) || sanitize_path($fullpath);
    $fullpath =~ s{/$}{} unless ($path eq '/');

    # check authorization to access directory path
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
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath || -l $fullpath) {
            $vsap->error($_ERR{'PATH_EXISTS'} => "path exists: $fullpath");
            return;
        }
    };

    # figure out who is going to own the target
    my ($effective_uid, $effective_gid);
    if ($vsap->{server_admin}) {
        # set to be the uid of the parent directory
        my $parentpath = $fullpath;
        while (!(-e $parentpath) && ($parentpath ne "")) {
            $parentpath =~ s/[^\/]+$//g;
            $parentpath =~ s/\/+$//g;
            $parentpath = '/' unless ($parentpath);
        }
        ($effective_uid, $effective_gid) = (lstat($parentpath))[4,5];
    }
    else {
        if ($parentuser) {
            ($effective_uid, $effective_gid) = (getpwnam($parentuser))[2,3];
        }
        else {
            $effective_uid = $vsap->{uid};
            $effective_gid = $vsap->{gid};
        }
    }

    # check quota and if fail if over quota
    unless(diskspace_availability($effective_uid, $effective_gid)) {
        $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error making new directory: quota exceeded");
        VSAP::Server::Modules::vsap::logger::log_error("cannot mkdir '$fullpath' (quota exceeded)");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:mkdir');

    # make new directory
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        system('mkdir', '-p', '--', $fullpath)
          and do {
              my $exit = ($? >> 8);
              $vsap->error($_ERR{'MKDIR_FAILED'} => "cannot mkdir '$fullpath' (exitcode $exit)");
              VSAP::Server::Modules::vsap::logger::log_error("mkdir() for $fullpath failed (exitcode $exit)");
              return;
          };
        VSAP::Server::Modules::vsap::logger::log_message("$user created directory '$fullpath'");
    }
    $root_node->appendTextChild(path => $path);
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(status => "ok");

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::mkdir - VSAP module to create a new
directory

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::mkdir;

=head1 DESCRIPTION

The VSAP create directory module allows users to create a new directory
(one per request) with user-defined contents.

To create a new directory, you need to specify a path name and an
optional user name.  The following example generically represents the
structure of a typical create directory request:

  <vsap type="files:mkdir">
    <path>path name</path>
    <user>user name</user>
  </vsap>

System Administrators should use the full path name of a file and need
not ever include the optional user name in a file mode query.  Domain
Administrators should use the "virtual path name" of a file, i.e. the
path name without prepending the home directory where the file resides.
If the file is homed in a one of the Domain Administrator's End Users'
file spaces, then the optional '<user>' node should be used.  End Users
will also need to use a "virtual path name" to a file; no '<user>'
specification is required, as the authenticated user name is presumed.

Consider the following examples:

=over 2

A request made by System Administrator to make a new directory.

    <vsap type="files:mkdir">
      <path>/usr/tmp/logs</path>
    </vsap>

A request made by a Domain Administrator or End User to make a new
directory homed in their own home directory.

    <vsap type="files:mkdir">
      <path>/mystuff/photos/my_pets</path>
      </contents>
    </vsap>

A request made by a Domain Administrator to make a new directory
homed in the directory space of an End User.

    <vsap type="files:mkdir">
      <user>scott</user>
      <path>/www/data/tabasco</path>
    </vsap>

=back

If the path name is accessible (see NOTES), the new directory will be
created or an error will be returned.  A successful update will be
indicated by the return '<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to
the file system, therefore the validity of the path name is only
determined whether it exists or not.  However, End Users are restricted
access (or 'jailed') to their own home directory tree.  Domain
Administrators are likewise restricted, but to the home directory trees
of themselves and their end users.  Any attempts to get information
about or modify properties of files that are located outside of these
valid directories will be denied and an error will be returned.

=head1 SEE ALSO

mkdir(1)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

