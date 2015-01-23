package VSAP::Server::Sys::Service::Control::FreeBSD::RC;

use strict;
use Carp;
use Fcntl qw(O_RDWR LOCK_SH LOCK_EX LOCK_UN O_RDONLY);
use File::Temp;
use Tie::File;

use base qw(VSAP::Server::Sys::Service::Control::Base);

use VSAP::Server::Modules::vsap::sys::monitor;

our $VERSION = '0.01';

our $TIED_CONF;
our $CONFFILE = "/etc/rc.conf";
our $DISABLE_STRING = '"NO"';
our $ENABLE_STRING = '"YES"';

##############################################################################

sub new { 
    my $class = shift;
    my %args = @_;
    $args{conf} ||= $CONFFILE;  
    $args{readonly} ||= 0; 
    $args{enablestring} ||= $ENABLE_STRING; 
    $args{disablestring} ||= $DISABLE_STRING; 
    my $this = $class->SUPER::new(%args);
    my $self = bless $this, $class;
    return $self;
}

sub enable {
    my $self = shift; 
    $self->_tie_conf;
    $self->_adjust_conf($self->{enablestring});
    $self->_untie_conf;
}

sub disable {
    my $self = shift; 
    $self->_tie_conf;
    $self->_adjust_conf($self->{disablestring});
    $self->_untie_conf;
}

sub start { 
    my $self = shift;

    croak "must specify a script in order to use start."
	unless $$self{script};

    my $results;

    if ($self->{_delay_shutdown}) { 
    	$results = system("sleep 6 && $$self{script} forcestart &");
	return 1;
    } else { 
    	$results = `$$self{script} forcestart`;
    }

    my $cnt = 0; 
    while ($cnt++ < 3 && !$self->is_running) { sleep 1; } 

    return 1 if ($results =~ /Starting/);
    return 0;
}

sub coldstart { 
    my $self = shift;

    ## just like start(), but ignore any _delay_shutdown

    croak "must specify a script in order to use coldstart."
	unless $$self{script};

    my $results;
    $results = `$$self{script} forcestart`;

    my $cnt = 0; 
    while ($cnt++ < 3 && !$self->is_running) { sleep 1; } 

    return 1 if ($results =~ /Starting/);
    return 0;
}

sub stop {
    my $self = shift;
    my $results; 

    if ($self->{_delay_shutdown}) { 
    	$results = system("sleep 5 && $$self{script} forcestop &");
	return 1;
    } else { 
    	$results = `$$self{script} forcestop`;
    }

    croak "must specify a script in order to use stop."
	unless $$self{script};

    return 1 if ($results =~ /Stopping/);
    return 0;
}

sub is_available { 
    my $self = shift;

    croak "must specify a script in order to use start."
	unless $$self{script};

    return 1
	if (-f $self->{script});

    return 0;
}

sub run_script { 
    my $self = shift;
    my $script = shift;
     
    my $fh = new File::Temp();
    my $filename = $fh->filename;
    print $fh $script;
    close $fh;
    
    chmod 700,$filename;
    
    system($filename);
    
    die "unable to execute script."
	if ($? == -1);
    
    return !($? >> 8);
}

sub is_enabled { 
    my $self = shift;

    if ($self->{script}) { 
	return 1 if (`$$self{script} rcvar` =~ (/=YES/));
	return 0;
    } else { 
    	# Ok, here is the deal with this. In order to
       	# really determine if a service is enabled
	# you must check the default file in
	# /etc/defaults/rc.conf and then check any
	# conf file listed in that. Do do this all
	# in perl would be complex, so writing out
	# a simple shell script to do it and return
	# the results just seems easier. If we have
	# a real startup script, the rcvar does this for us.
	my $service = $self->{servicename};
	return $self->run_script(". /usr/local/etc/rc.subr; . /etc/defaults/rc.conf; source_rc_confs; checkyesno ${service}_enable");
    }
}

sub is_running { 
    my $self = shift;

    if ($self->{script}) { 
	return 1 if (`$$self{script} forcestatus` =~ (/is running/));
	return 0;
    }
}

