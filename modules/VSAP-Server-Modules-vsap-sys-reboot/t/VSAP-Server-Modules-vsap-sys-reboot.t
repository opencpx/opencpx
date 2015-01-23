use Test::More tests => 9; 

BEGIN { 
	use_ok('VSAP::Server::Modules::vsap::sys::reboot');
	use_ok('VSAP::Server::Test::Account');
};

#########################

my $ACCT = VSAP::Server::Test::Account->create({ type => 'end-user' });
ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::reboot']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

# Cause a reboot, should fail with not authorized. 
$resp = $CLIENT->xml_response(qq!<vsap type='sys:reboot'/>!);

# Confirm error response. 
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:reboot']/code"),"100","confirm not authorized response.")
	|| diag $resp->toString(1);

SKIP: { 
	skip "not actually rebooting box unless DOREBOOT environment variable is set", 3
		unless ($ENV{DOREBOOT});

	my $ACCT_O = VSAP::Server::Test::Account->create({ type => 'account-owner', username => 'joeaccountowner' });
	ok($ACCT_O->exists, "Account exists for account owner.");
	
	my $CLIENT_O = $VSAP->client({ acct => $ACCT_O });
	ok($CLIENT_O,"able to obtain vsap client connection");
	
	# Cause a reboot, should fail with not authorized. 
	$resp = $CLIENT_O->xml_response(qq!<vsap type='sys:reboot'/>!);
	ok($resp->findValue("/vsap/vsap[@type='sys:reboot']"), "reboot returned.");
}

# We will never get here. 
