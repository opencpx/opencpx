package VSAP::Server::Sys::Service::Control::Linux::Mailman;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.1';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'mailman';
    $args{script} = '/etc/init.d/mailman';
    my $this = $class->SUPER::new(%args);
    bless $this, $class;
}

sub last_started {
    my $self = shift;

    my $pidfile = '/var/run/mailman/master-qrunner.pid';
    my $pid = $self->get_pid($pidfile);

    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

sub version {
    my $version = "0.0.0.0";
    my $status = `/usr/lib/mailman/bin/version`;
    if ($status =~ /Using Mailman version: ([0-9\.]*)/i) {
        $version = $1;
    }
    return $version;
}

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Linux::Mailman - Module allowing control of mailman software 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Mailman;

  my $control = new VSAP::Server::Sys::Service::Mailman;

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

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Linux::RC object> in
order to provide control for the apache service. 

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Base::RC>. 

=head1 SEE ALSO

VSAP::Server::Sys::Service::Control, VSAP::Server::Sys::Service::Control::Linux::RC

=head1 EXPORT

None by default.

=head1 AUTHOR

James Russo and Rus Berrett

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
