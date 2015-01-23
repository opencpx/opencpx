use Test::More tests => 380;
use strict;

BEGIN { use_ok( 'VSAP::Server::Modules::vsap::webmail::addressbook' ) };
BEGIN { use_ok( 'VSAP::Server::Modules::vsap::webmail::distlist' ) };
BEGIN { use_ok( 'VSAP::Server::Modules::vsap::webmail::options' ) };
BEGIN { use_ok( 'VSAP::Server::Test' ); };
BEGIN { use_ok( 'VSAP::Server::Test::Account' ); };
BEGIN { use_ok( 'Data::UUID' ); };

##################################################
## initialization

my $acct;    # vsap test account object
my $vsap;    # vsap test object
my $client;  # vsap test client object
my $resp;    # vsap response
my $node;    # vsap responce node

ok( $acct = VSAP::Server::Test::Account->create({type => 'end-user'}), "create test account");
ok( $acct->exists, "test account exists");
ok( $vsap = $acct->create_vsap(['vsap::webmail::addressbook','vsap::webmail::distlist','vsap::webmail::options']),"started vsapd");
ok( $client = $vsap->client({acct => $acct}), "obtained vsap client");


## ---------------------------------------------------------------------- 
## test webmail:addressbook:list
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list"/>!);
($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address');
ok(!$node,"no nodes found in blank addressbook");

is( $resp->findvalue('/vsap/vsap/num_addresses'), '0', "number of addresses is 0");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "total pages is 1" );
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "prev page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank" );
is( $resp->findvalue('/vsap/vsap/first_address'), '0', "first address is 0");
is( $resp->findvalue('/vsap/vsap/last_address'), '0', "last address is 0" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sortby is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value is blank");

## ---------------------------------------------------------------------- 
## test address list: 1 item list
## ---------------------------------------------------------------------- 

ok(add_entry({ first => 'Kevin', 
		last => 'Whyte', 
		nickname => 'insert cool nickname here', 
		email => 'kwhyte@yahoo.com' }),
	 "adding addressbook entry");

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list"/>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '1', "number of addresses is 1");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '1', "last address is 1" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "record type is correct");
    is( $node->findvalue('./listid'), '', "listid is blank");
    is( $node->findvalue('./firstname'), 'Kevin', "first name is correct");
    is( $node->findvalue('./lastname'), 'Whyte', "last name is correct" );
    is( $node->findvalue('./nickname'), 'insert cool nickname here', "nickname is correct");
    is( $node->findvalue('./email'), 'kwhyte@yahoo.com', "email is correct" );
    ok( $node->findvalue('./uid'), "contains a uid" );
}


## ---------------------------------------------------------------------- 
## test address list: 2 item list
## ---------------------------------------------------------------------- 

ok(add_entry({ first => 'Ruud', 
		last => 'van Nistelrooy', 
		nickname => 'tien', 
		email => 'r.vannistelrooy@manu.co.uk' }),
	 "adding addressbook entry");

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list"/>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '2', "number of addresses is 2");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '2', "last address is 2" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[2]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ruud', "first name is correct" );
    is( $node->findvalue('./lastname'), 'van Nistelrooy', "last name is correct");
    is( $node->findvalue('./nickname'), 'tien', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.vannistelrooy@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}


## ---------------------------------------------------------------------- 
## test address list: 5 item list, include distribution list
## ---------------------------------------------------------------------- 

ok(add_entry({ first => 'Wayne', 
		last => 'Rooney', 
		nickname => 'Nails', 
		email => 'w.rooney@manu.co.uk' }),
	 "adding addressbook entry");

ok(add_entry({ first => 'Damien', 
		last => 'Duff', 
		nickname => '11', 
		email => 'd.duff@ChelseaFC.co.uk'}),
	 "adding addressbook entry");

ok(add_distlist( { name => 'Crew', nickname => 'My Team', description => 'teammates', 
    entries => [ { first => 'Ruud', last => 'van Nistelrooy', address => 'r.vannistelrooy@manu.co.uk'},
		 { first => 'Wayne', last => 'Rooney', address => 'w.rooney@manu.co.uk'},
		 { first => 'Cristiano', last => 'Ronaldo', address => 'c.ronaldo@manu.co.uk'}] 
		 }), "adding distribution list entry");

