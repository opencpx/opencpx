# t/VSAP-Server-Modules-vsap-files-download.t

use Test::More tests => 19;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::files');
  use_ok('VSAP::Server::Modules::vsap::files::download');
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
                                        "vsap::files::download"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# some simple error checks
#
my $query = qq!
<vsap type="files:download">
  <path></path>
</vsap>
!;
my $de = $t->xml_response($query);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 102, "error check: path must be defined");

my $filename = (getpwnam('quuxroot'))[7] . "/hello_world.txt";
$query = qq!
<vsap type="files:download">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 101, "error check: -e path");

#-----------------------------------------------------------------------------
#
# check download capability (and restrictions) of non-privileged user
#
open(TEMP, ">$filename");
print TEMP "hello world!\n";
close(TEMP);
my ($uid, $gid) = (getpwnam('quuxroot'))[2,3];
chown($uid, $gid, $filename);
ok((-e "$filename"), "created temp file in userdir to be 'downloaded'");
$query = qq!
<vsap type="files:download">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
my $path = $de->findvalue("/vsap/vsap[\@type='files:download']/source");
is($path, $filename, "source path returned is valid (1)");
$path = $de->findvalue("/vsap/vsap[\@type='files:download']/path");
my ($nlinks) = (stat($path))[3];
is ($nlinks, 2, "download path is a link to source path");
unlink($path);

# make file not readable by world and see if copy (not link) was made
system('chmod', '600', $filename);
$query = qq!
<vsap type="files:download">
  <path>/hello_world.txt</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$path = $de->findvalue("/vsap/vsap[\@type='files:download']/source");
is($path, $filename, "source path returned is valid (2)");
$path = $de->findvalue("/vsap/vsap[\@type='files:download']/path");
($nlinks) = (stat($path))[3];
is ($nlinks, 1, "download path is a copy from source path");
unlink($path);

# try and accedd a non-home file path
$filename = "/biff/../../../etc/passwd";
$query = qq!
<vsap type="files:download">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "verifying user not authorized to stat non-homed files");

#-----------------------------------------------------------------------------
# 
# check download capability of privileged users
#
$acctquuxroot->make_sa();
undef($t);
$t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for server admin");

# it probably isn't a good idea to run the test on the following file
$filename = ($ENV{VST_PLATFORM} eq "LVPS2") ? "/etc/shadow" : 
                                              "/etc/master.passwd";
$query = qq!
<vsap type="files:download">
  <path>$filename</path>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
$path = $de->findvalue("/vsap/vsap[\@type='files:download']/source");
is($path, $filename, "source path returned is valid for file");
($gid) = (stat($path))[5];
is ($gid, 0, "download source group ownership unchanged");
$path = $de->findvalue("/vsap/vsap[\@type='files:download']/path");
($nlinks) = (stat($path))[3];
is ($nlinks, 1, "download path is a copy from source path");
unlink($path);

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

