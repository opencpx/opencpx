use Test::More tests => 27;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

use_ok('VSAP::Server::Test::Account');
#########################

use_ok('POSIX');
my $user = 'joefoo';

my $is_linux =((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

my $co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');

##
## bogus users do not have any capabilities
##
ok( ! $co->capability('ftp'), 'bogus user no ftp' );
ok( ! $co->capability('mail'), 'bogus user no mail' );
ok( ! $co->capability('webmail'), 'bogus user no webmail' );
ok( ! $co->capability('spamassassin'), 'bogus user no spamassassin' );
ok( ! -e '/usr/local/etc/cpx.conf', 'bogus user no config file' );

undef $co;
## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( getpwnam('joefoo') ,"User exists");

$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');

##
ok( !  $co->capability('shell') , "check shell");

## get_capa will check platform and update capa accordingly...
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
ok(   $co->capability('ftp') ,'check ftp exists');
ok(   $co->capability('mail') , 'check mail exists');
ok( ! $co->capability('webmail'), 'check no webmail' );
ok( ! $co->capability('spamassassin'), 'check no spamassassin' );
undef $co;
ok( -f '/usr/local/etc/cpx.conf', "config file exists" );

##
## ...but will not demote capa when service is disabled
##
if ($is_linux)
{
	system('gpasswd -d joefoo ftp > /dev/null');  ## take away ftp service for this user
} else {
	system('pw user mod joefoo -G pop,imap,joefoo >/dev/null');  ## take away ftp service for this user
}
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
my $capa = $co->capabilities;
ok(   $co->capability('ftp'), 'Check ftp' );
ok(   $co->capability('mail'), 'Check mail' );
ok( ! $co->capability('webmail'), 'Check no webmail' );
ok( ! $co->capability('spamassassin'), 'Check no spamassassin' );

ok(   $capa->{ftp}, 'Check ftp' );
ok(   $capa->{mail}, 'Check mail' );
ok( ! $capa->{webmail}, 'Check no webmail' );
ok( ! $capa->{spamassassin}, 'Check no spamassassin' );

undef $co;

##
## wipe out the config file and test again
##
unlink '/usr/local/etc/cpx.conf';
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
ok( ! $co->capability('ftp'), 'Check no ftp' );
ok(   $co->capability('mail'), 'Check mail' );
ok( ! $co->capability('webmail'), 'Check no webmail' );
ok( ! $co->capability('spamassassin'), 'Check no spamassassin' );
undef $co;

END {
    ## move old file back
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
