use Test::More tests => 108;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail') };

#########################

use VSAP::Server::Test::Account;
use Data::Dumper;

use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();
my $USERNAME = $ACCT->username;
my $PASSWORD = $ACCT->password;

if ($ENV{VST_PLATFORM} eq "VPS2" || $ENV{VST_PLATFORM} eq "LVPS2") { 
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable.$$";
    unlink '/etc/mail/virtusertable.db';
    rename "/usr/local/etc/procmailrc", "/usr/local/etc/procmailrc.$$";
}
ok( ref($ACCT) && $ACCT->exists, "Account exists" );

# We need to become the user. This is for the sake of signature, where localhost will not work. 
my $sysuid = (getpwnam($ACCT->userid))[2];

local $> = $sysuid
  if !$>;

## constructor
my $wm = new VSAP::Server::Modules::vsap::webmail($USERNAME, $PASSWORD);
ok( ref($wm) && ref($wm->{mc}) && UNIVERSAL::isa($wm->{mc}, 'Mail::Cclient'), "wm object ok" );

## folder list
is( keys %{$wm->folder_list}, 1, "Get folder listing" );
is( $wm->folder_list->{INBOX}, 1, "Inbox exists in folder listing" );

## folder status, no argument defaults to 'INBOX'
my $fs = $wm->folder_status("INBOX");
ok( $fs ) || diag $wm->log;
is( $fs->{messages}, 0, "0 messages in INBOX");
is( $fs->{recent}, 0, "0 recent messages in INBOX");
is( $fs->{unseen}, 0, "0 unseen messages in INBOX");

## folder status with 'INBOX' argument.
$fs = $wm->folder_status("INBOX");
ok( $fs ) || diag $wm->log;
is( $fs->{messages}, 0, "0 messages in INBOX");
is( $fs->{recent}, 0, "0 recent messages in INBOX");
is( $fs->{unseen}, 0, "0 unseen messages in INBOX");

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

########################################################################
##
## folder manipulation tests
##

## folder status again. Should have 5 messages now. 
$fs = $wm->folder_status;
is( $fs->{messages}, 5, "check for 5 messages in inbox");
is( $fs->{recent}, 5,  "check for 5 recent messages in inbox");
is( $fs->{unseen}, 5, "check for 5 unseen messages in inbox");
cmp_ok( $fs->{size}, '==', -s $ACCT->inboxpath, "Check to be sure that INBOX size returned matches size on disk");

## Should have 5 messages, with 0 recent. 
## The recent check fails on Linux, this has to do with the way
## dovecot resets the recent flag as opposed to uw-imap.  Right now 
## this isn't a large concern because we don't actually use this number
## that I can see.
$fs = $wm->folder_status;
is( $fs->{messages}, 5, "Check for 5 messages");
is( $fs->{unseen}, 5, "Check for 5 unseen messages");
SKIP: {
    skip "Test currently doesn't work on Linux", 1
      if $ENV{VST_PLATFORM} eq 'LVPS2' ;

	is( $fs->{recent}, 0, "Check for 0 recent, since last status check");
}

## Folder creation
ok( $wm->folder_create('Junk'), "Create Junk folder");
is( keys %{$wm->folder_list}, 2, "folder list contains two folders");
is( $wm->folder_list->{Junk}, 1, "junk folder exists");

## create it again
ok( ! $wm->folder_create('Junk'), 'no duplicate folders' );
is( keys %{$wm->folder_list}, 2, "still just two folders" );
is( $wm->folder_list->{Junk}, 1, "junk folder exists");

## create a folder with leading dot
SKIP: {
    skip "Dovecot does not support leading dots in folder names.", 3
      if $ENV{VST_PLATFORM} eq 'LVPS2' ;

	ok( $wm->folder_create('.horses'), 'folders w/ leading dot' );
	is( keys %{$wm->folder_list}, 3, "3 folders now" );
	is( $wm->folder_list->{'.horses'}, 1, "leading dot folder exists");
}

## remove our dot folder
$wm->folder_delete('.horses');
is( keys %{$wm->folder_list}, 2, "leading dot folder removal");
ok( ! exists $wm->folder_list->{'.horses'}, "leading dot folder no longer exists");

