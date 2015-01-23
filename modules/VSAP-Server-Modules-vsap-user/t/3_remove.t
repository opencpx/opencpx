# t/3_remove.t

use Test::More tests => 44;

use VSAP::Server::Test::Account 0.02;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN { 
  use_ok('VSAP::Server::Modules::vsap::user');
  use_ok('VSAP::Server::Modules::vsap::config');
};

#-----------------------------------------------------------------------------

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefoobar = VSAP::Server::Test::Account->create( { username => 'joefoobar', fullname => 'Joe Foo Bar', password => 'joefoobar' });

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
      if -e "/usr/local/etc/cpx.conf";
open(CONF, "/www/conf/httpd.conf") ||
        die "Could not open httpd.conf";
open(BACKUP, ">/www/conf/httpd.conf.$$") ||
        die "Could not create backup of httpd.conf";
print BACKUP $_ while (<CONF>);
close(BACKUP);
close(CONF);

ok( getpwnam('joefoo') );
ok( getpwnam('joefoobar') );

## login as joefoo
my $vsap = $acctjoefoo->create_vsap(["vsap::auth", "vsap::user"]);
my $t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});
ok(ref($t));

## missing username
my $de = $t->xml_response(qq!<vsap type="user:remove">
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Username missing)i, "missing username" );

## bogus user
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>blahblahblah</user>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Nonexistent user)i, "bogus username" );

## delete self
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoo</user>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(cannot delete self)i, "delete self" );
ok( getpwnam('joefoo'), 'self still here' );

## try to delete joefoobar
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoobar</user>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "joefoo unable to delete joefoobar" );

##
## test to delete user for whom we do not have permission
##

# make joefoo a server admin and reauthenticate
$acctjoefoo->make_sa();

undef($t);
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});
ok(ref($t), "create new VSAP test object for system admin (joefoo)");

# create four new users - 2 da's and 2 eu's
#

# add user joeda1
#
undef($de);
$de = $t->xml_response(qq!
<vsap type="user:add">
  <login_id>joeda1</login_id>
  <fullname>Joe Da 1</fullname>
  <password>joetheda1</password>
  <confirm_password>joetheda1</confirm_password>
  <quota>89</quota>
  <da>
    <domain>joeda1.com</domain>
    <ftp_privs/>
    <mail_privs/>
    <eu_capa_ftp/>
    <eu_capa_mail/>
  </da>
</vsap>
!);

my $value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'created joeda1');

# add user joeda2
#
undef($de);
$de = $t->xml_response(qq!
<vsap type="user:add">
  <login_id>joeda2</login_id>
  <fullname>Joe Da 2</fullname>
  <password>joetheda2</password>
  <confirm_password>joetheda2</confirm_password>
  <quota>888</quota>
  <da>
    <domain>joeda2.com</domain>
    <ftp_privs/>
    <mail_privs/>
    <eu_capa_ftp/>
    <eu_capa_mail/>
  </da>
</vsap>
!);

$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'created joeda2');

# add a vhost to the httpd.conf file and monkey with the cpx config
open(CONF, ">>/www/conf/httpd.conf");
print CONF <<'ENDVHOST';
<VirtualHost joefoobar.com>
  User joefoo
  ServerName joefoobar.com
  ServerAlias www.joefoobar.com
  ServerAdmin joefoo@joefoobar.com
  DocumentRoot /home/joefoo
</VirtualHost>
<VirtualHost joeda1.com>
  User joeda1
  ServerName joeda1.com
  ServerAlias www.joeda1.com
  ServerAdmin joeda1@joeda1.com
  DocumentRoot /home/joeda1
</VirtualHost>
<VirtualHost joeda2.com>
  User joeda2
  ServerName joeda2.com
  ServerAlias www.joeda2.com
  ServerAdmin joeda2@joeda2.com
  DocumentRoot /home/joeda2
</VirtualHost>
ENDVHOST
close(CONF);

# assign joefoobar.com to joefoo
my $co = new VSAP::Server::Modules::vsap::config( username => 'joefoo');
$co->add_domain('joefoobar.com');
$co->domain('joefoobar.com');
$co->user_limit('joefoobar.com', 2);
$co->commit;
undef($co);

# assign joeda1.com to joeda1
$co = new VSAP::Server::Modules::vsap::config( username => 'joeda1');
$co->add_domain('joeda1.com');
$co->domain('joeda1.com');
$co->user_limit('joeda1.com', 2);
$co->commit;
undef($co);

# assign joeda2.com to joeda2
$co = new VSAP::Server::Modules::vsap::config( username => 'joeda2');
$co->add_domain('joeda2.com');
$co->domain('joeda2.com');
$co->user_limit('joeda2.com', 2);
$co->commit;
undef($co);

# add user joeeu1
#
undef($de);
$de = $t->xml_response(qq!
<vsap type="user:add">
  <login_id>joeeu1</login_id>
  <fullname>Joe Eu 1</fullname>
  <password>joetheeu1</password>
  <confirm_password>joetheeu1</confirm_password>
  <quota>20</quota>
  <eu>
    <domain>joeda1.com</domain>
    <ftp_privs/>
    <mail_privs/>
  </eu>
</vsap>
!);

