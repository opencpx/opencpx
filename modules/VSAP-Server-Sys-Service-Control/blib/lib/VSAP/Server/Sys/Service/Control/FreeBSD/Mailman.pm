package VSAP::Server::Sys::Service::Control::FreeBSD::Mailman;

use base VSAP::Server::Sys::Service::Control::FreeBSD::RC;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'mailman';
    $args{script} = '/usr/local/etc/rc.d/mailman';

    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub last_started {
    my $self = shift;

    my $pidfile = "/usr/local/mailman/data/master-qrunner.pid";
    chomp($pidfile);
    return 0 unless (-e "$pidfile");

    my $pid = $self->get_pid($pidfile);
    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

sub version {
    my $version = "0.0.0.0";
    my $status = `/usr/local/mailman/bin/version`;
    if ($status =~ /Using Mailman version: ([0-9\.]*).i) {
        $version = $1;
    }
    return $version;
}

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Mailman - Module allowing control of mailman service. 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Mailman;

  my $control = new VSAP::Server::Sys::Service::Mailman;

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

This object contains the specific methods to stop/stop/enable/disable Mailman. It is
typically used by the I<VSAP::Server::Sys::Service::Control> module. 

=head1 METHODS

=head2 stop
    Stops Mailman

=head2 start
    Starts Mailman

=head2 enable
    Enable Mailman to startup automatically.

=head2 disable
    Disable Mailman to startup automatically.

=head2 is_enabled
    Determine if Mailman is currently configured to startup automatically. 

=head2 is_running
    Determine if Mailman is currently running.

=head2 is_available
    Determine if Mailman is currently available. Meaning, is it installed.

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