## create a new folder with a name including quotation marks
ok( $wm->folder_create('special"foldername'), 'folders w/ DQUOTE in name' );
is( keys %{$wm->folder_list}, 3,"3 folders present");
is( $wm->folder_list->{'special"foldername'}, 1, "DQuote folder name in list of folders");

## move some mail to it
$wm->messages_move("1", 'INBOX' => 'special"foldername', 'move 1st message in INBOX to special"foldername');

## tickle the real bug
ok( $wm->folder_open('special"foldername'), 'open special"foldername') || diag($wm->log);
ok( $wm->folder_status('special"foldername'), 'DQUOTE bug test' ) || diag($wm->log);
my $msgs = $wm->messages_sort('special"foldername');
is( "@$msgs", "1", 'folder contains UID 1' );

## move message back out to INBOX, will now be UID 6.
$wm->messages_move("1", 'special"foldername' => 'INBOX', 'Move message one back to INBOX');

## delete the folder with quotation marks in its name
$wm->folder_delete('special"foldername');
is( keys %{$wm->folder_list}, 2 );
ok( ! exists $wm->folder_list->{'special"foldername'} );

##
## BUG04851: writing to a non-writable folder
##
ok( $wm->folder_create('unwritable') );
is( keys %{$wm->folder_list}, 3 );
is( $wm->folder_list->{'unwritable'}, 1 );
chmod 0400, $ACCT->mailboxpath.'/unwritable';

