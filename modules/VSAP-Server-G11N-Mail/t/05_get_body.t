use Test::More tests => 9;

use strict;

BEGIN { use_ok('VSAP::Server::G11N::Mail') };

use XML::LibXML;

my $default_encoding = 'UTF-8';

#use encoding 'ISO-2022-JP';
my $body = '男無頼庵

frogs
';
#no encoding;

my $mail = new VSAP::Server::G11N::Mail;

my $foo;
$foo = $mail->get_body({default_encoding => $default_encoding,
			   from_encoding  => 'ISO-2022-JP',
                           to_encoding => 'UTF-8',
                           content_encoding => '',
			   string      => $body});

like($foo, qr(frogs), "2022-jp body" );
ok( test_dom($foo), "added to dom" );

undef $mail;
undef $foo;
undef $body;

$mail = new VSAP::Server::G11N::Mail;
$body = <<_MSG_;
PEhUTUw+PEhFQUQ+PFRJVExFPsDMILinIDo8L1RJVExFPg0KPE1FVEEgaHR0cC1lcXVpdj1Db250ZW50
LVR5cGUgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PWtzX2NfNTYwMS0xOTg3Ij4NCjxNRVRBIGNv
bnRlbnQ9Ik1TSFRNTCA2LjAwLjI2MDAuMCIgbmFtZT1HRU5FUkFUT1I+PC9IRUFEPjxCT0RZIHRleHQ9
YmxhY2sgdkxpbms9cHVycGxlIGFMaW5rPXJlZCBsaW5rPWJsdWUgYmdDb2xvcj13aGl0ZSB0b3BNYXJn
aW49MCBtYXJnaW5oZWlnaHQ9IjAiPg0KPFRBQkxFIGNlbGxTcGFjaW5nPTAgY2VsbFBhZGRpbmc9MCB3
aWR0aD03MDAgYWxpZ249Y2VudGVyIGJvcmRlcj0wPg0KPFRCT0RZID4NCjxUUiA+DQo8VEQgd2lkdGg9
NzAwIGJnQ29sb3I9Izk5NjY2NiA+DQogIDxhIA0KICAgICAgaHJlZj0iaHR0cDovL3d3dy5vazQ1bWFs
bC5jb20vbWFpbC9za3kvc2t5X2cuaHRtIiB0YXJnZXQ9X2JsYW5rIA0KICAgICAgPg0KICA8SU1HIGhl
aWdodD0zMyANCiAgICAgIHNyYz0iaHR0cDovL3d3dy5vazQ1bWFsbC5jb20vbWFpbC9za3kvdGl0bGVf
YmFyLmdpZiIgd2lkdGg9NzAwIGJvcmRlcj0wIA0KICAgICAgPjwvYT48L1REPg0KPC9UUj4NCiAgICAg
IDxUUiA+IDxURCB3aWR0aD03MDAgYmdDb2xvcj0jOTk2NjY2PjxQPg0KICA8YSANCiAgICAgIGhyZWY9
Imh0dHA6Ly93d3cub2s0NW1hbGwuY29tL21haWwvc2t5L3NreV9nLmh0bSIgdGFyZ2V0PV9ibGFuayAN
CiAgICAgID4NCiAgICA8SU1HIHdpZHRoPTcwMCBoZWlnaHQgPSA3MDYgDQogICAgICBzcmM9Imh0dHA6
Ly8yMDMuMjUxLjIyNS4xNTkvfmludGVsamptL2ltZy9za3lsaWZlLmpwZyIgYm9yZGVyPTAgDQogICAg
ID48L2E+PC9QPjwvVEQ+PC9UUj4NCiAgICAgIDxUUj48VEQgd2lkdGg9NzAwID48ZGl2IGFsaWduPWNl
bnRlciA+DQogIDxhIA0KICAgICAgaHJlZj0iaHR0cDovL3d3dy5vazQ1bWFsbC5jb20vbWFpbC9za3kv
c2t5X2cuaHRtIiB0YXJnZXQ9X2JsYW5rIA0KICAgICAgPg0KICAgICAgPElNRyB3aWR0aD03MDAgaGVp
Z2h0PTMzIA0KICAgICAgc3JjPSJodHRwOi8vd3d3Lm9rNDVtYWxsLmNvbS9tYWlsL3NreS9xcXFfYmFy
LmdpZiIgYm9yZGVyPTAgDQogICAgID4NCiAgICA8L2E+IDxiciA+LjxiciANCiAgICAgID48L2Rpdj48
L1REPjwvVFI+PFRSPjxURCB3aWR0aD03MDA+DQogICAgICAgICAgIDxkaXYgYWxpZ249Y2VudGVyPg0K
ICA8SU1HIGhlaWdodD0zMyANCiAgICAgIHNyYz0iaHR0cDovL3d3dy5vazQ1bWFsbC5jb20vbWFpbC9z
a3kvdGl0bGVfYmFyLmdpZiIgd2lkdGg9NzAwIA0KICAgICAgPg0KICAgICAgPGJyID4gLiA8YnIgDQog
ICAgICA+PC9kaXY+PC9URD48L1RSPjxCUiA+PGJyPg0KICAgICAgICAgICA8VFI+PHRkIHN0eWxlPSJQ
QURESU5HLVRPUDogMTBweCIgYWxpZ249bWlkZGxlIHdpZHRoPTY4OCBiZ0NvbG9yPSM5OTY2NjYgDQog
ICAgPjxkaXYgYWxpZ249Y2VudGVyPg0KDQogIDxmb250IGNvbG9yPSNmZmZmZmYgDQogICAgICA+DQog
ICAgursguN7Az8C6IMGkurjF673Fus4gscew7bvnx9fAziCxpLDtuN7Az7fOvK0gKLGksO0pt84gx6Wx
4sfRILjewM/A1LTPtNkuDQogICAgPGJyIA0KICAgICAgPg0KICAgICAgICCxzcfPwMcguN7Az8HWvNK0
wiBodHRwOi8vaWxvdmVzY2hvb2wuY28ua3K/obytIDIwMDKz4jEyv/nAzMD8v6EgDQogICAgICCwy7v2
x8+/tL3AtM+02S4NCiAgICAgICAgPGJyID6w7bC0wMcguN7Az8HWvNLAzL/cv6G0wiC+7rawx9EgwaS6
uLW1ILChwfaw7SDA1sH2IL7KvcC0z7TZLjxiciANCiAgICAgID4guN7Az7z2vcXAuyC/+MShIL7KwLi9
w7jpIMDMuN7Az8C7IMDUt8LIxCC89r3FsMW6ziANCiAgICAgICAgICC59sawwLsgtK23r8HWvcq9w7/k
Ljxicj4NCiAgICAgICAgICC43sDPILD8t8MNCiAgICAgICAgICC5rsDHtMIgY2o3eXUyQGRyZWFtd2l6
LmNvbbfOILmuwMfH2CDB1r3DseIgudm2+LTPtNkuIDxicj4NCiAgICAgICAgICBJZiB5b3UgZG9uJ3Qg
d2lzaCB0byByZWNlaXZlIHRoaXMgZS1tYWlsIA0KICAgICAgY2xpY2s8L2ZvbnQ+DQogICAgICAgICAg
ICAgICAgPGJyPg0KICAgICAgICAgICAgICAgICA8QSBocmVmPSJtYWlsdG86Y2o3eXUyQGRyZWFtd2l6
LmNvbSIgPg0KICAgICAgICAgICAgICAgIDxpbWcgDQogICAgICBoZWlnaHQ9Mjcgc3JjPSJodHRwOi8v
dml0Y2l0eS5uZXQvbWFpbC9jZXMvMjAwMzAyMjQvcmVqZWN0LmdpZiIgd2lkdGg9MTAwIA0KICAgICAg
Ym9yZGVyPTA+PC9BPjwvZGl2PjwvdGQ+PC9UUj48L1RCT0RZPjwvVEFCTEU+PFA+Jm5ic3A7PC9QPiAg
DQo8L0JPRFk+PC9IVE1MPg0K
_MSG_

