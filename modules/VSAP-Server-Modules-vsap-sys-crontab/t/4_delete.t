use Test::More tests => 19;
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
my $de;

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
## write out a fresh default crontab file
##
if ($SIG) {
    write_usr_cron(1);
} else {
    write_sys_cron(1);
}


my $cron = `cat $CRONTAB`;
my $cron_test;
if ($SIG) {
    $cron_test = $Usr_cron[1] = $Usr_cron[1];  ## silence warning
} else {
    $cron_test = $Sys_cron[1] = $Sys_cron[1];  ## silence warning
}
is( $cron, $cron_test, "crontab not changed" );

##
## delete non-existent things
##
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete"/>!);
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="0"/>
</vsap>!);
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="7">
    <event id="0"/>
    <event id="5"/>
  </block>
</vsap>!);

$cron = `cat $CRONTAB`;
is( $cron, $cron_test, "crontab not changed" );

## just a sanity check
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[7]->findvalue('event[3]/schedule/minute'), 30, 'original minute' );
is( $nodes[7]->findvalue('event[3]/schedule/hour'), 0, 'original hour' );
if ($SIG) {
    is( $nodes[7]->findvalue('event[3]/user'), '', 'original user' );
} else {
    is( $nodes[7]->findvalue('event[3]/user'), 'bin', 'original user' );
}

##
## delete some entries
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="7">
    <event id="1"/>
    <event id="3"/>
  </block>
</vsap>!);

$de = $t->xml_response(qq!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($de);
is( scalar(@nodes), 9, "nodes found" );
is( $nodes[7]->findvalue('event[1]/schedule/minute'), 15, 'minutes moved' );
like( $nodes[7]->findvalue('event[1]/command'), qr(^analog), 'command moved' );
is( $nodes[7]->findvalue('event[2]/schedule/dow'), '1-5', 'dow moved' );
like( $nodes[7]->findvalue('event[2]/command'), qr(rundig), 'command moved' );

##
## delete a block and some entries
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="7"/>
  <block id="8">
    <event id="1"/>
  </block>
</vsap>!);

#system('less', '/etc/crontab');

undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($de);
is( scalar(@nodes), 8, "nodes list" );
like( $nodes[7]->findvalue('event[1]/command'), qr(rundig), 'new command set' );

##
## delete a block, then some entries from that block
##
if ($SIG) {
    write_usr_cron(1);
} else {
    write_sys_cron(1);
}

undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="7"/>
  <block id="7">
    <event id="1"/>
  </block>
</vsap>!);

## the last block should be completely intact
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( scalar(@nodes), 8, "nodes list" );
like( $nodes[7]->findvalue('comment'), qr(mail archiving and search), 'comment intact' );
like( $nodes[7]->findvalue('event[1]/command'), qr(mhonarc), 'new command set' );
like( $nodes[7]->findvalue('event[2]/command'), qr(rundig), 'new command set' );


##
## test for BUG09013, BUG09014
##
if( $SIG ) {
    write_usr_cron(3);
}
else {
    write_sys_cron(3);
}

undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:delete">
  <block id="10"><event id="1"/></block>
  <block id="10"><event id="2"/></block>
  <block id="10"><event id="3"/></block>
  <block id="10"><event id="4"/></block>
  <block id="10"><event id="5"/></block>
  <block id="10"><event id="6"/></block>
  <block id="10"><event id="7"/></block>
  <block id="10"><event id="8"/></block>
  <block id="10"><event id="9"/></block>
  <block id="10"><event id="10"/></block>
  <block id="10"><event id="11"/></block>
  <block id="10"><event id="12"/></block>
  <block id="10"><event id="13"/></block>
  <block id="10"><event id="14"/></block>
  <block id="10"><event id="15"/></block>
  <block id="10"><event id="16"/></block>
  <block id="10"><event id="17"/></block>
  <block id="10"><event id="18"/></block>
  <block id="10"><event id="19"/></block>
  <block id="10"><event id="20"/></block>
  <block id="10"><event id="21"/></block>
</vsap>!);

$de = $t->xml_response(qq!<vsap type="sys:crontab:list" />!);
@nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/block[@id="10"]/*');
is( scalar(@nodes), 0, "no more nodes" );

exit;

######################################################################
sub get_nodes {
    my $de = shift;
    my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
    unshift @nodes, undef;
    return @nodes;
}
