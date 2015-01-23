#!/usr/local/bin/perl -w
use strict;

my $pass = "i8dfj29falk3aa()*";

my $start = shift @ARGV || 1;
my $end   = (@ARGV ? $start + shift : $start + 99);

for my $n ( $start..$end ) {
    print STDERR "\rCreating user $n...";
    system('vadduser', '--quiet', "--login=user_$n", "--fullname=User Number $n", "--home=/home/user_$n", "--password=$pass", "--services=mail,ftp", "--quota=5");
}
print STDERR "\r\n";
