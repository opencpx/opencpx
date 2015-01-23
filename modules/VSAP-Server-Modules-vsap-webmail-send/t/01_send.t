use Test::More tests => 47;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::send') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;
use VSAP::Server::Base;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 5;

# Versions of perl 5.8.7 and newer differetiate between utf-8 and strict utf-8.
my $utfString = "utf-8-strict";
if ($] < 5.008007)
{
    $utfString = "utf-8";
}

my $egrep_cmd = `which egrep`;
chomp($egrep_cmd);
## set up a user
my $ACCT = VSAP::Server::Test::Account->create();
ok($ACCT->exists, "the account exists.");
my $vsap = $ACCT->create_vsap(['vsap::webmail',
			       'vsap::webmail::send', 
			       'vsap::webmail::options',
			       'vsap::webmail::folders',
			       'vsap::webmail::messages',]);

my $t = $vsap->client( { acct => $ACCT});

ok(ref($t),"obtained a vsap client object.");

my $email = $ACCT->emailaddress;
my $msgs = 0;

my $bad_email = $email;
$bad_email =~ (s/@/@@@/g);

my $de = $t->xml_response(qq!<vsap type="webmail:options:save"><webmail_options><from_name>Joseph T. Foo</from_name></webmail_options></vsap>!);
my $nl = $de->find("/vsap/vsap[\@type='webmail:options:save']/status");
is ($nl->string_value, "ok","able to set from_name in options") || print STDERR $de->toString();

$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:options:load']/webmail_options/from_name");
is($nl->string_value, "Joseph T. Foo","from name was correctly set");

##  <vsap type="webmail:send">
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Cc></Cc><Subject>testing</Subject><Text>This is a test.</Text></vsap>!);
$msgs++;
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/status");
is ($nl->string_value, "ok","send a message using the module.")
    || print STDERR $de->toString();

## give the mail some time for delivery
mail_pause();

## should now show the mail we just received
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value, '==', -s $ACCT->inboxpath, "size returned matches size on disk") || diag($de->toString);

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "The number of messages is $msgs" ) || diag $de->toString ;

use encoding 'utf8';
## send a utf-8 subject message: BUG05618
my $utf8sub = "男無頼庵";
$de = '';
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>$utf8sub</Subject><Text>This message has a utf-8 encoded subject.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
# diag($de->toString);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(Subject: =\?$utfString\?B\?55S354Sh6aC85bq1\?=), "utf-8 mime encoded subject")
    || print STDERR $de->toString();
mail_pause();

## send a utf-8 subject message: BUG05618
$utf8sub = "男無頼庵";
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>$utf8sub</Subject><Text>This message has a utf-8 encoded subject.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
#diag($de->toString);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(Subject: =\?$utfString\?B\?55S354Sh6aC85bq1\?=), "utf-8 mime encoded subject")
    || print STDERR $de->toString();
mail_pause();

## another utf-8  - BUG12684
$utf8sub = "lamó lamó niño, lloró";
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>$utf8sub</Subject><Text>This message has a utf-8 encoded subject.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
#diag($de->toString);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(Subject: =\?utf-8\?B\?bGFtw7MgbGFtw7MgbmnDsW8sIGxsb3LDsw==\?=), "another utf-8 mime encoded subject")
    || print STDERR $de->toString();
mail_pause();

no encoding;

## test for saving to drafts folder - this just returns a copy of the
## fully formatted email message (in <email_msg>) without sending to
## any folder
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text><SaveDraft>1</SaveDraft></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, "/This is a test./", "email_msg contains the message.")
    || print STDERR $de->toString();

## scottw: Quotes are required for RFC 822
like($nl->string_value, qr(From: "Joseph T. Foo" <$email>), "the from address contains the from name from options.");

## make sure our quote-fixer works
$de = $t->xml_response(qq!<vsap type="webmail:send"><From>Joe T. Foo &#060;$email&#062;</From><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text><SaveDraft>1</SaveDraft></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(From: "Joe T. Foo" <$email>), "quote fixer");

## Set the from_name to contain quotes. 
$de = $t->xml_response(qq!<vsap type="webmail:options:save"><webmail_options><from_name>"Joseph T. Foo"</from_name></webmail_options></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:options:save']/status");
is ($nl->string_value, "ok","able to set from_name in options") || print STDERR $de->toString();

## Confirm that we dont have two quotes in the From.. 
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text><SaveDraft>1</SaveDraft></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(From: "Joseph T. Foo" <$email>), "quote fixer with from_name contains quotes");

# Set the full name back to nothing. 
$de = $t->xml_response(qq!<vsap type="webmail:options:save"><webmail_options><from_name/></webmail_options></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:options:save']/status");
is ($nl->string_value, "ok","able to set from_name back to nothing.") 
	|| print STDERR $de->toString();

$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text><SaveDraft>1</SaveDraft></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, "/From: $email/", "email_msg contains just email address, no personal name.");

##
## test for saving a copy to Sent Items - this just returns a copy of
## the fully formatted email message (in <email_msg>)
##
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;

## give the mail some time for delivery
mail_pause();
#sleep 5;

## should now show the mail we just received
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/status");
is ($nl->string_value, "ok","status was 'ok' on mail sent");

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");

like($nl->string_value, "/This is a test./", "email_msg contains the correct message.")
    || print STDERR $de->toString();

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value,'==', -s $ACCT->inboxpath, "size of inbox matches size on disk");

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "number of messages in INBOX is $msgs" );

