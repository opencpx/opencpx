package VSAP::Server::Modules::vsap::files::upload;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::globals;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = ( 
                 NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 CANT_OPEN_PATH     => 102,
                 UPLOAD_FAILED      => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_SESSIONID  => 106,
                 INVALID_FILENAME   => 107,
                 INVALID_TARGET     => 108,
               );

our $TEMP_DIR = $VSAP::Server::Modules::vsap::globals::APACHE_TEMP_DIR;

##############################################################################

sub _get_sessionid
{
    my $tmpdir = shift;

    # seed the random number generator
    srand(time() ^ ($$ + ($$ <<15)));

    # get a unique 20-char random id to use for this upload session
    my @chars=('a'..'z','A'..'Z','0'..'9','_');
    my $sessionid = "";
    foreach (0..20) {
        $sessionid .= $chars[rand @chars];
    }
    my $sessiondir = $tmpdir . "/" . $sessionid;
    while (-e $sessiondir) {
        $sessionid = "";
        foreach (0..20) {
            $sessionid .= $chars[rand @chars];
        }
        $sessiondir = $tmpdir . "/" . $sessionid;
    }
    return($sessionid);
}

# ----------------------------------------------------------------------------

sub _init_sessiondir
{
    my $tmpdir = shift;
    my $sessionid = shift;

    # create the temporary upload directory
    my $sessiondir = $tmpdir . "/" . $sessionid;
    unless (-e $sessiondir) {
        mkdir($sessiondir) ||
            warn("could not mkdir($sessiondir): $!");
    }

    # make sure upload directory has ample perms (g+rw)
  REWT: {
      local $> = $) = 0;  ## regain privileges for a moment
      system('chmod', 'g+rw', $sessiondir)
          and do {
              my $exit = ($? >> 8);
              warn("chmod() failed on '$sessiondir' (exitcode $exit)");
          };
    }
    return(1);
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::add;

