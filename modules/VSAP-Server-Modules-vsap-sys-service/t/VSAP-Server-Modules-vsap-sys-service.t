use Test::More tests => 32;

BEGIN { 
	use_ok('VSAP::Server::Modules::vsap::sys::service');
	use_ok('VSAP::Server::Test::Account');
};
use File::Copy;
use Data::Dumper;

#########################

my $ACCT = VSAP::Server::Test::Account->create({ type => 'account-owner' });

ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::service']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

my $ACCT_EU = VSAP::Server::Test::Account->create({ type => 'end-user', username => 'joeenduser' });
ok($ACCT_EU->exists,"end-user account exists");
my $CLIENT_EU = $VSAP->client({ acct => $ACCT_EU });

# Here, we are really only testing the glue between the vsap module and VSAP::Server::Sys::Service::Control.
# The tests for the starting/stopping of each module happens in the test suite for Sys::Service::Control. 
# So, here we do minimal testing and just on the httpd service, since we know that will be there. 

# First, lets stop apache. 
my $resp = $CLIENT->xml_response(qq!<vsap type="sys:service:stop"><httpd/></vsap>!);
ok($resp->findnodes("/vsap/vsap[\@type = 'sys:service:stop']/httpd"),"httpd stopped.");

sleep 10;

# Obtain status on the httpd service.
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:status"/>!);
is($resp->findvalue("/vsap/vsap[\@type = 'sys:service:status']/httpd/running"),'false', "found httpd not running");

# Start apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:start"><httpd/></vsap>!);
ok($resp->findnodes("/vsap/vsap[\@type = 'sys:service:start']/httpd"),"httpd started.");

sleep 10;

# Obtain status on apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:status"/>!);
is($resp->findvalue("/vsap/vsap[\@type = 'sys:service:status']/httpd/running"),'true', "found httpd running");

# Restart apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:restart"><httpd/></vsap>!);
ok($resp->findnodes("/vsap/vsap[\@type = 'sys:service:restart']/httpd"), "httpd restarted. ");

sleep 30; 

# Obtain status on apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:status"/>!);
is($resp->findvalue("/vsap/vsap[\@type = 'sys:service:status']/httpd/running"),'true', "httpd running after restart");

# Disable httpd
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:disable"><httpd/></vsap>!);
ok($resp->findnodes("/vsap/vsap[\@type = 'sys:service:disable']/httpd"), "httpd disabled");

# Obtain status on apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:status"/>!);
is($resp->findvalue("/vsap/vsap[\@type = 'sys:service:status']/httpd/enabled"),'false', "httpd not enabled");

# Enable httpd
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:enable"><httpd/></vsap>!);
ok($resp->findnodes("/vsap/vsap[\@type = 'sys:service:enable']/httpd"), "httpd enabled");

# Obtain status on apache. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:service:status"/>!);
is($resp->findvalue("/vsap/vsap[\@type = 'sys:service:status']/httpd/enabled"),'true', "httpd now enabled");

foreach $action ('stop','start','restart','enable','disable','status') { 

    # Provide unknown service. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:service:$action"><unknown/></vsap>!);
    is($resp->findvalue("/vsap/vsap[\@type='error' and  \@caller = 'sys:service:$action']/code"),101, "$action with unknown service.");

    next 
	if ($action eq 'status');

    # Unauthorized user. 
    $resp = $CLIENT_EU->xml_response(qq!<vsap type="sys:service:$action"><httpd/></vsap>!);
    is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller = 'sys:service:$action']/code"),100, "$action unauthorized user.");

    # No services at all, but we skip status. 
    $resp = $CLIENT->xml_response(qq!<vsap type="sys:service:$action"/>!);
    is($resp->findvalue("/vsap/vsap[\@type='error' and \@caller = 'sys:service:$action']/code"),103, "$action no services.");
}
