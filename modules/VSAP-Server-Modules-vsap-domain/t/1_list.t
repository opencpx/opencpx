use Test::More tests => 65;
BEGIN { use_ok('VSAP::Server::Modules::vsap::domain') };

#########################

use VSAP::Server::Test::Account;

use POSIX;
our $LVPS = 0;  # Linux
our $VPS2 = 0;  # FreeBSD 4.x
our $VPS3 = 0;  # FreeBSD 6.x
if ((POSIX::uname())[0] =~ /Linux/i) { 
    $LVPS = 1;
} elsif ((POSIX::uname())[0] =~ /FreeBSD/i) { 
    if ((POSIX::uname())[2] =~ /^4/) { 
        $VPS2 = 1;
    } elsif ((POSIX::uname())[2] =~ /^6/) { 
        $VPS3 = 1;
    }
}

## make sure our user does not exist

my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar', type => 'account-owner' });
# Need to make joefoo an administrator by adding to wheel group.
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', fullname => 'Joe Foo', password => 'joebarbar' });
my $acctjoebaz = VSAP::Server::Test::Account->create( { username => 'joebaz', fullname => 'Joe Foo', password => 'joebazbar' });
my $acctjoeblech = VSAP::Server::Test::Account->create( { username => 'joeblech', fullname => 'Joe Foo', password => 'joebazbar' });
my $acctjoesablech = VSAP::Server::Test::Account->create( { username => 'joesablech', fullname => 'Joe SA Blech', password => 'joebazbar' });

ok($acctjoefoo->exists, "joefoo exists");
ok($acctjoebar->exists, "joebar exists");
ok($acctjoebaz->exists, "joebaz exists");
ok($acctjoeblech->exists, "joeblech exists");
ok($acctjoesablech->exists, "joesablech exists");

## TODO make this /etc/passwd.master on freebsd.
$PASSWD_FILE = (-f '/etc/passwd.master' ? '/etc/passwd.master' : '/etc/passwd');

## FIXME: added new users; assign these to domains now for later tests

system('cp', '-p', '/etc/crontab', "/etc/crontab.$$");
system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$")
	if ($ENV{VST_PLATFORM} eq 'VPS2');

## fix Apache
{
    rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
      if -e "/usr/local/etc/cpx.conf";

    ## a-patch-y fix
    my $ip    = `sinfo | egrep '^ip' | awk '{print \$2}'`; chomp $ip;
    my $admin = `sinfo | egrep '^account'    | awk '{print \$2}'`; chomp $admin;
    print STDERR "Using '$ip' for ip address\n" if $ENV{VSAPD_DEBUG};
    print STDERR "Using '$admin' for admin\n"   if $ENV{VSAPD_DEBUG};

    ## move apache config file
    system('cp', '-rp', "/www/conf/httpd.conf", "/www/conf/httpd.conf.$$")
      if -e "/www/conf/httpd.conf";

    open CONF, ">>/www/conf/httpd.conf"
      or die "Could not open Apache conf for append: $!\n";
    print CONF <<_CONFFILE_;
## DELETE THIS: vsap::domain test begins here

## vaddhost: (foo-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     foo-$$.com
    ServerAlias    www.foo-$$.com
    ServerAdmin    webmaster\@foo-$$.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    TransferLog    /www/logs/joefoo/foo-$$.com-access_log
    ErrorLog       /dev/null
</VirtualHost>

## vaddhost: (bar-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/bar-$$.com
    ServerName     bar-$$.com
    ServerAlias    www.bar-$$.com
</VirtualHost>

## vaddhost: (baz-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/baz-$$.com
    ServerName     baz-$$.com
    ServerAlias    www.baz-$$.com
</VirtualHost>

## vaddhost: (baz-$$.com) at $ip:443
<VirtualHost $ip:443>
    SSLEnable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/baz-$$.com
    ServerName     baz-$$.com
    ServerAlias    www.baz-$$.com
</VirtualHost>

## vaddhost: (blech-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           $admin
    Group          $admin
    ServerName     blech-$$.com
    ServerAlias    www.blech-$$.com
    ServerAlias    www.blech-$$.org blech-$$.org
    ServerAlias    blech-$$.net www.blech-$$.net
</VirtualHost>
_CONFFILE_
    close CONF;
}

my $vsap = $acctjoefoo->create_vsap(['vsap::domain',
                               'vsap::mail::addresses']);

$t = $vsap->client({ username => 'joefoo', password => 'joefoobar' }); 
ok(ref($t), 'obtained a vsap client for joefoo');

my $de;

