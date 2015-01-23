use Test::More tests => 58;

warn <<_MAIL_;

NOTE: These tests *may* (though unlikely) disrupt normal mail flow.
NOTE: You shouldn't run this on a live server with legitimate mail
NOTE: traffic.
_MAIL_

BEGIN { use_ok('VSAP::Server::Modules::vsap::mail') };

#########################

use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

my $pwd = `pwd`; chomp $pwd;

##
## rebuild local-host-names
##
if( -e '/etc/mail/local-host-names' ) {
    rename '/etc/mail/local-host-names', "/etc/mail/local-host-names-backup.$$"
      or die "Could not rename local-host-names: $!\n";
}

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

my $hostname = `hostname`; chomp $hostname;
open LHN, ">/etc/mail/local-host-names"
  or die "Could not open local-host-names: $!\n";
print LHN <<_LHN_;
$hostname
tubbing.com
tubbing.net
tubbing.org
extremesledding.net
extremesledding.org
savelogs.org
mailblock.net
_LHN_
close LHN;
chdir('/etc/mail');
system('make', 'restart');
chdir($pwd);

##
## rebuild virtusertable
##
if( -e '/etc/mail/virtusertable' ) {
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable-backup.$$"
      or die "Could not rename virtusertable: $!\n";
}

## try to create virtusertable
VSAP::Server::Modules::vsap::mail::domain_catchall('mailblock.net', '/dev/null');
my $ca = `egrep -C2 '^\@mailblock.net' /etc/mail/virtusertable`;
like( $ca, qr(^\@mailblock\.net                          /dev/null), 'create virtusertable entry' );

select undef, undef, undef, 1.3;  ## needed for make to detect a change in virtusertable
## overwrite virtusertable
open VUT, ">/etc/mail/virtusertable"
  or die "Could not open virtusertable: $!\n";
print VUT <<'_VUT_';
##
## horkedmail.org
##
@horkedmail.org                         horked@gmail.com
scott@horkedmail.org                    scott
joe@horkedmail.org                      joe@yahoo.com

##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## tubbing.com
##

webmaster@tubbing.com                   scott
scott@tubbing.com                       scott
ryan@tubbing.com                        ryan
jason@tubbing.com                       jason

## majordomo admininstrative
majordomo@tubbing.com                   tubbing.com~majordomo
majordomo-owner@tubbing.com             tubbing.com~majordomo-owner
owner-majordomo@tubbing.com             tubbing.com~owner-majordomo

## majordomo friends of tubbing list
friends@tubbing.com                     tubbing.com~friends
friends-request@tubbing.com             tubbing.com~friends-request
friends-owner@tubbing.com               tubbing.com~friends-owner
owner-friends@tubbing.com               tubbing.com~owner-friends
friends-approval@tubbing.com            tubbing.com~friends-approval

## spam honeypots
pc04@tubbing.com                        submit.1234567890@spam.spamcop.net

@tubbing.com                            nouser
@tubbing.net                            nouser
@tubbing.org                            nouser
@extremesledding.net                    nouser
@extremesledding.org                    nouser
@savelogs.org                           nouser

##
## mailblock.net
##
mwalters21@mailblock.net                nouser
pfw1@mailblock.net                      nouser
geo9@mailblock.net                      scott
mwalters23@mailblock.net                nouser
mwalters24@mailblock.net                nouser
mwalters25@mailblock.net                nouser
ppj5@mailblock.net                      nouser
scott@mailblock.net                     scott
@mailblock.net                          nouser
_VUT_
close VUT;
chdir('/etc/mail');
system('make', 'all');
chdir($pwd);

##
## test domain_virtusertable
##
is( keys %{ VSAP::Server::Modules::vsap::mail::domain_virtusertable('mailblock.net') },  9, 'testing virtusertable entries for mailblock.net' );
is( keys %{ VSAP::Server::Modules::vsap::mail::domain_virtusertable('savelogs.org') },   1, 'testing virtusertable entries for savelogs.org' );
is( keys %{ VSAP::Server::Modules::vsap::mail::domain_virtusertable('tubbing.com') },   14, 'testing virtusertable entries for tubbing.com' );

