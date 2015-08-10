# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VWH-Platform-Info.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
if( $^O ne 'linux' ) {
    plan skip_all => 'Test irrelevant unless on Linux';
} else {
    plan tests => 2;
}

BEGIN { use_ok('VWH::Platform::Info') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$info = new VWH::Platform::Info;

is(ref($info),'VWH::Platform::Info::Linux', "obtained a linux object");
@fields = $info->fields();
@FIELDS = qw/login hostname ipaddr vid nofile nofilelimit noproc noproclimit diskusage nofilebarrier noprocbarrier server diskquota/;

ok( eq_set(\@fields, \@FIELDS), "fields are all there" );
