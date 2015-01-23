# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VSAP-Server-Sys-Service-Control.t'

#########################

use Test::More tests => 43;
use strict; 
BEGIN { use_ok('VSAP::Server::Sys::Service::Control') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $service = VSAP::Server::Sys::Service::Control->new;

ok($service->stop('httpd'),"stop httpd");
ok(sleep 15,"waiting for httpd to shutdown..");
ok(!$service->is_running('httpd'),"httpd not running");
ok($service->start('httpd'), "start httpd");
ok(sleep 15,"waiting for httpd to startup..");
ok($service->is_running('httpd'), "httpd running");
ok($service->disable('httpd'), "disable httpd");
ok(!$service->is_enabled('httpd'), "httpd is disabled");
ok($service->enable('httpd'), "enable httpd");
ok($service->is_enabled('httpd'),"httpd is enabled");
ok($service->restart('httpd'),"try to restart httpd");
ok(sleep 15,"waiting for httpd to restart..");
ok($service->is_running('httpd'), "httpd running");

ok($service->disable('sendmail'), "disable sendmail");
ok($service->stop('sendmail'), "stop sendmail");
ok(!$service->is_running('sendmail'), "sendmail is stopped");
ok($service->enable('sendmail'), "enable sendmail");
ok($service->start('sendmail'), "start sendmail");
ok($service->is_running('sendmail'),"sendmail is running");
ok($service->disable('sendmail'), "disable sendmail");
ok(!$service->is_enabled('sendmail'), "sendmail is disabled");
ok($service->enable('sendmail'), "enable sendmail");
ok($service->is_enabled('sendmail'),"sendmail is enabled");

ok($service->stop('inetd'), "stop inetd");
ok(!$service->is_running('inetd'), "inetd is stopped");
ok($service->start('inetd'), "start inetd");
ok($service->is_running('inetd'),"inetd is running");
ok($service->disable('inetd'), "disable inetd");
ok(!$service->is_enabled('inetd'), "inetd is disabled");
ok($service->enable('inetd'), "enable inetd");
ok($service->is_enabled('inetd'),"inetd is enabled");
ok(!$service->start('inetd'),"try to start inetd again");

SKIP: {
    skip "mysqld not available",10
    	unless (grep (/mysqld/, $service->available_services));

    ok($service->stop('mysqld'), "stop mysqld");
    ok(sleep 1,"waiting for mysql to stop");
    ok(!$service->is_running('mysqld'), "mysqld is stopped");
    ok($service->start('mysqld'), "start mysqld");
    ok(sleep 1,"waiting for mysql to start");
    ok($service->is_running('mysqld'),"mysqld is running");
    ok($service->disable('mysqld'), "disable mysqld");
    ok(!$service->is_enabled('mysqld'), "mysqld is disabled");
    ok($service->enable('mysqld'), "enable mysqld");
    ok($service->is_enabled('mysqld'),"mysqld is enabled");
}