my $vm = VSAP::Server::Modules::vsap::mail::domain_virtusertable('tubbing.com');
is( $vm->{'majordomo@tubbing.com'} => 'tubbing.com~majordomo', 'Test virtusertable entries for tubbing.com majoromo' );
is( $vm->{'@tubbing.com'} => 'nouser', 'Testing that tubbing.com does not have a user' );

##
## test addr_virtusertable
##
is( scalar @{ VSAP::Server::Modules::vsap::mail::addr_virtusertable('scott') },  6, 'Testing addr_virtusertable for scott' );
is( scalar @{ VSAP::Server::Modules::vsap::mail::addr_virtusertable('scotty') }, 0, 'Testing addr_virtusertable for scotty' );
is( scalar @{ VSAP::Server::Modules::vsap::mail::addr_virtusertable('scot') },   0 );
is( scalar @{ VSAP::Server::Modules::vsap::mail::addr_virtusertable('ryan') },   1, 'Testing addr_virtusertable for ryan' );
is( scalar @{ VSAP::Server::Modules::vsap::mail::addr_virtusertable('nouser') }, 13, 'Testing addr_virtusertable for nouser' );
my @addrs = @{VSAP::Server::Modules::vsap::mail::addr_virtusertable('submit.1234567890@spam.spamcop.net')};
is( scalar @addrs, 1, 'testing addr_virtusertable for spam.spamcop.net' );
is( $addrs[0], 'pc04@tubbing.com', 'testing addr_virtusertable for pc04@tubbing.com' );

##
## test is_local
##
is( VSAP::Server::Modules::vsap::mail::is_local('foo@tubbing.com'), 'nouser', 'Testing if foo@tubbing.com is local' );
is( VSAP::Server::Modules::vsap::mail::is_local('friends@tubbing.com'), 'tubbing.com~friends', 'Testing if tubbing.com~friends is local' );
is( VSAP::Server::Modules::vsap::mail::is_local('pc04@tubbing.com'), undef, 'Testing if pc04@tubbing.com is not valid' );

##
## domain catchall
##

## replace an existing catchall
VSAP::Server::Modules::vsap::mail::domain_catchall('mailblock.net', '/dev/null');
$ca = `egrep -C2 '^\@mailblock.net' /etc/mail/virtusertable`;
like( $ca, qr(^ppj5\@mailblock\.net                      nouser
scott\@mailblock\.net                     scott
\@mailblock\.net                          /dev/null) );

## replace a lone catchall
VSAP::Server::Modules::vsap::mail::domain_catchall('tubbing.net', '/dev/null');
$ca = `egrep -C2 '^\@tubbing\.net' /etc/mail/virtusertable`;
like( $ca, qr(^
\@tubbing\.com                            nouser
\@tubbing\.net                            /dev/null
\@tubbing\.org                            nouser
\@extremesledding\.net                    nouser) );

## create a new entry
VSAP::Server::Modules::vsap::mail::domain_catchall('frobnitz.org', 'nouser');
$ca = `egrep -C2 '^\@frobnitz\.org' /etc/mail/virtusertable`;
like( $ca, qr(^scott\@mailblock\.net                     scott
\@mailblock\.net                          /dev/null
\@frobnitz\.org                           nouser) );

## replace a catchall that is not the last instance of its domain
VSAP::Server::Modules::vsap::mail::domain_catchall('horkedmail.org', 'nouser');
$ca = `egrep -C2 '^\@horkedmail\.org' /etc/mail/virtusertable`;
like( $ca, qr(^## horkedmail.org
##
\@horkedmail\.org                         nouser
scott\@horkedmail\.org                    scott
joe\@horkedmail\.org                      joe\@yahoo\.com) );

select undef, undef, undef, 1.3;  ## needed for timing test next

## create a new catchall for existing domain w/o catchall
VSAP::Server::Modules::vsap::mail::domain_catchall('swedishbork.com', 'nouser');
$ca = `egrep -C2 '^\@swedishbork\.com' /etc/mail/virtusertable`;
like( $ca, qr(^##
scott\@swedishbork\.com                   scott
\@swedishbork\.com                        nouser) );

ok( (lstat("/etc/mail/virtusertable"))[9] <= (lstat("/etc/mail/virtusertable.db"))[9], "vut db rebuilt" );

