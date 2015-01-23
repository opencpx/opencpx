use Test::More tests => 9;

BEGIN { use_ok( 'VSAP::Client'); }

use VSAP::Server::Test;
use utf8;

$vsapd = new VSAP::Server::Test({ standalone => 1 });

$client = $vsapd->client({ autoauth => 0 });

my $real_client = $client->{client};

ok(ref($real_client),"was able to create client");
like($real_client->response->toString,"/OK/", "Obtained greeting.");
like($real_client->send("<vsap/>"),"/\<vsap\/\>/", "send null request one tag");
like($real_client->send("<vsap test='100男無頼庵'/>"),"/\<vsap\/\>/", "send null request one tag");
like($real_client->send("<vsap></vsap>"),"/\<vsap\/\>/", "send null request opening and closing tags.");
like($real_client->send("<vsap><vsap></vsap></vsap>"),"/\<vsap\/\>/", "send null request opening and closing tags.");

## vsapd disconnects now on invalid calls:
#like($real_client->send("<vsap><vsap type='invalid'/></vsap>"),"/No such module/","issue request.");
#like($real_client->send("<vsap><vsap type='invalid'/><vsap type='otherinvalid'/></vsap>"),
#	"/No such module vsap::otherinvalid/","issue multiple requests.");

$vsapd->shutdown;
ok(sleep 3,"Waiting for vsapd server to shutdown");
$resp = $real_client->send("<vsap><vsap type='sending:command:request'/></vsap>");
ok(!defined($resp));
