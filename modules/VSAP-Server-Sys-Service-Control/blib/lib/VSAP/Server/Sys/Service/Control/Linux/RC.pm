package VSAP::Server::Sys::Service::Control::Linux::RC;

use strict;
use Carp;

use base qw(VSAP::Server::Sys::Service::Control::Base);

use VSAP::Server::Modules::vsap::sys::monitor;

our $VERSION = '0.01';

##############################################################################

sub new { 
    my $class = shift;
    my %args = @_;
    my $this = $class->SUPER::new(%args);
    my $self = bless $this, $class;
    return $self;
}

sub enable {
    my $self = shift; 
    my $service_name = $$self{servicename};

    my $rc = system('/sbin/chkconfig','--level','3',$service_name, 'on');

    croak "failed to execute chkconfig: $!" if ($rc == -1);

    croak "chkconfig failed with rc  ".($rc >> 8)
	unless (($rc >> 8) == 0);
}

sub disable {
    my $self = shift; 
    my $service_name = $$self{servicename};

    my $rc = system('/sbin/chkconfig','--level=3',$service_name, 'off');

    croak "failed to execute chkconfig: $!" if ($rc == -1);

    croak "chkconfig failed with rc  ".($rc >> 8)
	unless (($rc >> 8) == 0);
}

sub restart { 
    my $self = shift;

    croak "must specify a script in order to use restart."
	unless $$self{script};

    my $results;

    if ($self->{_delay_shutdown}) { 
    	$results = system("sleep 3 && $$self{script} restart 2>&1 >/dev/null &");
	return 1;
    } else { 
    	$results = system("$$self{script} restart 2>&1 >/dev/null");
	croak ("failed to execute $$self{script}")
	   if ($results == -1);
    }

    my $cnt = 0; 


    return 1 if (($results >> 8) == 0);
    return 0;
}

sub start { 
    my $self = shift;

    croak "must specify a script in order to use start."
	unless $$self{script};

    return 0
        if ($self->is_running);

    my $results;

    if ($self->{_delay_shutdown}) { 
    	$results = system("sleep 6 && $$self{script} start 2>&1 >/dev/null &");
	return 1;
    } else { 
    	$results = system("$$self{script} start 2>&1 >/dev/null");
	croak ("failed to execute $$self{script}")
	   if ($results == -1);
    }

    if ($self->{_let_the_dust_settle}) { 
        sleep 3;
    }

    my $cnt = 0; 
    while ($cnt++ < 3 && !$self->is_running) { sleep 1; } 

    return 1 if (($results >> 8) == 0);
    return 0;
}

sub coldstart { 
    my $self = shift;

    ## just like start(), but ignore any _delay_shutdown

    croak "must specify a script in order to use coldstart."
	unless $$self{script};

    return 0
        if ($self->is_running);

    my $results;
    $results = system("$$self{script} start 2>&1 >/dev/null");
    croak ("failed to execute $$self{script}")
       if ($results == -1);

    my $cnt = 0; 
    while ($cnt++ < 3 && !$self->is_running) { sleep 1; } 

    return 1 if (($results >> 8) == 0);
    return 0;
}

sub stop { 
    my $self = shift;

    croak "must specify a script in order to use stop."
	unless $$self{script};

    my $results;

    if ($self->{_delay_shutdown}) { 
    	$results = system("sleep 3 && $$self{script} stop 2>&1 >/dev/null &");
	return 1;
    } else { 
    	$results = system("$$self{script} stop 2>&1 >/dev/null");
	croak ("failed to execute $$self{script}")
	   if ($results == -1);
    }

    return 1 if (($results >> 8) == 0);
    return 0;
}

sub is_available { 
    my $self = shift;

    croak "must specify a script in order to use is_available."
	unless $$self{script};

    return 1
	if (-f $self->{script});

    return 0;
}

sub is_enabled { 
    my $self = shift;
    my $service_name = $$self{servicename};

    my $rc = system("/sbin/chkconfig --level 3 $service_name");

    croak("unable to run chkconfig: $!")
	if ($rc == -1);

    # if the return code of chkconfig is 0 it is enabled. 1 is disabled. 
    # this is in conflict with what the chkconfig man page states. 
    return 0
        if (($rc >> 8));

    return 1; 
}

