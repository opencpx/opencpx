use Test::More tests => 16;

BEGIN { 
	use_ok('VSAP::Server::Modules::vsap::sys::timezone');
	use_ok('VSAP::Server::Test::Account');
};

use File::Copy;

BEGIN { 

`mv /etc/localtime /etc/localtime.$$`
    if (-e '/etc/localtime');
}

my $ACCT = VSAP::Server::Test::Account->create({ type => 'account-owner' });

ok($ACCT->exists, "Account exists");

my $VSAP = $ACCT->create_vsap(['vsap::sys::timezone']);
ok($VSAP,"able to create vsap server");

my $CLIENT = $VSAP->client({ acct => $ACCT });
ok($CLIENT,"able to obtain vsap client connection");

## Test for missing timezone element. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:set"/>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:timezone:set']/code"),'==',101, "missing timezone element")
    || diag $resp->toString(1);

## Test for invalid characters in timezone. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:set"><timezone>America/../New_York</timezone></vsap>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:timezone:set']/code"),'==',100, "invalid characters in timezone.")
    || diag $resp->toString(1);

## Test for invalid timezone
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:set"><timezone>America/Nowhere</timezone></vsap>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:timezone:set']/code"),'==',100, "invalid timezone specified.")
    || diag $resp->toString(1);

## Set the time zone to New_York.
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:set"><timezone>America/New_York</timezone></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='sys:timezone:set']/timezone"),'America/New_York', "timezone set response is correct")
    || diag $resp->toString(1);

## Get the time zone and confirm that it is set to New York. 
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:get"/>!);
is($resp->findvalue("/vsap/vsap[\@type='sys:timezone:get']/timezone"),'America/New_York', "get returns correct timezone") 
	|| diag $resp->toString(1);

unlink ("/etc/localtime");

$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:get"/>!);
is($resp->findvalue("/vsap/vsap[\@type='sys:timezone:get']/timezone"),'GMT', "timezone get response is correct when no file")
    || diag $resp->toString(1);

open FH, '>/etc/localtime';
close FH;
chmod 0, '/etc/localtime';

$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:get"/>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:timezone:get']/code"),'==',103, "/etc/localtime does not exist.")
    || diag $resp->toString(1);

unlink ("/etc/localtime");

## Set the time zone back to New_York.
$resp = $CLIENT->xml_response(qq!<vsap type="sys:timezone:set"><timezone>America/New_York</timezone></vsap>!);
is($resp->findvalue("/vsap/vsap[\@type='sys:timezone:set']/timezone"),'America/New_York', "timezone set response is correct")
    || diag $resp->toString(1);

## Try and set the timezone from an end-user account. This should return an unauthorized response. 

my $ACCT_EU = VSAP::Server::Test::Account->create({ type => 'end-user', username => 'joeenduser' });
ok($ACCT_EU, "able to create end user account");
my $CLIENT_EU = $VSAP->client({ acct => $ACCT_EU });
ok($CLIENT_EU, "able to create a vsap client authenticated with end user");

## Set the time zone back to New_York.
$resp = $CLIENT_EU->xml_response(qq!<vsap type="sys:timezone:set"><timezone>America/New_York</timezone></vsap>!);
cmp_ok($resp->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:timezone:set']/code"),'==',104, "not authorized to set timezone")
     || diag $resp->toString(1);


END { 

`rm /etc/localtime`
    if (-e "/etc/localtime");

`mv /etc/localtime.$$ /etc/localtime`
    if (-e "/etc/localtime.$$");
}