## copy mail
ok( ! $wm->messages_copy("5", INBOX => 'unwritable') );
if ($is_linux)
{
	like( $wm->log, qr(Internal error)i, "not writable" );
} else {
	like( $wm->log, qr((?:failed|can't open))i, "not writable" );
}
undef $msgs;
$msgs = $wm->messages_sort('unwritable');
is( @$msgs, 0 );

chmod 0640, $ACCT->mailboxpath.'/unwritable';

##
## try a non-readable folder
##
ok( $wm->folder_create('unreadable'), "create unreadable folder" );
is( keys %{$wm->folder_list}, 4 );
is( $wm->folder_list->{'unreadable'}, 1 );
ok( $wm->messages_copy("5", INBOX => 'unreadable'), "setup unreadable folder" );
$msgs = $wm->messages_sort('unreadable');
is( "@$msgs", '1' );
$wm->folder_open();  ## divert attention away from unreadable folder

chmod 0000, $ACCT->mailboxpath.'/unreadable';

ok( ! $wm->messages_copy('1', unreadable => 'unwritable' ), "copy failed" );
if ($is_linux)
{
	like( $wm->log, qr(Internal error)i, "not readable" );
} else {
	like( $wm->log, qr(unable to open file)i, "not readable" );
}

## clean up
chmod 0640, $ACCT->mailboxpath.'/unreadable';
$wm->folder_delete('unreadable');
is( keys %{$wm->folder_list}, 3 );
ok( ! exists $wm->folder_list->{'unreadable'} );

$wm->folder_delete('unwritable');
is( keys %{$wm->folder_list}, 2 );
ok( ! exists $wm->folder_list->{'unwritable'} );

##
## test for bad chars
##
ok( ! $wm->folder_create('folder(name') );
like( $wm->log, qr(illegal characters), "illegal char" );

ok( ! $wm->folder_create('folder*name') );
like( $wm->log, qr(illegal characters), "illegal char" );

ok( ! $wm->folder_create('folder%name') );
like( $wm->log, qr(illegal characters), "illegal char" );

ok( ! $wm->folder_create('folder\name') );
like( $wm->log, qr(illegal characters), "illegal char" );

ok( ! $wm->folder_create('folder]name') );
like( $wm->log, qr(illegal characters), "illegal char" );

ok( ! $wm->folder_create("folder\0201name") );
like( $wm->log, qr(control characters), "control char" );

ok( $wm->folder_create("folder&-name") );
is( keys %{$wm->folder_list}, 3 );
$wm->folder_delete("folder&-name");
is( keys %{$wm->folder_list}, 2 );


##
## rename a folder
##
$wm->folder_rename('Junk', 'Garbage');
is( keys %{$wm->folder_list}, 2 );
is( $wm->folder_list->{Garbage}, 1 );
ok( ! exists $wm->folder_list->{Junk} );

##
## delete a folder
##
$wm->folder_delete('Garbage');
is( keys %{$wm->folder_list}, 1 );
ok( ! exists $wm->folder_list->{Garbage} );

##
## try a directory
##
my $fl = $wm->folder_list;
is( keys %$fl, 1 ); ## inbox

ok( $wm->directory_create("zzz") );
$fl = $wm->folder_list;
is( keys %$fl, 2 ); ## inbox and zzz
ok( exists $fl->{zzz} );

SKIP: {
    skip( "non-local mailbox tests", 4 )
      if $VSAP::Server::Modules::vsap::webmail::HOST eq '';

    $wm->folder_rename('zzz', 'Some Directory');
    $fl = $wm->folder_list;
    is( keys %$fl, 2 ); ## inbox and zzz
    ok( exists $fl->{'Some Directory'} );

    ## this should fail
    ok( ! $wm->folder_open('Some Directory') );
    ok( ! $wm->folder_status('Some Directory') );

    $wm->folder_delete('Some Directory');
}

########################################################################
##
## folder subscription tests
##
is( keys %{$wm->folder_list_subscribed}, 1, "subscribed folders == 1 (INBOX only)" );
ok( $wm->folder_create("QuuxFoo1"), "created test mail folder 'QuuxFoo1'" );
ok( $wm->folder_subscribe("QuuxFoo1"), "subscribed to test mail folder 'QuuxFoo1'" );
is( keys %{$wm->folder_list_subscribed}, 2, "subscribed folders == 2 (INBOX + QuuxFoo1)" );
is( $wm->folder_list_subscribed->{QuuxFoo1}, 1, "QuuxFoo folder listed in subscription list");
ok( ! $wm->folder_subscribe("QuuxFoo2"), "subscribe to non-existent folder fails" );
ok( $wm->folder_create("QuuxFoo2"), "created test mail folder 'QuuxFoo2'" );
ok( $wm->folder_subscribe("QuuxFoo2"), "subscribed to test mail folder 'QuuxFoo2'" );
ok( $wm->folder_create("QuuxFoo3"), "created test mail folder 'QuuxFoo3'" );
ok( $wm->folder_subscribe("QuuxFoo3"), "subscribed to test mail folder 'QuuxFoo3'" );
is( keys %{$wm->folder_list_subscribed}, 4, "subscribed folders == 4 (INBOX + 3)" );
ok( $wm->folder_unsubscribe("QuuxFoo2"), "unsubscribed to test mail folder 'QuuxFoo2'" );
is( keys %{$wm->folder_list_subscribed}, 3, "subscribed folders == 3 (INBOX + 2)" );
is( ! $wm->folder_list_subscribed->{QuuxFoo2}, 1, "QuuxFoo2 folder not listed in subscription list");

## delete a folder should unsubscribe
$wm->folder_delete('QuuxFoo1');
is( keys %{$wm->folder_list_subscribed}, 2, "subscribed folders == 2 (INBOX + 1)" );
is( ! $wm->folder_list_subscribed->{QuuxFoo1}, 1, "QuuxFoo1 folder not listed in subscription list");

## try and subscribe to the same folder twice
SKIP: {
    skip "Dovecot does not throw an error when attempting to subscribe to a folder already subscribed to.", 1
      if $ENV{VST_PLATFORM} eq 'LVPS2' ;

        ok( ! $wm->folder_subscribe("QuuxFoo3"), "re-subscribe to test mail folder 'QuuxFoo3' failed" );
}

is( keys %{$wm->folder_list_subscribed}, 2, "subscribed folders == 2 (INBOX + 1)" );

########################################################################

END {
    if ($ENV{VST_PLATFORM} eq "VPS2" || $ENV{VST_PLATFORM} eq "LVPS2") { 
        rename "/etc/mail/virtusertable.$$", '/etc/mail/virtusertable'
            if -e "/etc/mail/virtusertable.$$";
        chdir('/etc/mail');
        system('make');
        rename "/usr/local/etc/procmailrc.$$", "/usr/local/etc/procmailrc"
            if "/usr/local/etc/procmailrc.$$";
    } 
}
