use Test::More tests => 58;
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

## FIXME: find out why:
## doing folder_status is necessary for messages_sort to work

##
## body and attachment tests
##
## send another message
ok($acct->send_email('test-emails/07.txt'), "send test 07");
sleep 1;
ok($acct->send_email('test-emails/08.txt'), "send test 08");
sleep 1;
ok($acct->send_email('test-emails/09.txt'), "send test 09");
sleep 1; 
ok($acct->send_email('test-emails/10.txt'), "send test 10 - worm sent");
sleep 1;
ok($acct->send_email('test-emails/11.txt'), "sending spreadsheet attachments");
sleep 1;
ok($acct->send_email('test-emails/12.txt'), "sending pgp signed message (12)");
sleep 1;
ok($acct->send_email('test-emails/30.txt'), "sending message from Tbird with attachment name in double byte characters (30)");
sleep 1;
ok($acct->send_email('test-emails/31.txt'), "sending HTML message without Disposition header for image attachment");
sleep 3;

$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /gana dinero/i;
}
like( $msg->{body}->{'text/plain'}->{text}, qr(Mientras mi PC trabaja yo gano dinero)i, "text/plain part" );
like( $msg->{body}->{'text/html'}->{text},  qr(Mientras mi PC trabaja yo gano dinero)i, "text/html part" );
is( @{$msg->{attachments}}, 1, "attachments found in multipart/related" );

for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /Your website/i;
}

like( $msg->{body}->{'text/html'}->{text}, qr(only <FONT color=#ff0000><B>guaranteed), "html found" );
is( @{$msg->{attachments}}, 0 );

##
## save attachment
##
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /gana dinero/i;
}
like( $msg->{body}->{'text/plain'}->{text}, qr(Mientras mi PC trabaja yo gano dinero)i );
is( @{$msg->{attachments}}, 1 );

my $tmpFilePath;
$attach_id = $msg->{attachments}->[0]->{attach_id};
($filename, $tmpFilePath, $mime) = $wm->message_attachment('INBOX', $msg->{uid}, $attach_id, "/tmp");
is( $filename, "nelson_Chica_saltando02.jpg" );
is( $mime, 'image/jpeg' );
ok( -s "/tmp/$tmpFilePath", "attachment saved" );
unlink "/tmp/$tmpFilePath";

##
## Test for inline image without Disposition header.
##
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /attachment without disposition/i;
}
is( @{$msg->{attachments}}, 1 );

$attach_id = $msg->{attachments}->[0]->{attach_id};
($filename, $tmpFilePath, $mime) = $wm->message_attachment('INBOX', $msg->{uid}, $attach_id, "/tmp");
is( $filename, "image-jpeg", "Testing inline image without disposition header." );

##
## Check filename for attachment with double byte character filename from Tbird
## according to RFC2231.
##
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{from}->[0]->{mailbox} =~ /cmkeung/i;
}
is( @{$msg->{attachments}}, 1 );

$tmpFilePath;
$attach_id = $msg->{attachments}->[0]->{attach_id};
($filename, $tmpFilePath, $mime) = $wm->message_attachment('INBOX', $msg->{uid}, $attach_id, "/tmp");
is( $filename, "2M中文字形");

##
## what does a worm look like?
##

$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /Re: A!p\$ghsa/;
}
like( $msg->{subject}, qr/Re: A!p\$ghsa/ );
is( @{$msg->{attachments}}, 1 );

like( $msg->{attachments}->[0]->{name}, qr(^important\.txt *\.exe$) );
is( $msg->{attachments}->[0]->{discrete}, 'application' );
is( $msg->{attachments}->[0]->{composite}, 'octet-stream' );
is( $msg->{attachments}->[0]->{encoding}, 'base64' );
is( $msg->{attachments}->[0]->{size}, 2780, "attachment size" );
my $attach_id = $msg->{attachments}->[0]->{attach_id};

