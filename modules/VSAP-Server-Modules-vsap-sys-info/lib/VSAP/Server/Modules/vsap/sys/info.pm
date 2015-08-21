package VSAP::Server::Modules::vsap::sys::info;

use 5.008004;
use strict;
use warnings;

use POSIX;

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::sys::monitor;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;
use VSAP::Server::Sys::Platform::Info;

##############################################################################

our $VERSION = '0.12';

our %_ERR = ( 
              ERR_NOTAUTHORIZED => 100,
              ERR_VKERN         => 101,
              ERR_UNKNOWN_FIELD => 102,
            );

##############################################################################

sub _boottime
{
    my $epoch = 0;

    REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        if (-e "/proc/uptime") {
            # Linux
            # cat /proc/uptime
            # 7131666.89 7088764.27  
            my $retval = `/bin/cat /proc/uptime`;
            if ($retval =~ m#^([0-9]*).#) {
                $epoch = time() - $1;
            }
        }
        else {
            # FreeBSD
            my @return = `/bin/ps -p 1 -o lstart`;
            my $date = $return[1];
            $date =~ s/\s+$//g;
            my $command = '/bin/date -j -f %c "' . $date . '" +%s';
            $epoch = `$command`;
            $epoch =~ s/\s+$//g;

        }
    }
    return($epoch);
}

# ----------------------------------------------------------------------------

sub _osrelease
{
    my $version = "0.0.0";
    my $osrelease = (POSIX::uname())[2];
    if ($osrelease =~ /([0-9\.]*?)\-/) {
        $version = $1;
    }
    return $version;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::info::get;

sub handler
{
    my $vsap = shift;
    my $xml = shift;
    my $dom = $vsap->{_result_dom};

    my $info;
    my @fields;

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to obtain system information.");
        return;
    }

    ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $info = new VSAP::Server::Sys::Platform::Info;
    }

    # Obtain the available list of fields from the module.
    my @all_fields = $info->fields;

    unless ($info) {
        $vsap->error($_ERR{ERR_VKERN} => 'Unable to obtain information object.');
        return;
    }

    foreach my $field ($xml->children_names) {
        if (grep(/^$field$/, @all_fields)) {
            push @fields, $field;
        } else {
            $vsap->error($_ERR{ERR_UNKNOWN_FIELD} => "Unknown field: '$field'");
            return;
        }
    }

    @fields = @all_fields
       unless (@fields);

    my $root = $dom->createElement('vsap');

    $root->setAttribute( type => 'sys:info:get');

    foreach my $field (@fields) {
        my $value = $info->get($field);
        next unless (defined($value));
        $root->appendTextChild( $field => $info->get($field));
    }

    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::info::uptime;

sub handler
{
    my $vsap = shift;
    my $xml = shift;
    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to obtain system information.");
        return;
    }

    my $epoch = VSAP::Server::Modules::vsap::sys::info::_boottime();
    my $numsec = $epoch % 60;
    $epoch -= $numsec;

    my $root = $dom->createElement('vsap');

    $root->setAttribute( type => 'sys:info:uptime');
    $root->appendTextChild( 'epoch' => $epoch );

    # set date
    my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') ||
                   VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
    my $d = new VSAP::Server::G11N::Date( epoch => $epoch, tz => $timezone );
        if ($d) {
        my $date_node = $root->appendChild($dom->createElement('date'));
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

    # are reboot notifications monitored
    my %monitor_prefs = VSAP::Server::Modules::vsap::sys::monitor::get_prefs();
    my $notify_reboot = $monitor_prefs{'notify_server_reboot'};
    my $notify_events = $monitor_prefs{'notify_events'};
    my $monitoring_on = $monitor_prefs{'monitor_interval'};
    my $is_monitoring = ($notify_reboot && $notify_events && $monitoring_on);
    $root->appendTextChild( 'notify_reboot' => ($is_monitoring) ? "true" : "false" );

    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::info - VSAP module providing interface for platform based information.

=head1 SYNOPSIS

Obtain all fields:

    <vsap type='sys:info:get'/>

Obtain just certain fields.

    <vsap type='sys:info:get'>
        <nofile/>
        <vmem/>
    </vsap>

=head1 DESCRIPTION

This module obtains the fields contained in the platform. See the 
VSAP::Server::Sys::Platform::Info module for more information and 
a listing of available fields.

=head2 EXPORT

None by default.

=head1 SEE ALSO

VSAP::Server::Sys::Platform::Info module.

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

opyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
