package VSAP::Server::Modules::vsap::files::properties;

use 5.008004;
use strict;
use warnings;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED          => 100,
                 CANT_OPEN_PATH          => 101,
                 INVALID_PATH            => 102,
                 QUOTA_EXCEEDED          => 103,
                 CANNOT_WRITE_CONTENTS   => 104,
                 INVALID_USER            => 105,
               );

# suggested thumbnail WIDTHxHEIGHT constraints
my $MAX_THUMBNAIL_WIDTH = 400;
my $MAX_THUMBNAIL_HEIGHT = 250;

##############################################################################

package VSAP::Server::Modules::vsap::files::properties;

use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Basename qw(fileparse);
use File::Spec::Functions qw(canonpath catfile);
use LWP::UserAgent;

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::domain qw(get_docroot_all);
use VSAP::Server::Modules::vsap::files qw(build_file_node sanitize_path url_encode url_escape diskspace_availability);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::string::encoding qw(guess_string_encoding);

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $path = $xmlobj->child('path') ? $xmlobj->child('path')->value : '';
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};

    my $set_contents = $xmlobj->child('set_contents') ?
                       $xmlobj->child('set_contents')->value : '';

    unless ($path) {
        $vsap->error( $_ERR{'INVALID_PATH'} => "path undefined");
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

    # get the file name and the parent path
    my ($file, $parent_dir) = fileparse($fullpath);
    $parent_dir =~ s/\/+$//g;
    $parent_dir = '/' unless ($parent_dir);

    # start building the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'files:properties');

    # append path information
    $root_node->appendTextChild('path', $path);
    $root_node->appendTextChild('user', $user);

    # append url encoded path
    my $url_encoded_path = url_encode($path);
    $root_node->appendTextChild('url_encoded_path', $url_encoded_path);

    # append url escaped path
    my $url_escaped_path = url_escape($path);
    $root_node->appendTextChild('url_escaped_path', $url_escaped_path);

    # set the contents if so specified
    if ($set_contents) {
        # check if over quota
        # will the -e require REWT?  probably not... -michael
        if (-e "$fullpath") {
                    my ($size) = (lstat("$fullpath"))[7];
                    unless(diskspace_availability($effective_uid, $effective_gid, (length($set_contents) - $size)))
                    {
                        # the increased size of the file will put the user over quota
                        $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error editing file: quota exceeded");
                        return;
                    }
        }
        else {
                    unless(diskspace_availability($effective_uid, $effective_gid, length($set_contents)))
                    {
                        # the new file will put the user over quota
                        $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error editing file: quota exceeded");
                        return;
                    }
        }

        # strip out any carriage returns added to text area contents by browser
        $set_contents =~ s/\015//g;
        chomp($set_contents);
        $set_contents .= "\n";

        # make sure the user has permission
      EFFECTIVE: {
            local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
            local $) = $effective_gid;
            local $> = $effective_uid;
            unless (-w "$fullpath") {
                $vsap->error($_ERR{'CANNOT_WRITE_CONTENTS'} => "Error editing file: not writable by user");
                return;
            }

            open (CFILE, ">$fullpath")
                or do {
                    $vsap->error($_ERR{'CANNOT_WRITE_CONTENTS'} => "Cannot write contents: $!");
                    return;
                };
            print CFILE $set_contents;
            close CFILE;
        }

        $root_node->appendTextChild(set_contents_status => 'ok');
    }

    # append file properties for file to dom
    my $mime_type;
    $mime_type = build_file_node($vsap, $root_node, $parent_dir, $file,
                                 $effective_uid, $effective_gid, $lfm);

    # append document root info (if applicable)
    my $documentroot = "";
    my $domainparent = "";
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my %docpaths = VSAP::Server::Modules::vsap::domain::get_docroot_all();
        foreach my $vhost (keys(%docpaths)) {
            my $curdocroot = abs_path($docpaths{$vhost});
            if ($parent_dir =~ /^$curdocroot/) {
                my $path_length = length($curdocroot);
                if ($path_length > length($documentroot)) {
                    $documentroot = $curdocroot;
                    $domainparent = $vhost;
                }
            }
        }
    }
    if ($documentroot) {
        my $relpath = $parent_dir;
        $relpath =~ s/^$documentroot//;
        $relpath = "/" . $relpath unless ($relpath =~ m#^/#);
        $relpath = $relpath . "/" unless ($relpath =~ m#/$#);
        if (!$vsap->{server_admin} || $lfm) {
            $documentroot =~ s#^\Q$valid_paths{$user}\E(/|$)#/#;
        }
        # check http status
        my $ua = LWP::UserAgent->new;
        $ua->agent("Tabasco/0.9 (vsapd; LWP::UserAgent; $^O)");
        $ua->timeout(5);
        my $url = 'http://' . $domainparent . $relpath . $file;
        my $response = $ua->head($url);
        my $return_code = $response->{_rc};
        # append to dom
        if ($return_code != 403) {
            $root_node->appendTextChild('documentroot', $documentroot);
            $root_node->appendTextChild('documentroot_domain', $domainparent);
            $root_node->appendTextChild('documentroot_relativepath', $relpath);
        }
    }

    # append parent dir info (chroot parent_dir if necessary)
    if (!$vsap->{server_admin} || $lfm) {
        $parent_dir =~ s#^\Q$valid_paths{$user}\E(/|$)#/#;
    }
    $root_node->appendTextChild('parent_dir', $parent_dir);

  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        if ((-f $fullpath) && ((-T $fullpath) || ($mime_type =~ /^text/)) && ($fullpath !~ /\.pdf$/i)) {
            # fetch file contents for text files under 1MB
            my $contents_node = $root_node->appendChild($dom->createElement('contents'));
            my $contents = "";

            if ((stat($fullpath))[7] <= (1024 * 1024)) {
                open (FILE, '<', $fullpath);
                while (<FILE>) {
                    $contents .= $_;
                }
                close FILE;
                $contents = guess_string_encoding($contents);
                $contents_node->appendText($contents);
            }
            else {
                $contents_node->setAttribute('large', 'yes');
            }
        }
    }

    if ($fullpath =~ /\.(bmp|gif|jpe|jpeg|jpg|png)$/i) {
        # get some info from ImageMagick's identify() and append to dom
        my ($img_info, $img_width, $img_height, $thumb_type);
        $img_info = $thumb_type = "";
        $img_width = $img_height = 0;
      EFFECTIVE: {
            local $> = $effective_uid;
            unless (open(IDENTIFY, "identify $fullpath |")) {
                warn "identify() for '$fullpath' failed: $!";
            }
            else {
                $img_info = <IDENTIFY>;
                close(IDENTIFY);
                if ($img_info =~ /^\S+\s(\S+)\s([0-9]*)x([0-9]*)\s/) {
                    $thumb_type = "image/" . $1;
                    $thumb_type =~ tr/A-Z/a-z/;
                    $img_width = $2;
                    $img_height = $3;
                }
            }
        }
        if ($img_height && $img_width) {
            # build a thumbnail
            my $scale_width = $img_width / $MAX_THUMBNAIL_WIDTH;
            my $scale_height = $img_height / $MAX_THUMBNAIL_HEIGHT;
            my $scale = ($scale_width > $scale_height) ? $scale_width : $scale_height;
            my ($thumb, $thumb_width, $thumb_height);
            if ($scale < 1) {
                $thumb_width = $img_width;
                $thumb_height = $img_height;
            }
            else {
                $thumb_width = int(($img_width / $scale) + 0.5);
                $thumb_height = int(($img_height / $scale) + 0.5);
            }
            $root_node->appendTextChild('image_width', $img_width);
            $root_node->appendTextChild('image_height', $img_height);
            $root_node->appendTextChild('thumb_type', $thumb_type);
            $root_node->appendTextChild('thumb_width', $thumb_width);
            $root_node->appendTextChild('thumb_height', $thumb_height);
            # write thumbnail out to temporary file
            my $resize_arg = $thumb_width . "x" . $thumb_height;
            my $thumb_ext = $thumb_type;
            $thumb_ext =~ s#image\/#\.#;
            my $thumb_path = $vsap->{tmpdir} . "/";
            $thumb_path .= time() . "-" . $$ . "_thumb" . $thumb_ext;
            my(@convertcommand);
            push(@convertcommand, "convert");
            push(@convertcommand, $fullpath);
            push(@convertcommand, "-resize");
            push(@convertcommand, $resize_arg);
            push(@convertcommand, $thumb_path);
            system(@convertcommand)
                and do {
                    my $exit = ($? >> 8);
                    warn("build thumbnail failed for '$fullpath' (exitcode $exit)");
                };
            # make sure group ownership is set so thumb can be read/unlinked
            system('chgrp', $VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP, $thumb_path)
                and do {
                    my $exit = ($? >> 8);
                    warn("chgrp() failed on '$thumb_path' (exitcode $exit)");
                };
            # make sure g+r perms are set so thumb can be read/unlinked
            system('chmod', 'g+rw', $thumb_path)
                and do {
                    my $exit = ($? >> 8);
                    warn("chmod() failed on '$thumb_path' (exitcode $exit)");
                };
            # clean up thumbnail path and append to dom
            if (!$vsap->{server_admin} || $lfm) {
                $thumb_path =~ s#^\Q$valid_paths{$user}\E(/|$)#/#;
                # if domain admin is viewing end user file, this is necessary
                $thumb_path =~ s#^\Q$vsap->{homedir}\E(/|$)#/#;
            }
            $root_node->appendTextChild('thumb_path', $thumb_path);
        }
    }
    elsif ($fullpath =~ /\.(bz|bz2|gz|tar|taz|tbz|tbz2|tgz|zip|Z)$/i) {
        # get a list of compressed and/or archived paths from the file.
        #
        # bz      = bzip2 compressed single file
        # bz2     = bzip2 compressed single file
        # gz      = gzip compressed single file
        # tar     = tar archive
        # taz     = Lempel-Ziv compressed tar archive (also .tar.Z)
        # tbz     = bzip2 compressed tar archive (also .tar.tbz)
        # tbz2    = bzip2 compressed tar archive (also .tar.tbz2)
        # tgz     = gzip compressed tar archive (also .tar.gz)
        # zip     = zip archive
        # Z       = Lempel-Ziv compressed file
        #
        my %archinfo = ();
        my ($curline, $size, $fpath, $type);
        if ($fullpath =~ /\.zip$/i) {
            # get list of files via zipinfo system command
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                unless (open(ZIPINFO, "zipinfo \"$fullpath\" |")) {
                    warn "zipinfo() for '$fullpath' failed: $!";
                }
                else {
                    <ZIPINFO>;  # throw out header line
                    while (<ZIPINFO>) {
                        next if (/number of entries:/);
                        last if (/uncompressed,/ && (/compressed:/));
                        $curline = $_;
                        chomp($curline);
                        $curline =~ /^\S+\s+\S+\s+\S+\s+([0-9]*)/;
                        $size = $1;
                        $curline =~ /\s(\S+?)$/;
                        $fpath = $1;
                        $fpath =~ s/\#U([0-9a-fA-F]{4})/chr(hex($1))/eg;
                        $type = ($fpath =~ m#/$#) ? "dir" : "file";
                        $archinfo{$fpath}->{'size'} = $size;
                        $archinfo{$fpath}->{'type'} = $type;
                    }
                    close(ZIPINFO);
                }
            }
        }
        elsif (($fullpath =~ /\.(tar|taz|tbz|tbz2|tgz)$/i) ||
               ($fullpath =~ /\.tar\.(gz|bz|bz2|Z)$/i)) {
            # get list of files via tar system command
            my ($tar) = "tar -t -v ";
            if (($fullpath =~ /\.taz$/i) || ($fullpath =~ /\.tar\.Z$/i)) {
                $tar .= "-Z ";
            }
            elsif (($fullpath =~ /\.(tbz|tbz2)$/i) || ($fullpath =~ /\.tar\.(bz|bz2)$/i)) {
                $tar .= "-j ";
            }
            elsif (($fullpath =~ /\.tgz$/i) || ($fullpath =~ /\.tar\.gz$/i)) {
                $tar .= "-z ";
            }
            $tar .= "-f \"$fullpath\"";
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                unless (open(TARINFO, "$tar |")) {
                    warn "tar() for '$fullpath' failed: $!";
                }
                else {
                    while (<TARINFO>) {
                        $curline = $_;
                        chomp($curline);
                        if ($curline =~ /^\S+\s+[0-9]+\s+\S+\s+\S+\s+([0-9]*)/) {
                            $size = $1;
                        }
                        elsif ($curline =~ /^\S+\s+\S+\s+([0-9]*)/) {
                            $size = $1;
                        }
                        else {
                            $size = 0;
                        }
                        $curline =~ /\s(\S+?)$/;
                        $fpath = $1;
                        $type = ($fpath =~ m#/$#) ? "dir" : "file";
                        $fpath =~ s{\\([0-9][0-9][0-9])}{chr(oct($1))}eg;
                        $archinfo{$fpath}->{'size'} = $size;
                        $archinfo{$fpath}->{'type'} = $type;
                    }
                    close(TARINFO);
                }
            }
        }
        else {
            # single compressed file
            $fpath = $file;
            $fpath =~ s/\.(bz|bz2|gz|Z)$//i;
            $archinfo{$fpath}->{'type'} = "file";
            if (($fullpath =~ /\.Z$/i)) {
                # not sure how to determine uncompressed size... skip for now
            }
            elsif ($fullpath =~ /\.(bz|bz2)$/i) {
                # not sure how to determine uncompressed size... skip for now
            }
            elsif ($fullpath =~ /\.gz$/i) {
              EFFECTIVE: {
                    local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                    local $) = $effective_gid;
                    local $> = $effective_uid;
                    unless (open(GZIP, "gzip -l $fullpath |")) {
                        warn "gzip() for '$fullpath' failed: $!";
                    }
                    else {
                        <GZIP>;  # throw out header line
                        $curline = <GZIP>;
                        $curline =~ s/^\s+//;
                        $curline =~ /\S+\s+([0-9]*)/;
                        $archinfo{$fpath}->{'size'} = $1;
                        close(GZIP);
                    }
                }
            }
        }
        my @archpaths = sort(keys(%archinfo));
        if ($#archpaths >= 0) {
            # append all of the file archive info to the dom
            my $arch_node = $root_node->appendChild($dom->createElement('archive_contents'));
            foreach my $archpath (@archpaths) {
                next if ($archinfo{$archpath}->{'type'} eq "dir");
                # append file name and size information to contents node
                my $child_node = $arch_node->appendChild($dom->createElement('file'));
                $child_node->appendTextChild('name', $archpath);
                $child_node->appendTextChild('size', $archinfo{$archpath}->{'size'});
                # add parent path
                my ($archfilename, $archparent) = fileparse($archpath);
                $archparent = './' unless ($archparent);
                $child_node->appendTextChild('path', $archparent);
                # add encoded and escape filenames
                my $url_encoded_name = url_encode($archpath);
                my $url_escaped_name = url_escape($archpath);
                $child_node->appendTextChild('url_encoded_name', $url_encoded_name);
                $child_node->appendTextChild('url_escaped_name', $url_escaped_name);
            }
        }
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::properties::type;

use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Basename qw(fileparse);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path);
use VSAP::Server::Modules::vsap::globals;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $path = $xmlobj->child('path') ? $xmlobj->child('path')->value : '';
    my $user = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                $xmlobj->child('user')->value : $vsap->{username};

    unless ($path) {
        $vsap->error( $_ERR{'INVALID_PATH'} => "path undefined");
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
    my $link_followed = 0;
    if (-l "$fullpath") {
        # follow the link back to the target
        $link_followed = 1;
        my($linktarget) = readlink($fullpath);
        if ($linktarget =~ m#^/#) {
            $fullpath = $linktarget;
        }
        else {
            my($linkname, $linkpath) = fileparse($fullpath);
            $fullpath = canonpath(catfile($linkpath, $linktarget));
        }
    }
    $fullpath = decode_utf8(abs_path($fullpath)) || sanitize_path($fullpath);

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
    my ($type);
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath) {
            $type = (-d $fullpath) ? "dir" : "file";
        }
        else {
            $vsap->error($_ERR{'CANT_OPEN_PATH'} => "can't open path: $fullpath");
            return;
        }
    }

    # chroot fullpath if necessary (before appending to dom)
    if (!$vsap->{server_admin} || $lfm) {
        $fullpath =~ s#^\Q$valid_paths{$user}\E(/|$)#/#;
    }

    # start building the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'files:properties:type');
    $root_node->appendTextChild('path', $fullpath);
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('link_followed', 1) if ($link_followed);

    # append file type
    $root_node->appendTextChild('type', $type);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::properties - VSAP module to get file
