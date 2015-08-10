# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VWH-Platform-Info.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('VWH::Platform::Info') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$info = new VWH::Platform::Info;

like($info->get('diskquota'), qr/\d+/, 'disk quota returns a number');
my $hostname = `hostname`;
chomp $hostname;
is($info->get('hostname'),$hostname,"hostname is correct");

like($info->get('vid'), qr/\d+/, 'vid returns a number');
like($info->get('nofile'), qr/\d+/, 'nofile returns a number');
like($info->get('ipaddr'), qr/\d+\.\d+\.\d+\.\d+/, 'ipaddr looks like an ip');
like($info->get('nofilelimit'), qr/\d+/, 'nofilelimit returns a number');
like($info->get('noproc'), qr/\d+/, 'noproc returns a number');
like($info->get('noproclimit'), qr/\d+/, 'noproclimit returns a number');
like($info->get('diskusage'), qr/\d+/, 'diskusage returns a number');
