package VSAP::Server::Modules::vsap::files::uncompress;

use 5.008004;
use strict;
use warnings;
use Cwd qw(abs_path cwd);
use Encode qw(decode_utf8);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(fileparse);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::files qw(sanitize_path diskspace_availability);
use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.01';

our %_ERR    = ( NOT_AUTHORIZED     => 100,
                 INVALID_PATH       => 101,
                 CANT_OPEN_PATH     => 102,
                 UNCOMPRESS_FAILED  => 103,
                 QUOTA_EXCEEDED     => 104,
                 INVALID_USER       => 105,
                 INVALID_TARGET     => 106,
                 REQUEST_QUEUED     => 250,
               );

# path to the unzip/tar executables....    (LINUX)           (FreeBSD)
our $UNZIP_PATH = (-e "/usr/bin/unzip") ? "/usr/bin/unzip" : "/usr/local/bin/unzip";
our $UNTAR_PATH = (-e "/bin/tar")       ? "/bin/tar"       : "/usr/bin/tar";

# platform info
use constant IS_LINUX => ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
use constant IS_CLOUD => (-d '/var/vsap' && IS_LINUX);

# 'unzip' cannot read selected files from a separate file - but 'tar' can;
# find limit for number of arguments and maximum length of args (BUG25662)
our $max_arg_list_length = (IS_LINUX) ? `getconf ARG_MAX` : `sysctl kern.argmax`;
$max_arg_list_length =~ s/[^\d]//g;
$max_arg_list_length = sprintf "%d", ($max_arg_list_length / 4 - 1);

##############################################################################