## test address list: firstname, ascending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list"/>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '5', "number of addresses is 5");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '5', "last address is 1" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "type of group is correct");
    like( $node->findvalue('./listid'),'/\d+/', "listid is numerical");
    is( $node->findvalue('./firstname'), 'Crew', "first name of group is correct");
    is( $node->findvalue('./lastname'), 'Crew', "last name of group is correct");
    is( $node->findvalue('./nickname'), 'My Team', "nickname of group is correct" );
    is( $node->findvalue('./email[1]'), 'r.vannistelrooy@manu.co.uk', "email of group is corredct");
}

## test address list: firstname, descending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>descending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is descending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[2]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ruud', "first name is correct" );
    is( $node->findvalue('./lastname'), 'van Nistelrooy', "last name is correct");
    is( $node->findvalue('./nickname'), 'tien', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.vannistelrooy@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: lastname, ascending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>lastname</sort_by>
  <sort_type>ascending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'lastname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[4]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ruud', "first name is correct" );
    is( $node->findvalue('./lastname'), 'van Nistelrooy', "last name is correct");
    is( $node->findvalue('./nickname'), 'tien', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.vannistelrooy@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: lastname, descending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>lastname</sort_by>
  <sort_type>descending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'lastname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is ascending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[4]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Damien', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Duff', "last name is correct");
    is( $node->findvalue('./nickname'), '11', "nickname is correct" );
    is( $node->findvalue('./email'), 'd.duff@ChelseaFC.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: nickname, ascending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>nickname</sort_by>
  <sort_type>ascending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'nickname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Damien', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Duff', "last name is correct");
    is( $node->findvalue('./nickname'), '11', "nickname is correct" );
    is( $node->findvalue('./email'), 'd.duff@ChelseaFC.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: nickname, descending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>nickname</sort_by>
  <sort_type>descending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'nickname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is ascending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[4]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "record type is correct");
    is( $node->findvalue('./listid'), '', "listid is blank");
    is( $node->findvalue('./firstname'), 'Kevin', "first name is correct");
    is( $node->findvalue('./lastname'), 'Whyte', "last name is correct" );
    is( $node->findvalue('./nickname'), 'insert cool nickname here', "nickname is correct");
    is( $node->findvalue('./email'), 'kwhyte@yahoo.com', "email is correct" );
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: email, ascending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>email</sort_by>
  <sort_type>ascending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'email', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[2]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "record type is correct");
    is( $node->findvalue('./listid'), '', "listid is blank");
    is( $node->findvalue('./firstname'), 'Kevin', "first name is correct");
    is( $node->findvalue('./lastname'), 'Whyte', "last name is correct" );
    is( $node->findvalue('./nickname'), 'insert cool nickname here', "nickname is correct");
    is( $node->findvalue('./email'), 'kwhyte@yahoo.com', "email is correct" );
    ok( $node->findvalue('./uid'), "contains a uid" );
}

## test address list: email, descending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>email</sort_by>
  <sort_type>descending</sort_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/sort_by'), 'email', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is ascending");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[5]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Damien', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Duff', "last name is correct");
    is( $node->findvalue('./nickname'), '11', "nickname is correct" );
    is( $node->findvalue('./email'), 'd.duff@ChelseaFC.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok(add_entry({ first => 'Ryan', 
		last => 'Giggs', 
		nickname => '', 
		email => 'r.giggs@manu.co.uk'}),
	 "adding addressbook entry");

ok(add_entry({ first => 'Cristiano', 
		last => 'Ronaldo', 
		nickname => 'Rono', 
		email => 'c.ronaldo@manu.co.uk'}),
	 "adding addressbook entry");

select(undef, undef, undef, 1.1);  ## have to do this to get new unique id

ok(add_distlist( { name => 'Strikers', nickname => '', description => 'front line', 
    entries => [ { first => 'Thierry', last => 'van Nistelrooy', address => 't.henrey@arsenal.co.uk'}],
		 { first => 'Wayne', last => 'Rooney', address => 'w.rooney@manu.co.uk'},
		 { first => 'Ruud', last => 'van Nistelrooy', address => 'r.vannistelrooy@manu.co.uk'},
		 }), "adding distribution list entry");

