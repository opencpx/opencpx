package VSAP::Server::Base;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

##############################################################################

sub url_encode
{
  my $text = shift;

  if ($text ne "") {
    $text =~ s/([^0-9A-Za-z_])/"%".unpack("H2",$1)/ge;
    # replacing /'s with %2f has been a problem so let's put those back.
    $text =~ s/%2f/\//g;
  }
  return $text;
}

##############################################################################

sub xml_escape
{
  my $text = shift;

  $text =~ s/\&/\&amp;/g;
  $text =~ s/</\&lt;/g;
  $text =~ s/>/\&gt;/g;
  $text =~ s/\r/\&#013;/g;
  $text =~ s/\n/\&#010;/g;
  $text =~ s/"/\&#034;/g;
  $text;
}

##############################################################################

sub xml_unescape
{
  my $text = shift;

  $text =~ s/\&amp\;/\&/g;
  $text =~ s/\&lt\;/</g;
  $text =~ s/\&#013\;/\r/g;
  $text =~ s/\&#010\;/\n/g;
  $text;
}

##############################################################################

1;

=head1 NAME

VSAP::Server::Base - various low-level supporting subroutines

=head1 SYNOPSIS

  use VSAP::Server::Base;

  $filename_url_encoded = VSAP::Server::Base::url_encode($filename);
  $node->appendTextChild(filename     => $filename);
  $node->appendTextChild(url_filename => $filename_url_encoded);

  $bar = VSAP::Server::Base::xml_escape($bar);
  $node->appendTextChild(foo => $bar);

  $bar = $xmlobj->child('foo')->value;
  $bar = VSAP::Server::Base::xml_unescape($bar);

=head1 DESCRIPTION

Several string manipulation functions that can be used to aid in 
contructing (or deconstructing) a DOM.

=head1 Subroutines

=head2 url_encode()

    * encodes a filename (typically)

=head2 xml_escape()

    * escapes strings in preparation to append to a DOM

=head2 xml_unescape()

    * unescapes strings retrieved from a DOM

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut

