package VSAP::Client::INET;

use 5.006001;
use strict;
use warnings;

our @ISA = qw/VSAP::Client IO::Socket::INET/;

our $VERSION = '0.12';

use utf8;
use Carp;
use IO::Socket;

use VSAP::Client::Config qw($VSAP_CLIENT_TCP_PORT $VSAP_CLIENT_TCP_HOST);

my %debug = ();

##############################################################################

sub new
{
    my $pkg = shift;
    my %arg = @_;
    my $client;
    $client = IO::Socket::INET->new(
                      PeerAddr => (defined($arg{Hostname}) ? $arg{Hostname} : $VSAP_CLIENT_TCP_HOST),
                      PeerPort => (defined $arg{PeerPort} ?  $arg{PeerPort} : $VSAP_CLIENT_TCP_PORT),
                      Proto    => 'tcp',
                      Timeout  => (defined $arg{Timeout} ? $arg{Timeout} : 40)
                  ) or die "$!";
    bless $client, $pkg;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Client::INET - INET based VSAP client object

=head1 SYNOPSIS

  use VSAP::Client::INET;

  $client = VSAP::Client::INET->new( Hostname => 'somehost', PeerPort => 551);

  $client->authenticate(...);

=head1 DESCRIPTION

Provides client acccess to the vsap server running on a tcp port.  The default configuration options will
come from the VSAP::Client::Config module.

=head1 SEE ALSO

VSAP(1), VSAP::Server(3), VSAP::Client::Config(3), VSAP::Client

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
