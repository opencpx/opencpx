use Test::More tests => 124;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };
BEGIN { use_ok('VSAP::Server::Test::Account') };
#########################

my $user = 'joefoo';

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

my $co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');

##
## bogus users do not have any capabilities
##
ok( ! $co->fullname );
ok( ! $co->comments );
ok( ! $co->eu_prefix   );
ok( ! $co->domain   );
undef $co;

use_ok('POSIX');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

## set up a user w/ mail, ftp
$acct = VSAP::Server::Test::Account->create( { username => $user, fullname => 'Joe Foo', password => 'joefoobar' });
ok( $acct->exists, "$user exists");

##
## try bogus user
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefooasdflkj');
ok( ref($co) );
ok( ! $co->is_valid, 'Checking that bogus user is not valid' );

##
## will check platform and update capa accordingly...
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->fullname, "Joe Foo" , 'Verifying full name');
undef $co;
ok( -f '/usr/local/etc/cpx.conf', "config file exists" );

if ($is_linux)
{
	system('usermod -c "Foo, Joe" joefoo');  ## new fullname
} else {
	system('pw usermod joefoo -c "Foo, Joe"');  ## new fullname
}
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->fullname, "Joe Foo" , 'Checking full name after changing via usermod');

$co->fullname("Joseph Foo, Esquire");
is( $co->fullname, "Joseph Foo, Esquire" , 'Checking full name in config');
is( (getpwnam('joefoo'))[6], "Foo, Joe" , 'Checking full name in passwd file');

##
## check domain
##
my $domain = `hostname`; chomp $domain;
is( $co->domain, $domain, "domain check" );
$co->domain("foo.com");
is( $co->domain, 'foo.com', "domain check after change" );
undef $co;

$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->domain, 'foo.com', "domain check" );
undef $co;

##
## check comments
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->comments( 'This is a test user.' );
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->comments, 'This is a test user.', "comments check" );
undef $co;

##
## check eu_prefix
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->eu_prefix( 'joefoo_' );
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->eu_prefix, 'joefoo_', "eu_prefix check" );
undef $co;

## 
## Check another user
##
my $acctjoefoobar = VSAP::Server::Test::Account->create( { username => 'joefoobar', fullname => 'Joe Foo Bar', password => 'joefoobarp' });
my $acctjoquux = VSAP::Server::Test::Account->create( { username => 'joequux', fullname => 'Joe Foo Quux', password => 'joefoobarp' });
my $acctjoequuux = VSAP::Server::Test::Account->create( { username => 'joequuux', fullname => 'Joe Foo Quuux', password => 'joefoobarp' });

ok( getpwnam('joefoobar') && getpwnam('joequux') && getpwnam('joequuux') , "Verifying new users");

## domain should be server default
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoobar' );
is( $co->domain, $domain, "new user domain" );
getpwnam('joefoobar') && system q(vrmuser -y joefoobar 2>/dev/null);

## create quuux node
##
## the side effects of this test (creating a <user> element for
## joequuux) will be used later to test whether the domain_admin node
## was automatically added for him
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'joequuux' );
is( $co->domain, $domain, "new user domain" );
ok( ! $co->domain_admin, "joequuux is NOT a domain admin" );

##
## some variables for later
##
my $hostname = `hostname`; chomp $hostname;
my $admin    = `sinfo -a`; chomp $admin;

##
## test whether eu is automatically upgraded to da w/o removing cpx.conf
##

## add domain for joequuux
open CONF, ">httpd.conf.$$"
  or die "Could not write new conf file: $!\n";
print CONF <<_CONF_;
ServerName     $hostname
User           $admin

## vaddhost: (quuux.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joequuux
    Group          joequuux
    ServerName     quuux.com
    ServerAlias    www.quuux.com
    ServerAdmin    webmaster\@quuux.com
    DocumentRoot   /home/$admin/www/quuux.com
    ScriptAlias    /cgi-bin/ "/home/$admin/www/cgi-bin/"
    <Directory /home/$admin/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/$admin/quuux.com-access_log combined
    ErrorLog       /usr/local/apache/logs/$admin/quuux.com-error_log
</VirtualHost>

_CONF_
close CONF;
$VSAP::Server::Modules::vsap::config::HTTPD_CONF = "httpd.conf.$$";

$co = new VSAP::Server::Modules::vsap::config( username => 'joequuux' );
is( $co->domain, $domain, "updated user to DA (use primary domain)");
ok( $co->domain_admin, "joequuux is a domain admin" );


##
## now start fresh with cpx.conf
##

##
## check domains list (different from 'domain')
##
undef $co;
unlink '/usr/local/etc/cpx.conf';

## write Apache conf file
open CONF, ">httpd.conf.$$"
  or die "Could not write new conf file: $!\n";
print CONF <<_CONF_;
ServerName     $hostname
User           $admin