## 
## test all_virtusertable
##

is( keys %{ VSAP::Server::Modules::vsap::mail::all_virtusertable() }, 34 );

## 
## add basic entry (should appear before catchall)
## 
VSAP::Server::Modules::vsap::mail::add_entry('bill@tubbing.com', 'bill');
$ca = `egrep -C2 'bill\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(bill\@tubbing\.com                        bill
\@tubbing\.com                            nouser) );

##
## update entry
##
VSAP::Server::Modules::vsap::mail::update_entry('bill@tubbing.com', 'charlie');
is( keys %{ VSAP::Server::Modules::vsap::mail::all_virtusertable() }, 35 );
$ca = `egrep -C2 'bill\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(bill\@tubbing\.com                        charlie
\@tubbing\.com                            nouser) );

## 
## delete entry
##
VSAP::Server::Modules::vsap::mail::delete_entry('bill@tubbing.com');
is( keys %{ VSAP::Server::Modules::vsap::mail::all_virtusertable() }, 34 );
$ca = `egrep -C2 'bill\@tubbing\.com' /etc/mail/virtusertable`;
unlike( $ca, qr(bill\@tubbing\.com\s+\S+) );

##
## add long entry
##
VSAP::Server::Modules::vsap::mail::add_entry('hisroyalexcellencyollivershagnaster@tubbing.com', 'bill');
$ca = `egrep -C2 'hisroyal' /etc/mail/virtusertable`;
like( $ca, qr(hisroyalexcellencyollivershagnaster\@tubbing\.com\s+bill
\@tubbing\.com                            nouser), "long virtmap entry" );

select undef,undef,undef,1.5; ## needed for time test next

##
## add list/alias entry
##
VSAP::Server::Modules::vsap::mail::add_entry('list@tubbing.com', 'dan, phil, jon@pl.com');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(list\@tubbing\.com                        tubbing.com~list) );

$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
like( $ca, qr(tubbing\.com~list:                       dan, phil, jon\@pl\.com) );

ok( (lstat("/etc/mail/virtusertable"))[9] <= (lstat("/etc/mail/virtusertable.db"))[9], "vut db rebuilt" );
ok( (lstat("${aliasesDir}/aliases"))[9]       <= (lstat("${aliasesDir}/aliases.db"))[9], "aliases db rebuilt" );

## BUG05124: remove all but one rhs; check to remove orphaned alias
VSAP::Server::Modules::vsap::mail::update_entry('list@tubbing.com', 'nodan');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(list\@tubbing\.com\s+nodan) );
$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
is( $ca, '', "no more alias" );


##
## update list/alias entry
##
VSAP::Server::Modules::vsap::mail::update_entry('list@tubbing.com', 'nodan, nophil, nojon@pl.com');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(list\@tubbing\.com                        tubbing.com~list) );

$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
like( $ca, qr(tubbing\.com~list:                       nodan, nophil, nojon\@pl\.com));
unlike( $ca, qr(tubbing\.com~list:                       dan, phil, jon\@pl\.com));

## 
## get alias rhs 
##
my $rhs = VSAP::Server::Modules::vsap::mail::get_alias_rhs('tubbing.com~list');
is($rhs, 'nodan, nophil, nojon@pl.com');

##
## delete list/alias entry
##
my $wc = `wc ${aliasesDir}/aliases`;
VSAP::Server::Modules::vsap::mail::delete_entry('list@tubbing.com');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
unlike( $ca, qr(list\@tubbing\.com                        tubbing.com~list) );
isnt($wc, `wc ${aliasesDir}/aliases`);

$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
unlike( $ca, qr(tubbing\.com~list:                       dan, phil, jon\@pl\.com));
$wc = `wc ${aliasesDir}/aliases`;

## delete nonexistant alias entry
VSAP::Server::Modules::vsap::mail::delete_entry('list@tubbing.com');
is($wc, `wc ${aliasesDir}/aliases`);

## localhostname tests
##

## the way it is
$ca = `egrep tubbing\.net /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^tubbing\.net$), "lhn - grok" );

## disable
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.net',
                                                action => 'disable');
$ca = `egrep tubbing\.net /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^#tubbing\.net$), "lhn - disable domain" );

