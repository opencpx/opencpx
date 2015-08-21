package VSAP::Server::Modules::vsap::sys::monitor;

use 5.008004;
use strict;
use warnings;

use Authen::SASL;
use Config::Crontab;
use Email::Valid;
use Encode;
use File::Basename qw(fileparse);
use Net::SMTP;
use Net::SMTP::TLS;
use POSIX qw(uname);

use VSAP::Server::G11N::Mail;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_pref get_prefs );

##############################################################################

use constant LOCK_EX => 2;

our %_ERR = (
              ERR_NOT_AUTHORIZED             => 100,
              ERR_INTERVAL_INVALID           => 200,
              ERR_NOTHING_TO_MONITOR         => 201,
              ERR_NO_NOTIFY_SELECTED         => 202,
              ERR_MAX_NOTIFY_BLANK           => 203,
              ERR_MAX_NOTIFY_INVALID         => 204,
              ERR_EMAIL_ADDRESS_BLANK        => 205,
              ERR_EMAIL_ADDRESS_INVALID      => 206,
              ERR_REMOTE_MAIL_SERVER_INVALID => 207,
              ERR_REMOTE_AUTH_USERNAME_BLANK => 208,
              ERR_REMOTE_AUTH_PASSWORD_BLANK => 209,
              ERR_REMOTE_MAIL_CONNECT_FAIL   => 210,
              ERR_REMOTE_MAIL_AUTH_FAIL      => 211,
            );

our $IS_LINUX = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

our $VERSION = (-e "/usr/local/cp/RELEASE") ? `/bin/cat /usr/local/cp/RELEASE` : "0.12";
chomp($VERSION);

# where is swaks?
our $SWAKS = "/usr/bin/swaks";

##############################################################################

## monitoring prefs file
our $PREFS_FILE = '/usr/local/share/cpx/monitor_prefs';

## monitoring remote email server auth creds file
our $REMOTE_AUTH_CREDS = '/usr/local/share/cpx/.monitor/smtp_auth_creds';

## where is the notification data stored?
our $NOTIFY_DATA = '/usr/local/share/cpx/.monitor/notify_data';

## default prefs
our %DEFAULT_PREFS = (
                      'monitor_interval' => '0',  ## off
                      'autorestart_service_dovecot' => '1',
                      'autorestart_service_ftp' => '1',
                      'autorestart_service_httpd' => '1',
                      'autorestart_service_imap' => '1',
                      'autorestart_service_imaps' => '1',
                      'autorestart_service_inetd' => '1',
                      'autorestart_service_mailman' => '1',
                      'autorestart_service_mysqld' => '0',
                      'autorestart_service_pop3' => '1',
                      'autorestart_service_pop3s' => '1',
                      'autorestart_service_postfix' => '1',
                      'autorestart_service_postgresql' => '0',
                      'autorestart_service_sendmail' => '1',
                      'autorestart_service_ssh' => '1',
                      'autorestart_service_vsapd' => '1',
                      'notify_events' => '-1',  ## until restarted
                      'notify_service_dovecot' => '1',
                      'notify_service_ftp' => '1',
                      'notify_service_httpd' => '1',
                      'notify_service_imap' => '1',
                      'notify_service_imaps' => '1',
                      'notify_service_inetd' => '1',
                      'notify_service_mailman' => '1',
                      'notify_service_mysqld' => '1',
                      'notify_service_postfix' => '1',
                      'notify_service_pop3' => '1',
                      'notify_service_pop3s' => '1',
                      'notify_service_postfix' => '1',
                      'notify_service_postgresql' => '1',
                      'notify_service_sendmail' => '1',
                      'notify_service_ssh' => '1',
                      'notify_service_vsapd' => '1',
                      'notify_server_reboot' => '1',
                      'notify_email_address' => '',
                      'notify_email_server' => '',
                      'notify_smtp_auth_username' => '',
                      'notify_smtp_auth_password' => '',
                      'locale' => 'en_US',
                     );

our @PREFS_SORT_ORDER = (
                      'monitor_interval',
                      'autorestart_service_dovecot',
                      'autorestart_service_ftp',
                      'autorestart_service_httpd',
                      'autorestart_service_imap',
                      'autorestart_service_imaps',
                      'autorestart_service_inetd',
                      'autorestart_service_mailman',
                      'autorestart_service_mysqld',
                      'autorestart_service_pop3',
                      'autorestart_service_pop3s',
                      'autorestart_service_postfix',
                      'autorestart_service_postgresql',
                      'autorestart_service_sendmail',
                      'autorestart_service_ssh',
                      'autorestart_service_vsapd',
                      'notify_events',
                      'notify_service_dovecot',
                      'notify_service_ftp',
                      'notify_service_httpd',
                      'notify_service_imap',
                      'notify_service_imaps',
                      'notify_service_inetd',
                      'notify_service_mailman',
                      'notify_service_mysqld',
                      'notify_service_pop3',
                      'notify_service_pop3s',
                      'notify_service_postfix',
                      'notify_service_postgresql',
                      'notify_service_sendmail',
                      'notify_service_ssh',
                      'notify_service_vsapd',
                      'notify_server_reboot',
                      'notify_email_address',
                      'notify_email_server',
                      'notify_smtp_auth_username',
                      'notify_smtp_auth_password',
                      'locale',
                     );

##############################################################################

