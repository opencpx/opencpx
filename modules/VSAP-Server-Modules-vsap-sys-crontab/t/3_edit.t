use Test::More tests => 14;
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
## change 3rd entry to run at 45 past midnight
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block id="7">
    <event id="3">
      <schedule>
        <minute>45</minute>
      </schedule>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[7]->findvalue('event[3]/schedule/minute'), 45, 'new minute' );
is( $nodes[7]->findvalue('event[3]/schedule/hour'), 0, 'hour preserved' );
if ($SIG) {
    is( $nodes[7]->findvalue('event[3]/user'), '', 'user preserved' );
} else {
    is( $nodes[7]->findvalue('event[3]/user'), 'bin', 'user preserved' );
}
like( $nodes[7]->findvalue('event[3]/command'), qr(^savelogs --config), 'command preserved' );

##
## change 4th entry to use relative command path
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block id="7">
    <event id="4">
      <command>rundig -c /usr/local/etc/htdig/onlineutah.com.conf</command>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
like( $nodes[7]->findvalue('event[4]/command'), qr(^rundig -c), 'new command set' );

##
## use a special schedule
##
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block id="7">
    <event id="3">
      <schedule><special>@daily</special></schedule>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
ok( ! $nodes[7]->find('event[3]/schedule/minute'), 'no minute' );
ok( ! $nodes[7]->find('event[3]/schedule/hour'), 'no hour' );

## now revert to a normal schedule
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block id="7">
    <event id="3">
      <schedule>
        <minute>44</minute>
        <hour>9</hour>
        <dom>*</dom>
        <month>*</month>
        <dow>*</dow>
      </schedule>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[7]->findvalue('event[3]/schedule/minute'), 44, 'minute set' );
is( $nodes[7]->findvalue('event[3]/schedule/hour'), 9, 'hour set' )
  or diag($nodes[7]->toString(1));

exit;

######################################################################
sub get_nodes {
    my $de = shift;
    my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
    unshift @nodes, undef;
    return @nodes;
}
