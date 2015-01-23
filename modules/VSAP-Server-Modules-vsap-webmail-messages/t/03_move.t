use Test::More tests => 23;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test::Account;
use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 3;

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });
my $homedir = $ACCT->homedir;

ok(ref($t));

## list the folders
my $de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/folder"), 'INBOX' );
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 0 );


my $inboxpath = $ACCT->inboxpath;
my $mailboxpath = $ACCT->mailboxpath;
my $trashpath= $ACCT->mailboxpath.'/Trash';;
my $userid = $ACCT->userid;


ok($ACCT->send_email('test-emails/01-01.txt'));
sleep 1;
ok($ACCT->send_email('test-emails/01-02.txt'));
sleep 1;
ok($ACCT->send_email('test-emails/01-03.txt'));
sleep 1;
ok($ACCT->send_email('test-emails/01-04.txt'));
sleep $MAIL_PAUSE_TIME;

## list Trash (system folders are created automatically)
$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>Trash</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 0 );

## list, should have 4 messages
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 4 );

#print STDERR $de->toString(1);

## trying moving to Trash after making INBOX unreadable
chmod (0000,$inboxpath);
$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>1</uid>
  <uid>4</uid>
  <folder>INBOX</folder>
  <dest_folder>Trash</dest_folder>
</vsap>!);
## NOTE: INBOX has different behavior than other mail folders; it
## NOTE: always says "empty" when the folder is unreadable no matter
## NOTE: what. Other folders will trigger the message in folder_open.
like( $de->findvalue('/vsap/vsap[@type="error"][@caller="webmail:messages:move"]/message'), qr(folder not readable)i, 'Checking folder not readable');

if ($is_linux)	## dovecot creates an inbox folder in the imap folder
		## space from the above failure.  Not sure why!
{
	unlink($mailboxpath."/inbox");
	system("rm", "-rf", $mailboxpath."/.imap/INBOX");
	chmod (0660,$inboxpath);
} else {
	chmod (0600,$inboxpath);
}

## trying moving to Trash after making Trash unwriteable
chmod (0400,$trashpath);
$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>1</uid>
  <uid>4</uid>
  <folder>INBOX</folder>
  <dest_folder>Trash</dest_folder>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"][@caller="webmail:messages:move"]/message'), qr(folder not writable), 'Trash is not writeable');

## double-check no msgs in Trash
$de = $t->xml_response('<vsap type="webmail:messages:list"><folder>Trash</folder></vsap>');
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 0 );

## now try to move the message to Trash
chmod (0600,$trashpath);
$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>1</uid>
  <uid>4</uid>
  <folder>INBOX</folder>
  <dest_folder>Trash</dest_folder>
</vsap>!);
ok( ! $de->findvalue('/vsap/vsap[@type="error"]/message'), 'Moved message to Trash' );

## list again
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 2 );

$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>Trash</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 2 );

## make Trash unreadable
chmod (0000,$trashpath);
$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>1</uid>
  <folder>Trash</folder>
  <dest_folder>INBOX</dest_folder>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"][@caller="webmail:messages:move"]/message'), qr(unable to open)i);

## put something in the Sent Items folder
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>INBOX</folder><uid>2</uid></vsap>!);
#print STDERR $de->toString(1);

$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>2</uid>
  <folder>INBOX</folder>
  <dest_folder>Sent Items</dest_folder>
</vsap>!);

$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/num_messages"), 1 );

unlink $inboxpath;
unlink $trashpath;

ok($ACCT->send_email('test-emails/01-01.txt'));
sleep $MAIL_PAUSE_TIME;
ok($ACCT->send_email('test-emails/01-01.txt'));
sleep $MAIL_PAUSE_TIME;

$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>1</uid>
  <folder>INBOX</folder>
  <dest_folder>Trash</dest_folder>
</vsap>!);

ok(!$de->findvalue('/vsap/vsap[@type="error"]/message'));

# Quota test. 
## get quota
$> = $< = getpwnam($ACCT->userid);
system("dd count=55000 if=/dev/zero of=$homedir/foo1 bs=1024 >/dev/null 2>&1");
system('chown', $userid, "$homedir/foo1");

unless( -d '/skel' || $is_linux) {
    use Quota;
    my ($usage,undef,$quota) = Quota::query(Quota::getqcarg($homedir));
    my $remaining = ($quota - $usage);
    system("dd count=$remaining if=/dev/zero of=$homedir/foo2 bs=1024 >/dev/null 2>&1");
    system('chown', $userid, "$homedir/foo2");
}

$de = $t->xml_response(q!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
my $uid = $de->findvalue("/vsap/vsap[\@type='webmail:messages:list']/message[1]/uid");


$de = $t->xml_response(qq!<vsap type="webmail:messages:move">
  <uid>$uid</uid>
  <folder>INBOX</folder>
  <dest_folder>Trash</dest_folder>
</vsap>!);

is($de->findvalue("/vsap/vsap/code"),117);

END {
	$ACCT->delete();
	}
