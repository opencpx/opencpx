package VSAP::Server::Modules::vsap::files::create;

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
                 PATH_EXISTS        => 102,
                 CREATE_FAILED      => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
               );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get file path (and user)
    my $path = $xmlobj->child('path') ? $xmlobj->child('path')->value : '';
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};

    # get contents
    my $contents = $xmlobj->child('contents') ?
                   $xmlobj->child('contents')->value : '';
    if ($contents) {
        # strip out any carriage returns added to text area contents by browser
        $contents =~ s/\015//g;
        chomp($contents);
        $contents .= "\n";
    }

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

    # build full file path
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
    my ($target_euid, $target_egid);
    if ($vsap->{server_admin}) {
        # set to be the uid of the parent directory
        my $parentpath = $fullpath;
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

    # check quota and if fail if over quota
    unless(diskspace_availability($target_euid, $target_egid, length($contents)))
    {
            $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error creating new file: quota exceeded");
            return;
    }

    # make sure parent directory exists before attempting to create file
    my ($file, $parent_dir) = fileparse($fullpath);
    $parent_dir =~ s/\/+$//g;
    $parent_dir = '/' unless ($parent_dir);
  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily if switching to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        unless (-e $parent_dir) {
            system('mkdir', '-p', '--', $parent_dir)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'CREATE_FAILED'} => "cannot mkdir '$parent_dir' (exitcode $exit)");
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
        $effective_uid = $target_euid;
        $effective_gid = $target_egid;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:create');

    # create the file and save the contents
  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily if switching to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        use open ':utf8';
        open (CFILE, ">$fullpath")
            or do {
                $vsap->error($_ERR{'CREATE_FAILED'} => "Cannot create file: $!");
                VSAP::Server::Modules::vsap::logger::log_error("Cannot create file: $!");
                return;
            };
        # save the contents
        print CFILE $contents if ($contents);
        # shut it down
        close(CFILE);
        # chown newly created file
        chown($target_euid, $target_egid, $fullpath) ||
            warn("chown() failed on $fullpath: $!");
        VSAP::Server::Modules::vsap::logger::log_message("$user created file '$fullpath'");
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

VSAP::Server::Modules::vsap::files::create - VSAP module to create new file

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::create;

=head1 DESCRIPTION

The VSAP create file module allows users to create a new file (one per
request) with user-defined contents.

To create a new file, you need to specify a path name, an optional user
name, and the file contents (also optional).  The following example
generically represents the structure of a typical create file request:

  <vsap type="files:create">
    <path>path name</path>
    <user>user name</user>
    <contents>contents</contents>
  </vsap>

System Administrators should use the full path name of a file and need
not ever include the optional user name in a file mode query.  Domain
Administrators should use the "virtual path name" of a file, i.e. the
path name without prepending the home directory where the file resides.
If the file is homed in a one of the Domain Administrator's End Users'
file spaces, then the optional '<user>' node should be used.  End Users
will also need to use a "virtual path name" to a file; no '<user>'
specification is required, as the authenticated user name is presumed.
The value of the '<contents>' node, if defined, will be stored in the
newly created file.

Consider the following examples:

=over 2

A request made by System Administrator to create a new file.

    <vsap type="files:create">
      <path>/usr/tmp/bob.txt</path>
      <contents>I'm sailing!</contents>
    </vsap>

A request made by a Domain Administrator or End User to create a file
homed in their own home directory.

    <vsap type="files:create">
      <path>/mystuff/photos/caption.txt</path>
      <contents>(this space intentionally left blank)
      </contents>
    </vsap>

A request made by a Domain Administrator to create a file homed in the
directory space of an End User.

    <vsap type="files:create">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
      <contents>
         all day every day
         i taste the tabasco sauce
         my lips are burning
      </contents>
    </vsap>

=back

If the path name is accessible (see NOTES), the new file will be created
or an error will be returned.  A successful update will be indicated by
the return '<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to
the file system, therefore the validity of the path name is only
determined whether it exists or not.  However, End Users are restricted
access (or 'jailed') to their own home directory tree.  Domain
Administrators are likewise restricted, but to the home directory trees
of themselves and their end users.  Any attempts to get information
about or modify properties of files that are located outside of these
valid directories will be denied and an error will be returned.

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