my $co;
for my $user qw(joebar joebaz joeblech) {
    $co = new VSAP::Server::Modules::vsap::config( username => $user );
    $co->domain("foo-$$.com");
    undef $co;
}

$co = new VSAP::Server::Modules::vsap::config( username => 'joesablech' );
undef $co;

## add some email addresses for joefoo
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>joefoo\@foo-$$.com</source><dest>joefoo</dest></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>srfoo\@foo-$$.com</source><dest>joefoo</dest></vsap>!);
$de = $t->xml_response(qq!<vsap type="mail:addresses:add"><source>srfoo\@baz-$$.com</source><dest>joefoo</dest></vsap>!);

##
## list a bogus user joeboo
##
$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joeboo</admin></vsap>!);
ok( ! $de->find('/vsap/vsap[@type="domain:list"]/domain'), "no bogus domain" );
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(domain admin missing)i, "correct message for missing domain admin");

##
## list all domains (joefoo is server_admin)
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"/>!);
my @domains = $de->findnodes('/vsap/vsap[@type="domain:list"]/domain');
ok( scalar(@domains) >= 5, "domain count" ); ## server domain + our vhosts + (any existing vhosts)
my $admin = `sinfo | egrep '^account'    | awk '{print \$2}'`; chomp $admin;

is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='foo-$$.com']/admin"), 'joefoo', "joefoo is an admin for foo-$$.com");
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='bar-$$.com']/admin"), 'joefoo', "joefoo is an admin for bar-$$.com");
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='baz-$$.com']/admin"), 'joefoo', "joefoo is an admin for baz-$$.com");
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='blech-$$.com']/admin"), $admin, "$admin is an admin for blech-$$.com");

##
## list primary domain (BUG04492)
##
my $pass = `egrep '^$admin:' $PASSWD_FILE`; chomp $pass;
die unless $pass =~ /^$admin:/;
my $password = '';

NEW_PASSWORD: {
    ## make random password
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9', '/', '.');
    $password = $chars[rand @chars] . $chars[rand @chars] . 
      $chars[rand @chars] . $chars[rand @chars] . 
        $chars[rand @chars] . $chars[rand @chars] . 
	  $chars[rand @chars] . $chars[rand @chars];
    my $salt = $chars[rand @chars] . $chars[rand @chars];
    my $newpass = crypt($password, $salt);

    if ($ENV{VST_PLATFORM} eq 'LVPS2') { 
	system('usermod', '-p', $newpass, $admin);
    } else { 
	system('chpass', '-p', $newpass, $admin);
    }
}

$t->quit;
undef $t;

print STDERR "creating a new client using $admin and $password";
$t = $vsap->client({ username => $admin, password => $password } );
my $hostname = `hostname`; chomp $hostname;

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>$hostname</domain><diskspace/></vsap>!);
my $base_du = $de->findvalue("/vsap/vsap/domain[name='$hostname']/diskspace/usage");

## make a primary EU take up space (should affect primary domain space metrics)
{
    local $> = getpwnam('joesablech');
    open FILE, ">/home/joesablech/phat";
    print FILE '.' x (1024*1024*20);
    close FILE;
}


undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>$hostname</domain><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='$hostname']/diskspace/usage"), ($base_du+20), "primary domain disk usage" );

is( $de->findvalue("/vsap/vsap/domain[\@type='server']/name"), $hostname, "hostname has server type" ) ||
	diag $de->toString(1);

## make a DA take up space (should not affect primary domain space metrics)
{
    local $> = getpwnam('joefoo');
    open FILE, ">/home/joefoo/phat";
    print FILE '.' x (1024*1024*20);
    close FILE;
}
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>$hostname</domain><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='$hostname']/diskspace/usage"), ($base_du+20), "primary domain disk usage" );

unlink "/home/joefoo/phat", "/home/joesablech/phat";

## -- all done for primary domain diskuse tests -- ##


##
## put things back
##
$t->quit;
undef $t;
$t = $vsap->client( { username => 'joefoo', password => 'joefoobar' } );

##
## list domains for a particular user
##
undef $de;

## this will test perms on /etc/mail/virtusertable
chmod 0600, '/etc/mail/virtusertable';

$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joefoo</admin></vsap>!);
@domains = $de->findnodes('/vsap/vsap[@type="domain:list"]/domain');
is( scalar(@domains), 3, "domain count for admin" );

## make sure user and email count is correct
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='foo-$$.com']/users/usage"), 3 );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='foo-$$.com']/mail_aliases/usage"), 2 );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='baz-$$.com']/users/usage"), 0 );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='baz-$$.com']/mail_aliases/usage"), 1 );