ok(add_entry({ first => 'Shaun', 
		last => 'Wright-Phillips', 
		nickname => 'Flash', 
		email => 's.wrightphilips@mancity.co.uk'}),
	 "adding addressbook entry");

ok(add_entry({ first => 'Thierry', 
		last => 'Henry', 
		nickname => '', 
		email => 't.henry@arsenal.co.uk'}),
	 "adding addressbook entry");

ok(add_entry({ first => 'Ashley', 
		last => 'Cole', 
		nickname => '', 
		email => 'a.cole@arsenal.co.uk'}),
	 "adding addressbook entry");

ok(add_entry({ first => 'Didier', 
		last => 'Drogba', 
		nickname => '', 
		email => 'd.drogba@ChelseaFC.co.uk'}),
	 "adding addressbook entry");

select(undef, undef, undef, 1.1);  ## have to do this to get new unique id

ok(add_distlist( { name => 'Chelsea', nickname => 'Fly Emirates', description => 'Chelsea Football Club', 
    entries => [ { first => 'Damien', last => 'Duff', address => 'd.duff@ChelseaFC.co.uk'},
		 { first => 'Didier', last => 'Drogba', address => 'd.drogba@ChelseaFC.co.uk'}]
		 }), "adding distribution list entry");

ok(add_entry({ first => 'David', 
		last => 'Beckham', 
		nickname => 'Seven', 
		email => 'd.beckham@realmadrid.co.es'}),
	 "adding addressbook entry");

select(undef, undef, undef, 1.1);  ## have to do this to get new unique id

ok(add_distlist( { name => 'Arsenal', nickname => 'O2', description => 'Arsenal Football Club', 
    entries => [ { first => 'Thierry', last => 'Henry', address => 't.henry@arsenal.co.uk'},
		 { first => 'Ashley', last => 'Cole', address => 'a.cole@arsenal.co.uk'}]
		 }), "adding distribution list entry");

## test address list: firstname, ascending, page 1

## test address list: firstname, ascending

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <page>1</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '15', "number of addresses is 15");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '2', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '10', "last address is 1" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Arsenal', "first name is correct");
    is( $node->findvalue('./lastname'), 'Arsenal', "last name is correct" );
    is( $node->findvalue('./nickname'), 'O2', "nickname is correct");
    is( $node->findvalue('./email[1]'), 't.henry@arsenal.co.uk', "email is correct" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[10]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ruud', "first name is correct" );
    is( $node->findvalue('./lastname'), 'van Nistelrooy', "last name is correct");
    is( $node->findvalue('./nickname'), 'tien', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.vannistelrooy@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[11]!), "There is no 11th entry.");