##
## test for a utf-8 message in Sent Items (BUG04188)
##
use encoding 'utf8';
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>utf-8 body 1</Subject><Text>This is a test with some Unicode in the body: 男無頼庵</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
mail_pause();
no encoding;

## should now show the mail we just received
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/status");
is ($nl->string_value, "ok","status was 'ok' on mail sent");

SKIP: {
	skip "Need to fix this test for Linux", 3
		if $ENV{VST_PLATFORM} eq "LVPS2";

## now save the output into Sent Items
my $message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
$message = VSAP::Server::Base::xml_escape($message);
$de = $t->xml_response(qq!<vsap type="webmail:messages:save"><folder>Sent Items</folder><message>$message</message></vsap>!);

## check inbox
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "number of messages in INBOX is $msgs" );
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
my $msgid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="utf-8 body 1"]/uid');
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$msgid</uid></vsap>!);
my $unibody = $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body');
like( $unibody, qr(\x{7537}\x{7121}\x{983c}\x{5eb5}), 'unicode body (INBOX)' );

## check Sent Items
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
$msgid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="utf-8 body 1"]/uid');

## read the messages from Sent Items
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>Sent Items</folder><uid>$msgid</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), $unibody, "unicode body (Sent Items)");

} # End of SKIP

##
## test for including a bad email address
##
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$bad_email</To><Subject>testing</Subject><Text>This is a test.</Text></vsap>!);

## should now find errors for the invalid email address
$nl = $de->find("/vsap/vsap[\@type='error']/code");
is ($nl->string_value, "101", "correct error code for bad email address reported.") 
	|| diag $de->toString;

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
is (length($nl->string_value), 0, "length of email address returned is 0") 
	|| diag $de->toString;

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value,'==', -s $ACCT->inboxpath, "size of INBOX matches size on disk");

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "the number of messages in this is still $msgs") 
	|| diag $de->toString();

## test for save draft and no body in email
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text></Text><SaveDraft>1</SaveDraft></vsap>!);

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(Subject: testing\W*$), "email_msg contains no body");

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value,'==',-s $ACCT->inboxpath, "size of INBOX matches size on disk")
	|| diag $de->toString;

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "number of messages in inbox is $msgs" )
	|| diag $de->toString();

## test for save draft and no body/subject/recipient in email
$de = $t->xml_response(q!<vsap type="webmail:send"><SaveDraft>1</SaveDraft></vsap>!)
	|| diag $de->toString();

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(From: $email\W*$), "email_msg contains no body/subject/recipient");

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!) || diag $de->toString;
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size");
cmp_ok( $nl->string_value,'==',-s $ACCT->inboxpath, "size of INBOX matches size on disk") 
	|| diag $de->toString;

$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "number of messages is still $msgs") 
	|| diag $de->toString;

##
## send a message with unknown encoding
##
##  <Subject>just a test with ø in it</Subject>
##  <Text>this message has a ø inside it.</Text>
$de = $t->xml_response(qq!<vsap type="webmail:send">
  <To>$email</To>
  <Subject>just a test with o-slash in it</Subject>
  <Text>this message has a &#xF8; inside it.</Text>
  <SaveOut>1</SaveOut>
</vsap>!);
mail_pause();
$message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
$message =~ s/\r/&#013;/g;
$message =~ s/\n/&#010;/g;
like( $message, qr(message has a \x{c3}\x{b8} inside), 'message received' );
$msgs++;

$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages"), $msgs, "number of messages in INBOX is $msgs" );

## save messages to Sent Items
$de = $t->xml_response(qq!<vsap type="webmail:messages:save"><folder>Sent Items</folder><message>$message</message></vsap>!);

## check message
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
$msgid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="just a test with o-slash in it"]/uid');

## read the messages from Sent Items
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>Sent Items</folder><uid>$msgid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(message has a \x{00f8} inside), 'message saved to Sent Items properly encoded' );

use encoding 'utf8';
##
## send a message with encoded cc header
##
$de = $t->xml_response(qq~<vsap type="webmail:send">
  <To>$email</To>
  <Cc>"Scøtt Wiersdorf" &#060;$email&#062;</Cc>
  <Subject>A nice cc test</Subject>
  <Text>Tabasco sauce rules the universe!</Text>
  <SaveOut>1</SaveOut>
</vsap>~);
mail_pause();
no encoding;


$message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
like( $message, qr(\QCc: "=?$utfString?B?U2PDuHR0IFdpZXJzZG9yZg==?=" <$email>\E)m, "encoded cc found" );

