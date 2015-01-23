# t/VSAP-Server-Modules-vsap-files-mkdir.t

use Test::More tests => 31;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::mkdir');
  use_ok('VSAP::Server::Modules::vsap::config');
  use_ok('VSAP::Server::Test::Account');
};

#-----------------------------------------------------------------------------
#
# set up a dummy server admin 'quuxroot'
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
# create a new vsap test object
#
my $vsap = $acctquuxroot->create_vsap( ["vsap::auth", "vsap::user",
                                        "vsap::files::mkdir"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $query = qq!
<vsap type="files:mkdir">
  <path></path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: path must be defined");

#-----------------------------------------------------------------------------
#
# check mkdir capability (and restrictions) of non-privileged user
#
my $newdir = (getpwnam('quuxroot'))[7] . "/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>/newdirectory</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:mkdir']/path");
is($value, "/newdirectory", "mkdir in user home directory heirarchy: VSAP returned ok");
ok((-e $newdir), "verify mkdir was successful; directory exists");
my ($tuid, $tgid) = (lstat("$newdir"))[4,5];
is($tuid, (getpwnam('quuxroot'))[2], "verify correct ownership of new directory");
rmdir($newdir);

$newdir = "/biff/../../tmp/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>$newdir</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "VSAP does not authorize non-privileged user to mkdir in non-homed file space");
ok(!(-e "$newdir"), "non-privileged user cannot mkdir outside of homedir");

#-----------------------------------------------------------------------------
#
# check move capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");
$newdir = "/tmp/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>$newdir</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:mkdir']/path");
is($value, $newdir, "mkdir by server admin in root-owned file heirarchy: VSAP returned ok");
ok((-e $newdir), "verify mkdir was successful; directory exists");
($tuid, $tgid) = (lstat("$newdir"))[4,5];
is($tuid, (getpwnam('root'))[2], "verify correct ownership of new directory");
rmdir($newdir);

$newdir = "/tmp/new/directory";
$query = qq!
<vsap type="files:mkdir">
  <path>$newdir</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:mkdir']/path");
is($value, $newdir, "mkdir by server admin in root-owned file heirarchy: VSAP returned ok");
ok((-e $newdir), "verify mkdir was successful; directory exists");
($tuid, $tgid) = (lstat("$newdir"))[4,5];
is($tuid, (getpwnam('root'))[2], "verify correct ownership of new directory");
rmdir($newdir);
rmdir("/tmp/new");

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
# check mkdir capability of server admin in user-owned directory space
#
$newdir = (getpwnam('quuxfoo'))[7] . "/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>$newdir</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:mkdir']/path");
is($value, $newdir, "mkdir by server admin in user home directory heirarchy: VSAP returned ok");
ok((-e $newdir), "verify mkdir was successful; directory exists");
($tuid, $tgid) = (lstat("$newdir"))[4,5];
is($tuid, (getpwnam('quuxfoo'))[2], "verify correct ownership of new directory");
rmdir($newdir);

#-----------------------------------------------------------------------------
#
# add an end user to domain admin
#
undef $t;
$t = $vsap->client( { password => 'quuxf00bar', username => 'quuxfoo'});
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

$query = qq!
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
is($value, "ok", 'vsap user:add returned ok status for enduser1');

#-----------------------------------------------------------------------------
#
# check lack of mkdir capability of domain admin in non-enduser-owned space
#
$newdir = (getpwnam('quuxroot'))[7] . "/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>/newdirectory</path>
  <user>quuxroot</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "VSAP does not authorize domain admin to mkdir in non-enduser-homed file space");
ok(!(-e "$newdir"), "domain admin cannot mkdir outside of in non-enduser-homed file space");

#-----------------------------------------------------------------------------
#
# check mkdir capability of domain admin in enduser-owned files file space
#
$newdir = (getpwnam('quuxfoochild1'))[7] . "/newdirectory";
$query = qq!
<vsap type="files:mkdir">
  <path>/newdirectory</path>
  <user>quuxfoochild1</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:mkdir']/path");
is($value, "/newdirectory", 
   "mkdir by domain admin in end user home directory heirarchy: VSAP returned ok");
ok((-e $newdir), "verify mkdir was successful; directory exists");
($tuid, $tgid) = (lstat("$newdir"))[4,5];
is($tuid, (getpwnam('quuxfoochild1'))[2], "verify correct ownership of new directory");
rmdir($newdir);

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

