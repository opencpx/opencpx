# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VSAP-Client-Config.t'

#########################

use Test::More tests => 4;
use VSAP::Client::Config qw/ $VSAP_CLIENT_MODE $VSAP_CLIENT_TCP_PORT $VSAP_CLIENT_TCP_HOST $VSAP_CLIENT_UNIX_SOCKET_PATH /;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok($VSAP_CLIENT_MODE);
ok($VSAP_CLIENT_TCP_PORT);
ok($VSAP_CLIENT_TCP_HOST);
ok($VSAP_CLIENT_UNIX_SOCKET_PATH);