sub handler {
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # get path to compressed archive (and user)
    my $source = $xmlobj->child('source') ?
                 $xmlobj->child('source')->value : '';
    my $sourceuser = ($xmlobj->child('source_user') && $xmlobj->child('source_user')->value) ?
                      $xmlobj->child('source_user')->value : $vsap->{username};

    # get target directory
    my $targetdir = $xmlobj->child('target') ?
                    $xmlobj->child('target')->value : '';
    my $targetuser = ($xmlobj->child('target_user') && $xmlobj->child('target_user')->value) ?
                      $xmlobj->child('target_user')->value : $vsap->{username};

    # get uncompress options
    my $uncompress_option = ( $xmlobj->child('uncompress_option')
                              ? $xmlobj->child('uncompress_option')->value
                              : '' );

    # get all non-empty files that user wishes to extract from archive
    my @files = ($xmlobj->children('file') ?
                 grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('file') : () );

    unless ($source) {
        $vsap->error($_ERR{'INVALID_PATH'} => "source archive required");
        return;
    }

    unless ($targetdir) {
        $vsap->error($_ERR{'INVALID_TARGET'} => "target directory required");
        return;
    }

    if ($source !~ /\.(bz|bz2|gz|tar|taz|tbz|tbz2|tgz|zip|Z)$/i) {
        # unknown or unsupported format
        $vsap->error($_ERR{'INVALID_PATH'} => "compressed archive type invalid");
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
        $valid_paths{$validuser} = (getpwnam($validuser))[7];
    }

    # build full source path
    my $fullpath = $source;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$sourceuser})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown source user: $sourceuser");
            return;
        }
        $fullpath = canonpath(catfile($valid_paths{$sourceuser}, $source));
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

    # build full target path
    my $fulltarget = $targetdir;
    if (!$vsap->{server_admin} || $lfm) {
        # rebuild chroot'd paths
        unless (defined($valid_paths{$targetuser})) {
            $vsap->error($_ERR{'INVALID_USER'} => "unknown target user: $targetuser");
            return;
        }
        $fulltarget = canonpath(catfile($valid_paths{$targetuser}, $targetdir));
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

    # check authorization to access source path
    my $authorized = 0;
    my $sourceparentuser = "";
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if (($fullpath =~ m#^\Q$valid_path\E/# ) ||
            ($fullpath eq $valid_path) || ($valid_path eq "/")) {
            $sourceparentuser = $validuser;
            $authorized = 1;
            last;
        }
    }
    unless ($vsap->{server_admin} || $authorized) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fullpath");
        return;
    }

    # check authorization to access target path
    $authorized = 0;
    my $targetparentuser = "";
    foreach $validuser (keys(%valid_paths)) {
        my $valid_path = $valid_paths{$validuser};
        if (($fulltarget =~ m#^\Q$valid_path\E/# ) ||
            ($fulltarget eq $valid_path) || ($valid_path eq "/")) {
            $targetparentuser = $validuser;
            $authorized = 1;
            last;
        }
    }
    unless ($vsap->{server_admin} || $authorized) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized: $fulltarget");
        return;
    }

    # does the source and/or target exist?
    my ($source_euid, $source_egid);
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e $fullpath || -l $fullpath) {
            if ($vsap->{server_admin}) {
                $source_euid = 0;  # give plenty of rope
                $source_egid = 0;
            }
            else {
                # set effective uid/gid to default values
                if ($sourceparentuser) {
                    ($source_euid, $source_egid) = (getpwnam($sourceparentuser))[2,3];
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
        # if the target exists, it must be a directory
        if (-e $fulltarget) {
            unless (-d $fulltarget) {
                $vsap->error($_ERR{'INVALID_TARGET'} => "existing target not a directory: $fulltarget");
                return;
            }
        }
    }

    # figure out who is going to own the target and files extracted beneath it
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
        if ($targetparentuser) {
            ($target_euid, $target_egid) = (getpwnam($targetparentuser))[2,3];
        }
        else {
            $target_euid = $vsap->{uid};
            $target_egid = $vsap->{gid};
        }
    }

    # check quota and fail if no room for extracted files
    my %extracted_files = ();
    my ($curline, $size, $fpath, $type, $command);
    if ($fullpath =~ /\.zip$/i) {
        # get list of files via zipinfo system command
        $command = "zipinfo $fullpath";
        # if only concerned with selected files, don't pass in files as command line args
        # which may break the pipe due to length.  check on hashed paths instead (BUG25662)
        my %selected_files = ();
        foreach $fpath (@files) {
            $selected_files{$fpath} = "dau!";
        }
      EFFECTIVE: {
            local $> = $source_euid;
            unless (open(ZIPINFO, "$command |")) {
                warn "zipinfo() for '$fullpath' failed: $!";
            }
            else {
                while (<ZIPINFO>) {
                    next if (/^Archive/);
                    last if (/uncompressed,/ && (/compressed:/));
                    $curline = $_;
                    chomp($curline);
                    $curline =~ /^\S+\s+\S+\s+\S+\s+([0-9]*)\s+\S+\s+\S+\s+\S+\s+\S+\s+(.*)$/;
                    $size = $1;
                    $fpath = $2;
                    next if (($#files >= 0) && (!defined($selected_files{$fpath})));
                    $type = ($fpath =~ m#/$#) ? "dir" : "file";
                    $extracted_files{$fpath}->{'size'} = $size;
                    $extracted_files{$fpath}->{'type'} = $type;
                }
                close(ZIPINFO);
            }
        }
    }
    elsif (($fullpath =~ /\.(tar|taz|tbz|tbz2|tgz)$/i) ||
           ($fullpath =~ /\.tar\.(gz|bz|bz2|Z)$/i)) {
        # get list of files via tar system command
        $command = "tar -t -v ";
        if (($fullpath =~ /\.taz$/i) || ($fullpath =~ /\.tar\.Z$/i)) {
            $command .= "-Z ";
        }
        elsif (($fullpath =~ /\.(tbz|tbz2)$/i) || ($fullpath =~ /\.tar\.(bz|bz2)$/i)) {
            $command .= "-j ";
        }
        elsif (($fullpath =~ /\.tgz$/i) || ($fullpath =~ /\.tar\.gz$/i)) {
            $command .= "-z ";
        }
        $command .= "-f $fullpath";
        # if only concerned with selected files, don't pass in files as command line args
        # which may break the pipe due to length.  check on hashed paths instead (BUG25662)
        my %selected_files = ();
        foreach $fpath (@files) {
            $selected_files{$fpath} = "dau!";
        }
      EFFECTIVE: {
            local $> = $source_euid;
            unless (open(TARINFO, "$command |")) {
                warn "tar() for '$fullpath' failed: $!";
            }
            else {
                while (<TARINFO>) {
                    $curline = $_;
                    chomp($curline);
                    $curline =~ /^\S+\s+\S+\s+([0-9]*)\s+\S+\s+\S+\s+(.*)$/;
                    $size = $1;
                    $fpath = $2;
                    next if (($#files >= 0) && (!defined($selected_files{$fpath})));
                    $type = ($fpath =~ m#/$#) ? "dir" : "file";
                    $extracted_files{$fpath}->{'size'} = $size;
                    $extracted_files{$fpath}->{'type'} = $type;
                }
                close(TARINFO);
            }
        }
    }
    else {
        # single compressed file
        $fpath = $fullpath;
        $fpath =~ s/\.(bz|bz2|gz|Z)$//i;
        if ($fullpath =~ /\.Z$/i) {
            # not sure how to determine uncompressed size... skip for now
            $size = 0;
        }
        elsif ($fullpath =~ /\.(bz|bz2)$/i) {
            # not sure how to determine uncompressed size... skip for now
            $size = 0;
        }
        elsif ($fullpath =~ /\.gz$/i) {
            $command = "gzip -l $fullpath";
          EFFECTIVE: {
                local $> = $source_euid;
                unless (open(GZIP, "command |")) {
                    warn "gzip() for '$fullpath' failed: $!";
                }
                else {
                    <GZIP>;  # throw out header line
                    if( defined( $curline = <GZIP> ) ) {
                        $curline =~ s/^\s+//;
                        $curline =~ /\S+\s+([0-9]*)/;
                        $size = $1;
                    }
                    $size ||= 0;
                    close(GZIP);
                }
            }
        }
        $extracted_files{$fpath}->{'size'} = $size;
        $extracted_files{$fpath}->{'type'} = "file";
    }
    my ($new_disk_space_requirements) = 0;
    foreach $fpath (keys(%extracted_files)) {
        $new_disk_space_requirements += $extracted_files{$fpath}->{'size'};
    }
    if ($new_disk_space_requirements) {
        # get quota/usage for owner of the target directory
        unless(diskspace_availability($target_euid, $target_egid, $new_disk_space_requirements))
        {
                $vsap->error($_ERR{'QUOTA_EXCEEDED'} => "Error uncompressing file: quota exceeded");
                return;
        }
    }

    # make sure parent of target exists before attempting extraction/decompression
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = $target_egid;
        local $> = $target_euid;
        unless (-e $fulltarget) {
            system('mkdir', '-p', '--', $fulltarget)
              and do {
                  my $exit = ($? >> 8);
                  $vsap->error($_ERR{'UNCOMPRESS_FAILED'} => "cannot mkdir '$fulltarget' (exitcode $exit)");
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
        $effective_uid = $target_euid;  # default
        $effective_gid = $target_egid;  # default
        if (($source_euid != $target_euid) ||
            ($source_egid != $target_egid)) {
            # need to be super user
            $effective_uid = $effective_gid = 0;
        }
    }


    # uncompress/extract path to target
    my @command = ();
    my @precommand = ();
    my @postcommand = ();
    my $filelistpath = "";
    if ($fullpath =~ /\.zip$/i) {
        push(@precommand, $UNZIP_PATH);
        if( $uncompress_option eq 'skip' ) {
            push @precommand, '-n';
        }
        else {
            push @precommand, '-o';
        }
        push(@precommand, '-qq');
        push(@precommand, '-UU') if (VSAP::Server::Modules::vsap::files::uncompress::IS_CLOUD);
        push(@precommand, $fullpath);
        # @files will be inserted between pre and post insofar as command line length limit not reached
        push(@postcommand, '-d');
        push(@postcommand, $fulltarget);
    }
    elsif (($fullpath =~ /\.(?:tar|taz|tbz|tbz2|tgz)$/i) ||
           ($fullpath =~ /\.tar\.(?:gz|bz|bz2|Z)$/i)) {
        push(@command, $UNTAR_PATH);
        push(@command, '-x');
        if (($fullpath =~ /\.taz$/i) || ($fullpath =~ /\.tar\.Z$/i)) {
            push(@command, '-Z');   ## FIXME: FreeBSD 5.x may not support this option
        }
        elsif (($fullpath =~ /\.(?:tbz|tbz2)$/i) || ($fullpath =~ /\.tar\.(?:bz|bz2)$/i)) {
            push(@command, '-j');
        }
        elsif (($fullpath =~ /\.tgz$/i) || ($fullpath =~ /\.tar\.gz$/i)) {
            push(@command, '-z');
        }
        ## don't clobber existing files during extraction
        if( $uncompress_option eq 'skip' ) {
            push @command, '-k';
        }
        ## keep these options together
        push(@command, '-f', $fullpath);
        if ($#files > -1) {
            push(@command, '-T');
            my ($filename) = (fileparse($fullpath))[0];
            $filelistpath = "/tmp/." . $filename . "-selectedfiles_" . $$;
            open(FLIST, ">$filelistpath");
            print FLIST "$_\n" foreach(@files);
            close(FLIST);
            push(@command, $filelistpath);
        }
        push(@command, '-C');
        push(@command, $fulltarget);
    }
    elsif ($fullpath =~ /\.(?:bz|bz2)$/i) {
        push(@command, 'bunzip2');
        push(@command, '-q');
        if( $uncompress_option eq 'skip' ) {
            ## save a place for a 'rename' option in the future
        }
        else {
            push(@command, '-f');
        }
        push(@command, $fullpath);
    }
    elsif ($fullpath =~ /\.(?:gz|Z)$/i) {
        push(@command, 'gunzip');
        push(@command, '-q');
        if( $uncompress_option eq 'skip' ) {
            ## save a place for a 'rename' option in the future
        }
        else {
            push(@command, '-f');
        }
        push(@command, $fullpath);
    }

    my ($source_size) = (stat($fullpath))[7];
    my $error_status = 0;   ## 0 = happy ... !0 = !happy

    # fork here to uncompress the file(s)... wait for child if the size of the
    # source files seems too large (>200MB), otherwise queue message (BUG21365)
    my $size_threshold = 200 * 1024 * 1024;
  FORK: {
        my $pid;
        if ($pid = fork) {
            # parent
            if ($source_size > $size_threshold ) {
                VSAP::Server::Modules::vsap::user::messages::_queue_add($vsap->{username}, $pid, $$, "FILE_UNCOMPRESS",
                                                                        ( 'source_filename' => $source ,
                                                                          'source_size' => $source_size ) );
                $vsap->error( $_ERR{REQUEST_QUEUED} => "request to compress file queued." );
                $error_status = 250;
                # child is not waited for
            }
            else {
                waitpid($pid, 0);  # the parent waits for the child to finish
            }
        }
        elsif (defined $pid) {
            # child
          EFFECTIVE: {
                local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
                local $) = $effective_gid;
                local $> = $effective_uid;
                # cross your fingers, uncompress, and hope for the best
                my $oldpath = cwd();
                chdir($fulltarget) || warn("can't chdir to $fulltarget: $!");
                if ($fullpath =~ /\.zip$/i) {
                    # build an array of commands that fit under max command line arg length limit
                    if (scalar @files) {
                        my $index = 0;
                        while (scalar @files) {
                            $command[$index] = [ @precommand ];
                            while ( (scalar @files) &&
                                    (length( join(" ", @{$command[$index]}) ) + length($files[0]) +
                                     length( join(" ", @postcommand) )) < $max_arg_list_length ) {
                                push(@{$command[$index]}, shift(@files) );
                            }
                            $command[$index] = [ @{$command[$index]}, @postcommand ];
                            $index++;
                        }
                    }
                    else {
                        $command[0] = [ @precommand, @postcommand ];
                    }
                    # run each command in turn
                    for my $index (0 .. $#command) {
                        system(@{$command[$index]})
                          and do {
                              my $exit = ($? >> 8);
                              if ($exit) {
                                  chdir($oldpath);
                                  $vsap->error($_ERR{'UNCOMPRESS_FAILED'} => "cannot unzip '$fullpath' (exitcode $exit)");
                                  VSAP::Server::Modules::vsap::logger::log_error("cannot unzip '$fullpath' (exitcode $exit)");
                                  $error_status = 103; 
                              }
                          };
                    }
                }
                else {
                    my $pid = open my $pipe_uncomp, '-|';
                    unless( defined $pid ) {
                        chdir $oldpath;
                        $vsap->error( $_ERR{UNCOMPRESS_FAILED} => "unable to fork" );
                        $error_status = 103; 
                    }

                    ## capture stderr/stdout output from uncompress child
                    my $return = '';
                    if( $pid ) {
                        while( <$pipe_uncomp> ) {
                            if( $uncompress_option eq 'skip' ) {
                                next if /file exists/io;    ## NOTE: this message dependent on BSDtar
                                next if /exit delayed/io;   ## NOTE: this message dependent on BSDtar
                            }
                            $return .= $_;
                        }
                    }

                    ## do decompression (this is the child process)
                    else {
                        open STDIN, "/dev/null";        ## detach stdin (for this child only);
                                                        ## this causes gzip/bzip2 to skip
                                                        ## confirmation for overwriting files
                        close STDERR;                   ## necessary per perlfunc 'open'
                        open STDERR, ">& STDOUT";       ## redirect stderr to stdout (parent will capture)
                        exec @command;
                    }

                    ## any unexpected error messages will be in '$return' now
                    if( $@ && $return ) {
                        my $exit = ($? >> 8);
                        if( $exit ) {
                            chdir $oldpath;
                            $vsap->error( $_ERR{UNCOMPRESS_FAILED} => "cannot uncompress '$fullpath' (code $exit)");
                            VSAP::Server::Modules::vsap::logger::log_error("cannot uncompress '$fullpath' (code $exit)");
                            return;
                        }
                    }

                    ## tidy up
                    unlink($filelistpath) if ($filelistpath);
                }
    
                unless ($error_status) {
                    # chown uncompressed files
                    foreach $fpath (keys(%extracted_files)) {
                        if (-l $fpath) {
                            # use system chown
                            system('chown', '-h', "$target_euid:$target_egid", $fpath)
                              and do {
                                  my $exit = ($? >> 8);
                                  warn("cannot chown '$fpath' (exitcode $exit)");
                              };
                        }
                        else {
                            # use perl built-in chown
                            chown($target_euid, $target_egid, $fpath) ||
                                warn("chown() failed on $fpath: $!");
                        }
                        # chown any subdirectories that were created too
                        my ($index, $subdirpath);
                        my @subpaths = split(/\//, $fpath);
                        $subdirpath = "";
                        for ($index=0; $index<$#subpaths; $index++) {
                            $subdirpath .= "/" unless ($subdirpath eq "");
                            $subdirpath .= $subpaths[$index];
                            chown($target_euid, $target_egid, $subdirpath) ||
                                warn("chown() failed on $subdirpath: $!");
                        }
                    }
                }
                chdir($oldpath);
            }
            if ($source_size > $size_threshold ) {
                VSAP::Server::Modules::vsap::user::messages::_job_complete($vsap->{username}, $$);
            }
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} uncompressed archive '$fullpath'");
            exit;  # child dies
        }
        else {
            # fork failure
            sleep(5);
            redo FORK;
        }
    }

    return if ( $error_status != 0 );

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'files:uncompress');
    $root_node->appendTextChild(source => $source);
    $root_node->appendTextChild(source_user => $sourceuser);
    $root_node->appendTextChild(target => $targetdir);
    $root_node->appendTextChild(target_user => $targetuser);
    $root_node->appendTextChild(status => "ok");

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::files::uncompress - VSAP module to uncompress 
archives

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::files::uncompress;

=head1 DESCRIPTION

The VSAP uncompress module allows users to uncompress all files or only
specified files from a file archive.

To uncompress a file archive, you need to specify a source directory, an
optional source user name, an optional list of paths to files in the
file archive, a target directory path name, and an optional target user
name.

The following template represents the generic form of a query to
uncompress a file archive:

  <vsap type="files:uncompress">
    <source>source archive path name</source>
    <source_user>user name</source_user>
    <file>file name</file>
    <file>file name</file>
    <file>file name</file>
    <file>file name</file>
    <target>target directory path name</target>
    <target_user>target directory user name</target_user>
  </vsap>

System Administrators should use the full path name to the source
archive and need not ever include the optional source user name.  Domain
Administrators should use the "virtual path name" for the source
archive, i.e. the path name without prepending the home directory where
the file resides.  If the archive is homed in a one of the Domain 
Administrator's End Users' file spaces, then the '<source_user>' node
should be used.  End Users will also need to use a "virtual path name"
to a file; no '<source_user>' specification is required, as the
authenticated user name is presumed.

The source archive type must be one of the following:

        tar
                A "tar" archive.

        taz
                A compressed "tar" archive using adaptive
                Lempel-Ziv coding.

        tbz 
        tbz2
                A compressed "tar" archive using the
                Burrows-Wheeler block sorting text
                compression algorithm and Huffman coding.

        tgz
                A compressed "tar" archive using Lempel-Ziv
                coding (LZ77).

        zip
                A "zip" archive.

The target directory is the directory where the files will be extracted.
System Administrators should use the full path name to the target
directory and need not ever include the optional target user name.
Domain Administrators should use the "virtual path name" for the target
directory and the '<target_user>' node if required (per the same
methodology of the source directory specification).  End Users will also
need to use a "virtual path name" to a file; no '<target_user>'
specification is required, as the authenticated user name is presumed.

An optional list of one or more file names can be included in the query.
If included, only those files will be extracted from the source archive 
and placed in the target directory.

Consider the following examples:

=over 2

A request made by a System Administrator to uncompress a system archive:

    <vsap type="files:uncompress">
      <source>/root/logs.tar</source>
      <target>/root</target>
    </vsap>

A request made by a Domain Administrator or End User to uncompress some
files from an archive homed in their own home directory structure.

    <vsap type="files:uncompress">
      <source>/archives/my_stuff.zip</source>
      <file>my_cats.jpg</file>
      <file>my_dogs.jpg</file>
      <target>/mystuff/photos</target>
    </vsap>

A request made by a Domain Administrator to archive files homed in the
directory space of an End User.

    <vsap type="files:compress">
      <source_user>scott</source_user>
      <source>/disaster_recovery/content.tgz</source>
      <target_user>scott</target_user>
      <target>/www/data</target>
    </vsap>

=back

If the source archive is valid, and the target directory is accessible
(see NOTES), all of the files (or the specified files) in the archive
will be extracted or an error will be returned.  A successful request
will be indicated by the return '<status>' node.

=head1 NOTES

File Accessibility.  System Administrators are allowed full access to
the file system, therefore the validity of the path name is only
determined whether it exists or not.  However, End Users are restricted
access (or 'jailed') to their own home directory tree.  Domain
Administrators are likewise restricted, but to the home directory trees
of themselves and their end users.  Any attempts at access to files that
are located outside of these valid directories will be denied and an
error will be returned.


=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

