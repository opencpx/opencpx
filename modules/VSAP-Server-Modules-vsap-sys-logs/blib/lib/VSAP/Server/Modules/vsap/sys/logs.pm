package VSAP::Server::Modules::vsap::sys::logs;

use 5.008004;
use strict;
use warnings;
use POSIX qw(uname);
use Cwd qw(abs_path);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.02';

our %_ERR    = (LOGS_PERMISSION             => 100,
                LOGS_NO_PATH                => 101,
                LOGS_NO_DOMAIN              => 102,
                LOGS_OPEN_FAILED            => 103,
                LOGS_DELETE_FAILED          => 104,
                LOGS_DOWNLOAD_FAILED        => 105,
                LOGS_PATH_NOT_FOUND         => 106);


use constant IS_LINUX => ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
use constant IS_APACHE2 => (IS_LINUX || readlink("/www") =~ /apache2/i) ? 1 : 0;

##############################################################################
# subroutines used by more than one package
##############################################################################

sub get_vhost_logs {
    my $domain = shift;
    my %logs;
    local $> = $) = 0;  ## regain privileges for a moment
    open CONF, "/www/conf/httpd.conf" or do {
        #$vsap->error( $_ERR{LOGS_OPEN_FAILED} => "Log file open failed: $!" );
        #return;
    };
    local $_;
    my @vhost = ();

    unless( @vhost ) {
        my $found = 0;
        my $state = 0;
        while(<CONF>) {
            if( m!^\s*<VirtualHost!io ) {
                $state = 1;
                push @vhost, $_;
                next;
            }

            if( $state && m!^\s*</VirtualHost>!io ) {
                $state = 0;
                push @vhost, $_;

                ## is this our vhost?
                unless( $found ) {
                    @vhost = ();
                    next;
                }

                last;  ## all done
            }
            ## in a virtualhost block
            if( $state ) {
                if( /^\s*ServerName\s+\Q$domain\E\s*$/i ) {
                    $found = 1;
                }
                push @vhost, $_;
                next;
            }
        }
        close CONF;
    }

    my $value = '';
    for my $line ( @vhost ) {
        if ($line =~ /\s*(\w+Log)\s+(\S+)/) {
            $logs{$1} = $2;
        }
    }
    return %logs;
}


sub getAbsPath {
  my $path = shift;
  my $absPath;

  REWT: {
    local $> = $) = 0;  ## regain privileges for a moment
    $absPath = abs_path( $path );
  }
  
  return $absPath;
}

##############################################################################
# packages
##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::list;

use Config::Savelogs;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:list' );

    my $log_path = (VSAP::Server::Modules::vsap::sys::logs::IS_LINUX) ? 
                    "/var/log/httpd/" : 
                   ((VSAP::Server::Modules::vsap::sys::logs::IS_APACHE2) ? 
                     "/usr/local/apache2/logs/" : 
                     "/usr/local/apache/logs/");

    # take the supplied domain,
    my $domain =  $xmlobj->child('domain')->value;
    $return->appendTextChild( domain => $domain );

    # check perms
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
    unless ($co->domain_admin(domain => $domain) || $vsap->{server_admin}) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }
    
    # and grab log info for each domain, 
    my %logs;
    if ($domain eq $co->primary_domain()) {
        %logs = (
            CustomLog     => $log_path . "access_log",
            ErrorLog      => $log_path . "error_log",
            SSLCustomLog  => $log_path . "ssl_access_log",
            SSLErrorLog   => $log_path . "ssl_error_log",
            SSLRequestLog => $log_path . "ssl_request_log"
        );
    } else {
        %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);
    }

    ## get all log rotation information from savelogs.conf files
    ## order is important: the latter entries will override the former ones
    my %log_settings = ();
    for my $frequency qw(monthly weekly daily) {
        my $cpx_conf = "/usr/local/etc/savelogs-cpx.$frequency.conf";
        next unless -f $cpx_conf;

        my $sc = new Config::Savelogs($cpx_conf)
          or do {
              warn "Could not open '$cpx_conf': $!\n";
              next;
          };

        my $groups = $sc->data->{groups};
        for my $group ( @$groups ) {
            $group->{frequency} = $frequency;
            my @vhost = (ref($group->{apachehost}) ? @{ $group->{apachehost} } : $group->{apachehost});

            for my $vhost ( @vhost ) {
                $log_settings{$vhost} = $group;
            }
        }
    }

    foreach my $log (keys %logs) {
        my $lognode = $vsap->{_result_dom}->createElement('log');
        $lognode->appendTextChild("domain" => $domain);
        $lognode->appendTextChild("description" => $log);
        $lognode->appendTextChild("path" => $logs{$log});
        unless( $logs{$log} eq "/dev/null") {
            local $> = $) = 0;  ## regain privileges for a moment
            my ($size,$ctime) = (stat($logs{$log}))[7,10];
            $lognode->appendTextChild("size" => $size || 0);
            $lognode->appendTextChild("creation_date" => $ctime || 0);

            if( $log_settings{$domain} ) {
                $lognode->appendTextChild( rotation => $log_settings{$domain}->{frequency} );
            }

            my @archives = VSAP::Server::Modules::vsap::sys::logs::list_archives::_list_archives($logs{$log});
            $lognode->appendTextChild("number_archived", scalar @archives);
        }
        $return->appendChild($lognode);
    }

    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::show;

