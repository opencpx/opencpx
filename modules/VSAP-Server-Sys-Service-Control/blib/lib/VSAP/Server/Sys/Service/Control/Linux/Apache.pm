package VSAP::Server::Sys::Service::Control::Linux::Apache;

use base VSAP::Server::Sys::Service::Control::Linux::RC;

our $VERSION = '0.1';

our $HTTPD_CONF   = "/www/conf/httpd.conf";

sub new { 
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'httpd';
    $args{script} = '/etc/init.d/httpd';
    $args{_restart_script} = '/usr/local/sbin/restart_apache';
    $args{_delay_shutdown} = 1; 
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
}

sub restart {
    my $self = shift;
    my $cmd = qq|sleep 5; $self->{_restart_script} &|;
    system("$cmd");
    return 1;
}

sub last_started {
    my $self = shift;
    my $pidfile;

    local $_;
    open CONF, $HTTPD_CONF
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

    my $pid = $self->get_pid($pidfile);
    return 0 unless ($pid);

    my $mtime = (stat($pidfile))[9];
    return $mtime;
}

sub version {
    my $version = "0.0.0.0";
    my $status = `/usr/sbin/httpd -v`;
    if ($status =~ m#Apache/([0-9\.]*)\s#is) {
        $version = $1;
    }
    return $version;
}

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Linux::Apache - Module allowing control of apache service. 

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

This is a simple object which extends the I<VSAP::Server::Sys::Service::Control::Linux::RC object> in
order to provide control for the apache service. 

=head1 METHODS

See the methods defined in I<VSAP::Server::Sys::Service::Control::Base::RC>. 

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
