# t/VSAP-Server-Modules-vsap-files-uncompress.t

use Test::More tests => 29;

use strict;
use Cwd;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::uncompress');
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
                                        "vsap::files::uncompress"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.zip";
my $target = (getpwnam('quuxroot'))[7] . "/uncompress";
my $query = qq!
<vsap type="files:uncompress">
  <source>/hello_world.zip</source>
  <target></target>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 106, "error check: target undefined");

$query = qq!
<vsap type="files:uncompress">
  <source></source>
  <target>/uncompress</target>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: path undefined");

$query = qq!
<vsap type="files:uncompress">
  <source>/hello_world.zip</source>
  <target>/uncompress</target>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: -e path");

#-----------------------------------------------------------------------------
#
# check basic uncompress capability
#
my $file = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
open(TEMP, ">$file");
print TEMP "hello world!\n";
close(TEMP);
my ($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $file);
ok((-e "$file"), "created temp file 1 in userdir to be archived");
$file = (getpwnam('quuxroot'))[7] . "/hi_world.txt";
open(TEMP, ">$file");
print TEMP "hi world!\n";
close(TEMP);
chown($uid, $gid, $file);
ok((-e "$file"), "created temp file 2 in userdir to be archived");
my $oldpath = cwd();
chdir((getpwnam('quuxroot'))[7]);
system('zip', '-q', 'hello_world.zip', 'hello_world.txt', 'hi_world.txt');
chdir($oldpath);
ok((-e "$filename"), "created temp archive file to be uncompressed");

undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='files:uncompress']/target");
is($value, "/uncompress", "uncompress file: VSAP returned ok");
$file = (getpwnam('quuxroot'))[7] . "/uncompress/hello_world.txt";
ok((-e "$file"), "verify uncompress: temp file 1 unpacked");
my ($tuid, $tgid, $size) = (stat($file))[4,5,7];
is($size, 13, "verify uncompress: temp file 1 size matches original");
is($tuid, $uid, "verify uncompress: temp file 1 user ownership matches original");
is($tgid, $gid, "verify uncompress: temp file 1 group ownership matches original");
unlink($file);
$file = (getpwnam('quuxroot'))[7] . "/uncompress/hi_world.txt";
ok((-e "$file"), "verify uncompress: temp file 2 unpacked");
($tuid, $tgid, $size) = (stat($file))[4,5,7];
is($size, 10, "verify uncompress: temp file 2 size matches original");
is($tuid, $uid, "verify uncompress: temp file 2 user ownership matches original");
is($tgid, $gid, "verify uncompress: temp file 2 group ownership matches original");
unlink($file);
unlink( (getpwnam('quuxroot'))[7] . '/hello_world.txt' );
unlink( (getpwnam('quuxroot'))[7] . '/hi_world.txt' );
unlink( (getpwnam('quuxroot'))[7] . '/hello_world.zip' );

#-----------------------------------------------------------------------------
#
# check overwrite/skip options
#

## clean up this directory
my $hrewt = (getpwnam('quuxroot'))[7];

$file = (getpwnam('quuxroot'))[7] . "/uncompress/hello_world.txt";
open(TEMP, ">$file");
print TEMP "hello world!\n";
close(TEMP);
($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $file);

my $file2 = (getpwnam('quuxroot'))[7] . '/hello_world.txt.tgz';
my $wd = `pwd`; chomp $wd;
system("tar -zcf $file2 -C /home/quuxroot/uncompress hello_world.txt");
chown($uid, $gid, $file2);
ok( -f $file, "created temp file 1 in userdir to be archived");
ok( -f $file2, "created tgz archive" );

## zero out the original file
open TEMP, ">$file";
close TEMP;
is( -s $file, 0, "zero file size" );

#system("find $hrewt -print | xargs ls -lTd");
#system('logger', '-p', 'daemon.notice', '*' x 40);  ###############

## try to extract, but don't clobber
undef $de;
$de = $t->xml_response(<<_VSAP_);
<vsap type="files:uncompress">
  <source>/hello_world.txt.tgz</source>
  <target>/uncompress</target>
  <uncompress_option>skip</uncompress_option>
</vsap>
_VSAP_

is( -s $file, 0, "zero file size ($file)" );
ok( -f $file2, "tgz archive intact ($file2)" );

#system("find $hrewt -type f -print | xargs ls -lT");
#print STDERR `zcat $file2`;
#print STDERR "\n\n";
#sleep 2;

## try again, but clobber it
undef $de;
$de = $t->xml_response(<<_VSAP_);
<vsap type="files:uncompress">
  <source>/hello_world.txt.tgz</source>
  <target>/uncompress</target>
</vsap>
_VSAP_

#system("find $hrewt -type f -print | xargs ls -lT");
#print STDERR "\n\n";

isnt( -s $file, 0, "not zero file size" );
ok( -f $file2, "tgz archive not gone" );


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

