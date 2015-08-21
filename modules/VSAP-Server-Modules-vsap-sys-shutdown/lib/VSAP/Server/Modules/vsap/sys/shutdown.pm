package VSAP::Server::Modules::vsap::sys::shutdown;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR = ( ERR_NOTAUTHORIZED => 100 );

our $SHUTDOWN_PATH = 'sleep 5 && /sbin/poweroff &';

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to shut down server");
        return;
    }

    REWT: {
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} shut down server");
        local $> = $) = 0;  ## regain privileges for a moment
        system($SHUTDOWN_PATH);
    }

    # We may never get to here.. humph.

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:sys:shutdown');
    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::shutdown - VSAP module to shut down an account.

=head1 SYNOPSIS

=head2 vsap:sys:shutdown

    <vsap type='vsap:sys:shutdown'/>

Responds with:

    <vsap type='vsap:sys:shutdown'/>

=head1 DESCRIPTION

This module simply executes the /sbin/poweroff binary causes the VPS server
to shut down. Depending on the speed of the shutdown, this module might not
even get a response back.

=head1 ERRORS

    100 - Not authorized. You must be a server adminisrator in order to shut down the server.

=head2 EXPORT

None by default.

=head1 SEE ALSO

reboot(8)

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
