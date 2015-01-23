# t/VSAP-Server-Modules-vsap-mail-spamassassin.t'

use Test::More tests => 62;

use strict;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::mail::procmail');
  use_ok('VSAP::Server::Modules::vsap::mail::spamassassin');
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
                                        "vsap::mail::spamassassin"] );
my $t = $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for non-privileged user");

my $home = $acctquuxroot->homedir();

#-----------------------------------------------------------------------------
#
# end user tests
#

# get initial status via <vsap type="mail:spamassassin:status">; should return off
my $de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
my $value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# turn 'on' via <vsap type="mail:spamassassin:enable">
ok( ! -f "$home/Mail/Junk", "No Junk mailbox" );
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:enable"/>!);
is(platform_status($home), "on", 'enable spamassassin');
ok( -f "$home/Mail/Junk", "Junk mailbox exists" );
# see if the default values for logabstract, logfile, spamfolder
my $logabstract = "";
my $logfile = "";
my $spamfolder = "";
open(SARC, "$home/.cpx/procmail/spamassassin.rc");
while (<SARC>) {
  s/\s+$//;
  if (/^LOGABSTRACT=(.*)/) {
    $logabstract = $1;
  }
  elsif (/^LOGFILE=(.*)/) {
    $logfile = $1;
  }
  elsif (/^\* \^X-Spam-Status: Yes/) {
    $spamfolder = <SARC>;
    $spamfolder =~ s/\s+$//;
    last;
  }
}
close(SARC);
is($logabstract, "yes", "verifying default status of logabstract ('yes')");
is($logfile, '$HOME/log.spam', "verifying default status of logfile ('\$HOME/log.spam')");
is($spamfolder, '$HOME/Mail/Junk', "verifying default status of spamfolder ('\$HOME/Mail/Junk')");

# get status via <vsap type="mail:spamassassin:status">; should return on and
# the correct default values for logabstract, logfile, and spamfolder
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "on", "verifying vsap returned status as on");
$logabstract = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/logabstract");
is($logabstract, "yes", "verifying vsap returned logabstract eq 'yes'");
$logfile = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/logfile");
is($logfile, '$HOME/log.spam', "verifying vsap returned logfile eq '\$HOME/log.spam'");
$spamfolder = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/spamfolder");
is($spamfolder, '$HOME/Mail/Junk', "verifying vsap returned spamfolder eq '\$HOME/Mail/Junk'");
my $score = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/required_score");
is($score, '5', "verifying vsap returned required_score == '5'");

# test setting some prefs
my $query = q!
<vsap type="mail:spamassassin:set_user_prefs">
  <required_score>3.2</required_score>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
$score = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/required_score");
is($score, '3.2', "verifying vsap returned required_score == '3.2'");

$query = q!
<vsap type="mail:spamassassin:set_user_prefs">
  <whitelist_to>foo@foobar.com</whitelist_to>
  <whitelist_from>foobar.com</whitelist_from>
  <whitelist_from>barfoo.com</whitelist_from>
  <whitelist_from>foobarfoo.com</whitelist_from>
  <blacklist_from>quuxfoo.com</blacklist_from>
  <blacklist_from>fooquux.com</blacklist_from>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
$score = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/required_score");
is($score, '3.2', "verifying required_score still == '3.2'");
my @nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_to');
is(scalar(@nodes), 1, "whitelist_to has 1 entry");
ok(grep(/^foo\@foobar.com$/, $nodes[0]->to_literal), "whitelist_to has correct node value");
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_from');
is(scalar(@nodes), 3, "whitelist_from has 3 entries");
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/blacklist_from');
is(scalar(@nodes), 2, "blacklist_from has 2 entries");

$query = q!
<vsap type="mail:spamassassin:remove_patterns">
  <whitelist_from>foobarfoo.com</whitelist_from>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_from');
is(scalar(@nodes), 2, "removed one pattern; whitelist_from now has 2 entries");

$query = q!
<vsap type="mail:spamassassin:remove_patterns">
  <whitelist_from>barfoo.com</whitelist_from>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_from');
is(scalar(@nodes), 1, "removed one pattern; whitelist_from now has 1 entry");
ok(grep(/^foobar.com$/, $nodes[0]->to_literal), "whitelist_from has correct node value");

$query = q!
<vsap type="mail:spamassassin:remove_patterns">
  <whitelist_from>foobar.com</whitelist_from>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_from');
is(scalar(@nodes), 0, "removed one pattern; whitelist_from now has 0 entries");

$query = q!
<vsap type="mail:spamassassin:add_patterns">
  <whitelist_from>foobar.com</whitelist_from>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
@nodes = $de->findnodes('/vsap/vsap[@type="mail:spamassassin:status"]/whitelist_from');
is(scalar(@nodes), 1, "added one pattern; whitelist_from now has 1 entry");
ok(grep(/^foobar.com$/, $nodes[0]->to_literal), "whitelist_from has correct node value");

# turn 'off' via <vsap type="mail:spamassassin:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:disable"/>!);
is(platform_status($home), "off", 'disable spamassassin');

# get status via <vsap type="mail:spamassassin:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"/>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "off", "verifying vsap returned status as off");

#-----------------------------------------------------------------------------
#
# make quuxroot a server admin
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

