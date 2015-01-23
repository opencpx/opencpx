use Test::More;
BEGIN { plan tests => 5 };
use VSAP::Server::Test::Account;
use VSAP::Server::Modules::vsap::auth;
use VSAP::Server::Modules::vsap::user::prefs;

## NOTE: this test file exists only to exploit a bug in
## VSAP::Server::Test (or auth.pm--not sure where precisely). A
## session key is kept from the previous object instance (probably by
## way of a static class variable). When the bug is fixed, all tests
## in this file (2) should pass.

## test setup
######################################################################
##
my $cpx_config   = "_cpx.$$.conf";

rename "/usr/local/etc/cpx.conf", "/usr/local/etc/$cpx_config"
  if -e "/usr/local/etc/cpx.conf";

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefooson = VSAP::Server::Test::Account->create( { username => 'joefooson', fullname => 'Joe Foo Son', password => 'joefoosonbar' });

ok( $acctjoefoo->exists(), "joefoo exists");
ok( $acctjoefooson->exists(), "joefooson exists");

##
######################################################################

##
## login with normal auth; get session key
##
my $vsap = $acctjoefoo->create_vsap(['vsap::user::prefs']);

my $t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth">
  <username>joefoo</username>
  <password>joefoobar</password>
</vsap>!);
my $session = $de->findvalue('/vsap/vsap[@type="auth"]/sessionkey');

##
## login with session key
##
$t->quit; 
undef $t;

$t = $vsap->client({ sessionkey   => $session });

##
## login as new user
##
$t->quit; 
undef $t;
$t = $vsap->client({ username => 'joefooson', password => 'joefoosonbar' } );
is( $t->sessionkey, undef, "empty session key" );

END {
	$acctjoefoo->delete();
	ok( ! $acctjoefoo->exists(), 'User joefoo was removed');
	$acctjoefooson->delete();
	ok( ! $acctjoefooson->exists(), 'User joefooson was removed');
    unlink '/usr/local/etc/cpx.conf';
    rename "/usr/local/etc/$cpx_config", "/usr/local/etc/cpx.conf" if -e "/usr/local/etc/$cpx_config";
}
