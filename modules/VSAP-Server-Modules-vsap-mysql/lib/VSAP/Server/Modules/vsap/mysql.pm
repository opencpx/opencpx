package VSAP::Server::Modules::vsap::mysql;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::sys::monitor;

##############################################################################

our $VERSION = '0.12';

our %_ERR =
(
    ERROR_PASSWORD_MISSING         => 100,
    ERROR_PASSWORD_MISMATCH        => 101,
    ERROR_PASSWORD_CHANGE_FAILED   => 102,
    ERROR_LOGROTATE_CREATE_FAILED  => 200,
    ERROR_LOGROTATE_UPDATE_FAILED  => 201,
    ERROR_LOGROTATE_SANITY_FAILED  => 202,
    ERROR_LOGROTATE_TOGGLE_FAILED  => 203,
    ERROR_PERMISSION_DENIED        => 500,
);

our $LOGROTATE_MY_CONF       = '/root/.my.cnf';
our $LOGROTATE_ENABLED_DIR   = '/etc/logrotate.d/';
our $LOGROTATE_DISABLED_DIR  = '/etc/logrotate.d/disabled/';
our $LOGROTATE_SCRIPT        = 'mysql';

our $LOGROTATE_D_CONFIG = <<_ENDCONFIG;
/var/log/mysql.log /var/log/mysql/*.log {
    notifempty
    daily
    rotate 5
    missingok
    create 644 mysql mysql
    nocompress
    sharedscripts
    postrotate
      test -x /usr/bin/mysqladmin || exit 0
      MYADMIN="/usr/bin/mysqladmin --defaults-file=/etc/mysql/logrotate.cnf"
      if [ -z "`/usr/bin/mysqladmin ping 2>/dev/null`" ]; then
        if killall -q -s0 -umysql mysqld; then
          exit 1
        fi 
      else
        /usr/bin/mysqladmin flush-logs
      fi
    endscript
}
_ENDCONFIG

##############################################################################

sub _logrotate_conf_create
{
    my $passwd = shift;

    local $> = $) = 0;  ## got rewt?

    my $warn = <<_ENDWARN;
# WARNING! WARNING! WARNING!
#
# Edit this file at your own risk. It is highly recommended that this
# password only be changed via the control panel. Do not change the
# user.
#
# WARNING! WARNING! WARNING!
#
_ENDWARN

    open(CONF, ">$LOGROTATE_MY_CONF") || return 0;
    print CONF $warn;
    print CONF "[mysqladmin]\n";
    print CONF "user=\"root\"\n";
    print CONF "password=\"$passwd\"\n";
    close(CONF);

    # set permissions
    chmod(0600, $LOGROTATE_MY_CONF);

    return(1);
}

# ----------------------------------------------------------------------------

sub _logrotate_conf_password
{
    local $> = $) = 0;  ## got rewt?

    open(CONF, "<$LOGROTATE_MY_CONF");
    my @conf = <CONF>;
    close CONF;

    my $passwd = '';
    foreach my $line ( @conf ) {
        next unless ($line =~ /^password/);
        chomp($line);
        my ($key, $val) = split(/\s*=\s*/, $line);
        $val =~ s/(^"|"$)//g;
        $passwd = $val;
        last;
    }
    return($passwd);
}

# ----------------------------------------------------------------------------

sub _logrotate_conf_sanity_check
{
    my $passwd = shift;

    local $> = $) = 0;  ## got rewt?

    return(0) unless (-d $LOGROTATE_ENABLED_DIR);
    unless (-d $LOGROTATE_ENABLED_DIR) {
        mkdir($LOGROTATE_ENABLED_DIR) || return(0);
    }

    my $enabled_path = $LOGROTATE_ENABLED_DIR . $LOGROTATE_SCRIPT;
    my $disabled_path = $LOGROTATE_ENABLED_DIR . $LOGROTATE_SCRIPT;

    return(1) if ((-e $enabled_path) || (-e $disabled_path));

    # logrotate.d config not found; create as "disabled" by default
    open(CONFIG, ">$disabled_path") || return(0);
    print CONFIG $LOGROTATE_D_CONFIG;
    close(CONFIG);

    # set permissions
    chmod(0664, $disabled_path);

    return(1);
}

# ----------------------------------------------------------------------------

