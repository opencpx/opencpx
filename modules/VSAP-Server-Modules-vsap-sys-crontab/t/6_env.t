use Test::More tests => 12;
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


## empty query
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env"/>!);
ok( ! $de->findnodes('/vsap/vsap[@type="sys:crontab:env"]/env') );

## empty get
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name></env>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), '' );

## set MAILTO
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name><value>joe@schmoe.org</value></env>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), 'joe@schmoe.org', "env set" );

## get MAILTO
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name></env>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), 'joe@schmoe.org', "env set" );

## clear MAILTO
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name><value/></env>
</vsap>!);
ok( $de->findnodes('/vsap/vsap[@type="sys:crontab:env"]/env[name="MAILTO"]'), 'MAILTO exists' );
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), '', "MAILTO empty" );

## check again
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name></env>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), '', "env clear" );

## reset MAILTO
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name><value>joe@schmoe.tld</value></env>
</vsap>!);

undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env">
  <env><name>MAILTO</name></env>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env"]/env/value'), 'joe@schmoe.tld', "env set" );

## delete MAILTO
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:env:remove"><name>MAILTO</name></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="sys:crontab:env:remove"]/name'), 'MAILTO', "MAILTO removed" );

## double-check
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:list"/>!);
ok( ! $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/block/env[name="MAILTO"]'), 'MAILTO gone' );

exit;

######################################################################
sub get_nodes {
    my $de = shift;
    my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
    unshift @nodes, undef;
    return @nodes;
}
