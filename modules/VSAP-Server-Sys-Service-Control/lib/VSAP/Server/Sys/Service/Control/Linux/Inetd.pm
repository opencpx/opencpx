package VSAP::Server::Sys::Service::Control::Linux::Inetd;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'inetd';
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub start { 
    my $self = shift;
    # Inetd could be started multiple times, so prevent this. 
    return 0 if ($self->is_running); 

    # Here use a simple generated shell script to start inetd, this is so the options
    # specified in /etc/rc.conf and /etc/defaults/rc.conf are used. 
    return $self->run_script('. /usr/local/etc/rc.subr; . /etc/defaults/rc.conf; source_rc_confs; ${inetd_program:-/usr/sbin/inetd} ${inetd_flags}');
}

sub stop { 
    my $self = shift;
    my $pid = $self->get_pid('/var/run/inetd.pid');

    return 0
	if (!$pid);

    return 1
	if kill 15, $pid;

    return 0;
}

sub is_running { 
    my $self = shift;
    my $pid = $self->get_pid('/var/run/inetd.pid');

    return 0
	unless ($pid);

    return kill 0, $pid;
}

sub is_available { 
    return 1; 
}

sub last_started {
    my $self = shift;
    my $pid = $self->get_pid('/var/run/inetd.pid');

    return 0 unless ($pid);

    my $mtime = (stat('/var/run/inetd.pid'))[9];
    return $mtime;
}

sub version {
    my $version = "0.0.0.0";
    my $status = `/usr/sbin/xinetd -version 2>&1`;
    if ($status =~ m#Version ([0-9\.]*)\s#i) {
        $version = $1;
    }
    return $version;
}

1;
=head1 NAME

VSAP::Server::Sys::Service::Control::Inetd - Module allowing control of inetd service. 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Inetd;

  my $control = new VSAP::Server::Sys::Service::Inetd;

  # Start inetd
  $control->start;

  # Stop inetd 
  $control->stop;

  # Restart inetd
  $control->restart;

  # Enable inetd to start when machine boots.
  $control->enable;

  # Disable inetd from starting when machine boots.
  $control->disable;

  do_something() 
    if ($control->is_available);

  # Check if inetd is enabled. 
  do_something()
    if ($control->is_enabled);

  # Check if inetd is running. 
  do_something()
    if ($control->is_running);


=head1 DESCRIPTION

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Base::RC object> in
order to provide control for the inetd service. Inetd is not currently controlled via a rcNG script, 
so the stop, start and is_running methods have been overridden to provide the required functionality 
for the inetd daemon.

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Base::RC>. 

=head2 stop

Stops the inetd process by obtaining its pid and killing it with a SIGTERM. 

=head2 start

Start the inetd process by running /usr/sbin/inetd -wW 

=head2 is_running

Check to see if inetd is running by checking the validity of the pid contained
in the /var/run/inetd.pid file. 

=head1 SEE ALSO

VSAP::Server::Sys::Service::Control, VSAP::Server::Sys::Service::Control::Base::RC

=head1 EXPORT

None by default.

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
