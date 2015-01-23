package VSAP::Client::UNIX;

use 5.006001;
use strict;
use warnings;

our @ISA = qw/VSAP::Client IO::Socket::UNIX/;

our $VERSION = '0.03';

use utf8;
use Carp;
use IO::Socket;
use VSAP::Client::Config qw($VSAP_CLIENT_MODE $VSAP_CLIENT_TCP_PORT $VSAP_CLIENT_UNIX_SOCKET_PATH);

my %debug = ();

sub new {
    my $pkg = shift;
    my %arg = @_;
    my $client;

    $client = IO::Socket::UNIX->new( Type    => SOCK_STREAM,
                                       Peer    => ($arg{Socket} ? $arg{Socket} : $VSAP_CLIENT_UNIX_SOCKET_PATH),
				       Timeout => 40,
				 ) or die "$!"; #return;
    binmode $client, ":utf8";
    #binmode $client, ":encoding(utf8)";
    bless $client, $pkg;
}

1;
__END__

=head1 NAME

VSAP::Client::UNIX - Unix domain socket based VSAP client object

=head1 SYNOPSIS

  use VSAP::Client;

  # Unix domain socket mode.  
  $client = VSAP::Client::UNIX->new( mode => 'unix', Socket => '/var/run/vsapd.sock');

  $client->authenticate(...);

=head1 DESCRIPTION

Provides client acccess to the vsap server running on a unix domain socket.  The 
default configuration options will come from the VSAP::Client::Config module. 

=head1 SEE ALSO

VSAP(1), VSAP::Server(3), VSAP::Client::Config(3), VSAP::Client(3), VSAP::Client::INET

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
