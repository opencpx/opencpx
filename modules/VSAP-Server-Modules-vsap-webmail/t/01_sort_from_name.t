use Test::More tests => 14;
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

ok(ref($ACCT),"Account object is a reference");
ok($ACCT->exists,"Account existance");

# We need to become the user. This is for the sake of signature, where localhost will not work. 
my $sysuid = (getpwnam($ACCT->userid))[2];

local $> = $sysuid
  if ($>==0);

## constructor
my $wm = new VSAP::Server::Modules::vsap::webmail($USERNAME,$PASSWORD);
ok( ref($wm), "webmail object created" );
ok( ref($wm->{mc}), "mail::cclient object intenral to webmail object created.");
ok( UNIVERSAL::isa($wm->{mc}, 'Mail::Cclient'), "Internal mail::cclient is actually a Mail::Cclient reference" );

## send a message
ok($ACCT->send_email('test-emails/15.txt'), "send 1st test email");
sleep 1;
ok($ACCT->send_email('test-emails/16.txt'), "send 2nd test email");
sleep 1;
ok($ACCT->send_email('test-emails/17.txt'), "send 3rd test email");
sleep 1;
ok($ACCT->send_email('test-emails/18.txt'), "send 4th test email");
sleep 1;
ok($ACCT->send_email('test-emails/19.txt'), "send 5th test email");
sleep 1;
ok(1, "Waiting for delivery of emails");
sleep 7; 

$wm->folder_status('INBOX');
$msgs = $wm->messages_sort(from_name => 0);
is( "@$msgs", "1 2 5 3 4", "from name ordering is correct");

$msgs = $wm->messages_sort(from_name => 1);
is( "@$msgs", "4 3 5 2 1", "from_name ordering is correct");

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
