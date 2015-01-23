use strict; 
use Test::More;
use File::Copy;

BEGIN { 

if( $^O ne 'linux' ) {
    plan skip_all => 'Test irrelevant on all but Linux';
} else {
    plan tests => 5;
}

use_ok('VSAP::Server::Sys::Service::Control::Linux::RC');

    open FH, '>','/etc/init.d/test' || die "unable to create test file";
    print FH<<EOF;
#!/bin/bash
#
# test          this shell script is for testing startup
#
#
#
# chkconfig: - 80 30
# description: hello
# processname: test 
# config: /etc/test.cf
# pidfile: /var/run/test.pid
EOF
    close FH;

    system('/sbin/chkconfig --add test') && die "unable to add test to chkconfig";
    system('/sbin/chkconfig test reset') && die "unable to reset chkconfig";
};


# Test enable for test service. 
my $rc = VSAP::Server::Sys::Service::Control::Linux::RC->new(script => '/etc/init.d/test', servicename => 'test');
$rc->enable;
ok($rc->is_enabled, "is enabled");
$rc->disable;
ok(!$rc->is_enabled, "is disabled");
ok($rc->is_available, "is available");
move '/etc/init.d/test', '/etc/init.d/test.old';
ok(!$rc->is_available, "is not available");
move '/etc/init.d/test.old', '/etc/init.d/test';

END { 
    system('/sbin/chkconfig --del test') && die "unable to delete test from chkconfig";
    unlink '/etc/init.d/test';
}
