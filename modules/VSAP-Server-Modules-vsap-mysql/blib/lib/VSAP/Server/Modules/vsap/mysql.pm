package VSAP::Server::Modules::vsap::mysql;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::monitor;

our %_ERR =
(
    ERROR_PASSWORD_MISSING        => 100,
    ERROR_PASSWORD_MISMATCH       => 101,
    ERROR_PASSWORD_CHANGE_FAILED  => 102,
    ERROR_LOGROTATE_UPDATE        => 103,
    ERROR_PERMISSION_DENIED       => 500,
);

#
# *** NOTE: The handlers for the following are not currently called, but left 
# *** for future use:
# *** logrotate_status, logrotate_toggle, logrotate_on, logrotate_off
#
our $LOGROTATE_CONF = '/home/admin/.my-logrotate.conf';
our $LOGROTATE_ON_DIR = '/etc/logrotate.d/';
our $LOGROTATE_OFF_DIR = '/etc/logrotate.d/disabled/';
our $LOGROTATE_SCRIPT = 'mysql';

##############################################################################

sub set_root_password {
    my $root_passwd = shift;

    local $> = $) = 0;  ## got rewt?

    my $is_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mysql();
    return(1) unless ($is_installed);

    # figure out the service name (Linux)
    my $mysql_service = "mysqld";
    if (-e "/sbin/service") {
        my $mysql_path = (-e '/usr/bin/mysql') ? '/usr/bin/mysql' : '/usr/local/bin/mysql';
        my $mysql_version = `$mysql_path -V`;
        $mysql_version =~ /Distrib ([0-9\.]*)/;
        $mysql_version = $1;
        $mysql_service = ($mysql_version ge 5.1) ? "mysqld" : "mysql";
    }

    # figure out the script name (FreeBSD)
    my $mysql_script = (-e "/usr/local/etc/rc.d/mysql-server") ?
                           "/usr/local/etc/rc.d/mysql-server" :
                           "/usr/local/etc/rc.d/mysql-server.sh";

    my $tmpfile = "/tmp/mysql-$$.tmp";

    open MYINIT, ">$tmpfile" or return "Can't open output: $tmpfile ($!)";
    print MYINIT "SET PASSWORD FOR 'root'\@'localhost' = PASSWORD('$root_passwd')\;\n";
    print MYINIT "SET PASSWORD FOR 'root'\@'127.0.0.1' = PASSWORD('$root_passwd')\;\n";
    print MYINIT "FLUSH PRIVILEGES\;\n";
    close MYINIT;

    ## stop mysqld
    if (-e "/sbin/service") {
        system("/sbin/service $mysql_service stop > /dev/null 2>&1");
    }
    else {
        system("$mysql_script stop > /dev/null 2>&1");
    }

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
    if (-e "/sbin/service") {
        system("/sbin/service $mysql_service start > /dev/null 2>&1");
    }
    else {
        system("$mysql_script start > /dev/null 2>&1");
    }

    ## take a nap
    sleep(3);

    ## I leave mysqld running with the init_file arg, but revert the my.cnf file
    ## it should be okay... and we don't have to wait for mysqld to restart
    rename('/etc/my.cnf.bak', '/etc/my.cnf');
    unlink($tmpfile);

    return(0);
}

##############################################################################

# Return either the password or indication of presence of the password in $LOGROTATE_CONF.
# NOTE: Does not check of the existance of the file.
sub logrotatePassword {
  my $confFile = shift;
  my $retType = shift; # 0 = return yes/no, 1 = return password
  
  local $> = $) = 0;  ## got rewt?
  
  # See if a password has been set for the admin.
  open CONF, "<$confFile";
  my @conf = <CONF>;
  close CONF;
  
  foreach my $ln ( @conf ) {
    next unless ( $ln =~ /^password/ );
    chomp $ln;
    my ( $key, $val ) = split( /\s*=\s*/, $ln );
    $val =~ s/(^"|"$)//g;
    
    if ( $val eq '' ) {
      return ( $retType == 0 ) ? 'no' : '';
    }
    else {
      return ( $retType == 0 ) ? 'yes' : $val;
    }

  }
  
  return ( $retType == 0 ) ? 'no' : '';
}

##############################################################################

sub updateLogRotateConf {
  my $confFile = shift;
  my $passwd = shift;
  
  local $> = $) = 0;  ## got rewt?
  
  my $foundPw = 0;
  
  open CONF, "<$confFile" or return 0;
  my @conf = <CONF>;
  close CONF;
  rename( $confFile, $confFile . '.bak' );
  
  open CONF, ">$confFile" or return 0;

  foreach my $ln ( @conf ) {
    if ( $ln =~ /^password/ ) {
      print CONF "password=\"$passwd\"\n";
    }
    else {
      print CONF $ln;
    }
  }

  close CONF;
  unlink( $confFile . '.bak' );
  
  # Try to keep a tiny bit of security.
  chmod 0640, $confFile;
      
  return 1;
  
}

