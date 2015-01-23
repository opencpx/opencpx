#!/usr/bin/perl -w
use strict;

use blib;
use Benchmark;
use VSAP::Server::Modules::vsap::config;

my $tests = shift @ARGV || 5000;
my $time = timeit $tests, sub {
    my $co = new VSAP::Server::Modules::vsap::config(username => 'thursday');
    $co->{is_dirty} = 1;
    undef $co;
};

print STDERR "$tests loops (caching) took: ", timestr($time, 'noc'), "\n";
