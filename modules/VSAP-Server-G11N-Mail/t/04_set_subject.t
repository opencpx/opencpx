use Test::More tests => 10;

use strict;

BEGIN { use_ok('VSAP::Server::G11N::Mail') };

my $default_encoding = 'UTF-8';

# UTF-8 subject
use encoding 'utf8';
my $subject = "男無頼庵";
no encoding;

my $mail = new VSAP::Server::G11N::Mail;

my $foo;
$foo = $mail->set_subject({default_encoding => $default_encoding,
                           to_encoding => 'UTF8',
			   subject      => $subject});

is($foo, "=?utf-8?B?55S354Sh6aC85bq1?=");

## test to see that we default to utf-8 when unsafe ascii is given
undef $mail;
$mail = new VSAP::Server::G11N::Mail;

undef $foo;
$foo = $mail->set_subject({default_encoding => $default_encoding,
                           to_encoding => 'US-ASCII',
			   subject      => $subject});

is($foo, "=?utf-8?B?55S354Sh6aC85bq1?=");

my $foo2 = $mail->set_subject({ default_encoding => $default_encoding,
                           to_encoding => 'ISO-2022-JP',
                           subject      => $subject});

is($foo2, "=?iso-2022-jp?B?GyRCQ0tMNU1qMEMbKEI=?=");

##
## ASCII subject
##
$subject = "I am a regular ole subject line";

$foo = $mail->set_subject({default_encoding => $default_encoding,
                           to_encoding  => "ASCII",
                           subject      => $subject});

is($foo, "I am a regular ole subject line");

##
## don't MIME encode plain ascii
##
$subject = "I am a regular ole subject line";

$foo = $mail->set_subject({default_encoding => $default_encoding,
                           to_encoding  => "UTF-8",
                           subject      => $subject});

is($foo, "I am a regular ole subject line");

##
## try chinese
##
use encoding 'utf8';
$subject = "\xe4\xbc\x8a\xe6\x8b\x89\xe5\x85\x8b\xe4\xb8\xb4\xe6\x97\xb6\xe6\x80\xbb\xe7\x90\x86\xe9\x98\xbf";
no encoding;

$foo = $mail->set_subject({default_encoding => $default_encoding,
                           to_encoding  => "euc-cn",
                           subject      => $subject});

is($foo, "=?euc-cn?B?0sHArb/LwdnKsdfcwO2wog==?=");

$foo = $mail->set_subject({default_encoding => $default_encoding,
                            to_encoding  => "US-ASCII",
                            subject      => $subject});

is($foo, "=?utf-8?B?5LyK5ouJ5YWL5Li05pe25oC755CG6Zi/?=");

$subject = "\xe7\x94\xb7\xe7\x84\xa1\xe9\xa0\xbc\xe5\xba\xb5";
$foo = $mail->set_subject({default_encoding => $default_encoding,
                            to_encoding  => "US-ASCII",
                            subject      => $subject});
is($foo, "=?utf-8?B?55S354Sh6aC85bq1?=");

##
## iso-8859-1
##
$subject = "This has a \x{f8} in it";
$mail    = new VSAP::Server::G11N::Mail;
$foo     = $mail->set_subject( { default_encoding => $default_encoding,
				 to_encoding      => 'UTF-8',
				 subject          => $subject } );

# Perl5.8.7 and later treats UTF8 and UTF-8 differently.  UTF-8 is considered
# strict UTF-8 and must adhere to the rules of UTF-8.  UTF8 is perls internal
# implementation of UTF8 which is not quite as strict.
is( $foo, "=?utf-8?B?VGhpcyBoYXMgYSDDuCBpbiBpdA==?=", "correct encoding");