##
## initialize the <domain> nodes for these domains
##
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );
$co->disk_limit("foo-$$.com", 20);
$co->alias_limit("foo-$$.com", 'unlimited');
$co->user_limit("foo-$$.com", 10);
$co->disk_limit("bar-$$.com", 30);
$co->disk_limit("baz-$$.com", 10);
undef $co;

##
## test nodes (disk limits, alias limits, etc.)
##

## domains for joefoo
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joefoo</admin><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/diskspace/limit"), 20, "disk limits" );
is( $de->findvalue("/vsap/vsap/domain[name='bar-$$.com']/diskspace/limit"), 30, "(ditto)" );
is( $de->findvalue("/vsap/vsap/domain[name='baz-$$.com']/diskspace/limit"), 10, "(ditto)" );

is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/diskspace/usage"), 0, "disk usage" );
is( $de->findvalue("/vsap/vsap/domain[name='bar-$$.com']/diskspace/usage"), 0, "(ditto)" );
is( $de->findvalue("/vsap/vsap/domain[name='baz-$$.com']/diskspace/usage"), 0, "(ditto)" );


my $acctjoefoo1 = VSAP::Server::Test::Account->create( { username => 'joefoo1', fullname => 'Joe Foo 1', password => 'joebarbar' });
my $acctjoefoo2 = VSAP::Server::Test::Account->create( { username => 'joefoo2', fullname => 'Joe Foo 2', password => 'joebarbar' });
my $acctjoefoo3 = VSAP::Server::Test::Account->create( { username => 'joefoo3', fullname => 'Joe Foo 3', password => 'joebarbar' });
my $acctjoebar1 = VSAP::Server::Test::Account->create( { username => 'joebar1', fullname => 'Joe Bar 1', password => 'joebarbar' });
my $acctjoebar2 = VSAP::Server::Test::Account->create( { username => 'joebar2', fullname => 'Joe Bar 2', password => 'joebarbar' });
ok($acctjoefoo1->exists, "joefoo1 exists");
ok($acctjoefoo2->exists, "joefoo2 exists");
ok($acctjoebar1->exists, "joebar1 exists");
ok($acctjoebar2->exists, "joebar2 exists");


## assign users to domains
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo1' );
$co->domain("foo-$$.com");
$co->init( username => 'joefoo2' );
$co->domain("foo-$$.com");
$co->init( username => 'joefoo3' );
$co->domain("foo-$$.com");
$co->init( username => 'joebar1' );
$co->domain("bar-$$.com");
$co->init( username => 'joebar2' );
$co->domain("bar-$$.com");

## double-check
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );
my %users = %{$co->users(domain => "foo-$$.com")};
is( keys(%users), 6, "new users count" );

#print STDERR "KEYS: $_\n" for keys(%users);
#print STDERR $co->{dom}->toString(1);
undef $co;

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joefoo</admin><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/diskspace/usage"), 0, "disk usage" );
is( $de->findvalue("/vsap/vsap/domain[name='bar-$$.com']/diskspace/usage"), 0, "(ditto)" );
is( $de->findvalue("/vsap/vsap/domain[name='baz-$$.com']/diskspace/usage"), 0, "(ditto)" );
is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/mail_aliases/usage"), 2, "mail aliases" );


## use some space
{
    local $> = getpwnam('joefoo1');
    open FILE, ">/home/joefoo1/phat";
    print FILE '.' x (1024*1024*9.9);
    close FILE;

    local $> = getpwnam('joefoo2');
    open FILE, ">/home/joefoo2/phat";
    print FILE '.' x (1024*1024*9.9);
    close FILE;

    local $> = getpwnam('joebar1');
    open FILE, ">/home/joebar1/phat";
    print FILE '.' x (1024*1024*9.9);
    close FILE;
}

$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joefoo</admin><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/diskspace/usage"), 20, "disk usage" );
is( $de->findvalue("/vsap/vsap/domain[name='bar-$$.com']/diskspace/usage"), 10, "(ditto)" );
is( $de->findvalue("/vsap/vsap/domain[name='baz-$$.com']/diskspace/usage"), 0, "(ditto)" );

## take up some space in a domain
{
    local $> = getpwnam('joefoo');

    system('mkdir', '-p', "/home/joefoo/www/bar-$$.com");
    open FILE, ">/home/joefoo/www/bar-$$.com/phat"
      or do "Could not open file: $!\n";
    print FILE '.' x (1024*1024*5);
    close FILE;
    ok( -s "/home/joefoo/www/bar-$$.com/phat" >= 5000000, "phat file created" );

    system('mkdir', '-p', "/home/joefoo/www/baz-$$.com");
    open FILE, ">/home/joefoo/www/baz-$$.com/phat"
      or do "Could not open file: $!\n";
    print FILE '.' x (1024*1024*15);
    close FILE;
    ok( -s "/home/joefoo/www/baz-$$.com/phat" >= 15000000, "phat file created" );
}