sub _logrotate_conf_update
{
    my $passwd = shift;

    local $> = $) = 0;  ## got rewt?

    # create config unless exist
    unless (-e "$LOGROTATE_MY_CONF") {
        return(VSAP::Server::Modules::vsap::mysql::_logrotate_conf_create($passwd));
    }

    # load up config
    open CONF, "<$LOGROTATE_MY_CONF";
    my @conf = <CONF>;
    close CONF;

    # make a backup
    my $config_backup = $LOGROTATE_MY_CONF . '-bak';
    rename($LOGROTATE_MY_CONF, $config_backup);

    # write out new config
    if (open(CONF, ">$LOGROTATE_MY_CONF")) {
        foreach my $line ( @conf ) {
            if ($line =~ /^password/) {
                print CONF "password=\"$passwd\"\n";
            }
            else {
                print CONF $line;
            }
        }
        close(CONF);
    }
    else {
       rename($config_backup, $LOGROTATE_MY_CONF);
       return(0);
    }

    # try to keep a tiny bit of security
    chmod(0600, $LOGROTATE_MY_CONF);

    return 1;
}

##############################################################################

sub set_root_password
{
    my $root_passwd = shift;

    local $> = $) = 0;  ## got rewt?

    ## seems obvious to check if mysql is installed
    my $is_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mysql();
    return(1) unless ($is_installed);

    ## figure out how to stop and start the service
    my $mysql_command = '';
    if (-e "/sbin/service") {
        $mysql_command = '/sbin/service '. (-e "/etc/init.d/mysqld") ? 'mysqld' : 'mysql';
    }
    else {
        # FreeBSD
        $mysql_command = (-e "/usr/local/etc/rc.d/mysql-server") ?
                             '/usr/local/etc/rc.d/mysql-server' :
                             '/usr/local/etc/rc.d/mysql-server.sh';
    }

    ## build a mysql init file
    my $tmpfile = "/tmp/mysql-$$.tmp";
    open MYINIT, ">$tmpfile" or return "Can't open output: $tmpfile ($!)";
    print MYINIT "SET PASSWORD FOR 'root'\@'localhost' = PASSWORD('$root_passwd')\;\n";
    print MYINIT "SET PASSWORD FOR 'root'\@'127.0.0.1' = PASSWORD('$root_passwd')\;\n";
    print MYINIT "FLUSH PRIVILEGES\;\n";
    close MYINIT;

    ## stop mysqld
    system("$mysql_command stop > /dev/null 2>&1");

    ## backup the my.cnf
    open CNF, "</etc/my.cnf";
    my @cnf = <CNF>;
    close CNF;
    rename('/etc/my.cnf', '/etc/my.cnf.bak');

    ## add init_file directive to reset the password
    my @newcnf;
    foreach my $line (@cnf) {
        push @newcnf, $line;
        if (($line =~ /[mysqld]/) || ($line =~ /[mysqld_safe]/)) {
            push @newcnf, "init_file=$tmpfile\n";
        }
    }

    ## write the changes
    open CNF, ">/etc/my.cnf";
    print CNF @newcnf;
    close CNF;

    ## start mysqld which changes the password
    system("$mysql_command start > /dev/null 2>&1");

    ## take a nap
    sleep(3);

    ## leave mysqld running with the init_file arg, but revert the my.cnf file
    ## it should be okay... and we don't have to wait for mysqld to restart
    rename('/etc/my.cnf.bak', '/etc/my.cnf');
    unlink($tmpfile);

    return(0);
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::config;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # check for server admin
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
        return;
    }

    # get the password
    my $passwd = ( $xmlobj->child('new_password') &&
                             $xmlobj->child('new_password')->value
                             ? $xmlobj->child('new_password')->value : '' );

    # get the password confirmation
    my $confirm_passwd = ( $xmlobj->child('confirm_password') &&
                             $xmlobj->child('confirm_password')->value
                             ? $xmlobj->child('confirm_password')->value : '' );

    # check for password
    unless ($passwd) {
        $vsap->error($_ERR{ERROR_PASSWORD_MISSING} => "Password missing");
        return;
    }

    # do the passwords match?
    my $passwords_match = ($passwd == $confirm_passwd);
    unless ($passwords_match) {
        $vsap->error($_ERR{ERROR_PASSWORD_MISMATCH} => "Password mismatch");
        return;
    }

    # set the mysqld root password
    my $fail = VSAP::Server::Modules::vsap::mysql::set_root_password($passwd);
    if ($fail) {
        $vsap->error($_ERR{PASSWORD_CHANGE_FAILED} => "Password change failed: exitcode=$fail");
        return;
    }

    # handle mysql logrotate stuff (if applicable)
    if ($VSAP::Server::Modules::vsap::globals::IS_LINUX) {
        # make sure the system logrotate config exits in logrotate.d
        unless (VSAP::Server::Modules::vsap::mysql::_logrotate_sanity_check()) {
            $vsap->error($_ERR{ERROR_LOGROTATE_SANITY_FAILED} => "Cannot create config file in logrotate.d.");
        }
        # create/update the local root .my.cnf file
        if (-e "$LOGROTATE_MY_CONF") {
            # update the root .my.cnf file
            unless (VSAP::Server::Modules::vsap::mysql::_logrotate_conf_update($passwd)) {
                $vsap->error($_ERR{ERROR_LOGROTATE_UPDATE_FAILED} => "Cannot update root .my.cnf file.");
            }
        }
        else {
            # create the logrotate root .my.cnf file
            unless (VSAP::Server::Modules::vsap::mysql::_logrotate_conf_create($passwd)) {
                $vsap->error($_ERR{ERROR_LOGROTATE_CREATE_FAILED} => "Cannot create root .my.cnf file.");
            }
        }
    }

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mysql:config');
    $root_node->appendTextChild(status => "success");
    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::logrotate::status;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # check for server admin
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
        return;
    }

    # make sure the logrotate.d config exits (at least in a disabled state)
    unless (VSAP::Server::Modules::vsap::mysql::_logrotate_sanity_check()) {
        $vsap->error($_ERR{ERROR_LOGROTATE_SANITY_FAILED} => "Cannot create config file in logrotate.d.");
    }

    my $enabled_path = $LOGROTATE_ENABLED_DIR . $LOGROTATE_SCRIPT;
    my $disabled_path = $LOGROTATE_DISABLED_DIR . $LOGROTATE_SCRIPT;

    local $> = $) = 0;  ## got rewt?

    # get logrotate status
    my $status = 'off';
    $status = 'on' if (-e $enabled_path);

    # do we have a password in LOGROTATE_MY_CONF
    my $password_on_file = 'no';
    my $passwd = VSAP::Server::Modules::vsap::mysql::_logrotate_conf_password();
    $password_on_file = 'yes' if ($passwd ne '');

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mysql:logrotate:status');
    $root_node->appendTextChild(status => $status);
    $root_node->appendTextChild(pw_exists => $password_on_file);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::logrotate::toggle;

