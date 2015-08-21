package VSAP::Server::Sys::Service::Control::FreeBSD::Mysql;

use base VSAP::Server::Sys::Service::Control::FreeBSD::RC;

##############################################################################

our $VERSION = '0.12';

##############################################################################

sub new
{
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'mysql';
    if (-f '/usr/local/etc/rc.d/mysql-server.sh') {
        $args{script} = '/usr/local/etc/rc.d/mysql-server.sh';
    }
    elsif (-f '/usr/local/etc/rc.d/mysql-server') {
        $args{script} = '/usr/local/etc/rc.d/mysql-server';
    }
    else {
        $args{script} = '/usr/local/etc/rc.d/mysql-server.sh';
    }
    my $this = $class->SUPER::new(%args);
    bless $this, $class;
}

##############################################################################

sub last_started
{
    my $self = shift;

    my $pidfile = `ls -1 /var/db/mysql/*.pid`;
    chomp($pidfile);
    return 0 unless (-e "$pidfile");

    my $pid = $self->get_pid($pidfile);
    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

##############################################################################

sub version
{
    my $version = "0.0.0.0";
    my $status = `/usr/local/libexec/mysqld --version`;
    if ($status =~ m#Ver\s([0-9\.]*)\s#i) {
        $version = $1;
    }
    return $version;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Mysql - Module allowing control of mysql service.

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Mysql;

  my $control = new VSAP::Server::Sys::Service::Mysql;

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
