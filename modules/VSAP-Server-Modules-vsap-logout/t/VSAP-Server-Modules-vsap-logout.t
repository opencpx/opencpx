use Test::More tests => 7;
BEGIN { use_ok('VSAP::Server::Modules::vsap::logout') };

#########################
use VSAP::Server::Test;
my $vsapd_config = "_config.$$.vsapd";

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up a user
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    system( 'vadduser --quiet --login=joefoo --password=joefoobar --home=/home/joefoo --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joefoo'\n";
}

ok( getpwnam('joefoo') );

## write a simple config file
open VSAPD, ">$vsapd_config"
    or die "Couldn't open '$vsapd_config': $!\n";
print VSAPD <<_CONFIG_;
LoadModule    vsap::auth
LoadModule    vsap::diskspace
LoadModule    vsap::logout
_CONFIG_
close VSAPD;

my $vsap = new VSAP::Server::Test( { vsapd_config => $vsapd_config } );

my $t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

ok(ref($t));

## check diskspace
my $de;
my $node;

## test happy quota
$de = $t->xml_response(qq!<vsap type="diskspace"/>!);

if( ($node) = $de->findnodes('/vsap/vsap[@type="diskspace"]') ) {
    is( $node->findvalue('./allocated'), 50 );
    is( $node->findvalue('./used'), 0 );
    is( $node->findvalue('./percent'), 0 );
}
else {
    fail();
    fail();
    fail();
}

## logout
$de = $t->xml_response(qq!<vsap type="logout"/>!);

## check again (should fail)
ok( ! $t->response(qq!<vsap type="diskspace"/>!) );

END {
    getpwnam('joefoo') && system q(vrmuser -y joefoo 2>/dev/null);
    unlink $vsapd_config;
}