sub _audit
{
    my %prefs = @_;

    my @files = ( $VSAP::Server::Modules::vsap::sys::monitor::PREFS_FILE,
                  $VSAP::Server::Modules::vsap::sys::monitor::REMOTE_AUTH_CREDS );

    # audit ownership and perms of important files (and their parent directories)
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        foreach my $fullpath (@files) {
            my ($file, $parent_dir) = fileparse($fullpath);
            # does parent directory exist?
            unless (-e $parent_dir) {
                system('mkdir', '-p', '--', $parent_dir)
                  and do {
                      my $exit = ($? >> 8);
                      VSAP::Server::Modules::vsap::logger::log_error("cannot mkdir '$parent_dir' (exitcode $exit)");
                  };
            }
            # parent directory should be owned by root
            chown(0, 0, $parent_dir)
              or do {
                  VSAP::Server::Modules::vsap::logger::log_error("cannot chown '$parent_dir' ($!)");
              };
            # parent directory for auth creds should be rwx only for root
            if ($fullpath =~ /smtp_auth_creds/) {
                chmod(0700, $parent_dir)
                  or do {
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed ($!)");
                  };
            }
            # check ownership and perms of file itself
            next unless (-e "$fullpath");
            chown(0, 0, $fullpath)
              or do {
                  VSAP::Server::Modules::vsap::logger::log_error("cannot chown '$fullpath' ($!)");
              };
            if ($fullpath =~ /smtp_auth_creds/) {
                # read/write only for root
                chmod(0600, $fullpath)
                  or do {
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed ($!)");
                  };
            }
            else {
                # read/write for root; read for everyone else
                chmod(0644, $fullpath)
                  or do {
                      VSAP::Server::Modules::vsap::logger::log_error("chmod() for $fullpath failed ($!)");
                  };
            }
        }
    }

    # build the minutes field for the cron entry
    my $cmf = ($prefs{'monitor_interval'} == 1) ? "*" :
              ($prefs{'monitor_interval'} == 60) ? "0" : "*/$prefs{'monitor_interval'}";

    # check existence of crontab entries (or lack thereof)
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 );
        $ct->read;
        # this remove() call just keeps new events from accumulating
        $ct->remove( $ct->block( $ct->select( -type       => 'event',
                                              -user       => 'root',
                                              -command_re => qr(/usr/local/cp/sbin/monitor) ) ) );
        # add monitor event as required
        if ($prefs{'monitor_interval'}) {
            my $block = new Config::Crontab::Block;
            $block->last( new Config::Crontab::Comment( -data => '## Control Panel service monitoring system' ) );
            if ($prefs{'notify_email_address'}) {
                $block->last( new Config::Crontab::Env( -name => 'MAILTO', -value => $prefs{'notify_email_address'} ) );
            }
            $block->last( new Config::Crontab::Event( -minute => $cmf,
                                                      -user    => 'root',
                                                      -command => qq!/usr/local/cp/sbin/monitor 2>/dev/null 1>/dev/null! ) );
            $ct->last($block);
        }
        $ct->write;
    }

    # reset service notification counts
    if (($prefs{'monitor_interval'} == 0) || ($prefs{'notify_events'} == 0)) {
        VSAP::Server::Modules::vsap::sys::monitor::_reset_notification_data();
    }
}

#-----------------------------------------------------------------------------

sub _disable
{
    # remove crontab
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 );
        $ct->read;
        # remove the crontab entry
        $ct->remove( $ct->block( $ct->select( -type       => 'event',
                                              -user       => 'root',
                                              -command_re => qr(/usr/local/cp/sbin/monitor) ) ) );
        $ct->write;
    }

    # reset service notification counts
    VSAP::Server::Modules::vsap::sys::monitor::_reset_notification_data();
}

#-----------------------------------------------------------------------------

sub _enable
{
    my %prefs = @_;

    # build the minutes field for the cron entry
    my $cmf = ($prefs{'monitor_interval'} == 1) ? "*" :
              ($prefs{'monitor_interval'} == 60) ? "0" : "*/$prefs{'monitor_interval'}";

    # add crontab
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 );
        $ct->read;
        # this remove() call just keeps new events from accumulating
        $ct->remove( $ct->block( $ct->select( -type       => 'event',
                                              -user       => 'root',
                                              -command_re => qr(/usr/local/cp/sbin/monitor) ) ) );
        my $block = new Config::Crontab::Block;
        $block->last( new Config::Crontab::Comment( -data => '## Control Panel service monitoring system' ) );
        if ($prefs{'notify_email_address'}) {
            $block->last( new Config::Crontab::Env( -name => 'MAILTO', -value => $prefs{'notify_email_address'} ) );
        }
        $block->last( new Config::Crontab::Event( -minute => $cmf,
                                                  -user    => 'root',
                                                  -command => qq!/usr/local/cp/sbin/monitor 2>/dev/null 1>/dev/null! ) );
        $ct->last($block);
        $ct->write;
    }
}

#-----------------------------------------------------------------------------

sub _is_installed_dovecot
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dovecot = `$rpm -q dovecot 2>&1`;
            $installed = ($dovecot =~ /is not installed/) ? 0 : 1;
        }
    }
    else {
        my $cmd = '/usr/sbin/pkg_info -x dovecot >/dev/null 2>&1';
        $installed = 1 if ( ! system($cmd) );
    }

    if ($IS_LINUX && $installed && (-e "/var/run/dovecot")) {
        # on Linux, check /etc/xinetd.d to see if popa3ds, popa3d, imaps, and imap are disabled
        my @xfiles = ("/etc/xinetd.d/imap", "/etc/xinetd.d/imaps",
                      "/etc/xinetd.d/popa3d", "/etc/xinetd.d/popa3ds");
        my $disabled = 1;
        foreach my $xfile (@xfiles) {
            local $/;  # enable "slurp" mode
            if (open(XFP, $xfile)) {
                my $config = <XFP>;
                close(XFP);
                if ($config =~ m#disable\s*=\s*no#is) {
                    $disabled = 0;
                }
                last unless ($disabled);
            }
        }
        $installed = $disabled;
    }

    return($installed);
}