## vaddhost: (baz.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     baz.com
    ServerAlias    www.baz.com
    ServerAdmin    webmaster\@baz.com
    DocumentRoot   /home/joefoo/www/baz.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/baz.com-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/baz.com-error_log
</VirtualHost>

## vaddhost: (foo.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     foo.com
    ServerAlias    www.foo.com
    ServerAdmin    webmaster\@foo.com
    DocumentRoot   /home/joefoo/www/foo.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/foo.com-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/foo.com-error_log
</VirtualHost>

## vaddhost: (bar.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     bar.com
    ServerAlias    www.bar.com
    ServerAdmin    webmaster\@bar.com
    DocumentRoot   /home/joefoo/www/bar.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/bar.com-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/bar.com-error_log
</VirtualHost>

## vaddhost: (blech.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    ServerName     blech.com
    ServerAlias    www.blech.com
    ServerAdmin    webmaster\@blech.com
    DocumentRoot   /home/$admin/www/blech.com
    ScriptAlias    /cgi-bin/ "/home/$admin/www/cgi-bin/"
    <Directory /home/$admin/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/$admin/blech.com-access_log combined
    ErrorLog       /usr/local/apache/logs/$admin/blech.com-error_log
</VirtualHost>

## vaddhost: (quux.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joequux
    Group          joequux
    ServerName     quux.com
    ServerAlias    www.quux.com
    ServerAdmin    webmaster\@quux.com
    DocumentRoot   /home/$admin/www/quux.com
    ScriptAlias    /cgi-bin/ "/home/$admin/www/cgi-bin/"
    <Directory /home/$admin/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/$admin/quux.com-access_log combined
    ErrorLog       /usr/local/apache/logs/$admin/quux.com-error_log
</VirtualHost>

## vaddhost: (quuux.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joequuux
    Group          joequuux
    ServerName     quuux.com
    ServerAlias    www.quuux.com
    ServerAdmin    webmaster\@quuux.com
    DocumentRoot   /home/$admin/www/quuux.com
    ScriptAlias    /cgi-bin/ "/home/$admin/www/cgi-bin/"
    <Directory /home/$admin/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/$admin/quuux.com-access_log combined
    ErrorLog       /usr/local/apache/logs/$admin/quuux.com-error_log
</VirtualHost>

_CONF_
close CONF;
$VSAP::Server::Modules::vsap::config::HTTPD_CONF = "httpd.conf.$$";

$co = new VSAP::Server::Modules::vsap::config( username => 'joequuux' );
is( $co->domain, $domain, "updated user to DA (use primary domain)");
ok( $co->domain_admin, "joequuux is a domain admin" );

$co = new VSAP::Server::Modules::vsap::config(username => 'joequux');
$co->domain('quux.com');

undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->domain, $domain, "domain admin check" );

##
## domains check
##
my $domains = $co->domains;
is( keys %$domains, 7 );
is( $domains->{'foo.com'}, 'joefoo' );
is( $domains->{'bar.com'}, 'joefoo' );
is( $domains->{'baz.com'}, 'joefoo' );
is( $domains->{'blech.com'}, $admin );
is( $domains->{'quux.com'}, 'joequux' );
is( $domains->{$hostname}, $admin );

undef $domains;
$domains = $co->domains('joefoo');
is( keys %$domains, 3 );
is( $domains->{'foo.com'}, 'joefoo' );
is( $domains->{'bar.com'}, 'joefoo' );
is( $domains->{'baz.com'}, 'joefoo' );

undef $domains;
$domains = $co->domains(domain => 'baz.com');
is( keys %$domains, 1 );
is( $domains->{'baz.com'}, 'joefoo' );

undef $domains;
$domains = $co->domains(domain => 'quux.com');
is( keys %$domains, 1 );
is( $domains->{'quux.com'}, 'joequux' );


##
## add a new domain to httpd.conf.$$
##
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->add_domain('glarch.com');

undef $domains;
$domains = $co->domains('joefoo');
is( keys %$domains, 3 );
ok( ! $domains->{'glarch.com'} );

open CONF, ">>httpd.conf.$$"
  or die "Could not write new conf file: $!\n";
print CONF <<_CONF_;

## vaddhost: (quux.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     quux.com
    ServerAlias    www.quux.com
    ServerAdmin    webmaster\@quux.com
    DocumentRoot   /home/joefoo/www/quux.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/quux.com-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/quux.com-error_log
</VirtualHost>

## vaddhost: (glarch.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     glarch.com
    ServerAlias    www.glarch.com
    ServerAdmin    webmaster\@glarch.com
    DocumentRoot   /home/joefoo/www/glarch.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/glarch.com-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/glarch.com-error_log
</VirtualHost>
_CONF_
close CONF;

