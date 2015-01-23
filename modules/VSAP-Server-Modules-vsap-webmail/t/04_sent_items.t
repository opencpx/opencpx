use Test::More tests => 18;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail') };

#########################

use VSAP::Server::Test::Account;
use Data::Dumper;

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

## make some messages in INBOX
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
sleep 3;

##
## BUG05084: Messages in Sent Items folder can not be deleted
##
ok( $wm->folder_create('Sent Items'), 'create "Sent Items" folder' );
is( keys %{$wm->folder_list}, 2 );
is( $wm->folder_list->{'Sent Items'}, 1 );

## copy mail to it
$wm->messages_copy("5", INBOX => 'Sent Items');
$msgs = $wm->messages_sort('Sent Items');
is( "@$msgs", '1' );

## (test INBOX as side effect) Sort by size. Should be in order of sent since each email is bigger by 100 chars. 
$msgs = $wm->messages_sort('INBOX');
is( "@$msgs", "5 4 3 2 1" );

## compare the messages
{
    my $msg1 = $wm->message('INBOX', 5, 1);
    my $msg2 = $wm->message('Sent Items', 1, 1);
    is( $msg1->{subject} => $msg2->{subject}, "subjects match" );
}

## delete the message
$wm->messages_delete('Sent Items', '1');
$msgs = $wm->messages_sort('Sent Items');
is( "@$msgs", "", "messagse deleted from 'Sent Items'" );

## delete folder
$wm->folder_delete('Sent Items');
is( keys %{$wm->folder_list}, 1 );
ok( ! exists $wm->folder_list->{'Sent Items'} );


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
