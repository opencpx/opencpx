use Test::More tests => 13;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::send') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;
use VSAP::Server::Base;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 5;

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

# First we will set the outbound encoding to UTF-8 and send a test message.
my $outboundEncoding = "UTF-8";
my $de = $t->xml_response(qq!<vsap type="webmail:options:save"><webmail_options><from_name>Joseph T. Foo</from_name><outbound_encoding>$outboundEncoding</outbound_encoding></webmail_options></vsap>!);
my $nl = $de->find("/vsap/vsap[\@type='webmail:options:save']/status");
is ($nl->string_value, "ok","able to set from_name and outbound encoding in options") || print STDERR $de->toString();

$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:options:load']/webmail_options/from_name");
is($nl->string_value, "Joseph T. Foo","from name was correctly set");
$nl = $de->find("/vsap/vsap[\@type='webmail:options:load']/webmail_options/outbound_encoding");
is($nl->string_value, $outboundEncoding,"Setting encoding.");

##  <vsap type="webmail:send">
# Now we send a message containing characters available in ISO-8859-1.
# The outbound encoding is set to UTF-8.
use encoding 'utf8';
my $utf8string = "äëñ";
no encoding;
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Cc></Cc><Subject>testing $utf8string</Subject><Text>This is a $utf8string test.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/status");
is ($nl->string_value, "ok","sent a message containing UTF-8 characters.")
    || print STDERR $de->toString();

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(This is a äëñ test.), "Message body with outbound encoding of utf-8")
    || print STDERR $de->toString();

## give the mail some time for delivery
sleep 3;

## should now show the mail we just received
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "The number of messages is $msgs" ) || diag $de->toString ;

# Now we will set the outbound encoding to ISO-8859-1 and send a test message.
$outboundEncoding = "ISO-8859-1";
$de = $t->xml_response(qq!<vsap type="webmail:options:save"><webmail_options><from_name>Joseph T. Foo</from_name><outbound_encoding>$outboundEncoding</outbound_encoding></webmail_options></vsap>!);

$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:options:load']/webmail_options/outbound_encoding");
is($nl->string_value, $outboundEncoding,"Setting encoding.");

##  <vsap type="webmail:send">
# Now we send a message containing characters availabe in ISO-8859-1.
# The outbound encoding is set to ISO-8859-1. Note that we still provide 
# these characters to vsap in the utf-8 encoding.  The reason is because 
# characters should always be transported over the server in UTF-8.
use encoding 'utf8';
$utf8string = "äëñ";
no encoding;
$de = $t->xml_response(qq!<vsap type="webmail:send"><To>$email</To><Cc></Cc><Subject>testing $utf8string</Subject><Text>This is a $utf8string test.</Text><SaveOut>1</SaveOut></vsap>!);
$msgs++;
$nl = $de->find("/vsap/vsap[\@type='webmail:send']/status");
is ($nl->string_value, "ok","sent a message containing UTF-8 characters.")
    || print STDERR $de->toString();

$nl = $de->find("/vsap/vsap[\@type='webmail:send']/email_msg");
like($nl->string_value, qr(This is a äëñ test.), "Message body with outbound encoding of iso-8859-1")
    || print STDERR $de->toString();

## give the mail some time for delivery
sleep 3;

## should now show the mail we just received
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/num_messages");
is( $nl->string_value, $msgs, "The number of messages is $msgs" ) || diag $de->toString ;

exit ;
