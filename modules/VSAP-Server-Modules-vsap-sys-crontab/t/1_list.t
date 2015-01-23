use Test::More tests => 25;
## this hack also found in vsapd; it pushes vendor_perl higher than
## site_perl in Perl's @INC array so we find the right modules and
## versions of those modules. -scottw
BEGIN {
    my @vendor = grep {   m!/vendor_perl! } @INC;
    @INC       = grep { ! m!/vendor_perl! } @INC;
    my $i = 0; for ( @INC ) { last if m!/site_perl!; $i++ }
    splice @INC, $i, 0, @vendor;
    use_ok('VSAP::Server::Modules::vsap::sys::crontab');
};

#########################

use VSAP::Server::Test::Account;

##
## test setup
##
my $ACCT = create VSAP::Server::Test::Account( { type => 'account-owner' } );
my $vsap = $ACCT->create_vsap( [qw(vsap::sys::crontab)] );
my $t    = $vsap->client( { acct => $ACCT } );
ok( ref($t), 'got vsap server test object' );

##
## set crontab file
##
our $CRONTAB;
our $SIG = 0;
our $VPS = 0;
our $LVPS = 0;
use POSIX qw(uname);
if ( -d '/skel' ) {
    # For FreeBSD VPS2
    $VPS = 1;
    $CRONTAB = '/etc/crontab';
} elsif ( (POSIX::uname())[0] =~ /Linux/ ) {
    # For Linux VPS2
    $LVPS = 1;
    $CRONTAB = '/etc/crontab';
} else {
    # For Signature
    $SIG = 1;
    $CRONTAB = $ACCT->homedir . '/etc/crontab';
}

require 't/crontab.pl';

##
## empty crontab
##
my $de = $t->xml_response(qq!<vsap type="sys:crontab:list"/>!);
my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
is( scalar(@nodes), 0, "empty crontab" );

## write a crontab
if ($SIG) {
    write_usr_cron(0);
} else {
    write_sys_cron(0);
}

##
## list basic crontab
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
is( scalar(@nodes), 6, "node count" );
unshift @nodes, undef;

is( $nodes[1]->findvalue('env[name="HOME"]/value'), '/var/log', 'env variable' );
is( $nodes[5]->findvalue('comment'), 'do daily/weekly/monthly maintenance', 'comment' );
is( $nodes[6]->findvalue('comment'), '', 'comment' );
is( $nodes[4]->findvalue('event/command'), 'newsyslog', 'command' );
is( $nodes[2]->findvalue('comment/@hidden'), '1', 'hidden comment' );
if ($SIG) {
    is( $nodes[6]->findvalue('event/user'), '', 'user' );
} else {
    is( $nodes[6]->findvalue('event/user'), 'root', 'user' );
}
like( $nodes[6]->findvalue('event/command'), qr(savelogs), 'command' );

##
## list one block in a crontab
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:list"><block id="3"/></vsap>!);
@nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
is( scalar(@nodes), 1, "node count" );
unshift @nodes, undef;

is( $nodes[1]->findvalue('comment'), '', 'comment empty' );
is( $nodes[1]->findvalue('event/schedule/minute'), '*/5', 'minutes set' );
is( $nodes[1]->findvalue('event/command'), '/usr/libexec/atrun', 'command set' );

##
## list one even in a crontab
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:list"><block id="5"><event id="2"/></block></vsap>!);
if ($SIG) {
    is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event[@id="2"]/user'), '', 'user set' );
} else {
    is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event[@id="2"]/user'), 'root', 'user set' );
}
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event[@id="2"]/command'), 'periodic weekly', 'command set (id addressable)' );
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/command'), 'periodic weekly', 'command set' );
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/schedule/minute'), 15, 'minute set' );

## write a new crontab out
if ($SIG) {
    write_usr_cron(1);
} else {
    write_sys_cron(1);
}



##
## list a comment and an event
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:list"><block id="8"><comment id="1"/><event id="2"/></block></vsap>!);
if ($SIG) {
    is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/user'), '', 'user set' );
} else {
    is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/user'), 'www', 'user set' );
}
like( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/command'), qr(rundig), 'command set' );
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/schedule/minute'), 30, 'minute set' );
like( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/comment'), qr(mail archiving and search), 'comment');
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/event/@id'), 2, "event id" );
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/comment/@id'), 1, "comment id" );
