use Test::More tests => 110;
use strict;

BEGIN { use_ok( 'VSAP::Server::Test' ); };
BEGIN { use_ok( 'VSAP::Server::Test::Account' ); };

##################################################
## initialization

my $acct;    # vsap test account object
my $vsap;    # vsap test object
my $client;  # vsap test client object
my $resp;    # vsap response
my $node;    # vsap responce node

ok( $acct = VSAP::Server::Test::Account->create({type => 'end-user'}), "created an end-user account");
ok( $acct->exists, "that account does exist");
ok( $vsap = $acct->create_vsap(['vsap::webmail::addressbook',
				'vsap::webmail::distlist',
				'vsap::webmail::options']), "starting vsapd");
ok( $client = $vsap->client({acct => $acct}), "obtained vsapd client");

##################################################


## ---------------------------------------------------------------------- 
## test empty addressbook
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);
($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:load"]/*');
ok(!$node, "Obtained results from loading blank addressbook");


## ---------------------------------------------------------------------- 
## Add entry to addressbook. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:add">
  <Last_Name>Wiersdorf</Last_Name>
  <First_Name>Scotty</First_Name>
  <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
  <Email_Address>scott@perlcode.org</Email_Address>
  <Phone_Business>801-111-2222</Phone_Business>
</vsap>!);

($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard[First_Name="Scotty"]');
my $uid1 = $node->getAttribute('uid');

# Check response back from add. 

is( $resp->findvalue('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard/First_Name'), 'Scotty', "First_Name is correct");
is( $resp->findvalue('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard/Last_Name'), 'Wiersdorf', "Last_Name is correct");
is( $resp->findvalue('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard/Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
	"Nickname is correct");
is( $resp->findvalue('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard/Email_Address'), 'scott@perlcode.org', "Email_Address is correct");


## ---------------------------------------------------------------------- 
## Load addressbook, check for same response. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);

SKIP: {
	my ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:load"]/vCardSet');
	skip "failed to obtain node from addressbook load operation.", 3 
	    unless ok($node, "obtained node as poart of load response");
	is( $node->findvalue('./vCard/First_Name'), 'Scotty', "First_Name is correct");
	is( $node->findvalue('./vCard/Last_Name'), 'Wiersdorf', "Last_Name is correct");
	is( $node->findvalue('./vCard/Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
	    "Nickname is correct");
	is( $node->findvalue('./vCard/Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
} 


## ---------------------------------------------------------------------- 
## Add another entry with same email address, but different phone number. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:add">
  <Last_Name>Wiersdorf</Last_Name>
  <First_Name>Scott</First_Name>
  <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
  <Email_Address>scott@perlcode.org</Email_Address>
  <Phone_Business>801-437-7422</Phone_Business>
</vsap>!);

## should be ok, but reponse will have a different uid. 
($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard[Phone_Business="801-437-7422"]');
my $uid2 = $node->getAttribute('uid');
ok($node,"Obtained vCard node as result of add.");
isnt($uid2,$uid1,"uid of newly added element doesn't match existing uid");


## ---------------------------------------------------------------------- 
## Load the entire addressbook looking at the contents. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type='webmail:addressbook:load']/vCardSet/vCard[\@uid='$uid1']!);
    skip "failed to obtain nodes.", 5 
    	unless ok($node,"obtained first node from load response");
    is( $node->findvalue('./First_Name'), 'Scotty', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-111-2222', "Phone_Business is correct");
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type='webmail:addressbook:load']/vCardSet/vCard[\@uid='$uid2']!);
    skip "failed to obtain nodes.", 5 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone_Business is correct" );
}


## ---------------------------------------------------------------------- 
## Now edit the first entry, adjusting just the phone business to match the 
## second entry. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:add">
  <edit/>
  <uid>$uid1</uid>
  <Last_Name>Wiersdorf</Last_Name>
  <First_Name>Scott</First_Name>
  <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
  <Email_Address>scott\@perlcode.org</Email_Address>
  <Phone_Business>801-437-7422</Phone_Business>
</vsap>!);

SKIP: { 
    ($node) = $resp->findnodes(qq!/vsap/vsap[\@type='webmail:addressbook:add']/vCardSet/vCard[\@uid='$uid1']!);

    skip "failed to obtain node from edit operation", 5 
	unless ok($node,"obtained node from edit operation");

    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone_Business is correct.");
    is( $node->getAttribute('uid'), $uid1, "uid attribute is correct");
}


## ---------------------------------------------------------------------- 
## Now load the addressbook again, confirming both entries are correct.
## Even with the change to the business phone numeber. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid1"]!);
    skip "failed to obtain nodes.", 5 
    	unless ok($node,"obtained first node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone_Business is correct.");
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid2"]!);
    skip "failed to obtain nodes.", 5 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone_Business is correct.");
}


## ---------------------------------------------------------------------- 
## Add another address to the book
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:add">
  <Last_Name>von Heinz</Last_Name>
  <First_Name>Mr.</First_Name>
  <Nickname>411 Scammer Deluxe</Nickname>
  <Email_Address>vonheinz@yahoo.com</Email_Address>
</vsap>!);

