use Test::More tests => 23;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail') };

use VSAP::Server::Test::Account;
use Data::Dumper;

my $MAIL_PAUSE_TIME = 5;

my $acct = VSAP::Server::Test::Account->create();
ok( $acct->exists, "account created" );

if( $ENV{VST_PLATFORM} eq 'VPS2'  || $ENV{VST_PLATFORM} eq "LVPS2") {
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable.$$";
    unlink '/etc/mail/virtusertable.db';
    rename "/usr/local/etc/procmailrc", "/usr/local/etc/procmailrc.$$";
}
local $> = getpwnam($acct->userid) if $> == 0;
    
my $wm = new VSAP::Server::Modules::vsap::webmail($acct->username, $acct->password);
ok( ref($wm) && ref($wm->{mc}) && UNIVERSAL::isa($wm->{mc}, 'Mail::Cclient'), "webmail object created" );
is( $wm->folder_list->{INBOX}, 1, "Inbox exists in folder listing" );

##
## save a raw utf-8 message
##
$wm->folder_create('Boing');
is( $wm->folder_list->{Boing}, 1, "folder created" );

my $utf8_msg = <<_MSG_;
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=utf-8; format=flowed
MIME-Version: 1.0
Date: Fri, 26 Jun 2004 17:30:25 GMT
From: Charlie Root <root\@thursday.securesites.net>
To: joe\@localhost
Subject: Joe sends his love.

This body has a \x{c3}\x{b8} in it.

Bye.
_MSG_

$ret = $wm->message_save('Boing', $utf8_msg);
ok( $ret );

$msg = $wm->message('Boing', 1, 0);
is( $msg->{subject}, "Joe sends his love.", "message found" );
like( $msg->{body}->{'text/plain'}->{text}, qr(This body has a \x{c3}\x{b8} in it), "utf-8 in body" );
is( $msg->{body}->{'text/plain'}->{charset}, 'utf-8', "utf-8 charset found" );

##
## a crashme test: 14.txt contains high-ascii characters in headers and body
##
ok($acct->send_email('test-emails/14.txt'), "sending high-ascii headers/body message (14)");
sleep 3;

my $inbox = $acct->inboxpath;
## 0xCA = e+circumflex; 0xEE = i+circumflex; 0xE4 = a+umlaut
like( `grep '^2. ' $inbox`, qr#\xca\xee\xe4#, "raw bytes in message" );

$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{from}->[0]->{host} eq 'dsnov.ru';
}
like( $msg->{body}->{'text/plain'}->{text}, qr(www\.vinalco\.ru)i, "crashme message 14 received");
like( $msg->{body}->{'text/plain'}->{text}, qr#\xca\xee\xe4#, "raw bytes preserved" );


##
## colon in 'From:' name
##
ok($acct->send_email('test-emails/27.txt'), "a from name w/ colon (27)" );
mail_pause();

##
## parsing bogus 'From' header (colon is illegal unless quoted)
##
$wm->folder_status;    ## FIXME: why do I have to do this? prolly folder_open is called correctly

my $msgs = $wm->messages_sort('INBOX');
my $msg = undef;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} eq 'nice frog';
}
is( $msg->{subject}, 'nice frog', "message found" );
is( $msg->{from}->[0]->{personal}, 'Hi:There', "from personal found" );
is( $msg->{from}->[0]->{mailbox},  'scott', 'from mailbox found' );
is( $msg->{from}->[0]->{host},     'perlcode.com', "from host found" );

##
## bad From encoding
##
ok($acct->send_email('test-emails/26.txt'), "bad from encoding mail (26)");
mail_pause();

##
$msgs = $wm->messages_sort('INBOX');    ## and here folder_open isn't called correctly
$msg  = undef;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} eq q!=?GB2312?B?08PO3s/fveK+9sT6tcTX6c34us284L/YxNHM4g==?=!;
}
is( $msg->{subject}, q(=?GB2312?B?08PO3s/fveK+9sT6tcTX6c34us284L/YxNHM4g==?=), "message found" );
like( $msg->{from}->[0]->{personal}, qr(ÃÀ¤H_CoCo), "got from header" );
is( $msg->{from}->[0]->{mailbox}, q(fczuqv), "mailbox name found" );
is( $msg->{from}->[0]->{host},    q(mail2000.com.tw), "hostname found" );

exit;

## wait no longer than necessary or $MAIL_PAUSE_TIME (whichever comes first)
sub mail_pause {
    my $sent_time  = time;
    my $mtime_orig = (stat($acct->inboxpath))[9];
    do { sleep 1 } while( time <= ($sent_time + $MAIL_PAUSE_TIME) &&
                          $mtime_orig == (stat($acct->inboxpath))[9] );
}

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
