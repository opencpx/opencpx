use Test::More tests => 7;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

# The amount of time to wait for mail delivery.
my $MAIL_PAUSE_TIME = 3;

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));

## list drafts (empty)
my $de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Drafts</folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 0 );

## save message to Drafts
$de = $t->xml_response(q~<vsap type="webmail:messages:save">
  <folder>Drafts</folder>
  <message>Date: Fri, 26 Jun 2004 17:30:25 GMT&#010;From: Charlie Root &lt;root@thursday.securesites.net>&#010;To: joe@thursday.securesites.net&#010;Subject: Joe Rocks!&#010;&#010;Your good friends in system administration wish you a happy birthday.&#010;&#010;Charlie&#010;</message></vsap>~);

#print STDERR $de->toString(1);

## list drafts (one message)
$de = $t->xml_response(qq!<vsap type="webmail:messages:list"><folder>Drafts</folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 1 );

## dump message pieces
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message/subject'), "Joe Rocks!");
#print STDERR $de->toString(1);

## save a utf8 message to Sent Items
$de = $t->xml_response(qq~<vsap type="webmail:messages:save">
  <folder>Sent Items</folder>
  <message>Content-Disposition: inline&#010;Content-Transfer-Encoding: 8bit&#010;Content-Type: text/plain; charset=utf-8; format=flowed&#010;MIME-Version: 1.0&#010;X-Mailer: MIME::Lite 3.0104 (F2.72; T1.13; A1.66; B3.01; Q3.01)&#010;Date: Wed, 11 May 2005 20:09:10 +0000&#010;To: scott\@perclode.org&#010;Subject: =?UTF-8?B?dGVzdGluZyBpMThu?=&#010;&#010;This message has some jp in it:&#13;&#010;&#13;&#010;男無頼庵&#13;&#010;&#13;&#010;Have a nice day.</message>
</vsap>~);

## list drafts (one message)
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><folder>Sent Items</folder><uid>1</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(\x{7537}\x{7121}\x{983c}\x{5eb5}), 'unicode body');

#qr(\xe7\x94\xb7\xe7\x84\xa1), 'i18n body');
#print STDERR $de->toString(1);

END { }
