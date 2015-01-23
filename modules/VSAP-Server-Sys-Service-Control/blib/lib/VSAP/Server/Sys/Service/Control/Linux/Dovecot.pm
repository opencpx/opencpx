package VSAP::Server::Sys::Service::Control::Linux::Dovecot;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'dovecot';
    $args{script} = '/etc/init.d/dovecot';
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub last_started {
    my $self = shift;
    my $pid = $self->get_pid('/var/run/dovecot/master.pid');

    return 0 unless ($pid);

    my $mtime = (stat('/var/run/dovecot/master.pid'))[9];
    return $mtime;
}

sub version {
    my $version = `/usr/sbin/dovecot --version`;
    chomp($version);
    return $version;
}

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Linux::Dovecot - Module allowing control of dovecot service. 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Linux::Dovecot;

  my $control = new VSAP::Server::Sys::Service::Linux::Dovecot;

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

This object contains the specific methods to stop/stop/enable/disable Dovecotd. It is
typically used by the I<VSAP::Server::Sys::Service::Control> module. 

=head1 METHODS

=head2 stop
    Stops Dovecot

=head2 start
    Starts Dovecot

=head2 enable
    Enable Dovecot to startup automatically.

=head2 disable
    Disable Dovecot to startup automatically.

=head2 is_enabled
    Determine if Dovecot is currently configured to startup automatically. 

=head2 is_running
    Determine if Dovecot is currently running.

=head2 is_available
    Determine if Dovecot is currently available. Meaning, is it installed.

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
