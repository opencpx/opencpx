use Test::More tests => 26;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

#########################

use VSAP::Server::Modules::vsap::mail::spamassassin qw(nv_enable nv_disable);
use VSAP::Server::Modules::vsap::mail::clamav qw(nv_enable nv_disable);
use VSAP::Server::Test::Account;
use POSIX('uname');

my $user = "joefoo";
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

##
## bogus users do not have any services
##
my $co = new VSAP::Server::Modules::vsap::config(username => $user);
ok( ! $co->service('ftp'), 'check no ftp', );
ok( ! $co->service('mail'), 'check no mail' );
ok( ! $co->service('webmail'), 'check no webmail' );
ok( ! -e '/usr/local/etc/cpx.conf', "config file does not exist" );
undef $co;

## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( $acctjoefoo->exists, "account exists");

##
## get_services will check platform and update
##

$co = new VSAP::Server::Modules::vsap::config(username => $user);
ok(   $co->service('ftp'), "has ftp" );
ok(   $co->service('mail'), "has mail" );
ok( ! $co->service('webmail'), "no webmail" );
undef $co;
ok( -f '/usr/local/etc/cpx.conf', "config file exists" );

##
## check update from platform
##
if ($is_linux)
{
	system("gpasswd -d $user ftp > /dev/null");  ## take away ftp service for this user
} else {
	system("pw user mod $user -G pop,imap,$user > /dev/null");  ## take away ftp service for this user
}
$co = new VSAP::Server::Modules::vsap::config(username => $user);
ok( ! $co->service('ftp'), 'Check no ftp' );
ok(   $co->service('mail'), 'Check mail' );
ok( ! $co->service('webmail'), 'check no webmail' );
undef $co;

##
## wipe out the config file and test again
##
unlink '/usr/local/etc/cpx.conf';
$co = new VSAP::Server::Modules::vsap::config(username => $user);
ok( ! $co->service('ftp'), 'check no ftp' );
ok(   $co->service('mail'), 'check mail' );
ok( ! $co->service('webmail'), 'check no webmail' );
undef $co;

##
## restore ftp
##
if ($is_linux)
{
	system("gpasswd -a $user ftp > /dev/null");  ## Add ftp service back
} else {
	system("pw user mod $user -G pop,imap,ftp,$user > /dev/null");  ## Add ftp service back
}
$co = new VSAP::Server::Modules::vsap::config(username => $user);
my $serv = $co->services;
ok(   $co->service('ftp'), 'check ftp' );
ok(   $co->service('mail'), 'check mail' );
ok( ! $co->service('webmail'), 'check no webmail' );
ok(   $serv->{ftp}, 'check ftp' );
ok(   $serv->{mail},'check mail' );
ok( ! $serv->{webmail}, 'check no webmail' );
undef $co;

##
## try some other services
##
$co = new VSAP::Server::Modules::vsap::config(username => $user);
ok((!$co->service('mail-spamassassin') and ! $co->service('mail-clamav')), "no spamassassin and no clamav" );

## enable sa
{
    local $> = getpwnam($user);
    VSAP::Server::Modules::vsap::mail::spamassassin::nv_enable();
}
ok(($co->service('mail-spamassassin') and !$co->service('mail-clamav')), "spamassassin and no clamav" );

## enable clamav
{
    local $> = getpwnam($user);
    VSAP::Server::Modules::vsap::mail::clamav::nv_enable();
}
ok(($co->service('mail-spamassassin') and   $co->service('mail-clamav')), "spamassassin and clamav" );

## disable spamassassin
{
    local $> = getpwnam($user);
    VSAP::Server::Modules::vsap::mail::spamassassin::nv_disable();
}
ok((! $co->service('mail-spamassassin') and $co->service('mail-clamav')), "no spamassassin and clamav" );


END {
    ## move old file back
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
