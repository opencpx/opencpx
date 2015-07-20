package VSAP::Server::Modules::vsap::files::delete;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = ( 
                 NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 CANT_OPEN_PATH     => 102,
                 DELETE_FAILED      => 103,
                 INVALID_USER       => 104,
               );

##############################################################################

sub handler {
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get all non-empty paths
    my @paths = ($xmlobj->children('path') ?
                 grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('path') : () );

    # get domain admin or enduser for which the paths are presumed to be homed;
    # this obviously implies that _all_ paths must be homed in said directory.
    # non-homogeneous path deletion is not permitted for domain admins.
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};

    if ($#paths == -1) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source paths required");
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
    my ($path, $fullpath, $source_euid, $source_egid, %bitbucket);
    for $path (@paths) {
        # fix up the path
        $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
        $path = canonpath($path);
        # build full source path
        $fullpath = $path;
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
        # check authorization to access source path
        my $authorized = 0;
        my $parentuser = "";
        foreach $validuser (keys(%valid_paths)) {
            my $valid_path = $valid_paths{$validuser};
            if ($fullpath eq $valid_path) {
                # can't delete home directories
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
        $bitbucket{$path}->{'fullpath'} = $fullpath;
        $bitbucket{$path}->{'euid'} = $source_euid;
        $bitbucket{$path}->{'egid'} = $source_egid;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:delete');

    # delete all paths
    my $success_node = "";
    my $failure_node = "";
    my ($path_node, $mesg);
    my ($effective_uid, $effective_gid);
    for $path (keys(%bitbucket)) {
        $fullpath = $bitbucket{$path}->{'fullpath'};
        $source_euid = $bitbucket{$path}->{'euid'};
        $source_egid = $bitbucket{$path}->{'egid'};
        # figure out who is going to execute the command for this path
        if ($vsap->{server_admin}) {
            # give plenty of rope
            $effective_uid = 0;
            $effective_gid = 0;
        }
        else {
            $effective_uid = $source_euid;
            $effective_gid = $source_egid;
        }
      EFFECTIVE: {
            local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
            local $) = $effective_gid;
            local $> = $effective_uid;
            if (-d "$fullpath") {
                # delete the directory using rm()
                system('rm', '-rf', '--', $fullpath)
                  and do {
    		      my $exit = ($? >> 8);
                      $mesg = "An error occured while deleting '$fullpath' (exitcode $exit)";
                      warn($mesg);
                      VSAP::Server::Modules::vsap::logger::log_error($mesg);
                      unless ($failure_node) {
                          $failure_node = $root_node->appendChild($dom->createElement('failure'));
                      }
                      $path_node = $failure_node->appendChild($dom->createElement('path'));
                      $path_node->appendTextChild(name => $path);
                      $path_node->appendTextChild(code => $_ERR{'DELETE_FAILED'});
                      $path_node->appendTextChild(mesg => $mesg);
                      next;
    	          };
                VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} deleted '$fullpath'");
                # add path to success node
                unless ($success_node) {
                    $success_node = $root_node->appendChild($dom->createElement('success'));
                }
                $path_node = $success_node->appendChild($dom->createElement('path'));
                $path_node->appendTextChild(name => $path);
                $path_node->appendTextChild(type => "dir");
                $path_node->appendTextChild(status => "ok");
            }
            else {
                # use perl built-in unlink() function for everything else
                unlink($fullpath)
                  or do {
                      $mesg = "unlink '$fullpath' failed: $!";
                      warn($mesg);
                      VSAP::Server::Modules::vsap::logger::log_error($mesg);
                      unless ($failure_node) {
                          $failure_node = $root_node->appendChild($dom->createElement('failure'));
                      }
                      $path_node = $failure_node->appendChild($dom->createElement('path'));
                      $path_node->appendTextChild(name => $path);
                      $path_node->appendTextChild(code => $_ERR{'DELETE_FAILED'});
                      $path_node->appendTextChild(mesg => $mesg);
                      next;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} deleted '$fullpath'");
                # add path to success node
                unless ($success_node) {
                    $success_node = $root_node->appendChild($dom->createElement('success'));
                }
                $path_node = $success_node->appendChild($dom->createElement('path'));
                $path_node->appendTextChild(name => $path);
                $path_node->appendTextChild(type => "file");
                $path_node->appendTextChild(status => "ok");
            }
        }
    }

    # add user to dom
    $root_node->appendTextChild(user => $user);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::delete - VSAP module to delete one or
more files

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::delete;

=head1 DESCRIPTION

The VSAP delete module allows users to delete one or more specified
files.

To delete a file, you need to specify one or more path names and an
optional user name.  The following example generically represents the
structure of a typical delete file request:

  <vsap type="files:delete">
    <path>path name</path>
    <path>path name</path>
    <path>path name</path>
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

A request made by System Administrator to delete several files:

    <vsap type="files:delete">
      <path>/var/log/maillog.0.gz</path>
      <path>/var/log/maillog.1.gz</path>
      <path>/var/log/maillog.2.gz</path>
      <path>/var/log/maillog.3.gz</path>
    </vsap>

A request made by a Domain Administrator or End User to delete files
homed in their own home directory.

    <vsap type="files:delete">
      <path>/mystuff/photos/my_cats.jpg</path>
      <path>/mystuff/photos/my_dogs.jpg</path>
      <path>/mystuff/photos/my_gerbils.jpg</path>
    </vsap>

A request made by a Domain Administrator to delete files homed in the
directory space of an End User.

    <vsap type="files:delete">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
      <path>/www/data/my_life_as_a_tabasco_pepper.html</path>
      <path>/www/data/tabasco_bottle.jpg</path>
    </vsap>

=back

If the files are valid and accessible (see NOTES), they will be deleted.
Successful requests to delete files will be indicated in the return
'<success>' node; whereas, failed requests to delete files will be
appended to the '<failure>' node.  It is possible that some files may be
deleted successfully while others fail.

The following illustrates the basic form of the data returned from a
delete file request:

  <vsap type="files:delete">
    <user>user name</user>
    <success>
      <path>
         <file>path name</file>
         <type>dir|file</type>
      </path>
      <path>
         <file>path name</file>
         <type>dir|file</type>
      </path>
      <path>
        .
        .
        .
      </path>
    </success>
    <failure>
      <path>
         <file>path name</file>
         <code>system exit code</code>
         <mesg>description of failure</mesg>
      </path>
      <path>
         <file>path name</file>
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

rm(1)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

