use Test::More tests => 21;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::distlist') };

#########################
use VSAP::Server::Test;
use VSAP::Server::Test::Account;

## make sure our user does not exist

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail::distlist']);
my $t = $vsap->client({ acct => $ACCT });
ok(ref($t));

my $de;
my $node;

## test empty list
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"/>!);
($node) = $de->findnodes('/vsap/vsap[@type="webmail:distlist:list"]/*');
ok( ! $node );

## add a new list
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>My Friends</name>
  <nickname>friends</nickname>
  <description>some of my friends</description>
  <entry>
    <first>Bob</first>
    <last>Smith</last>
    <address>bob@friend.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Jones</last>
    <address>bill@friend.com</address>
  </entry>
  <entry>
    <first>Mike</first>
    <last>Anderson</last>
    <address>mike@friend.com</address>
  </entry>
  <entry>
    <first>Ron</first>
    <last>Morgan</last>
    <address>ron@friend.com</address>
  </entry>
  <entry>
    <first>Scooby</first>
    <last>Doo</last>
    <address>scoob@friend.com</address>
  </entry>
</vsap>!);

## test return values
ok( $de );

## list lists
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:list"/>!);
my $friendlistid = $de->findvalue('/vsap/vsap[@type="webmail:distlist:list"]/distlist[name="My Friends"]/listid');


## list again
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"><listid>$friendlistid</listid></vsap>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:distlist:list"]/distlist') ) {
    is( $node->findvalue('./name'), "My Friends" );
}
else {
    fail();
}

select(undef, undef, undef, 1.1);  ## have to do this to get new unique id

## try a duplicate listname
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>My Friends</name>
  <nickname>friends</nickname>
  <description>some of my friends</description>
  <entry>
    <first>Norville</first>
    <last>Rogers</last>
    <address>shaggy@friend.com</address>
  </entry>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(already exists) );

## try a list with an apostrophe
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>Scott's Friends</name>
  <nickname>friends</nickname>
  <description>some of my friends</description>
  <entry>
    <first>Norville</first>
    <last>Rogers</last>
    <address>shaggy@friend.com</address>
  </entry>
</vsap>!);

ok( $de );


## try a duplicate w/ apostrophe
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>Scott's Friends</name>
  <nickname>friends</nickname>
  <description>some of my friends</description>
  <entry>
    <first>Norville</first>
    <last>Rogers</last>
    <address>shaggy@friend.com</address>
  </entry>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(already exists) );

select(undef, undef, undef, 1.1);  ## have to do this to get new unique id

## add another
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>My Enemies</name>
  <nickname>enemies</nickname>
  <description>people who are my enemies</description>
  <entry>
    <first>Bob</first>
    <last>Roberts</last>
    <address>bob@enemy.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Johnson</last>
    <address>bill@enemy.com</address>
  </entry>
  <entry>
    <first>Mike</first>
    <last>Smith</last>
    <address>mike@enemy.com</address>
  </entry>
  <entry>
    <first>Ron</first>
    <last>Weasley</last>
    <address>ron@enemy.com</address>
  </entry>
  <entry>
    <first>Scooby</first>
    <last>Doo-Doo</last>
    <address>scoob@enemy.com</address>
  </entry>
</vsap>!);

ok($de);

undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:list"/>!);
my $enemylistid = $de->findvalue('/vsap/vsap[@type="webmail:distlist:list"]/distlist[name="My Enemies"]/listid');


## and list one
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"><listid>$enemylistid</listid></vsap>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:distlist:list"]/distlist') ) {
    is( $node->findvalue('./name'), "My Enemies" );
}
else {
    fail();
}

## list both
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"/>!);

if( ($node) = $de->findnodes("/vsap/vsap[\@type='webmail:distlist:list']/distlist[listid='$enemylistid']") ) {
    is( $node->findvalue('./name'), "My Enemies" );
}
else {
    fail();
}

if( ($node) = $de->findnodes("/vsap/vsap[\@type='webmail:distlist:list']/distlist[listid='$friendlistid']") ) {
    is( $node->findvalue('./name'), "My Friends" );
}
else {
    fail();
}


## try a new list w/o a name
sleep 1;
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <nickname>people</nickname>
  <description>people I know</description>
  <entry>
    <first>Bob</first>
    <last>Roberts</last>
    <address>bob@enemy.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Johnson</last>
    <address>bill@enemy.com</address>
  </entry>
  <entry>
    <first>Mike</first>
    <last>Smith</last>
    <address>mike@enemy.com</address>
  </entry>
  <entry>
    <first>Ron</first>
    <last>Weasley</last>
    <address>ron@enemy.com</address>
  </entry>
  <entry>
    <first>Scooby</first>
    <last>Doo-Doo</last>
    <address>scoob@enemy.com</address>
  </entry>
  <entry>
    <first>Bob</first>
    <last>Smith</last>
    <address>bob@friend.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Jones</last>
    <address>bill@friend.com</address>
  </entry>
  <entry>
    <first>Mike</first>
    <last>Anderson</last>
    <address>mike@friend.com</address>
  </entry>
  <entry>
    <first>Ron</first>
    <last>Morgan</last>
    <address>ron@friend.com</address>
  </entry>
  <entry>
    <first>Scooby</first>
    <last>Doo</last>
    <address>scoob@friend.com</address>
  </entry>
</vsap>!);

like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Need a listname and at least one address) );

## try a new list w/o an address
sleep 1;
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:distlist:add">
  <name>people</name>
  <nickname>people</nickname>
  <description>people I know</description>
</vsap>!);

like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Need a listname and at least one address) );

## edit an existing node
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:add">
  <edit/>
  <listid>$enemylistid</listid>
  <name>My Best Enemies</name>
  <nickname>enemies</nickname>
  <description>people who are my best enemies</description>
  <entry>
    <first>Bob</first>
    <last>Roberts</last>
    <address>bob\@enemy.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Johnson</last>
    <address>bill\@enemy.com</address>
  </entry>
</vsap>!);

$de = $t->xml_response(q!<vsap type="webmail:distlist:list"/>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:distlist:list"]/distlist[name="My Best Enemies"]/description'),
	"people who are my best enemies" );


## double check the edit
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"><listid>$enemylistid</listid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:distlist:list"]/distlist/name'),  "My Best Enemies" );


## delete a distlist
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:delete"><listid>$enemylistid</listid></vsap>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="webmail:distlist:delete"]') ) {
    is( $node->findvalue('./listid'), $enemylistid );
}
else {
    fail();
}

## add one back in
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:add">
  <listid>$enemylistid</listid>
  <name>My Best Enemies</name>
  <nickname>enemies</nickname>
  <description>people who are my best enemies</description>
  <entry>
    <first>Bob</first>
    <last>Roberts</last>
    <address>bob\@enemy.com</address>
  </entry>
  <entry>
    <first>Bill</first>
    <last>Johnson</last>
    <address>bill\@enemy.com</address>
  </entry>
</vsap>!);


## check it
$de = $t->xml_response(qq!<vsap type="webmail:distlist:list"><listid>$enemylistid</listid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:distlist:list"]/distlist/name'),  "My Best Enemies" );


## delete multiple dist lists
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:distlist:delete"><listid>$enemylistid</listid><listid>$friendlistid</listid></vsap>!);

ok( $de->findnodes(qq!/vsap/vsap[\@type="webmail:distlist:delete"][listid="$enemylistid"]/listid!) );
ok( $de->findnodes(qq!/vsap/vsap[\@type="webmail:distlist:delete"][listid="$friendlistid"]/listid!) );
