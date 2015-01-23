use Test::More tests => 66;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail') };

#########################

use VSAP::Server::Test::Account;
use Data::Dumper;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();
my $USERNAME = $ACCT->username;
my $PASSWORD = $ACCT->password;

use POSIX('uname');
my $is_linux =((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

if ($ENV{VST_PLATFORM} =~ /VPS2/) { 
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable.$$";
    unlink '/etc/mail/virtusertable.db';
    rename "/usr/local/etc/procmailrc", "/usr/local/etc/procmailrc.$$";
}

my $INBOX = ($ENV{VST_PLATFORM} eq "VPS2" || $ENV{VST_PLATFORM} eq "LVPS2") ? "/var/mail/$USERNAME"
                : "/usr/home/" . $ACCT->userid . "/users/$USERNAME/mail/INBOX";
my $INBOX_new = ($ENV{VST_PLATFORM} eq "VPS2" || $ENV{VST_PLATFORM} eq "LVPS2") ? "/var/mail/$USERNAME.$$"
                : "/usr/home/" . $ACCT->userid . "/users/$USERNAME/INBOX.$$";

ok(ref($ACCT),"Account object is a reference");
ok($ACCT->exists,"Account existance");

# We need to become the user. This is for the sake of signature, where localhost will not work. 
my $sysuid = (getpwnam($ACCT->userid))[2];

## constructor with unselectable INBOX
rename $INBOX, $INBOX_new;
system("ln", "-s", "/dev/null", $INBOX);
ok(! -f $INBOX);

{
local $> = $sysuid if ($> == 0);
my $wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,$PASSWORD);
ok( ref($wm), "webmail object created (unselectable INBOX)" );
ok( ref($wm->{mc}), "mail::cclient object internal to webmail object created (unselectable INBOX).");
## folder list with unselectable INBOX
is( keys %{$wm->folder_list}, 1, "Get folder listing (unselectable INBOX)" );
is( $wm->folder_list->{INBOX}, 1, "Inbox does not exist in folder listing" );
}

unlink $INBOX;
rename $INBOX_new, $INBOX;
ok(-f $INBOX);

local $> = $sysuid
  if ($> == 0);

## constructor with valid INBOX
my $wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,$PASSWORD);
ok( ref($wm), "webmail object created" );
ok( ref($wm->{mc}), "mail::cclient object internal to webmail object created.");
ok( UNIVERSAL::isa($wm->{mc}, 'Mail::Cclient'), "Internal mail::cclient is actually a Mail::Cclient reference" );

##
## MESSAGES
##

## send a message
ok($ACCT->send_email('test-emails/01.txt'), "send 1st test email");
sleep 1;
ok($ACCT->send_email('test-emails/02.txt'), "send 2nd test email");
sleep 1;
ok($ACCT->send_email('test-emails/03.txt'), "send 3rd test email");
sleep 1;
ok($ACCT->send_email('test-emails/04.txt'), "send 4th test email");
sleep 1;
ok($ACCT->send_email('test-emails/05.txt'), "send 5th test email");
sleep 1;
ok(1, "Waiting for delivery of emails");
sleep 5;

## move #1 to trash, then back
$wm->folder_create('Trash');
$wm->messages_move("1", INBOX => 'Trash');
$wm->messages_move("1", Trash => 'INBOX');
$wm->folder_delete('Trash');

## list messages

# Sort by date ascending order which is the default.
$msgs = $wm->messages_sort;
is( "@$msgs", "5 4 3 2 6", "sorting" );

# Sort by date in descending order. 
$msgs = $wm->messages_sort( date => 0);
is( "@$msgs", "6 2 3 4 5", "sorting by date");

$msgs = $wm->messages_sort(subject => 1);
is( "@$msgs", "5 4 3 2 6", "sorting by subject" );

$msgs = $wm->messages_sort(from => 0);
is( "@$msgs", "2 4 6 3 5", "sorting by from" );

$msgs = $wm->messages_sort(from => 1);
is( "@$msgs", "5 3 6 4 2", "descending from sort" );

