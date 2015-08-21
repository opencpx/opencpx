package VSAP::Server::Modules::vsap::sys::service;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Sys::Service::Control;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::monitor;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

##############################################################################

our $VERSION = '0.12';

our %_ERR = (
             ERR_NOTAUTHORIZED    => 100,
              ERR_UNKNOWN_SERVICE => 101,
              ERR_INTERNAL        => 102,
              ERR_NO_SERVICES     => 103,
            );

##############################################################################

sub action
{
    my $action = shift;
    my $vsap = shift;
    my $xmlobj = shift;

    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to $action services.");
        return;
    }

    unless ($xmlobj->children_names) {
        $vsap->error( $_ERR{ERR_NO_SERVICES} => "a service must be specified for $action.");
        return;
    }

    my $svc_control;
    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $svc_control = new VSAP::Server::Sys::Service::Control;
    }

    if (!$svc_control) {
        $vsap->error($_ERR{ERR_INTERNAL} => 'Error obtaining service control.');
        return;
    }

    my @services = $svc_control->available_services;

    # Check for valid services.
    foreach my $service ($xmlobj->children_names) {
        unless (grep /^$service$/, @services) {
            $vsap->error( $_ERR{ERR_UNKNOWN_SERVICE} => "Unknown service $service.");
            return;
        }
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => "sys:service:$action");

    foreach my $service ($xmlobj->children_names) {

        my $node = $dom->createElement($service);
        $root->appendChild($node);

        if (($service eq 'httpd') && ($action eq 'restart')) {
            # gracefully restart
            $vsap->need_apache_restart();
        }
        else {
            ROOT: {
                local $> = $) = 0;  ## regain privileges for a moment
                eval {
                    unless ($svc_control->$action($service)) {
                        $node->setAttribute ( error => "unable to $action $service");
                    }
                };
            }

            if ($@) {
                $node->setAttribute ( error => "unable to $action $service: $@");
                VSAP::Server::Modules::vsap::logger::log_error("unable to $action $service: $@");
            }
            else {
                VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} requested to $action service '$service'");
                if ($action eq "start") {
                    # reset monitor data
                    VSAP::Server::Modules::vsap::sys::monitor::_reset_notification_data($service);
                }
            }
        }
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::enable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    VSAP::Server::Modules::vsap::sys::service::action('enable',$vsap,$xmlobj);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::disable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    VSAP::Server::Modules::vsap::sys::service::action('disable',$vsap,$xmlobj);
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::stop;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;

    VSAP::Server::Modules::vsap::sys::service::action('stop',$vsap,$xmlobj);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::start;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;

    VSAP::Server::Modules::vsap::sys::service::action('start',$vsap,$xmlobj);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::restart;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;

    VSAP::Server::Modules::vsap::sys::service::action('restart',$vsap,$xmlobj);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::service::status;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};
    my $svc_control;
    my @available_services;

    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment

        $svc_control = new VSAP::Server::Sys::Service::Control;

        if (!$svc_control) {
            $vsap->error($_ERR{ERR_INTERNAL} => 'Error obtaining service control.');
            return;
        }

        @available_services = $svc_control->available_services;
    }

    # Check for valid services.
    foreach my $service ($xmlobj->children_names) {
        $vsap->error( $_ERR{ERR_UNKNOWN_SERVICE} => "Unknown service $service.")
            unless (grep /^$service$/, @available_services);
        return;
    }

    # Use the services provided or available services if no xml children.
    my @services = $xmlobj->children_names || @available_services;

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:service:status');

    foreach my $service (@available_services) {
        my $node = $dom->createElement($service);

        ROOT: {
            local $> = $) = 0;  ## regain privileges for a moment
            eval {
                $node->appendTextChild( version => $svc_control->version($service));
                $node->appendTextChild( enabled => ($svc_control->is_enabled($service) ? "true" : "false"));
                $node->appendTextChild( running => ($svc_control->is_running($service) ? "true" : "false"));
                $node->appendTextChild( monitor_autorestart => ($svc_control->monitor_autorestart($service) ? "true" : "false"));
                $node->appendTextChild( monitor_notify => ($svc_control->monitor_notify($service) ? "true" : "false"));
                my $stime = $svc_control->last_started($service);
                $node->appendTextChild( last_started_epoch => $stime );
                my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') ||
                               VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
                my $d = new VSAP::Server::G11N::Date( epoch => $stime, tz => $timezone );
                if ($d) {
                    my $date_node = $node->appendChild($dom->createElement('last_started'));
                    $date_node->appendTextChild( year   => $d->local->year    );
                    $date_node->appendTextChild( month  => $d->local->month   );
                    $date_node->appendTextChild( day    => $d->local->day     );
                    $date_node->appendTextChild( hour   => $d->local->hour    );
                    $date_node->appendTextChild( hour12 => $d->local->hour_12 );
                    $date_node->appendTextChild( minute => $d->local->minute  );
                    $date_node->appendTextChild( second => $d->local->second  );

                    $date_node->appendTextChild( o_year   => $d->original->year    );
                    $date_node->appendTextChild( o_month  => $d->original->month   );
                    $date_node->appendTextChild( o_day    => $d->original->day     );
                    $date_node->appendTextChild( o_hour   => $d->original->hour    );
                    $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
                    $date_node->appendTextChild( o_minute => $d->original->minute  );
                    $date_node->appendTextChild( o_second => $d->original->second  );
                    $date_node->appendTextChild( o_offset => $d->original->offset  );
                }
            };
        }

        if ($@) {
            $node->removeChildNodes;
            $node->setAttribute('error' => "Error obtaining status: $@");
        }

        $root->appendChild($node);
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::service - VSAP module supporting the control of certain services.

