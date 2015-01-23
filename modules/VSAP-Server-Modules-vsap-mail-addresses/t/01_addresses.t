use Test::More tests => 45;
no warnings 'all';

BEGIN { use_ok('VSAP::Server::Modules::vsap::mail::addresses') };
    
#########################

use VSAP::Server::Test::Account;
use VSAP::Server::Modules::vsap::config;

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
my $aliasDir;
if ($is_linux) {
    $aliasDir = '/etc';
} else {
    $aliasDir = '/etc/mail';
}
unless( -e '${aliasDir}/aliases' ) {
    system "touch ${aliasDir}/aliases";
}
system "/bin/cp ${aliasDir}/aliases ${aliasDir}/aliases.$$";

open ALIASES, ">>${aliasDir}/aliases"
  or die "Could not open ${aliasDir}/aliases: $!\n";
print ALIASES <<'_ALIASES_';
tubbing.com~majordomo:                  placeholder
tubbing.com~majordomo-owner:            placeholder
tubbing.com~owner-majordomo:            placeholder
tubbing.com~friends:                    placeholder
tubbing.com~friends2:			scott, ryan, jason
tubbing.com~friends-request:            placeholder
tubbing.com~friends-owner:              placeholder
tubbing.com~owner-friends:              placeholder
tubbing.com~friends-approval:           placeholder
_ALIASES_
close ALIASES;

##
## set up httpd.conf
##

system("/bin/cp /www/conf/httpd.conf /www/conf/httpd.conf.$$");

open HTTPD, ">>/www/conf/httpd.conf" or die "Couldn't open httpd.conf: $!";
print HTTPD <<EOF;
<VirtualHost tubbing.com:80 >
  ServerName tubbing.com
  User joebaz
</VirtualHost>
EOF
close HTTPD;

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
hyphen-name.tld
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

open VUT, ">/etc/mail/virtusertable"
  or die "Could not open virtusertable: $!\n";
print VUT <<'_VUT_';
##
## horkedmail.org
##
@horkedmail.org                         horked@gmail.com
scott@horkedmail.org                    scott
joe@horkedmail.org                      joe@yahoo.com
joefoo@horkedmail.org                    joefoo

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
friends2@tubbing.com                    tubbing.com~friends2
friends-request@tubbing.com             tubbing.com~friends-request
friends-owner@tubbing.com               tubbing.com~friends-owner
owner-friends@tubbing.com               tubbing.com~owner-friends
friends-approval@tubbing.com            tubbing.com~friends-approval

## spam honeypots
pc04@tubbing.com                        submit.1234567890@spam.spamcop.net

root@tubbing.com			nouser
postmaster@tubbing.com			nouser
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
chmod 0600, '/etc/mail/virtusertable';  ## BUG05042
chdir('/etc/mail');
system('make', 'all');
chdir($pwd);

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up users
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', password => 'joefoobar', fullname => 'Joe Foo', type => 'account-owner' } );
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', password => 'joebarbar', fullname => 'Joe Foo' } );
my $acctjoebaz = VSAP::Server::Test::Account->create( { username => 'joebaz', password => 'joebazbar', fullname => 'Joe Foo' } );
my $acctjoeblech = VSAP::Server::Test::Account->create( { username => 'joeblech', password => 'joeblechbar', fullname => 'Joe Foo' } );
ok( getpwnam('joefoo') && getpwnam('joebar') &&getpwnam('joebaz') &&getpwnam('joeblech') );

## temp cpx config file
system('cp', '-p', "/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$") if -e "/usr/local/etc/cpx.conf";

## MODULE TESTS

## As system admin ...

my $vsap = $acctjoefoo->create_vsap( ["vsap::auth", "vsap::logout", "vsap::domain", "vsap::mail::addresses"] );
my $t = $vsap->client({ username => 'joefoo', password => 'joefoobar' }) ; 
## list all addresses
my $de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
my @nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 40);

## list addresses for a given domain
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"><domain>tubbing.com</domain></vsap>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 17, "select all addresses");

## select system nodes
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address[system]');
is (scalar(@nodes), 3, "select system addresses");

## select non-system nodes
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address[not(system)]');
is (scalar(@nodes), 14, "select non-system addresses");

## add a new address
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>bob\@tubbing.com</source><dest>bob</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:add"]/status');
is($status, "ok");

## test listing of local mailbox, versus alias and address
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[dest = "joefoo"][1]/dest/@type');
is ($result, "local");

undef $t;
sleep 2;

### As nobody special ...

$t = $vsap->client({ username     => 'joebar', password     => 'joebarbar'});

## list all addresses
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 0);

undef $t;
sleep 2;

### As domain admin ...

$t = $vsap->client({ username     => 'joebaz', password     => 'joebazbar'});

my $co = new VSAP::Server::Modules::vsap::config (username => 'joebaz');
$co->add_domain("tubbing.com");
$co->domain("tubbing.com");
$co->domain_admin(set => 1);
$co->commit;
undef $co; ## this needs to be here so mail:addresses:list will not contend for the config object lock

## list addresses without a domain, as domain admin
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 18);

## try to add address without permission for that domain
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>billl\@table.com</source></vsap>!);
$status = $de->findvalue('/vsap/vsap[@type="mail:addresses:add"]/status');
is($status,"not ok");

## add address for domain with permission
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>catchboy\@tubbing.com</source><dest>catcher</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:add"]/status');
is($status, "ok");

$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);

## edit address
$de = $t->xml_response(qq!<vsap type="mail:addresses:update"><source>catchboy\@tubbing.com</source><dest>billyboy</dest></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
my $result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="catchboy@tubbing.com"]/dest');
is ($result, "billyboy");

##
## delete address
##
$de = $t->xml_response(qq!<vsap type="mail:addresses:delete"><source>catchboy\@tubbing.com</source></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 18);

##
## add list
##
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>danslist\@tubbing.com</source><dest>dan\@lk.com, jimbo, scottie</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:add"]/status');
is($status, "ok");

$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="danslist@tubbing.com"]/dest');
is($result, "dan\@lk.com, jimbo, scottie");

##
## edit list, replacing with a (varied) newline delimited list
##
$de = $t->xml_response(q!<vsap type="mail:addresses:update"><source>danslist@tubbing.com</source><dest>dan@lk.com&#010;ryan,jimbo&#010;&#013;scottie&#013;senorfoo@timpanogos.tld&#013;&#010;lastguy@here.foo&#010;,,,</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:update"]/status');
is($status, "ok", "newline delimieted list accepted");

$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="danslist@tubbing.com"]/dest');
is($result, q!dan@lk.com, ryan, jimbo, scottie, senorfoo@timpanogos.tld, lastguy@here.foo!, "newline list");

##
## edit list, replacing with address
##
$de = $t->xml_response(qq!<vsap type="mail:addresses:update"><source>danslist\@tubbing.com</source><dest>scottie</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:update"]/status');
is($status, "ok");

$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="danslist@tubbing.com"]/dest');
is($result, "scottie");

##
## edit address, replacing with list
##
$de = $t->xml_response(qq!<vsap type="mail:addresses:update"><source>danslist\@tubbing.com</source><dest>scottie, donniebrascoe, pl\@pl.cwo</dest></vsap>!);
my $status = $de->findvalue('/vsap/vsap[@type="mail:addresses:update"]/status');
is($status, "ok");

$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="danslist@tubbing.com"]/dest');
is($result, "scottie, donniebrascoe, pl\@pl.cwo");

##
## delete list
##
$de = $t->xml_response(qq!<vsap type="mail:addresses:delete"><source>danslist\@tubbing.com</source></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 18);

## add bouncing address
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>bouncer\@tubbing.com</source><dest type="reject"/></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 19);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="bouncer@tubbing.com"]/dest/@type');
is($result, "reject");

## add deleting address
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>deleter\@tubbing.com</source><dest type="delete"/></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 20);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="deleter@tubbing.com"]/dest/@type');
is($result, "delete");