$msgs = $wm->messages_sort(subject => 0, from => 0);
is( "@$msgs", "6 2 3 4 5", "subject-from sort" );

$msgs = $wm->messages_sort(subject => 0, from => 1);
is( "@$msgs", "6 2 3 4 5", "subject-from descending sort" );

## change a flag on this message
my $msg = $wm->message('INBOX', 3, 1);
ok( grep {'\Valid'} @{$msg->{flags}}, "get flag" );

## check again to make sure '\Seen' is not set
$msg = $wm->message('INBOX', 3, 1);
ok( grep {'\Valid'} @{$msg->{flags}}, "get flag" );

## message information
$msg = $wm->message('INBOX', 6, 1);
is( $msg->{subject}, "test 1" );
is( $msg->{uid}, 6 );
is( $msg->{to}->[0]->{mailbox}, $USERNAME);

$msg = $wm->message('INBOX', 3, 1);
is( $msg->{subject}, "test 3" );
is( $msg->{uid}, 3 );
is( $msg->{flags}->[0], '\Valid' );

## change a flag on this message
$wm->messages_flag('INBOX', '3', '\Deleted');
$msg = $wm->message('INBOX', 3, 1);
ok( grep {'\Deleted \Valid'} @{$msg->{flags}}, "new flags set" );

## create another folder and move messages to it
$wm->folder_create('Trash');
is( keys %{$wm->folder_list}, 2 );
is( $wm->folder_list->{Trash}, 1 );

## move some messages to Trash
if ($is_linux)
{
	$wm->messages_move("3,6", 'INBOX' => 'Trash');
} else {
	$wm->messages_move("6,3", 'INBOX' => 'Trash');
}

$msgs = $wm->messages_sort;
is( "@$msgs", "5 4 2", "sorting" );

$msgs = $wm->messages_sort('Trash');
is( "@$msgs", "1 2", "sorting" );

## delete one
$wm->messages_delete('INBOX', "2");
$msgs = $wm->messages_sort;
is( "@$msgs", "5 4", "sorting" );

## send some more
ok($ACCT->send_email('test-emails/04.txt'));
sleep 3;

## delete several
$wm->messages_delete('INBOX', '4,5');
$msgs = $wm->messages_sort;
is( "@$msgs", "7", "after deleting" );

## send a tab message
ok($ACCT->send_email('test-emails/06.txt'));
sleep 3;

$msgs = $wm->messages_sort;
is( "@$msgs", "8 7", "sorting" );
$msg = $wm->message('INBOX', 8);
if ($is_linux)
{
	is( $msg->{subject}, "test\twith a tab", 'dovecot preserves tabs in subject');
} else {
	is( $msg->{subject}, "test with a tab", "tab in subject, uw-imap strips tabs in subject" ); ## looks like IMAP strips the header whitespace
}
like( $msg->{body}->{'text/plain'}->{text}, qr(This is testing\twith a tab character.*Bye)s );

##
## save a new message
##
$wm->folder_create('Junk');
is( $wm->folder_list->{Junk}, 1, "Junk folder created" );

my $ret = $wm->message_save('Junk', <<'_MSG_');
Date: Fri, 26 Jun 2004 17:30:25 GMT
From: Charlie Root <root@thursday.securesites.net>
To: joe@localhost
Subject: Joe Rocks!

Your good friends in system administration wish you a happy birthday.

Charlie
_MSG_

ok( $ret );
$msgs = $wm->messages_sort('Junk');
is( "@$msgs", "1" );

$msg = $wm->message('Junk', 1, 1);
is( $msg->{subject}, "Joe Rocks!", "saved message to Junk" );

##
## read a message
##
$msg = $wm->message('Junk', 1);
is( $msg->{date}, 'Fri, 26 Jun 2004 17:30:25 GMT', "Junk header read" );
like( $msg->{body}->{'text/plain'}->{text}, qr(good friends in system administration), "Junk message read" );