use DB_File;
use Fcntl;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:show' );

    # get the supplied log
    my $path =  $xmlobj->child('path')->value;
    unless ($path) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Log path missing" );
        return;
    }

    # scrub up user-specified path
    my $fullpath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $path );
    
    # check authorization according the following security model:
    #
    # server administrator
    # can show any log file for any domain
    #
    # domain administrator 
    # can only show log files for domains which they administrate

    my $valid = 0;
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $valid = 1;
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }

        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check for valid path
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);

            foreach my $log (keys %logs) {
                my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                if (($fullpath =~ /^$absPath$/) ||
                    ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                    $valid = 1;
                    last;
                }
            }
        }
    }
    unless ($valid) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }

    # get number of lines and a page number
    my $range = $xmlobj->child('range')->value || 100;
    my $page = $xmlobj->child('page')->value || 1;

    $return->appendTextChild("path" => $path);
    $return->appendTextChild("range" => $range);
    $return->appendTextChild("page" => $page);

    my @lines;
    local $> = $) = 0;  ## regain privileges for a moment
    my $tie = tie(@lines, "DB_File", $fullpath, O_RDWR, 0666, $DB_RECNO) or do {
        $vsap->error( $_ERR{LOGS_OPEN_FAILED} => "Log file open failed: $!" );
        return;
    };
    
    my $totalpages = int(($tie->length / $range) + .5);
    if ($totalpages == 0) { $totalpages = 1 }
    $return->appendTextChild("total_pages" => $totalpages);

    my $reversepage = ($totalpages - $page) + 1;

    my @content;

    my $line;
    my $length = $tie->length - 1;
    my $stop   = $reversepage * $range;
    my $start = ($reversepage - 1) * $range;
    if ($stop > $length) {
      $stop = $length;
      $start = $stop - $range;
    }
    for ($line = $start; $line < $stop; $line++) {
        if ($line > $length || $line < 0) {
            next;
        }
        push @content, $lines[$line];
    }
    untie @lines;

    $return->appendTextChild("content" => join "\n", @content);

    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::search;
        
use DB_File;
use Fcntl;
 
sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:search' );
 
    # get the supplied log
    my $path =  $xmlobj->child('path')->value;   
    # string to search for
    my $string =  $xmlobj->child('string')->value;   
    unless ($path) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Log path missing" );
        return;   
    }

    # scrub up user-specified path
    my $fullpath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $path );

    # check authorization according the following security model:
    #
    # server administrator
    # can search any log file for any domain
    #
    # domain administrator 
    # can only search log files for domains which they administrate

    my $valid = 0;
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $valid = 1;
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check for valid path
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);

            foreach my $log (keys %logs) {
                my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                if (($fullpath =~ /^$absPath$/) ||
                    ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                    $valid = 1;
                    last;
                }
            }
        }
    }
    unless ($valid) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }

    # get number of lines and a page number
    my $range = $xmlobj->child('range')->value || 100;
    my $page = $xmlobj->child('page')->value || 1;
  
    $return->appendTextChild("path" => $path);   
    $return->appendTextChild("range" => $range);
    
    my @lines;
    local $> = $) = 0;  ## regain privileges for a moment
    my $tie = tie(@lines, "DB_File", $path, O_RDWR, 0666, $DB_RECNO) or do {
        $vsap->error( $_ERR{LOGS_OPEN_FAILED} => "Log file open failed: $!" );
        return;
    };

    my $totalpages = int($tie->length / $range + .5);
    $return->appendTextChild("total_pages" => $totalpages);

    my $reversepage = $totalpages - ($page - 1);
    
    my $found = 0;
    my @content;

    while ($found == 0) {
        my $line;
        my $stop   = $reversepage * $range;
        @content = ();
        for ($line = ($reversepage + 1) * $range; $line > $stop; $line--) {
            my $tmpline = $lines[$line - 1];
            if ($tmpline =~ /$string/) {
                $found = 1;
            }
            push @content, $lines[$line - 1];
        }
        $reversepage--;
        if ($found) {
            $page = $totalpages - $reversepage + 1;
            last;
        }
    }

    $return->appendTextChild("page" => $page);

    untie @lines;
     
    $return->appendTextChild("content" => join "\n", @content);

    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::list_archives;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:list_archives' );

    # take the log path, and list archives of that file
    my $path =  $xmlobj->child('path')->value;
    $return->appendTextChild("path" => $path);

    unless ($path) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Log path missing" );
        return;
    }

    # scrub up user-specified path
    my $fullpath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $path );

    # check authorization according the following security model:
    #
    # server administrator
    # can list archives for any log file for any domain
    #
    # domain administrator 
    # can only list archives for log files for domains which they administrate

    my $valid = 0;
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $valid = 1;
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check for valid path
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);

            foreach my $log (keys %logs) {
                my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                if (($fullpath =~ /^$absPath$/) ||
                    ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                    $valid = 1;
                    last;
                }
            }
        }
    }
    unless ($valid) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }

    local $> = $) = 0;  ## regain privileges for a moment
    # list archives; we assume these are in the same location
    my $path_parent_dir = $path;
    $path_parent_dir =~ s/[^\/]+$//;
    foreach my $archive (_list_archives($path)) {
        chomp $archive;
        my $archivenode = $vsap->{_result_dom}->createElement('archive');
        $archive =~ s|/+|/|g;
        $archivenode->appendTextChild("path" => $archive);
        my ($size,$ctime) = (stat($archive))[7,10];
        $archivenode->appendTextChild("size" => $size);
        $archivenode->appendTextChild("creation_date" => $ctime);
        $return->appendChild($archivenode);
    }
     
    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

sub _list_archives {
    my $path = shift;
    my $log = $path;
    local $> = $) = 0;  ## regain privileges for a moment
    $path =~ s/[^\/]+$//;
    $log =~ s/^.+\///;
    opendir DIR, $path or return ();
    my @archives = map {"$path/$_"} grep { /^$log\.\d+\.gz$/ } readdir DIR;
    closedir DIR;
    return @archives;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::archive_settings;

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::archive_now;

