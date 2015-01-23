use Test::More tests => 10;

BEGIN { 
	use_ok('VSAP::Server::Test::Account');
};

#########################

my $ACCT = VSAP::Server::Test::Account->create({ type => 'account-owner' });

ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::info']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

## Test for invalid attribute. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:info:get"><some_unknown_field/></vsap>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:info:get']/code"),'==',102, 'unknown field.')
    || diag $resp->toString(1);

## Test for just one field. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:info:get"><nofile/></vsap>!);
my $nodes = $resp->findnodes("/vsap/vsap[\@type = 'sys:info:get']/*");
cmp_ok($nodes->size,'==',1,'returned just the nofile field')
    || diag $resp->toString(1);

### Get all fields. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:info:get"/>!);
$nodes = $resp->findnodes("/vsap/vsap[\@type = 'sys:info:get']/*");
cmp_ok($nodes->size,'==',9,'returned all fields')
    || diag $resp->toString(1);

my $ACCT_EU = VSAP::Server::Test::Account->create({ type => 'end-user', username => 'joeenduser' });
ok($ACCT_EU, "able to create end user account");
my $CLIENT_EU = $VSAP->client({ acct => $ACCT_EU });
ok($CLIENT_EU, "able to create a vsap client authenticated with end user");

$resp = $CLIENT_EU->xml_response(qq!<vsap type="sys:info:get"/>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:info:get']/code"),'==',100, "not authorized to obtain info info")
        || diag $resp->toString(1);
