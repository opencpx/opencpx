use Test::More;
BEGIN { plan tests => 52 };
use VSAP::Server::Test::Account 0.02; #0.02 includes the password method required.
use VSAP::Server::Modules::vsap::auth;
use VSAP::Server::Modules::vsap::user::prefs;
use VSAP::Server::Modules::vsap::config;
use POSIX;
ok(1, "finished loading modules"); # If we made it this far, we're ok.

#########################

my $cpx_config   = "_cpx.$$.conf";

$is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefooson = VSAP::Server::Test::Account->create( { username => 'joefooson', fullname => 'Joe Foo Son', password => 'joefoosonbar' });
my $acctbartbar = VSAP::Server::Test::Account->create( { username => 'bartbar', fullname => 'Bart Bar', password => 'bartbarfoo' });

ok( $acctjoefoo->exists(), "joefoo exists");
ok( $acctjoefooson->exists(), "joefooson exists");
ok( $acctbartbar->exists(), "bartbar exists");

## make joefoo the DA for joefooson
my $ip = `sinfo`; $ip =~ s{\A.*^address:\s*([\d\.]+).*}{$1}smi;

open HC, ">httpd.conf.$$"
  or die "Could not write to file: $!\n";
print HC <<_CONF_;

## vaddhost: (joefoo.tld) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     joefoo.tld
    ServerAlias    www.joefoo.tld
    ServerAdmin    webmaster\@joefoo.tld
    DocumentRoot   /home/joefoo/www/joefoo.tld
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    <Directory /home/joefoo/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/joefoo/joefoo.tld-access_log combined
    ErrorLog       /usr/local/apache/logs/joefoo/joefoo.tld-error_log
</VirtualHost>

_CONF_
close HC;
$VSAP::Server::Modules::vsap::config::HTTPD_CONF = "httpd.conf.$$";

## move old config file
rename "/usr/local/etc/cpx.conf", "/usr/local/etc/$cpx_config" if -e "/usr/local/etc/cpx.conf";
my $co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );
my $hostname = `hostname`; chomp $hostname;
$co->domain( $hostname );
$co->domain_admin( set => 1 );
$co->init( username => 'joefooson' );
$co->domain( 'joefoo.tld' );
undef $co;

## Start up a standalone vsapd server. 
my $vsap = $acctjoefoo->create_vsap(['vsap::user::prefs']);



# Obtain a connection to the vsap server we started. 
my $t = $vsap->client();

# Login and save the session key. 
ok(ref($t),"obtained a vsap client");
my $de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>joefoobar</password></vsap>!);
my $session;
ok( $session = $de->find('/vsap/vsap[@type="auth"]/sessionkey'),"obtained a session key");

$t->quit; 
undef $t;
undef $de;

## Obtain a new client, try a bogus password. There should be a no auth node. 
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><username>foojoe</username><password>knuckle</password></vsap>!);
ok( ! $de->find("/vsap/vsap[\@type='auth']/sessionkey"), "Bad password, no session key" );

## try a bogus user
ok( ! getpwnam('foojoecujo'), "No such user" );
$de = $t->xml_response(qq!<vsap type="auth"><username>foojoecujo</username><password>joefoobar</password></vsap>!);
ok( ! $de->find("/vsap/vsap[\@type='auth']/sessionkey"), "Invalid user, no session key available" );
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Login invalid), "got invalid user message.");

$t->quit; 
undef $t; 
undef $de;

## move the home directory out of the way
rename('/home/joefoo', "/home/joefoo.$$");
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>joefoobar</password></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error" and code="104"]/code'), 104, "home directory gone" );
rename("/home/joefoo.$$", '/home/joefoo');

## mess up the home directory permissions
chmod(0055, '/home/joefoo');
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>joefoobar</password></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error" and code="105"]/code'), 105, "home directory inaccessible" );
chmod(0755, '/home/joefoo');

$t->quit;
undef $t;
undef $de;

## move the keyfile out of the way
rename("/home/joefoo/.cpx_key", "/home/joefoo/.cpx_key.$$");
system('mkdir', "/home/joefoo/.cpx_key");
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>joefoobar</password></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error" and code="103"]/code'), 103, "key file is bad" );
system('rm', '-rf', "/home/joefoo/.cpx_key");
rename("/home/joefoo/.cpx_key.$$", "/home/joefoo/.cpx_key");