# get spamassassin status of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# enable spamassassin of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:enable"><user>quuxfoo</user></vsap>!);
is(platform_status($home), "on", 'enable spamassassin');

# get spamassassin status of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoo</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "on", 'verifying vsap returned updated status as on');

# disable spamassassin of user as server admin
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:disable"><user>quuxfoo</user></vsap>!);
is(platform_status($home), "off", 'disable spamassassin');

#-----------------------------------------------------------------------------
#
# check lack of capability to get/set status as non-privileged user
#

undef $t;
$t = $vsap->client( { username => 'quuxfoo', password => 'quuxf00bar' } );
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

# get spamassassin status of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to check spamassassin status of enduser by non-privileged user');

# enable spamassassin of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:enable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to enable spamassassin of enduser by non-privileged user');

# disable spamassassin of user as non-privileged user; should return error
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:disable"><user>quuxroot</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", 'attempt to disable spamassassin of enduser by non-privileged user');

#-----------------------------------------------------------------------------
#
# add an end user to domain admin
#
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

($home) = (getpwnam("quuxfoochild1"))[7];

#-----------------------------------------------------------------------------
#
# check capability of domain admin to get/set status of end user
#

# get initial status via <vsap type="mail:spamassassin:status">; should return off
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "off", 'verifying vsap returned initial status as off');

# turn 'on' via <vsap type="mail:spamassassin:enable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:enable"><user>quuxfoochild1</user></vsap>!);
is(platform_status($home), "on", 'enable spamassassin');
# see if the default values for logabstract, logfile, spamfolder
$logabstract = "";
$logfile = "";
$spamfolder = "";
open(SARC, "$home/.cpx/procmail/spamassassin.rc");
while (<SARC>) {
  s/\s+$//;
  if (/^LOGABSTRACT=(.*)/) {
    $logabstract = $1;
  }
  elsif (/^LOGFILE=(.*)/) {
    $logfile = $1;
  }
  elsif (/^\* \^X-Spam-Status: Yes/) {
    $spamfolder = <SARC>;
    $spamfolder =~ s/\s+$//;
    last;
  }
}
close(SARC);
is($logabstract, "yes", "verifying default status of logabstract ('yes')");
is($logfile, '$HOME/log.spam', "verifying default status of logfile ('\$HOME/log.spam')");
is($spamfolder, '$HOME/Mail/Junk', "verifying default status of spamfolder ('\$HOME/Mail/Junk')");

# get status via <vsap type="mail:spamassassin:status">; should return on and
# the correct default values for logabstract, logfile, and spamfolder
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "on", "verifying vsap returned status as on");
$logabstract = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/logabstract");
is($logabstract, "yes", "verifying vsap returned logabstract eq 'yes'");
$logfile = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/logfile");
is($logfile, '$HOME/log.spam', "verifying vsap returned logfile eq '\$HOME/log.spam'");
$spamfolder = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/spamfolder");
is($spamfolder, '$HOME/Mail/Junk', "verifying vsap returned spamfolder eq '\$HOME/Mail/Junk'");
$score = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/required_score");
is($score, '5', "verifying vsap returned required_score == '5'");

# test setting some prefs
$query = q!
<vsap type="mail:spamassassin:set_user_prefs">
  <user>quuxfoochild1</user>
  <required_score>3.2</required_score>
</vsap>
!;
undef($de);
$de = $t->xml_response($query);
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoochild1</user></vsap>!);
$score = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/required_score");
is($score, '3.2', "verifying vsap returned required_score == '3.2'");

# turn 'off' via <vsap type="mail:spamassassin:disable">
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:disable"><user>quuxfoochild1</user></vsap>!);
is(platform_status($home), "off", 'disable spamassassin');

# get status via <vsap type="mail:spamassassin:status">; should return off
undef($de);
$de = $t->xml_response(qq!<vsap type="mail:spamassassin:status"><user>quuxfoochild1</user></vsap>!);
$value = $de->findvalue("/vsap/vsap[\@type='mail:spamassassin:status']/status");
is($value, "off", "verifying vsap returned status as off");

#-----------------------------------------------------------------------------
#
# nv (non-vsap) tests
#
is( VSAP::Server::Modules::vsap::mail::spamassassin::nv_status('quuxroot'), 'off', 'procedural status' );
ok( VSAP::Server::Modules::vsap::mail::spamassassin::nv_enable('quuxroot'), 'procedural enable' );
is( VSAP::Server::Modules::vsap::mail::spamassassin::nv_status('quuxroot'), 'on', 'procedural status' );
ok( VSAP::Server::Modules::vsap::mail::spamassassin::nv_disable('quuxroot'), 'procedural disable' );
is( VSAP::Server::Modules::vsap::mail::spamassassin::nv_status('quuxroot'), 'off', 'procedural status' );

#-----------------------------------------------------------------------------

## platform verification
sub platform_status
{
    my $home = shift;

    my $status = "off";
    open(PMRC, "$home/.procmailrc");
    while (<PMRC>) {
	if (m!^#INCLUDERC=\$CPXDIR/spamassassin.rc!) {
	    $status = "off";
	    last;
	}
	elsif (m!^INCLUDERC=\$CPXDIR/spamassassin.rc!) {
	    $status = "on";
	    last;
	}
    }
    close(PMRC);
    return $status;
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