$de = $t->xml_response(qq!<vsap type="domain:list"><admin>joefoo</admin><diskspace/></vsap>!);
is( $de->findvalue("/vsap/vsap/domain[name='foo-$$.com']/diskspace/usage"), 20, "disk usage (foo-$$.com)" );
is( $de->findvalue("/vsap/vsap/domain[name='bar-$$.com']/diskspace/usage"), 15, "(ditto - bar-$$.com)" );
is( $de->findvalue("/vsap/vsap/domain[name='baz-$$.com']/diskspace/usage"), 15, "(ditto - baz-$$.com)" );

##
## test get_vhost
##
my %vhosts = VSAP::Server::Modules::vsap::domain::get_vhost("baz-$$.com");
like( $vhosts{ssl}, qr(ServerName\s+baz-$$\.com)i );
like( $vhosts{ssl}, qr(SSLEnable)i );
like( $vhosts{nossl}, qr(ServerName\s+baz-$$\.com)i );
like( $vhosts{nossl}, qr(SSLDisable)i );

##
## test properties
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/services/ssl'), 0 );
is( $de->findvalue('/vsap/vsap/domain/services/cgi'), 1 );
is( $de->findvalue('/vsap/vsap/domain/domain_contact'), "webmaster\@foo-$$.com" );
is( $de->findvalue('/vsap/vsap/domain/catchall'), 'none' );
is( $de->findvalue('/vsap/vsap/domain/www_alias'), 1 );
is( $de->findvalue('/vsap/vsap/domain/www_logs'), "/www/logs/joefoo" );
is( $de->findvalue('/vsap/vsap/domain/www_elogs'), "none" );
is( $de->findvalue('/vsap/vsap/domain/log_rotation'), 'none');
is( $de->findvalue('/vsap/vsap/domain/disabled'), 0 );
my $docroot;
if ($LVPS) {
    $docroot = '/var/www/html';
} elsif ($VPS2) {
    $docroot = '/usr/local/apache/htdocs';
} elsif ($VPS3) {
    $docroot = '/usr/local/apache2/htdocs';
}
is( $de->findvalue('/vsap/vsap/domain/doc_root'), $docroot );


## change enabled to disabled
$t->xml_response(qq!<vsap type="domain:disable"><domain>foo-$$.com</domain></vsap>!);
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/disabled'), 1 );

## change to enabled
$t->xml_response(qq!<vsap type="domain:enable"><domain>foo-$$.com</domain></vsap>!);
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/disabled'), 0 );

##
## change the catchall
##

## move virtusertable
rename("/etc/mail/virtusertable", "/etc/mail/virtusertable.$$");

use VSAP::Server::Modules::vsap::mail;
system('touch', '/etc/mail/virtusertable');
VSAP::Server::Modules::vsap::mail::domain_catchall("foo-$$.com", 'joefoo');

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/catchall'), 'admin' );

VSAP::Server::Modules::vsap::mail::domain_catchall("foo-$$.com", 'joefoo@yahoo.com');

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/catchall'), 'joefoo@yahoo.com' );

## FIXME: add test for disabling logging at all; should disable rotation too

## try different rotations
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>foo-$$.com</domain>
  <website_logs>1</website_logs>
  <log_rotate>weekly</log_rotate>
</vsap>!);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/log_rotation'), 'weekly');

##
## check server alias properties
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>blech-$$.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/other_aliases'), "blech-$$.net, www.blech-$$.net, blech-$$.org, www.blech-$$.org", "other server aliases" );

END {
    print STDERR "Restoring account password entry...\n";
    system('chpass', '-a', $pass);

    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf")
      if -e "/www/conf/httpd.conf.$$";
    rename("/etc/mail/virtusertable.$$", "/etc/mail/virtusertable");
    my $wd = `pwd`; chomp $wd;
    chdir('/etc/mail');
    system('make', 'maps')
	unless ($ENV{VST_PLATFORM} eq 'LVPS2');
    chdir($wd);
    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
	   "/www/conf/httpd.conf");
    system('apachectl graceful 2>&1 >/dev/null');
    rename "/etc/crontab.$$", '/etc/crontab'
	if -f "/etc/crontab.$$";
}