properties

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::properties;

=head1 DESCRIPTION

The VSAP properties module allows users to view basic information about
files including file properties, file contents, and file type.

=head2 files:properties

The VSAP files::properties module allows users to get basic properties
such as size, mode, last modification time, for files.

To get file properties, you need to specify a path name and an optional
user  name.  The following example generically represents the structure
of a typical file properties request:

  <vsap type="files:properties">
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

A request made by System Administrator to get the file properties for a
system file:

    <vsap type="files:properties">
      <path>/var/log/maillog</path>
    </vsap>

A request made by a Domain Administrator or End User to get the file
properties of a file homed in their own home directory structure.

    <vsap type="files:properties">
      <path>/mystuff/photos/my_gerbils.jpg</path>
    </vsap>

A request made by a Domain Administrator to get the file properties of a
file homed in the directory space of an End User.

    <vsap type="files:properties">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
   </vsap>

=back

If the path name is accessible (see NOTES), the properties of the file
will be shown (please see the example below).

  <vsap type="files:properties">
    <user>user name</user>
    <path>path name</path>
    <owner>directory owner user name</owner>
    <group>directory owner group name</group>
    <size>directory size (in bytes)</size>
    <is_writable>0|1</is_writable>
    <is_executable>0|1</is_executable>
    <mtime>
      <sec>0-59</sec>
      <min>0-59</min>
      <hour>0-23</hour>
      <mday>1-31</mday>
      <month>1-12</month>
      <year>4-digit year</year>
      <epoch>long integer value</epoch>
    </mtime>
    <date>
      <year>4-digit year</year>
      <month>1-12</month>
      <day>1-31</day>
      <hour>1-12</hour>
      <hour12>1-23</hour12>
      <minute>1-59</minute>
      <second>1-59</second>
      <o_year>4-digit year</o_year>
      <o_month>1-12</o_month>
      <o_day>1-31</o_day>
      <o_hour>1-12</o_hour>
      <o_hour12>1-23</o_hour12>
      <o_minute>1-59</o_minute>
      <o_second>1-59</o_second>
      <o_offset>time zone offset</o_offset>
    </date>
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
    <octal_mode>octal number between 0000-7777</octal_mode>
    <symbolic_mode>rwxrwxrwx</symbolic_mode>
    <parent_dir>path name</parent_dir>
    <name>file name</name>
    <type>file type</type>
    <contents>text string</contents>
  </vsap>