## Send a message with HTML contents..
$de = $t->xml_response(qq~<vsap type="webmail:send">
  <To>$email</To>
  <Cc>"Scøtt Wiersdorf" &#060;$email&#062;</Cc>
  <Subject>A nice cc test</Subject>
  <Text><h2>This is an HTML message </h2></Text>
  <TextType>text/html</TextType>
  <SaveOut>1</SaveOut>
</vsap>~);
mail_pause();

$message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
like( $message, qr(Content-Type: text/html)m, "found text/html content type." );


## Send message 2 multiple recipients with ; as seperator in To: field.

$de = $t->xml_response(qq~<vsap type="webmail:send">
  <To>$email; jkoecher@verio.net</To>
  <Subject>Multiple Recipients</Subject>
  <Text>Testing for Multiple Send ControlPanel</Text>
  <SaveOut>1</SaveOut>
</vsap>~);
mail_pause();
$message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
like( $message, qr(\QTo: $email, jkoecher@verio.net)m, "Multiple To found" );

## test genericstable (VPS v2 only)
SKIP: {
    skip "VPS v2 specific tests", 5
      unless $ENV{VST_PLATFORM} =~ 'VPS2' ;

    if( -e "/etc/mail/genericstable" ) {
	rename "/etc/mail/genericstable", "/etc/mail/genericstable.$$";
    }
    if( -e "/etc/mail/virtusertable" ) {
	rename "/etc/mail/virtusertable", "/etc/mail/virtusertable.$$";
    }

    my $user = $ACCT->username;
    my $hostname = `hostname`; chomp $hostname;
    open GT, ">/etc/mail/genericstable";
    print GT "$user		malarkey\@$hostname\n";
    close GT;

    open VT, ">/etc/mail/virtusertable";
    print VT "malarkey\@$hostname		$user\n";
    close VT;

    my $wd = `pwd`; chomp $wd;
    chdir('/etc/mail');
    system('make > /dev/null 2>&1');
    chdir($wd);

    $de = $t->xml_response(qq!<vsap type="webmail:send">
  <To>$email</To>
  <From>"Eddie Palmieri" &#060;palmas\@nonesuch.org&#062;</From>
  <Subject>testing generics</Subject>
  <Text>This is a test.</Text>
  <SaveOut>1</SaveOut>
</vsap>!);

    is ($de->findvalue("/vsap/vsap[\@type='webmail:send']/status"), "ok", "message sent")
      or print STDERR $de->toString();
    $msgs++;
    mail_pause();

    $message = $de->findvalue('/vsap/vsap[@type="webmail:send"]/email_msg');
    $message = VSAP::Server::Base::xml_escape($message);

    $de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>INBOX</folder></vsap>!);
    $msgid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="testing generics"]/uid');
    ok( $msgid, "message id $msgid found" );
    $de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>INBOX</folder><uid>$msgid</uid></vsap>!);
    like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(This is a test\.), "body groked" );
    my $inbox = $ACCT->inboxpath;

    ok( ! system($egrep_cmd, '-q', '^From malarkey', $inbox), "envelope sender set" )
      or print STDERR `tail -n 25 $inbox`;

    $de = $t->xml_response(qq!<vsap type="webmail:messages:save"><folder>Sent Items</folder><message>$message</message></vsap>!);
    $de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Sent Items</folder></vsap>!);
    $msgid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="testing generics"]/uid')
	or diag($de->toString(1));
    $de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>Sent Items</folder><uid>$msgid</uid></vsap>!);
    is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/from/address/personal'), q(Eddie Palmieri), 'message saved to Sent Items has correct "From:" header' )
      or diag($de->toString(1));
}

## wait no longer than necessary or $MAIL_PAUSE_TIME (whichever comes first)
## this saves (with 34 tests) about 25 seconds of test time
sub mail_pause {
    my $sent_time  = time;
    my $mtime_orig = (stat($ACCT->inboxpath))[9];
    do { sleep 1 } while( time <= ($sent_time + $MAIL_PAUSE_TIME) &&
			  $mtime_orig == (stat($ACCT->inboxpath))[9] );
}

END {
    $ACCT->delete();
    if( $ENV{VST_PLATFORM} eq 'VPS2' ) {
	my $changed = 0;

	## restore genericstable
	if( -e "/etc/mail/genericstable.$$" ) {
	    unlink "/etc/mail/genericstable", "/etc/mail/genericstable.db";
	    rename "/etc/mail/genericstable.$$", "/etc/mail/genericstable";
	    $changed = 1;
	}

	if( -e "/etc/mail/virtusertable.$$" ) {
	    unlink "/etc/mail/virtusertable", "/etc/mail/virtusertable.db";
	    rename "/etc/mail/virtusertable.$$", "/etc/mail/virtusertable";
	    $changed = 1;
	}

	if( $changed ) {
	    chdir('/etc/mail');
	    system('make > /dev/null 2>&1');
	}
    }
}
