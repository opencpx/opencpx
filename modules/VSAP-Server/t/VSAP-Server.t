use Test::More tests => 14;

use lib '/usr/local/cp/lib/';

use POSIX;
use VSAP::Server;

ok(1, "module loaded");
my $server = new VSAP::Server;
ok($server, "object instantiated");
## for the platform, we're going to require that only one of these work.
is($server->is_linux + $server->is_freebsd4 + $server->is_freebsd6, 1, "just one OS");
is($server->is_signature + $server->is_vps2, 1, "just one platform");

diag("We're not really testing the platform, just doing some sanity checks here.");

## affirm platform to OS
if($server->is_signature) {
  ok($server->is_freebsd4, "Signature is properly FreeBSD 4");
}
if($server->is_vps2) {
  is($server->is_freebsd4 + $server->is_freebsd6 + $server->is_linux, 1, "VPS2 is either FreeBSD 4 or 6 or Linux");
}

## affirm OS to platform
if($server->is_freebsd4) {
  is($server->is_vps2 + $server->is_signature, 1, "FreeBSD4 is a VPS2 or Signature");
}

if($server->is_freebsd6) {
  ok($server->is_vps2, "FreeBSD6 is a VPS2");
}

if($server->is_linux) {
  ok($server->is_vps2, "Linux is a VPS2");
}

## negate the wrong platform and/or OS
if($server->is_vps2) {
  ok(!$server->is_signature, "VPS2 is not Signature");
}

if($server->is_signature) {
  ok(!$server->is_vps2 && !$server->is_linux, "Signature is not VPS2 or Linux");
}

if($server->is_linux) {
  ok(!$server->is_signature && !$server->is_freebsd4 && !$server->is_freebsd6, "Linux is not Signature or FreeBSD");
}

if($server->is_freebsd6) {
  ok(!$server->is_signature && !$server->is_linux, "FreeBSD 6 is not Signature or Linux");
}

if($server->is_freebsd4) {
  ok(!$server->is_linux && !$server->is_freebsd6, "FreeBSD 4 is not Linux or FreeBSD 6");
}

## confirm os and platform match

my $os = (POSIX::uname())[0];
SKIP: {
    if ($os =~ /Linux/i) {
        ok($server->is_linux, "os is Linux");
        ok(!$server->is_freebsd4, "os is not FreeBSD 4");
        ok(!$server->is_freebsd6, "os is not FreeBSD 6");
        ok($server->is_vps2, "platform is VPS2");
        ok(!$server->is_signature, "platform is not Signature");
    } elsif ($os =~ /FreeBSD/i) {
        my $version = (POSIX::uname())[2];
        if ($version =~ /^4/) {
            ok($server->is_freebsd4, "os is FreeBSD 4");
            ok(!$server->is_freebsd6, "os is not FreeBSD 6");
            ok(!$server->is_linux, "os is not Linux");
        } elsif ($version =~ /^6/) {
            ok($server->is_freebsd6, "os is FreeBSD 6");
            ok(!$server->is_freebsd4, "os is not FreeBSD 4");
            ok(!$server->is_linux, "os is not Linux");
        } else {
            skip "os version not supported", 3; 
        }
        if (-d '/skel') {
            ok($server->is_vps2, "platform is VPS2");
            ok(!$server->is_signature, "platform is not Signature");
        } else {
            ok($server->is_signature, "platform is Signature");
            ok(!$server->is_vps2, "platform is not VPS2");
        }
    } else {
        skip "os type not supported", 5; 
    }
}

## confirm release

SKIP: {
    skip "release file not found", 1
        unless (-e '/usr/local/cp/RELEASE');
    my $rel = `cat /usr/local/cp/RELEASE`;
    chomp $rel;
    is($VSAP::Server::RELEASE, $rel, "release set as expected");
}

