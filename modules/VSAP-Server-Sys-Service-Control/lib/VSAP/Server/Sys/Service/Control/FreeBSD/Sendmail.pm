package VSAP::Server::Sys::Service::Control::FreeBSD::Sendmail;

use base VSAP::Server::Sys::Service::Control::FreeBSD::RC;

##############################################################################

our $VERSION = '0.01';

##############################################################################

sub new
{
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'sendmail';
    $args{disablestring} = '"NONE"';
    my $this = $class->SUPER::new(%args);
    bless $this, $class;
}

##############################################################################

sub coldstart
{
    my $self = shift;

    # Sendmail could be started multiple times, so prevent this.
    return 0 if ($self->is_running);

    my $results = `/bin/sh /etc/rc.sendmail start`;
    sleep(3);  ## to allow things to settle down (L1143)
    return 1 if ($results =~ /sendmail/);
    return 0;
}

##############################################################################

sub is_available
{
    my $self = shift;

    return (-f '/etc/rc.sendmail');
}

##############################################################################

sub is_running
{
    my $self = shift;

    return 0 unless (-f '/var/run/sendmail.pid' and -r _);

    open FH, "</var/run/sendmail.pid";
    my $pid = (<FH>);
    my $data = (<FH>);
    close FH;

    return kill 0, $pid;
}

##############################################################################

sub last_started
{
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

##############################################################################

sub restart
{
    my $self = shift;

    $self->stop;
    return $self->start;
}

##############################################################################

sub start
{
    my $self = shift;

    # Sendmail could be started multiple times, so prevent this.
    return 0 if ($self->is_running);

    my $results = `/bin/sh /etc/rc.sendmail start`;
    sleep(3);  ## to allow things to settle down (L1143)
    return 1 if ($results =~ /sendmail/);
    return 0;
}

##############################################################################

sub stop
{
    my $self = shift;

    my $results = `/bin/sh /etc/rc.sendmail stop`;
    return 1 if ($results =~ /sendmail/);
    return 0;
}

##############################################################################

sub version
{
    my $version = "0.0.0.0";
    my $status = `/usr/sbin/sendmail -d0.4 -bv root`;
    if ($status =~ m#Version ([0-9\.]*)$#im) {
        $version = $1;
    }
    return $version;
}

##############################################################################
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

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Base::RC object> in
order to provide control for the sendmail service. Sendmail is not currently controlled via a
rcNG script, so the stop, start and is_running methods have been overridden to provide the required
functionality for the sendmail daemon.

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Base::RC>.

=head2 stop

Stops the sendmail process by running /etc/rc.sendmail with the stop option.

=head2 start

Start the sendmail process by running etc/rc.sendmail with the start option.

=head2 is_running

Check to see if sendmail is running by checking the validity of the pid contained
in the /var/run/sendmail.pid file.

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