($filename, $tmpFilePath, $mime) = $wm->message_attachment('INBOX', $msg->{uid}, $attach_id, "/tmp");
like( $filename, qr(^important\.txt\s*\.exe$), "attachment filename" );
is( $mime, 'application/octet-stream', "attachment mime-type" );
ok( -f "/tmp/$tmpFilePath", "attachment exists" );
ok( -s "/tmp/$tmpFilePath", "attachment saved" );
unlink "/tmp/$tmpFilePath";

##
## rigorous attachment tests
##

$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /spreadsheets/i;
}
like( $msg->{subject}, qr(spreadsheets) );
is( @{$msg->{attachments}}, 6 );
like( $msg->{body}->{'text/plain'}->{text}, qr(some spreadsheets\. Have a nice life\.) );
is( $msg->{attachments}->[4]->{name}, '040104.ss' );
is( $msg->{attachments}->[4]->{attach_id}, 6, "attachment id" );  ## attach_id has index base 1

##
## PGP signed message
##


##
$wm->folder_status;  ## FIXME: why do I have to do this? prolly folder_open is called correctly
my $msgs = $wm->messages_sort('INBOX');    ## and here folder_open isn't called correctly
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /sub-subfolders from/i;
}
like( $msg->{subject}, qr(create sub-subfolders from) );
like( $msg->{body}->{'text/plain'}->{text},
      qr(It does not work here.*procmail mailing list)s,
      "PGP signed message" );

##
## multipart/mixed w/ multipart/related w/ multipart/alternative w/ text/plain & text/html
##
ok($acct->send_email('test-emails/24.txt'), "sending multipart/mixed, related, alternative");
mail_pause();

undef $msg;
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /Organizational Announcement/;
}

like( $msg->{body}->{'text/plain'}->{text}, 
      qr(Dear Verio Colleagues,.*future endeavors.*Verio-All mailing list)s,
      "all plain text body" );

## grab one of the attachments
is( @{$msg->{attachments}}, 5 );
$attach_id = $msg->{attachments}->[0]->{attach_id};
($filename, $tmpFilePath, $mime) = $wm->message_attachment('INBOX', $msg->{uid}, $attach_id, '/tmp');
is( $filename, "image001.gif", "image name" );
is( $mime, "image/gif", "image mime type" );

##
## Test html message which includes a Disposition header in the text/html part.
##
ok($acct->send_email('test-emails/32.txt'), "sending alternative with a Disposition header in the text/html part.");
mail_pause();

undef $msg;
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /FL Residents/;
}

ok( $msg->{body}->{'text/html'}->{text}, "text/html with a Disposition header for the text/html part." );

##
## test for rfc822 multipart/report
##
ok( $acct->append_email_to_spool('test-emails/25.txt', $acct->inboxpath), "sending rfc822 message" );
mail_pause();

undef $msg;
$msgs = $wm->messages_sort('INBOX');
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid);
    last if $msg->{subject} =~ /Delivery Status Notification/;
}

like( $msg->{body}->{'text/plain'}->{text}, 
      qr(This is an automatically.*Delivery to the following recipients.*The requested abuse list)s,
      "rfc822 message body" );

##
## outlook messages
##

$acct->send_email('test-emails/23.txt');
mail_pause();
$msgs = $wm->messages_sort('INBOX');
$a_uid = 0;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid, 1);  ## header only
    if( $msg->{subject} eq 'This is a test html email.' ) {
        $a_uid = $uid;
        last;
    }
}
ok( $a_uid, "found our message" );
is( $msg->{numattachments}, 0, "zero attachments" );


##
## inline attachment count
##

$acct->send_email('test-emails/mhtml-1.txt');
mail_pause();

undef $msg;
$msgs = $wm->messages_sort('INBOX');
$a_uid = 0;
for my $uid ( @$msgs ) {
    $msg = $wm->message('INBOX', $uid, 1);
    if( $msg->{subject} eq 'Test message no. 1' ) {
        $a_uid = $uid;
        last;
    }
}
ok( $a_uid, "found message" );
is( $msg->{numattachments}, 0, "no true attachments" );
is( scalar( @{ $msg->{attachments} } ), 2, "two inline attachments" );

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