$t->quit;
undef $t;
undef $de;

$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
ok( $de->find("/vsap/vsap[\@type='auth']/sessionkey"), "Login ok with previous session key");

## test for creation of home directories
ok( -d "/home/joefoo/.cpx","cpx directory exists");
my $mode = (stat(_))[2] & 07777;
is( sprintf("%04o", $mode), "0700","cpx directory has correct mode." );
is( (stat(_))[4] => (getpwnam('joefoo'))[2], "cpx directory owner is correct");
is( (stat(_))[5] => (getpwnam('joefoo'))[3], "cpx directory group is correct" );

ok( -d "/home/joefoo/.cpx_tmp", ".cpx_tmp directory exists." );
$mode = (stat(_))[2] & 07777;
is( sprintf("%04o", $mode), "0770", ".cpx_tmp directory has correct mode");
is( (stat(_))[4] => (getpwnam('joefoo'))[2], ".cpx_tmp directory has correct owner");
if ($is_linux)
{
	is( (stat(_))[5] => (getpwnam('apache'))[3], ".cpx_tmp directory has correct group");
} else {
	is( (stat(_))[5] => (getpwnam('www'))[3], ".cpx_tmp directory has correct group");
}
## test for server admin w/o resetting the password
ok( ! $de->find('/vsap/vsap[@type="auth"]/server_admin'), "is not a server admin" );
## make us a server admin for a sec
$acctjoefoo->make_sa();

## test again
undef $de;
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
ok( $de->find('/vsap/vsap[@type="auth"]/sessionkey'),"logged back in with sessionkey");
ok( $de->find('/vsap/vsap[@type="auth"]/server_admin'), "is a server admin" );

## test services
ok( $de->find('/vsap/vsap[@type="auth"]/services/ftp'), "ftp user service" );
ok( $de->find('/vsap/vsap[@type="auth"]/services/mail'), "mail user service" );
ok( $de->find('/vsap/vsap[@type="auth"]/capabilities/ftp'), "ftp user capa" );
ok( $de->find('/vsap/vsap[@type="auth"]/capabilities/mail'), "mail user capa" );
ok( $de->find('/vsap/vsap[@type="auth"]/packages'), "packages node" );

## remove priv
if ($is_linux)
{
	$acctjoefoo->set_groups(['mailgrp','joefoo']);
} else {
	$acctjoefoo->set_groups(['imap','pop','joefoo']);
}

undef $de;
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
ok( ! $de->find('/vsap/vsap[@type="auth"]/services/ftp'), "no ftp user" );
ok( $de->find('/vsap/vsap[@type="auth"]/services/mail'), "mail user" );

$t->quit;
undef $t; 

## reset password to start with '::' BUG12610
undef $t;
undef $de;
$t = $vsap->client();
$acctjoefoo->password('::hello');
$de = $t->xml_response(qq!<vsap type="auth"><username>joefoo</username><password>::hello</password></vsap>!);
ok( $session = $de->find('/vsap/vsap[@type="auth"]/sessionkey'),"obtained a session key for :: password");

undef $t;
undef $de;
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
ok( !$de->find('/vsap/vsap[@type="error"]'), 'able to use session key with :: in password' ) || diag $de->toString(1);
# back to normal password.
$acctjoefoo->password('joefoobar');

##
## some auth:authz login tests
##
undef $t;
undef $de;
$t = $vsap->client();

# Login as joefooson with joefoo's password. 
$de = $t->xml_response(qq!<vsap type="auth">
  <username>joefoo:joefooson</username>
  <password>joefoobar</password>
</vsap>!);
ok( $de->find("/vsap/vsap[\@type='auth']/sessionkey"), "got sessionkey via auth:authz login" ) || diag $de->toString(1);

## Load prefs and confirm default timezone.
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'GMT', "got timezone");

## Adjust time_zone of joefooson, while still logged in as joefoo. 
$de = $t->xml_response(qq!<vsap type="user:prefs:save">
  <user_preferences>
    <time_zone>CDT6CST</time_zone>
  </user_preferences>
</vsap>!);
is($de->findvalue('/vsap/vsap[@type="user:prefs:save"]/status'), 'ok', "saved new timezone.");

