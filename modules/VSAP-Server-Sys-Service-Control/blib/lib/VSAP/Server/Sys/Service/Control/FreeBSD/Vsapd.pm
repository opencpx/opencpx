package VSAP::Server::Sys::Service::Control::FreeBSD::Vsapd;

use base VSAP::Server::Sys::Service::Control::FreeBSD::RC;

our $VERSION = '0.1';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'vsapd';
    if ( -f '/usr/local/etc/rc.d/vsapd.sh' ) {
        $args{script} = '/usr/local/etc/rc.d/vsapd.sh';
    } else {
        $args{script} = '/usr/local/etc/rc.d/vsapd';
    }
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub last_started {
    my $self = shift;
    my $pid = $self->get_pid('/var/run/vsapd.pid');

    return 0 unless ($pid);

    my $mtime = (stat('/var/run/vsapd.pid'))[9];
    return $mtime;
}

sub version {
    my $version = `/bin/cat /usr/local/cp/RELEASE`;
    chomp($version);
    return $version;
}

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Vsapd - Module allowing control of vsap service. 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Vsapd;

  my $control = new VSAP::Server::Sys::Service::Vsapd;

  # Start vsapd
  $control->start;

  # Stop vsapd 
  $control->stop;

  # Restart vsapd
  $control->restart;

  # Enable vsapd to start when machine boots.
  $control->enable;

  # Disable vsapd from starting when machine boots.
  $control->disable;

  do_something() 
    if ($control->is_available);

  # Check if vsapd is enabled. 
  do_something()
    if ($control->is_enabled);

  # Check if vsapd is running. 
  do_something()
    if ($control->is_running);


=head1 DESCRIPTION

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Base::RC object> in
order to provide control for the vsap service. The vsap service is run via a standard BSD rcNG
startup script, which makes it possible to simply extend the RC baseclass

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Base::RC>. 

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