sub monitor_autorestart {
    my $self = shift;
    my $service_name = $$self{servicename};
    $service_name ="mysqld" if ($service_name eq "mysql");
    $service_name ="httpd" if ($service_name eq "apache");
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

sub _adjust_conf {
    my $self = shift; 
    my $new_str = shift; 

    my $service = $self->{servicename}; 

    #ugly nasty hack for BUG25081 - this method should not be called on a stop
    #until AFTER dovecot is stopped
    return 1 if $service eq 'dovecot';

    # Find the line. If it's not these, simply add one. 
    foreach my $line (@{$self->{CONF}}) { 
	my $str = $service.'_enable=';
	if ($line =~ (/\s*$str/)) { 
	    $line = "${service}_enable=".$new_str;
	    return 1; 
	}
    }

    # We didn't find it. 
    push(@{$self->{CONF}},"$service".'_enable='.$new_str);
    push(@{$self->{LINES}},"$service".'_enable='.$new_str);
    return 1;
}

sub _tie_conf {
    my $self = shift;
    my $file = $self->{conf};

    $TIED_CONF = tie @{$self->{CONF}}, 'Tie::File', $file, mode => ($self->{readonly} ? O_RDONLY : O_RDWR)
        or die "Could't tie $file: $!";

    $self->{readonly} ? $TIED_CONF->flock(LOCK_SH) : $TIED_CONF->flock(LOCK_EX);
}

sub _untie_conf { 
    my $self = shift;

    undef $TIED_CONF;
    untie @{$self->{CONF}};
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
    $args{readonly} = 0;
    $args{script} = '/some/rcNG/startup/script.sh';
    $args{conf} = '/some/other/place/rc.conf';   
    my $this = $class->SUPER::new(%args);
    bless $this, $class; 
  } 

  sub stop { .. } 
  sub start { .. } 
    ... 

=head1 DESCRIPTION

This is a base object for services which are typically managed by the /etc/rc.conf file. It provides
an implementation for the I<enable> and I<disable> method which adjusts the value in the /etc/rc.conf
file. When passed a script option in the constructor, the stop, start, is_running, methods can also 
be used as these will simply call the startup script. This would typically be used when a script
exists which uses the rcNG BSD system as many recent scripts do. If you have a script which is 
not rcNG but is controlled via the /etc/rc.conf file you would need to override the stop, start
and is_running methods. 

=head1 METHODS

=head2 new(%args)

Constructor for the rcNG base class. As part of the arguments to the constructor you must pass the servicename
field. This defines the name of the service used in the rc.conf file. This may or may not be different 
from the name of the service used in the VSAP::Server::Sys::Service::Control module. (ex: apache vs httpd).
Other optional files which can be defined via the constructor are enablestring and disablestring. These
two variables define the value used in the rc.conf when enabling and disabling a service. By default
these values are "YES" and "NO", respectively. The readonly option defines whether or not the file is opened 
readonly (which doesn't make sense in the currently implementation, it always modifies the files). The last 
option is I<conf> and this defines the location of the rc.conf file to modify which is /etc/rc.conf by default.
If a I<script> option is passed it is expected that this is a path to a rcNG script as defined by rc.subr(8). If
specified, the stop/start/is_running and is_enabled methods will use the functionality provided by the script. 

=head2 enable

Adjust (or add if not found) the service_enable string in the rc.conf file. The value of the variable is set to 
enablestring, which is "YES" by default.

=head2 disable 

Adjust (or add if not found) the service_enable string in the rc.conf file. The value of the variable is set to 
disablestring, which is "NO" by default.

=head2 stop 

Call the script specified to the constructor with the I<forcestop> option and return success if the service
successfully starts.  Will croak if the script was not specified. 

=head2 start

Call the script specified to the constructor with the I<forcestart> option and return success if the service
successfully stops. Will croak if the script was not specified.  

=head2 is_running 

Call the script specified to the constructor with the I<forcestatus> option and return success if the service
is running. Will croak if the script was not specified. 

=head2 is_enabled

If the script was specified in the constructor, that script is called with the I<rcvar> option returning
its current status. If the script is not specified, a simpel shell script is created and run to determine
the status of the service. This is needed because the shell script need to source all the specified configuration
files. 

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
