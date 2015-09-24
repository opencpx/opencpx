package VSAP::Server::Modules::vsap::globals;

use 5.008004;
use strict;
use warnings;

use POSIX qw(uname);

use VSAP::Server::Modules::vsap::sys::monitor;

##############################################################################

our $VERSION = '0.12';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                  $CONFIG
                  $SITE_PREFS
                  $IS_LINUX
                  $IS_BSD
                  $PLATFORM_TYPE
                  $PLATFORM_DISTRO
                  $PLATFORM_UID_MIN
                  $PLATFORM_UID_MAX
                  $ACCOUNT_CONF
                  $APACHE_SERVER_ROOT
                  $APACHE_CONF
                  $APACHE_CGIBIN
                  $APACHE_LOGS
                  $APACHE_RUN_USER
                  $APACHE_RUN_GROUP
                  $APACHE_TEMP_DIR
                  $APACHE_SSL_CONF
                  $APACHE_SSL_CERT_CHAIN
                  $APACHE_SSL_CERT_FILE
                  $APACHE_SSL_CERT_KEY
                  $APACHE_CPX_CONFIG
                  $POSTFIX_INSTALLED
                  $MAIL_ALIASES
                  $MAIL_GENERICS
                  $MAIL_VIRTUAL_DOMAINS
                  $MAIL_VIRTUAL_USERS
                );

##############################################################################
##
## config, prefs, etc
## 
##############################################################################

our $CONFIG         = '/usr/local/etc/cpx.conf';
our $SITE_PREFS     = '/usr/local/share/cpx/site_prefs';

##############################################################################
##
## platform information
## 
##############################################################################

our $IS_LINUX = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
our $IS_BSD   = ! $IS_LINUX;

our $PLATFORM_TYPE = 'bsd';
our $PLATFORM_DISTRO = 'freebsd';
our $PLATFORM_UID_MIN = 1000;
our $PLATFORM_UID_MAX = 60000;

if ($IS_LINUX) {
    $PLATFORM_TYPE = 'linux';
    if (-e "/usr/bin/apt-get") {
        # Debian, Ubuntu
        $PLATFORM_DISTRO = 'debian';
    }
    elsif (-e "/sbin/service") {
        # Fedora Core, CentOS, RHEL
        $PLATFORM_DISTRO = 'rhel';
        $PLATFORM_UID_MIN = 500;
    }
    else {
        # not supported
        $PLATFORM_DISTRO = 'other';
    }
}

##############################################################################
##
## account information
## 
##############################################################################

our $ACCOUNT_CONF = '/var/vsap/account.conf';

##############################################################################
##
## default apache pathnames (see https://wiki.apache.org/httpd/DistrosDefaultLayout)
##
##############################################################################

# presume FreeBSD
our $APACHE_SERVER_ROOT = '/usr/local/apache2';
our $APACHE_CONF        = '/usr/local/apache2/conf/httpd.conf';
our $APACHE_CGIBIN      = '/usr/local/apache2/cgi-bin';
our $APACHE_LOGS        = '/var/log/httpd';
our $APACHE_RUN_USER    = 'www';
our $APACHE_RUN_GROUP   = 'www';

if ($PLATFORM_DISTRO eq 'debian') {
    $APACHE_SERVER_ROOT = '/etc/apache2';
    $APACHE_CONF        = '/usr/local/apache2/apache2.conf';
    $APACHE_CGIBIN      = '/usr/lib/cgi-bin';
    $APACHE_RUN_USER    = 'www-data';
    $APACHE_RUN_GROUP   = 'www-data';
}
elsif ($PLATFORM_DISTRO eq 'rhel') {
    $APACHE_SERVER_ROOT = '/etc/httpd';
    $APACHE_CONF        = '/etc/httpd/conf/httpd.conf';
    $APACHE_CGIBIN      = '/var/www/cgi-bin';
    $APACHE_RUN_USER    = 'apache';
    $APACHE_RUN_GROUP   = 'apache';
}

our $APACHE_SSL_CONF       = $APACHE_SERVER_ROOT . '/conf.d/ssl.conf';
our $APACHE_SSL_CERT_CHAIN = $APACHE_SERVER_ROOT . '/conf/certs/server.pem';
our $APACHE_SSL_CERT_FILE  = $APACHE_SERVER_ROOT . '/conf/certs/server-chain.pem';
our $APACHE_SSL_CERT_KEY   = $APACHE_SERVER_ROOT . '/conf/private/server.pem';

our $APACHE_CPX_CONFIG     = $APACHE_SERVER_ROOT . '/conf.d/perl_opencpx.conf';

our $APACHE_TEMP_DIR       = '/tmp';

##############################################################################
##
## mail information
##
## postfix or sendmail?  if postfix is installed, then presume postfix is the
## active MTA.  if postfix is not installed, then assume sendmail is the MTA.
##
##############################################################################

our $POSTFIX_INSTALLED = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postfix();

our $MAIL_ALIASES         = $IS_LINUX ? "/etc/aliases" : $POSTFIX_INSTALLED ? 
                            "/etc/postfix/aliases" : "/etc/mail/aliases" ;

our $MAIL_GENERICS        = "/etc/mail/genericstable";
our $MAIL_VIRTUAL_DOMAINS = "/etc/mail/local-host-names";
our $MAIL_VIRTUAL_USERS   = "/etc/mail/virtusertable";

if ($POSTFIX_INSTALLED) {
    $MAIL_GENERICS        = "/etc/postfix/generic";
    $MAIL_VIRTUAL_DOMAINS = "/etc/postfix/domains";
    $MAIL_VIRTUAL_USERS   = "/etc/postfix/virtual";
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::globals - vsap global variables

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::globals;

=head1 DESCRIPTION

The VSAP::Server::Modules::vsap::globals module sets several global various
used by various other vsap utilities.  For example, pathnames to apache 
config files and such would be found here.

=head1 SEE ALSO

VSAP::Server::Modules::vsap::config()

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