=head1 SYNOPSIS

=head2 sys:service:stop, sys:service:start, sys:service:restart, sys:service:enable, sys:service:disable

All of these methods use the same format for both the request and response. Simply replace $action
in the below example with either stop, start, restart, enable or disable.

    <vsap type='sys:service:$action'>
        <service1/>
        <service2/>
        <service3/>
    </vsap>

Would return

    <vsap type='sys:service:$action'>
        <service1/>
        <service2/>
        <service3 error="some error occured while" />
    </vsap>

=head2 sys:service:status

    <vsap type='sys:service:status'/>

Would return:

    <vsap type='sys:service:status'>
        <service1>
            <running>true</running>
            <enabled>true</enabled>
        </service1>
        <service2/>
            <running>true</running>
            <enabled>true</enabled>
        </service2>
        <service3/>
            <running>true</running>
            <enabled>true</enabled>
        </service3>
        <service4 error="Error x occured while obtaining status"/>
    </vsap>

For the status request, you can also just specify one service and the status will be returned.

Ex:

    <vsap type='sys:service:status'>
        <service1/>
    </vsap>

Would return:

    <vsap type='sys:service:status'>
        <service1>
            <running>true</running>
            <enabled>true</enabled>
        </service1>
    </vsap>

=head1 DESCRIPTION

This vsap module provides control of services on the machine. It provides the ability to
stop, start, restart, enable or disable the services. It also provides methods to enable
or disable the service on the machine. An enabled service starts up automatically when the
machine is booted. A service can be started or stopped indepdent of it being enabled or
disabled. Most of the functionality of this module is taken care of in the another module
called VSAP::Server::Sys::Service::Control. Please refer to this module for additional
information.

The services which are listed and available for control depends on the available services as
obtained by the VSAP::Server::Sys::Service::Control module. A service is determined avaiable
(and will be returned by the status) method typically if its startup script exists. See the
VSAP::Server::Sys::Service::Control and other related modules for more information.

=head2 EXPORT

None by default.

=head1 SEE ALSO

VSAP::Server::Sys::Service::Control

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
