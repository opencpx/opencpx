package VSAP::Server::Modules::vsap::globals;

use 5.008004;
use strict;
use warnings;

use POSIX qw(uname);

##############################################################################

our $VERSION = '0.12';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                  $IS_LINUX
                  $IS_BSD
                  $PLATFORM_TYPE
                  $PLATFORM_DISTRO
                  $PLATFORM_UID_MIN
                  $PLATFORM_UID_MAX
                  $APACHE_SERVER_ROOT
                  $APACHE_CONF
                  $APACHE_CGIBIN
                  $APACHE_RUN_USER
                  $APACHE_RUN_GROUP
                  $APACHE_TEMP_DIR
                );

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
    if (-e "/sbin/service") {
        # Fedora Core, CentOS, RHEL
        $PLATFORM_DISTRO = 'rhel';
        $PLATFORM_UID_MIN = 500;
    }
    elsif (-e "/usr/bin/apt-get") {
        # Debian, Ubuntu
        $PLATFORM_DISTRO = 'debian';
    }
    else {
        # not supported
        $PLATFORM_DISTRO = 'other';
    }
}

##############################################################################
##
## default apache pathnames (see https://wiki.apache.org/httpd/DistrosDefaultLayout)
##
##############################################################################

our $APACHE_SERVER_ROOT = '/usr/local/apache2';
our $APACHE_CONF        = '/usr/local/apache2/conf/httpd.conf';
our $APACHE_CGIBIN      = '/usr/local/apache2/cgi-bin';
our $APACHE_RUN_USER    = 'www';
our $APACHE_RUN_GROUP   = 'www';
our $APACHE_TEMP_DIR    = '/tmp';

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