## test address list: firstname, ascending, page 2

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <page>2</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '15', "number of addresses is 15");
is( $resp->findvalue('/vsap/vsap/page'), '2', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '1', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '11', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '15', "last address is 1" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is firstname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is ascending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ryan', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Giggs', "last name is correct");
    is( $node->findvalue('./nickname'), '', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.giggs@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[5]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Wayne', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Rooney', "last name is correct");
    is( $node->findvalue('./nickname'), 'Nails', "nickname is correct" );
    is( $node->findvalue('./email'), 'w.rooney@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[6]!), "There is no 6th entry." );


## test address list: lastname, descending, page 1

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>lastname</sort_by>
  <sort_type>descending</sort_type>
  <page>1</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '15', "number of addresses is 15");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '2', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '10', "last address is 10" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'lastname', "sort_by is lastname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is descending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Shaun', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Wright-Phillips', "last name is correct");
    is( $node->findvalue('./nickname'), 'Flash', "nickname is correct" );
    is( $node->findvalue('./email'), 's.wrightphilips@mancity.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[10]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Didier', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Drogba', "last name is correct");
    is( $node->findvalue('./nickname'), '', "nickname is correct" );
    is( $node->findvalue('./email'), 'd.drogba@ChelseaFC.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[11]!), "There is no 11th entry");

## test address list: lastname, descending, page 2

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>lastname</sort_by>
  <sort_type>descending</sort_type>
  <page>2</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '15', "number of addresses is 15");
is( $resp->findvalue('/vsap/vsap/page'), '2', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '1', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '11', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '15', "last address is 10" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'lastname', "sort_by is lastname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is descending");
is( $resp->findvalue('/vsap/vsap/search_value'), '', "search_value");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Crew', "first name is correct");
    is( $node->findvalue('./lastname'), 'Crew', "last name is correct" );
    is( $node->findvalue('./nickname'), 'My Team', "nickname is correct");
    is( $node->findvalue('./email[1]'), 'r.vannistelrooy@manu.co.uk', "email is correct" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[5]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Arsenal', "first name is correct");
    is( $node->findvalue('./lastname'), 'Arsenal', "last name is correct" );
    is( $node->findvalue('./nickname'), 'O2', "nickname is correct");
    is( $node->findvalue('./email[1]'), 't.henry@arsenal.co.uk', "email is correct" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[6]!), "There is no 6th entry");

## test address list: firstname, ascending, search string 'man'

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <search_value>man</search_value>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '6', "number of addresses is correct");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is correct" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is correct");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is correct" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is correct");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is correct" );
is( $resp->findvalue('/vsap/vsap/last_address'), '6', "last address is correct" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is correct");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is correct");
is( $resp->findvalue('/vsap/vsap/search_value'), 'man', "search_value is correct");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Crew', "first name is correct");
    is( $node->findvalue('./lastname'), 'Crew', "last name is correct" );
    is( $node->findvalue('./nickname'), 'My Team', "nickname is correct");
    is( $node->findvalue('./email[1]'), 'r.vannistelrooy@manu.co.uk', "email is correct" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[6]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Wayne', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Rooney', "last name is correct");
    is( $node->findvalue('./nickname'), 'Nails', "nickname is correct" );
    is( $node->findvalue('./email'), 'w.rooney@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[7]!), "There is no 7th entry");


## test address list: firstname, ascending, search string 'co.uk', page 1

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <search_value>co.uk</search_value>
  <page>1</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '13', "number of addresses is 13");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '2', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '10', "last address is 10" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is lastname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is descending");
is( $resp->findvalue('/vsap/vsap/search_value'), 'co.uk', "search_value");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Arsenal', "first name is correct");
    is( $node->findvalue('./lastname'), 'Arsenal', "last name is correct" );
    is( $node->findvalue('./nickname'), 'O2', "nickname is correct");
    is( $node->findvalue('./email[1]'), 't.henry@arsenal.co.uk', "email is correct" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[10]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Shaun', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Wright-Phillips', "last name is correct");
    is( $node->findvalue('./nickname'), 'Flash', "nickname is correct" );
    is( $node->findvalue('./email'), 's.wrightphilips@mancity.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[11]!), "Is no 11th entry.");

## test address list: firstname, ascending, search string 'co.uk', page 2

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <search_value>co.uk</search_value>
  <page>2</page>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '13', "number of addresses is 13");
is( $resp->findvalue('/vsap/vsap/page'), '2', "current page is 1" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '2', "number of pages is 1");
is( $resp->findvalue('/vsap/vsap/prev_page'), '1', "previous page is blank" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is blank");
is( $resp->findvalue('/vsap/vsap/first_address'), '11', "first address is 1" );
is( $resp->findvalue('/vsap/vsap/last_address'), '13', "last address is 10" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is lastname");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is descending");
is( $resp->findvalue('/vsap/vsap/search_value'), 'co.uk', "search_value");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 6 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'group', "record type is correct");
    like( $node->findvalue('./listid'), qr/^\d+$/, "listid is numerical");
    is( $node->findvalue('./firstname'), 'Strikers', "first name is correct");
    is( $node->findvalue('./lastname'), 'Strikers', "last name is correct" );
    is( $node->findvalue('./nickname'), '', "nickname is correct");
    is( $node->findvalue('./email[1]'), 't.henrey@arsenal.co.uk', "email is correct" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[3]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Wayne', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Rooney', "last name is correct");
    is( $node->findvalue('./nickname'), 'Nails', "nickname is correct" );
    is( $node->findvalue('./email'), 'w.rooney@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[4]!), "There is no 4th element");

## test address list: lastname, descending, search string 'd'

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>lastname</sort_by>
  <sort_type>descending</sort_type>
  <search_value>d</search_value>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '7', "number of addresses is correct");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is correct" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is correct");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is correct" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is correct");
