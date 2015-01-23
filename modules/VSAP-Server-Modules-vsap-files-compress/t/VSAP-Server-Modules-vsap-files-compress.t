# t/perl VSAP-Server-Modules-vsap-files-compress.t

use Test::More tests => 25;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::compress');
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
                                        "vsap::files::compress"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $path = (getpwnam('quuxroot'))[7];
my $file1 = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
my $file2 = (getpwnam('quuxroot'))[7] . "/hello_world.c";
my $file3 = (getpwnam('quuxroot'))[7] . "/hello_world.pl";
my $target = (getpwnam('quuxroot'))[7] . "/compress";
my $arcname = "hello_world.zip";
my $arctype = "zip";

my $query = qq!
<vsap type="files:compress">
  <source>/</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type></type>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 109, "error check: archive type undefined");

$query = qq!
<vsap type="files:compress">
  <source>/</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name></target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 108, "error check: archive name undefined");

$query = qq!
<vsap type="files:compress">
  <source>/</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target></target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 107, "error check: target undefined");

$query = qq!
<vsap type="files:compress">
  <source>/</source>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 106, "error check: files undefined");

$query = qq!
<vsap type="files:compress">
  <source></source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: source path undefined");

$query = qq!
<vsap type="files:compress">
  <source>/</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: -e full source path");

$query = qq!
<vsap type="files:compress">
  <source>/biff/../../tmp</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "error check: not authorized to access non-homed directory");

#-----------------------------------------------------------------------------
#
# check basic compress capability
#
open(TEMP, ">$file1");
print TEMP "hello world!\n";
close(TEMP);
my ($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $file1);
ok((-e "$file1"), "created temp file 1 in userdir to be archived");
open(TEMP, ">$file2");
print TEMP "main( ) {\n    printf(\"hello, world\");\n}\n\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $file2);
ok((-e "$file2"), "created temp file 2 in userdir to be archived");
open(TEMP, ">$file3");
print TEMP "#!/usr/bin/perl\n    print \"hello, world\";\n\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $file3);
ok((-e "$file3"), "created temp file 3 in userdir to be archived");

$query = qq!
<vsap type="files:compress">
  <source>/</source>
  <path>/hello_world.txt</path>
  <path>/hello_world.c</path>
  <path>/hello_world.pl</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:compress']/target");
my $archive = (getpwnam('quuxroot'))[7] . "/compress/hello_world.zip";
is($value, "/compress/hello_world.zip", "uncompress file: VSAP returned ok");
ok((-e "$archive"), "verify compress: archive built");

unlink $archive, $file1, $file2, $file3;

#-----------------------------------------------------------------------------
#
# test compress a directory (BUG05867)
#
my $home = (getpwnam('quuxroot'))[7];
chdir $home;
{
    local $> = getpwnam('quuxroot');
    system('mkdir', '-p', 'compressme/barfus');
    open FILE, "> $home/compressme/barfus/somedata.txt";
    print FILE <<_FOO_;
I'm glad the weather's clearing up. I can't take much more sunshine.

Ta.
_FOO_
    close FILE;
}
$query = qq!<vsap type="files:compress">
  <source>/compressme</source>
  <path>/</path>
  <target>/compress</target>
  <target_name>$arcname</target_name>
  <type>$arctype</type>
</vsap>!;
undef $de;
$de = $t->xml_response($query);
is( $de->findvalue('/vsap/vsap[@type="files:compress"]/target') => "/compress/hello_world.zip", "vsap ok" );
is( $de->findvalue('/vsap/vsap[@type="files:compress"]/status') => "ok", "vsap ok");
ok( -f $archive, "archive built" );
unlink $archive;
system('rm', '-r', "$home/compressme");

#-----------------------------------------------------------------------------
#
# test compress with tgz (BUG05720)
#
chdir $home;
{
    local $> = getpwnam('quuxroot');
    system('mkdir', '-p', "$home/compressme/barfus");
    open FILE, "> $home/compressme/barfus/somedata.txt";
    print FILE <<_FOO_;
I'm glad the weather's clearing up. I can't take much more sunshine.

Ta ta.
_FOO_
    close FILE;
}
undef $de;
$de = $t->xml_response(qq!<vsap type="files:compress">
  <source>/compressme</source>
  <path>/compressme/barfus/somedata.txt</path>
  <target>/compress</target>
  <target_name>hello_world.tgz</target_name>
  <type>tgz</type>
</vsap>!);
is( $de->findvalue('/vsap/vsap[@type="files:compress"]/target') => "/compress/hello_world.tgz", "vsap ok" );
is( $de->findvalue('/vsap/vsap[@type="files:compress"]/status') => "ok", "vsap ok");
ok( -f "$home/compress/hello_world.tgz", "tgz archive built" );
unlink "$home/compress/hello_world.tgz";
system('rm', '-r', "$home/compressme");
system('rm', '-r', "$home/compress");


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
