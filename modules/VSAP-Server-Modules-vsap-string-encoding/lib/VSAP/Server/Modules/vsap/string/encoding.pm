package VSAP::Server::Modules::vsap::string::encoding;

use 5.008004;
use strict;
use warnings;

use Encode 'from_to';
use Encode::Guess;
use Text::Iconv;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(guess_string_encoding);

##############################################################################

our $VERSION = '0.12';

##############################################################################

sub guess_string_encoding
{
    my $string = shift;

    # remove evil spirits
    $string =~ s/[\x01-\x08\x0B\x0C\x0E-\x1F]//g;

    my $converter = Text::Iconv->new("UTF-8", "UTF-8");
    my $converted = $converter->convert($string);
    if ($string eq $converted) {
        return($string)
    }

    # try and guess the encoding
    my $charset;
    if ($string =~ m![^\011\012\015\040-\176]!) {
        # string contains "high-byte" characters; see if we can't guess what
        # the encoding is (it could just be utf8; it could be anything)
        my $enc;
        # first guess... iso-8859-1
        $enc = guess_encoding($string, qw/iso-8859-1/);
        # next guess... japanese
        $enc = guess_encoding($string, qw/iso-2022-jp euc-jp shiftjis 7bit-jis/) unless (ref($enc));
        # next guess... chinese
        $enc = guess_encoding($string, qw/iso-2022-cn euc-cn big5-eten/) unless (ref($enc));
        if (ref($enc)) {
            $charset = $enc->name;
            $charset =~ tr/A-Z/a-z/;
            if (($charset eq "utf8") || ($charset eq "utf-8")) {
                return($string)
            }
            # decode
            warn("decoding contents from $charset to utf-8");
            from_to($string, $charset, "utf-8");
            undef($enc);
        }
        else {
            # punt
            $charset = "UNKNOWN";
            warn("encoding could not be guessed... punting!");
            $string =~ s![^\011\012\015\040-\176]!?!go;
        }
    }
    return wantarray ? ($string, $charset) : $string;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::string::encoding - VSAP string encoding utilities

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::string::encoding;

=head1 DESCRIPTION

vsap::string::encoding contains some subroutines that perform
common encoding tasks; tasks that are required by more than one
vsap module.

=head2 guess_string_encoding($string)

Try to guess the encoding of a given string and convert the string
into utf8 encoding.

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