## disable again (no duplicate #)
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.net',
                                                action => 'disable');
$ca = `egrep tubbing\.net /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^#tubbing\.net$), "lhn - duplicate disable domain" );

## enable now
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.net',
                                                action => 'enable');
$ca = `egrep tubbing\.net /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^tubbing\.net$), "lhn - enable domain" );

## add new domain
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.info',
                                                action => 'add');
$ca = `egrep tubbing\.info /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^tubbing\.info$), "lhn - add new domain" );

## add again (check for duplicates)
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.info',
						 action => 'add');
$ca = `egrep tubbing\.info /etc/mail/local-host-names`; chomp $ca;
like( $ca, qr(^tubbing\.info$), "lhn - don't add duplicate" );

## remove domain
VSAP::Server::Modules::vsap::mail::localhostname(domain => 'tubbing.info',
                                                action => 'delete');
$ca = `egrep tubbing\.info /etc/mail/local-host-names`; chomp $ca;
is( $ca, '', "lhn - remove domain" );

##
## test remove_domain
##

## setup domain
VSAP::Server::Modules::vsap::mail::add_entry('list@tubbing.com', 'dan, phil, jon@pl.com');
VSAP::Server::Modules::vsap::mail::add_entry('list2@tubbing.com', 'dan, scott, jon@pl.com');
VSAP::Server::Modules::vsap::mail::add_entry('list3@tubbing.com', 'dan, fred, jon@pl.com');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
like( $ca, qr(list\@tubbing\.com\s+tubbing.com~list
list2\@tubbing\.com\s+tubbing.com~list2
list3\@tubbing\.com\s+tubbing.com~list3) );

$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
like( $ca, qr(tubbing\.com~list:\s+dan, phil, jon\@pl\.com
tubbing\.com~list2:\s+dan, scott, jon\@pl\.com
tubbing\.com~list3:\s+dan, fred, jon\@pl\.com) );

## remove whole domain from virtmaps and aliases
VSAP::Server::Modules::vsap::mail::delete_domain('tubbing.com');
$ca = `egrep -C2 'list\@tubbing\.com' /etc/mail/virtusertable`;
is( $ca, '' );

$ca = `egrep -C2 'tubbing\.com~list' ${aliasesDir}/aliases`;
is( $ca, '' );

VSAP::Server::Modules::vsap::mail::check_devnull;
$ca = `egrep '^bit-bucket' ${aliasesDir}/aliases`; chomp $ca;
like( $ca, qr(^bit-bucket:\s+/dev/null$) );
$ca = `egrep '^dev-null' ${aliasesDir}/aliases`; chomp $ca;
like( $ca, qr(^dev-null:\s+bit-bucket) );


##
## test add_entry granularity: if we add more than one entry per
## second, 'make' will not detect them.
##
my %names = map { sprintf("zed%02d", $_) => 1 } (1..30);
for my $lhs ( sort keys %names ) {
    VSAP::Server::Modules::vsap::mail::add_entry("$lhs\@tubbing.com" => 'dan');
}

my $vutout = `makemap -u hash /etc/mail/virtusertable.db | egrep '^zed' | wc -l`;
$vutout =~ s/\s//g;
is( $vutout, scalar keys %names, "same number of keys as addresses" );


END {
    unlink "${aliasesDir}/aliases" if -e "${aliasesDir}/aliases";
    if( -e "${aliasesDir}/aliases.$$" ) {  
        rename "${aliasesDir}/aliases.$$", "${aliasesDir}/aliases";
    }

    unlink "/etc/mail/virtusertable" if -e "/etc/mail/virtusertable";
    if( -e "/etc/mail/virtusertable-backup.$$" ) {
	rename "/etc/mail/virtusertable-backup.$$", '/etc/mail/virtusertable';
        unlink "/etc/mail/virtusertable-backup.$$";
	chdir('/etc/mail');
	system('make', 'all');
    }

    unlink "/etc/mail/local-host-names" if -e "/etc/mail/local-host-names";
    if( -e "/etc/mail/local-host-names-backup.$$" ) {
	rename "/etc/mail/local-host-names-backup.$$", '/etc/mail/local-host-names';
	chdir('/etc/mail');
	system('make', 'restart');
    }
}