($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard[Last_Name="von Heinz"]');
my $uid3 = $node->getAttribute('uid');
ok($node,"Obtained vCard node as result of add.");
isnt($uid3,$uid1, "uid of newly added element doesn't match existing uid");
isnt($uid3,$uid2, "uid of newly added element doesn't match existing uid");


## ---------------------------------------------------------------------- 
## Now load the addressbook again, confirming all three entries are correct. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid1"]!);
    skip "failed to obtain node for first entry.", 5 
    	unless ok($node,"obtained first node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone Business is correct" );
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid2"]!);
    skip "failed to obtain node for second entry.", 5 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone Business is correct" );
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid3"]!);
    skip "failed to obtain node for third entry.", 4 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Mr.', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'von Heinz', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), '411 Scammer Deluxe', "Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'vonheinz@yahoo.com', "Email_Address is correct");
}


## ---------------------------------------------------------------------- 
## load just one address
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:load"><uid>$uid1</uid></vsap>!);
SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCard[\@uid="$uid1"]!);

    skip "failed to obtain node.", 5 
    	unless ok($node,"obtained first node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone Business is correct" );
}

## Check that we have only returned one node.

$node = $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:load"]/vCard!);
is($node->size,1,"Only one node was returned");


## ---------------------------------------------------------------------- 
## delete an email address
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:delete"><uid>$uid3</uid></vsap>!);

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);
($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid3"]!);
ok( ! $node, "No node found after delete");


## ---------------------------------------------------------------------- 
## add back in the deleted entry. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:add">
  <Last_Name>von Heinz</Last_Name>
  <First_Name>Mr.</First_Name>
  <Nickname>411 Scammer Deluxe</Nickname>
  <Email_Address>vonheinz@yahoo.com</Email_Address>
</vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:add"]/vCardSet/vCard[Last_Name="von Heinz"]');
    $uid3 = $node->getAttribute('uid');
    skip "failed to obtain node for third entry.", 4
       	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Mr.', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'von Heinz', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), '411 Scammer Deluxe', "Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'vonheinz@yahoo.com', "Email_Address is correct");
}


## ---------------------------------------------------------------------- 
## Now load the addressbook again, confirming all three entries are correct. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid1"]!);
    skip "failed to obtain node for first entry.", 5 
    	unless ok($node,"obtained first node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone Business is correct" );
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid2"]!);
    skip "failed to obtain node for second entry.", 5 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Scott', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'Wiersdorf', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), 'That one guy who likes root beer and Tabasco sauce', 
    	"Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'scott@perlcode.org', "Email_Address is correct");
    is( $node->findvalue('./Phone_Business'), '801-437-7422', "Phone Business is correct" );
}