#-----------------------------------------------------------------------------

sub _is_installed_mailman
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $mailman = `$rpm -q mailman 2>&1`;
            $installed = ($mailman =~ /is not installed/) ? 0 : 1;
        }
    }
    else {
        my $cmd = '/usr/sbin/pkg_info -x mailman >/dev/null 2>&1';
        $installed = 1 if ( ! system($cmd) );
    }
    return($installed);
}

#-----------------------------------------------------------------------------

sub _is_installed_mysql
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
        my $mysql4x = "";
        my $mysql50 = "";
        my $mysql5x = "";
        my $mysql5c = "";
        my $mysql_generic = "";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $mysql4x = `$rpm -q mysql-verio-server 2>&1`;
            $mysql50 = `$rpm -q mysql-server-community 2>&1`;
            $mysql5x = `$rpm -q mysql-server.i386 2>&1`;
            $mysql5c = `$rpm -q MySQL-server.i386 2>&1`;
            $mysql_generic = `/bin/rpm -q mysql 2>&1`;
        }
        if (($mysql4x =~ /is not installed/) && ($mysql50 =~ /is not installed/) &&
            ($mysql5x =~ /is not installed/) && ($mysql5c =~ /is not installed/) &&
            ($mysql_generic =~ /is not installed/)) {
            $installed = 0;
        }
        else {
            $installed = 1;
        }
    }
    else {
        # a reliable way to determine if mysql is installed on FreeBSD?  (BUG35017)
        my $cmd = '/usr/sbin/pkg_info -x mysql-server >/dev/null 2>&1';
        $installed = 1 if ( ! system($cmd) );
    }
    return($installed);
}

#-----------------------------------------------------------------------------

sub _is_installed_postfix
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $postfix = `$rpm -q postfix 2>&1`;
            $installed = ($postfix =~ /is not installed/) ? 0 : 1;
        }
    }
    else {
        my $cmd = '/usr/sbin/pkg_info -x postfix >/dev/null 2>&1';
        $installed = 1 if ( ! system($cmd) );
    }
    return($installed);
}

#-----------------------------------------------------------------------------

sub _is_installed_postgresql
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $postgresql = `$rpm -q postgresql 2>&1`;
            $installed = ($postgresql =~ /is not installed/) ? 0 : 1;
        }
    }
    else {
        my $cmd = '/usr/sbin/pkg_info -x postgresql >/dev/null 2>&1';
        $installed = 1 if ( ! system($cmd) );
    }
    return($installed);
}

#-----------------------------------------------------------------------------

sub _is_installed_sendmail
{
    my $installed = 0;

    if ((-e "/bin/rpm") || (-e "/usr/bin/rpm")) {
        my $rpm = (-e "/bin/rpm") ? "/bin/rpm" : "/usr/bin/rpm";
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $sendmail = `$rpm -q sendmail 2>&1`;
            $installed = ($sendmail =~ /is not installed/) ? 0 : 1;
        }
    }
    else {
        $installed = 1;  ## always installed
    }
    return($installed);
}

#-----------------------------------------------------------------------------

sub _read_prefs
{
    my %prefs = %VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS;

    my @files = ( $VSAP::Server::Modules::vsap::sys::monitor::PREFS_FILE,
                  $VSAP::Server::Modules::vsap::sys::monitor::REMOTE_AUTH_CREDS );

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        foreach my $file (@files) {
            open(PREFS_FILE, $file) || next;
            while (<PREFS_FILE>) {
                next unless /^[a-zA-Z]/;
                s/\s+$//g;
                if (/(.*)="?(.*?)"?$/) {
                    my $name = $1;
                    $name =~ tr/A-Z/a-z/;
                    my $value = $2;
                    next unless (defined($prefs{$name}));  # skip unknown pref
                    if ($name =~ /^(monitor|notify)_service/) {
                        $value = ($value =~ /^(y|1)/i) ? 1 : 0;
                    }
                    $prefs{$name} = $value;
                }
            }
            close(PREFS_FILE);
        }
    }
    return(%prefs);
}

#-----------------------------------------------------------------------------

sub _reset_notification_data
{
    my $service = shift || "";

    my %data = ();
    $data{'reboot'} = time();  ## default

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment

        # load up last saved
        if (open(MYDATA, "$NOTIFY_DATA")) {
            while (<MYDATA>) {
                s/\s+$//g;
                /(.*):(.*)/;
                $data{$1} = $2;
            }
            close(MYDATA);
        }

        if ($service) {
            # reset specified service only
            $data{$service} = 0;
        }
        else {
            # reset everything but 'reboot'
            foreach my $key (keys(%data)) {
                next if ($key eq 'reboot');
                $data{$key} = 0;
            }
        }

        open(NEWDATA, ">$NOTIFY_DATA") || return;
        flock(NEWDATA, LOCK_EX) || return;
        foreach my $key (sort(keys(%data))) {
            next if ($key eq 'reboot');
            print NEWDATA "$key:$data{$key}\n";
        }
        print NEWDATA "reboot:$data{'reboot'}\n";
        close(NEWDATA);
    }
}

#-----------------------------------------------------------------------------

