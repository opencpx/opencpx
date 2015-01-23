package VSAP::Server::Modules::vsap::files::download;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(get_mime_type sanitize_path);
use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.01';

our %_ERR    = ( NOT_AUTHORIZED          => 100,
                 CANT_OPEN_PATH          => 101,
                 INVALID_PATH            => 102,
                 DOWNLOAD_FAILED         => 103,
                 INVALID_USER            => 104,
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

    # download format type 
    my $format = $xmlobj->child('format') ? 
                 $xmlobj->child('format')->value : '';

    # requester's user agent
    my $user_agent = $xmlobj->child('user_agent') ? 
                     $xmlobj->child('user_agent')->value : '';

    unless ($path) {
        $vsap->error( $_ERR{'INVALID_PATH'} => "path undefined");
        return;
    }

    # fix up the path
    $path = "/" . $path unless ($path =~ m{^/});    # prepend with /
    $path = canonpath($path);

    unless ($format) {
        $format = "download";
    }
    unless (($format eq "download") || ($format eq "print")) {
        $format = "download";
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
        # add web administrator
        my $webadmin = ( $vsap->is_linux() ) ? "apache" : "webadmin";
        push(@ulist, $webadmin);
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
        if (($fullpath =~ m#^\Q$valid_path\E/#) ||
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
    my ($source_euid, $source_egid, $fsize, $ftype);
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath || -l $fullpath) {
            $ftype = ((-T $fullpath) && 
                      ($fullpath !~ /\.pdf$/)) ? "text" : "binary";
            ($fsize) = (lstat($fullpath))[7];
            if ($vsap->{server_admin}) {
                # give plenty of rope
                $source_euid = 0;
                $source_egid = 0;
            }
            else {
                # set effective uid/gid to default value
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

    # get the filename, extension, and mime_type
    my ($filename) = fileparse($fullpath);
    $filename =~ m{\.([^\./]*)$};
    my $extension = lc($1);
    my ($mime_type) = get_mime_type($extension) ||
                (($ftype eq "binary") ? "application/octet-stream" :
                                        "text/plain");  

    # create encoded filename
    my $enc_filename = $filename;
    if ($filename =~ m![^\011\012\015\040-\176]!) {
        utf8::encode($enc_filename);
        $enc_filename =~ s/([^\011\012\015\040-\176])/uc sprintf("%%%02x",ord($1))/eg;
        $enc_filename = "utf-8''" . $enc_filename;
    }
    else {
        $enc_filename = "us-ascii'en-us'" . $enc_filename
    }

    # if not "printing" the file, reset mime type to a non-standard value
    if ($format eq "download") {
        $mime_type = "application/x-download";
    }

    # figure out who is going to own the target
    my ($target_euid, $target_egid);
    $target_euid = $vsap->{uid};
    $target_egid = $vsap->{gid};

    # build the download path
    my $downloadpath = "";
    my ($effective_uid, $effective_gid);
    if ($fullpath =~ m#^\Q$vsap->{tmpdir}\E/#) {
        # file already in users tmpdir (probably a thumbnail);
        # no need to create a link to file, just use path to file
        $downloadpath = $fullpath;
    }
    if ($downloadpath eq "") {
        # make a hard link in tmpdir to file
        $downloadpath = $vsap->{tmpdir} . "/";
        $downloadpath .= time() . "-" . $$ . ".download";
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
    }

    # determine if we should make a link to the file in cpx_tmp or if we
    # should make a copy of the file.  making a link to the file is nice
    # because no additional disk space is required (and much less time
    # is required as opposed to copying a file).  in order to determine 
    # if a link can be made, see if the file has perms that would allow
    # the apache owner to access it.  if no such access is allowed (not
    # world readable by the apache user), then copy the file (BUG05857).
    my $link_file = 0;
    my $apache_user = $vsap->is_linux() ? "apache" : "www";
    my $apache_group = $vsap->is_linux() ? "apache" : "www";
    my ($apache_uid, $apache_gid) = (getpwnam($apache_user))[2,3];
  CHECK_ACCESS: {
          local $> = $) = 0;  ## regain privileges for a moment
          my ($fmode, $owner_uid, $owner_gid) = (lstat($fullpath))[2,4,5];
          if (($owner_uid == $apache_uid) ||
              (($owner_gid == $apache_gid) && ($fmode & 040)) ||
              ($fmode & 04)) {
              $link_file = 1;
          }
    }

    # if requester user agent is "Windows" and download target is text,
    # then copy file for now.  after the copy is complete, then we will
    # parse the file and convert EOL from '\r\n' to '\n' (BUG11277)
    if (($user_agent =~ /Windows/) && ($ftype eq "text")) {
        $link_file = 0;
    }

    unless ($downloadpath eq $fullpath) {
        if ($link_file) {
            # make a link to the file in cpx_tmp
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                link($fullpath, $downloadpath) 
                    or do {
                        $vsap->error($_ERR{'DOWNLOAD_FAILED'} => "create link failed: $!");
                        VSAP::Server::Modules::vsap::logger::log_error("create link for download failed: $!");
                        return;
                    };
            }
        }
        else {
            # copy the file to cpx_tmp
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                system('cp', $fullpath, $downloadpath) 
                    and do {
                        my $exit = ($? >> 8);
                        warn("cp($fullpath, $downloadpath) failed... (exitcode $exit)");
                        $vsap->error($_ERR{'DOWNLOAD_FAILED'} => "copy source failed: $!");
                        VSAP::Server::Modules::vsap::logger::log_error("copy source for download failed: $!");
                        return;
                    };
                # if requester user agent is "Windows" and download target is text,
                # parse the file and convert EOL from '\r\n' to '\n' (BUG11277)
                if (($user_agent =~ /Windows/) && ($ftype eq "text")) {
                    my $tmpfilepath = $downloadpath . ".tmp";
                    open(NEWFP, ">$tmpfilepath");
                    open(OLDFP, "$downloadpath");
                    while (<OLDFP>) {
                       s/\n$/\r\n/ unless (/\r\n$/);
                       print NEWFP $_;
                    }
                    close(OLDFP);
                    close(NEWFP);
                    rename($tmpfilepath, $downloadpath);
                }
            }
            # set perms and ownership so file can be read/unlinked
          REWT: {
              local $> = $) = 0;  ## regain privileges for a moment
              system('chgrp', $apache_group, $downloadpath)
                  and do {
                      my $exit = ($? >> 8);
                      warn("chgrp() failed on '$downloadpath' (exitcode $exit)");
                  };
              system('chmod', 'g+rw', $downloadpath)
                  and do {
                      my $exit = ($? >> 8);
                      warn("chmod() failed on '$downloadpath' (exitcode $exit)");
                  };
            }
        }
    }

    # log happy result
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} requested to download '$fullpath'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'files:download');
    $root_node->appendTextChild('format', $format);
    $root_node->appendTextChild('filename', $filename);
    $root_node->appendTextChild('url_filename', $filename);
    $root_node->appendTextChild('enc_filename', $enc_filename);
    $root_node->appendTextChild('mime_type', $mime_type);
    $root_node->appendTextChild('path', $downloadpath);
    $root_node->appendTextChild('source', $fullpath);
    $root_node->appendTextChild('size', $fsize);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
    
