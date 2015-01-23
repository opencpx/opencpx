use Test::More tests => 10;
BEGIN { use_ok('VSAP::Server::Modules::vsap::mail') };

#########################
use VSAP::Server::Test::Account;

use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

my $pwd = `pwd`; chomp $pwd;

## run vadduser (quietly)
my $acctjoequuxy = VSAP::Server::Test::Account->create( {username => 'joequuxy', password => 'joequuxyrootbar', shell => '/sbin/noshell', fullname => 'Joe Quux'} );
my $accthorkquux = VSAP::Server::Test::Account->create( {username => 'horkquux', password => 'horkquuxrootbar', shell => '/sbin/noshell', fullname => 'Joe Quux'} );
ok(getpwnam('joequuxy'), 'successfully created new user');
ok(getpwnam('horkquux'), 'successfully created new user');

## local-host-names
if( -e '/etc/mail/local-host-names' ) {
    rename '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$"
      or die "Could not rename local-host-names: $!\n";
}
open LHN, "> /etc/mail/local-host-names";
print LHN "foo.com\n";
close LHN;

my $ip = `sinfo`;
$ip =~ s/.*address:\s*([\d\.]+)\n.*/$1/s;

## hosts
if( -e '/etc/hosts' ) {
    rename '/etc/hosts', "/etc/hosts.$$"
      or die "Could not rename /etc/hosts: $!\n";
}
open HOSTS, "> /etc/hosts";
print HOSTS "$ip    foo.com\n";
close HOSTS;

## aliases
my $aliasesDir;
if ($is_linux)
{
    $aliasesDir = "/etc";
} else {
    $aliasesDir = "/etc/mail";
}

unless( -e "${aliasesDir}/aliases" ) {
  system "touch ${aliasesDir}/aliases";
}
system "/bin/cp ${aliasesDir}/aliases ${aliasesDir}/aliases.$$";

## genericstable
if( -e '/etc/mail/genericstable' ) {
    rename '/etc/mail/genericstable', "/etc/mail/genericstable.$$"
      or die "Could not rename genericstable: $!\n";
}

## virtusertable
if( -e '/etc/mail/virtusertable' ) {
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable.$$"
      or die "Could not rename virtusertable: $!\n";
}
open VUT, "> /etc/mail/virtusertable";
print VUT <<'_EOF_';
joequuxy@foo.com	joequuxy
horkquux@foo.com	horkquux
@foo.com		error:nouser User unknown
_EOF_
close VUT;

my $gt = `cat /etc/mail/genericstable 2>/dev/null`;
is( $gt, '', "empty generics" );

## empty generics
ok( ! VSAP::Server::Modules::vsap::mail::genericstable( user => '',
							dest => '' ), "empty user" );

## bogus user
ok( ! VSAP::Server::Modules::vsap::mail::genericstable( user => 'bogususer',
							dest => '' ), "bogus user" );

## new entry
VSAP::Server::Modules::vsap::mail::genericstable( user => 'joequuxy',
						  dest => 'joequuxy@foo.com' );
$gt = `cat /etc/mail/genericstable`;
like($gt, qr(^joequuxy\s+joequuxy\@foo\.com), "joequuxy has entered the building");

## change existing entry
VSAP::Server::Modules::vsap::mail::genericstable( user => 'joequuxy',
						  dest => 'quuxjoe@foo.com' );
$gt = `cat /etc/mail/genericstable`;
like($gt, qr(^joequuxy\s+quuxjoe\@foo\.com), "joequuxy has a new groove");

## delete entry
VSAP::Server::Modules::vsap::mail::genericstable( user => 'joequuxy',
						  action => 'delete' );
$gt = `cat /etc/mail/genericstable`;
is( $gt, '', "joequuxy has left the building" );

##
## some mail tests
##
VSAP::Server::Modules::vsap::mail::genericstable( user => 'joequuxy',
						  dest => 'joequuxy@foo.com' );
$gt = `cat /etc/mail/genericstable`;
like($gt, qr(^joequuxy\s+joequuxy\@foo\.com), "joequuxy has entered the building again");

## FIXME: send mail and check headers


END {
    getpwnam('joequuxy')      && system q(vrmuser -y joequuxy 2>/dev/null);
    getpwnam('horkquux')      && system q(vrmuser -y horkquux 2>/dev/null);

    unlink "/etc/hosts" if -e "/etc/hosts";
    if( -e "/etc/hosts.$$" ) {  
        rename "/etc/hosts.$$", '/etc/hosts';
    }

    unlink "${aliasesDir}/aliases" if -e "${aliasesDir}/aliases";
    if( -e "${aliasesDir}/aliases.$$" ) {  
        rename "${aliasesDir}/aliases.$$", "${aliasesDir}/aliases";
    }

    unlink "/etc/mail/virtusertable" if -e "/etc/mail/virtusertable";
    if( -e "/etc/mail/virtusertable.$$" ) {
	rename "/etc/mail/virtusertable.$$", '/etc/mail/virtusertable';
	chdir('/etc/mail');
	system('make', 'all');
    }

    unlink "/etc/mail/genericstable" if -e "/etc/mail/genericstable";
    if( -e "/etc/mail/genericstable.$$" ) {
	rename "/etc/mail/genericstable.$$", '/etc/mail/genericstable';
	unlink "/etc/mail/genericstable.db";
	chdir('/etc/mail');
	system('make', 'all');
    }

    unlink "/etc/mail/local-host-names" if -e "/etc/mail/local-host-names";
    if( -e "/etc/mail/local-host-names.$$" ) {
	rename "/etc/mail/local-host-names.$$", '/etc/mail/local-host-names';
	chdir('/etc/mail');
	system('make', 'restart');
    }
}
