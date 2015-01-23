use Test::More tests => 6;
BEGIN { use_ok('VSAP::Server::G11N') };

use utf8;

#my $subject = "男無頼庵";
my $subject = "\xe7\x94\xb7\xe7\x84\xa1\xe9\xa0\xbc\xe5\xba\xb5";
#$subject = Encode::decode_utf8($subject);
#diag($subject);

my $g11n = new VSAP::Server::G11N;

ok($g11n);

my $newstring = $g11n->convert(
    {from_encoding => 'UTF-8',
     to_encoding   => 'UTF-8',     
     string        => $subject}
);

is($newstring,"男無頼庵");

$newstring = $g11n->convert(
    {from_encoding => 'UTF-8',
     to_encoding   => 'ISO-2022-JP',
     string        => $subject}
);

use encoding "ISO-2022-JP";
is($newstring, "\$BCKL5Mj0C(B");

$subject = $g11n->convert(
    {from_encoding => 'ISO-2022-JP',
     to_encoding   => 'UTF-8',
     string        => $newstring}
);

is($subject, "\xe7\x94\xb7\xe7\x84\xa1\xe9\xa0\xbc\xe5\xba\xb5");


$newstring = "ø";
$subject = $g11n->convert(
	{from_encoding => 'unknown-8bit',
	to_encoding    => 'UTF-8',
	string         => $newstring}
);

is( $subject, "ø" );