The file's path name and file's user name values will mirror that
which was supplied by the query.  The file ownership vector, user and
group, is noted in the '<owner>' and '<group>' nodes respectively.
The file size is simply the size of the file (in bytes).  The
'<is_writable>' node will be set to "yes" or "no" depending on
whether the authenticated user has write privileges to the file;
likewaise, the '<is_executable>' node will be set to "yes" or "no"
depending on whether the authenticaed user has execute privileges for
the file.

The '<mtime>' node is populated with the year, month, day of the
month (mday), hour, min, and second that the file was last
modified.  The last modification time is also included as the number
of seconds elapsed since the Epoch (in the appropriately named
'<epoch>' node).

The '<date>' node also represents the file last modification date but
in the timezone of the user's preference.  The original unmodified
time parameters are also included (and should be identical to their
<mtime> counterparts).

The '<mode>' node is the file mode representation split into '<owner>',
'<group>', and '<world>' bits.  Each '<owner>', '<group>', and '<world>'
subnode will have a '<read>', '<write>', and '<execute>' child that
can be either 0 or 1.  The '<owner>' subnode also will include a
'<setuid>' child which will indicate whether or not the file is
setuid.  Likewise, the '<group>' subnode also will include a '<setgid>'
child which will indicate whether or not the file is setgid.  And
furthermore, the '<world>' subnode will include a '<sticky>' child set
if the sticky bit on the file is set.

