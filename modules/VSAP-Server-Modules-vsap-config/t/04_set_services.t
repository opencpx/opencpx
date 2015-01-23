use Test::More tests => 40;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

use_ok('VSAP::Server::Test::Account');
use_ok('POSIX');

#########################

my $user = 'joefoo';
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( getpwnam($user) );

## drop privs
{
    local $> = getpwnam($user);

my $co = new VSAP::Server::Modules::vsap::config( username => $user );

##
## happy save
##
my $services = $co->services;
ok(   $services->{ftp} );
ok(   $services->{mail} );
ok( ! $services->{webmail} );
$co->commit;
ok( -f '/usr/local/etc/cpx.conf', "config file exists" );

##
## remove service
##
$co->services( ftp => 0 );
$services = $co->services;
ok( ! $services->{ftp},     'ftp disabled' );
ok(   $services->{mail},    'mail enabled' );
ok( ! $services->{webmail}, 'webmail disabled' );
$co->commit;
if ($is_linux)
{
	ok( grep { $_ eq $user } split(' ', (getgrnam('mailgrp'))[3]) );
} else {
	ok( grep { $_ eq $user } split(' ', (getgrnam('imap'))[3]) );
}

##
## change services
##
$co->services( mail => 0, ftp => 1, webmail => 1 );
$services = $co->services;
ok(   $services->{ftp} );
ok( ! $services->{mail}, "mail disabled" );
ok(   $services->{webmail}, 'webmail still enabled' );
$co->commit;

## check platform
if ($is_linux)
{
	ok( grep { $_ ne $user } split(' ', (getgrnam('mailgrp'))[3]), 'mail disabled' );
} else {
	ok( grep { $_ ne $user } split(' ', (getgrnam('imap'))[3]), 'mail disabled' );
}

## put it back
$co->services( ftp => 0, webmail => 0, mail => 1 );
$services = $co->services;
ok( ! $services->{ftp} && $services->{mail} && ! $services->{webmail}, 'services restored' );
$co->commit;

## try one w/ a bogus service
$co->services( mail => 0, ftp => 1, webmail => 1, bogus => 1 );
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => $user );
$services = $co->services;
ok(   $services->{ftp},     "ftp enabled" );
ok( ! $services->{mail},    "mail disabled" );
ok(   $services->{webmail}, "webmail enabled" );
ok( ! $services->{bogus},   "no bogus service" );
$co->commit;

## check platform
ok( grep { $_ ne $user } split(' ', (getgrnam('imap'))[3]), "no longer in imap group" );

##
## set services
##
$co->services( mail => 0, webmail => 0 );
$services = $co->services;
ok( ! $services->{mail} );
ok( ! $services->{webmail}, "webmail disabled" );
if ($is_linux)
{
	ok( grep { $_ ne $user } split(' ', (getgrnam('mailgrp'))[3]), 'mail disabled' );
} else {
	ok( grep { $_ ne $user } split(' ', (getgrnam('imap'))[3]), 'mail disabled' );
}

$services = $co->services;
ok(   $services->{ftp} );
ok( ! $services->{mail} );
ok( ! $services->{webmail} );
undef $co;

##
## change via platform (remove ftp service)
##
{
    local $> = 0;
	if ($is_linux)
	{
    system('usermod', '-G', , join(',', grep { $_ ne 'ftp' } 
		(qw(mailgrp), split(' ', `id -Gn $user`))), $user);
	} else {
    system('pw', 'usermod', $user, '-G', join(',', grep { $_ ne 'ftp' } 
		(qw(imap pop), split(' ', `id -Gn $user`))));
	}
}
$co = new VSAP::Server::Modules::vsap::config( username => $user );
$services = $co->services;
ok( ! $services->{ftp} );
ok(   $services->{mail} );
ok( ! $services->{webmail} );
undef $co;

$co = new VSAP::Server::Modules::vsap::config( username => $user );
$services = $co->services;

## tests for applications like spamassassin and clamav
ok( ! $services->{'mail-spamassassin'} && ! $services->{'mail-clamav'} );

#$VSAP::Server::Modules::vsap::config::TRACE = 1;
$co->services( 'mail-spamassassin' => 1, 'mail-clamav' => 1 );
$services = $co->services;
ok(   $services->{'mail-spamassassin'} &&   $services->{'mail-clamav'} );

my $status = VSAP::Server::Modules::vsap::mail::spamassassin::nv_status();
is( $status, 'on', 'spamassassin enabled' );

## retest as root (should work by username => $user)
{
    local $> = 0;

    $co = new VSAP::Server::Modules::vsap::config( username => $user );
    $services = $co->services;

    ok(   $services->{'mail-spamassassin'} &&   $services->{'mail-clamav'} );

    $status = VSAP::Server::Modules::vsap::mail::spamassassin::nv_status($user);
    is( $status, 'on', 'spamassassin enabled' );
    $status = VSAP::Server::Modules::vsap::mail::clamav::nv_status($user);
    is( $status, 'on', 'clamav enabled' );

    ## these tests check whether we can enable/disable services as root correctly
    $co->services( 'mail-spamassassin' => 0, 'mail-clamav' => 0 );
    $services = $co->services;
    ok( ! $services->{'mail-spamassassin'} && ! $services->{'mail-clamav'} );
    $status = VSAP::Server::Modules::vsap::mail::spamassassin::nv_status($user);
    is( $status, 'off', 'spamassassin disabled' );
    $status = VSAP::Server::Modules::vsap::mail::clamav::nv_status($user);
    is( $status, 'off', 'clamav disabled' );

}


}  ## end of local non-root privs; sorry for the bad indenting

END {
    ## move old file back
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
