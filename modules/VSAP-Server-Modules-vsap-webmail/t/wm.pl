#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use blib;
use VSAP::Server::Modules::vsap::webmail ();

unless( scalar @ARGV > 1 ) {
    die "Usage: wm.pl username password\n";
}

my $wm = new VSAP::Server::Modules::vsap::webmail( @ARGV );
my $msgs = $wm->messages_sort();  ## default INBOX

my $uid = 0;
my $msg;
for my $tuid ( @$msgs ) {
    $msg = $wm->message('INBOX', $tuid);
    if( $msg->{subject} =~ 'Verio' ) {
        $uid = $tuid;
        last;
    }
}
die "No message\n" unless $uid;
#print STDERR Dumper $msg;

#exit;

my ($attach, $tmpFilePath, $type) = $wm->message_attachment('INBOX', $uid, '1.2', ".");

print STDERR "Name: $attach, Temp File Location: $tmpFilePath, Type: $type\n";
