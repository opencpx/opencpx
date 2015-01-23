use strict; 
use Test::More;

if( $^O ne 'freebsd' ) {
    plan skip_all => 'Test irrelevant on all but FreeBSD';
} else {
    plan tests => 11;
}



BEGIN { use_ok('VSAP::Server::Sys::Service::Control::FreeBSD::RC'); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test enable on blank file. 
write_file("");
my $rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->enable;
undef $rc;
is(&read_file, "service_enable=\"YES\"", "enable on empty file");

# Test disable on blank file. 
write_file("");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is(&read_file, "service_enable=\"NO\"", "disable on empty file");

# Test enable on file without quotes. 
write_file("service_enable=NO");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->enable;
undef $rc;
is(&read_file, "service_enable=\"YES\"", "enable without quotes.");

# Test enable on file with quotes. 
write_file("service_enable=\"NO\"");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->enable;
undef $rc;
is(&read_file, "service_enable=\"YES\"", "enable with quotes.");

# Test disable on file with quotes. 
write_file("service_enable=\"YES\"");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is(&read_file, "service_enable=\"NO\"", "disable with quotes.");

# Test disable on file without quotes. 
write_file("service_enable=YES");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is(&read_file, "service_enable=\"NO\"", "disable without quotes.");

# Test disable on file with leading spaces
write_file("    service_enable=YES");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is(&read_file, "service_enable=\"NO\"", "disable leading spaces.");

# Test disable on file with leading tabs
write_file("\t\tservice_enable=YES");
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is(&read_file, "service_enable=\"NO\"", "disable leading tabs.");

# Test Comments. 
write_file(<<EOF);
# This is a comment in the file. 
service_enable="YES"
EOF
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(conf => 'test.conf', servicename => 'service');
$rc->disable;
undef $rc;
is((&read_whole_file)[1], "service_enable=\"NO\"\n", "deal with comments.");

# Test the real rc.conf to test
$rc = VSAP::Server::Sys::Service::Control::FreeBSD::RC->new(servicename => 'service');
$rc->disable;
ok(!$rc->is_enabled,"test !is_enabled");
$rc->enable;
ok($rc->is_enabled, "test is_enabled");
undef $rc;

sub read_file {
    open FH, "<test.conf";
    my $data = (<FH>);
    close FH;
    chop $data; 
    return $data;
}

sub read_whole_file { 
    open FH, "<test.conf";
    my @lines = (<FH>);
    close FH;
    return @lines;
}

sub write_file { 
    my $data = shift; 
    open FH, ">test.conf";
    print FH $data;
    close FH;
}


END { 
    unlink "test.conf";
}
