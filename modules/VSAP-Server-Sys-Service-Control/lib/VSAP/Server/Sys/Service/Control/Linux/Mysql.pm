package VSAP::Server::Sys::Service::Control::Linux::Mysql;

use POSIX qw(uname);

use base VSAP::Server::Sys::Service::Control::Linux::RC;

use VSAP::Server::Modules::vsap::sys::monitor;

##############################################################################

our $VERSION = '0.12';

##############################################################################

sub new
{
    my $class = shift;
    my %args = @_;

    $args{script} = '/etc/init.d/mysqld';
    my $version = `/usr/bin/mysql -V`;
    $version =~ /Distrib ([0-9\.]*)/;
    $version = $1;
    my $service = ($version ge 5.1) ? "mysqld" : "mysql";
    my $is_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_mysql();
    if ( $is_installed ) {
        if ( -f '/etc/init.d/mysql' ) {
            $args{servicename} = 'mysql';
            $args{script} = '/etc/init.d/mysql';
        }
        else {
            $args{servicename} = 'mysqld';
            $args{script} = '/etc/init.d/mysqld';
        }
    }
    my $this = $class->SUPER::new(%args);
    bless $this, $class;
}

##############################################################################

sub is_running
{
    my $self = shift;
    my $script = $self->{script};

    if ($self->{script} eq '/etc/init.d/mysql' ) {
        my $rc = `ps -ef | grep mysql | grep -v grep`;
        return 1 if ( $rc =~ m/mysql/ );
        return 0;
    }
    else {
        my $rc = system($$self{script},'status','2>&1','>/dev/null');
        return 1 if (($rc>>8) == 0);
        return 0;
    }
}

##############################################################################

sub last_started
{
    my $self = shift;

    my $pidfile;
    if ( -f '/etc/init.d/mysql' ) {
        my $hostname = (POSIX::uname())[1];
        $pidfile = "/var/lib/mysql/" . $hostname . ".pid";
    }
    else {
        $pidfile = "/var/run/mysqld/mysqld.pid";
    }
    my $pid = $self->get_pid($pidfile);
    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

##############################################################################

sub version
{
    my $version = "0.0.0.0";
    my $status = `/usr/bin/mysql -V`;
    if ($status =~ m#Distrib\s([0-9\.]*),#i) {
        $version = $1;
    }
    return $version;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Linux::Mysql - Module allowing control of mysql service.

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Linux::Mysql;

  my $control = new VSAP::Server::Sys::Service::Linux::Mysql;

  # Start service
  $control->start;

  # Stop service
  $control->stop;

  # Restart service
  $control->restart;

  # Enable service to start when machine boots.
  $control->enable;

  # Disable service from starting when machine boots.
  $control->disable;

  do_something()
    if ($control->is_available);

  # Check if service is enabled.
  do_something()
    if ($control->is_enabled);

  # Check if service is running.
  do_something()
    if ($control->is_running);


=head1 DESCRIPTION

This object contains the specific methods to stop/stop/enable/disable Mysqld. It is
typically used by the I<VSAP::Server::Sys::Service::Control> module.

=head1 METHODS

=head2 stop
    Stops Mysql

=head2 start
    Starts Mysql

=head2 enable
    Enable Mysql to startup automatically.

=head2 disable
    Disable Mysql to startup automatically.

=head2 is_enabled
    Determine if Mysql is currently configured to startup automatically.

=head2 is_running
    Determine if Mysql is currently running.

=head2 is_available
    Determine if Mysql is currently available. Meaning, is it installed.

=head1 SEE ALSO

VSAP::Server::Sys::Service::Control

=head1 EXPORT

None by default.

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
