use Test::More tests => 20;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 3;

$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });

my $user = $ACCT->userid;
my $homedir = $ACCT->homedir;

ok(ref($t));

## list the folders
my $de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/folder"), 'INBOX' );
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 0 );

ok($ACCT->send_email('test-emails/01-01.txt'), "sending test email 1");
sleep 1;
ok($ACCT->send_email('test-emails/01-02.txt'), "sending test email 2");
sleep 1;
ok($ACCT->send_email('test-emails/01-03.txt'), "sending test email 3");
sleep 1;
ok($ACCT->send_email('test-emails/01-04.txt'), "sending test email 4");
sleep 1;
sleep $MAIL_PAUSE_TIME;

## list, should have 4 messages
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 4, "inbox has 4 messages" );

## now try to delete messages from INBOX
$de = $t->xml_response(qq!<vsap type="webmail:messages:delete">
  <folder>INBOX</folder>
  <uid>1</uid>
  <uid>3</uid>
</vsap>!);

## got two left
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 2, "inbox now has two messages");

## delete something bogus
$de = $t->xml_response(q!<vsap type="webmail:messages:delete"><folder>INBOX</folder><uid>1</uid></vsap>!);
ok( $de, "bogus delete ok");

## move messages to 'Sent Items' and delete them from there
$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>2</uid>
  <uid>4</uid>
  <folder>INBOX</folder>
  <dest_folder>Sent Items</dest_folder>
</vsap>!);
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 2, "Sent Items now has 2 messages");

## delete from 'Sent Items'
$de = $t->xml_response(qq!<vsap type="webmail:messages:delete">
  <folder>Sent Items</folder>
  <uid>1</uid>
  <uid>2</uid>
</vsap>!);

$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 0, "no messages in sent items" );

# Send some more emails. 
ok($ACCT->send_email('test-emails/01-01.txt'), "send test email 5");
sleep 1;
ok($ACCT->send_email('test-emails/01-02.txt'), "send test email 6");
sleep 1;
ok($ACCT->send_email('test-emails/01-03.txt'), "send test email 7");
sleep 1;
ok($ACCT->send_email('test-emails/01-04.txt'), "send test email 8");
sleep 1;

# Fill up their quota. 
system("dd count=55000 if=/dev/zero of=$homedir/foo bs=1024 >/dev/null 2>&1");
system('chown', $ACCT->userid, "$homedir/foo");

## delete from 'Sent Items'
$de = $t->xml_response(qq!<vsap type="webmail:messages:delete">
  <folder>INBOX</folder>
  <uid>5</uid>
  <uid>6</uid>
</vsap>!);

ok($de) || warn $de->toString(1);

## got two left
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 2, "inbox now has two messages");