use VSAP::Server::Modules::vsap::logger;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # check for server admin
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
        return;
    }

    # make sure the logrotate.d config exits (at least in a disabled state)
    unless (VSAP::Server::Modules::vsap::mysql::_logrotate_sanity_check()) {
        $vsap->error($_ERR{ERROR_LOGROTATE_SANITY_FAILED} => "Cannot create config file in logrotate.d.");
    }

    # get the requested state ('on' or 'off')
    my $new_state = ( $xmlobj->child('state') &&
                      $xmlobj->child('state')->value
                      ? $xmlobj->child('state')->value : 'off' );

    # make sure the logrotate config exits
    VSAP::Server::Modules::vsap::mysql::_logrotate_sanity_check();

    my $enabled_path = $LOGROTATE_ENABLED_DIR . $LOGROTATE_SCRIPT;
    my $disabled_path = $LOGROTATE_DISABLED_DIR . $LOGROTATE_SCRIPT;

    local $> = $) = 0;  ## got rewt?

    # get current logrotate status
    my $status = 'off';
    $status = 'on' if (-e $enabled_path);

    # do we have a password in LOGROTATE_MY_CONF
    my $password_on_file = 'no';
    my $passwd = VSAP::Server::Modules::vsap::mysql::_logrotate_conf_password();
    $password_on_file = 'yes' if ($passwd ne '');

    my $msg = 'success';
    my $source = '';
    my $target = '';

    # does the state need to be toggled?
    if (($status eq 'on') && ($new_state eq 'off')) {
        # disable from active state
        $source = $enabled_path;
        $target = $disabled_path;
    }
    elsif (($status eq 'off') && ($new_state eq 'on')) {
        # enable from inactive state
        $source = $disabled_path;
        $target = $enabled_path;
        $msg = "WARN_NO_PASSWORD_ON_FILE" if ($password_on_file eq 'no');
    }
    else {
        # do nothing
    }

    if ($source && $target) {
        rename($source, $target)
          or do {
              $vsap->error($_ERR{'ERROR_LOGROTATE_TOGGLE_FAILED'} => "move '$source' to '$target' failed: $!");
              VSAP::Server::Modules::vsap::logger::log_error("move '$source' to '$target' failed: $!");
              return;
          };
    }

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mysql:logrotate:toggle');
    $root_node->appendTextChild(status => $new_state);
    $root_node->appendTextChild(message => $msg);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mysql -  VSAP helper module for managing mySQL

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mysql;

=head1 DESCRIPTION

=head2 set_root_password

Use to set the root password for the mySQL database.

=head1 AUTHOR

Rus Berrett

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

