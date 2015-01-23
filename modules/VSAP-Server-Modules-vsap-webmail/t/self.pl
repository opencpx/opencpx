#!/usr/bin/perl -w
use strict;

use blib;
use VSAP::Server::Modules::vsap::webmail ();
use Data::Dumper;

print STDERR "user: ";
my $user = <STDIN>; chomp $user;
print STDERR "password: ";
my $pass = <STDIN>; chomp $pass;

print STDERR "Connecting...";
my $wm = new VSAP::Server::Modules::vsap::webmail($user, $pass, 'readonly');
print STDERR "done.\n";

#my $msg = do_wm($wm);
#print STDERR Dumper $msg;

print STDERR "Running loop...";
for (1..25) {
    do_wm($wm);
    print STDERR ".";
}
print STDERR "done.\n";

exit;

sub do_wm {
    my $wm = shift;
    my @folders = sort keys %{$wm->folder_list};
    my $status = $wm->folder_status($folders[3]);

    my $msgs = $wm->messages_sort('INBOX');
    my $a_uid = 0;
    my $msg;
    for my $uid ( @$msgs ) {
        $msg = $wm->message('INBOX', $uid);
        if( $msg->{subject} eq '10m attachment' ) {
            $a_uid = $uid;
        last;
        }
    }

    return $msg;
}
