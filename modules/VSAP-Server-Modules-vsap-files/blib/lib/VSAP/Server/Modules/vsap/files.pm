package VSAP::Server::Modules::vsap::files;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path cwd);
use File::Spec::Functions qw(canonpath);

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::string::encoding;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(build_file_node
                    get_mime_type
                    mode_octal
                    mode_symbolic
                    sanitize_path
                    tmp_dir_housekeeping
                    url_encode
                    url_escape
                    diskspace_availability);

our $VERSION = '0.01';

use constant IS_LINUX => ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
our $lowUID = ( IS_LINUX ) ? 500 : 1001;  ## lowest non-system UID

our $MIME_TYPES = (-e "/etc/mime.types") ? "/etc/mime.types" : "/www/conf/mime.types";

##############################################################################
#
# build_file_node() 
#
# called from vsap::files::list and vsap::files::properties
#

sub build_file_node 
{
    my $vsap = shift;
    my $file_node = shift;
    my $path = shift;
    my $file = shift;
    my $euid = shift;
    my $egid = shift;
    my $lfm = shift;  ## limited file manager for server admin

    my $dom = $vsap->dom;

    my ($is_readable, $is_writable, $is_executable);
    my ($type, $mode, $uid, $gid, $size, $mtime);
    my ($target, $target_path, $target_name, $target_type);
    my $test_characters = "";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $egid;
        local $> = $euid;
        my $oldpath = cwd();
        chdir($path) || warn("can't chdir to $path: $!");
        my $utf8_safe_filename = VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($file);
        if ($utf8_safe_filename ne $file) {
            # we have a problem here... filename is not specified using
            # valid utf8 encoding.  should we skip or rename?  we have
            # to do one or the other as non-utf8 string will cause the
            # control panel meta proc to convulse.  if we skip, it will
            # appear as if the file does not exist on the file system.
            # this is easy to explain to most people, but I'm sure that
            # there will be many who will complain vociferously.  the 
            # only other option is to rename the file surreptitiously
            # and append a warning to the log.  There will probably be
            # some that complain about this behavior as well.  Non-utf8
            # characters in filenames is not supported, so it is really
            # a no-win situation... skip or rename... pick your poison.
            VSAP::Server::Modules::vsap::logger::log_message("files: rename $file to $utf8_safe_filename");
            warn("renaming non-utf filename '$file' to utf-safe counterpart ($utf8_safe_filename)");
            rename($file, $utf8_safe_filename);
            $file = $utf8_safe_filename;
        }
        $type = 
          (-S $file) ? "socket" :
          (-p $file) ? "named pipe (FIFO)" :
          (-t $file) ? "tty" :
          (-b $file) ? "block special file" :
          (-c $file) ? "character special file" :
          (-l $file) ? ((-d $file) ? "dirlink" : "symlink") :
          (-d $file) ? "dir" :
          (-T $file) ? "text" :
          (-B $file) ? "binary" : "plain";
        $is_readable = (-r $file) ||
                       ((-d $file) && (!(-l $file)) && (-x $file));
        $is_writable = (-w $file);
        $is_executable = (-x $file);
        ($mode, $uid, $gid, $size, $mtime) = (lstat($file))[2,4,5,7,9];
        if (($type eq 'symlink') or ($type eq 'dirlink')) {
            $target = readlink($file);
            $target_path = abs_path($target);
            $target_path = $target unless ($target_path);
            $target_path =~ m{/([^/]+)$};
            $target_name = $1;
            $target_type = 
              (-S $target_path) ? "socket" :
              (-p $target_path) ? "named pipe (FIFO)" :
              (-t $target_path) ? "tty" :
              (-b $target_path) ? "block special file" :
              (-c $target_path) ? "character special file" :
              (-l $target_path) ? ((-d $target_path) ? "dirlink" : "symlink") :
              (-d $target_path) ? "dir" :
              (-T $target_path) ? "text" :
              (-B $target_path) ? "binary" : "plain";
        }
        if (($type eq "text") || ($type eq "plain")) {
            if (open(FP, '<', $file)) {
                $test_characters = <FP>;
                close(FP);
            } 
        }
        chdir($oldpath);
    }

    # set name
    $file_node->appendTextChild('name', $file);

    # append url encoded name 
    my $url_encoded_name = url_encode($file);
    $file_node->appendTextChild('url_encoded_name', $url_encoded_name);

    # append url escaped name
    my $url_escaped_name = url_escape($file);
    $file_node->appendTextChild('url_escaped_name', $url_escaped_name);

    # get the extension
    $file =~ m{\.([^\./]*)$};
    my $extension = lc($1);

    # get the mime_type and subtype based on file extension
    my ($mime_type, $subtype);
    $mime_type = $subtype = "";   
    if ($extension) {
        $file_node->appendTextChild('extension', $extension);
        if (($type eq "text") || ($type eq "binary") || ($type eq "plain")) {
            $mime_type = get_mime_type($extension) || 
                    (($type eq "binary") ? "application/octet-stream" : 
                                           "text/plain");
            $file_node->appendTextChild('mime_type', $mime_type);
            if ($type eq "binary") {
                # set a binary subtype based on mime type
                if ($mime_type =~ m#^image/#) {
                    $subtype = "image";
                }
                elsif (($mime_type =~ m#^audio/#) || ($mime_type =~ m#^video/#)) {
                    $subtype = "media";
                }
                $file_node->appendTextChild('subtype', $subtype) if ($subtype);
            }
        }
    }

    # override file type (which is perl's best guess) with mime type
    if ($mime_type && ($mime_type =~ /^text/)) {
        $type = "text";
    }

    # set type
    $file_node->appendTextChild('type', $type);

    # set owner, group, size, and date
    my $owner = getpwuid($uid);
    my $group = getgrgid($gid);
    $size = $size ? $size : '0';
    $file_node->appendTextChild('owner', $owner);
    $file_node->appendTextChild('group', $group);
    $file_node->appendTextChild('size', $size);

    # set system_folder node
    if (($uid < $lowUID) || ($uid > 65533)) {
        $file_node->appendTextChild('system_folder', 'yes');
    }

    # set a couple of nodes that are peculiar to the CPX XSL implementation
    # cp_icon = icon graphic to use in file listing (file, file_hidden, etc)
    # cp_category = (folder|text|image|media|compressed|binary|other)
    my ($cp_category, $cp_icon);
    $cp_category = $cp_icon = "";
    if ($type eq "dir" || $type eq "dirlink") {
        # folder
        $cp_category = $cp_icon = "folder";
        if (($uid < $lowUID) || ($uid > 65533)) {
            $cp_icon .= "_sys";
        }
        if ($type eq "dirlink") {
            $cp_icon .= "_link";
        }
        if ($file =~ /^\./) {
            $cp_icon .= "_hidden";
        }
    }
    else {
        # set type of file
        $cp_category = $subtype || $type;
        $cp_category = "text" if ($cp_category eq "plain");
        $cp_category = "other" if ($cp_category eq "symlink");
        # set icon of file
        $cp_icon = "file";
        if (($type eq "symlink") || ($file =~ /^\./)) {
            if ($type eq "symlink") {
                $cp_icon .= "_link";
            }
            if ($file =~ /^\./) {
                $cp_icon .= "_hidden";
            }
        }
        elsif ($file =~ /\.(bz|bz2|gz|tar|taz|tbz|tbz2|tgz|zip|Z)$/i) {
            if (($file =~ /\.(zip)$/i) ||
                ($file =~ /\.(tar|taz|tbz|tbz2|tgz)$/i) ||
                ($file =~ /\.(tar\.(?:gz|bz|bz2|Z))$/i)) {
                $cp_category = "compressed";
                $cp_icon = "folder_compressed";
            }
            else {
                $file =~ /\.([^.]+)$/;  ## capture extension
                $cp_icon = "file_compressed";
            }
            $file_node->appendTextChild( archive_ext => lc($1) );
        }
        elsif ($subtype && ($subtype eq "image")) {
            $cp_icon = "file_image";
        }
        elsif ($subtype && ($subtype eq "media")) {
            $cp_icon = "file_media";
        }
        elsif ($mime_type && ($mime_type eq "text/html")) {
            $cp_icon = "file_html";
        }
        elsif ($mime_type && ($mime_type eq "text/plain")) {
            $cp_icon = "file_txt";
        }
        elsif ($test_characters && is_mailbox($test_characters)) {
            $cp_icon = "file_mail";
        }
    }
    $file_node->appendTextChild('cp_category', $cp_category);
    $file_node->appendTextChild('cp_icon', $cp_icon);

    # is the file writable?
    $file_node->appendTextChild('is_writable', ($is_writable ? 'yes' : 'no'));

    # is the file executable?
    $file_node->appendTextChild('is_executable', ($is_executable ? 'yes' : 'no'));

    # set mtime
    my ($mtime_sec, $mtime_min, $mtime_hour, $mtime_day, $mtime_mon, $mtime_year);
    ($mtime_sec, $mtime_min, $mtime_hour, $mtime_day, $mtime_mon, $mtime_year) =
       (localtime($mtime))[0,1,2,3,4,5];
    $mtime_mon++; 
    $mtime_year += 1900;
    my $mtime_node = $file_node->appendChild($dom->createElement('mtime'));
    $mtime_node->appendTextChild('sec', $mtime_sec);
    $mtime_node->appendTextChild('min', $mtime_min);
    $mtime_node->appendTextChild('hour', $mtime_hour);
    $mtime_node->appendTextChild('mday', $mtime_day);
    $mtime_node->appendTextChild('month', $mtime_mon);
    $mtime_node->appendTextChild('year', $mtime_year);
    $mtime_node->appendTextChild('epoch', $mtime);

    # set date
    my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') || 
                   VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
    my $d = new VSAP::Server::G11N::Date( epoch => $mtime, tz => $timezone );
    if ($d) {
        my $date_node = $file_node->appendChild($dom->createElement('date'));
        $date_node->appendTextChild( year   => $d->local->year    );
        $date_node->appendTextChild( month  => $d->local->month   );
        $date_node->appendTextChild( day    => $d->local->day     );
        $date_node->appendTextChild( hour   => $d->local->hour    );
        $date_node->appendTextChild( hour12 => $d->local->hour_12 );
        $date_node->appendTextChild( minute => $d->local->minute  );
        $date_node->appendTextChild( second => $d->local->second  );
    
        $date_node->appendTextChild( o_year   => $d->original->year    );
        $date_node->appendTextChild( o_month  => $d->original->month   );
        $date_node->appendTextChild( o_day    => $d->original->day     );
        $date_node->appendTextChild( o_hour   => $d->original->hour    );
        $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
        $date_node->appendTextChild( o_minute => $d->original->minute  );
        $date_node->appendTextChild( o_second => $d->original->second  );
        $date_node->appendTextChild( o_offset => $d->original->offset  );
    }
    
    # set permissions
    my $mode_node = $file_node->appendChild($dom->createElement('mode'));
    my $owner_node = $mode_node->appendChild($dom->createElement('owner'));
    my $group_node = $mode_node->appendChild($dom->createElement('group'));
    my $world_node = $mode_node->appendChild($dom->createElement('world'));
    $owner_node->appendTextChild(read    => ($mode &  0400 ? 1 : 0));
    $owner_node->appendTextChild(write   => ($mode &  0200 ? 1 : 0));
    $owner_node->appendTextChild(execute => ($mode &  0100 ? 1 : 0));
    $group_node->appendTextChild(read    => ($mode &   040 ? 1 : 0));
    $group_node->appendTextChild(write   => ($mode &   020 ? 1 : 0));
    $group_node->appendTextChild(execute => ($mode &   010 ? 1 : 0));
    $world_node->appendTextChild(read    => ($mode &    04 ? 1 : 0));
    $world_node->appendTextChild(write   => ($mode &    02 ? 1 : 0));
    $world_node->appendTextChild(execute => ($mode &    01 ? 1 : 0));
    $owner_node->appendTextChild(setuid  => ($mode & 04000 ? 1 : 0));
    $group_node->appendTextChild(setgid  => ($mode & 02000 ? 1 : 0));
    $world_node->appendTextChild(sticky  => ($mode & 01000 ? 1 : 0));
    # add text child for both symbolic and octal representation of mode
    my $octal_mode = mode_octal($mode);
    $file_node->appendTextChild(octal_mode => $octal_mode);
    my $symbolic_mode = mode_symbolic($mode);
    $file_node->appendTextChild(symbolic_mode => $symbolic_mode);

    # add the target of a symlink
    if (($type eq 'symlink') || ($type eq 'dirlink')) {
        my ($tvpath, $tvuser) = chroot_target_path($target_path, $vsap->{uid}, $vsap->{username}, $vsap->{server_admin}, $lfm);
        if ($tvpath) {
            $file_node->appendTextChild('target', $tvpath);
            $file_node->appendTextChild('target_user', $tvuser) if ($tvuser);
            $file_node->appendTextChild('target_name', $target_name);
            $file_node->appendTextChild('target_type', $target_type);
            # get the extension, mime_type, and subtype
            $target_name =~ m{\.([^\./]*)$};
            my $target_extension = lc($1);
            if ($target_extension) {
                $file_node->appendTextChild('target_extension', $target_extension);
                if (($target_type eq "text") || ($target_type eq "binary") || 
                    ($target_type eq "plain")) {
                    my $target_mime_type = get_mime_type($target_extension) || 
                            ($target_type eq "binary") ? "application/octet-stream" : 
                                                         "text/plain";
                    $file_node->appendTextChild('target_mime_type', $target_mime_type);
                    if ($target_type eq "binary") {
                        # set a binary subtype based on mime type
                        if ($target_mime_type =~ m#^image/#) {
                            $file_node->appendTextChild('target_subtype', 'image');
                        }
                        elsif (($target_mime_type =~ m#^audio/#) || 
                               ($target_mime_type =~ m#^video/#)) {
                            $file_node->appendTextChild('target_subtype', 'media');
                        }
                    }
                }
            }
            # append url_encoded target pathname and filename to dom
            my $url_encoded_target = url_encode($tvpath);
            $file_node->appendTextChild('url_encoded_target', $url_encoded_target);
            my $url_encoded_target_name = url_encode($target_name);
            $file_node->appendTextChild('url_encoded_target_name', $url_encoded_target_name);
            # append url_escaped target pathname and filename to dom
            my $url_escaped_target = url_escape($tvpath);
            $file_node->appendTextChild('url_escaped_target', $url_escaped_target);
            my $url_escaped_target_name = url_escape($target_name);
            $file_node->appendTextChild('url_escaped_target_name', $url_escaped_target_name);
        }
    }

    return($mime_type);
}

##############################################################################

sub chroot_target_path
{
    my $target_fullpath = shift;
    my $userid = shift;
    my $username = shift;
    my $server_admin = shift;
    my $lfm = shift;

    if ($server_admin && !$lfm) {
        return($target_fullpath, "");
    }
    my $target_virtualpath = $target_fullpath;
    my $target_virtualuser = $username;
    my $co = new VSAP::Server::Modules::vsap::config(uid => $userid);
    my @ulist;
    if ($server_admin) {
        @ulist = keys %{$co->users()};
        my $webadmin = ( IS_LINUX ) ? "apache" : "webadmin";
        push(@ulist, $webadmin);
    }
    else {
        @ulist = keys %{$co->users(admin => $username)};
        push(@ulist, $username);
    }
    my $invalid = 1;
    foreach my $validuser (@ulist) {
        my $valid_path = (getpwnam($validuser))[7];
        if (($target_fullpath =~ m#^\Q$valid_path\E/# ) ||
            ($target_fullpath eq $valid_path)) {
            $target_virtualpath =~ s#^\Q$valid_path\E(/|$)#/#;
            $target_virtualuser = $validuser;
            $invalid = 0;
            last;
        }
    }
    return("", "") if ($invalid);
    return($target_virtualpath, $target_virtualuser);
}

##############################################################################

sub get_mime_type
{
    my $extension = shift;

    my $mime_type = "";
    my $filename = $VSAP::Server::Modules::vsap::files::MIME_TYPES;
    if (open(TFILE, $filename)) {
        while (<TFILE>) {
            s/^\s+//g;
            s/\s+$//g;
            s/\s+/ /g;
            next if (/^#/);
            my ($type, @extlist) = split(/\s/);
            foreach my $ext (@extlist) {
                if ($ext eq $extension) {
                    $mime_type = $type;
                    last;
                }
            }
            last if ($mime_type);     
        }
        close(TFILE);
    }
    return($mime_type);
}

##############################################################################

sub is_mailbox
{
    my $test_chars = shift;

    # borrowed from Mail::Mbox::MessageParser::Config
    # X-From-Line is used by Gnus, and From is used by normal Unix
    # format. Newer versions of Gnus use X-Draft-From
    my $from_pattern = q/(?x)^
        (X-Draft-From:\s|X-From-Line:\s|
        From\s                          
          # Skip names, months, days
          (?> [^:]+ )
          # Match time
          (?: :\d\d){1,2}
          # Match time zone (EST), hour shift (+0500), and-or year
          (?: \s+ (?: [A-Z]{2,3} | [+-]?\d{4} ) ){1,3}
          # smail compatibility
          (\sremote\sfrom\s.*)?
        )/;

    if ($test_chars =~ /$from_pattern/im) {
        return(1);
    }
    else {
        return(0);
    }
}

##############################################################################

sub mode_octal
{
    my $mode = shift;

    my $octal_mode = 0;
    $octal_mode += 4000 if ($mode & 04000);
    $octal_mode += 1000 if ($mode & 01000);
    $octal_mode += 2000 if ($mode & 02000);
    $octal_mode +=  400 if ($mode & 0400);
    $octal_mode +=  200 if ($mode & 0200);
    $octal_mode +=  100 if ($mode & 0100);
    $octal_mode +=   40 if ($mode & 040);
    $octal_mode +=   20 if ($mode & 020);
    $octal_mode +=   10 if ($mode & 010);
    $octal_mode +=    4 if ($mode & 04);
    $octal_mode +=    2 if ($mode & 02);
    $octal_mode +=    1 if ($mode & 01);
    return("0000") unless ($octal_mode);
    $octal_mode = "0" . $octal_mode if ($octal_mode < 1000);
    return($octal_mode);
}

##############################################################################

sub mode_symbolic
{
    my $mode = shift;

    my $symbolic_mode = "";
    $symbolic_mode .= ($mode & 0400) ? "r" : "-";
    $symbolic_mode .= ($mode & 0200) ? "w" : "-";
    $symbolic_mode .= ($mode & 0100) ? "x" : "-";
    $symbolic_mode .= ($mode &  040) ? "r" : "-";
    $symbolic_mode .= ($mode &  020) ? "w" : "-";
    $symbolic_mode .= ($mode &  010) ? "x" : "-";
    $symbolic_mode .= ($mode &   04) ? "r" : "-";
    $symbolic_mode .= ($mode &   02) ? "w" : "-";
    $symbolic_mode .= ($mode &   01) ? "x" : "-";
    substr($symbolic_mode, 2, 1) = 's' if ($mode & 04000);
    substr($symbolic_mode, 5, 1) = 's' if ($mode & 02000);
    substr($symbolic_mode, 8, 1) = 't' if ($mode & 01000);
    return($symbolic_mode);
}

##############################################################################

sub sanitize_path
{
    my $unclean_path = shift;

    $unclean_path = canonpath($unclean_path);
    my @subpaths = split(/\//, $unclean_path);
    my $sanitized_path = "";
    foreach my $subpath (@subpaths) {
        next if ($subpath eq "");
        next if ($subpath eq ".");
        if ($subpath eq "..") {
            $sanitized_path =~ s/[^\/]+$//g;
            $sanitized_path =~ s/\/+$//g;
        }
        else {
            $sanitized_path .= "/$subpath";
        }   
    }
    $sanitized_path = "/" unless ($sanitized_path);
    return($sanitized_path);
}

##############################################################################

sub tmp_dir_housekeeping
{
    my $vsap = shift;

    my $apache_group = $vsap->is_linux() ? "apache" : "www";

    my $curtime = time();
    use bytes;
    if (opendir(TMPDIR, "$vsap->{tmpdir}")) {
        foreach my $filename (readdir(TMPDIR)) {
            next if (($filename eq ".") || ($filename eq ".."));
            my $tmpfile = $vsap->{tmpdir} . "/" . $filename;
            my ($mtime) = (stat($tmpfile))[9];
            if (($curtime - $mtime) > (24 * 60 * 60)) {
                # over 24 hours old... clean it
                if ((-d $tmpfile) && (!(-l $tmpfile))) {
                    system('rm', '-rf', '--', $tmpfile);
                } 
                else {
                    unlink($tmpfile);
                }
            }
            else {
                # check ownership
                my ($file_uid) = (lstat($tmpfile))[4];
                if ($file_uid != $vsap->{uid}) {
                  REWT: {
                        local $> = $) = 0;  ## regain privileges for a moment
                        system('chown', '-R', "$vsap->{username}:$apache_group", $tmpfile)
                          and do {   
                              my $exit = ($? >> 8);
                              warn("chown() failed on '$tmpfile' (exitcode $exit)");
                          };
                        my $perms;
                        if ((-d $tmpfile) && (!(-l $tmpfile))) {
                            $perms = "g+rwx";
                        }
                        else {
                            $perms = "g+rw";
                        }
                        system('chmod', "$perms", $tmpfile)
                          and do {
                              my $exit = ($? >> 8);
                              warn("chmod() failed on '$tmpfile' (exitcode $exit)");
                          };
                    }
                }
            }
        }
        closedir(TMPDIR);
    }
    no bytes;
}

##############################################################################

sub url_encode
{
  my $filename = shift;

  # Only alphanumerics [0-9a-zA-Z] and special characters "$-_.+!*'()," 
  # can be used unencoded within a URL.  URL encoded strings can be used
  # as link targets.
  #
  # Note: this is separate from "url escaped" string (see following).
  # URL escaped strings are used for the benefit of javascript.

  if (utf8::is_utf8($filename)) {
      utf8::encode($filename);
  }
  $filename =~ s/([^A-Za-z0-9\/\.\ ])/uc sprintf("%%%02x",ord($1))/eg;
  $filename =~ s/ /\+/g;
  return($filename);
}

##############################################################################

sub url_escape
{
  my $filename = shift;

  # don't use xml_escape or other similarly broad techniques.  just escape
  # the very minimum required in order to embed the filenames into hrefs 
  # and into javascript onClick events, etc.  javascript's unescape() maps
  # escaped chars back to a Latin-1 encoding... not utf-8.  Amir's CPX
  # implementation uses a lot of javascript (unfortunately), so the 
  # limitation of the javascript unescape() function is in play here.

  $filename =~ s/([\\\|\%\&<>"' ])/uc sprintf("%%%02x",ord($1))/eg;
  return($filename);
}

##############################################################################

sub diskspace_availability
{
  my($uid, $gid, $additional_usage) = @_;

  unless(defined($additional_usage)) {
      $additional_usage = 0;  # avoid uninitialized value warning
  }

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $dev = Quota::getqcarg('/home');

        my($usage, $quota) = (Quota::query($dev, $uid))[0,1];
        if($quota > 0)
        {
          $usage *= 1024;  # convert to bytes
          $quota *= 1024;  # convert to bytes
          my $new_usage = $usage + $additional_usage;
          if(($usage > $quota) || ($new_usage > $quota)) {
            # already over, or will go over
            return 0;
          }
        }

        ## most of the calls to this function send in $vsap->{gid} here,
        ## but that value is something else, apparently,
        ## so i'm just doing this instead.  improve it if you like.
        ##   -michael
        $gid = (getpwuid($uid))[3];
        my($grp_usage, $grp_quota) = (Quota::query($dev, $gid, 1))[0,1];
        if($grp_quota > 0)
        {
          $grp_usage *= 1024;  # convert to bytes
          $grp_quota *= 1024;  # convert to bytes
          my $new_grp_usage = $grp_usage + $additional_usage;
          if(($grp_usage > $grp_quota) || ($new_grp_usage > $grp_quota)) {
            # already over, or will go over
            return 0;
          }
        }
  }

  return 1;
}

##############################################################################

1;

__END__

=head1 NAME
     
VSAP::Server::Modules::vsap::files - VSAP file manager utilities
    
=head1 SYNOPSIS
    
  use VSAP::Server::Modules::vsap::files;
        
=head1 DESCRIPTION
    
vsap::files contains some subroutines that perform common tasks; tasks
that are required by more than one file manager module.

=head2 build_file_node($vsap, $node, $path, $file, $uid, $gid)

Determines file properties of path/file and appends those properties to 
the file node.  Accessibility to file is made using the requested 
effective uid/gid.

=head2 get_mime_type($extension)

Looks up the mime type for extension from the system mime types file.

=head2 mode_octal($mode)

Returns the string representation of the octal mode for a file ("0755", 
"0644", etc).

=head2 mode_symbolic($mode)

Returns the string representation of the symbolic mode for a file 
("rwxr-xr-x", "rw-r--r--", etc). 

=head2 sanitize_path($path)

Returns a "sanitized" version of the pathname supplied.  The primary 
concern is the reckoning (and replacement) of all ".." subpath elements 
with actual path names.

=head2 tmp_dir_housekeeping($vsap)

Removes files found in temporary folder that are have a file modification
date of more than 24 hours old.

=head2 url_encode($filename)

Replaces troublesome characters in filenames with an encoded equivalent.

=head2 url_escape($filename)

Replaces troublesome characters in filenames with an escaped equivalent.

=head1 AUTHOR
        
Rus Berrett, E<lt>rus@surfutah.comE<gt>
        
=head1 COPYRIGHT AND LICENSE
            
Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.
         
=cut 

