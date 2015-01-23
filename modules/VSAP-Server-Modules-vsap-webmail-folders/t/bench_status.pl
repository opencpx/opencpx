#!/usr/bin/perl -w
use strict;

use VSAP::Server::Modules::vsap::config ();
use VSAP::Server::Modules::vsap::mail::clamav ();
use VSAP::Server::Modules::vsap::mail::spamassassin ();

use Benchmark;

my $user = 'thursday';
local $> = getpwnam($user);

my($csa, $ccl) = f_config();
my($nsa, $ncl) = f_status();

print STDERR "config: $csa, $ccl\n";
print STDERR "status: $nsa, $ncl\n";

## Er, fairly conclusive...
##
## Benchmark: timing 5000 iterations of config, status...
##  config: 72 wallclock secs (59.42 usr + 11.89 sys = 71.31 CPU) @ 70.11/s (n=5000)
##  status:  2 wallclock secs ( 0.95 usr +  1.04 sys =  1.98 CPU) @ 2519.69/s (n=5000)
##

timethese 5_000, {
                  config  => q( f_config() ),
                  status  => q( f_status() ),
                 };
exit;

sub f_config {
    my $conf = new VSAP::Server::Modules::vsap::config( username => $user);
    my $sa   = $conf->service('mail-spamassassin');
    my $cl   = $conf->service('mail-clamav');

    return ($sa, $cl);
}

sub f_status {
    my $sa = (VSAP::Server::Modules::vsap::mail::spamassassin::nv_status() eq 'on' ? 1 : 0);
    my $cl = (VSAP::Server::Modules::vsap::mail::clamav::nv_status()       eq 'on' ? 1 : 0);
    return ($sa, $cl);
}