$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'created joeeu1');

# add user joeeu2
#
undef($de);
$de = $t->xml_response(qq!
<vsap type="user:add">
  <login_id>joeeu2</login_id>
  <fullname>Joe Eu 2</fullname>
  <password>joetheeu2</password>
  <confirm_password>joetheeu2</confirm_password>
  <quota>18</quota>
  <eu>
    <domain>joeda1.com</domain>
    <ftp_privs/>
    <mail_privs/>
  </eu>
</vsap>
!);

$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'created joeeu2');

# try having the eu remove the various users
#
undef($t);
$t = $vsap->client({ username => 'joeeu1', password => 'joetheeu1'});
ok(ref($t), "create new VSAP test object for end-user");

# eu trying to remove sa
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoo</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "end-user unable to delete server admin" );

# eu trying to remove own admin
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "end-user unable to delete end-user admin" );

# eu trying to remove other admin
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda2</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "end-user unable to delete other domain admin" );

# eu trying to remove other eu
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeeu2</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "end-user unable to delete other end-user" );

# eu trying to remove self
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeeu1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	104, "end-user unable to delete self" );

# try having the eu-ownlerless da2 remove the various users
#
undef($t);
$t = $vsap->client({ username => 'joeda2', password => 'joetheda2'});

ok(ref($t), "create new VSAP test object for domain admin joeda2");

# da2 trying to remove sa
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoo</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "ownerless da unable to delete server admin" );

# da2 trying to remove other domain admin
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "ownerless da unable to delete other domain admin" );

# da2 trying to remove other admin's eu
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeeu1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "ownerless da unable to delete other admin's end-user" );

# da2 trying to remove self
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda2</user>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	104, "ownerless da unable to delete self" );

# try having the da1 remove the various users
#
undef($t);
$t = $vsap->client({ username => 'joeda1', password => 'joetheda1'});

ok(ref($t), "create new VSAP test object for domain admin joeda1");

# da1 trying to remove sa
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoo</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "da unable to delete server admin" );

# da1 trying to remove other domain admin
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda2</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	105, "da unable to delete other domain admin" );

# da1 trying to remove eu
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeeu1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 
 	'ok', "da able to delete end-user" );
ok( ! getpwnam('joeeu1'), 'joeeu1 is really gone' );

# check to see if da1 quota bumped back up by eu1 quota amount
undef($de);
$de = $t->xml_response(q!<vsap type="user:list"><domain>joeda1.com</domain></vsap>!);
my $quota = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="joeda1"]/quota/limit');
is($quota, 71, "checking user:list quota for domain admin after eu1 removal") || diag($de->toString(1));

# da1 trying to remove self
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda1</user>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	104, "da unable to delete self" );

# sa should be able to remove anyone
#
undef($t);
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});
ok(ref($t), "create new VSAP test object for server admin joefoo");

# sa trying to remove joefoobar
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoobar</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 
 	'ok', "sa able to delete joefoobar" );
ok( ! getpwnam('joefoobar'), 'joefoobar is really gone' );

# sa trying to remove joeda2
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda2</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 
 	'ok', "sa able to delete joeda2" );
ok( ! getpwnam('joeda2'), 'joeda2 is really gone' );

# sa trying to remove joeeu2
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeeu2</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 
 	'ok', "sa able to delete joeeu2" );
ok( ! getpwnam('joeeu2'), 'joeeu2 is really gone' );

# check to see if da1 quota bumped back up by eu2 quota amount
undef($de);
$de = $t->xml_response(q!<vsap type="user:list"><domain>joeda1.com</domain></vsap>!);
$quota = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="joeda1"]/quota/limit');
is($quota, 89, "checking user:list quota for domain admin after eu2 removal") || diag($de->toString(1));

# sa trying to remove joeda1
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joeda1</user>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 
 	'ok', "sa able to delete joeda1" );
ok( ! getpwnam('joeda1'), 'joeda1 is really gone' );

# da1 trying to remove self
undef($de);
$de = $t->xml_response(qq!<vsap type="user:remove">
  <user>joefoo</user>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:remove"]/code'), 
	104, "da unable to delete self" );

END {
	$acctjoefoo->delete();
	$acctjoefoobar->delete();
    getpwnam('joeda1') && system q(vrmuser -y joeda1 2>/dev/null);
    getpwnam('joeda2') && system q(vrmuser -y joeda2 2>/dev/null);
    getpwnam('joeeu1') && system q(vrmuser -y joeeu1 2>/dev/null);
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf")
      if (-e "/www/conf/httpd.conf.$$");
}

##############################################################################

sub get_quota
{
    my $username = shift;

    my $quota;
    $quota = (Quota::query(Quota::getqcarg('/home'), (getpwnam($username))[2]))[1];
    $quota /= 1024;
    return($quota);
}