is( $resp->findvalue('/vsap/vsap/first_address'), '1', "first address is correct" );
is( $resp->findvalue('/vsap/vsap/last_address'), '7', "last address is correct" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'lastname', "sort_by is correct");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'descending', "sort_type is correct");
is( $resp->findvalue('/vsap/vsap/search_value'), 'd', "search_value is correct");


SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[1]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'Ruud', "first name is correct" );
    is( $node->findvalue('./lastname'), 'van Nistelrooy', "last name is correct");
    is( $node->findvalue('./nickname'), 'tien', "nickname is correct" );
    is( $node->findvalue('./email'), 'r.vannistelrooy@manu.co.uk', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="webmail:addressbook:list"]/address[7]');
    skip "unable to obtain node from address listing", 7 
	unless ok($node,"found address node");
    is( $node->findvalue('./type'), 'individual', "type is individual");
    is( $node->findvalue('./listid'), '',"listid is blank" );
    is( $node->findvalue('./firstname'), 'David', "first name is correct" );
    is( $node->findvalue('./lastname'), 'Beckham', "last name is correct");
    is( $node->findvalue('./nickname'), 'Seven', "nickname is correct" );
    is( $node->findvalue('./email'), 'd.beckham@realmadrid.co.es', "email is correct");
    ok( $node->findvalue('./uid'), "contains a uid" );
}

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[8]!), "There is no 8th address.");

## test address list: firstname, ascending, search string 'bogus'

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:list">
  <sort_by>firstname</sort_by>
  <sort_type>ascending</sort_type>
  <search_value>bogus</search_value>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/num_addresses'), '0', "number of addresses is correct");
is( $resp->findvalue('/vsap/vsap/page'), '1', "current page is correct" );
is( $resp->findvalue('/vsap/vsap/total_pages'), '1', "number of pages is correct");
is( $resp->findvalue('/vsap/vsap/prev_page'), '', "previous page is correct" );
is( $resp->findvalue('/vsap/vsap/next_page'), '', "next page is correct");
is( $resp->findvalue('/vsap/vsap/first_address'), '0', "first address is correct" );
is( $resp->findvalue('/vsap/vsap/last_address'), '0', "last address is correct" );
is( $resp->findvalue('/vsap/vsap/sort_by'), 'firstname', "sort_by is correct");
is( $resp->findvalue('/vsap/vsap/sort_type'), 'ascending', "sort_type is correct");
is( $resp->findvalue('/vsap/vsap/search_value'), 'bogus', "search_value is correct");

ok( ! $resp->findnodes(q!/vsap/vsap[@type="webmail:addressbook:list"]/address[1]!), "There are no addresses." );

END { }

sub add_entry { 
    my $data = shift;

    my $resp = $client->xml_response(qq!<vsap type="webmail:addressbook:add">
    <Last_Name>$$data{last}</Last_Name>
    <First_Name>$$data{first}</First_Name>
    <Nickname>$$data{nickname}</Nickname>
    <Email_Address>$$data{email}</Email_Address>
    </vsap>!);

    return $resp->findvalue(qq!/vsap/vsap[\@type="webmail:addressbook:add"]/vCardSet/vCard[Email_Address="$$data{email}"]!);
}

sub add_distlist { 
    my $data = shift;

    my $xml = qq!
<vsap type="webmail:distlist:add">
  <name>$$data{name}</name>
  <nickname>$$data{nickname}</nickname>
  <description>$$data{description}</description>!;

   foreach my $entry (@{$$data{entries}}) { 
    $xml .=<<EOF;
  <entry>
    <first>$$entry{first}</first>
    <last>$$entry{last}</last>
    <address>$$entry{address}</address>
  </entry>
EOF
   }
   $xml.= "</vsap>";

   my $resp = $client->xml_response($xml);
   return $resp->findvalue(q!/vsap/vsap[@type="webmail:distlist:add"]/status!);
}
