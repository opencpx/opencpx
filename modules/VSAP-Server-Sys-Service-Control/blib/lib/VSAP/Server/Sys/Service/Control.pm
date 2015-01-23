package VSAP::Server::Sys::Service::Control;

use 5.008004;
use strict;
use warnings;
use Carp;
use POSIX qw(uname);

use VSAP::Server::Modules::vsap::sys::monitor;

my $isInstalledDovecot = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_dovecot();

our %SERVICES;
if ( $isInstalledDovecot ) {
    %SERVICES = ( 'FreeBSD' => {
                                   vsapd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Vsapd',
                                   sendmail => 'VSAP::Server::Sys::Service::Control::FreeBSD::Sendmail',
                                   httpd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Apache',
                                   mysqld => 'VSAP::Server::Sys::Service::Control::FreeBSD::Mysql',
                                   postgresql => 'VSAP::Server::Sys::Service::Control::FreeBSD::Postgresql',
                                   mailman => 'VSAP::Server::Sys::Service::Control::Linux::Mailman',
                                   dovecot => 'VSAP::Server::Sys::Service::Control::FreeBSD::Dovecot',
                                   inetd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Inetd'
                               },

                    'Linux' => {
                                   vsapd => 'VSAP::Server::Sys::Service::Control::Linux::Vsapd',
                                   sendmail => 'VSAP::Server::Sys::Service::Control::Linux::Sendmail',
                                   httpd => 'VSAP::Server::Sys::Service::Control::Linux::Apache',
                                   mysqld => 'VSAP::Server::Sys::Service::Control::Linux::Mysql',
                                   postgresql => 'VSAP::Server::Sys::Service::Control::Linux::Postgresql',
                                   mailman => 'VSAP::Server::Sys::Service::Control::Linux::Mailman',
                                   postfix => 'VSAP::Server::Sys::Service::Control::Linux::Postfix',
                                   dovecot => 'VSAP::Server::Sys::Service::Control::Linux::Dovecot',
                                   inetd => 'VSAP::Server::Sys::Service::Control::Linux::Xinetd'
                               }
                  );
} else {
    %SERVICES = ( 'FreeBSD' => {
                                   vsapd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Vsapd',
                                   sendmail => 'VSAP::Server::Sys::Service::Control::FreeBSD::Sendmail',
                                   httpd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Apache',
                                   mysqld => 'VSAP::Server::Sys::Service::Control::FreeBSD::Mysql',
                                   postgresql => 'VSAP::Server::Sys::Service::Control::FreeBSD::Postgresql',
                                   mailman => 'VSAP::Server::Sys::Service::Control::Linux::Mailman',
                                   inetd => 'VSAP::Server::Sys::Service::Control::FreeBSD::Inetd'
                               },

                    'Linux' => {
                                   vsapd => 'VSAP::Server::Sys::Service::Control::Linux::Vsapd',
                                   sendmail => 'VSAP::Server::Sys::Service::Control::Linux::Sendmail',
                                   httpd => 'VSAP::Server::Sys::Service::Control::Linux::Apache',
                                   mysqld => 'VSAP::Server::Sys::Service::Control::Linux::Mysql',
                                   postgresql => 'VSAP::Server::Sys::Service::Control::Linux::Postgresql',
                                   mailman => 'VSAP::Server::Sys::Service::Control::Linux::Mailman',
                                   postfix => 'VSAP::Server::Sys::Service::Control::Linux::Postfix',
                                   inetd => 'VSAP::Server::Sys::Service::Control::Linux::Xinetd'
                               }
                  );
}

our $VERSION = '0.01';
our $UNAME = (POSIX::uname())[0];

sub new {
    my $class = shift;
    my %args = @_;

    bless \%args, $class;
}

sub _maybe_load_obj {
    my $self = shift;
    my $service = shift;

    die "Unknown service $service for platform $UNAME"
         unless ($SERVICES{$UNAME}->{$service});

    my $package = $SERVICES{$UNAME}->{$service};

    return $self->{objcache}{$package}
         if ($self->{objcache}{$package});

    my $req_package = $package;
    $req_package =~ (s/::/\//g);

    require "$req_package.pm";

    $self->{objcache}{$package} = $package->new;

    return $self->{objcache}{$package};
}

sub start {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);
    return $package->start;
}