##
## try to crash Mail::Cclient
## this test used to crash Mail::Cclient::fetch_structure if the
## mailbox had not been previously opened. The opened mailbox from
## 'new' is not the same as a true 'open'
##
$msgs = $wm->messages_sort('INBOX');
undef $wm;
$wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,$PASSWORD);
ok( ref($wm) && ref($wm->{mc}), "object ok" );
ok( $msg = $wm->message('INBOX', $msgs->[0]), "death trap" );  ## this would trigger the crash


##
## test for cc and bcc recipients
##

## add message to drafts folder (doesnt work to INBOX)

$ACCT->append_email_to_spool('test-emails/13.txt', $ACCT->mailboxpath."/Drafts");

$msgs = $wm->messages_sort('Drafts');
for my $uid ( @$msgs ) {
    $msg = $wm->message('Drafts', $uid);
    next unless $msg->{subject};
    last if $msg->{subject} =~ /cc and bcc recipients/i;
}
my $cc_addr = $msg->{cc};
my $cc_mailbox = $cc_addr->[0]->{mailbox};
is( $cc_mailbox, 'joecc' );
my $bcc_addr = $msg->{bcc};
my $bcc_mailbox = $bcc_addr->[0]->{mailbox};
is( $bcc_mailbox, 'joebcc' );

##
## test for bad date header
##
$inbox = $ACCT->inboxpath;
$ACCT->append_email_to_spool('test-emails/20.txt', $inbox);
like( `egrep '^Date: ' $inbox`, qr#\xBF\xC0\xC8\xC4#, "raw octets in date header" );
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{from}->[0]->{mailbox} eq '35sesf45w6c3';
}
like( $msg->{body}->{'text/html'}->{text}, qr(wish to receive this), "body found" );
like( $msg->{date}, qr(\xBF\xC0\xC8\xC4), "date header" );

$ACCT->append_email_to_spool('test-emails/21.txt', $inbox);
$msgs = $wm->messages_sort('INBOX');
my $a_uid = 0;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    if( $msg->{subject} eq 'gb2312 test' ) {
	$a_uid = $uid;
	last;
    }
}

ok( $a_uid, "found our uid" );
is( $msg->{charset}, 'GB2312', "encoding found" );

$ACCT->append_email_to_spool('test-emails/22.txt', $inbox);
$msgs = $wm->messages_sort('INBOX');
$a_uid = 0;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    if( $msg->{to}->[0]->{mailbox} eq 'hsw' && $msg->{to}->[0]->{host} eq 'best.com' ) {
        $a_uid = $uid;
        last;
    }
}
ok( $a_uid, "found our uid" );
like( $msg->{charset}, qr{US-ASCII}i, "encoding found" );

$ACCT->append_email_to_spool('test-emails/29.txt', $inbox);
$msgs = $wm->messages_sort('INBOX');
$a_uid = 0;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    if( $msg->{subject} =~ /\?gb2312\?/ ) {
	$a_uid = $uid;
	last;
    }
}

ok( $a_uid, "found our uid" );
like( $msg->{body}->{'text/plain'}->{charset}, qr{gb2312}i, "encoding found for multipart/alternative" );

eval { 
	$wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,'invalid');
	$wm->folder_list;
};

ok(!$@, "folder list on invalid password doesn't cause die")
	|| diag $@;

eval { 
	$wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,'invalid');
	$wm->folder_create('bleh');
};

ok(!$@, "folder create on invalid password doesn't cause die")
	|| diag $@;
	

END {
    if ($ENV{VST_PLATFORM} eq "VPS2" || $ENV{VST_PLATFORM} eq "LVPS2") { 
        rename "/etc/mail/virtusertable.$$", '/etc/mail/virtusertable'
            if -e "/etc/mail/virtusertable.$$";
        chdir('/etc/mail');
        system('make all');
        rename "/usr/local/etc/procmailrc.$$", "/usr/local/etc/procmailrc"
            if "/usr/local/etc/procmailrc.$$";
    } 
}
