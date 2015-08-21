package VSAP::Server::Sys::Service::Control::FreeBSD::Apache;

use base VSAP::Server::Sys::Service::Control::FreeBSD::RC;

use VSAP::Server::Modules::vsap::globals;

##############################################################################

our $VERSION = '0.12';

##############################################################################

sub new
{
    my $class = shift;
    my %args = @_;
    # Set the service name used in /etc/rc.conf
    $args{servicename} = 'apache';
    # Set the rcNG script name.
    $args{script} = '/usr/local/etc/rc.d/apache.sh';
    $args{_delay_shutdown} = 1;
    $args{_restart_script} = '/usr/local/sbin/restart_apache';
    my $this = $class->SUPER::new(%args);
    bless $this, $class;
}

##############################################################################

sub last_started
{
    my $self = shift;

    my $pidfile;
    if (-e "/var/run/httpd/httpd.pid") {
        $pidfile = "/var/run/httpd/httpd.pid";
    }
    else {
        # check for pidfile in httpd.conf
        local $_;
        open CONF, $VSAP::Server::Modules::vsap::globals::APACHE_CONF
          or return 0;
        while( <CONF> ) {
            s/^\s+//g;
            s/\s+$//g;
            s/\s+/ /g;
            if (/^pidfile (.*)/i) {
                $pidfile = $1;
                last;
            }
        }
        close CONF;
        $pidfile = "/var/" . $pidfile if ($pidfile =~ /^run/);
        return 0 unless (-e "$pidfile");
    }

    my $pid = $self->get_pid($pidfile);
    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

##############################################################################

sub restart
{
    my $self = shift;

    my $cmd = qq|sleep 5; $self->{_restart_script} &|;
    system("$cmd");
    return 1;
}

##############################################################################

sub version
{
    my $version = "0.0.0.0";
    my $httpd_path = (-e "/usr/local/apache2/bin/httpd") ?
                         "/usr/local/apache2/bin/httpd" :
                         "/usr/local/apache/bin/httpd";
    my $status = `$httpd_path -v`;
    if ($status =~ m#Apache/([0-9\.]*)\s#is) {
        $version = $1;
    }
    return $version;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Apache - Module allowing control of apache service.

=head1 SYNOPSIS

  use VSAP::Server::Sys::Service::Control::Apache;

  my $control = new VSAP::Server::Sys::Service::Apache;

  # Start httpd
  $control->start;

  # Stop httpd
  $control->stop;

  # Restart httpd
  $control->restart;

  # Enable httpd to start when machine boots.
  $control->enable;

  # Disable httpd from starting when machine boots.
  $control->disable;

  do_something()
    if ($control->is_available);

  # Check if httpd is enabled.
  do_something()
    if ($control->is_enabled);

  # Check if httpd is running.
  do_something()
    if ($control->is_running);


=head1 DESCRIPTION

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Base::RC object> in
order to provide control for the apache service. The apache service is run via a standard BSD rcNG
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
