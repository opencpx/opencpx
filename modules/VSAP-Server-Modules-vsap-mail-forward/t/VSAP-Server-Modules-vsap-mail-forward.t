# t/VSAP-Server-Modules-vsap-mail-forward.t'

use Test::More tests => 47;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::mail::procmail');
  use_ok('VSAP::Server::Modules::vsap::mail::forward');
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
                                        "vsap::mail::forward"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

my $home = $acctquuxroot->homedir();

#-----------------------------------------------------------------------------
# 
# end user tests
#

# get initial status via <vsap type="mail:forward:status">; should return off
my $de = $t->xml_response(qq!<vsap type="mail:forward:status"/>!);
my $value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# attempt to turn 'on' via <vsap type="mail:forward:enable">; 
#   but omit forwarding email address and check for returned error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><email></email></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "550", 'enable without forwarding address; check vsap error code');

# get status via <vsap type="mail:forward:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "off", "verifying vsap returned status as off");

# turn 'on' via <vsap type="mail:forward:enable">; include forwarding address
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><email>quuxroot\@gmail.com</email></vsap>!);
is(platform_status($home), "on", 'enable forward with single address; savecopy == off');
# check the savecopy status in the recipe file
is(platform_savecopy($home), "off", 'verifying that savecopy == off against recipe file');

# get status via <vsap type="mail:forward:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
my $email = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/email");
my $savecopy = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/savecopy");
is($value, "on", "verifying vsap returned status as on");
is($email, 'quuxroot@gmail.com', "verifying vsap returned proper e-mail address");
is($savecopy, 'off', "verifying vsap returned proper savecopy value");

# turn 'on' via <vsap type="mail:forward:enable">; include forwarding address
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><email>quuxroot\@gmail.com</email><savecopy>on</savecopy></vsap>!);
is(platform_status($home), "on", 'enable forward with single address; savecopy == on');
# check the savecopy status in the recipe file
is(platform_savecopy($home), "on", 'verifying that savecopy == on against recipe file');

# get status via <vsap type="mail:forward:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
$email = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/email");
$savecopy = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/savecopy");
is($value, "on", "verifying vsap returned status as on");
is($email, 'quuxroot@gmail.com', "verifying vsap returned proper e-mail address");
is($savecopy, 'on', "verifying vsap returned proper savecopy value");

# turn 'on' again; check procmail recipe
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><email>quuxroot\@gmail.com</email><savecopy>on</savecopy></vsap>!);
is(platform_savecopy($home), "on", 'verifying that savecopy == on against recipe file (2)');

# turn 'off' via <vsap type="mail:forward:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:disable"/>!);
is(platform_status($home), "off", 'disable forward');

# get status via <vsap type="mail:forward:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
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
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# enable mail forward for user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><user>quuxfoo</user><email>quuxfoo\@gmail.com</email></vsap>!);
is(platform_status($home), "on", 'enable mail forward');

# get status of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "on", 'verifying vsap returned updated status as on');

# disable mail forward for user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:disable"><user>quuxfoo</user></vsap>!)
;
is(platform_status($home), "off", 'disable mail forward');

#-----------------------------------------------------------------------------
#
# check lack of capability to get/set status as non-privileged user
#

undef $t;
$t = $vsap->client( { username => 'quuxfoo', password => 'quuxf00bar' } );
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

# get forward status of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to check forward status of enduser by non-privileged user');

# disable forward of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:disable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to disable forward of enduser by non-privileged user');

# disable forward of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to enable forward of enduser by non-privileged user');

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

# get status via <vsap type="mail:forward:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "off", "verifying vsap returned status as off");

# turn 'on' via <vsap type="mail:forward:enable">; include forwarding address
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><user>quuxfoochild1</user><email>quuxfoochild1\@gmail.com</email></vsap>!);
is(platform_status($home), "on", 'enable forward with single address; savecopy == off');
# check the savecopy status in the recipe file
is(platform_savecopy($home), "off", 'verifying that savecopy == off against recipe file');

# get status via <vsap type="mail:forward:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
$email = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/email");
$savecopy = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/savecopy");
is($value, "on", "verifying vsap returned status as on");
is($email, 'quuxfoochild1@gmail.com', "verifying vsap returned proper e-mail address");
is($savecopy, 'off', "verifying vsap returned proper savecopy value");

# turn 'on' via <vsap type="mail:forward:enable">; include forwarding address
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:enable"><user>quuxfoochild1</user><email>quuxfoochild1\@gmail.com</email><savecopy>on</savecopy></vsap>!);
is(platform_status($home), "on", 'enable forward with single address; savecopy == on');
# check the savecopy status in the recipe file
is(platform_savecopy($home), "on", 'verifying that savecopy == on against recipe file');

# get status via <vsap type="mail:forward:status">; should return on
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
$email = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/email");
$savecopy = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/savecopy");
is($value, "on", "verifying vsap returned status as on");
is($email, 'quuxfoochild1@gmail.com', "verifying vsap returned proper e-mail address");
is(platform_savecopy($home), 'on', "verifying vsap returned proper savecopy value");

# turn 'off' via <vsap type="mail:forward:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:disable"><user>quuxfoochild1</user></vsap>!);
is(platform_status($home), "off", 'disable forward');

# get status via <vsap type="mail:forward:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:forward:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:forward:status']/status");
is($value, "off", "verifying vsap returned status as off");

#-----------------------------------------------------------------------------

## platform verification
sub platform_status
{
    my $home = shift;

    my $status = "off";
    open(PMRC, "$home/.procmailrc");
    while (<PMRC>) {
        if (m!^#INCLUDERC=\$CPXDIR/mailforward.rc!) {
            $status = "off";
            last;
        }
        elsif (m!^INCLUDERC=\$CPXDIR/mailforward.rc!) {
            $status = "on";
            last;
        }
    }
    close(PMRC);
    return($status);
}

sub platform_savecopy
{
    my $home = shift;

    my $savecopy = "off";
    open(MFRC, "$home/.cpx/procmail/mailforward.rc");
    while (<MFRC>) {
        chomp;
        if (/^:0/) {
            $savecopy = (/^:0 c$/) ? "on" : "off";
            last;  # only interested in first recipe
        }
    }
    close(MFRC);
    return($savecopy);
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
