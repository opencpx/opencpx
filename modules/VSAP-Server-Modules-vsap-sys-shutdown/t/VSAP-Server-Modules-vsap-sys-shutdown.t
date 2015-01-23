use Test::More tests => 9; 

BEGIN { 
	use_ok('VSAP::Server::Modules::vsap::sys::shutdown');
	use_ok('VSAP::Server::Test::Account');
};

#########################

my $ACCT = VSAP::Server::Test::Account->create({ type => 'end-user' });
ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::shutdown']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

# Cause a shutdown, should fail with not authorized. 
$resp = $CLIENT->xml_response(qq!<vsap type='sys:shutdown'/>!);

# Confirm error response. 
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:shutdown']/code"),"100","confirm not authorized response.")
	|| diag $resp->toString(1);

SKIP: { 
	skip "not actually shutdown box unless DOSHUTDOWN environment variable is set", 3
		unless ($ENV{DOSHUTDOWN});

	my $ACCT_O = VSAP::Server::Test::Account->create({ type => 'account-owner', username => 'joeaccountowner' });
	ok($ACCT_O->exists, "Account exists for account owner.");
	
	my $CLIENT_O = $VSAP->client({ acct => $ACCT_O });
	ok($CLIENT_O,"able to obtain vsap client connection");
	
	# Cause a shutdown, should fail with not authorized. 
	$resp = $CLIENT_O->xml_response(qq!<vsap type='sys:shutdown'/>!);
	ok($resp->findValue("/vsap/vsap[@type='sys:shutdown']"), "shutdown returned.");
}

# We will never get here. 
