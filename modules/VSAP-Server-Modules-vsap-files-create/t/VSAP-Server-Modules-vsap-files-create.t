# t/VSAP-Server-Modules-vsap-files-create.t

use Test::More tests => 41;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::create');
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
open(SOURCE, "/www/conf/httpd.conf") ||
    die "Could not open httpd.conf";
open(BACKUP, ">/www/conf/httpd.conf.$$") ||
    die "Could not create backup of httpd.conf";
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
                                        "vsap::files::create"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $query = qq!
<vsap type="files:create">
  <path></path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: path must be defined");

#-----------------------------------------------------------------------------
#
# check create file capability (and restrictions) of non-privileged user
#
my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
my $contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>/hello_world.txt</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, "/hello_world.txt", "create file in directory owned by self: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
my ($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('quuxroot'))[2], "verify correct ownership of new file");
my $tcontents;
open(FP, "$filename");
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
is($tcontents, $contents, "verify correct contents of new file");
unlink($filename);

# don't add trailing '\n' to contents; see if it gets added
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}";
$query = qq!
<vsap type="files:create">
  <path>/hello_world.txt</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, "/hello_world.txt", "create file in directory owned by self: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('quuxroot'))[2], "verify correct ownership of new file");
open(FP, "$filename");
$tcontents = "";
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
$contents .= "\n";
is($tcontents, $contents, "verify correct contents of new file");
unlink($filename);

# create a file that also requires a new subdirectory
$filename = (getpwnam('quuxroot'))[7] . "/tmp/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>/tmp/hello_world.txt</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, "/tmp/hello_world.txt", 
   "create file in new subdirectory owned by self: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('quuxroot'))[2], "verify correct ownership of new file");
my $subdirectory = (getpwnam('quuxroot'))[7] . "/tmp";
($tuid) = (lstat("$subdirectory"))[4];
is($tuid, (getpwnam('quuxroot'))[2], "verify correct ownership of new subdirectory");
$tcontents = "";
open(FP, "$filename");
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
is($tcontents, $contents, "verify correct contents of new file");
unlink($filename);
rmdir($subdirectory);

# try and create a file outside of the authorized path
$filename = "/biff/../../tmp/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>$filename</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "VSAP does not authorize non-privileged user to create non-homed files");
ok(!(-e "/tmp/hello_world.txt"), "non-privileged user cannot create files outside of homedir");

#-----------------------------------------------------------------------------
#
# check create file capability of server admin on root-owned files
#
$acctquuxroot->make_sa();
undef($t);  
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");
$filename = "/tmp/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>$filename</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, $filename, "create file in root-owned directory by server admin: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('root'))[2], "verify correct ownership of new file");
$tcontents = "";
open(FP, "$filename");
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
is($tcontents, $contents, "verify correct contents of new file");
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
$co->user_limit('quuxfoo.com', 3);
$co->commit;
undef($co);

#-----------------------------------------------------------------------------
#
# check create file capability of server admin in user-owned directories
#
$filename = (getpwnam('quuxfoo'))[7] . "/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>$filename</path>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, $filename, "create file in user-owned directory by server admin: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('quuxfoo'))[2], "verify correct ownership of new file");
$tcontents = "";
open(FP, "$filename");
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
is($tcontents, $contents, "verify correct contents of new file");
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
# check lack of create file capability of domain admin on non-enduser-owned files
#
$filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>/hello_world.txt</path>
  <user>quuxroot</user>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "VSAP does not authorize domain admin to create non-enduser-homed files");
ok(!(-e "/tmp/hello_world.txt"), "domain admin cannot create files in non-enduser directories");

#-----------------------------------------------------------------------------
#
# check create file capability of domain admin in enduser-owned directories
#
$filename = (getpwnam('quuxfoochild1'))[7] . "/hello_world.txt";
$contents = "main( ) {&#010;    printf(\"hello, world\");&#010;}&#010;";
$query = qq!
<vsap type="files:create">
  <path>/hello_world.txt</path>
  <user>quuxfoochild1</user>
  <contents>$contents</contents>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:create']/path");
is($value, "/hello_world.txt", 
   "create file in enduser-owned directory by domain admin: VSAP returned ok");
ok((-e "$filename"), "verify create file was successful; new file exists");
($tuid) = (lstat("$filename"))[4];
is($tuid, (getpwnam('quuxfoochild1'))[2], "verify correct ownership of new file");
$tcontents = "";
open(FP, "$filename");
$tcontents .= $_ while (<FP>);
close(FP);
$contents =~ s/\&\#010;/\n/g;
is($tcontents, $contents, "verify correct contents of new file");
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

