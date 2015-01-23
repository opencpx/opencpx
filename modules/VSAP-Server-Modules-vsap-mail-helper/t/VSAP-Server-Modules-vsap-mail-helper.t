# t/VSAP-Server-Modules-vsap-mail-helper.t'

use Test::More tests => 14;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::mail::helper');
  use_ok('VSAP::Server::Modules::vsap::config');
  use_ok('VSAP::Server::Test::Account');
};

# make sure our users don't exist
if (getpwnam('quuxroot')) {
    die "User 'quuxroot' already exists. Remove the user (rmuser -y quuxroot) and try again.\n";
}
if (getpwnam('quuxfoo')) {
    die "User 'quuxfoo' already exists. Remove the user (rmuser -y quuxfoo) and try again.\n";
}
if (getpwnam('quuxfoochild1')) {
    die "User 'quuxfoochild1' already exists. Remove the user (rmuser -y quuxfoo) and try again.\n";
}

#-----------------------------------------------------------------------------
#
# set up a dummy user 'quuxroot'
#
my $acctquuxroot = VSAP::Server::Test::Account->create( { username => 'quuxroot',
                                                          password => 'quuxrootbar',
                                                          fullname => 'Quux Root',
                                                          shell => '/sbin/noshell' } );
ok(getpwnam('quuxroot'), 'successfully created new user');

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
    if (-e "/usr/local/etc/cpx.conf");
open(SOURCE, "/www/conf/httpd.conf") || die "Could not open httpd.conf";
open(BACKUP, ">/www/conf/httpd.conf.$$") || die "Could not create backup of httpd.conf";
print BACKUP $_ while (<SOURCE>);
close(BACKUP);
close(SOURCE);
rename("/etc/mail/virtusertable", "/etc/mail/virtusertable.$$")
    if (-e "/etc/mail/virtusertable");

#-----------------------------------------------------------------------------
#
# create a vsap test object
#
my $vsap = $acctquuxroot->create_vsap( ["vsap::auth", "vsap::user",
                                        "vsap::mail::helper"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# call the audit package to create default .procmailrc or .dovecot.sieve
#
my $de = $t->xml_response(qq!<vsap type="mail:helper:init"/>!);
my $found = 0;
if (open(HELPERRC, "/home/quuxroot/.procmailrc")) {
  while (<HELPERRC>) {
    if (/^\#\# NOTICE: Begin Control Panel Section/) {
      $found = 1;
      last;
    }
  }
  close(HELPERRC);
}
if (open(HELPERRC, "/home/quuxroot/.dovecot.sieve")) {
  while (<HELPERRC>) {
    if (/^\#\# NOTICE: Begin Control Panel Section/) {
      $found = 1;
      last;
    }
  }
  close(HELPERRC);
}
ok($found, 'Control Panel block found in helper file');

#-----------------------------------------------------------------------------
#
# test that unprivileged user has limited access
#
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:helper:init"><user>root</user></vsap>!);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "error check: unprivileged user correctly restricted");

# make quuxroot a server admin
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");

#-----------------------------------------------------------------------------
# 
# add a new domain admin user
#
my $addquery = qq!
<vsap type="user:add">
  <login_id>quuxfoo</login_id>
  <fullname>Quux Foo</fullname>
  <password>quuxf00bar</password>
  <confirm_password>quuxf00bar</confirm_password>
  <quota>19</quota>
  <da>
    <domain>quuxfoo.com</domain>
    <ftp_privs/>
    <mail_privs/>
    <shell_privs/>
    <shell>/bin/tcsh</shell>
    <eu_capa_ftp/>
    <eu_capa_mail/>
    <eu_capa_shell/>
  </da>
</vsap>
!;

undef($de);
$de = $t->xml_response($addquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'user:add returned success for domain admin (quuxfoo)');
    
# add a vhost to the httpd.conf file and monkey with the cpx config
open(CONF, ">>/www/conf/httpd.conf");
print CONF <<'ENDVHOST';
<VirtualHost quuxfoo.com>
  User quuxfoo
  ServerName quuxfoo.com
  ServerAlias www.quuxfoo.com
  ServerAdmin quuxfoo@quuxfoo.com
  DocumentRoot /home/quuxfoo
</virtualHost>
ENDVHOST
close(CONF);
 
# assign domain to domain admin
my $co = new VSAP::Server::Modules::vsap::config( username => 'quuxfoo');
$co->add_domain('quuxfoo.com');
$co->domain('quuxfoo.com');
$co->user_limit('quuxfoo.com', 3);
$co->commit;
undef($co);

#-----------------------------------------------------------------------------
#
# check capability of server admin on other users
#
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:helper:init"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:helper:init']/status");
is($value, "ok", 'server admin given plenty of rope');

#-----------------------------------------------------------------------------
#
# add an end user to domain admin
#
undef $t;
$t = $vsap->client( { password => 'quuxf00bar', username => 'quuxfoo'});
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");
    
my $query = qq!
<vsap type="user:add">
  <login_id>quuxfoochild1</login_id>
  <fullname>Quux Foo Child 1</fullname>
  <password>quuxf00childbar1</password>
  <confirm_password>quuxf00childbar1</confirm_password>
  <quota>10</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <mail_privs/>
    <shell_privs/>
    <shell>/bin/tcsh</shell>
  </eu>
</vsap>
!;
  
undef $de;
$de = $t->xml_response($query);  
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'vsap user:add returned ok status for enduser');

#-----------------------------------------------------------------------------
#
# check capability of domain admin to act in behalf of enduser
#
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:helper:init"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:helper:init']/status");
is($value, "ok", 'domain admin has privileges to act in behalf of enduser');

#-----------------------------------------------------------------------------
#
# cleanup   
#

END {
    $acctquuxroot->delete();
    ok( ! $acctquuxroot->exists, 'Quux Root was removed.');
    getpwnam('quuxfoo') && system q(vrmuser -y quuxfoo 2>/dev/null);
    getpwnam('quuxfoochild1') && system q(vrmuser -y quuxfoochild1 2>/dev/null);
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if (-e "/usr/local/etc/cpx.conf.$$");
    rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf")
      if (-e "/www/conf/httpd.conf.$$");
    if (-e "/etc/mail/virtusertable.$$") {
      rename("/etc/mail/virtusertable.$$", "/etc/mail/virtusertable");
      chdir("/etc/mail");
      my $out = `make`;
    }
}

# eof
