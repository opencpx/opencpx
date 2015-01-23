use Test::More tests => 39;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::options') };

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail::options']);

my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));
my $node;

##
## test load empty
##

## should not be empty
$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);

## these should be from the defaults
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options') ) {
    is( $node->findvalue('./from_name'), '' );
    is( $node->findvalue('./outbound_encoding'), 'UTF-8');
    is( $node->findvalue('./messages_per_page'), 10 );
    is( $node->findvalue('./addresses_per_page'), 10 );
    is( $node->findvalue('./html_compose'), 'yes');
}
else {
    fail();
    fail();
    fail();
    fail();
}

ok( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options/reply_to_toggle') );
ok( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options/signature_toggle') );

##
## test load happy
##

## give joe some webmail options

my $homedir = $ACCT->homedir;
my $webmail_options = "$homedir/.cpx/webmail_options.xml";
my $sysuser = $ACCT->sysusername;
my $sysgroup = $ACCT->sysgroupname;

system('touch', $webmail_options);
system('chown', "$sysuser:$sysgroup", $webmail_options);

open OPTIONS, ">>$webmail_options"
  or die "Could not open webmail_options.xml: $!\n";
print OPTIONS <<'_OPTIONS_';
<webmail_options>
  <from_name>Joe Schmoe, Jr.</from_name>
  <preferred_from>jschmoe@schmoe.org</preferred_from>
  <reply_to>jschmoe@schmoe.org</reply_to>
  <reply_to_toggle>1</reply_to_toggle>
  <signature>Joe Schmoe, Jr.
Root Beer Drinkers Anonymous
&lt;joe@schmoe.org&gt;</signature>
  <outbound_encoding>US-ASCII</outbound_encoding>
  <fcc>Sent Items</fcc>
  <url_highlight>yes</url_highlight>
  <addresses_per_page>10</addresses_per_page>
  <messages_per_page>10</messages_per_page>
  <tz_display></tz_display>
  <display_encoding>ISO-2022jp</display_encoding>
  <use_mailboxlist>yes</use_mailboxlist>
  <inbox_checkmail>0</inbox_checkmail>
  <html_compose>no</html_compose>
</webmail_options>
_OPTIONS_
close OPTIONS;

$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options') ) {
    is( $node->findvalue('./preferred_from'), 'jschmoe@schmoe.org' );
    is( $node->findvalue('./display_encoding'), 'ISO-2022jp' );
    is( $node->findvalue('./from_name'), 'Joe Schmoe, Jr.' );
    is( $node->findvalue('./reply_to_toggle'), 1 );
    is( $node->findvalue('./addresses_per_page'), 10 );
    is( $node->findvalue('./use_mailboxlist'), 'yes' );
    is( $node->findvalue('./inbox_checkmail'), 0 );
    is( $node->findvalue('./html_compose'), 'no' );
}
else {
    fail();
    fail();
    fail();
    fail();
    fail();
    fail();
}

##
## test save happy
##
undef $de;
undef $node;

$de = $t->xml_response(qq!<vsap type='webmail:options:save'>
<webmail_options>
  <from_name>Joseph Schmoe, Esquire</from_name>
  <addresses_per_page>25</addresses_per_page>
  <use_mailboxlist>no</use_mailboxlist>
  <inbox_checkmail>5</inbox_checkmail>
</webmail_options>
</vsap>!);

undef $de;
## check to see that the new name was saved
$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options') ) {
    is( $node->findvalue('./from_name'), 'Joseph Schmoe, Esquire' );
    is( $node->findvalue('./addresses_per_page'), 25 );
    is( $node->findvalue('./use_mailboxlist'), 'no' );
    is( $node->findvalue('./inbox_checkmail'), 5 );
}
else {
    fail();
    fail();
    fail();
}

##
## test fetch happy
##
undef $de;
undef $node;
$de = $t->xml_response(qq!<vsap type='webmail:options:fetch'>
<from_name/><display_encoding/><addresses_per_page/></vsap>!);

if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:fetch"]/webmail_options') ) {
    is( $node->findvalue('./from_name'), 'Joseph Schmoe, Esquire' );
    is( $node->findvalue('./display_encoding'), 'ISO-2022jp' );
    is( $node->findvalue('./addresses_per_page'), 25 );
}
else {
    fail();
    fail();
    fail();
}

##
## unlink the defaults and start again
##
unlink $webmail_options;

## should return hard-coded defaults
undef $de;
undef $node;
$de = $t->xml_response(qq!<vsap type='webmail:options:load'/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options') ) {
    is( $node->findvalue('./display_encoding'), 'UTF-8' );
    is( $node->findvalue('./addresses_per_page'), 10 );
    is( $node->findvalue('./use_mailboxlist'), 'no' );
    is( $node->findvalue('./inbox_checkmail'), 0 );
    is( $node->findvalue('./html_compose'), 'yes');
}
else {
    fail();
    fail();
    fail();
}

ok( !-f $webmail_options );

## save some new settings which include a high ascii utf-8 character
undef $de;
undef $node;
$de = $t->xml_response(qq!<vsap type='webmail:options:save'>
  <webmail_options>
    <from_name>Joe Schmoeñ</from_name>
    <display_encoding>ISO-8859-1</display_encoding>
    <addresses_per_page>50</addresses_per_page>
    <html_compose>yes</html_compose>
  </webmail_options>
</vsap>!);

## should be a mix of our settings and defaults
undef $de;
undef $node;

$de = $t->xml_response(qq!<vsap type="webmail:options:load"/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:options:load"]/webmail_options') ) {
    is( $node->findvalue('./from_name'), 'Joe Schmoeñ' );
    is( $node->findvalue('./display_encoding'), 'ISO-8859-1' );
    is( $node->findvalue('./outbound_encoding'), 'UTF-8' );
    is( $node->findvalue('./addresses_per_page'), 50 );
    is( $node->findvalue('./html_compose'), 'yes');
}
else {
    fail();
    fail();
    fail();
    fail();
}

# Signature Issue BUG07780 - Make sure if reply_to is not valid email address that the following code and message are in dom.
undef $de;
undef $node;
$de = $t->xml_response(qq!<vsap type='webmail:options:save'>
  <webmail_options>
    <reply_to>Joe Schmoe</reply_to>
  </webmail_options>
</vsap>!);

ok($de->find('/vsap/vsap[@type="error"][code="102"]'),"look for error code on invalid reply_to");
ok($de->find('/vsap/vsap[@type="error"][message="Invalid address in reply_to field."]'),"look for error message on invalid reply_to");

## FIXME: test set_values
## FIXME: test get_value

## as_hash
my $dom = XML::LibXML->createDocument( "1.0", "UTF8" );
$dom->setDocumentElement($dom->createElement('vsap'));
$vsap->{homedir} = $ACCT->homedir;
$vsap->{cpxbase} = $vsap->{homedir} . "/.cpx";
my $hash = VSAP::Server::Modules::vsap::webmail::options::as_hash($vsap, $dom);
is( $hash->{from_name}, 'Joe Schmoeñ', "hash data" );

exit;
