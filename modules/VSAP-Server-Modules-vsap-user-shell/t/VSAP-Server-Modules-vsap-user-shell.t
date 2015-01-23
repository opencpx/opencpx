use Test::More tests => 9;

# test 1
BEGIN { use_ok('VSAP::Server::Modules::vsap::user::shell') };

#########################

use VSAP::Server::Test::Account;

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });

# test 2
ok( getpwnam('joefoo'), 'user exists' );

my $vsap = $acctjoefoo->create_vsap(['vsap::user::shell']);
my $t = $vsap->client({ username     => 'joefoo', password     => 'joefoobar'});

# test 3
ok(ref($t), 'created client');

my $de;


# Test 4 --------------------------------------------------
# Happy shell:list
$de = $t->xml_response(qq!<vsap type="user:shell:list" />!);
ok( $de->find('/vsap/vsap[@type="user:shell:list"]'), 'Checking shell list' );
#----------------------------------------------------------

# Test 5  -------------------------------------------------
# Happy test
$de = $t->xml_response(qq!<vsap type="user:shell:change">
  <shell>/bin/tcsh</shell>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="user:shell:change"]'), 'Changing shell');
#----------------------------------------------------------

# Test 6 --------------------------------------------------
## Invalid Shell value 
$de = $t->xml_response(qq!<vsap type="user:shell:change">
  <shell>barfoojoe</shell>
</vsap>!);

like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Invalid shell)i, 'Invalid shell' );
#----------------------------------------------------------

# Test 7 --------------------------------------------------
$acctjoefoo->make_sa;
## Disable Shell value 
$de = $t->xml_response(qq!<vsap type="user:shell:disable">
  <user>joefoo</user>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="user:shell:disable"]/status'), 'ok', 'Disable shell');

## earn our trust, check for nologin
$de = $t->xml_response(qq!<vsap type="user:shell:list">
  <user>joefoo</user>
</vsap>!);

isnt( $de->findvalue('/vsap/vsap[@type="user:shell:list"]/shell[@current=1]/path'), '/bin/tcsh', 'tcsh disabled');
#----------------------------------------------------------


END {
	$acctjoefoo->delete();
	ok(! $acctjoefoo->exists(),'joefoo no longer exists');
}


