# t/VSAP-Server-Modules-vsap-files-list.t

use Test::More tests => 33;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN { 
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::list');
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
my $vsap = $acctquuxroot->create_vsap( ["vsap::auth", "vsap::user", "vsap::user::prefs", 
                                        "vsap::files::list"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
# 
# some simple error checks
#
my $dirpath = (getpwnam('quuxroot'))[7] . "/biff";
my $query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: -e path");

$query = qq!
<vsap type="files:list">
  <path></path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:list']/path");
is($value, "/", "empty path returns home directory listing");

#-----------------------------------------------------------------------------
#
# check list capability (and restrictions) of non-privileged user
#
$dirpath = "/";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
my ($nodes) = $de->findnodes("/vsap/vsap[\@type='files:list']");
$value = $nodes->findvalue("./path");
is($value, $dirpath, "path ok");
$value = $nodes->findvalue("./parent_dir");
my $parent_dir = $dirpath;
$parent_dir =~ s/[^\/]+$//g;
$parent_dir =~ s/\/+$//g;
is($value, $parent_dir, "parent_dir ok");
ok($nodes->findvalue("./owner"), "owner defined for self-named node ('.') in $dirpath");
ok($nodes->findvalue("./group"), "group defined for self-named node ('.') in $dirpath");
ok($nodes->findvalue("./size"), "size defined for self-named node ('.') in $dirpath");
ok($nodes->findvalue("./mtime"), "mtime defined for self-named node ('.') in $dirpath");
ok($nodes->findvalue("./mode"), "mode defined for self-named node ('.') in $dirpath");

$dirpath = "/home/quuxroot/../../..";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "verifying user not authorized to access non-homed directories");

$dirpath = "/root";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "verifying user cannot open non-homed directories");

my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
open(TEMP, ">$filename");   
print TEMP "hello world!\n";
close(TEMP);
$query = qq!
<vsap type="files:list">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 302, "verifying error code when attempting to list non-directories");
unlink($filename);

#-----------------------------------------------------------------------------
#
# check list capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");   
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:list']");
$value = $nodes->findvalue("./path");
is($value, "/root", "server admin authorized to view root-owned files (/root)");
$value = $nodes->findvalue("./system_folder");
is($value, "yes", "root-owned file (/root) is designated as a system file");

# Create a temp directory in the user space.
my $tempdir = (getpwnam('quuxroot'))[7] . "/tmpdir";
mkdir($tempdir,"0755");
chown( (getpwnam('quuxroot'))[2,3], $tempdir);
ok(-d "${tempdir}", "Created temp directory.");

# Create a symlink in the user space.
ok(symlink($tempdir,(getpwnam('quuxroot'))[7]."/tmplink"), "Created symlink to tmpdir.") ;

# Set startpath to a symbolic link.
$query = qq!
<vsap type="user:prefs:save">
  <user_preferences>
    <fm_startpath>/www/htdocs</fm_startpath>
  </user_preferences>
</vsap>
!;
$de = $t->xml_response($query);
my $status = $de->findvalue("/vsap/vsap[\@type='user:prefs:save']/status");
is($status , "ok", "Set startpath to symlink.");

# Verify that the list display for the abs_path of the symlink in start path.
$query = qq!
<vsap type="files:list">
  <path></path>
</vsap>
!;

$de = $t->xml_response($query);
ok($de->findnodes("/vsap/vsap[\@type='files:list']"), "List startpath that is a symlink");

# check /dev directory (per BUG05838)
$dirpath = "/dev";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:list']");
$value = $nodes->findvalue("./path");
is($value, "/dev", "server admin authorized to view root-owned files (/dev)");

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
# check list capability of server admin on user-owned files
#
$dirpath = (getpwnam('quuxfoo'))[7];
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:list']");
$value = $nodes->findvalue("./path");
is($value, $dirpath, "server admin authorized to view user-owned files");

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
# check lack of list capability of domain admin for non-enduser-owned files
#
$dirpath = "/";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
  <user>quuxroot</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "domain admin unable to list non-enduser files");

#-----------------------------------------------------------------------------
#
# check list capability of domain admin on enduser-owned files
#
$dirpath = "/";
$query = qq!
<vsap type="files:list">
  <path>$dirpath</path>
  <user>quuxfoochild1</user>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
($nodes) = $de->findnodes("/vsap/vsap[\@type='files:list']");
$value = $nodes->findvalue("./path");
is($value, $dirpath, "domain admin able to list enduser files");

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
      if (-e "/usr/local/apache/conf/httpd.conf.$$");
    if (-e "/etc/mail/virtusertable.$$") {
      rename("/etc/mail/virtusertable.$$", "/etc/mail/virtusertable");
      chdir("/etc/mail");
      my $out = `make`;
    }
}

# eof

