package VSAP::Server::XMLObj;

use strict;
use vars qw($VERSION @ISA);
use XML::SimpleObject::LibXML;

$VERSION = '0.12';

@ISA = qw(XML::SimpleObject::LibXML);

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::XMLObj - VSAP Server XML Object

=head1 SYNOPSIS

        my $dom = XML::LibXML::Document->new("1.0", "UTF-8");
        $dom->setDocumentElement($content);
        $xmlobj = new VSAP::Server::XMLObj($dom);

=head1 SEE ALSO

L<perl>. VSAP::Server module.

=head1 AUTHOR

System Administrator, E<lt>root@iserver.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

