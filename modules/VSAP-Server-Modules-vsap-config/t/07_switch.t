use Test::More tests => 42;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

#########################

my $user  = "joefoo";
my $user2 = "joefoo2";
use VSAP::Server::Test::Account;

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefoo2 = VSAP::Server::Test::Account->create( { username => 'joefoo2', fullname => 'Joe Foo Jr.', password => 'joefoobar' });
ok( getpwnam($user) && getpwnam($user2), "user accounts exist");

## do some operations that only this user can do, or retrieve info
## specific to this user. Then, login as another user and do the same
## operations. The restricted operations should fail and the
## user-specific information should change.

## login as user 1
my $co = new VSAP::Server::Modules::vsap::config( username => $user );

## set some features for this user
$co->capabilities( webmail => 1, 'mail-clamav' => 1 );
$co->domain('charliesangels.com');
$co->domain_admin( set => 1 );

is( $co->{username}, $user, "username ok" );
is( $co->{uid}, scalar (getpwnam($user)), "uid ok" );
is( $co->fullname, "Joe Foo", "fullname ok" );
is( $co->domain, "charliesangels.com", "domain ok" );
ok(   $co->domain_admin, "is domain admin" );
ok(   $co->capability('webmail'), "webmail active" );
ok(   $co->capability('mail-clamav'), "clamav enabled" );
ok( ! $co->capability('mail-spamassassin'), "spamassassin disabled" );

## login as user 2
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => $user2 );

## set some features
$co->capabilities( 'mail-spamassassin' => 1 );

my $hostname = `hostname`; chomp $hostname;

is( $co->{username}, $user2, "username ok" );
is( $co->{uid}, scalar (getpwnam($user2)), "uid ok" );
is( $co->fullname, "Joe Foo Jr.", "fullname ok" );
is( $co->domain, $hostname, "domain ok" );
ok( ! $co->domain_admin, "is NOT domain admin" );
ok( ! $co->capability('webmail'), "webmail inactive" );
ok( ! $co->capability('mail-clamav'), "clamav disabled" );
ok(   $co->capability('mail-spamassassin'), "spamassassin enabled" );

## switch user to user 1
$co->switch_user(username => $user);
is( $co->{username}, $user, "username ok" );
is( $co->{uid}, scalar (getpwnam($user)), "uid ok" );
is( $co->fullname, "Joe Foo", "fullname ok" );
is( $co->domain, "charliesangels.com", "domain ok" );
ok(   $co->domain_admin, "is domain admin" );
ok(   $co->capability('webmail'), "webmail active" );
ok(   $co->capability('mail-clamav'), "clamav enabled" );
ok( ! $co->capability('mail-spamassassin'), "spamassassin disabled" );

## and set a value
$co->capabilities( webmail => 0 );

## switch back to user 2
$co->switch_user(username => $user2);
is( $co->{username}, $user2, "username ok" );
is( $co->{uid}, scalar (getpwnam($user2)), "uid ok" );
is( $co->fullname, "Joe Foo Jr.", "fullname ok" );
is( $co->domain, $hostname, "domain ok" );
ok( ! $co->domain_admin, "is NOT domain admin" );
ok( ! $co->capability('webmail'), "webmail inactive" );
ok( ! $co->capability('mail-clamav'), "clamav disabled" );
ok(   $co->capability('mail-spamassassin'), "spamassassin enabled" );

## try a bogus user
$co->switch_user(username => 'somebogususerfoo');
ok( ! $co->is_valid, "user is not valid" );
is( $co->{username}, 'somebogususerfoo', "bogus username" );
ok( ! $co->fullname, "no full name" );
ok( ! $co->{uid}, "no userid" );

## back to 1 and check our webmail capa
$co->switch_user(username => $user);
ok( $co->is_valid, "object is valid" );
ok( ! $co->capability('webmail'), "webmail inactive for user1" );

## make sure the commit worked
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => $user );
ok( ! $co->capability('webmail'), "webmail inactive for user1" );
ok(   $co->capability('mail-clamav'), "clamav enabled" );


END {
    ## move old file back
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
