use Test::More tests => 3;
use strict;
#use utf8;

BEGIN { use_ok('VSAP::Server::G11N::Mail') };

my $default_encoding = 'UTF-8';

## this file contains utf8 and iso-8859-1 encoded data. Put
## iso-2022-jp tests in the iso-2022-jp encoded test file.

##
## make sure ascii message upgrades to utf-8 w/ non-ascii chars
##
use encoding 'iso-8859-1';
my $body = "this message has a \x{f8} inside it.";  ## o-slash
no encoding;
my $mail = new VSAP::Server::G11N::Mail;
my $foo = $mail->set_body({default_encoding => $default_encoding,
                           from_encoding => 'UTF-8',
                           to_encoding => 'US-ASCII',
                           content_encoding => '',
                           string      => $body});

like($foo->{string}, qr(message has a \x{c3}\x{b8} inside));


##
## message encoded into iso-8859-1 (iso-2022-jp version in other file)
##
use encoding 'utf8';
$body =<<_FOO_;
This message has some ascii,
some Japanese: \x{4EBA}\x{4E5A}\x{4E9A}
and some European characters: \x{00A7}\x{00C7}\x{00DF}

The end.
_FOO_
no encoding;

use encoding 'utf8';
$body =<<_FOO_;
This message has some ascii,
some Japanese: \x{4EBA}\x{4E5A}\x{4E9A}
and some European characters: \x{00A7}\x{00C7}\x{00DF}

The end.
_FOO_
no encoding;

$mail = new VSAP::Server::G11N::Mail;
$foo  = $mail->set_body( { default_encoding => $default_encoding,
			   from_encoding    => 'UTF-8',
			   to_encoding      => 'ISO-8859-1',
			   content_encoding => '',
			   string           => $body } );

like( $foo->{string},
      qr(Japanese: \?\?\?\n.*characters: \x{00A7}\x{00C7}\x{00DF}),
      "iso-8859-1 conversion" );

