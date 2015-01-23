use Test::More no_plan;          # No plan since the list of services comes from the module which could be different
			 	 # on different platforms.

BEGIN { 
	use_ok('VSAP::Server::Modules::vsap::sys::inetd');
	use_ok('VSAP::Server::Test::Account');
};

use File::Copy;

#########################

my $ACCT = VSAP::Server::Test::Account->create({ type => 'account-owner' });

ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::inetd']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

# First obtain a list of all services from the module status response. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"/>!);
my @services = map { $_->nodeName } $resp->findnodes('/vsap/vsap[@type=\'sys:inetd:status\']/*');

# Next set all the services to a known state. 
foreach my $service (@services) { 
	$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:enable"><$service/></vsap>!);
	ok($resp->findnodes("/vsap/vsap[\@type='sys:inetd:enable']/$service"),"enable response contains $service node.")
		|| diag $resp->toString(1);
}

# Loop through each service, first obtaining its status, disabling the service, 
# checking status, enabling the service, checking status

foreach my $service (@services) { 
    # First we obtain the status on this service. Should be enabled from above. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"><$service/></vsap>!);

    is($resp->findvalue("/vsap/vsap[\@type='sys:inetd:status']/$service/status"),"enabled","confirm $service is enabled.")
	|| diag $resp->toString(1);

    # Now we disable it, confirm the disable response. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:disable"><$service/></vsap>!);

    ok($resp->findnodes("/vsap/vsap[\@type='sys:inetd:disable']/$service"),"disable response contains $service.")
	|| diag $resp->toString(1);

    # Request the status again, confirm disabled. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"><$service/></vsap>!);

    is($resp->findvalue("/vsap/vsap[\@type='sys:inetd:status']/$service/status"),"disabled","confirm $service is disabled.")
	|| diag $resp->toString(1);

    # Now enable the service, confirm enable response. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:enable"><$service/></vsap>!);

    ok($resp->findnodes("/vsap/vsap[\@type='sys:inetd:enable']/$service"),"enable response contains $service.")
	|| diag $resp->toString(1);

    # Request the status again, confirm enabled. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"><$service/></vsap>!);

    is($resp->findvalue("/vsap/vsap[\@type='sys:inetd:status']/$service/status"),'enabled',"confirm $service is enabled.")
	|| diag $resp->toString(1);
}

## Test invalid service name error conditions. 

# Test invalid service name on status. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"><unknownservice/></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:status']/code"),100,"unknown service on status.")
	|| diag $resp->toString(1);

$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:enable"><unknownservice/></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:enable']/code"),100,"unknown service on enable.")
	|| diag $resp->toString(1);

$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:disable"><unknownservice/></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:disable']/code"),100,"unknown service on disable.")
	|| diag $resp->toString(1);

SKIP: { 
	skip "linux doesn't used inetd.conf", 3 if $ENV{VST_PLATFORM} eq 'LVPS2';

	# Test for missing inetd. 
	move "/etc/inetd.conf", "/etc/inetd.conf.$$";

	$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:status"/>!);
	is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:status']/code"),101,"unable to read conf on status.")
		|| diag $resp->toString(1);

	$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:disable"><ftp/></vsap>!);
	is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:disable']/code"),101,"unable to read conf on disable")
		|| diag $resp->toString(1);

	$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:enable"><ftp/></vsap>!);
	is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:enable']/code"),101,"unable to read conf on enable")
		|| diag $resp->toString(1);

	move "/etc/inetd.conf.$$", "/etc/inetd.conf";
}

$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:disable"/>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:disable']/code"),103,"missing services on disable")
	|| diag $resp->toString(1);

$resp = $CLIENT->xml_response(qq!<vsap type="sys:inetd:enable"/>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:enable']/code"),103,"missing services on enable")
	|| diag $resp->toString(1);

# Test for authz 

my $ACCT_EU = VSAP::Server::Test::Account->create({ type => 'end-user', username => 'joeenduser' });
ok($ACCT_EU->exists,"end-user account exists");

my $CLIENT_EU = $VSAP->client({ acct => $ACCT_EU });
ok($CLIENT_EU, "client for end-user exists.");

$resp = $CLIENT_EU->xml_response(qq!<vsap type="sys:inetd:disable"><ftp/></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:disable']/code"),104,"authz failed on disable.")
	|| diag $resp->toString(1);

$resp = $CLIENT_EU->xml_response(qq!<vsap type="sys:inetd:enable"><ftp/></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:inetd:enable']/code"),104,"authz failed on enable.")
	|| diag $resp->toString(1);
