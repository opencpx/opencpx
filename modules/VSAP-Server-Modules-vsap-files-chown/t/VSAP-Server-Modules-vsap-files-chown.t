# t/VSAP-Server-Modules-vsap-files-chown.t

use Test::More tests => 43;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::chown');
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
                                        "vsap::files::chown"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
my $owner = "quuxroot";
my ($gid) = (getpwnam('quuxroot'))[3];
my $group = getgrgid($gid);
my $query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path>
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: -e path");

$query = qq!
<vsap type="files:chown">
  <path></path>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: path must be defined");

$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path>
  <owner></owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 106, "error check: user must be defined");

$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path>
  <owner>$owner</owner>
  <group></group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 107, "error check: group must be defined");

open(FP, ">$filename");
print FP "hello, world!\n";
close(FP);
ok("-e $filename", "created temp file in userdir");
$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path>
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 103, "error check: user can't chown files not owned by user");

#-----------------------------------------------------------------------------
#
# check chown capability (and restrictions) of non-privileged user
#
my $uid;
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, "/hello_world.txt", 
   "query ownership of file in user directory owned by self: VSAP returned ok");
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/owner");
is($value, $owner, "verify query accuracy: owner matches");
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/group");
is($value, $group, "verify query accuracy: group matches");

$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path> 
  <owner>root</owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 106, "verifying user cannot chown to non-member users");
unlink($filename);

$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path> 
  <owner>$owner</owner>
  <group>wheel</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 107, "verifying user cannot chown to non-member groups");
unlink($filename);

$filename = "/biff/../../tmp/hello_world.txt";
$query = qq!
<vsap type="files:chown">
  <path>$filename</path> 
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "verifying user to authorized to chown non-homed files");

#-----------------------------------------------------------------------------
#
# check chown capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t); 
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");
$filename = "/tmp/hello_world.txt";
open(FP, ">$filename");
print FP "hello, world!\n";
close(FP);
ok("-e $filename", "created temp file in root-owned directory (/tmp)");
$query = qq!
<vsap type="files:chown">
  <path>$filename</path> 
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, $filename, "chown file in root-owned directory by server admin: VSAP returned ok");
($uid, $gid) = (lstat($filename))[4,5];
my $newuser = getpwuid($uid);
my $newgroup = getgrgid($gid);
is($newuser, $owner, "verify chown was successful: user matches");
is($newgroup, $group, "verify chown was successful: group matches");

# change ownership back to root:wheel
$query = qq!
<vsap type="files:chown">
  <path>$filename</path> 
  <owner>root</owner>
  <group>wheel</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, $filename, "chown file to root:wheel by server admin: VSAP returned ok");
($uid, $gid) = (lstat($filename))[4,5];
$newuser = getpwuid($uid);
$newgroup = getgrgid($gid);
is($newuser, "root", "verify chown was successful: user matches");
is($newgroup, "wheel", "verify chown was successful: group matches");
unlink($filename);

#-----------------------------------------------------------------------------
#
# add a new domain admin user
#
$query = qq!
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
$de = $t->xml_response($query);
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
# check chown capability of server admin on user-owned files
#
$filename = (getpwnam('quuxfoo'))[7] . "/hello_world.txt";
open(FP, ">$filename");
print FP "hello, world!\n";
close(FP);
($uid, $gid) = (getpwnam('quuxfoo'))[2,3];
chown($uid, $gid, $filename);
ok("-e $filename", "created temp file in domain admin directory");
$query = qq!
<vsap type="files:chown">
  <path>$filename</path> 
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, $filename, "chown file in root-owned directory by server admin: VSAP returned ok");
($uid, $gid) = (lstat($filename))[4,5];
$newuser = getpwuid($uid);
$newgroup = getgrgid($gid);
is($newuser, $owner, "verify chown was successful: user matches");
is($newgroup, $group, "verify chown was successful: group matches");
unlink($filename);

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
# check lack of chown capability of domain admin on non-enduser-owned files
#
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
open(FP, ">$filename");
print FP "hello, world!\n";
close(FP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
$owner = "quuxfoo";
($gid) = (getpwnam('quuxfoo'))[3];
$group = getgrgid($gid);
ok("-e $filename", "created temp file in non-enduser directory");
$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path> 
  <user>quuxroot</user>
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "verifying domain admin not authorized to chown non-enduser owned files");
unlink($filename);

#-----------------------------------------------------------------------------
#
# check chmod capability of domain admin in enduser-owned directories
#
$filename = (getpwnam('quuxfoochild1'))[7] . "/hello_world.txt";
open(FP, ">$filename");
print FP "hello, world!\n";
close(FP);
($uid, $gid) = (getpwnam('quuxfoochild1'))[2,3];
chown($uid, $gid, $filename);
ok("-e $filename", "created temp file in non-enduser directory");
$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path> 
  <user>quuxfoochild1</user>
  <owner>$owner</owner>
  <group>$group</group>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, "/hello_world.txt", 
   "chown file in enduser-owned directory by domain admin: VSAP returned ok");
($uid, $gid) = (lstat($filename))[4,5];
$newuser = getpwuid($uid);
$newgroup = getgrgid($gid);
is($newuser, $owner, "verify chown was successful: user matches");
is($newgroup, $group, "verify chown was successful: group matches");

# domain admin can chgrp to web group
my $web_group = ($ENV{VST_PLATFORM} eq "LVPS2") ? "apache" : "www";
$query = qq!
<vsap type="files:chown">
  <path>/hello_world.txt</path> 
  <user>quuxfoochild1</user>
  <owner>quuxfoochild1</owner>
  <group>$web_group</group>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chown']/path");
is($value, "/hello_world.txt", 
   "chown file to group 'www' by domain admin: VSAP returned ok");
($uid, $gid) = (lstat($filename))[4,5];
$newuser = getpwuid($uid);
$newgroup = getgrgid($gid);
is($newuser, "quuxfoochild1", "verify chown was successful: user matches");
is($newgroup, $web_group, "verify chown was successful: group matches");
unlink($filename);

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

