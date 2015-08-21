package VSAP::Server::Modules::vsap::sys::reboot;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR = ( ERR_NOTAUTHORIZED => 100 );

our $REBOOT_PATH = 'sleep 5 && /sbin/reboot &';

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to reboot server");
        return;
    }

    REWT: {
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} reboot server");
        local $> = $) = 0;  ## regain privileges for a moment
        system($REBOOT_PATH);
    }

    # We may never get to here.. humph.

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:sys:reboot');
    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::reboot - VSAP module to reboot an account.

=head1 SYNOPSIS

=head2 vsap:sys:reboot

    <vsap type='vsap:sys:reboot'/>

Responds with:

    <vsap type='vsap:sys:reboot'/>

=head1 DESCRIPTION

This module simply executes the /sbin/reboot binary causes the server to
reboot. Depending on the speed of the reboot, this module might not even
get a response back.

=head1 ERRORS

    100 - Not authorized. You must be a server adminisrator in order to reboot the server.

=head2 EXPORT

None by default.

=head1 SEE ALSO

reboot(2)

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