sub _save_prefs
{
    my %prefs = @_;

    my @files = ( $VSAP::Server::Modules::vsap::sys::monitor::PREFS_FILE,
                  $VSAP::Server::Modules::vsap::sys::monitor::REMOTE_AUTH_CREDS );

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        foreach my $file (@files) {
            open(NEW_PREFS_FILE, ">$file.$$")
              or do {
                  VSAP::Server::Modules::vsap::logger::log_error("open(>$file.$$) failed: $!");
                  next;
              };
            if (-e "$file") {
                open(CUR_PREFS_FILE, "$file")
                  or do {
                      VSAP::Server::Modules::vsap::logger::log_error("open($file) failed: $!");
                      next;
                  };
                while (<CUR_PREFS_FILE>) {
                    my $curline = $_;
                    if (/^[a-zA-Z]/) {
                        s/\s+$//g;
                        tr/A-Z/a-z/;
                        if (/(.*)="?(.*?)"?$/) {
                            my $name = $1;
                            my $value = $2;
                            if (exists($prefs{$name})) {
                                $curline = "$name=$prefs{$name}\n";
                                # keep track what has been saved and what hasn't been saved
                                $prefs{$name} = "these are not the droids you are looking for";
                            }
                            else {
                                # probably should do something here
                            }
                        }
                    }
                    print NEW_PREFS_FILE $curline;
                }
                close(CUR_PREFS_FILE);
            }
            # write out prefs still in hash
            foreach my $pref (@PREFS_SORT_ORDER) {
                next if ($prefs{$pref} eq "these are not the droids you are looking for");
                if ($file =~ /smtp_auth_creds/) {
                    next unless (($pref eq 'notify_email_server') ||
                                 ($pref eq 'notify_smtp_auth_username') ||
                                 ($pref eq 'notify_smtp_auth_password'));
                }
                else {
                    next if (($pref eq 'notify_email_server') ||
                             ($pref eq 'notify_smtp_auth_username') ||
                             ($pref eq 'notify_smtp_auth_password'));
                }
                print NEW_PREFS_FILE "$pref=$prefs{$pref}\n";
            }
            close(NEW_PREFS_FILE);
            rename("$file.$$", $file)
              or do {
                  VSAP::Server::Modules::vsap::logger::log_error("rename($file.$$, $file) failed: $!");
                  next;
              };
        }
    }
    return(1);
}

##############################################################################

sub get_pref
{
    my $pref = shift;

    my @name = ( "$pref" );
    my $value = VSAP::Server::Modules::vsap::sys::monitor::get_prefs(@name);
    return($value);
}

##############################################################################