The '<octal_node>' is the string based representation of the octal mode
of the file ("0664", "0644", "0600", etc).  The '<symbolic_node>'
is a string based representation of the file mode in the "rwx" fashion
(e.g. "rw-rw-r--", "rw-r--r--", etc).

The '<parent_dir>' node contains the full path to the parent directory
of the file made in the query.

The '<name>' node contains simply the file name.  The values for the
'<type>' node can be one of: "socket" : "named pipe (FIFO)", "tty",
"block special file", "character special file", "dirlink", "symlink",
"dir", "text", "binary", or "plain".

If the file '<type'> is "text" and if the file size is under 1024 bytes,
then the '<contents>' node will contain the contents of the file.

If the path name was not found or if the path name is not accessible, an
error will be returned.

=head2 files:properties:type

The VSAP files::properties:type module allows users to quickly retrieve
the "type" of a file given a specified pathname.  The type returned can
be one of two values: "dir" or "file".

To get the file type, you need to specify a path name and an optional
user name.  The following example generically represents the structure
of a typical file type request:

  <vsap type="files:properties:type">
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

A request made by System Administrator to get the file type of a
system file:

    <vsap type="files:properties:type">
      <path>/var/log/maillog</path>
    </vsap>

A request made by a Domain Administrator or End User to get the file
type of a file homed in their own home directory structure.

    <vsap type="files:properties:type">
      <path>/mystuff/photos/my_gerbils.jpg</path>
    </vsap>

A request made by a Domain Administrator to get the file type of a
file homed in the directory space of an End User.

    <vsap type="files:properties:type">
      <user>scott</user>
      <path>/www/data/ode_to_tabasco.html</path>
   </vsap>

=back

If the path name is accessible (see NOTES), the type of the file will
be returned.  If a link was resolved from the path submitted, then a
'<link_followed>' node will be included in the output (please see the
sample below).

  <vsap type="files:properties">
    <user>user name</user>
    <path>path name</path>
    <type>dir|file</type>
    <link_followed/>
  </vsap>

If the path name was not found or if the path name is not accessible, an
error will be returned.

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

