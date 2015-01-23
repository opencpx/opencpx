#!/usr/local/bin/perl -w
use strict;

## benchmark tests
##
## this file is not run automatically but is included in the suite for
## the curious. This was written to gauge the difference between when 
## caching is enabled and when it is disabled.
##

use blib;

use Benchmark;
use VSAP::Server::Modules::vsap::config;

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up a user
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    print STDERR "Creating user...\n";
    system( 'vadduser --quiet --login=joefoo --password=joefoobar --home=/home/joefoo --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joefoo'\n";
    print STDERR "Promoting user to SA...\n";
    system('pw', 'groupmod', '-n', 'wheel', '-m', 'joefoo');  ## make us an administrator
}

my $tests = shift @ARGV || 50;

## benchmark uncached operation
print STDERR "Benchmarking uncached operation...\n";
$VSAP::Server::Modules::vsap::config::DISABLE_CACHING = 1;
my $time = timeit $tests, sub {
    my $co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
    $co->platform_refresh;
    my $users = $co->users;
    undef $co;
};
print STDERR "$tests loops (no caching) took: ", timestr($time, 'noc'), "\n";  ## no children
undef $time;


## benchmark cached operation
print STDERR "Benchmarking cached operation...\n";
$VSAP::Server::Modules::vsap::config::DISABLE_CACHING = 0;
$time = timeit $tests, sub {
    my $co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
    $co->platform_refresh;
    my $users = $co->users;
    undef $co;
};
print STDERR "$tests loops (caching) took: ", timestr($time, 'noc'), "\n";  ## no children
undef $time;


END {
    print STDERR "Cleaning up...\n";
    getpwnam('joefoo')      && system q(vrmuser -y joefoo 2>/dev/null);
}
