package VSAP::Server::Modules::vsap::files::list;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::files qw(build_file_node mode_octal mode_symbolic sanitize_path tmp_dir_housekeeping url_encode url_escape);
use VSAP::Server::Modules::vsap::user::prefs;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 NOT_AUTHORIZED     => 100,
                 CANT_OPEN_PATH     => 101,
                 INVALID_USER       => 102,
                 PATH_INVALID       => 302,
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

    # get config object and site prefs
    my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
    my $siteprefs = $co->siteprefs;
    my $lfm = ($siteprefs->{'limited-file-manager'}) ? 1 : 0;  ## chroot file manager for server admin

    # load default path if none specified
    unless ($path) {
        $path = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'fm_startpath') || '';
    }
    unless ($path) {
        if ($vsap->{server_admin} && !$lfm) {
            ($path) = abs_path((getpwuid($vsap->{uid}))[7]);
        }
        else {
            $path = "/";
        }
    }

    # fix up the path
    $path = "/" . $path unless ($path =~ m{^/});  # prepend with /
    $path =~ s{/$}{} unless ($path eq '/');      # strip slash off end
    $path = canonpath($path);

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
    my $pathowner = "";
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if (($fullpath =~ m#^\Q$valid_path\E/#) ||
            ($fullpath eq $valid_path) || ($valid_path eq "/")) {
            $pathowner = $validuser;
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
        if (-e $fullpath) {
            if  (-d $fullpath) {
                if ($vsap->{server_admin}) {
                    $effective_uid = 0;  # give plenty of rope
                    $effective_gid = 0;
                }
                else {
                    # set effective uid/gid to default values
                    if ($pathowner) {
                        ($effective_uid, $effective_gid) = (getpwnam($pathowner))[2,3];
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
                $vsap->error($_ERR{'PATH_INVALID'} => "path isn't a directory: $fullpath");
                return;
            }
        }
        else {
            $vsap->error($_ERR{'CANT_OPEN_PATH'} => "can't open path: $fullpath");
            return;
        }
    }

    # figure out and set the parent dir
    my $parent_dir = "";
    if (($fullpath ne '/') &&
        (($vsap->{server_admin} && !$lfm) || ($fullpath ne $valid_paths{$user}))) {
        $fullpath =~ m{^(.*)/[^/]*$};
        $parent_dir = $1;
        $parent_dir = '/' unless ($parent_dir);
    }

    my ($is_writable, $is_executable, $is_readable);
    my (@files, $mode, $uid, $gid, $size, $mtime);
    my ($parent_dir_uid, $parent_dir_gid);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        # does the path exist?
        unless (-e $fullpath) {
            $vsap->error($_ERR{'CANT_OPEN_PATH'} => "can't open path: $fullpath");
            return;
        }
        # is the path a directory?
        unless (-d $fullpath) {
            # path isn't a directory; use parent directory of path instead
            $fullpath =~ s/[^\/]+$//g;
            $fullpath =~ s/\/+$//g;
        }
        # open the dir and read files if possible
        use bytes;
        if (opendir(DIR, $fullpath)) {
            @files = readdir(DIR);
            closedir(DIR);
        }
        no bytes;
        # get attributes of the dir
        $is_writable = (-w $fullpath);
        $is_executable = (-x $fullpath);
        $is_readable = (-r $fullpath);
        ($mode, $uid, $gid, $size, $mtime) = (stat($fullpath))[2,4,5,7,9];
        # get attributes of the parent dir
        if ($parent_dir) {
            ($parent_dir_uid, $parent_dir_gid) = (stat($fullpath))[4,5];
        }
    }

    #
    # read determines if a user can view a directory's contents
    #	execute determines if a user can cd into a directory
    # write determines if user can add files/folders to dir
    #
    # only allow access if user can read/execute the folder
    #
    unless ($is_readable && $is_executable ) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fullpath");
        return;
    }

    # start building the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'files:list');
    $root_node->appendTextChild('path', $path);
    $root_node->appendTextChild('user', $user);

    # append url encoded path
    my $url_encoded_path = url_encode($path);
    $root_node->appendTextChild('url_encoded_path', $url_encoded_path);

    # append url escaped path
    my $url_escaped_path = url_escape($path);
    $root_node->appendTextChild('url_escaped_path', $url_escaped_path);

    # append dir owner, group, size, and date to dom
    my $owner = getpwuid($uid);
    my $group = getgrgid($gid);
    $size = $size ? $size : '0';
    $root_node->appendTextChild('owner', $owner);
    $root_node->appendTextChild('group', $group);
    $root_node->appendTextChild('size', $size);

    # append system_folder node to dom
    if (($uid < $VSAP::Server::Modules::vsap::globals::PLATFORM_UID_MIN) ||
        ($uid > $VSAP::Server::Modules::vsap::globals::PLATFORM_UID_MAX)) {
        $root_node->appendTextChild('system_folder', 'yes');
    }

    # is the dir writable?
    $root_node->appendTextChild('is_writable', ($is_writable ? 'yes' : 'no'));

    # is the dir executable?
    $root_node->appendTextChild('is_executable', ($is_executable ? 'yes' : 'no'));

    # append mtime info to dom
    my ($mtime_sec, $mtime_min, $mtime_hour, $mtime_day, $mtime_mon, $mtime_year);
    ($mtime_sec, $mtime_min, $mtime_hour, $mtime_day, $mtime_mon, $mtime_year) =
       (localtime($mtime))[0,1,2,3,4,5];
    $mtime_mon++;
    $mtime_year += 1900;
    my $mtime_node = $root_node->appendChild($dom->createElement('mtime'));
    $mtime_node->appendTextChild('sec', $mtime_sec);
    $mtime_node->appendTextChild('min', $mtime_min);
    $mtime_node->appendTextChild('hour', $mtime_hour);
    $mtime_node->appendTextChild('mday', $mtime_day);
    $mtime_node->appendTextChild('month', $mtime_mon);
    $mtime_node->appendTextChild('year', $mtime_year);
    $mtime_node->appendTextChild('epoch', $mtime);

    my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') || 'GMT';
    my $d = new VSAP::Server::G11N::Date( epoch => $mtime, tz => $timezone );
    if ($d) {
        my $date_node = $root_node->appendChild($dom->createElement('date'));
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

    # append permissions to dom
    my $mode_node = $root_node->appendChild($dom->createElement('mode'));
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
    $root_node->appendTextChild(octal_mode => $octal_mode);
    my $symbolic_mode = mode_symbolic($mode);
    $root_node->appendTextChild(symbolic_mode => $symbolic_mode);

    # append parent dir info
    if ($parent_dir) {
        # chroot parent_dir if necessary
        if (!$vsap->{server_admin} || $lfm) {
            $parent_dir =~ s#^\Q$valid_paths{$user}\E(/|$)#/#;
        }
        # append parent dir path to dom
        $root_node->appendTextChild('parent_dir', $parent_dir);
        # append url encoded parent dir path to dom
        my $url_encoded_parent_dir = url_encode($parent_dir);
        $root_node->appendTextChild('url_encoded_parent_dir', $url_encoded_parent_dir);
        # append url escaped parent dir path to dom
        my $url_escaped_parent_dir = url_escape($parent_dir);
        $root_node->appendTextChild('url_escaped_parent_dir', $url_escaped_parent_dir);
        # is parent dir a system folder
        if (($parent_dir_uid < $VSAP::Server::Modules::vsap::globals::PLATFORM_UID_MIN) ||
            ($parent_dir_uid > $VSAP::Server::Modules::vsap::globals::PLATFORM_UID_MAX)) {
            $root_node->appendTextChild('parent_dir_system_folder', 'yes');
        }
    }

    # append file properties for each file in the directory to dom
    foreach my $file (@files) {
        # skip ".." if at top of chroot'd space
        next if (($file eq "..") && ($parent_dir eq ""));
        # build node for current file and append to dom
        my $file_node = $root_node->appendChild($dom->createElement('file'));
        build_file_node($vsap, $file_node, $fullpath, $file,
                        $effective_uid, $effective_gid, $lfm);
    }

    $dom->documentElement->appendChild($root_node);

    if ($fullpath eq $vsap->{homedir}) {
        # do some housekeeping on tmpdir (seems like as good a time as any)
        tmp_dir_housekeeping($vsap);
    }

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::list - VSAP module to list files
in a directory

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::list;

=head1 DESCRIPTION

The VSAP files::list module allows users to list files in a directory.

To list files, you need to specify a path name and an optional user
name.  The following example generically represents the structure of a
typical list files request:

  <vsap type="files:list">
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

A request made by System Administrator to list files in a system folder:

    <vsap type="files:list">
      <path>/var/log</path>
    </vsap>

A request made by a Domain Administrator or End User to list files homed
in their own home directory structure.

    <vsap type="files:list">
      <path>/mystuff/photos</path>
    </vsap>

A request made by a Domain Administrator to list files homed in the
directory space of an End User.

    <vsap type="files:list">
      <user>scott</user>
      <path>/poetry/tabasco</path>
   </vsap>

=back

If the path name is accessible (see NOTES), the properties of the
directory will be listed as well as the properties of each file that is
located in that directory (please see the example below).

  <vsap type="files:list">
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
    <file>
      <name>file name</name>
      <type>file type</type>
      <owner>file owner user name</owner>
      <group>file owner group name</group>
      <size>file size (in bytes)</size>
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
    </file>
    <file>
      <name>file name</name>
      <type>file type</type>
       .
       .
       .
    </file>
    <file>
       .
       .
       .
    </file>
  </vsap>

The directory path name and directory user name properties will mirror
that which was supplied by the query.  The directory ownership vector,
user and group, is noted in the '<owner>' and '<group>' nodes
respectively.  The directory size is simply the size of the directory
itself (B<not> the sum of the sizes of all files in the directory).
The '<is_writable>' node will be set to "yes" or "no" depending on
whether the authenticated user has write privileges to the directory;
likewaise, the '<is_executable>' node will be set to "yes" or "no"
depending on whether the authenticaed user has execute privileges for
the directory.

The '<mtime>' node is populated with the year, month, day of the
month (mday), hour, min, and second that the directory was last
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
'<setuid>' child which will indicate whether or not the directory is
setuid.  Likewise, the '<group>' subnode also will include a '<setgid>'
child which will indicate whether or not the directory is setgid.  And
furthermore, the '<world>' subnode will include a '<sticky>' child set
if the sticky bit on the directory is set.

The '<octal_node>' is the string based representation of the octal mode
of the directory ("0775", "0755", "0700", etc).  The '<symbolic_node>'
is a string based representation of the file mode in the "rwx" fashion
(e.g. "rwxrwxr-x", "rwxr-xr-x", etc).

The '<parent_dir>' node contains the full path to the parent directory
of the directory made in the query.

A description of each file is also included in the directory listing.
Each file description includes most of the nodes included above
('<owner>', '<group>', '<is_writable>', '<is_executable>', '<mtime>',
'<date>', '<mode>', '<octal_node>', and '<symbolic_node>').  Each
file node will also include a '<type>' child.  The values for the type
child can be one of: "socket" : "named pipe (FIFO)", "tty", "block
special file", "character special file", "dirlink", "symlink", "dir",
"text", "binary", or "plain".

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

