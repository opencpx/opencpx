use Test::More tests => 8;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

my $MAIL_PAUSE_TIME = 3; 

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));
ok($ACCT->send_email('test-emails/attachment01.txt'));
sleep $MAIL_PAUSE_TIME;

## get a list of UIDs in the inbox
my $de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);

is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 1 );

my $uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[from/address/mailbox="atlas"]/uid');

## fetch the message & attachment id
$de = $t->xml_response( qq!<vsap type="webmail:messages:read"><uid>$uid</uid></vsap>! );
my $attach_id = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/attach_id');

## make place to save the attachment
{
    local $> = getpwnam($ACCT->userid());
    mkdir $ACCT->mailtmppath . "/foo";
}

## get the attachment
$de = $t->xml_response(qq!<vsap type="webmail:messages:attachment"><folder>INBOX</folder><uid>$uid</uid><attach_id>$attach_id</attach_id><messageid>foo</messageid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:attachment"]/attachment/mime_type'), "image/jpeg", "attachment mime-type" );
my $tmpPath = $de->findvalue('/vsap/vsap[@type="webmail:messages:attachment"]/attachment/path');
my $fileName = $de->findvalue('/vsap/vsap[@type="webmail:messages:attachment"]/attachment/filename');

ok(-f $tmpPath, "attachment extracted");
is($fileName, "nelson_Chica_saltando02.jpg", "check attachment name");

END { }