use Config::Savelogs;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:archive_now' );

    my $bin_path = (VSAP::Server::Modules::vsap::sys::logs::IS_LINUX) ? 
                    "/usr/sbin/" :
                   ((VSAP::Server::Modules::vsap::sys::logs::IS_APACHE2) ? 
                     "/usr/local/apache2/bin/" :
                     "/usr/local/apache/bin/");

    my $path =  $xmlobj->child('path')->value;
    unless ($path) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Log path missing" );
        return;
    }

    # scrub up user-specified path
    my $fullpath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $path );

    # check authorization according the following security model:
    #
    # server administrator
    # can archive any log file for any domain
    #
    # domain administrator 
    # can only archive log files for domains which they administrate

    my $valid = 0;
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $valid = 1;
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check for valid path
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);

            foreach my $log (keys %logs) {
                my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                if (($fullpath =~ /^$absPath$/) ||
                    ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                    $valid = 1;
                    last;
                }
            }
        }
    }
    unless ($valid) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $domain = $xmlobj->child('domain') ? $xmlobj->child('domain')->value : '';
        my $conf   = '';
        my $period = 30;
        my $chown  = '';

        ## if we already rotate this log, get the settings (otherwise,
        ## the above defaults will apply)
      FREQ: for my $freq qw(daily weekly monthly) {  ## find the right conf file
            $conf = "/usr/local/etc/savelogs-cpx.$freq.conf";
            next unless -f $conf;

            my $sc = new Config::Savelogs($conf)
              or do {
                  warn "Could not open '$conf': $!\n";
                  next FREQ;
              };

            my $group = $sc->find_group( match => { ApacheHost => $domain } )
              or next FREQ;

            if( ref($group) and exists $group->{period} ) {
                $period = $group->{period};

                if( exists $group->{count} and $group->{period} !~ /^\d+$/ ) {
                    $period = $group->{count};
                }
            }

            if( ref($group) and exists $group->{chown} ) {
                $chown = $group->{chown};
            }

            last FREQ;
        }

        my @cmd = ('/usr/local/bin/savelogs',
                   "--period=$period",
                   '--touch');
        push @cmd, ($chown ? "--chown=$chown" : ());
        push @cmd, $fullpath;

      DO_EXEC: {
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} rotated apache log file '$path'");
            system(@cmd);
            ## NOTE: this apache restart must be 'graceful' in order 
            ## NOTE: for the ControlPanel not to die while vsapd is 
            ## NOTE: sending the results of *this* operation back. 
            $vsap->need_apache_restart();
        }

        $return->appendTextChild( period => $period );
        $return->appendTextChild( chown  => $chown ) if $chown;
    }  ## end REWT

    $return->appendTextChild( status => "ok");
    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::del_archive;

use Cwd qw(abs_path);
    
sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    # required: path to one or more log files
    my @paths = ($xmlobj->children('path') ?
                 grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('path') : () );
    if ($#paths == -1) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Archive path(s) missing" );
        return;
    }

    # scrub up user-specified path(s)
    my %fullpaths = ();
    REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        for my $path (@paths) {
            my $fullpath = abs_path($path);
            if (-e $fullpath) {
              $fullpaths{$path} = $fullpath unless ($fullpath eq "/dev/null");
            }
        }
    }
    if (keys(%fullpaths) == 0) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "No valid path(s) found" );
        return;
    }

    # check authorization according the following security model:
    #
    # server administrator
    # can remove any log file for any domain
    #
    # domain administrator 
    # can only remove log files for domains which they administrate

    if ($vsap->{server_admin}) {
        # give plenty of rope
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check each path for validity
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);
            foreach my $path (keys(%fullpaths)) {
                my $valid = 0;
                my $fullpath = $fullpaths{$path};

                foreach my $log (keys %logs) {
                    my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                    if (($fullpath =~ /^$absPath$/) ||
                        ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                        $valid = 1;
                        last;
                    }
                }

                unless ($valid) {
                    $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
                    return;
                }
            }
        }
        else {
            $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
            return;
        }
    }

    my $dom = $vsap->{_result_dom};
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:logs:del_archive');

    # fasten your seat belts, this could get a bit bumpy
    my $success_node = "";
    my $failure_node = "";
    my ($path_node);
    foreach my $path (keys(%fullpaths)) {
        my $fullpath = $fullpaths{$path};
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            if (-e $fullpath) {
                unlink($fullpath)
                  or do {
                      # failure
                      my $mesg = "unlink '$fullpath' failed: $!";
                      unless ($failure_node) {
                          $failure_node = $root_node->appendChild($dom->createElement('failure'));
                      }
                      $path_node = $failure_node->appendChild($dom->createElement('path'));
                      $path_node->appendTextChild(file => $path);
                      $path_node->appendTextChild(code => $_ERR{'LOGS_DELETE_FAILED'});
                      $path_node->appendTextChild(mesg => $mesg);
                      next;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} deleted apache log file '$path'");
                unless ($success_node) {
                    $success_node = $root_node->appendChild($dom->createElement('success'));
                }
                $path_node = $success_node->appendChild($dom->createElement('path'));
                $path_node->appendTextChild(file => $path);
                $path_node->appendTextChild(status => "ok");
            }
            else {
                my $mesg = "unlink '$fullpath' failed: path not found";
                unless ($failure_node) {
                    $failure_node = $root_node->appendChild($dom->createElement('failure'));
                }
                $path_node = $failure_node->appendChild($dom->createElement('path'));
                $path_node->appendTextChild(file => $path);
                $path_node->appendTextChild(code => $_ERR{'LOGS_PATH_NOT_FOUND'});
                $path_node->appendTextChild(mesg => $mesg);
            }
        }
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::logs::download;

