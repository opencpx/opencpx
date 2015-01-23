package VSAP::Server::Sys::Service::Control::Linux::Xinetd;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'xinetd';
    $args{script} = '/etc/init.d/xinetd';
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub last_started {
    my $self = shift;
    my $pid = $self->get_pid('/var/run/xinetd.pid');

    return 0 unless ($pid);

    my $mtime = (stat('/var/run/xinetd.pid'))[9];
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

VSAP::Server::Sys::Service::Control::Linux::Inetd - Module allowing control of inetd service. 

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
order to provide control for the inetd service. 

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Linux::RC>. 

=head1 SEE ALSO

VSAP::Server::Sys::Service::Control, VSAP::Server::Sys::Service::Control::Linux::RC

=head1 EXPORT

None by default.

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
