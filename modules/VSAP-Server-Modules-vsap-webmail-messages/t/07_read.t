use Test::More tests => 48;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;
use utf8;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 5;

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });
ok(ref($t));

# Setting messages per page to 50 so we don't have message dropping to
# the second page if tests get added above.
$t->xml_response(qq!<vsap type='webmail:options:save'><webmail_options><messages_per_page>50</messages_per_page></webmail_options></vsap>!);

ok($ACCT->send_email('test-emails/01-01.txt'));
mail_pause();
ok($ACCT->send_email('test-emails/attachment02.txt'));
mail_pause();
ok($ACCT->send_email('test-emails/attachment03.txt'));
mail_pause();

## do not go through sendmail on this one
ok($ACCT->append_email_to_spool('test-emails/attachment04.txt',$ACCT->inboxpath, { '$to' => $ACCT->emailaddress}));

## get a list of UIDs in the inbox
my $de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder><sortby>date</sortby><order>ascending</order></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 4 ) || print STDERR $de->toString();

# Create a uid mapping
my @uidList = map { $_->to_literal() } $de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message/uid');

## view happy message
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uidList[3]</uid></vsap>!);
my $body = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
$body =~ s/\r\n/\n/g;
is( $body, 'This is test 1&#013;&#010;<br>&#013;&#010;<br>Bye&#013;&#010;<br>' );
my $hour = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/hour');
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/o_hour'), 
	sprintf("%02d", (($hour + 0) % 24)), "timezone check" );  ## adjust to time_zone pref

## view tricky message
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uidList[1]</uid></vsap>!);
$body = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
$body =~ s/\r\n/\n/g;
like( $body, qr("Every day over 340 million web), "Testing Tricky message" );

## look at the attachment of the 3rd message
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uidList[0]</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/name'), 'nelson_Chica_saltando02.jpg' );
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/year'), '2001' );
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/month'), '9' );
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/hour'), 21, "gmt offset" );
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/date/second'), '41' );

##
## read raw
##
$de = $t->xml_response(qq!<vsap type="webmail:messages:raw"><folder>INBOX</folder><uid>$uidList[0]</uid></vsap>!);
like( $de->toString, qr(\Q------=_NextPart_000_00C0_01C104A3.A4029EA0--\E), "read raw message" );

#print STDERR $de->toString(1);

##
## read raw w/ html
##
$de = $t->xml_response(qq!<vsap type="webmail:messages:raw"><folder>INBOX</folder><uid>$uidList[2]</uid></vsap>!);
like( $de->toString, qr(&lt;img.*src=&#034;http://df3ssw\.com/2/&#034;&gt;)s, "read raw html message" );

## read with quoting
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><quote>&gt; </quote><folder>INBOX</folder><uid>$uidList[3]</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(&gt; This is test 1), "read with quoting body");

## read with saved attachments

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uidList[0]</uid><save_attach>yes</save_attach></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/filepath'), 'nelson_Chica_saltando02.jpg' );
is( -e $ACCT->mailtmppath.'/nelson_Chica_saltando02.jpg', 1, "read attachments");

## try an international message
ok($ACCT->send_email('test-emails/utf8-test.txt'));
sleep 1;
# Try a message with raw iso-8859-1 in the subject.
ok($ACCT->send_email('test-emails/01-06.txt'),'Sending message with high ascii in subject');

mail_pause();

## find the uid of this message
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder><sortby>date</sortby><order>ascending</order></vsap>!);

my $uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="tÃ©sting"]/uid', "list with iso-8859-1 subject");
my $uid2 = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[from/address/full_address="worbe@kbp-organisationsberatung.de"]/uid', "list with raw iso-8859-1 subject");

@uidList = map { $_->to_literal() } $de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message/uid');

is($uid,$uidList[5]);

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><encoding>ISO-8859-1</encoding><uid>$uid</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/subject'), "t\xe9sting", "read with iso-8859-1 encoding" );

is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/from/address/personal'), 
	q!"ã§æŽ¢ã™"!, "personal decoded utf8" );

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><encoding>ISO-8859-1</encoding><uid>$uid2</uid></vsap>!);

ok($de, 'Retrieved message with raw high ascii in subject');
ok($ACCT->send_email('test-emails/iso2022jp.txt'));
mail_pause();
# $de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder><sortby>date</sortby><order>ascending</order></vsap>!);
@uidList = map { $_->to_literal() } $de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message/uid');
## headers
$uid2 = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="test ç”·ç„¡é ¼åºµ"]/uid');
is($uid2, $uidList[6], "listing with iso-2022-jp subject");
## message
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid2</uid><encoding>ISO-2022-JP</encoding></vsap>!);

is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), "ç”·ç„¡é ¼åºµ&#013;&#010;<br>", "read with iso-2022-jp body" );
#diag($de->toString);

## read without explicit encoding
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid2</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), "ç”·ç„¡é ¼åºµ&#013;&#010;<br>", "read with implicit encoding" );

## Test URL encoding support. 
ok($ACCT->send_email('test-emails/url_highlight.txt'));
mail_pause();

