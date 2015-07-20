package VSAP::Server::Modules::vsap::logout;

use 5.008004;
use strict;
use warnings;

##############################################################################

our $VERSION = '0.12';

our $NO_AUTH = 1;

##############################################################################

sub handler {
    my $vsap = shift;

    $vsap->{disconnect} = 1;
    $vsap->{_cmd_response} = "";
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::logout - VSAP logout

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::logout;
  blah blah blah

=head1 DESCRIPTION

Terminates a vsap session.

=head1 SEE ALSO

vsap(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