## make sure dev-null entries are active in aliases file after adding deleting address
my $null = `egrep 'dev\-null:' ${aliasDir}/aliases`; chomp $null;
my $bit  = `egrep 'bit\-bucket:' ${aliasDir}/aliases`; chomp $bit;
like ($null, qr(^dev\-null:\s) );
like ($bit, qr(^bit\-bucket:\s) );

## list addresses for just one rhs
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"><rhs>scott</rhs></vsap>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 6);
$result = $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[1]/dest');
is($result, "scott");

## delete multiples
$de = $t->xml_response(qq!<vsap type="mail:addresses:delete"><source>friends\@tubbing.com</source><source>friends-request\@tubbing.com</source></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:list"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address');
is (scalar(@nodes), 18, "delete multiple test");

##
## BUG05171: hyphenated domain name
##

## become the SA
$t->quit; 
undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

$de = $t->xml_response(q!<vsap type="mail:addresses:add"><source>joe@hyphen-name.tld</source><dest>sherm</dest></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="mail:addresses:add"]/status'), "ok" );

## list
$de = $t->xml_response(q!<vsap type="mail:addresses:list"/>!);
ok( $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address[source="joe@hyphen-name.tld"]'), "hyphenated domain address added" );

##
## update hyphenated domain
##
$de = $t->xml_response(q!<vsap type="mail:addresses:update">
  <source>joe@hyphen-name.tld</source>
  <dest type="reject"/>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="mail:addresses:update"]/status'), "ok" );

$de = $t->xml_response(q!<vsap type="mail:addresses:list"/>!);
is( $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="joe@hyphen-name.tld"]/dest/@type'), 'reject', "hyphenated domain address updated" );

##
## delete hyphenated domain
##
$de = $t->xml_response(q!<vsap type="mail:addresses:delete">
  <source>joe@hyphen-name.tld</source>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="mail:addresses:delete"]/status'), "ok" );

$de = $t->xml_response(q!<vsap type="mail:addresses:list"/>!);
ok( ! $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address[source="joe@hyphen-name.tld"]'), "hyphenated domain address deleted" );

##
## check perms on 0600 aliases file
##
chmod 0600, '${aliasDir}/aliases';
$de = $t->xml_response(q!<vsap type="mail:addresses:list"/>!);
ok( $de->findnodes('/vsap/vsap[@type="mail:addresses:list"]/address[source="friends2@tubbing.com"]'), "alias with list of local users" );
is( $de->findvalue('/vsap/vsap[@type="mail:addresses:list"]/address[source="friends2@tubbing.com"]/dest'), "scott, ryan, jason", "alias with list of users target" );

# CLEANUP

END {
    getpwnam('joefoo')    && system q(vrmuser -y joefoo 2>/dev/null);
    getpwnam('joebar')    && system q(vrmuser -y joebar 2>/dev/null);
    getpwnam('joebaz')    && system q(vrmuser -y joebaz 2>/dev/null);
    getpwnam('joeblech')  && system q(vrmuser -y joeblech 2>/dev/null);

    unlink "${aliasDir}/aliases" if -e "${aliasDir}/aliases";
    if( -e "${aliasDir}/aliases.$$" ) {
        rename "${aliasDir}/aliases.$$", "${aliasDir}/aliases";
    }  

    unlink "/etc/mail/virtusertable" if -e "/etc/mail/virtusertable";
    if( -e "/etc/mail/virtusertable-backup.$$" ) {
        rename "/etc/mail/virtusertable-backup.$$", '/etc/mail/virtusertable';
        chdir('/etc/mail');
        system('make', 'all');
    }
    unlink "/www/conf/httpd.conf" if -e "/www/conf/httpd.conf";
    if( -e "/www/conf/httpd.conf.$$" ) {
        rename "/www/conf/httpd.conf.$$", '/www/conf/httpd.conf';
    }
 
    unlink "/etc/mail/local-host-names" if -e "/etc/mail/local-host-names";
    if( -e "/etc/mail/local-host-names-backup.$$" ) {
        rename "/etc/mail/local-host-names-backup.$$", '/etc/mail/local-host-names';
        chdir('/etc/mail');
        system('make', 'restart');
    }

    chdir($pwd);

    unlink '/usr/local/etc/cpx.conf';
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}

