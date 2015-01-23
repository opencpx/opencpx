#!/usr/bin/perl -w
use strict;

## Scott Wiersdorf
## Created: Fri Oct  7 13:49:51 GMT 2005
## $SMEId: vps2/user/local/cpx/modules/VSAP-Server-Modules-vsap-config/t/stress.pl,v 1.1 2005/10/28 17:30:16 scottw Exp $

## stress tests for CPX

use LWP::UserAgent;
use XML::LibXML;
use VSAP::Server::Modules::vsap::mail::addresses ();

##
## change these
##
my $domain      = `sinfo -h`; chomp $domain;
my $user        = shift @ARGV || `sinfo -a`; chomp $user;
my $password    = '';
my $page        = 'cp/users/index.xsl';
##
## end of changes
##

print STDERR "Using '$user' and '$domain' for authentication.\n";

GET_PASSWORD: {
    print STDERR "Password: ";
    system('stty', '-echo');
    $password = <STDIN>;
    print STDERR "\n";
    system('stty', 'echo');
}

chomp $password;

die "No password supplied. Quitting.\n" unless $password;

my $ua = LWP::UserAgent->new;
$ua->agent("E2E-Bench/0.1 ");

my $req = HTTP::Request->new(POST => "https://$domain/ControlPanel/$page");
$req->content_type('application/x-www-form-urlencoded');
$req->content("username=$user&password=$password");

my $pattern = '';
{
    print STDERR "Getting pattern...";
    local $/;
    $pattern = <DATA>;
    $pattern =~ s{\$user}{$user}g;
    $pattern =~ s{\$domain}{$domain}g;
    print STDERR "done.\n";
}
die "Could not find pattern!\n" unless $pattern;

my $quit = 0;
my %Childs = ();

$SIG{INT} = $SIG{TERM} = sub {
    $quit = 1;
    print STDERR " <INT/TERM caught> ";
    for my $pid ( keys %Childs ) {
        print STDERR "Killing $pid\n";
        kill 'TERM' => $pid;
    }
};

## fork a 'toucher': this causes config.pm to re-read the /etc/passwd
## file and update its cache. Herein lies the race condition, though
## anything that causes config.pm to rewrite cpx.conf would do.
if( my $pid = fork() ) {
    print STDERR "Adding $pid for toucher\n";
    $Childs{$pid} = 1;
}
else {
    while( ! $quit ) {
        system('touch', '/etc/passwd');
        sleep 1;
        print STDERR "_";
    }
    print STDERR "toucher exiting\n";
    exit;
}

## for a vsap hitter. This is a reduced way to accomplish contention
## faster than two user agents. I'm not sure if this will still be as
## effective on the new mail::address:list which runs in about 1/90th
## the time of the old one for several hundred addresses.
if( my $pid = fork() ) {
    print STDERR "Adding $pid for vsap fetcher\n";
    $Childs{$pid} = 1;
}
else {
    while( ! $quit &&
           ! system('perl', '-0777', '-ne', "exit (m!$pattern! ? 0 : 1)", '/usr/local/etc/cpx.conf') ) {

        ## make a vsap call
        package Foo;
        sub new { return bless {} }
        sub child { return '' }
        package main;
        my $dom = XML::LibXML->createDocument('1.0' => 'UTF-8');
        $dom->setDocumentElement($dom->createElement('vsap'));
        system('logger', '-p', 'daemon.notice', "Doing mail::address::list::handler");
        VSAP::Server::Modules::vsap::mail::addresses::list::handler( { username => $user,
                                                                       server_admin => 1,
                                                                       _result_dom  => $dom },
                                                                     new Foo,
                                                                     $dom, );

        print STDERR "V";
    }

    select undef, undef, undef, 0.5;  ## window
    if( ! $quit && 
        ! system('perl', '-0777', '-ne', "exit (m!$pattern! ? 0 : 1)", '/usr/local/etc/cpx.conf') ) {
        print STDERR " (restarting vsap loop) ";
        redo;
    }

    print STDERR " wget fetching done ($quit) ";
    exit;
}

## this is the control panel hitter via a web client. We have a
## restart window for the occasional hits on cpx.conf when it is not
## there (after a write from config.pm)
my $iterations = 0;
DO_UA: {
    while( ! $quit &&
           ! system('perl', '-0777', '-ne', "exit (m!$pattern! ? 0 : 1)", '/usr/local/etc/cpx.conf') ) {
        system('logger', '-p', 'daemon.notice', "Doing request to $page");
        $ua->request($req);
        $iterations++;
        print STDERR "U";
    }

    select undef, undef, undef, 0.5;  ## window
    if( ! $quit && 
        ! system('perl', '-0777', '-ne', "exit (m!$pattern! ? 0 : 1)", '/usr/local/etc/cpx.conf') ) {
        print STDERR " (restarting UA loop) ";
        redo DO_UA;
    }
}

##
## all done! Why?...
##

## check return value
if( $quit ) {
    print STDERR " done.\n";
}
else {
    print STDERR " pattern not found! Config is broken.\n";
}
print STDERR "Iterations: $iterations\n";

## kill all the children. Sometimes the child needs a KILL :(
kill 'TERM' => keys %Childs;

exit;

## NOTE: Your server admin account will need all of the following
## NOTE: capabilities enabled. This works because when the bug is
## NOTE: triggered, all of the cpx-only settings (filemanager and
## NOTE: webmail) disappear, where the platform settings (ftp, mail,
## NOTE: spamassassin, etc.) are discovered by config.pm and put back.

__DATA__
    <user name="$user">
      <domain>$domain</domain>
      <domain_admin/>
      <capabilities>
        <ftp/>
        <fileman/>
        <shell/>
        <mail/>
        <mail-spamassassin/>
        <webmail/>
      </capabilities>
      <services>
        <ftp/>
        <fileman/>
        <shell/>
        <mail/>
        <mail-spamassassin/>
        <webmail/>
      </services>
      <fullname>Administrative User</fullname>
      <eu_capabilities/>
    </user>
