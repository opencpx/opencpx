# t/VSAP-Server-Modules-vsap-files-properties.t

use Test::More tests => 49;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::properties');
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
                                        "vsap::files::properties"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $query = qq!
<vsap type="files:properties">
  <path></path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: path must be defined");

my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: -e path");

#-----------------------------------------------------------------------------
#
# check get file properties capability (and restrictions) of non-privileged user
#
open(TEMP, ">$filename");   
print TEMP "hello world!\n";
close(TEMP);
my ($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
ok((-e "$filename"), "created temp file in userdir to be stat()'d");
$query = qq!
<vsap type="files:properties">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
my ($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), "/hello_world.txt", "path ok");
is($nodes->findvalue("./parent_dir"), "/", "file:properties returned correct 'parent_dir' value");
is($nodes->findvalue("./type"), "text", "file:properties returned correct 'type' value");
is($nodes->findvalue("./name"), "hello_world.txt", "file:properties returned correct 'name' value");
is($nodes->findvalue("./extension"), "txt", "file:properties returned correct 'extension' value");
is($nodes->findvalue("./mime_type"), "text/plain", "file:properties returned correct 'mime_type' value");
is($nodes->findvalue("./size"), "13", "file:properties returned correct 'size' value");
is($nodes->findvalue("./is_writable"), "yes", "file:properties returned correct 'is_writable' value");
is($nodes->findvalue("./owner"), "quuxroot", "file:properties returned correct 'owner' value");
is($nodes->findvalue("./group"), "quuxroot", "file:properties returned correct 'group' value");
is($nodes->findvalue("./contents"), "hello world!\n", "file:properties returned correct 'contents' value");
ok($nodes->findvalue("./mtime"), "file:properties returned a defined 'mtime' value");
ok($nodes->findvalue("./mode"), "file:properties returned a defined 'mode' value");

# check properties:type for valid 'file' retval
$query = qq!
<vsap type="files:properties:type">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties:type']");
is($nodes->findvalue("./type"), "file", "file:properties:type returned correct 'type' value for file");

# check different invalid access path
$filename = "biff/../../../tmp/hello_world.txt";
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "verifying user not authorized to stat non-homed files");

# try and read non-homed file
$filename = "/tmp/hello_world.txt";
open(TEMP, ">$filename");
print TEMP "hello world!\n";
close(TEMP);
ok((-e "$filename"), "created temp file in tmp to be stat()'d");
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "verifying user cannot open non-homed files");

#-----------------------------------------------------------------------------
#
# check set contents capability on self-owned file
#
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
my $contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:properties">
  <path>/hello_world.txt</path>
  <set_contents>$contents</set_contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), "/hello_world.txt", "set_contents query returned correct path");
$contents =~ s/\&\#010;/\n/g;
is($nodes->findvalue("./contents"), $contents, "modified 'contents' value is correct");

#-----------------------------------------------------------------------------
#
# check get file properties capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
  <set_contents>$contents</set_contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), $filename, "server admin authorized to view root-owned files");

# get properties for certain troublesome files in /dev directory (BUG05838)
my $path = ($ENV{VST_PLATFORM} eq "LVPS2") ? "/dev/ptyp0" : "/dev/ptyP0";
$query = qq!
<vsap type="files:properties">
  <path>$path</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), $path, "viewing certain files in /dev doesn't hang server");

# check properties:type for valid 'dir' retval
$query = qq!
<vsap type="files:properties:type">
  <path>/tmp</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties:type']");
is($nodes->findvalue("./type"), "dir", "file:properties:type returned correct 'type' value for dir");

#-----------------------------------------------------------------------------
#
# check set contents capability of server_admin on root-owned file
#
$filename = "/tmp/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
  <set_contents>$contents</set_contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), $filename, "server admin authorized to edit root-owned files");
$contents =~ s/\&\#010;/\n/g;
is($nodes->findvalue("./contents"), $contents, "modified 'contents' value is correct");
unlink($filename);

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
$co->user_limit('quuxfoo.com', 2);
$co->commit;
undef($co);

#-----------------------------------------------------------------------------
# 
# check get file properties capability of server admin on user-owned files
#
$filename = (getpwnam('quuxfoo'))[7] . "/hello_world.txt";
open(TEMP, ">$filename");
print TEMP "hello world!\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxfoo'))[2,3];
chown($uid, $gid, $filename);
ok((-e "$filename"), "created temp file in quuxfoo userdir");
$query = qq!
<vsap type="files:properties">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), $filename, "server admin authorized to view user-owned files");
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

undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'vsap user:add returned ok status for enduser1');

#-----------------------------------------------------------------------------
#
# check lack of capability of domain admin for non-enduser-owned files
#
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
open(TEMP, ">$filename");
print TEMP "hello world!\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
ok((-e "$filename"), "created temp file in non-enduser homedir");
$query = qq!
<vsap type="files:properties">
  <path>/hello_world.txt</path>
  <user>quuxroot</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "domain admin unable to get file properties of non-enduser files");
unlink($filename);

#-----------------------------------------------------------------------------
#
# check get file properties capability of domain admin on enduser-owned files
#
$filename = (getpwnam('quuxfoochild1'))[7] . "/hello_world.txt";
open(TEMP, ">$filename");
print TEMP "hello world!\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxfoochild1'))[2,3];
chown($uid, $gid, $filename);
ok((-e "$filename"), "created temp file in enduser homedir");
$query = qq!
<vsap type="files:properties">
  <path>/hello_world.txt</path>
  <user>quuxfoochild1</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), "/hello_world.txt", 
   "domain admin authorized to get file properties of enduser-owned files");

#-----------------------------------------------------------------------------
#
# check set contents capability of domain admin on enduser-owned file
#
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:properties">
  <path>/hello_world.txt</path>
  <user>quuxfoochild1</user>
  <set_contents>$contents</set_contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:properties']");
is($nodes->findvalue("./path"), "/hello_world.txt", 
   "set_contents query returned correct path");
$contents =~ s/\&\#010;/\n/g;
is($nodes->findvalue("./contents"), $contents, "modified 'contents' value is correct");

#
# test non-UTF-8 file content conversion
#
use encoding 'utf8';
my $foohome = (getpwnam('quuxfoo'))[7];
system('cp', '-p', "t/sample-euc.txt", $foohome);
system('cp', '-p', "t/sample-jis.txt", $foohome);
system('cp', '-p', "t/sample-sjis.txt", $foohome);
($uid, $gid) = (getpwnam('quuxfoo'))[2,3];
my $efile = $foohome . "/sample-euc.txt";
chown($uid, $gid, $efile);
my $jfile = $foohome . "/sample-jis.txt";
chown($uid, $gid, $jfile);
my $sfile = $foohome . "/sample-sjis.txt";
chown($uid, $gid, $sfile);

undef $t;
$t = $vsap->client( { password => 'quuxf00bar', username => 'quuxfoo'});

$query = qq!
<vsap type="files:properties">
  <path>/sample-euc.txt</path>
</vsap>
!;   
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue('/vsap/vsap[@type="files:properties"]/contents');
$contents = "これはEUC-JPでコーディングされた日本語のファイルです。\n";
is($value, $contents, "file:properties returned contents of euc-jp file converted to utf-8");

$query = qq!
<vsap type="files:properties">
  <path>/sample-jis.txt</path>
</vsap>
!;   
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue('/vsap/vsap[@type="files:properties"]/contents');
$contents = "これはISO-2022-JPでコーディングされた日本語のファイルです。\n";
is($value, $contents, "file:properties returned contents of 7bit-jis file converted to utf-8");

$query = qq!
<vsap type="files:properties">
  <path>/sample-sjis.txt</path>
</vsap>
!;   
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue('/vsap/vsap[@type="files:properties"]/contents');
$contents = "これはShift-JISでコーディングされた日本語のファイルです。\n";
is($contents, $value, "file:properties returned contents of shift-jis file converted to utf-8");

unlink($efile);
unlink($jfile);
unlink($sfile);
no encoding;

#
# the guess encoding routine is getting better
#
# test non-UTF-8 file contents when conversion fails
# (e.g. when the file is short enough that a guess at the encoding cannot be made)
#
#system('cp', '-p', "t/small.txt", $foohome);
#($uid, $gid) = (getpwnam('quuxfoo'))[2,3];
#$efile = $foohome . "/small.txt";
#chown($uid, $gid, $efile);
#$query = qq!
#<vsap type="files:properties">
#  <path>/small.txt</path>
#</vsap>
#!;
#undef($de);
#$de = $t->xml_response($query);
#$value = $de->findvalue('/vsap/vsap[@type="files:properties"]/contents');
#chomp($value);
##diag($de->toString);
#is($value, "???", "file:properties returned contents with high-bits removed");
#unlink($efile);

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