# Turn on url highlighting.. 
$t->xml_response(qq!<vsap type='webmail:options:save'><webmail_options><url_highlight>yes</url_highlight></webmail_options></vsap>!);

$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="URL highlight test."]/uid');

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
$body = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
like($body,qr(href="http://www.someurl.com"),"url is a link");

$t->xml_response(qq!<vsap type='webmail:options:save'><webmail_options><url_highlight>no</url_highlight></webmail_options></vsap>!);

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
$body = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
unlike($body,qr(href="http://www.someurl.com"),"url is not linked");

=pod

## cn message
ok($ACCT->send_email('test-emails/iso2022cn.txt'));
mail_pause();
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="ä¼Šæ‹‰å…‹ä¸´æ—¶æ€»ç†é˜¿"]/uid');
ok($uid, "got a uid");
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr!!, "body groked" );

## kr message
#ok($ACCT->send_email('test-emails/iso2022kr.txt'));
#sleep 5;
#$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
#my $uid4 = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="2022-kr_ë°°ìŠ¹ì§„_"]/uid');
#is($uid3, 7);
#diag($de->toString);

=cut

##
## an unencoded message
## NOTE: Encode::decode will substitute \xFFFD for malformed UTF-8
## NOTE: characters. See Encode(3) for details
##
ok( $ACCT->send_email('test-emails/raw-high-ascii2.txt'));
mail_pause();
$de = $t->xml_response( q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);  #ú
use encoding 'iso-8859-1';
$uid = $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/message[subject='Acent\x{fa}e su nivel profesional.']/uid");
no encoding;
ok( $uid, "got the uid: $uid" );

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(Universidad
\s*para la Cooperaci&oacute;n Internacional), "unencoded body groked" );

#&amp;oacute;n Internacional), "unencoded body groked" );

##
## try the unencoded o-slash
##
ok( $ACCT->send_email('test-emails/oslash.txt'), 'sending o-slash message' );
mail_pause();
$de = $t->xml_response( q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
use encoding 'iso-8859-1';
$uid = $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/message[subject='testing the o-slash: \x{c3}\x{b8}']/uid");
no encoding;
ok( $uid, "got the o-slash uid: $uid" );

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(this message reminds everyone of the \x{fffd}\x{fffd} character)i, "o-slash body groked" );

##
## try the unknown encoding o-slash
##
ok( $ACCT->send_email('test-emails/oslash2.txt'), 'sending o-slash (2) message' );
mail_pause();
$de = $t->xml_response( q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
$uid = $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/message[subject='fozzie bear says \x{c3}\x{b8}']/uid");
ok( $uid, "got the o-slash 2 uid: $uid" );

$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(Have a nice day, sez fozzie)i, "o-slash 2 body groked" );


##
## try a date with high ascii
##
ok( $ACCT->send_email('test-emails/high-ascii-date.txt'), "sending high-ascii in date" );
mail_pause();
$de = $t->xml_response( q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[from/address/mailbox="35sesf45w6c3"]/uid');
ok( $uid, "got uid for high ascii date: $uid" );

##
## this message also contains some unicode that breaks things
##
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$uid</uid></vsap>!);
#print STDERR $de->toString(1);
$body = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
like( $body , qr(wish to receive this)i, "high ascii date body groked" );


##
## kr message
##
ok($ACCT->send_email('test-emails/kr_encoding.txt'));
mail_pause();
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
#use encoding 'utf8'; # (±¤°í)±¤°í·Î°í¹ÎÁßÀÌ¼¼¿ä?±¤°í¸¦ÀßÇØ¾ß»ç¾÷¼º°øÇÏÁÒ2878610@"]/uid');
#$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="(\x{B1}\x{A4}\x{B0}\x{ED})\x{B1}\x{A4}\x{B0}\x{ED}\x{B7}\x{CE}\x{B0}\x{ED}\x{B9}\x{CE}\x{C1}\x{DF}\x{C0}\x{CC}\x{BC}\x{BC}\x{BF}\x{E4}?\x{B1}\x{A4}\x{B0}\x{ED}\x{B8}\x{A6}\x{C0}\x{DF}\x{C7}\x{D8}\x{BE}\x{DF}\x{BB}\x{E7}\x{BE}\x{F7}\x{BC}\x{BA}\x{B0}\x{F8}\x{C7}\x{CF}\x{C1}\x{D2}2878610@"]/uid');
#no encoding;
$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[from/address/full_address="obk1@netian.com"]/uid');
ok($uid, "got uid for kr message") || diag $de->toString(1);

## wait no longer than necessary or $MAIL_PAUSE_TIME (whichever comes first)
## this saves (with 34 tests) about 25 seconds of test time
sub mail_pause {
    my $sent_time  = time;
    my $mtime_orig = (stat($ACCT->inboxpath))[9];
    do { sleep 1 } while( time <= ($sent_time + $MAIL_PAUSE_TIME) &&
                          $mtime_orig == (stat($ACCT->inboxpath))[9] );
}

END { } 