##############################################################################

sub createLogrotateConf {
  my $passwd = shift;
  my $confFile = shift;
  
  local $> = $) = 0;  ## got rewt?

  my $warn = <<_EOWARN;
# WARNING! WARNING! WARNING!
#
# Edit this file at your own risk. It is highly recommended that this 
# password only be changed via the control panel. Do not change the 
# user.
#
# WARNING! WARNING! WARNING!
#
_EOWARN

  open CONF, ">$confFile";
  print CONF $warn;
  print CONF "[client]\n";
  print CONF "user=\"root\"\n";
  print CONF "password=\"$passwd\"\n";
  close CONF;
  
  chmod 0640, $confFile;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::config;

sub handler {
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
    
    # Create the logrotate config file if it doesn't exist.
    # NOTE: logrotate functionality is currently disabled per OCN request. This 
    # code is left in place for ease of future re-implementation.
    #REWT: {
    #  local $> = $) = 0;  ## got rewt?
    #  
    #  if ( ! -e $LOGROTATE_CONF ) {
    #    VSAP::Server::Modules::vsap::mysql::createLogrotateConf( $passwd, $LOGROTATE_CONF );
    #  }
    #}
    #
    ## Update the logrotate conf file.
    #my $rc = VSAP::Server::Modules::vsap::mysql::updateLogRotateConf( $LOGROTATE_CONF, $passwd );
    #if ( ! $rc ) {
    #  $vsap->error($_ERR{ERROR_LOGROTATE_UPDATE} => "Cannot update logrotate conf file.");
    #}

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mysql:config');
    #$root_node->appendTextChild(status => $xmlobj->child('logrotate_state')->value );
    $root_node->appendTextChild(pw_exists => 'yes');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::logrotate_status;

sub handler {
  my $vsap   = shift;
  my $xmlobj = shift;
  my $dom = $vsap->dom;

  # Check for server admin
  unless ($vsap->{server_admin}) {
    $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
    return;
  }
  
  my $status = 'off';
  my $pwExist = 'no';
  my $confExist = 0;
  my $onScript = $LOGROTATE_ON_DIR . $LOGROTATE_SCRIPT;
  my $offScript = $LOGROTATE_OFF_DIR . $LOGROTATE_SCRIPT;

  if ( -e $LOGROTATE_CONF and -e $onScript  ) {
    $status = 'on';
    $confExist = 1;
  }
  else {
    $status = 'off';
    $confExist = ( -e $LOGROTATE_CONF ) ? 1 : 0;
  }
  
  # See if the password is in the file so we can warn (via javascript) if
  # the password needs setting again.
  if ( $confExist ) {
    $pwExist = VSAP::Server::Modules::vsap::mysql::logrotatePassword( $LOGROTATE_CONF, 0 ); # 0 = return yes/no
  }
  else {
    $pwExist = 'no'
  }
  
  # build return dom
  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute(type => 'mysql:logrotate_status');
  $root_node->appendTextChild(status => $status);
  $root_node->appendTextChild(pw_exists => $pwExist);
  $root_node->appendTextChild(conf_exists => $confExist);
  $dom->documentElement->appendChild($root_node);
  return;
}

##############################################################################
#
# NOTE: This function will probably not be called unless the old functionality
#       with '-OFF' suffix is reinstated, but it is left here for possible use.
#
package VSAP::Server::Modules::vsap::mysql::logrotate_toggle;

sub handler {
  my $vsap   = shift;
  my $xmlobj = shift;
  my $dom = $vsap->dom;

  # Check for server admin
  unless ($vsap->{server_admin}) {
    $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
    return;
  }
  
  my $status = $xmlobj->child('logrotate_state')->value;
  my $pwExist = 'yes';
  my $msg = '';
  my $onConf = $LOGROTATE_CONF;
  my $offConf = $LOGROTATE_CONF . '-OFF';
  my $onScript = $LOGROTATE_ON_DIR . $LOGROTATE_SCRIPT;
  my $offScript = $LOGROTATE_OFF_DIR . $LOGROTATE_SCRIPT;

  local $> = $) = 0;  ## got rewt?
  
  # Make sure the $LOGROTATE_OFF_DIR exists...might not on first run.
  if ( ! -d $LOGROTATE_OFF_DIR ) {
    mkdir( $LOGROTATE_OFF_DIR );
  }
  
  if ( $status eq 'on' and -e $offConf ) {
    rename( $offConf, $onConf );
    $msg = 'SUCCESS_LOGROTATE';
  }
  elsif ( $status eq 'on' and -e $onConf ) {
    # Already on.
  }
  elsif ( $status eq 'off' and -e $onConf ) {
    rename( $onConf, $offConf );
    $msg = 'SUCCESS_LOGROTATE';
  }
  elsif ( $status eq 'off' and -e $offConf ) {
    # Already off.
  }
  else {
    # Some funky state.
    # See if either of the conf files exists...if not, create one with an empty password.
    $pwExist = 'no';
    if ( ! -e $onConf and ! -e $offConf ) {
      VSAP::Server::Modules::vsap::mysql::createLogrotateConf( '', $offConf );
      $msg = 'WARN_NO_PASSWORD';
    }
    else {
      $msg = 'WARN_STRANGE_STATE';
    }
  }

  # Make sure the logrotate script is put in "on" directory if status is "on", and the "off" 
  # directory if status is "off".
  if ( $status eq 'on' && ! -e $onScript ) {
    rename( $offScript, $onScript );
    $msg = 'SUCCESS_LOGROTATE';
  }
  elsif ( $status eq 'off' && ! -e $offScript ) {
    rename( $onScript, $offScript );
    $msg = 'SUCCESS_LOGROTATE';
  }
  
  # build return dom
  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute(type => 'mysql:logrotate_toggle');
  $root_node->appendTextChild(status => $status);
  $root_node->appendTextChild(pw_exists => $pwExist);
  $root_node->appendTextChild(message => $msg);
  $dom->documentElement->appendChild($root_node);
  return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::logrotate_on;

sub handler {
  my $vsap   = shift;
  my $xmlobj = shift;
  my $dom = $vsap->dom;

  # Check for server admin
  unless ($vsap->{server_admin}) {
    $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
    return;
  }
  
  my $msg = 'FAILED_LOGROTATE_ON';
  my $onScript = $LOGROTATE_ON_DIR . $LOGROTATE_SCRIPT;
  my $offScript = $LOGROTATE_OFF_DIR . $LOGROTATE_SCRIPT;
  my $pwExist = VSAP::Server::Modules::vsap::mysql::logrotatePassword( $LOGROTATE_CONF, 0 ); # 0 = return yes/no

  local $> = $) = 0;  ## got rewt?
  
  # Make sure the $LOGROTATE_OFF_DIR exists...might not on first run.
  if ( ! -d $LOGROTATE_OFF_DIR ) {
    mkdir( $LOGROTATE_OFF_DIR );
  }
  
  # Make sure the logrotate script is put in "on" directory.
  if ( -e $offScript and ! -e $onScript ) {
    rename( $offScript, $onScript );
    $msg = 'SUCCESS_LOGROTATE';
  }
  
  # build return dom
  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute(type => 'mysql:logrotate_on');
  $root_node->appendTextChild(status => 'on');
  $root_node->appendTextChild(pw_exists => $pwExist);
  $root_node->appendTextChild(message => $msg);
  $dom->documentElement->appendChild($root_node);
  return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mysql::logrotate_off;

sub handler {
  my $vsap   = shift;
  my $xmlobj = shift;
  my $dom = $vsap->dom;

  # Check for server admin
  unless ($vsap->{server_admin}) {
    $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
    return;
  }
  
  my $msg = 'FAILED_LOGROTATE_OFF';
  my $onScript = $LOGROTATE_ON_DIR . $LOGROTATE_SCRIPT;
  my $offScript = $LOGROTATE_OFF_DIR . $LOGROTATE_SCRIPT;
  my $pwExist = VSAP::Server::Modules::vsap::mysql::logrotatePassword( $LOGROTATE_CONF, 0 ); # 0 = return yes/no

  local $> = $) = 0;  ## got rewt?
  
  # Make sure the $LOGROTATE_OFF_DIR exists...might not on first run.
  if ( ! -d $LOGROTATE_OFF_DIR ) {
    mkdir( $LOGROTATE_OFF_DIR );
  }
  
  # Make sure the logrotate script is put in "off" directory.
  if ( -e $onScript and ! -e $offScript ) {
    rename( $onScript, $offScript );
    $msg = 'SUCCESS_LOGROTATE';
  }
  
  # build return dom
  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute(type => 'mysql:logrotate_off');
  $root_node->appendTextChild(status => 'off');
  $root_node->appendTextChild(pw_exists => $pwExist);
  $root_node->appendTextChild(message => $msg);
  $dom->documentElement->appendChild($root_node);
  return;
}

##############################################################################

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

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