use VSAP::Server::Modules::vsap::files qw(diskspace_availability);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::string::encoding qw(guess_string_encoding);

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    my $filename = $xmlobj->child("filename") ?
                   $xmlobj->child("filename")->value : '';

    unless ($sessionid) {
        $sessionid = VSAP::Server::Modules::vsap::files::upload::_get_sessionid($vsap->{tmpdir});
    }

    unless ($filename) {
        $vsap->error($_ERR{'INVALID_FILENAME'} => "filename required");
        return;
    }

    # create the directory (if necessary)
    unless(diskspace_availability($vsap->{uid}, $vsap->{gid}))
    {
        $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error uploading file: quota exceeded");
        return;
    }
    VSAP::Server::Modules::vsap::files::upload::_init_sessiondir($vsap->{tmpdir}, $sessionid);

    my $destfile = $filename;
    $destfile =~ s/(.*)(\/|\\)//g;
    $destfile = guess_string_encoding($destfile);

    # move the uploaded file to the session directory
    my $status = "ok";
    my $sessiondir = $vsap->{tmpdir} . "/" . $sessionid;
    my $source = $vsap->{tmpdir} . "/" . $destfile;
    my $target = $sessiondir . "/" . $destfile;
    # check quota first
    my ($size) = (stat($source))[7];
    if ($size) {
        # get quota/usage of authenticated user
        unless(diskspace_availability($vsap->{uid}, $vsap->{gid}, $size)) {
                unlink($source);
                $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error uploading file: quota exceeded");
                return;
        }
    }
    rename($source, $target)
      or do {
          warn("rename($source, $target) failed: $!");
          VSAP::Server::Modules::vsap::logger::log_error("rename($source, $target) failed: $!");
          $status = "fail";
      };

    # chown to authenticated user
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $group = $VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP;
        system('chown', "$vsap->{username}:$group", $target)
          and do {
              my $exit = ($? >> 8);
              warn("chown() failed on '$target' (exitcode $exit)");
          };
        system('chmod', 'g+rw', $target)
          and do {
              my $exit = ($? >> 8);
              warn("chmod() failed on '$target' (exitcode $exit)");
          };
    }

    # do some nice things if the stored file is plain text file
    if ((-T $target) && ($target !~ /\.pdf$/i)) {
        # convert \r\n to \n
        my $curline = "";
        my $firstline = "";
        if (open(UFP, "$target")) {
            if (open(TFP, "+<$target")) {
                while (<UFP>) {
                    $curline = $_;
                    $firstline = $curline if ($firstline eq "");
                    $curline =~ s/\r//g;
                    print TFP $curline;
                }
                close(UFP);
                my $curpos = tell(TFP);
                truncate(TFP, $curpos);
                close(TFP);
                # chmod u+x,g+x if firstline starts with '#!/'
                if ($firstline =~ /^\#\!\//) {
                  system('chmod', 'u+x,g+x', $target)
                      and do {
                          my $exit = ($? >> 8);
                          warn("chmod(u+x,g+x) failed on '$target' (exitcode $exit)");
                      };
                }
            }
            else {
                warn("open(TFP, \"+<$target\") failed: $!\n");
            }
        }
        else {
            warn("open(UFP, \"$target\") failed: $!\n");
        }

    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:add');
    $root_node->appendTextChild(sessionid => $sessionid);
    $root_node->appendTextChild(filename => $filename);
    $root_node->appendTextChild(status => $status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::cancel;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    unless ($sessionid) {
        $vsap->error($_ERR{'INVALID_SESSIONID'} => "session id required");
        return;
    }

    my $sessiondir = $vsap->{tmpdir} . "/" . $sessionid;
    if (-e $sessiondir) {
        use bytes;
        opendir(TMPDIR, $sessiondir);
        for my $filename (readdir(TMPDIR)) {
            next if ($filename eq ".");
            next if ($filename eq "..");
            my $fullpath = $sessiondir . "/" . $filename;
            unlink($fullpath) ||
                warn("unlink($fullpath) failed: $!");
        }
        closedir(TMPDIR);
        no bytes;
        rmdir($sessiondir) ||
            warn("rmdir($sessiondir) failed: $!");
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:cancel');
    $root_node->appendTextChild(sessionid => $sessionid);
    $root_node->appendTextChild(status => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::confirm;

use Cwd qw(abs_path);
use Encode qw(decode_utf8);
use File::Basename qw(fileparse);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path diskspace_availability);

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get session id
    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    # get target directory (and target user)
    my $target = $xmlobj->child('path') ?
                 $xmlobj->child('path')->value : '';
    my $targetuser = ($xmlobj->child('user') && $xmlobj->child('user')->value) ?
                      $xmlobj->child('user')->value : $vsap->{username};

    # overwrite existing targets (should they exist)?
    my $overwrite = defined($xmlobj->child('overwrite'));

    unless ($sessionid) {
        $vsap->error($_ERR{'INVALID_SESSIONID'} => "session id required");
        return;
    }

    unless ($target) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    # set the sessiondir for upload
    my $sessiondir = $vsap->{tmpdir} . "/" . $sessionid;

    # set the sourceuser (used later to chroot if necessary)
    my $sourceuser = $vsap->{username};

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

    # check authorization to access target path
    my $authorized = 0;
    my $parentuser = "";
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

    # set source effective uid/gid
    my $source_euid = $vsap->{uid};
    my $source_egid = $vsap->{gid};

    # figure out who is going to own the target
    my ($target_euid, $target_egid);
    if ($vsap->{server_admin}) {
        # set to be the uid of the parent directory
        my $parentpath = $fulltarget;
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

    # if changing ownership, check quota and fail if no room
    my $new_disk_space_requirements = 0;
    if ($source_euid != $target_euid) {
        use bytes;
        opendir(TMPDIR, $sessiondir);
        for my $filename (sort(readdir(TMPDIR))) {
            next if ($filename eq ".");
            next if ($filename eq "..");
            my $fullpath = $sessiondir . "/" . $filename;
            my ($size) = (stat($fullpath))[7];
            $new_disk_space_requirements += $size;
        }
        closedir(TMPDIR);
        no bytes;
    }
    if ($new_disk_space_requirements) {
        # get quota/usage for owner of the target directory
        unless(diskspace_availability($target_euid, $target_egid, $new_disk_space_requirements))
        {
                $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error uploading file: quota exceeded");
                return;
        }
    }

    # if the target doesn't exist; we need to create it before we attempt
    # to move the temp files into it.
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        if (-e $fulltarget) {
            # if fulltargetpath exists; it must be a directory
            unless (-d $fulltarget) {
                $vsap->error($_ERR{'INVALID_TARGET'} => "invalid target: $fulltarget");
                return;
            }
        }
        else {
            # target directory does not exist; create it
            system('mkdir', '-p', '--', $fulltarget)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'UPLOAD_FAILED'} => "cannot mkdir '$fulltarget' (exitcode $exit)");
                  return;
              };
        }
    }

    # figure out who is going to execute the commands to move files
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

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:confirm');

    # move all upload file paths to target directory
    my $success_node = "";
    my $failure_node = "";
    my ($path_node, $mesg, $vsp, $vtp);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $effective_gid;
        local $> = $effective_uid;
        use bytes;
        opendir(TMPDIR, $sessiondir);
        for my $filename (readdir(TMPDIR)) {
            next if ($filename eq ".");
            next if ($filename eq "..");
            my $fullpath = $sessiondir . "/" . $filename;
            my ($sourcename) = (fileparse($fullpath))[0];
            my $fulltargetpath = canonpath(catfile($fulltarget, decode_utf8($sourcename)));
            unless ($overwrite) {
                # check to see if the target filename exists... if it does,
                # then rewrite source filename using the "_new" designation
                my $index = 1;
                while (-e $fulltargetpath) {
                    my ($ftname, $ftpath, $ftsuffix) = fileparse($fulltargetpath, '\..*');
                    if ($index == 1) {
                        $ftname = $ftname . "_new";
                    }
                    else {
                        $ftname =~ s/_[0-9]+$//;
                        $ftname =~ s/_new$//g;
                        $ftname .= "_new_$index";
                    }
                    $ftname .= $ftsuffix if ($ftsuffix);
                    $fulltargetpath = catfile($ftpath, $ftname);
                    $index++;
                }
            }
            # build virtualsourcepath from fullpath
            $vsp = $fullpath;
            if (!$vsap->{server_admin} || $lfm) {
                $vsp =~ s#^\Q$valid_paths{$sourceuser}\E(/|$)#/#;
            }
            # build virtualtargetpath from fulltargetpath
            $vtp = $fulltargetpath;
            if (!$vsap->{server_admin} || $lfm) {
                $vtp =~ s#^\Q$valid_paths{$targetuser}\E(/|$)#/#;
            }
            # cross your fingers, rename, and hope for the best
            rename($fullpath, $fulltargetpath)
              or do {
                  $mesg = "upload: rename '$fullpath' to '$fulltargetpath' failed: $!";
                  warn($mesg);
                  VSAP::Server::Modules::vsap::logger::log_error($mesg);
                  unless ($failure_node) {
                      $failure_node = $root_node->appendChild($dom->createElement('failure'));
                  }
                  $path_node = $failure_node->appendChild($dom->createElement('path'));
                  $path_node->appendTextChild(source => $vsp);
                  $path_node->appendTextChild(target => $vtp);
                  $path_node->appendTextChild(code => $_ERR{'UPLOAD_FAILED'});
                  $path_node->appendTextChild(mesg => $mesg);
                  next;
              };
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} uploaded file '$fulltargetpath'");
            # chown to the target path's owner
            chown($target_euid, $target_egid, $fulltargetpath) ||
                warn("chown on $fulltargetpath failed: $!)");
            # add path to success node
            unless ($success_node) {
                $success_node = $root_node->appendChild($dom->createElement('success'));
            }
            $path_node = $success_node->appendChild($dom->createElement('path'));
            $path_node->appendTextChild(source => $vsp);
            $path_node->appendTextChild(target => $vtp);
        }
        closedir(TMPDIR);
        no bytes;
    }

    # add user to dom
    $root_node->appendTextChild(user => $targetuser);

    $dom->documentElement->appendChild($root_node);

    # remove the (presumably) empty sessiondir
    if (-e $sessiondir) {
        rmdir($sessiondir) ||
            warn("rmdir($sessiondir) failed: $!");
    }

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::delete;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    # get all filenames to delete
    my @filenames = ($xmlobj->children('filename') ?
                     grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('filename') : () );

    unless ($sessionid) {
        $vsap->error($_ERR{'INVALID_SESSIONID'} => "session id required");
        return;
    }

    if ($#filenames == -1) {
        $vsap->error($_ERR{'INVALID_FILENAME'} => "filenames required");
        return;
    }

    my $sessiondir = $vsap->{tmpdir} . "/" . $sessionid;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:delete');
    $root_node->appendTextChild(sessionid => $sessionid);

    my $success_node = "";
    my $failure_node = "";
    foreach my $filename (@filenames) {
        my $fullpath = $sessiondir . "/" . $filename;
        unlink($fullpath)
            or do {
                warn("unlink($fullpath) failed: $!");
                unless ($failure_node) {
                    $failure_node = $root_node->appendChild($dom->createElement('failure'));
                }
                $failure_node->appendTextChild(filename => $filename);
                next;
            };
        unless ($success_node) {
            $success_node = $root_node->appendChild($dom->createElement('success'));
        }
        $success_node->appendTextChild(filename => $filename);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::init;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    unless ($sessionid) {
        $sessionid = VSAP::Server::Modules::vsap::files::upload::_get_sessionid($vsap->{tmpdir});
    }

    my $status = "ok";
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:init');
    $root_node->appendTextChild(sessionid => $sessionid);
    $root_node->appendTextChild(status => $status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::list;

use VSAP::Server::Modules::vsap::files qw(tmp_dir_housekeeping);

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    unless ($sessionid) {
        $sessionid = VSAP::Server::Modules::vsap::files::upload::_get_sessionid($vsap->{tmpdir});
    }

    my $sessiondir = $vsap->{tmpdir} . "/" . $sessionid;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:list');
    $root_node->appendTextChild(sessionid => $sessionid);

    my $upload_node;
    use bytes;
    opendir(TMPDIR, $sessiondir);
    for my $filename (sort(readdir(TMPDIR))) {
        next if ($filename eq ".");
        next if ($filename eq "..");
        my $fullpath = $sessiondir . "/" . $filename;
        my ($size) = (stat($fullpath))[7];
        $upload_node = $root_node->appendChild($dom->createElement('upload'));
        $upload_node->appendTextChild(filename => $filename);
        $upload_node->appendTextChild(size => $size);
    }
    closedir(TMPDIR);
    no bytes;

    $dom->documentElement->appendChild($root_node);

    # do some housekeeping on tmpdir
    tmp_dir_housekeeping($vsap);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::status;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    unless ($sessionid) {
        $vsap->error($_ERR{'INVALID_SESSIONID'} => "session id required");
        return;
    }

    my $statusfile = $TEMP_DIR . "/" . $sessionid;
    select(undef, undef, undef, 0.5) unless (-e "$statusfile");  # wait half a second for apache
    select(undef, undef, undef, 0.5) unless (-s "$statusfile");  # wait another half a second for apache
    unless (open(SFP, "$statusfile")) {
        $vsap->error($_ERR{'CANT_OPEN_PATH'} => "session upload status open($statusfile) failed: $!");
        return;
    }

    my $filename;
    my $time_elapsed;
    my $bytes_transferred;
    my $average_transfer_rate;
    my $total_size;
    my $percent_complete;

    my $tmpfilename = <SFP>;
    $filename = <SFP>;
    $total_size = <SFP>;
    my $start = <SFP>;
    close(SFP);

    chomp($tmpfilename);
    chomp($filename);
    chomp($total_size);
    chomp($start);

    $filename =~ s/(.*)(\/|\\)//g;

    $bytes_transferred = (-e "$tmpfilename") ? (-s "$tmpfilename") : $total_size;
    $percent_complete = ($total_size > 0) ? ($bytes_transferred / $total_size) : 0;
    $percent_complete = sprintf "%d", ($percent_complete * 100);

    my $end = (-e "$tmpfilename") ? time() : (stat("$statusfile"))[9];
    $time_elapsed = $end - $start;
    $average_transfer_rate = ($time_elapsed > 0) ? ($bytes_transferred / $time_elapsed) : 0;
    $average_transfer_rate = sprintf "%d", $average_transfer_rate;

    # return info about ongoing upload for sessionid
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:status');
    $root_node->appendTextChild(sessionid => $sessionid);
    $root_node->appendTextChild(filename => $filename);
    $root_node->appendTextChild(time_elapsed => $time_elapsed);
    $root_node->appendTextChild(bytes_transferred => $bytes_transferred);
    $root_node->appendTextChild(average_transfer_rate => $average_transfer_rate);
    $root_node->appendTextChild(total_size => $total_size);
    $root_node->appendTextChild(percent_complete => $percent_complete);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::files::upload::sweep;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sessionid = $xmlobj->child("sessionid") ?
                    $xmlobj->child("sessionid")->value : '';

    unless ($sessionid) {
        $vsap->error($_ERR{'INVALID_SESSIONID'} => "session id required");
        return;
    }

    my $status = "ok";
    my $statusfile = $TEMP_DIR . "/" . $sessionid;

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e "$statusfile") {
            unlink($statusfile)
              or do {
                  warn("unlink($statusfile) failed: $!");
                  $status = "fail";
              };
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:upload:sweep');
    $root_node->appendTextChild(sessionid => $sessionid);
    $root_node->appendTextChild(status => $status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::upload - VSAP module to "upload"
one or more files

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::upload;

=head1 DESCRIPTION

The VSAP upload module allows users to "upload" one or more files.  The
name "upload" is something of a misnomer since this module does nothing
more than move a file placed in the user's VSAP temporary directory
(vsap->{tmpdir}) into a session file during an "add" request, and move
those session files to their final destination during a "confirm"
request.

=head2 files:upload:add

The add method takes a file that was uploaded and placed in the users'
VSAP temporary directory (vsap->{tmpdir}) and moves it into a new or an
existing session directory.

The following template represents the generic form of an add query:

    <vsap type="files:upload:add">
        <sessionid>session id</sessionid>
        <filename>file name</filename>
    </vsap>

The '<sessionid>' is optional and only needs to be included if starting
a new session.  The '<filename>' specifies the file name of the file
that was recently uploaded (by an external process, such as an apache
modules, etc).  This file is presumed to exist in the authenticated
users' VSAP temporary directory (vsap->{tmpdir}).

=head2 files:upload:cancel

The cancel method will remove the session directory and any files that
may exist as part of the session.

The following template represents the generic form of a cancel query:

    <vsap type="files:upload:cancel">
        <sessionid>session id</sessionid>
    </vsap>

The '<sessionid>' is required.

=head2 files:upload:confirm

The confirm method will move all of the files found in the session
directory into a specified target directory.

The following template represents the generic form of a confirm query:

    <vsap type="files:upload:confirm">
        <sessionid>session id</sessionid>
        <target>target directory</target>
        <target_user>target directory</target_user>
    </vsap>

The '<sessionid>' is required.

The target directory is the directory where the files will be moved.
System Administrators should use the full path name to the target
directory and need not ever include the optional target user name.
Domain Administrators should use the "virtual path name" for the target
directory and the '<target_user>' node if required (per the same
methodology of the source directory specification).  End Users will also
need to use a "virtual path name" to a file; no '<target_user>'
specification is required, as the authenticated user name is presumed.

If the target directory is accessible (see NOTES), all of the files (or
the specified files) in the archive will be extracted or an error will
be returned.  A successful request will be indicated by the return
'<status>' node.

=head2 files:upload:delete

The delete method will delete specified files from the session
directory.

The following template represents the generic form of a delete query:

    <vsap type="files:upload:delete">
        <sessionid>session id</sessionid>
        <filename>file name</filename>
        <filename>file name</filename>
        <filename>file name</filename>
        <filename>file name</filename>
    </vsap>

The '<sessionid>' is required.  At least one '<filename>' is required.

=head2 files:upload:init

The init method will build a unique session id for the upload session.
There are no rquired child nodes for an init query.  A typical response
from an init query will look something like this:

    <vsap type="files:upload:init">
        <sessionid>session id</sessionid>
    </vsap>

=head2 files:upload:list

The list method will return a list of files in a specified session
directory.  The information on each file includes the file name and the
file size.

The following template represents the generic form of a list query:

    <vsap type="files:upload:list">
        <sessionid>session id</sessionid>
    </vsap>

The '<sessionid>' is required.

If the session id is valid, then a response will be built that includes
the file name and file size of each file in the session directory.  The
following example generically represents the structure of a typical
response from a query:

    <vsap type="files:upload:list">
        <sessionid>session id</sessionid>
        <upload>
          <name>file name</name>
          <size>file size</size>
        </upload>
        <upload>
          <filename>file name</filename>
          <size>file size</size>
        </upload>
        .
        .
        .
    </vsap>

=head2 files:upload:status

The status method will report information about the active upload in
progress for the specified session.  The following template represents
the generic form of a list query:

    <vsap type="files:upload:list">
        <sessionid>session id</sessionid>
    </vsap>

The '<sessionid>' is required.

If the session id is valid, then a response will be built that includes
information about how long the active file has been in transfer (in
seconds), the average transfer rate, the amount (in bytes) that has been
transferred, the total expected size (in bytes) of the transfer, as well
as the percentage of the transfer that has been completed.  The
following example generically represents the structure of a typical
response from a status query:

    <vsap type="files:upload:status">
        <sessionid>session id</sessionid>
        <filename>file name</filename>
        <time_elapsed>time in seconds</time_elapsed>
        <bytes_transferred>number of bytes</bytes_transferred>
        <average_transfer_rate>bytes per second</average_transfer_rate>
        <total_size>total number of bytes</total_size>
        <percent_complete>total number of bytes</percent_complete>
    </vsap>


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

