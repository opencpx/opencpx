use Test::More tests => 11;
BEGIN { use_ok( 'VSAP::Server::Modules::vsap::config' ) };

#########################
use_ok( 'VSAP::Server::Test::Account' );

my $user                                         = 'joefoo';
$VSAP::Server::Modules::vsap::config::CPX_VINST  = ".cpx_vinst.$$";
$VSAP::Server::Modules::vsap::config::TRACE      = 0;
$VSAP::Server::Modules::vsap::config::PACKAGES{'mail-spamassassin'} = ".ncsbr.$$";
$VSAP::Server::Modules::vsap::config::PACKAGES{'mail-clamav'}       = ".ncsbr.$$";

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( getpwnam($user), "test user exists" );

## disable all packages
system( 'touch', ".ncsbr.$$");
ok( -e ".ncsbr.$$", "packages marker file exists" );

system( 'touch', ".cpx_vinst.$$");
ok( -e ".cpx_vinst.$$", "cpx vinstall marker file exists" );

## parse config
my $co = new VSAP::Server::Modules::vsap::config(username => $user);
my $packages = $co->packages;
is( scalar keys %$packages, 0, "cpx has no packages" );

## time passes...
sleep 1;

## enable all packages
unlink ".ncsbr.$$";
ok( ! -e ".ncsbr.$$", "packages marker marker file unlinked" );

system( 'touch', ".cpx_vinst.$$");
ok( -e ".cpx_vinst.$$", "cpx vinstall marker file exists" );

## reparse config
my $co = new VSAP::Server::Modules::vsap::config(username => $user);
my $packages = $co->packages;
is( scalar keys %$packages, 2, "cpx has two packages" );
is( $packages->{'mail-spamassassin'}, 1, "mail-spamassassin package enabled" );
is( $packages->{'mail-clamav'}, 1, "mail-clamav package enabled" );


END {
    getpwnam($user)      && system qq(vrmuser -y $user 2>/dev/null);
    unlink "cpx.conf.$$";
    unlink ".cpx_vinst.$$";
    unlink ".ncsbr.$$";

    ## move old file back
    if( -e "/usr/local/etc/cpx.conf.$$" ) {
        unlink "/usr/local/etc/cpx.conf";
        rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf");
    }

}
