#!/usr/bin/perl

use strict;
use warnings;

# set current working directory
my $basedir = $0;
$basedir =~ s/[^\/]+$//g;
$basedir =~ s#(.*)/utils/(.*)#$1/utils#;
$basedir = "." if ($basedir eq "");
chdir("$basedir/..");

if (open(PIPE, "find modules -name \*.pm |")) {
    while (<PIPE>) {
        next if (/blib/);
        next if (/deprecated/);
        my $gitpath = $_;
        chomp($gitpath);
        $gitpath =~ m#(/lib/.*pm$)#;
        my $libpath = "/usr/local/cp" . $1;
        $gitpath =~ m#/([^/]*)$#;
        my $filename = $1;
        next unless (-e "$libpath");
        # get cksum
        my $git_cksum = _get_cksum($gitpath);
        my $lib_cksum = _get_cksum($libpath);
        if ($git_cksum ne $lib_cksum) {
            print "cksum mismatch for $filename:\n";
            print "     git cksum is $git_cksum ($gitpath)\n";
            print "     lib cksum is $lib_cksum ($libpath)\n\n";
        }
    }
    close(PIPE);
}
else {
    print $!;
}

##############################################################################

sub _get_cksum
{
  my $path = shift;

  my $cksum = `cksum $path`;
  ($cksum) = (split(/ /, $cksum))[0];
  return($cksum);
}

##############################################################################
# eof

