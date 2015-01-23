package VSAP::Server::Sys::Service::Control::Linux::Sendmail;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'sendmail';
    $args{script} = '/etc/init.d/sendmail';
    $args{_let_the_dust_settle} = 1; 
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub last_started {
    my $self = shift;

    return 0 unless (-f '/var/run/sendmail.pid' and -r _);

    open FH, "</var/run/sendmail.pid";
    my $pid = (<FH>);
    my $data = (<FH>);
    close FH;

    return 0 unless ($pid);

    my $mtime = (stat('/var/run/sendmail.pid'))[9];
    return $mtime;
}

sub version {
    my $version = "0.0.0.0";
    my $status = `/usr/lib/sendmail -d0.4 -bv root`;
    if ($status =~ m#Version ([0-9\.]*)$#im) {
        $version = $1;
    }
    return $version;
}

1;
=head1 NAME

VSAP::Server::Sys::Service::Control::Sendmail - Module allowing control of apache service. 

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Sendmail;

  my $control = new VSAP::Server::Sys::Service::Sendmail;

  # Start sendmail
  $control->start;

  # Stop sendmail 
  $control->stop;

  # Restart sendmail
  $control->restart;

  # Enable sendmail to start when machine boots.
  $control->enable;

  # Disable sendmail from starting when machine boots.
  $control->disable;

  do_something() 
    if ($control->is_available);

  # Check if sendmail is enabled. 
  do_something()
    if ($control->is_enabled);

  # Check if sendmail is running. 
  do_something()
    if ($control->is_running);


=head1 DESCRIPTION

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Linux::RC object> in
order to provide control for the sendmail service.

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