sub coldstart {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->coldstart;
}

sub stop {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->stop;
}

sub restart {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->restart;
}

sub enable {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->enable;
}

sub disable {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->disable;
}

sub last_started {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->last_started;
}

sub monitor_autorestart {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->monitor_autorestart;
}

sub monitor_notify {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->monitor_notify;
}

sub version {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->version;
}

sub is_running {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->is_running;
}

sub is_enabled {
    my $self = shift;
    my $service = shift;

    my $package = $self->_maybe_load_obj($service);

    return $package->is_enabled;
}

sub available_services {
    my $self = shift;
    my @services;

    foreach my $service (keys %{$SERVICES{$UNAME}}) {
         my $obj = $self->_maybe_load_obj($service);
         push @services, $service
             if ($obj->is_available);
    }

    return @services;
}

sub add_service {
    my $self = shift;
    my ($service,$package) = @_;

    $SERVICES{$service} = $package;

    return 1;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VSAP::Server::Sys::Service::Control - Perl extension providing pluggable control of services.

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control;

  my $control = new VSAP::Server::Sys::Service::Control;

  # Start httpd
  $control->start('httpd');

  # Stop httpd
  $control->stop('httpd');

  # Restart httpd
  $control->restart('httpd');

  # Enable httpd to start when machine boots.
  $control->enable('httpd');

  # Disable httpd from starting when machine boots.
  $control->disable('httpd');

  # Check if httpd is enabled.
  do_something()
    if ($control->is_enabled('httpd'));

  # Check if httpd is running.
  do_something()
    if ($control->is_running('httpd'));

=head1 DESCRIPTION

This object is used to control services which are installed on a machine. It provides
a pluggable interface so that different methods can be used to start, stop, enable, disable
and determine if a service is running. The objects used for the implementation are defined
in the %SERVICES hash at the top of this file, or can be added at runtime via the I<add_service>
method. The objects are loaded dynamically and only when actually used.

=head1 METHODS

=head2 start($service)

Start the specified service. Returns true if successfully started, false otherwise.
If the service specified is not known, I<die> is called.

=head2 stop($service)

Stop the specified service. Returns true if successfully started, false otherwise.
If the service specified is not known, I<die> is called.

=head2 restart($service)

Restart the specified service. Returns true if successfully started, false otherwise.
If the service specified is not known, I<die> is called.

=head2 is_running($service)

Check to see if the service is currently running. Return true if running, false otherwise.
If the service specified is not known, I<die> is called.

=head2 enable($service)

Enable the service to be started automatically when the machine boots up. Return true if
change was successful, false otherwise.  If the service specified is not known, I<die> is called.

=head2 disable($service)

Disable the service to be started automatically when the machine boots up. Return true if
change was successful, false otherwise.  If the service specified is not known, I<die> is called.

=head2 is_enabled($service)

Check to see if the service is currently enabled. An enabled service is one which automatically
starts at bootup. Return true if the service is enabled, false if it is not disabled.

=head2 available_services

Return an array of all available services. These service names are one which are acceptable
to be passed to all other methods. If the service specified is not known, I<die> is called.

=head2 add_service( service => 'Some::Package')

Add a service to the list of services available for control by this object. Also
specified is the name of the package (extending VSAP::Server::Sys::Service::Control::Base)
which is used to control that service.

=head1 ADDING ADDITIONAL SERVICES

You can extend this system to handle more services by adding objects which would control
these new services. The steps required would be to create an object which contains the
stop, start, restart, is_running, enable, disable, is_enabled and is_available methods.
The new class could also inherit from an existing class providing most of the functionality.
Once this class is created it can either be added at runtime using the C<add_service> method
or (more likely) can be added to the C<%SERVICES> hash contained in the
I<VSAP::Server::Sys::Service::Control> package.

If the service to be added uses a rcNG script, refer to the base class
L<VSAP::Server::Sys::Service::Control::Base::RC>.

=head1 EXPORT

None by default.

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