sub get_prefs
{
    my @keys = shift;

    my %all = VSAP::Server::Modules::vsap::sys::monitor::_read_prefs();

    if ($#keys >= 0) {
        my %wanted = ();
        foreach my $key (@keys) {
            next unless(defined($DEFAULT_PREFS{$key}));
            $wanted{$key} = $all{$key};
        }
        return wantarray ? %wanted : $wanted{$keys[0]};
    }

    return(%all);
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::monitor::get;

sub handler {
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # load 'em
    my %prefs = VSAP::Server::Modules::vsap::sys::monitor::_read_prefs();

    # while we are here... run an audit on the monitoring system
    VSAP::Server::Modules::vsap::sys::monitor::_audit(%prefs);

    # is dovecot installed?  find out
    my $dovecot_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_dovecot();

    # is mailman installed?  find out
    my $mailman_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mailman();

    # is mysql installed?  find out
    my $mysql_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mysql();

    # is postfix installed?  find out
    my $postfix_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postfix();

    # is postgresql installed?  find out
    my $postgresql_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postgresql();

    # is sendmail installed?  find out
    my $sendmail_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_sendmail();

    # build return dom
    my $password_on_file = 0;
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:monitor:get');
    foreach my $pref (sort(keys(%prefs))) {
        my $value = $prefs{$pref};
        if ($pref =~ /notify_smtp_auth_password/) {
            $password_on_file = 1 if ($value ne "");
            next;
        }
        $root_node->appendTextChild($pref => $value);
    }
    $root_node->appendTextChild('dovecot_installed' => $dovecot_installed);
    $root_node->appendTextChild('mailman_installed' => $mailman_installed);
    $root_node->appendTextChild('mysql_installed' => $mysql_installed);
    $root_node->appendTextChild('postfix_installed' => $postfix_installed);
    $root_node->appendTextChild('postgresql_installed' => $postgresql_installed);
    $root_node->appendTextChild('sendmail_installed' => $sendmail_installed);
    $root_node->appendTextChild('password_on_file' => $password_on_file);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::monitor::set;

sub handler {
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # monitor interval (in minutes, 0 == off)
    my $monitor_interval = $xmlobj->child('monitor_interval') ? $xmlobj->child('monitor_interval')->value : '0';

    # per service monitor prefs
    my $autorestart_service_dovecot = $xmlobj->child('autorestart_service_dovecot') ?
                                      $xmlobj->child('autorestart_service_dovecot')->value : '0';
    my $autorestart_service_ftp = $xmlobj->child('autorestart_service_ftp') ?
                                  $xmlobj->child('autorestart_service_ftp')->value : '0';
    my $autorestart_service_httpd = $xmlobj->child('autorestart_service_httpd') ?
                                    $xmlobj->child('autorestart_service_httpd')->value : '0';
    my $autorestart_service_imap = $xmlobj->child('autorestart_service_imap') ?
                                   $xmlobj->child('autorestart_service_imap')->value : '0';
    my $autorestart_service_imaps = $xmlobj->child('autorestart_service_imaps') ?
                                    $xmlobj->child('autorestart_service_imaps')->value : '0';
    my $autorestart_service_inetd = $xmlobj->child('autorestart_service_inetd') ?
                                    $xmlobj->child('autorestart_service_inetd')->value : '0';
    my $autorestart_service_mailman = $xmlobj->child('autorestart_service_mailman') ?
                                      $xmlobj->child('autorestart_service_mailman')->value : '0';
    my $autorestart_service_mysqld = $xmlobj->child('autorestart_service_mysqld') ?
                                     $xmlobj->child('autorestart_service_mysqld')->value : '0';
    my $autorestart_service_pop3 = $xmlobj->child('autorestart_service_pop3') ?
                                   $xmlobj->child('autorestart_service_pop3')->value : '0';
    my $autorestart_service_pop3s = $xmlobj->child('autorestart_service_pop3s') ?
                                    $xmlobj->child('autorestart_service_pop3s')->value : '0';
    my $autorestart_service_postfix = $xmlobj->child('autorestart_service_postfix') ?
                                      $xmlobj->child('autorestart_service_postfix')->value : '0';
    my $autorestart_service_postgresql = $xmlobj->child('autorestart_service_postgresql') ?
                                         $xmlobj->child('autorestart_service_postgresql')->value : '0';
    my $autorestart_service_sendmail = $xmlobj->child('autorestart_service_sendmail') ?
                                       $xmlobj->child('autorestart_service_sendmail')->value : '0';
    my $autorestart_service_ssh = $xmlobj->child('autorestart_service_ssh') ?
                                  $xmlobj->child('autorestart_service_ssh')->value : '0';
    my $autorestart_service_vsapd = $xmlobj->child('autorestart_service_vsapd') ?
                                    $xmlobj->child('autorestart_service_vsapd')->value : '0';

    # send notifications (-1 == until restarted, 0 == none, N = max)
    my $notify_events = $xmlobj->child('notify_events') ? $xmlobj->child('notify_events')->value : '0';
    my $notify_events_max = $xmlobj->child('notify_events_max') ?
                            $xmlobj->child('notify_events_max')->value : '';

    # per service notify prefs
    my $notify_service_dovecot = $xmlobj->child('notify_service_dovecot') ?
                                 $xmlobj->child('notify_service_dovecot')->value : '0';
    my $notify_service_ftp = $xmlobj->child('notify_service_ftp') ?
                               $xmlobj->child('notify_service_ftp')->value : '0';
    my $notify_service_httpd = $xmlobj->child('notify_service_httpd') ?
                               $xmlobj->child('notify_service_httpd')->value : '0';
    my $notify_service_imap = $xmlobj->child('notify_service_imap') ?
                              $xmlobj->child('notify_service_imap')->value : '0';
    my $notify_service_imaps = $xmlobj->child('notify_service_imaps') ?
                               $xmlobj->child('notify_service_imaps')->value : '0';
    my $notify_service_inetd = $xmlobj->child('notify_service_inetd') ?
                               $xmlobj->child('notify_service_inetd')->value : '0';
    my $notify_service_mailman = $xmlobj->child('notify_service_mailman') ?
                                 $xmlobj->child('notify_service_mailman')->value : '0';
    my $notify_service_mysqld = $xmlobj->child('notify_service_mysqld') ?
                                $xmlobj->child('notify_service_mysqld')->value : '0';
    my $notify_service_pop3 = $xmlobj->child('notify_service_pop3') ?
                              $xmlobj->child('notify_service_pop3')->value : '0';
    my $notify_service_pop3s = $xmlobj->child('notify_service_pop3s') ?
                               $xmlobj->child('notify_service_pop3s')->value : '0';
    my $notify_service_postfix = $xmlobj->child('notify_service_postfix') ?
                                 $xmlobj->child('notify_service_postfix')->value : '0';
    my $notify_service_postgresql = $xmlobj->child('notify_service_postgresql') ?
                                    $xmlobj->child('notify_service_postgresql')->value : '0';
    my $notify_service_sendmail = $xmlobj->child('notify_service_sendmail') ?
                                  $xmlobj->child('notify_service_sendmail')->value : '0';
    my $notify_service_ssh = $xmlobj->child('notify_service_ssh') ?
                             $xmlobj->child('notify_service_ssh')->value : '0';
    my $notify_service_vsapd = $xmlobj->child('notify_service_vsapd') ?
                               $xmlobj->child('notify_service_vsapd')->value : '0';
    my $notify_server_reboot = $xmlobj->child('notify_server_reboot') ?
                               $xmlobj->child('notify_server_reboot')->value : '0';

    # notification e-mail address and remote server/creds
    my $notify_email_address = $xmlobj->child('notify_email_address') ?
                               $xmlobj->child('notify_email_address')->value : '';
    my $notify_email_server = $xmlobj->child('notify_email_server') ?
                              $xmlobj->child('notify_email_server')->value : '';
    my $notify_smtp_auth_username = $xmlobj->child('notify_smtp_auth_username') ?
                                    $xmlobj->child('notify_smtp_auth_username')->value : '';
    my $notify_smtp_auth_password = $xmlobj->child('notify_smtp_auth_password') ?
                                    $xmlobj->child('notify_smtp_auth_password')->value : '';

    # reboot notify prefs
    my $notify_reboot = $xmlobj->child('notify_reboot') ? $xmlobj->child('notify_reboot')->value : '0';

    # locale
    my $locale = $xmlobj->child('locale') ? $xmlobj->child('locale')->value : 'en_US';

    # check for server admin
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOT_AUTHORIZED} => "Not authorized to set monitoring preferences");
        return;
    }

    # check for valid monitor_interval (e.g. factor of 60)
    if ($monitor_interval == 0) {
        # zero is allowed
    }
    elsif (($monitor_interval > 0) && ($monitor_interval <= 60) && ((60 % $monitor_interval) == 0)) {
        # factor of 60 is allowed
        # [1,2,3,4,5,6,10,12,15,20,30,60]
    }
    else {
        # 不行! (not allowed!)
        $vsap->error($_ERR{ERR_INTERVAL_INVALID} => "Monitoring interval invalid.");
        return;
    }

    # is dovecot installed?  find out
    my $dovecot_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_dovecot();

    # is mailman installed?  find out
    my $mailman_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mailman();

    # is mysql installed?  find out
    my $mysql_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mysql();

    # is postfix installed?  find out
    my $postfix_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postfix();

    # is postgresql installed?  find out
    my $postgresql_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postgresql();

    # is sendmail installed?  find out
    my $sendmail_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_sendmail();

    # if monitoring on, one service should be selected (inetd doesn't count)
    if ( ($monitor_interval != 0) &&
         (!$dovecot_installed || ($dovecot_installed && !$autorestart_service_dovecot)) &&
         (!$autorestart_service_ftp) &&
         (!$autorestart_service_httpd) &&
         ($dovecot_installed || (!$dovecot_installed && !$autorestart_service_imap)) &&
         ($dovecot_installed || (!$dovecot_installed && !$autorestart_service_imaps)) &&
         (!$mailman_installed || ($mailman_installed && !$autorestart_service_mailman)) &&
         (!$mysql_installed || ($mysql_installed && !$autorestart_service_mysqld)) &&
         ($dovecot_installed || (!$dovecot_installed && !$autorestart_service_pop3)) &&
         ($dovecot_installed || (!$dovecot_installed && !$autorestart_service_pop3s)) &&
         (!$postfix_installed || ($postfix_installed && !$autorestart_service_postfix)) &&
         (!$postgresql_installed || ($postgresql_installed && !$autorestart_service_postgresql)) &&
         (!$sendmail_installed || ($sendmail_installed && !$autorestart_service_sendmail)) &&
         (!$autorestart_service_ssh) &&
         (!$autorestart_service_vsapd) &&
         ($notify_events eq '0') ) {
        # monitoring turned on, but nothing to monitor!
        $vsap->error($_ERR{ERR_NOTHING_TO_MONITOR} => "Monitoring is on; but nothing to monitor!");
        return;
    }

    # load up current prefs
    my %prefs = VSAP::Server::Modules::vsap::sys::monitor::_read_prefs();

    # validate notification settings only if monitoring is turned on
    if ($monitor_interval != 0) {
        # need at least one service selected for notifications (inetd doesn't count)
        if ( (($notify_events eq '-1') || ($notify_events eq 'N')) &&
               (!$dovecot_installed || ($dovecot_installed && !$notify_service_dovecot)) &&
               (!$notify_service_ftp) &&
               (!$notify_service_httpd) &&
               ($dovecot_installed || (!$dovecot_installed && !$notify_service_imap)) &&
               ($dovecot_installed || (!$dovecot_installed && !$notify_service_imaps)) &&
               (!$mailman_installed || ($mailman_installed && !$notify_service_mailman)) &&
               (!$mysql_installed || ($mysql_installed && !$notify_service_mysqld)) &&
               ($dovecot_installed || (!$dovecot_installed && !$notify_service_pop3)) &&
               ($dovecot_installed || (!$dovecot_installed && !$notify_service_pop3s)) &&
               (!$postfix_installed || ($postfix_installed && !$notify_service_postfix)) &&
               (!$postgresql_installed || ($postgresql_installed && !$notify_service_postgresql)) &&
               (!$sendmail_installed || ($sendmail_installed && !$notify_service_sendmail)) &&
               (!$notify_service_ssh) &&
               (!$notify_service_vsapd) &&
               (!$notify_server_reboot)) {
            # notifications turned on, but nothing to monitor!
            $vsap->error($_ERR{ERR_NO_NOTIFY_SELECTED} => "No service selected for notifications.");
            return;
        }
        # if notify for N events, then value for max notifications cannot be blank
        if (($notify_events eq 'N') && ($notify_events_max eq "")) {
            # must provide value for max notifications
            $vsap->error($_ERR{ERR_MAX_NOTIFY_BLANK} => "Must supply value for max notifications.");
            return;
        }
        # if notify for N events, then value for max notifications must be an integer greater than 0
        if (($notify_events eq 'N') && (($notify_events_max == "0") || ($notify_events_max =~ /[^0-9]/))) {
            # value for max notifications is invalid
            $vsap->error($_ERR{ERR_MAX_NOTIFY_INVALID} => "Value for max notifications is invalid.");
            return;
        }
        if (($notify_events == -1) || ($notify_events eq 'N')) {
            # notification e-mail address cannot be blank
            if ($notify_email_address eq "") {
                # must provide value for email address
                $vsap->error($_ERR{ERR_EMAIL_ADDRESS_BLANK} => "Must provide value for email address.");
                return;
            }
            # check e-mail address validity
            unless (Email::Valid->address($notify_email_address)) {
                # value for email address is invalid
                $vsap->error($_ERR{ERR_EMAIL_ADDRESS_INVALID} => "Value for email address is invalid.");
                return;
            }
            # check smtp server hostname/ip validity
            if (0) {
                # FIXME: insert a domain/ip validity regex above
                $vsap->error($_ERR{ERR_REMOTE_MAIL_SERVER_INVALID} => "Mail server appears to be invalid.");
                return;
            }
            # use saved password if form password is blank (and username is not blank)
            if (($notify_smtp_auth_password eq "") && ($prefs{'notify_smtp_auth_password'} ne "") &&
                ($notify_smtp_auth_username ne "")) {
                # inherit password that is already on file
                $notify_smtp_auth_password = $prefs{'notify_smtp_auth_password'};
            }
            # smtp username can't be blank if a password is provided
            if (($notify_smtp_auth_username eq "") && ($notify_smtp_auth_password ne "")) {
                $vsap->error($_ERR{ERR_REMOTE_AUTH_USERNAME_BLANK} => "Must provide value for remote email server username.");
                return;
            }
            # smtp password can't be blank if a username is provided
            if (($notify_smtp_auth_username ne "") && ($notify_smtp_auth_password eq "")) {
                $vsap->error($_ERR{ERR_REMOTE_AUTH_PASSWORD_BLANK} => "Must provide value for remote email server password.");
                return;
            }
            # send a monitor settings confirmation message (if changes to applicable settings are pending)
            my $new_notify_events = ($notify_events eq 'N') ? $notify_events_max : $notify_events;
            my $changes = ( ($prefs{'monitor_interval'} != $monitor_interval) ||
                            ($prefs{'notify_events'} != $new_notify_events) ||
                            ($prefs{'notify_email_address'} ne $notify_email_address) ||
                            ($prefs{'notify_email_server'} ne $notify_email_server) ||
                            ($prefs{'notify_smtp_auth_username'} ne $notify_smtp_auth_username) ||
                            ($prefs{'notify_smtp_auth_password'} ne $notify_smtp_auth_password) ) ? 1 : 0;
            if ($changes) {
                # test the SMTP(/TLS) connection
                my $test_email_server = $notify_email_server || 'localhost';
                my $hostname = $vsap->{hostname} || (POSIX::uname())[1];
                my $stringpath = "/usr/local/cp/strings/" . $locale . "/cp_admin.xml";
                local $/;  # enable "slurp" mode
                open(SFP, $stringpath);
                my $strings = <SFP>;
                close(SFP);
                # notification message subject
                $strings =~ m#<monitor_test_message_subject>(.*)</monitor_test_message_subject>#is;
                my $subject = $1;
                # notification message body
                $strings =~ m#<monitor_test_message_body>(.*)</monitor_test_message_body>#is;
                my $msgbody = $1;
                $msgbody =~ s/__HOSTNAME__/$hostname/;
                my $encoding = ($locale =~ /^ja/i) ? "ISO-2022-JP" : "UTF-8";
                Encode::from_to($msgbody, "UTF-8", $encoding);
                my $gmail = VSAP::Server::G11N::Mail->new( { 'DEFAULT_ENCODING' => 'UTF-8' } );
                my $enc_subject = $gmail->set_subject( { from_encoding    => 'UTF-8',
                                                         to_encoding      => $encoding,
                                                         subject          => Encode::decode_utf8($subject) } );
                $enc_subject =~ s/\n//g;  # remove evil spirits
                my $message;
                $message .= "To: $notify_email_address\n";
                $message .= "Subject: $enc_subject\n";
                if (-e "$SWAKS") {
                    $message .= "X-Mailer: Swaks Hot Pepper Sauce v$VERSION\n";
                }
                $message .= "MIME-Version: 1.0\n";
                $message .= "Content-Type: text/plain; charset=\"$encoding\"; format=\"flowed\"\n";
                $message .= "\n";
                $message .= "$msgbody\n";
                my $sender = 'root@' . $hostname;
                if (-e "$SWAKS") {
                    # use the Swiss Army Knife for SMTP (SWAKS)
                    my @command;
                    push(@command, $SWAKS);
                    push(@command, '--hide-all');  # be quiet
                    push(@command, '--server');
                    push(@command, $test_email_server);
                    push(@command, '--helo');
                    push(@command, $hostname);
                    if ($notify_smtp_auth_username && $notify_smtp_auth_password) {
                        push(@command, '-tlso');  # attempt to use TLS if available
                        push(@command, '--auth-user');
                        push(@command, $notify_smtp_auth_username);
                        push(@command, '--auth-password');
                        push(@command, $notify_smtp_auth_password);
                    }
                    push(@command, '--to');
                    push(@command, $notify_email_address);
                    push(@command, '--from');
                    push(@command, $sender);
                    push(@command, '--data');
                    push(@command, $message);
                    system(@command)
                      and do {
                          my $exit = ($? >> 8);
                          VSAP::Server::Modules::vsap::logger::log_error("SMTP/TLS connection failed for $test_email_server ($exit)");
                          if ($notify_smtp_auth_username && $notify_smtp_auth_password) {
                              $vsap->error($_ERR{ERR_REMOTE_MAIL_AUTH_FAIL} => "Authentication to remote server with user/pass failed.");
                          }
                          else {
                              $vsap->error($_ERR{ERR_REMOTE_MAIL_CONNECT_FAIL} => "SMTP connection failed for $test_email_server ($@)");
                          }
                          return;
                      };
                }
                else {
                    my $smtp;
                    if ($notify_smtp_auth_username && $notify_smtp_auth_password) {
                        # try TLS first if user/pass provided
                        eval {
                            $smtp = Net::SMTP::TLS->new($test_email_server,
                                                        Hello => $hostname,
                                                        User => $notify_smtp_auth_username,
                                                        Password => $notify_smtp_auth_password,
                                                        Timeout => 10 );
                        };
                        if ($@) {
                            VSAP::Server::Modules::vsap::logger::log_error("SMTP/TLS connection failed for $test_email_server ($@)");
                        }
                    }
                    unless (defined($smtp)) {
                        # non-TLS connect
                        eval {
                            $smtp = Net::SMTP->new(Host => $test_email_server,
                                                   Hello => $hostname,
                                                   Timeout => 10);
                        };
                        if ($@) {
                            VSAP::Server::Modules::vsap::logger::log_error("SMTP connection failed for $test_email_server");
                            $vsap->error($_ERR{ERR_REMOTE_MAIL_CONNECT_FAIL} => "SMTP connection failed for $test_email_server ($@)");
                            return;
                        }
                        # check remote smtp server creds (if applicable)
                        if ($notify_smtp_auth_username && $notify_smtp_auth_password) {
                            if (!$smtp->auth($notify_smtp_auth_username, $notify_smtp_auth_password)) {
                                VSAP::Server::Modules::vsap::logger::log_error("SMTP basic auth failed for $test_email_server");
                                $vsap->error($_ERR{ERR_REMOTE_MAIL_AUTH_FAIL} => "Authentication to remote server with user/pass failed.");
                                $smtp->quit();
                                return;
                            }
                        }
                    }
                    $smtp->mail($sender);
                    $smtp->to($notify_email_address);
                    $smtp->data();
                    $smtp->datasend($message);
                    $smtp->dataend();
                    $smtp->quit();
                }
                # reset notification data
                VSAP::Server::Modules::vsap::sys::monitor::_reset_notification_data();
            }
        }
    }

    # set autorestart_service_inetd based on whether or not inetd services are monitored
    if ($dovecot_installed) {
        $autorestart_service_inetd = $autorestart_service_ftp || $autorestart_service_ssh;
    }
    else {
        $autorestart_service_inetd = $autorestart_service_ftp || $autorestart_service_ssh ||
                                     $autorestart_service_imap || $autorestart_service_imaps ||
                                     $autorestart_service_pop3 || $autorestart_service_pop3s;
    }

    # set notify_service_inetd to 0
    $notify_service_inetd = 0;

    # overwrite previously saved prefs with new user data (where applicable)
    $prefs{'monitor_interval'} = $monitor_interval;
    if ($monitor_interval != 0) {
        $prefs{'autorestart_service_dovecot'} = $autorestart_service_dovecot if ($dovecot_installed);
        $prefs{'autorestart_service_ftp'} = $autorestart_service_ftp;
        $prefs{'autorestart_service_httpd'} = $autorestart_service_httpd;
        $prefs{'autorestart_service_imap'} = $autorestart_service_imap if (!$dovecot_installed);
        $prefs{'autorestart_service_imaps'} = $autorestart_service_imaps if (!$dovecot_installed);
        $prefs{'autorestart_service_inetd'} = $autorestart_service_inetd;
        $prefs{'autorestart_service_mailman'} = $autorestart_service_mailman if ($mailman_installed);
        $prefs{'autorestart_service_mysqld'} = $autorestart_service_mysqld if ($mysql_installed);
        $prefs{'autorestart_service_pop3'} = $autorestart_service_pop3 if (!$dovecot_installed);
        $prefs{'autorestart_service_pop3s'} = $autorestart_service_pop3s if (!$dovecot_installed);
        $prefs{'autorestart_service_postfix'} = $autorestart_service_postfix if ($postfix_installed);
        $prefs{'autorestart_service_postgresql'} = $autorestart_service_postgresql if ($postgresql_installed);
        $prefs{'autorestart_service_sendmail'} = $autorestart_service_sendmail if ($sendmail_installed);
        $prefs{'autorestart_service_ssh'} = $autorestart_service_ssh;
        $prefs{'autorestart_service_vsapd'} = $autorestart_service_vsapd;
        $prefs{'notify_events'} = ($notify_events eq 'N') ? $notify_events_max : $notify_events;
        if (($notify_events == -1) || ($notify_events eq 'N')) {
            $prefs{'notify_service_dovecot'} = $notify_service_dovecot if ($dovecot_installed);
            $prefs{'notify_service_ftp'} = $notify_service_ftp;
            $prefs{'notify_service_httpd'} = $notify_service_httpd;
            $prefs{'notify_service_imap'} = $notify_service_imap if (!$dovecot_installed);
            $prefs{'notify_service_imaps'} = $notify_service_imaps if (!$dovecot_installed);
            $prefs{'notify_service_inetd'} = $notify_service_inetd;
            $prefs{'notify_service_mailman'} = $notify_service_mailman if ($mailman_installed);
            $prefs{'notify_service_mysqld'} = $notify_service_mysqld if ($mysql_installed);
            $prefs{'notify_service_pop3'} = $notify_service_pop3 if (!$dovecot_installed);
            $prefs{'notify_service_pop3s'} = $notify_service_pop3s if (!$dovecot_installed);
            $prefs{'notify_service_postfix'} = $notify_service_postfix if ($postfix_installed);
            $prefs{'notify_service_postgresql'} = $notify_service_postgresql if ($postgresql_installed);
            $prefs{'notify_service_sendmail'} = $notify_service_sendmail if ($sendmail_installed);
            $prefs{'notify_service_ssh'} = $notify_service_ssh;
            $prefs{'notify_service_vsapd'} = $notify_service_vsapd;
            $prefs{'notify_server_reboot'} = $notify_server_reboot;
            $prefs{'notify_email_address'} = $notify_email_address;
            $prefs{'notify_email_server'} = $notify_email_server;
            $prefs{'notify_smtp_auth_username'} = $notify_smtp_auth_username;
            $prefs{'notify_smtp_auth_password'} = $notify_smtp_auth_password;
        }
    }
    $prefs{'locale'} = $locale;

    # save prefs
    VSAP::Server::Modules::vsap::sys::monitor::_save_prefs(%prefs);

    # run an audit to enable (or disable) monitoring
    VSAP::Server::Modules::vsap::sys::monitor::_audit(%prefs);

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:monitor:set');
    $root_node->appendTextChild(status => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::monitor - VSAP module to monitor system services

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::monitor;

=head1 DESCRIPTION

The VSAP chmod module allows a server administrator to configure the
system monitoring service (turn on/off, change settings, etc).

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