1;
    
__END__
        
=head1 NAME

VSAP::Server::Modules::vsap::files::download - VSAP module to "download"
a single file
    
=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::download;
    
=head1 DESCRIPTION 
    
The VSAP download file module allows users to "download" a file (one 
per request).  The name "download" is something of a misnomer since 
this module does nothing more than create a hard link or copy the file
in the user's VSAP temporary directory (vsap->{tmpdir}).

To "download" a file, you need to specify a path name, an optional user
name, and the "format" preferred.  The following example generically
represents the structure of a typical create file request:

  <vsap type="files:download">
    <path>path name</path>
    <user>user name</user>
    <format>[download|print]</format>
  </vsap>

System Administrators should use the full path name of a file and need
not ever include the optional user name in a file mode query.  Domain
Administrators should use the "virtual path name" of a file, i.e. the
path name without prepending the home directory where the file resides.
If the file is homed in a one of the Domain Administrator's End Users'
file spaces, then the optional '<user>' node should be used.  End Users
will also need to use a "virtual path name" to a file; no '<user>'
specification is required, as the authenticated user name is presumed.

The value of the '<format>' node, must either be "download" or "print".
This value determines the mime-type that will be returned with the 
file download.  If the format specified is "download", then the returned
mime-type will be set to a value of "application/x-download".  If the
value for the format node is set to "print", then the mime-type will be
determined by matching the file extension of the the path name specified
to the list of mime extensions found in the system "mime.types" file.

Consider the following examples:

=over 2

A request made by System Administrator to "download" a system file.

    <vsap type="files:download">
      <path>/usr/local/share/doc/mutt/manual.txt</path>
      <format>print</format>
    </vsap>

A request made by a Domain Administrator or End User to "download" a 
file home in their own home directory.

    <vsap type="files:download">
      <path>/mystuff/photos/my_cats.jpg</path>
      <format>download</format>
    </vsap>

A request made by a Domain Administrator to "download" a file homed in 
the directory space of an End User.

    <vsap type="files:download">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
      <format>print</format>
    </vsap>

=back

If the path name is accessible (see NOTES), a hard link or copy of the
file will be created, and an appropriate mime-type will be returned 
(please see the example below).  

  <vsap type="files:download">
    <format>[download|print]</format>
    <filename>file name</filename>
    <mime_type>mime type</filename>
    <path>download path name</path>
    <source>original path name</source>
    <size>size of file in bytes</size>
  </vsap>

The '<path>' node specifies the path name to the hard link created to
or copy of the "source" file.  The link or copy is created in the 
user's temporary VSAP directory (vsap->{tmpdir}).

If the "download" operation was unsuccessful or the file is inaccessible, 
an error will be returned.

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