# Load the prefs, confirm that the change has infact been completed. 
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'CDT6CST', "timezone is correct");

$t->quit;
undef $t;
undef $de; 
# Connect as joefooson and confirm the changed timezone. 
$t = $vsap->client( { username => 'joefooson', password => 'joefoosonbar' });
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'CDT6CST', "timezone is still correct logging in as real user");
#print STDERR $de->toString(1);

$t->quit;
undef $t;
undef $de;
$t = $vsap->client();

# Login as joefoo using and save session key. 
$de = $t->xml_response(qq!<vsap type="auth">
  <username>joefoo</username>
  <password>joefoobar</password>
</vsap>!);
my $dsession = $de->findvalue('/vsap/vsap[@type="auth"]/sessionkey');

# Confirm that the time_zone is GMT which is the default and was not changed when logging in above as joefooson.
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'GMT', "timezone for user is still GMT");

$t->quit;
undef $de;
undef $t;

# now log back in as joefoo using the session key saved above. 
$t = $vsap->client({ sessionkey => $dsession });
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$dsession</sessionkey></vsap>!);
ok( $de->find("/vsap/vsap[\@type='auth']/sessionkey"), "login auth:authz with session key" );

# Adjust the timezone for joefoo. 
$de = $t->xml_response(qq!<vsap type="user:prefs:save">
  <user_preferences>
    <time_zone>EDT5EST</time_zone>
  </user_preferences>
</vsap>!);
is($de->findvalue('/vsap/vsap[@type="user:prefs:save"]/status'), 'ok', "saved new timezone.");

## check again as joefooson
$t->quit; 
undef $t;
undef $de; 

# No login as joefooson and and confirm the timezone changes done above. 
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'EDT5EST', "confirm timezone is still correct timezone via sessionkey auth" );

## try to become bartbar (should fail)
$t->quit;
undef $de;
undef $t;
$t = $vsap->client();
$de = $t->xml_response(qq!<vsap type="auth">
  <username>joefoo:bartbar</username>
  <password>joefoobar</password>
</vsap>!);
ok( ! $de->find("/vsap/vsap[\@type='auth']/sessionkey"),"confirm no session key");
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(authorized to become bartbar),"authorized");

##
## test for expired session (set session timeout low, wait
## for expiration, try auth)

## try to authenticate now
# set timeout to 3.6 seconds and force expiration
my $user_prefs_file = '/home/joefoo/.cpx/user_preferences.xml';
my $user_prefs = qq!
<user_preferences>
  <date_format>%d-%m-%Y</date_format>
  <dt_order>time</dt_order>
  <logout>.001</logout>
  <time_format>%H:%M</time_format>
  <time_zone>GMT</time_zone>
</user_preferences>
!;
if( open PREFS, ">$user_prefs_file" ) {
    print PREFS $user_prefs;
    close PREFS;
}
else {
    warn "Could not write prefs: $!\n";
}

$t->quit;
undef $de;
undef $t; 
$t = $vsap->client();
ok(1,"Sleeping for 4 seconds..");
sleep 4;
$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="auth"]/code'), 101, 'auth should fail from timing out');
#print STDERR $de->toString(1);

# set timeout to 1 hour and don't force expiration
$user_prefs =~ s/<logout>.001<\/logout>/<logout>1<\/logout>/mg;
open(PREFS,">$user_prefs_file");
print PREFS $user_prefs;
close PREFS;

ok(1,"Sleeping for 1 second");
sleep 1;

$de = $t->xml_response(qq!<vsap type="auth"><sessionkey>$session</sessionkey></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="auth"]/code'), '', 'auth should succeed (timeout not occurring)');

END {
	$acctjoefoo->delete();
	ok( ! $acctjoefoo->exists(), 'User joefoo removed');
	$acctjoefooson->delete();
	ok( ! $acctjoefooson->exists(), 'User joefooson removed');
	$acctbartbar->delete();
	ok( ! $acctbartbar->exists(), 'User bartbar removed');

    unlink '/usr/local/etc/cpx.conf';
    rename "/usr/local/etc/$cpx_config", "/usr/local/etc/cpx.conf" if -e "/usr/local/etc/$cpx_config";
    unlink "httpd.conf.$$";
}
