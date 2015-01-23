use Test::More tests => 26;
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
ok( $acctjoefoo->exists(), "account exists");

my $co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');

##
## happy save
##
$co->capabilities(ftp => 0, webmail => 1 );
ok(   $co->capability('ftp'), "has ftp" );  ## platform will override this
ok(   $co->capability('mail'), "has mail" );
ok(   $co->capability('webmail'), "has webmail" );
ok( ! $co->capability('mail-spamassassin'), "no spamassassin" );
undef $co;
ok( -f '/usr/local/etc/cpx.conf', "config file exists" );

##
## remove service
##
if ($is_linux)
{
	system('gpasswd -d joefoo ftp > /dev/null');  ## take away ftp service for this user
} else {
	system('pw user mod joefoo -G pop,imap,joefoo > /dev/null');  ## take away ftp service for this user
}
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->capabilities(ftp => 0);
ok( ! $co->capability('ftp'), "no ftp" );
ok(   $co->capability('mail'), "has mail" );
ok(   $co->capability('webmail'), "has webmail" );
ok( ! $co->capability('mail-spamassassin'), "no spamassassin" );
undef $co;

##
## remove service
##
if ($is_linux) 
{
	system('gpasswd -a joefoo ftp > /dev/null');  ## Add ftp service back
	system('gpasswd -d joefoo mailgrp > /dev/null');  ## take away mail service for this user
} else {
	system('pw user mod joefoo -G ftp,joefoo > /dev/null');  ## take away mail service for this user
}
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
ok(   $co->capability('ftp'), "has ftp" );  ## get_capa restores this value
ok(   $co->capability('mail'), "has mail" );
ok(   $co->capability('webmail'), "has webmail" );
ok( ! $co->capability('mail-spamassassin'), "no spamassassin" );
undef $co;

##
## set services
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->capabilities( mail => 0, 'mail-spamassassin' => 1, webmail => 0 );
ok( ! $co->capability('mail'), "no mail" );
ok( ! $co->capability('webmail'), "no webmail" );
ok(   $co->capability('mail-spamassassin'), "has spamassassin" );
undef $co;

if ($is_linux)
{
	system('gpasswd -a joefoo mailgrp > /dev/null'); ## Add mail service back
} else {
	system('pw user mod joefoo -G pop,imap,ftp,joefoo >/dev/null');
}
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
ok(   $co->capability('ftp'), "has ftp" );
ok(   $co->capability('mail'), "has mail" );
ok( ! $co->capability('webmail'), "no webmail" );
ok(   $co->capability('mail-spamassassin'), "has spamassassin" );
undef $co;

##
## eu capabilities
##

## test a non-da (should fail)
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
my $capa = $co->eu_capabilities;
$co->eu_capabilities( mail => 1, ftp => 1 );
is( keys %$capa, 0, "not a da, has 0 capabilities" );

$co->domain_admin(set => 1);
$co->eu_capabilities( mail => 1, ftp => 1 );
$capa = $co->eu_capabilities;
is( keys %$capa, 2, "has 2 capabilities" );

END {
    ## move old file baco
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