$foo = $mail->get_body({ default_encoding => $default_encoding,
			 from_encoding    => 'ks_c_5601-1987',
#			 from_encoding    => 'UTF-8',
			 to_encoding      => 'UTF-8',
			 content_encoding => 'B',
			 string           => $body });

like( $foo, qr(wish to receive this), "base64 encoded html body" );
ok( test_dom($foo), "added to dom" );

##
## korean text
##
open TEST, "test-data/euc-kr.txt"
  or die "Could not open test-data/euc-kr.txt: $!\n";
{
    local $/ = undef;
    $body = <TEST>;
}
close TEST;

$foo = $mail->get_body({ default_encoding => $default_encoding,
			 from_encoding    => 'euc-kr',
			 to_encoding      => 'UTF-8',
			 string           => $body });

like( $foo, qr(If you don't want to receive this), "korean text body" );
ok( test_dom($foo), "added to dom" );


##
## russian (Windows-1251) test
##
open TEST, "test-data/windows-1251.txt"
  or die "Could not open test-data/windows-1251.txt: $!\n";
{
    local $/ = undef;
    $body = <TEST>;
}
close TEST;

$foo = $mail->get_body({ default_encoding => $default_encoding,
			 from_encoding    => 'Windows-1251',
			 to_encoding      => 'UTF-8',
			 string           => $body });

like( $foo, qr(www.vinalco.ru), "russian text body" );
ok( test_dom($foo), "added to dom" );


exit;

sub test_dom {
    my $string = shift;
#    my $dom = XML::LibXML::Document->createDocument();              ## this is how VSAP::Server used to be
    my $dom = XML::LibXML::Document->createDocument('1.0', 'UTF8');  ## this is how it should be
    $dom->setDocumentElement($dom->createElement('vsap'));
    my $root = $dom->createElement( 'vsap' );

    eval {
	$root->appendTextChild( body => $string );
	$dom->documentElement->appendChild($root);
	my $string = $dom->toString(1);
    };

    if( $@ ) {
#	return 1 if $@ =~ /no dtd found/i;

	warn "************************ERROR: $@\n";
	return;
	
    }

    1;
}