use File::Basename qw(fileparse);
    
sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    # required: path to log file
    my $path =  $xmlobj->child('path')->value;
    unless ($path) {
        $vsap->error( $_ERR{LOGS_NO_PATH} => "Archive path missing" );
        return;
    }

    # scrub up user-specified path
    my $fullpath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $path );

    # check authorization according the following security model:
    #
    # server administrator
    # can download any log file for any domain
    #
    # domain administrator 
    # can only download log files for domains which they administrate

    my $valid = 0;
    if ($vsap->{server_admin}) {
        # give plenty of rope
        $valid = 1;
    }
    else {
        # required for domain administrators: domain name
        my $domain =  $xmlobj->child('domain')->value;
        unless ($domain) {
            $vsap->error( $_ERR{LOGS_NO_DOMAIN} => "Domain name missing" );
            return;
        }
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        if ($co->domain_admin(domain => $domain)) {
            # valid domain... now check for valid path
            my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs($domain);

            foreach my $log (keys %logs) {
                my $absPath = VSAP::Server::Modules::vsap::sys::logs::getAbsPath( $logs{$log} );

                if (($fullpath =~ /^$absPath$/) ||
                    ($fullpath =~ /^$absPath\.\d+\.gz$/)) {
                    $valid = 1;
                    last;
                }
            }
        }
    }
    unless ($valid) {
        $vsap->error( $_ERR{LOGS_PERMISSION} => "Not authorized" );
        return;
    }

    # access is authorized; time to work the "download" black magic
    my $fsize = 0;
    my $downloadpath = "";
    unless ($fullpath eq "/dev/null") {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            if (-e "$fullpath") {
                # create a link in vsap tmp directory
                $downloadpath = $vsap->{tmpdir} . "/";
                $downloadpath .= time() . "-" . $$ . ".download";

                link($fullpath, $downloadpath)
                  or do {
                      $vsap->error($_ERR{'LOGS_DOWNLOAD_FAILED'} => "create link for download failed: $!");
                      return;
                  };
                # set g+rw perms and web user ownership so file can be read/unlinked
                my $web_owner = ( VSAP::Server::Modules::vsap::sys::logs::IS_LINUX ) ? "apache" : "www";
                
                my ( $login, $pass, $uid, $gid ) = getpwnam( $web_owner );
                chown -1, $gid, $downloadpath or warn( "change group failed on '$downloadpath'" );
                chmod 0660, $downloadpath or warn( "chmod failed on '$downloadpath'" );
                  
                # need file size
                ($fsize) = (lstat($fullpath))[7];
            }
        }
    }
    unless ($downloadpath) {
        $vsap->error($_ERR{'LOGS_PATH_NOT_FOUND'} => "download failed: file not found");
        return;
    }

    # append trace to log file
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} requested to download log file '$path'");

    # everything seems to be ok
    my ($filename) = fileparse($fullpath);
    my $return = $vsap->{_result_dom}->createElement('vsap');
    $return->setAttribute( type => 'sys:logs:download' );
    $return->appendTextChild("format" => "download");
    $return->appendTextChild("filename" => $filename);
    $return->appendTextChild("url_filename" => $filename);
    $return->appendTextChild("mime_type" => "application/x-download");
    $return->appendTextChild("path" => $downloadpath);
    $return->appendTextChild("source" => $fullpath);
    $return->appendTextChild("size" => $fsize);
    $vsap->{_result_dom}->documentElement->appendChild($return);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::logs - Perl extension for listing, viewing, and archiving web log files.

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::logs;

