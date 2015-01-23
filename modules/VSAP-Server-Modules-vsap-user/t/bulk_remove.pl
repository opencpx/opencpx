#!/usr/local/bin/perl -w
use strict;

my $start = shift @ARGV || 1;
my $end   = (@ARGV ? $start + shift : $start + 99);

for my $n ( $start..$end ) {
    print STDERR "Removing user $n...\n";
    system('vrmuser', '-y', "user_$n");
}
