package VSAP::Server::Modules::vsap::sys::inetd;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::monitor;
use VSAP::Server::Sys::Config::Inetd;
use VSAP::Server::Sys::Service::Control;

##############################################################################
#
# NOTES
#
# To add another service, you must add it to the @SERVICES array and then add
# an entry to the search map hash in the platform-specific Inetd.pm.
#
# The searchmap can typically just contain the servicename and protocol if
# there is only one service in the inetd.conf. If there are multiple services
# specified in the inetd.conf and you would like to just enable/disable a
# specified one and not the first one encountered (from bottom-up) you must
# further qualify the search by using additional search criteria. Look at the
# ftp/proftpd entry as an example.
#
##############################################################################

our $VERSION = '0.12';

our %_ERR = (
              ERR_UNKNOWN_SERVICE => 100,  # Unkown service specified.
              ERR_INETD_CONF      => 101,  # Error in dealing with inetd.conf
              ERR_RESTART_INETD   => 102,  # deprecated.
              ERR_NO_SERVICES     => 103,  # No Services specified.
              ERR_NOTAUTHORIZED   => 104,  # Not authorized.
            );

##############################################################################

package VSAP::Server::Modules::vsap::sys::inetd::status;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    my $inetd;

    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment

        eval {
            $inetd = new VSAP::Server::Sys::Config::Inetd(readonly => 1);
        };

        if ($@) {
            $vsap->error($_ERR{ERR_INETD_CONF} => "Unable obtain stauts on services");
            return;
        }
    }

    # Check for valid services.
    foreach my $service ($xmlobj->children_names) {
        unless (grep /^$service$/, $inetd->services) {
            $vsap->error( $_ERR{ERR_UNKNOWN_SERVICE} => "Unknown service $service.");
            return;
        }
    }


    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:inetd:status');

    my @services = scalar($xmlobj->children_names) ? $xmlobj->children_names : $inetd->services;

    foreach my $service (@services) {
        my $node = $dom->createElement($service);
        my $version = $inetd->version($service);
        my $status = $inetd->is_enabled($service) ? "enabled" : "disabled";
        my $notify = $inetd->monitor_notify($service) ? "true" : "false";
        my $autorestart = $inetd->monitor_autorestart($service) ? "true" : "false";
        $node->appendTextChild( version => $version );
        $node->appendTextChild( status => $status );
        $node->appendTextChild( monitor_notify => $notify );
        $node->appendTextChild( monitor_autorestart => $autorestart );
        $root->appendChild($node);
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::inetd::enable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to enable inetd services.");
        return;
    }

    unless ($xmlobj->children_names) {
        $vsap->error( $_ERR{ERR_NO_SERVICES} => "a service must be specified for enable.");
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:inetd:enable');

    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment

        # instantiate an inetd object
        my $inetd;
        eval {
            $inetd = new VSAP::Server::Sys::Config::Inetd;
        };
        if ($@) {
            $vsap->error($_ERR{ERR_INETD_CONF} => "Unable to obtain Inetd object");
            return;
        }

        # instantiate a service control object
        my $svc_control;
        eval {
            $svc_control = new VSAP::Server::Sys::Service::Control;
        };
        if ($@) {
            $vsap->error($_ERR{ERR_INETD_CONF} => "Unable to obtain Service Control object");
            return;
        }

        # check for valid services
        foreach my $service ($xmlobj->children_names) {
            unless (grep /^$service$/, $inetd->services) {
                $vsap->error( $_ERR{ERR_UNKNOWN_SERVICE} => "Unknown service $service.");
                return;
            }
        }

        # enable inetd (if necessary)
        unless ($svc_control->is_running("inetd")) {
            $svc_control->start("inetd");
            # add a trace to the message log
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled inetd master service");
        }

        # enable the service
        foreach my $service ($xmlobj->children_names) {
            $inetd->enable($service);
            # reset monitor data
            VSAP::Server::Modules::vsap::sys::monitor::_reset_notification_data($service);
            # add a trace to the message log
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled inetd sub-service '$service'");
            my $node = $dom->createElement($service);
            $root->appendChild($node);
        }
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::inetd::disable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to disable inetd services.");
        return;
    }

    unless ($xmlobj->children_names) {
        $vsap->error( $_ERR{ERR_NO_SERVICES} => "a service must be specified for disable.");
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:inetd:disable');

    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $inetd;

        eval {
            $inetd = new VSAP::Server::Sys::Config::Inetd;
        };

        if ($@) {
            $vsap->error($_ERR{ERR_INETD_CONF} => "Unable to obtain object");
            return;
        }

        foreach my $service ($xmlobj->children_names) {
            unless (grep /^$service$/, $inetd->services) {
                $vsap->error( $_ERR{ERR_UNKNOWN_SERVICE} => "Unknown service $service.");
                return;
            }
        }

        foreach my $service ($xmlobj->children_names) {
            $inetd->disable($service);
            # add a trace to the message log
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled inetd sub-service '$service'");
            my $node = $dom->createElement($service);
            $root->appendChild($node);
        }
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::inetd - VSAP module allowing control and status of services
run from inetd.


=head1 SYNOPSIS

=head2 sys:inetd:status

<vsap type="sys:inetd:status"/>

Returns:

<vsap type="sys:inetd:status">
    <ftp>
        <status>enabled</status>
    </ftp>
    <pop3>
        <status>disabled</status>
    </pop3>
    ...
</vsap>

<vsap type="sys:inetd:status">
    </ftp>
</vsap>

Returns:

<vsap type="sys:inetd:status">
    <ftp>
        <status>enabled</status>
    </ftp>
</vsap>

=head2 sys:inetd:enable

<vsap type="sys:inetd:enable">
    </ftp>
    </pop3>
</vsap>

Returns:

<vsap type="sys:inetd:enable">
    </ftp>
    </pop3>
</vsap>

=head2 sys:inetd:disable

<vsap type="sys:inetd:disable">
    </ftp>
    </pop3>
</vsap>

Returns:

<vsap type="sys:inetd:disable">
    </ftp>
    </pop3>
</vsap>

=head1 DESCRIPTION

This module handles the enabling and disabling of services in the /etc/inetd.conf. After a service
is enabled or disabled, it also sends a SIGHUP signal to inetd via the pid found in inetd's pidfile.
All VSAP requests can take more then one service to be enabled or disabled. With no services specified
the status requests returns the status for all available services. This module doesn't handle all the
services in the inetd.conf, just those which are listed at the time of the module in the @SERVICES array.
Currently, these include pop3, pop3s, imap, imaps, ftp, telnet.

=head1 ERRORS

=head2 sys:inetd:status

    100 - An unknown service was specified.
    101 - Unable to read inetd.conf.

=head2 sys:inetd:enable

    100 - An unknown service was specified, no action taken on any service.
    101 - Unable to read inetd.conf.
    102 - Unable to restart inetd
    103 - No services were specified.
    104 - Not authorized, must be a server admin.

=head2 sys:inetd:enable

    100 - An unknown service was specified, no action taken on any service.
    101 - Unable to read inetd.conf.
    102 - Unable to restart inetd
    103 - No services were specified.
    104 - Not authorized, must be a server admin.

=head2 EXPORT

None by default.

=head1 SEE ALSO

VSAP::Server::Sys::Config::Inetd, inetd(5), inetd.conf(5)

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