=head1 DESCRIPTION

The VSAP logs module performs listing of web logs, browsing of their contents,
as well as listing and browsing of log archives.

=head2 sys:logs:list

Listing logs for a given domain:

  <vsap type="sys:logs:list">
    <domain>tuesday.securesites.net</domain>
  </vsap>

returns:

  <vsap type="sys:logs:list">
    <log>
      <domain>tuesday.securesites.net</domain>
      <description>ErrorLog</description>
      <path>/usr/local/apache/logs/error_log</path>
      <size>1197421</size>
      <creation_date>1121673925</creation_date>
      <rotation>daily</rotation>
      <number_archived>3</number_archived>
    </log>
    <log>
      <domain>tuesday.securesites.net</domain>
      <description>TransferLog</description>
      <path>/usr/local/apache/logs/access_log</path>
      <size>887291242</size>
      <creation_date>1121673925</creation_date>
      <rotation>daily</rotation>
      <number_archived>3</number_archived>
    </log>
    <log>
      <domain>tuesday.securesites.net</domain>
      <description>RefererLog</description>
      <path>/usr/local/apache/logs/referer_log</path>
      <size>241288733</size>
      <creation_date>1121673925</creation_date>
    </log>
  </vsap>

Listing logs for all domains under current user (NOT YET IMPLEMENTED!):

  <vsap type="sys:logs:list"/>

returns:

  <vsap type="sys:logs:list">
    <log>
      <domain>tuesday.securesites.net</domain>
      <description>ErrorLog</description>
      <path>/usr/local/apache/logs/error_log</path>
      <size>1197421</size>
      <creation_date> </creation_date>
      <archiving_enabled/>
      <number_archived>3</number_archived>
    </log>
    <log>
      <domain>tuesday.securesites.net</domain>
      <description>CombinedLog</description>
      <path>/usr/local/apache/logs/all_log</path>
      <size>1197421</size>
      <creation_date> </creation_date>
      <archiving_enabled/>
      <number_archived>3</number_archived>
    </log>
    <log>
      <domain>plethora.net</domain>
      <description>ErrorLog</description>
      <path>/usr/local/apache/logs/error_log</path>
      <size>74521</size>
      <creation_date></creation_date>
    </log>
  </vsap>

=head2 sys:logs:show

Note that paging begins at the end of log files; i.e. page 1 is the end of the file.

Show contents of log file (query made by a system administrator):

  <vsap type="sys:logs:show">
    <path>/usr/local/apache/logs/error_log</path>
    <range>100</range>
    <page>2</page>
  </vsap>

returns:

  <vsap type="sys:logs:show">
    <path>/usr/local/apache/logs/error_log</path>
    <range>100</range>
    <page>2</page>
    <total_pages>144</total_pages>
    <content>
      64.173.22.123 - - [18/Jul/2005:00:42:32 -0600] "GET /Blogs/Images/pedro.jpg HTTP
      ...
    </content>
  </vsap>

A query made by a domain administrator must include a '<domain>' node.  
For example:

  <vsap type="sys:logs:show">
    <domain>tabasco.com</domain>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.0.gz</path>
    <range>100</range>
    <page>1</page>
  </vsap>

=head2 sys:logs:search

Note that searching behaves like paging, with the search beginning at the end of the log if the page is 1. The "range" here is not the range for the search, but the range for the "currently displayed" page, where the search will begin. The "page" parameter in the request document is page on which to begin the search, but the "page" parameter in the response is the page (given the range) on which the string occurs, and which is contained in "content".

Search for first occurance of string in log:

  <vsap type="sys:logs:search">
    <path>/usr/local/apache/logs/error_log</path>
    <string>64.173.22.123</string>
    <range>100</range>
    <page>2</page>
  </vsap>

returns (with match results highlighted in "match"):

  <vsap type="sys:logs:search">
    <path>/usr/local/apache/logs/error_log</path>
    <string>10.0.1.4</string>
    <range>100</range>
    <page>16</page>
    <content>
      <match>64.173.22.123</match> - - [18/Jul/2005:00:42:32 -0600] "GET /Blogs/Images/pedro.jpg HTTP
      ...
    </content> 
  </vsap>

