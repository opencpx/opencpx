use Test::More tests => 20;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test::Account;
use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 3;

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok($ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));

## list the folders
my $de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/folder"), 'INBOX', "folder list contains INBOX") || diag $de->toString(1);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 0, "Number of messages in INBOX is 0" ) || diag $de->toString(1);
ok($ACCT->send_email('test-emails/01-01.txt'),"Sending 1st test email");
sleep 1;
ok($ACCT->send_email('test-emails/01-02.txt'),"Sending 2nd test email");
sleep 1;
ok($ACCT->send_email('test-emails/01-03.txt'),"Sending 3rd test email");
sleep 1;
ok($ACCT->send_email('test-emails/01-04.txt'),"Sending 4th test email");
sleep 1;
ok($ACCT->send_email('test-emails/01-05.txt'),"Sending 5th test email");

sleep $MAIL_PAUSE_TIME;

## list, should have 5 messages
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 5 );

## test for attachments
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="test 2"]/attachments'), 0 );
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="attachment test"]/attachments'), 1 );

## check sort order
$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
like( $de->toString, qr(<subject>test 2</subject>.*<subject>attachment test</subject>)si );

##
## test for sort order
##
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><sortby>size</sortby><order>descending</order><sortby2>subject</sortby2><order2>descending</order2></vsap>!);
if ($is_linux) ## Linux w/dovecot has slighly different sizes on the messages.
{
	like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 1</subject>.*<subject>test 4</subject>.*<subject>test 3</subject>.*<subject>test 2</subject>)si );
} else {
	like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 4</subject>.*<subject>test 3</subject>.*<subject>test 2</subject>.*<subject>test 1</subject>)si );
}

## the order should be preserved
$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
if ($is_linux) ## Linux w/dovecot has slighly different sizes on the messages.
{
	like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 1</subject>.*<subject>test 4</subject>.*<subject>test 3</subject>.*<subject>test 2</subject>)si );
} else {
	like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 4</subject>.*<subject>test 3</subject>.*<subject>test 2</subject>.*<subject>test 1</subject>)si );
}

##
## reverse it
##
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><sortby>size</sortby><order>descending</order><sortby2>subject</sortby2><order2>ascending</order2></vsap>!);
like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 1</subject>.*<subject>test 2</subject>.*<subject>test 3</subject>.*<subject>test 4</subject>)si );

## the order should be preserved
$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
like( $de->toString, qr(<subject>attachment test</subject>.*<subject>test 1</subject>.*<subject>test 2</subject>.*<subject>test 3</subject>.*<subject>test 4</subject>)si );

ok($ACCT->send_email('test-emails/01-06.txt'),"Sending test email with non-ascii in subject");

sleep $MAIL_PAUSE_TIME;

## Verify we can do a folder listing.
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
ok( $de, 'Retrieved message list ok');
