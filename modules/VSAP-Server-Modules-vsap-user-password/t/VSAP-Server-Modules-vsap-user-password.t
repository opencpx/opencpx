use Test::More tests => 9;

use Data::Dumper;

# test 1
BEGIN { use_ok('VSAP::Server::Modules::vsap::user::password') };
BEGIN { use_ok('VSAP::Server::Test::Account') };

#########################

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });

# test 2
ok( getpwnam('joefoo'), 'New user exists' );

my $vsap = $acctjoefoo->create_vsap(['vsap::user::password']);
my $t = $vsap->client({ username     => 'joefoo', password     => 'joefoobar'}); 

# test 3
ok(ref($t), 'Created vsap client');

my $de;

# test 4 
## happy test
$de = $t->xml_response(qq!<vsap type="user:password:change">
  <new_password>barfoojoe</new_password>
  <new_password2>barfoojoe</new_password2>
</vsap>!);

ok( $de->find('/vsap/vsap[@type="user:password:change"]'), 'Successfully changed password' );


# test 5
## New password not specified
$de = $t->xml_response(qq!<vsap type="user:password:change">
  <new_password></new_password>
  <new_password2></new_password2>
</vsap>!);

like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(New password not entered)i );


# test 6
## New password mismatch
$de = $t->xml_response(qq!<vsap type="user:password:change">
  <new_password>barfoojoe</new_password>
  <new_password2>barfoojoemis</new_password2>
</vsap>!);

like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(New passwords do not match)i );

# test 7 
## New password mismatch
$de = $t->xml_response(qq!<vsap type="user:password:change">
  <new_password>barfoojoethisisalongpassword</new_password>
  <new_password2>barfoojoethisisalongpassword</new_password2>
</vsap>!);

ok( $de->find('/vsap/vsap[@type="user:password:change"]'), 'Successfully changed password' );

$t->quit;

# test 8
my $t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>barfoojoethis</password></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(login failed)i, "failed to login with this shorter password" );
