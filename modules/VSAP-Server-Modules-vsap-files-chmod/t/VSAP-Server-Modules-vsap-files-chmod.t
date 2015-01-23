# t/VSAP-Server-Modules-vsap-files-chmod.t

use Test::More tests => 71;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::chmod');
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
                                        "vsap::files::chmod"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $query = qq!
<vsap type="files:chmod">
  <path></path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: path must be defined");

my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.pl";
$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: -e path");

$filename = (getpwnam('quuxroot'))[7] . "/hello_world.pl";
open(FP, ">$filename");
print FP "#!/usr/bin/perl\n\nprint \"hello, world!\\n\";\n\n";
close(FP);
chmod(0600, $filename);
ok("-e $filename", "created temp file in userdir");
$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 103, "error check: user can't chmod files not owned by user");

#-----------------------------------------------------------------------------
#
# check chmod capability (and restrictions) of non-privileged user
#
my ($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chmod']/path");
is($value, "/hello_world.pl", "query mode of file in user directory by self: VSAP returned ok");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/read"), 1, "u+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/write"), 1, "u+w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/execute"), 0, "u-x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/read"), 0, "g-r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/write"), 0, "g-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/execute"), 0, "g-x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/read"), 0, "o-r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/write"), 0, "o-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/execute"), 0, "o-x");

$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chmod']/path");
is($value, "/hello_world.pl", "chmod file in user directory by self: VSAP returned ok");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/read"), 1, "u+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/write"), 1, "u+w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/execute"), 1, "u+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/read"), 1, "g+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/write"), 0, "g-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/execute"), 1, "g+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/read"), 1, "o+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/write"), 0, "o-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/execute"), 1, "o+x");
unlink($filename);

$filename = "/biff/../../tmp/hello_world.pl";
$query = qq!
<vsap type="files:chmod">
  <path>$filename</path>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "verifying user to authorized to chmod non-homed files");

#-----------------------------------------------------------------------------
#
# check chmod capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");
$filename = "/tmp/hello_world.pl";
open(FP, ">$filename");
print FP "#!/usr/bin/perl\n\nprint \"hello, world!\\n\";\n\n";
close(FP);
chmod(0600, $filename);
ok("-e $filename", "created temp file in root-owned directory (/tmp)");
$query = qq!
<vsap type="files:chmod">
  <path>$filename</path>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chmod']/path");
is($value, $filename, "chmod file in root-owned directory by server admin: VSAP returned ok");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/read"), 1, "u+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/write"), 1, "u+w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/execute"), 1, "u+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/read"), 1, "g+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/write"), 0, "g-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/execute"), 1, "g+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/read"), 1, "o+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/write"), 0, "o-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/execute"), 1, "o+x");
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
# check chmod capability of server admin on user-owned files
#
$filename = (getpwnam('quuxfoo'))[7] . "/hello_world.pl";
open(FP, ">$filename");
print FP "#!/usr/bin/perl\n\nprint \"hello, world!\\n\";\n\n";
close(FP);
($uid, $gid) = (getpwnam('quuxfoo'))[2,3];
chown($uid, $gid, $filename);
chmod(0600, $filename);
ok("-e $filename", "created temp file in domain admin directory");
$query = qq!
<vsap type="files:chmod">
  <path>$filename</path>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chmod']/path");
is($value, $filename, "chmod domain admin file by server admin: VSAP returned ok");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/read"), 1, "u+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/write"), 1, "u+w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/execute"), 1, "u+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/read"), 1, "g+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/write"), 0, "g-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/execute"), 1, "g+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/read"), 1, "o+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/write"), 0, "o-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/execute"), 1, "o+x");
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
# check lack of chmod capability of domain admin on non-enduser-owned files
#
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.pl";
open(FP, ">$filename");
print FP "#!/usr/bin/perl\n\nprint \"hello, world!\\n\";\n\n";
close(FP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
chmod(0600, $filename);
ok("-e $filename", "created temp file in non-enduser directory");
$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
  <user>quuxroot</user>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "verifying domain admin not authorized to chmod non-enduser owned files");
unlink($filename);

#-----------------------------------------------------------------------------
#
# check chmod capability of domain admin in enduser-owned files
#
$filename = (getpwnam('quuxfoochild1'))[7] . "/hello_world.pl";
open(FP, ">$filename");
print FP "#!/usr/bin/perl\n\nprint \"hello, world!\\n\";\n\n";
close(FP);
($uid, $gid) = (getpwnam('quuxfoochild1'))[2,3];
chown($uid, $gid, $filename);
chmod(0600, $filename);
ok("-e $filename", "created temp file in enduser directory");
$query = qq!
<vsap type="files:chmod">
  <path>/hello_world.pl</path>
  <user>quuxfoochild1</user>
  <mode>
    <owner>
      <read>yes</read>
      <write>yes</write>
      <execute>yes</execute>
    </owner>
    <group>
      <read>yes</read>
      <execute>yes</execute>
    </group>
    <world>
      <read>yes</read>
      <execute>yes</execute>
    </world>
  </mode>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:chmod']/path");
is($value, "/hello_world.pl", "chmod enduser file by domain admin: VSAP returned ok");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/read"), 1, "u+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/write"), 1, "u+w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/owner/execute"), 1, "u+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/read"), 1, "g+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/write"), 0, "g-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/group/execute"), 1, "g+x");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/read"), 1, "o+r");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/write"), 0, "o-w");
is($de->findvalue("/vsap/vsap[\@type='files:chmod']/mode/world/execute"), 1, "o+x");
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