$co->add_domain('glarch.com');
$domains = $co->domains('joefoo');
is( keys %$domains, 4 );
is( $domains->{'foo.com'}, 'joefoo' );
is( $domains->{'bar.com'}, 'joefoo' );
is( $domains->{'baz.com'}, 'joefoo' );
is( $domains->{'glarch.com'}, 'joefoo' );

## test for no side effects: this will make some tests below fail
## FIXME: should have a test just for duplicates
$co->_parse_apache($co->{dom}->findnodes("/config/domains"));

## count glarch.com
my @nodes = $co->{dom}->findnodes('/config/domains/domain[name="glarch.com"]');
is( scalar @nodes, 1 );

## remove domain
$co->remove_domain('glarch.com');
@nodes = $co->{dom}->findnodes('/config/domains/domain[name="glarch.com"]');
is( scalar @nodes, 0 );

## add again
$co->add_domain('glarch.com');
@nodes = $co->{dom}->findnodes('/config/domains/domain[name="glarch.com"]');
is( scalar @nodes, 1 );

## duplicate check
$co->add_domain('glarch.com');
@nodes = $co->{dom}->findnodes('/config/domains/domain[name="glarch.com"]');
is( scalar @nodes, 1, 'duplicate add_domain check' );


##
## disable/enable
##
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');

ok( ! $co->disabled, "not disabled" );
$co->disabled(1);
ok(   $co->disabled, "disabled" );
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
ok(   $co->disabled, "disabled" );
{
    local $> = 0;
	if (! $is_linux)
	{
    	ok( (getpwnam('joefoo'))[1] =~ /^\*LOCKED/, "platform disabled" );
	} else {
    	ok( (getpwnam('joefoo'))[1] =~ /^\!/, "platform disabled" );
	}
}
undef $co;


##
## (disk|user|alias)_limit methods
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->disk_limit('foo.com'), 0 );
is( $co->alias_limit('foo.com'), 0 );
is( $co->user_limit('foo.com'), 0 );
is( $co->disk_limit('foo.com', 600), 600 );
is( $co->alias_limit('foo.com', 'unlimited'), 'unlimited' );
is( $co->user_limit('foo.com', 10), 10 );
undef $co;

$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->alias_limit('foo.com', 'wakawakawaka'), 'unlimited' );
is( $co->disk_limit('foo.com'), 600 );
is( $co->alias_limit('foo.com'), 'unlimited' );
is( $co->alias_limit('foo.com', 54), 54 );
is( $co->alias_limit('foo.com'), 54 );
is( $co->user_limit('foo.com'), 10 );
#undef $co;

$co->user_limit('foo.com', 0);
is( $co->user_limit('foo.com'), 0, "set zero in autoloader" );
undef $co;

##
## user lists
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
my $users = $co->users(domain => 'baz.com');
is( $users->{joefoo} => undef, "DA check" );
undef $co;

## add new users
my $acctjoefoobar1 = VSAP::Server::Test::Account->create( { username => 'joefoobar', fullname => 'Joe Foo Bar', password => 'joefoobarb' });
my $acctjoefoobaz = VSAP::Server::Test::Account->create( { username => 'joefoobaz', fullname => 'Joe Foo Baz', password => 'joefoobaz' });
use utf8;
my $acctjoefooblech = VSAP::Server::Test::Account->create( { username => 'joefooblech', fullname => 'Joe Foo Blech 日本語', password => 'joefooblech' });
no utf8;
ok( getpwnam('joefoobar') );
ok( getpwnam('joefoobaz') );
ok( getpwnam('joefooblech') );

## domain should be server default
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoobar' );
$co->domain('bar.com');    ## set domain name for joefoobar
$co->init( username => 'joefoobaz' );
$co->domain('baz.com');  ## set domain name for joefoobaz
$co->init( username => 'joefooblech' );
$co->domain('blech.com');  ## set domain name for joefooblech
is ($co->fullname, 'Joe Foo Blech 日本語'); ## test reading of fullname

$co->init( username => 'joefoo' );  ## init as admin for this domain

## tests a bug where I was using the wrong
## attribute in the init() method to find a user node
my @users = $co->{dom}->findnodes('/config/users/user[@name="joefoo"]');
is( scalar @users, 1 );

$users = $co->users(domain => 'baz.com');
is( $users->{joefoobaz} => "baz.com", "user check" );
ok( ! $users->{joefoobar}, "no user check" );
ok( ! $users->{joefooblech}, "no user check" );

## make sure we re not too closely tied to the object
delete $$users{joefoobaz};
$co->{is_dirty} = 1;
$co->commit;

# hostname change check (BUG05074)
my $old_hostname = $hostname;
my $new_hostname = "biff.foo.quux.com";
system("hostname", $new_hostname);
$co->init( username => 'joefoo' );
is( $co->domain, $new_hostname, "new hostname check" );
system("hostname", $old_hostname);