SKIP: { 
    my ($node) = $resp->findnodes(qq!/vsap/vsap[\@type="webmail:addressbook:load"]/vCardSet/vCard[\@uid="$uid3"]!);
    skip "failed to obtain node for third entry.", 4 
    	unless ok($node,"obtained second node from load response");
    is( $node->findvalue('./First_Name'), 'Mr.', "First_Name is correct");
    is( $node->findvalue('./Last_Name'), 'von Heinz', "Last_Name is correct");
    is( $node->findvalue('./Nickname'), '411 Scammer Deluxe', "Nickname is correct");
    is( $node->findvalue('./Email_Address'), 'vonheinz@yahoo.com', "Email_Address is correct");
}


## ---------------------------------------------------------------------- 
## Perform an edit leaving out the uid. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:add">
  <edit/>
  <Last_Name>Wiersdorf</Last_Name>
  <First_Name>Scott</First_Name>
  <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
  <Email_Address>scott\@perlcode.org</Email_Address>
  <Phone_Business>801-437-7422</Phone_Business>
</vsap>!);

like( $resp->findvalue('/vsap/vsap/message'), qr/uid attribute is required/,
    "correct error message returned when leaving out uid.");

cmp_ok( $resp->findvalue('/vsap/vsap/code'), '==', 104, 
    "correct error code returned when leaving out uid");


## ---------------------------------------------------------------------- 
## Perform an edit on an non-existant uid. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:add">
  <edit/>
  <uid>12345</uid>
  <Last_Name>Wiersdorf</Last_Name>
  <First_Name>Scott</First_Name>
  <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
  <Email_Address>scott\@perlcode.org</Email_Address>
  <Phone_Business>801-437-7422</Phone_Business>
</vsap>!);

like( $resp->findvalue('/vsap/vsap/message'), qr/Entry not found with specified uid./,
    "correct error message returned when providing incorrect uid when performing edit.");

cmp_ok( $resp->findvalue('/vsap/vsap/code'), '==', 100, 
    "correct error code returned when leaving out uid when performing edit.");


## ---------------------------------------------------------------------- 
## Perform an delete on an non-existant uid. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:delete">
  <uid>12345</uid>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/message'), 'XML node for \'12345\' not found',
    "correct error message returned when providing incorrect uid during delete.");

cmp_ok( $resp->findvalue('/vsap/vsap/code'), '==', 100, 
    "correct error code returned when leaving out uid during delete. ");


## ---------------------------------------------------------------------- 
## Now delete all email addresses
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(qq!<vsap type="webmail:addressbook:delete">
  <uid>$uid1</uid>
  <uid>$uid2</uid>
  <uid>$uid3</uid>
</vsap>!);


## ---------------------------------------------------------------------- 
## Do a load and confirm that there are no longer any entries. 
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);
($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:load"]/vCardSet/*');
ok( ! $node, "no nodes after all deleted");


## ---------------------------------------------------------------------- 
## Test conversion of an old file. 
## ---------------------------------------------------------------------- 

my $addrbook = $acct->homedir."/.cpx/addressbook.xml";
open FILE, ">$addrbook";
print FILE<<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE vCard SYSTEM "vcard.dtd">
<vCardSet name="Address Book">
    <vCard version="3.0">
       	<Last_Name>Russo</Last_Name>
	<First_Name>James</First_Name>
	<Nickname>James Russo</Nickname>
       	<Email_Address>jrusso\@verio.net</Email_Address>
    </vCard>
</vCardSet>
EOF
close FILE;

# now perform a load, check that each element now has uid. 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:load"/>!);
($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:load"]/vCardSet');

SKIP: { 
    skip "unable to obtain node", 1
	unless ok($node, "node exists after conversion");
    cmp_ok($node->getAttribute('version'),'==',1.1, "version on vCardSet is now correct");
}

($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:load"]/vCardSet/vCard[First_Name="James"]');

SKIP: { 
    skip "unable to obtain node", 1
	unless ok($node, "vCard node exists.");
    ok($node->getAttribute('uid'),"contains a uid");
}
