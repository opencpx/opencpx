use Test::More tests => 30;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::folders') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;
my $MAIL_PAUSE_TIME = 5; 

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT);

ok($ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail::folders']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));

##  <vsap type="webmail:folders:list">
my $de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
my $nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
is( $nl->string_value, 0 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, 0 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/recent_messages");
is( $nl->string_value, 0 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/unseen_messages");
is( $nl->string_value, 0 ) || diag $de->toString(1);

## now send a message and make sure it gets there
ok($ACCT->send_email('test-emails/01.txt'));

## append a message to "Sent Items" to test unseen_messages count
my $maildir = $ACCT->mailboxpath;
system("cat test-emails/03.txt >> '$maildir/Sent Items'");

## give the mail some time for delivery
sleep $MAIL_PAUSE_TIME;

## should now show the mail we just received
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, 1, "Verify message was delivered to Inbox") || diag $de->toString(1); 

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

## NOTE: this test changed because we removed the initial open('INBOX') at object creation time.
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/recent_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/unseen_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

## and one more time to see if the status changed
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/recent_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/unseen_messages");
is( $nl->string_value, 1 ) || diag $de->toString(1);

## make a directory for listing; make sure 'zzz' isn't in there
system('mkdir', '-p', $ACCT->mailboxpath.'/zzz');
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Sent Items"]') ) || diag $de->toString(1);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Drafts"]') ) || diag $de->toString(1);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Trash"]') ) || diag $de->toString(1);
ok( ! $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="zzz"]') ) || diag $de->toString(1);

## just list one folder
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"><folder>INBOX</folder></vsap>!);
my @nodes = $de->findnodes("/vsap/vsap[\@type='webmail:folders:list']/folder") || diag $de->toString(1);
is( @nodes, 1 ) || diag $de->toString(1);

## list no folders
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"><folder>bogus</folder></vsap>!);
@nodes = $de->findnodes('/vsap/vsap[@type="webmail:folders:list"]/folder');
is( @nodes, 0 );

## list folders with modified utf-7 contents
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Jack&amp;Jill</folder></vsap>!);
# Subscribe to newly created folder so it shows up in the listing.
$de = $t->xml_response( qq!<vsap type="webmail:folders:subscribe"><folder>Jack&amp;Jill</folder></vsap>! );

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"><folder>INBOX</folder></vsap>!);
@nodes = $de->findnodes('/vsap/vsap[@type="webmail:folders:list"]/folder');
is( @nodes, 1 ) || diag $de->toString(1);

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="webmail:folders:list"]/folder');
if ($ENV{VST_PLATFORM} eq "Signature") { 
	is( @nodes, 7 ) || diag $de->toString(1);
} else { 
	is( @nodes, 5 ) || diag $de->toString(1);
}

## make an unreadable folder in the Mail directory - make sure folder:list handles without crashing
system('touch', $ACCT->mailboxpath.'/badfolder');
chmod 0000, $ACCT->mailboxpath.'/badfolder';
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Sent Items"]') ) || diag $de->toString(1);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Drafts"]') ) || diag $de->toString(1);
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="Trash"]') ) || diag $de->toString(1);
ok( ! $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="badfolder"]') ) || diag $de->toString(1);
#print STDERR $de->toString(1);

## test brief listing
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:list"><fast/></vsap>! );
ok(   $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="INBOX"]'), "fast listing" );
ok( ! $de->find('/vsap/vsap[@type="webmail:folders:list"]/folder[name="INBOX"]/num_messages'), "no status nodes" );
