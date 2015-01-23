use Test::More tests => 15;
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
    write_usr_cron(2);
} else {
    write_sys_cron(2);
}


my $cron = `cat $CRONTAB`;
my $cron_test;
if ($SIG) {
    $cron_test = $Usr_cron[2] = $Usr_cron[2];  ## silence warning
} else {
    $cron_test = $Sys_cron[2] = $Sys_cron[2];  ## silence warning
}
is( $cron, $cron_test, "crontab not changed" );

##
## disable some bogus things
##
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"/>!);
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"><block/></vsap>!);
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"><block id="0"/></vsap>!);
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"><block id="10"/></vsap>!);
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"><block id="8"><event id="4"/></block></vsap>!);

$cron = `cat $CRONTAB`;
is( $cron, $cron_test, "crontab not changed" );

## precondition
$de = $t->xml_response(q!<vsap type="sys:crontab:list"><block id="9"/></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:list"]/block/env/active'), 1, "active variable" );

##
## disable a variable
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:disable">
  <block id="9"><env id="1"/></block>
</vsap>!);

$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[9]->findvalue('env[1]/active'), 0, 'variable disabled' );

##
## disable an event
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:disable">
  <block id="9"><event id="1"/></block>
</vsap>!);

$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[9]->findvalue('event[1]/active'), 0, 'event disabled' );

##
## enable a few things
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:enable">
  <block id="9"><env id="1"/><event id="1"/></block>
</vsap>!);

$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[9]->findvalue('env/active'), 1, 'variable enabled' );
is( $nodes[9]->findvalue('event[1]/active'), 1, 'event enabled' );

##
## disable a block wholesale
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:disable"><block id="9"/></vsap>!);

$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[9]->findvalue('env/active'), 0, 'variable disabled' );
is( $nodes[9]->findvalue('event[1]/active'), 0, 'event disabled' );
is( $nodes[9]->findvalue('event[2]/active'), 0, 'event disabled' );

##
## now enable the block
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:enable"><block id="9"/></vsap>!);

$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[9]->findvalue('env/active'), 1, 'variable enabled' );
is( $nodes[9]->findvalue('event[1]/active'), 1, 'event enabled' );
is( $nodes[9]->findvalue('event[2]/active'), 1, 'event enabled' );


######################################################################
sub get_nodes {
    my $de = shift;
    my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
    unshift @nodes, undef;
    return @nodes;
}
