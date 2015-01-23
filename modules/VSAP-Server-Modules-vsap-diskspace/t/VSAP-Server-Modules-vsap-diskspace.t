use Test::More tests => 20;
BEGIN { use_ok('VSAP::Server::Modules::vsap::diskspace') };

#########################
use VSAP::Server::Test;
use VSAP::Server::Test::Account;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT,"account was created");

ok($ACCT->exists,"account exists");

my $vsap = $ACCT->create_vsap(['vsap::diskspace']);
my $t = $vsap->client({ acct => $ACCT });

$ENV{BLOCKSIZE} = '512';

ok(ref($t), "obtained a vsap client");

my $de;
my $node;

## test happy quota
$de = $t->xml_response(qq!<vsap type="diskspace"/>!);

if( ($node) = $de->findnodes('/vsap/vsap[@type="diskspace"]') ) {
    is( 0+$node->findvalue('./allocated'), 50, "allocated 50" );
    cmp_ok( 0+$node->findvalue('./used'),'<=', 0.2, "used less then .2" );
    is( $node->findvalue('./percent'), 0, "percent is 0" );
}
else {
    fail();
    fail();
    fail();
}

## try updating that usage
open FILE, ">/home/joefoo/junk"
  or die "Could not open file: $!\n";
print FILE '.' x (1024 * 1024 * 25);
close FILE;

($login,$pass,$uid,$gid) = getpwnam('joefoo')
	or die "$user not in passwd file";
chown $uid, $gid, '/home/joefoo/junk' 
	or die "failed to chown: $!";

undef $de;
$de = $t->xml_response(qq!<vsap type="diskspace"/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="diskspace"]') ) {
    is( 0+$node->findvalue('./allocated'), 50, "allocated 50" );
    cmp_ok( 0+$node->findvalue('used'), ">=", 25.0, "used >= 25" );
    cmp_ok( 0+$node->findvalue('used'), "<", 25.5, "used < 25.5" );
    is( $node->findvalue('./percent'), 50, "percentage 50" );
}
else {
    fail();
    fail();
    fail();
}

##
## try as server admin
##


## make us a server admin for a sec
$ACCT->make_sa();

$t->quit;
undef $t;
undef $de;
$t = $vsap->client({ acct => $ACCT });
ok( ref($t), "obtained a new client as sa");

my $df;
for (`df -k`) {
    chomp;
    next unless m!\s/\s*$!;
    $df = $_;
    last;
}
die "Could not get df output\n" unless $df;

my( undef, $alloc, $used, undef, $percent, undef ) = split(' ', $df);
$percent =~ s/%//g;
if( $alloc > (1024*1024)-1 ) {
    $used  = sprintf("%.2f", $used/(1024*1024));
    $alloc = sprintf("%.2f", $alloc/(1024*1024));
}

elsif( $alloc > 1023 ) {
    $used  = sprintf("%.2f", $used/1024);
    $alloc = sprintf("%.2f", $alloc/1024);
}

undef $de;
$de = $t->xml_response(qq!<vsap type="diskspace"/>!);
if( ($node) = $de->findnodes('/vsap/vsap[@type="diskspace"]') ) {
    is( 0+$node->findvalue('./allocated'), 0+$alloc, "allocated $alloc");
    is( $node->findvalue('./used'), $used, "used $used" );
    is( $node->findvalue('./percent'), $percent, "percent $percent" );
}
else {
    fail();
    fail();
    fail();
}

undef $de;
$de = $t->xml_response(qq!<vsap type="diskspace:list"/>!);
is( $de->findvalue('/vsap/vsap[@type="diskspace:list"]/sz'), 4, "sz set" );

undef $de;
$de = $t->xml_response(qq!<vsap type="diskspace:list">
  <dir>3 12 4 15 8 13 11 2 0 1 14 9 10 5 7 6</dir>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="diskspace:list"]/dir'), '3 12 4 15 8 13 11 2 0 1 14 9 10 5 7 6', "dir sequence" );

$de = $t->xml_response(qq!<vsap type="diskspace:list">
  <dir>3 12 4 15 8 13 11 2 0 1 14 9 10 5 7 6</dir>
  <units>1</units>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="diskspace:list"]/dir'), '3 12 4 15 8 13 11 2 1 0 14 9 10 5 7 6', "dir sequence" );

$de = $t->xml_response(qq!<vsap type="diskspace:list">
  <dir>1 2 3 4 5 6 7 8 9 10 11 12 13 14 0 15</dir>
  <units>15</units>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="diskspace:list"]/hdr'), qr(nd p), "note check" );

$de = $t->xml_response(qq!<vsap type="diskspace:list">
  <dir>1 2 3 4 0 5 6 7 8 9 10 11 12 13 14 15</dir>
  <units>15</units>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="diskspace:list"]/hdr'), qr(nd p), "note check" );
