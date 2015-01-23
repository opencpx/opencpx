use Test::More tests => 4;
use strict;

BEGIN { use_ok('VSAP::Server::G11N::Mail') };

## NOTE: I am supplying test data in UTF8 where possible, since this
## is how we receive it from XSLT (we coerce a charset tag in our HTML
## forms).
##
## comparative results must be encoded in iso-2022-jp (i.e., this file
## is encoded using iso-2022-jp). If you use emacs to edit this file,
## don't put non-2022-jp data in it so that the results will not change.

my $default_encoding = 'UTF-8';

use encoding 'utf8';
my $body = "\xe7\x94\xb7\xe7\x84\xa1\xe9\xa0\xbc\xe5\xba\xb5\n\n";
no encoding;

my $mail = new VSAP::Server::G11N::Mail;

my $foo = $mail->set_body({default_encoding => $default_encoding,
			   from_encoding  => 'UTF-8',
                           to_encoding => 'ISO-2022-JP',
                           content_encoding => '',
			   string      => $body});

is($foo->{string}, '男無頼庵' . "\n\n",
   "utf8 to iso-2022-jp conversion");

##
## same message encoded into utf8
##
$mail = new VSAP::Server::G11N::Mail;
$foo = $mail->set_body({default_encoding => $default_encoding,
                           from_encoding => 'UTF-8',
                           to_encoding => 'UTF-8',
                           content_encoding => '',
                           string      => $body});

is($foo->{string}, "\xe7\x94\xb7\xe7\x84\xa1\xe9\xa0\xbc\xe5\xba\xb5\n\n");
diag($foo->{encoding});


##
## convert a message from utf8 to iso-2022-jp that has non-mappable glyphs
##
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
			   to_encoding      => 'ISO-2022-JP',
			   content_encoding => '',
			   string           => $body } );

my $target =<<'_FOO_';
This message has some ascii,
some Japanese: 人扤\x{4e9a}
and some European characters: §扤扤

The end.
_FOO_
is( $foo->{string}, $target, "another iso-2022-jp conversion" );

