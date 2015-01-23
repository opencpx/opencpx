use Test::More tests => 21;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::folders') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

my $MAIL_PAUSE_TIME = 1;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT, "ACCT created");

ok($ACCT->exists, "Account exists");

my $vsap = $ACCT->create_vsap(['vsap::webmail::folders']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t),"Obtained VSAP client");

## list the folders
my $de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
my $nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
is( $nl->string_value, 0, "size of INBOX is 0" );

$oldsize = -s $ACCT->inboxpath;

## send a message to this mailbox
## now send a message and make sure it gets there
ok($ACCT->send_email('test-emails/02.txt'), "sending email");
sleep $MAIL_PAUSE_TIME;

cmp_ok( $oldsize, '<', -s $ACCT->inboxpath, "inbox grew since sending mail");

## check the size
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value, '==', -s $ACCT->inboxpath,"Size of inbox matches size on disk");

## check trash size
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Trash']/size");
cmp_ok( $nl->string_value, '==', -s $ACCT->mailboxpath.'/Trash',"size of trash matches size on disk") || diag $de->toString(1);
$trash_size = $nl->string_value;

## clear it
$de = $t->xml_response(qq!<vsap type="webmail:folders:clear"><folder>INBOX</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:clear']/folder"), 'INBOX',"clear inbox" ) || diag $de->toString(1);

## check the size again
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value, '==', -s $ACCT->inboxpath, "size of inbox matches size on disk after clear") || diag $de->toString(1);

## check trash size again
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Trash']/size");
cmp_ok( $nl->string_value, '==', -s $ACCT->mailboxpath.'/Trash', "size of trash matches size on disk after clear of INBOX") || diag $de->toString(1);
cmp_ok( $trash_size, '<', $nl->string_value, "size of trash has grown changed with clear of INBOX") || diag $de->toString(1);

## delete from Trash
$de = $t->xml_response(q!<vsap type="webmail:folders:clear"><folder>Trash</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:clear']/folder"), 'Trash',"clear trash") || diag $de->toString(1);

## check Trash
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
cmp_ok( $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Trash']/size"),'==',-s $ACCT->mailboxpath.'/Trash', "Size of trash matches disk") || diag $de->toString(1);


##
## test multiple folders
##

## this section duplicates much of above
ok($ACCT->send_email('test-emails/02.txt'), "Send another email");

sleep $MAIL_PAUSE_TIME;

## check the size
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl, '==', -s $ACCT->inboxpath, "Check inbox size after sending mail");

## check trash size
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Trash']/size");
cmp_ok( $nl, '==', -s $ACCT->mailboxpath.'/Trash', "Check trash size after sending email") || diag $de->toString(1);

## clear all folders
$de = $t->xml_response(qq!<vsap type="webmail:folders:clear"><folder>INBOX</folder><folder>Trash</folder></vsap>!);
my @nodes = $de->findnodes("/vsap/vsap[\@type='webmail:folders:clear']/*");
is( scalar(@nodes), 2, "Clear all folders");

## check the INBOX size again
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl, '==', -s $ACCT->inboxpath, "check INBOX after clearing") || diag $de->toString(1);
sleep 5;
## check trash size again
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Trash']/size");
cmp_ok($nl, '==', -s $ACCT->mailboxpath.'/Trash', "Check Trash after clearning") || diag $de->toString(1);