$co->init( username => 'joefoo' );
$users = $co->users(domain => 'baz.com');
is( $users->{joefoobaz} => 'baz.com' );

## check all users for domain admin
#print STDERR $co->{dom}->toString(1);
$users = $co->users(admin => 'joefoo');
ok( ! $users->{joefoo}, "DA is not in his own list" );
is( $users->{joefoobar} => 'bar.com' );
is( $users->{joefoobaz} => 'baz.com' );
ok( ! $users->{joefooblech} );


## check all users via admin
$co->init( username => $admin );  ## init as server admin
$users = $co->users;  ## all users on system
is( $users->{joefoo},     => $domain, "DA in primary domain" );
is( $users->{joefoobar}   => "bar.com" );
is( $users->{joefoobaz}   => "baz.com" );
is( $users->{joefooblech} => "blech.com" );
ok( ! exists $users->{nobody}, "no nobody" );

##
## domain admin checks
##
ok( $co->domain_admin, "server admin domain admin check" );

ok(   $co->domain_admin(admin => 'joefoo'), "DA check on joefoo by admin" );
ok( ! $co->domain_admin(admin => 'joefooblech'), "DA check on joefooblech by admin" );

## set and unset
$co->domain_admin( admin => 'joefooblech', set => 1 );
ok(   $co->domain_admin(admin => 'joefooblech'), "DA check on joefooblech by admin" );
$co->domain_admin( admin => 'joefooblech', set => 0 );
ok( ! $co->domain_admin(admin => 'joefooblech'), "DA check on joefooblech by admin" );

$co->init( username => 'joefoo' );  ## init as server admin
ok(   $co->domain_admin, "domain admin check" );

## scottw- I just broke the admin semantics for domain_admin. The old
## test was:
##
##     ok( ! $co->domain_admin(admin => 'joefoo'), "DA check on joefoo by joefoo" );
##
## The new semantics allow a config object initialized by anyone to
## check domain_admin-ness on anyone.
##
ok( $co->domain_admin(admin => 'joefoo'), "DA check on joefoo by joefoo" );

## remove
$co->domain_admin( set => 0 );
ok( ! $co->domain_admin, "domain admin check (no)" );

$co->domain_admin( set => 1 );
ok(   $co->domain_admin, "domain admin check (yes)" );

ok(   $co->domain_admin(domain => 'bar.com') );
ok(   $co->domain_admin(domain => 'foo.com') );
ok(   $co->domain_admin(domain => 'baz.com') );
ok( ! $co->domain_admin(domain => 'blech.com') );
ok(   $co->domain_admin('joefoo'), "joefoo is joefoo's da" );
ok(   $co->domain_admin('joefoobar'), "joefoo is joefoobar's da" );
ok(   $co->domain_admin('joefoobaz'), "joefoo is joefoobaz's da" );
ok( ! $co->domain_admin('joefooblech'), "joefoo is NOT joefooblech's da" );

$co->init( username => 'joefoobar' );  ## init as server admin
ok( ! $co->domain_admin, "not domain admin check" );
ok( ! $co->domain_admin('joefoo') );
ok( ! $co->domain_admin('joefoobar') );

$co->init( username => 'joefoobaz' );  ## init as server admin
ok( ! $co->domain_admin, "not domain admin check" );

$co->init( username => $admin );
ok(   $co->domain_admin('joefoo'), "SA is always DA for DAs" );
ok(   $co->domain_admin('joefooblech'), "server admin is joefooblech's da" );
ok(   $co->domain_admin($admin), "sa is own da" );

##
## list domain admins
##
$co->init( username => $admin );
my %das = map { $_ => 1 } @{$co->domain_admins};
ok( $das{$admin} );
ok( $das{joefoo} );

getpwnam('joefoobar')   && system q(vrmuser -y joefoobar 2>/dev/null);
getpwnam('joefoobaz')   && system q(vrmuser -y joefoobaz 2>/dev/null);
getpwnam('joefooblech') && system q(vrmuser -y joefooblech 2>/dev/null);
getpwnam('joequux')     && system q(vrmuser -y joequux 2>/dev/null);

## transfer ownership of the domain
ok( ! $co->domain_admin(domain => 'quux.com') );
system('perl', '-pi', '-e', "s{User           joequux}{User           $admin}", "httpd.conf.$$");
system('perl', '-pi', '-e', "s{Group          joequux}{Group          $admin}", "httpd.conf.$$");


## make sure these users are removed from the config file
$users = $co->users;
ok( ! exists $users->{joefoobar} );
ok( ! exists $users->{joefoobaz} );
ok( ! exists $users->{joefooblech} );
ok( ! exists $users->{joequux} );

## make sure domain was transferred correctly
ok( $co->domain_admin(domain => 'quux.com') );

END {
    unlink "httpd.conf.$$";

    ## move old file back
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
