# t/VSAP-Server-Modules-vsap-mail-autoreply.t'

use Test::More tests => 24;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN {
  use_ok('VSAP::Server::Modules::vsap::user::mail');
  use_ok('VSAP::Server::Modules::vsap::config');
};

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
    if -e "/usr/local/etc/cpx.conf";
system('cp', '-p', "/www/conf/httpd.conf", "/www/conf/httpd.conf.$$");
rename("/etc/mail/virtusertable", "/etc/mail/virtusertable.$$")
    if -e "/etc/mail/virtusertable";

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

my $ACCT = VSAP::Server::Test::Account->create();
ok( $ACCT && $ACCT->exists , 'Account was created.');
my $vsap = $ACCT->create_vsap( [qw(vsap::user vsap::user::mail)] );
my $t = $vsap->client({acct => $ACCT});
my $user = $ACCT->username();
my $home = $ACCT->homedir();
my $pass = $ACCT->password();

#-----------------------------------------------------------------------------
#
# non-privileged user should not be able to call mail setup options
#
my $de = $t->xml_response(qq!<vsap type="user:mail:setup"><user>$user</user></vsap>!);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "100", "verify non-privileged user cannot save setup options");

# make quuxroot a server admin
$ACCT->make_sa();

undef($t);
$t = $vsap->client({ acct => $ACCT });

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

undef $de;
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
my $co = new VSAP::Server::Modules::vsap::config( username => "quuxfoo");
$co->add_domain("quuxfoo.com");
$co->domain("quuxfoo.com");
$co->user_limit("quuxfoo.com", 2);
$co->commit;
undef $co;

#-----------------------------------------------------------------------------
#
# test mail setup options with various bad queries
#
my $validquery = qq!
<vsap type="user:mail:setup">
  <user>quuxfoo</user>
  <domain>quuxfoo.com</domain>
  <email_prefix>qf</email_prefix>
  <capa_webmail/>
  <capa_spamassassin/>
  <capa_clamav/>
</vsap>
!;

# test: user must not be empty
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo//;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 200, "form validation: user cannot be empty");

# test: user must exist on system
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo/fooquux/;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 201, "form validation: user must exist on system");

# test: domain must not be empty
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo.com//;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 202, "form validation: domain cannot be empty");

# test: domain must exist on system
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo.com/fooquux.com/;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 203, "form validation: domain must exist on system");

# test: if defined, email prefix must be valid
undef $de;
$badquery = $validquery;
$badquery =~ s/qf/qf\@/;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 204, "form validation: email prefix must be valid");

#-----------------------------------------------------------------------------
#
# test adding mail setup options with valid entries
#
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:mail:setup']/status");
is($value, "ok", 'verifying vsap user:mail:setup returned success');

# make sure everything was actually set
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => "quuxfoo");
my %capa = %{ $co->capabilities };
is($capa{'webmail'}, 1, "config confirms capa set (webmail)");
is($capa{'mail-spamassassin'}, 1, "config confirms capa set (spamassassin)");
is($capa{'mail-clamav'}, 1, "config confirms capa set (clamav)");
undef $co;

# check virtusertable
my $found = 0;
open(FP, "/etc/mail/virtusertable");
while (<FP>) {
  chomp;
  next unless (/qf\@quuxfoo.com\s+quuxfoo$/);
  $found = 1;
  last;
}
close(FP);
ok($found, "virtmap configured correctly (qf\@quuxfoo.com -> quuxfoo)");

#-----------------------------------------------------------------------------
#
# add a second domain admin user (needed for authorization check below)
#
$addquery = qq!
<vsap type="user:add">
  <login_id>fooquux</login_id>
  <fullname>Foo Quux</fullname>
  <password>f00quuxbar</password>
  <confirm_password>f00quuxbar</confirm_password>
  <quota>17</quota>
  <da>
    <domain>fooquux.com</domain>
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

undef $de;
$de = $t->xml_response($addquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'user:add returned success for domain admin (fooquux)');

# add a vhost to the httpd.conf file and monkey with the cpx config
open(CONF, ">>/www/conf/httpd.conf");
print CONF <<'ENDVHOST';
<VirtualHost fooquux.com>
  User fooquux
  ServerName fooquux.com
  ServerAlias www.fooquux.com
  ServerAdmin fooquux@fooquux.com
  DocumentRoot /home/fooquux
</virtualHost>
ENDVHOST
close(CONF);
 
# assign domain to domain admin
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'fooquux');
$co->add_domain('fooquux.com');
$co->domain('fooquux.com');
$co->user_limit('fooquux.com', 2);
$co->commit;
undef $co;

#-----------------------------------------------------------------------------
#
# test adding end user mail setup options by domain admin
#
undef $t;
$t = $vsap->client({ username => "quuxfoo", password => 'quuxf00bar'});
ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

$addquery = qq!
<vsap type="user:add">
  <login_id>quuxfoochild</login_id>
  <fullname>Quux Foo Child</fullname>
  <password>quuxf00childbar</password>
  <confirm_password>quuxf00childbar</confirm_password>
  <quota>10</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <mail_privs/>
  </eu>
</vsap>
!;  

# add end user
undef $de;
$de = $t->xml_response($addquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'user:add returned success for end user');

$validquery = qq!
<vsap type="user:mail:setup">
  <user>quuxfoochild</user>
  <domain>quuxfoo.com</domain>
  <email_prefix>qfc</email_prefix>
  <capa_webmail/>
  <capa_spamassassin/>
  <capa_clamav/>
</vsap>
!;

# test: cannot store setup options for end users of a domain for which the
#       user is not domain admin
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo.com/fooquux.com/;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "203", "verify domain admin has restricted privileges");

# test: store mail setup options for end user with valid entries
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:mail:setup']/status");
is($value, "ok", 'verifying vsap user:mail:setup returned success (enduser)');

# make sure everything was actually set
undef $co;
$co = new VSAP::Server::Modules::vsap::config( username => 'quuxfoochild');
%capa = %{ $co->capabilities };
is($capa{'webmail'}, 1, "config confirms capa set (webmail)");
is($capa{'mail-spamassassin'}, 1, "config confirms capa set (spamassassin)");
is($capa{'mail-clamav'}, 1, "config confirms capa set (clamav)");

# check virtusertable
$found = 0;
open(FP, "/etc/mail/virtusertable");
while (<FP>) {
  chomp;
  next unless (/qfc\@quuxfoo.com\s+quuxfoochild$/);
  $found = 1;
  last;
}
close(FP);
ok($found, "virtmap configured correctly (qfc\@quuxfoo.com -> quuxfoochild)");

#-----------------------------------------------------------------------------
#
# cleanup
#
 
END {
    getpwnam('quuxfoo') && system q(vrmuser -y quuxfoo 2>/dev/null);
    getpwnam('quuxfoochild') && system q(vrmuser -y quuxfoochild 2>/dev/null);
    getpwnam('fooquux') && system q(vrmuser -y fooquux 2>/dev/null);
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