A query made by a domain administrator must include a '<domain>' node.  
For example:

  <vsap type="sys:logs:search">
    <domain>tabasco.com</domain>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.0.gz</path>
    <string>64.173.22.123</string>
    <range>100</range>
    <page>1</page>
  </vsap>

=head2 sys:logs:list_archives

This is almost identical to sys:logs:list, but takes an additional "path" parameter containing the original (unarchived) log source.

  <vsap type="sys:logs:list_archives">
    <path>/usr/local/apache/logs/error_log</path>
  </vsap>

returns:

  <vsap type="sys:logs:list_archives">
    <path>/usr/local/apache/logs/error_log</path>
    <archive>
      <path>/usr/local/apache/logs/error_log</path>
      <size>1197421</size>
      <creation_date> </creation_date>
    </archive>
    <archive>  
      <path>/usr/local/apache/logs/error_log</path>
      <size>1197421</size>
      <creation_date> </creation_date>
    </archive>
    <archive>  
      <path>/usr/local/apache/logs/error_log</path>
      <size>1197421</size>
      <creation_date> </creation_date>
    </archive>
  </vsap>

=head2 sys:logs:del_archive

Allows a server administrator or a domain administrator to delete a log
file.  Server administrators need only include the path name to the log
file.  However, domain administrators must also provide a domain name.
This is necessary to enforce a strict security model where domain
administrators may only delete log files (or log archives) for the
domain names which they administrate.  Consider the following examples:

=over 2

A request by a server administrator to delete a log archive.

  <vsap type="sys:logs:del_archive">
    <path>/usr/local/apache/logs/error_log.050308.gz</path>
    <path>/usr/local/apache/logs/error_log.050729.gz</path>
    <path>/usr/local/apache/logs/error_log.050803.gz</path>
    <path>/usr/local/apache/logs/error_log.050819.gz</path>
     .
     .
     .
  </vsap>

A request by a domain administrator to delete a log archive.

  <vsap type="sys:logs:del_archive">
    <domain>tabasco.com</domain>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.0.gz</path>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.1.gz</path>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.2.gz</path>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.3.gz</path>
     .
     .
     .
  </vsap>

=back

If the path to the log file is valid and the authenticated user has 
permission to access the log, the archive will be deleted or an error
will be returned.

=head2 sys:logs:download

Allows a server administrator or a domain administrator to "download" a 
log file.  The file is not actually downloaded per se, but instead a 
hard link is created to the log file in the user's VSAP temporary 
directory (vsap->{tmpdir}).  Subsequent action is required to read the 
file from this temporary location and then unlink the link to the log
file.

When making a "download" request, server administrators need only 
include the path name to the log file.  However, domain administrators 
must also provide a domain name.  This is necessary to enforce a strict 
security model where domain administrators may only download log files 
(or log archives) for the domain names which they administrate.  
Consider the following examples:

=over 2

A request by a server administrator to download a log archive.

  <vsap type="sys:logs:download">
    <path>/usr/local/apache/logs/error_log.050819.gz</path>
  </vsap>

A request by a domain administrator to download a log archive.

  <vsap type="sys:logs:download">
    <domain>tabasco.com</domain>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log.050819.gz</path>
  </vsap>

=back

If the path to the log file is valid and the authenticated user has 
permission to access the log, a link to the archive will be made in
the user's VSAP temporary directory or an error will be returned.

=head2 sys:logs:archive_now

Archives the log "now".  For system administrators, the path to the
log files is all that is required.  For example:

  <vsap type="sys:logs:archive_now">
    <path>/usr/local/apache/logs/error_log</path>
  </vsap>

However, for domain administrators, the path to the log file must be
coupled with a <domain> node specification.  For example:

  <vsap type="sys:logs:archive_now">
    <domain>tabasco.com</domain>
    <path>/usr/local/apache/logs/quuxfoo/tabasco.com-access_log</path>
  </vsap>

=head1 AUTHOR

Dan Brian

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