sub is_running { 
    my $self = shift;

    if ($self->{script}) { 
	my $rc = system($$self{script},'status','2>&1','>/dev/null');
	return 1 if (($rc>>8) == 0);
	return 0;
    }
}

sub monitor_autorestart {
    my $self = shift;
    my $service_name = $$self{servicename};
    $service_name ="mysqld" if ($service_name eq "mysql");
    $service_name ="httpd" if ($service_name eq "apache");
    $service_name ="inetd" if ($service_name eq "xinetd");  # apologies to Panos Tsirigotis
    my $pref = "autorestart_service_" . $service_name;

    my $autorestart_on = $VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS{$pref};
    my $monitoring_on = $VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS{'monitor_interval'};
    my $mpf = $VSAP::Server::Modules::vsap::sys::monitor::PREFS_FILE;
    if ( (-e "$mpf") && (open PREFS, $mpf) ) {
        while( <PREFS> ) {
            next unless /^[a-zA-Z]/;
            s/\s+$//g;
            tr/A-Z/a-z/;
            if (/$pref="?(.*?)"?$/) {
                $autorestart_on = ($1 =~ /^(y|1)/i) ? 1 : 0;
            }
            if (/monitor_interval="?(.*?)"?$/) {
                $monitoring_on = ($1 != 0);
            }
        }
        close(PREFS);
    }
    return( $autorestart_on && $monitoring_on );
}

sub monitor_notify {
    my $self = shift;
    my $service_name = $$self{servicename};

    $service_name ="mysqld" if ($service_name eq "mysql");
    $service_name ="httpd" if ($service_name eq "apache");
    $service_name ="inetd" if ($service_name eq "xinetd");  # apologies to Panos Tsirigotis
    my $pref = "notify_service_" . $service_name;

    my $notify_service_on = $VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS{$pref};
    my $notify_events = $VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS{'notify_events'};
    my $monitoring_on = $VSAP::Server::Modules::vsap::sys::monitor::DEFAULT_PREFS{'monitor_interval'};
    my $mpf = $VSAP::Server::Modules::vsap::sys::monitor::PREFS_FILE;
    if ( (-e "$mpf") && (open PREFS, $mpf) ) {
        while( <PREFS> ) {
            next unless /^[a-zA-Z]/;
            s/\s+$//g;
            tr/A-Z/a-z/;
            if (/$pref="?(.*?)"?$/) {
                $notify_service_on = ($1 =~ /^(y|1)/i) ? 1 : 0;
            }
            if (/monitor_interval="?(.*?)"?$/) {
                $monitoring_on = ($1 != 0);
            }
            if (/notify_events="?(.*?)"?$/) {
                $notify_events = ($1 != 0);
            }
        }
        close(PREFS);
    }
    return( $notify_service_on && $notify_events && $monitoring_on );
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Base::RCConf - Base class for services which are enabled/disabled
via the /etc/rc.conf file. 

=head1 SYNOPSIS

  package VSAP::Server::Sys::Service::Control::SomeService; 

  use base VSAP::Server::Sys::Service::Control::Base::RC;

  sub new {
    my $class = shift;
    my %args = @_;
    $args{servicename} = 'some_service';
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
  } 

  sub stop { .. } 
  sub start { .. } 
    ... 

=head1 DESCRIPTION

This is a base object for services which are typically managed by /etc/init.d/* files.  It provides
an implementation for the I<enable> and I<disable> method which adjusts the value in the 
/etc/init.d/<servicename> file by using the chkconfig utility. When passed a script option in the 
constructor, the stop, start, is_running, methods can also be used as these will simply call the 
startup script. 

=head1 METHODS

=head2 new(%args)

Constructor for the RC base class. As part of the arguments to the constructor you must pass the servicename
field. This defines the name of the service used in the rc.conf file. This may or may not be different 
from the name of the service used in the VSAP::Server::Sys::Service::Control module. (ex: apache vs httpd).
Other optional files which can be defined via the constructor are enablestring and disablestring.

=head2 enable

enable the service by calling chkconfig --level 3 <servicename> on

=head2 disable 

disable the service by calling chkconfig --level 3 <servicename> off

=head2 stop 

stop the service by calling <script_name> stop

=head2 start

start the service by calling <script_name> start

=head2 is_running 

return the results of <script_name> status

=head2 is_enabled

Return the results of chkconfig <service_name.> This will indicate whether is not he service is currently enabled.

=head2 is_available

Return true if the script was specified and exists. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
