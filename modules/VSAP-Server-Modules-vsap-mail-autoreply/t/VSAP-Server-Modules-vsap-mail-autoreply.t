# t/VSAP-Server-Modules-vsap-mail-autoreply.t'

use Test::More tests => 39;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::mail::procmail');
  use_ok('VSAP::Server::Modules::vsap::mail::autoreply');
  use_ok('VSAP::Server::Modules::vsap::config');
  use_ok('VSAP::Server::Test::Account');
};

# make sure our users don't exist
if (getpwnam('quuxroot')) {
    die "User 'quuxroot' already exists. Remove the user (rmuser -y quuxroot) and try again.\n
";
}
if (getpwnam('quuxfoo')) {
    die "User 'quuxfoo' already exists. Remove the user (rmuser -y quuxfoo) and try again.\n";
}
if (getpwnam('quuxfoochild1')) {
    die "User 'quuxfoochild1' already exists. Remove the user (rmuser -y quuxfoochild1) and try again.\n";
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
                                        "vsap::mail::procmail",
                                        "vsap::mail::autoreply"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

my $home = $acctquuxroot->homedir();

#-----------------------------------------------------------------------------
# 
# end user tests
#

# get initial status via <vsap type="mail:autoreply:status">; should return off
my $de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
my $value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# attempt to turn 'on' via <vsap type="mail:autoreply:enable">; 
#   but omit autoreply message and check for returned error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:enable"><message></message></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "555", 'enable without autoreply message; check vsap error code');

# get status via <vsap type="mail:autoreply:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", "verifying vsap returned status as off");

# turn 'on' via <vsap type="mail:autoreply:enable">; include autoreply message
undef($de);
my $msg = "Subject: vacation&#010;&#010;I received your message but am away on vacation.&#010;";
$de = $t->xml_response(qq!<vsap type=\"mail:autoreply:enable\"><message>$msg</message></vsap>!);
is(platform_status($home), "on", 'enable autoreply');

# get status via <vsap type="mail:autoreply:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
my $txt = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/message");
my $int = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/interval");
is($value, "on", "verifying vsap returned status as on");
is($int, 7, "verifying vsap returned default interval (7)");
$msg =~ s/\&\#010;/\n/g;
is($txt, $msg, "verifying vsap returned correct autoreply message");

# check the contents of the file for the presence of the X-Loop
$txt = `cat /home/quuxroot/.cpx/autoreply/message.txt`;
$msg = "X-Loop: quuxroot\@vsap.hot.pepper.sauce\n" . $msg;
is($txt, $msg, "verifying on-disk contents autoreply message");

# set something other than the default interval
undef($de);
$msg = "Subject: vacation&#010;&#010;I received your message but am away on vacation.&#010;";
$de = $t->xml_response(qq!<vsap type=\"mail:autoreply:enable\"><message>$msg</message><interval>3</interval></vsap>!);

# get status via <vsap type="mail:autoreply:status">; check new interval
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$int = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/interval");
is($int, 3, "verifying vsap returned specified interval (3)");

# set up autoreply with no interval
undef($de);
$de = $t->xml_response(qq!<vsap type=\"mail:autoreply:enable\"><message>$msg</message><interval>0</interval></vsap>!);

# get status via <vsap type="mail:autoreply:status">; check new interval
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$int = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/interval");
is($int, 0, "verifying vsap returned specified interval (0)");

# turn 'off' via <vsap type="mail:autoreply:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:disable"/>!);
is(platform_status($home), "off", 'disable autoreply');

# get status via <vsap type="mail:autoreply:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", "verifying vsap returned status as off");

#-----------------------------------------------------------------------------
#
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

($home) = (getpwnam("quuxfoo"))[7];

#-----------------------------------------------------------------------------
#
# check capability of server admin to get/set status of domain admin
#


# get status of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# enable mail autoreply for user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:enable"><user>quuxfoo</user><message>$msg</message></vsap>!);
is(platform_status($home), "on", 'enable mail autoreply');

# get status of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "on", 'verifying vsap returned updated status as on');

# disable mail autoreply for user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:disable"><user>quuxfoo</user></vsap>!);
is(platform_status($home), "off", 'disable mail autoreply');

#-----------------------------------------------------------------------------
#
# check lack of capability to get/set status as non-privileged user
#

undef $t;
$t = $vsap->client( { username => 'quuxfoo', password => 'quuxf00bar' } );
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

# get autoreply status of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to check autoreply status of enduser by non-privileged user');

# disable autoreply of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:disable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to disable autoreply of enduser by non-privileged user');

# disable autoreply of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:enable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to enable autoreply of enduser by non-privileged user');

#-----------------------------------------------------------------------------
#
# add an end user to domain admin
#
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
is($value, "ok", 'vsap user:add returned ok status for enduser1');

($home) = (getpwnam("quuxfoochild1"))[7];

# get initial status; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# turn 'on' via <vsap type="mail:autoreply:enable">; include autoreply message
undef($de);
$msg = "Subject: vacation&#010;&#010;I received your message but am away on vacation.&#010;";
$de = $t->xml_response(qq!<vsap type=\"mail:autoreply:enable\"><user>quuxfoochild1</user><message>$msg</message></vsap>!);
is(platform_status($home), "on", 'enable autoreply');

# get status via <vsap type="mail:autoreply:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
$txt = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/message");
is($value, "on", "verifying vsap returned status as on");
$msg =~ s/\&\#010;/\n/g;
is($txt, $msg, "verifying vsap returned correct autoreply message");

# check the contents of the file for the presence of the X-Loop
$txt = `cat /home/quuxfoochild1/.cpx/autoreply/message.txt`;
$msg = "X-Loop: quuxfoochild1\@vsap.hot.pepper.sauce\n" . $msg;
is($txt, $msg, "verifying on-disk contents autoreply message");

# turn 'off' via <vsap type="mail:autoreply:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:disable"><user>quuxfoochild1</user></vsap>!);
is(platform_status($home), "off", 'disable autoreply');

# get status via <vsap type="mail:autoreply:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:autoreply:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:autoreply:status']/status");
is($value, "off", "verifying vsap returned status as off");

#-----------------------------------------------------------------------------
#
# i18n tests
#

use POSIX('uname');
my ($platform, $version) = (POSIX::uname())[0,2];
if (($platform =~ /Linux/i) ||
    (($platform =~ /FreeBSD/i) && ($version =~ /^6/))) {
    # Scott's original tests for BSD4 (these now only work on Linux/BSD6)
    undef $de;
    $msg = "Subject: vacation&#010;&#010;I have utf-8 in my r\x{c3}\x{b8}ply!.&#010;";
    $de = $t->xml_response(qq!<vsap type="mail:autoreply:enable">
      <user>quuxfoo</user>
      <message>$msg</message>
    </vsap>!);

    # get it from status call
    undef $de;
    $de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoo</user></vsap>!);
    $txt = $de->findvalue('/vsap/vsap[@type="mail:autoreply:status"]/message');
    $msg =~ s/\x{c3}\x{b8}/\x{f8}/;  ## now in unicode
    $msg =~ s/\&\#010;/\n/g;
    is($txt, $msg, "verifying vsap returned correct autoreply message");

    $msg =~ s/\x{f8}/\x{c3}\x{b8}/;  ## back in utf8
    $txt = `cat /home/quuxfoo/.cpx/autoreply/message.txt`;
    $msg = "X-Loop: quuxfoo\@vsap.hot.pepper.sauce\n" . $msg;
    is($txt, $msg, "verifying on-disk contents autoreply message");
}
else {
    # my modifications to Scott's original tests (works on BSD4)
    undef $de;
    $msg = "Subject: vacation&#010;&#010;I have utf-8 in my r\x{c3}\x{b8}ply!.&#010;";
    $de = $t->xml_response(qq!<vsap type="mail:autoreply:enable">
      <user>quuxfoo</user>
      <message>$msg</message>
    </vsap>!);

    # get it from status call
    undef $de;
    $de = $t->xml_response(qq!<vsap type="mail:autoreply:status"><user>quuxfoo</user></vsap>!);
    $txt = $de->findvalue('/vsap/vsap[@type="mail:autoreply:status"]/message');
    $msg =~ s/\&\#010;/\n/g;
    is($txt, $msg, "verifying vsap returned correct autoreply message in utf-8");

    $txt = `cat /home/quuxfoo/.cpx/autoreply/message.txt`;
    my $decoded = Encode::decode_utf8($txt) || $txt;
    $msg = "X-Loop: quuxfoo\@vsap.hot.pepper.sauce\n" . $msg;
    is($decoded, $msg, "verifying on-disk contents autoreply message in utf-8");
}

#-----------------------------------------------------------------------------

## platform verification
sub platform_status
{
    my $home = shift;
  
    my $status = "off";
    open(PMRC, "$home/.procmailrc");
    while (<PMRC>) {
        if (m!^#INCLUDERC=\$CPXDIR/autoreply.rc!) {
            $status = "off";
            last;
        } 
        elsif (m!^INCLUDERC=\$CPXDIR/autoreply.rc!) {
            $status = "on";
            last;
        }
    }
    close(PMRC);
    return($status);
}

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
