# t/1_add.t

use Test::More tests => 75;

use VSAP::Server::Test::Account 0.02;

use POSIX('uname');

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN { 
  use_ok('VSAP::Server::Modules::vsap::user');
  use_ok('VSAP::Server::Modules::vsap::config');
};


#-----------------------------------------------------------------------------
#
# set up a dummy server admin 'quuxroot'
#

# make sure our user doesn't exist
if (getpwnam('quuxroot')) {
    die "User 'quuxroot' already exists. Remove the user (rmuser -y quuxroot) and try again.\n";
}

## run vadduser (quietly)
my $acctquuxroot = VSAP::Server::Test::Account->create( { username => 'quuxroot', fullname => 'Quux Root', password => 'quuxrootbar' });
ok(getpwnam('quuxroot'), 'successfully created new user');

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
    if (-e "/usr/local/etc/cpx.conf");
open(CONF, "/www/conf/httpd.conf") || 
    die "Could not open httpd.conf";
open(BACKUP, ">/www/conf/httpd.conf.$$") || 
    die "Could not create backup of httpd.conf";
print BACKUP $_ while (<CONF>);
close(BACKUP);
close(CONF);

my $vsap = $acctquuxroot->create_vsap(["vsap::auth", "vsap::user"]);
$t = $vsap->client( { username => 'quuxroot', password => 'quuxrootbar' });

ok(ref($t), "create new VSAP test object for non-privileged user");

#-----------------------------------------------------------------------------
#
# non-privileged user should not be able to add new user
#
my $de = $t->xml_response(qq!<vsap type="user:add"><login_id>quuxfoo</login_id></vsap>!);
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, "105", "verify non-privileged user cannot add new user");

# make quuxroot a server admin and reauthenticate
use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
$acctquuxroot->make_sa();

undef($t);
$t =  $vsap->client({ username => 'quuxroot', password => 'quuxrootbar'});
ok(ref($t), "create new VSAP test object for system admin (quuxroot)");

#-----------------------------------------------------------------------------
#
# test adding new domain admin with various empty fields
# (these tests should cover adding a new end user too)
#
my $validquery = qq!
<vsap type="user:add">
  <login_id>quuxfoo</login_id>
  <fullname>Quux Foo</fullname>
  <comments>test adding new domain admin with various empty fields</comments>
  <password>quuxf00bar</password>
  <confirm_password>quuxf00bar</confirm_password>
  <email_prefix>quuxfooster</email_prefix>
  <quota>99</quota>
  <da>
    <domain>quuxfoo.com</domain>
    <ftp_privs/>
    <fileman_privs/>
    <podcast_privs/>
    <mail_privs/>
    <shell_privs/>
    <shell>/bin/tcsh</shell>
    <eu_capa_ftp/>
    <eu_capa_fileman/>
    <eu_capa_mail/>
    <eu_capa_shell/>
  </da>
</vsap>
!;

# test: fullname cannot be empty
$badquery = $validquery;
$badquery =~ s/Quux Foo//;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 200, "fullname cannot be empty");

# test: fullname must be 100 chars or shorter
$badquery = $validquery;
my $longstring = sprintf "%s", 'Q' x 101;
$badquery =~ s/Quux Foo/$longstring/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 201, "fullname must be 100 chars or shorter");

# test: fullname cannot contain colon
$badquery = $validquery;
$badquery =~ s/Quux Foo/Quux:Foo/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 202, "fullname cannot contain colon");

# test: login ID cannot be empty
$badquery = $validquery;
$badquery =~ s/quuxfoo//;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 203, "login ID cannot be empty");

# test: login ID must be 16 chars or shorter
$badquery = $validquery;
$badquery =~ s/quuxfoo/quuxuumfoobarossa/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 204, "login ID must be 16 chars or shorter");

# test: login ID cannot contain [^a-z0-9_-]
$badquery = $validquery;
$badquery =~ s/quuxfoo/quux=foo/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 205, "login ID cannot contain [^a-z0-9_-]");

# test: login ID cannot begin with [^a-z0-9_]
$badquery = $validquery;
$badquery =~ s/quuxfoo/\-quuxfoo/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 206, "login ID cannot begin with dash");

# test: password cannot be empty
$badquery = $validquery;
$badquery =~ s/quuxf00bar//;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 207, "password cannot be empty");

# test: password cannot be less than 8 chars
$badquery = $validquery;
$badquery =~ s/quuxf00bar/f00bar/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 208, "password cannot be less than 8 chars");

# test: password must contain 1 non-letter
$badquery = $validquery;
$badquery =~ s/quuxf00bar/quuxfoobar/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 209, "password must contain 1 non-letter");

# test: password cannot be same as login ID
$badquery = $validquery;
$badquery =~ s/quuxfoo/quuxfoo1/;
$badquery =~ s/quuxf00bar/quuxfoo1/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 210, "password cannot be same as login ID"); 

# test: password and confirm_password must match
$badquery = $validquery;
$badquery =~ s/quuxf00bar/quuxbarf00/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 211, "password and confirm_password must match"); 

# test: email prefix can not contain '@'
$badquery = $validquery;
$badquery =~ s/quuxfooster/quuxfooster\@quuxfoo.com/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 229, "email prefix is invalid");

# test: quota cannot be empty
$badquery = $validquery;
$badquery =~ s/99//;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 212, "quota cannot be empty"); 

# test: quota cannot be zero
$badquery = $validquery;
$badquery =~ s/99/0/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 213, "quota cannot be zero"); 

# test: quota must be an integer
$badquery = $validquery;
$badquery =~ s/99/99.8/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 214, "quota must be an integer"); 

# test: domain cannot be empty
$badquery = $validquery;
$badquery =~ s/quuxfoo.com//;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 215, "domain cannot be empty"); 

# test: domain must be in a valid format
undef $de;
$badquery = $validquery;
$badquery =~ s/quuxfoo.com/quux_foo.com/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 216, "domain must be in a valid format"); 

# test: at least one service must be specified
undef $de;
$badquery = $validquery;
$badquery =~ s#<ftp_privs/>\s+##;
$badquery =~ s#<mail_privs/>\s+##;
$badquery =~ s#<shell_privs/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 217, "at least one service must be specified"); 

# test: if shell service is selected, shell must be valid
$badquery = $validquery;
$badquery =~ s#/bin/tcsh##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 218, "if shell service is selected; shell must be valid"); 

# test: user home directory cannot exist
$badquery = $validquery;
system('mkdir', '-p', '/home/quuxfoo');
undef $de;
$de = $t->xml_response($badquery);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(home directory)i, "home directory cannot exist" );
system('rm', '-r', '/home/quuxfoo');

# test: at least one end user capability must be specified
$badquery = $validquery;
$badquery =~ s#<eu_capa_ftp/>\s+##;
$badquery =~ s#<eu_capa_fileman/>\s+##;
$badquery =~ s#<eu_capa_mail/>\s+##;
$badquery =~ s#<eu_capa_shell/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 219, "at least one end user capability must be specified"); 

# test: end user capability cannot be added if corresponding domain admin
#       service is not selected
# case 1: ftp
$badquery = $validquery;
$badquery =~ s#<ftp_privs/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 220, "end user capability (ftp) cannot be selected if service undefined");
# case 2: file manager
$badquery = $validquery;
$badquery =~ s#<fileman_privs/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 220, "end user capability (fileman) cannot be selected if service undefined");
# case 3: mail
$badquery = $validquery;
$badquery =~ s#<mail_privs/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 220, "end user capability (mail) cannot be selected if service undefined");
# case 4: shell
$badquery = $validquery;
$badquery =~ s#<shell_privs/>\s+##;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 220, "end user capability (shell) cannot be selected if service undefined");

#-----------------------------------------------------------------------------
#
# test adding new domain admin with valid entries
#
$validquery =~ s#<ftp_privs/>\s+##;    # don't grant ftp privs or ftp eu_capa...
$validquery =~ s#<eu_capa_ftp/>\s+##;  # this will be important for a later test
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'verifying vsap user:add returned ok status');

my $name;
my $passwd;
my $uid;
my $gecos;
my $shell;
my $quota;
($name, $passwd, $uid, $gecos, $shell) = (getpwnam('quuxfoo'))[0,1,2,6,8];
is($name, "quuxfoo", "checking getpwnam() retval for username");
is($passwd, crypt("quuxf00bar", $passwd), "checking getpwnam() retval for passwd");
is($gecos, "Quux Foo", "checking getpwnam() retval for gecos");
like($shell, qr(tcsh$), "checking getpwnam() retval for shell");
($quota) = (Quota::query(Quota::getqcarg('/home'), $uid))[1];
$quota /= 1024;
is($quota, 99, "checking retval for quota");

# try adding the same login again
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 225, "no duplicate login id allowed");

# try adding the same login again with mixed case
$badquery = $validquery;
$badquery =~ s/quuxfoo/QuuxFoo/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 205, "no duplicate login id allowed");

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
# test adding new end user to domain admin with various invalid entries
#
$t->quit;
undef $t;
$t = $vsap->client({ username => 'quuxfoo', password => 'quuxf00bar'});

ok(ref($t), "create new VSAP test object for domain admin (quuxfoo)");

$validquery = qq!
<vsap type="user:add">
  <login_id>quuxfoochild1</login_id>
  <fullname>Quux Foo Child 1</fullname>
  <comments>test adding new end user to domain admin with various invalid entries</comments>
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

# test adding end user with quota > domain admin quota
$badquery = $validquery;
$badquery =~ s/10/100/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 221, "end user quota will exceed total domain admin quota");

# test adding end user to non-existent domain
$badquery = $validquery;
$badquery =~ s/quuxfoo.com/quuxbiff.com/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 222, "cannot create end user for unknown domain");

# test adding end user with capability that is not allowed
$badquery = $validquery;
$badquery =~ s/mail_privs/ftp_privs/;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");

is($value, 223, "cannot add end user with non-delegated capability"); 

# test adding new end user with valid entries
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, "ok", 'verifying vsap user:add returned ok status');

($name, $passwd, $uid, $gecos, $shell) = (getpwnam('quuxfoochild1'))[0,1,2,6,8];
is($name, "quuxfoochild1", "checking getpwnam() retval for username");
is($passwd, crypt("quuxf00childbar1", $passwd), "checking getpwnam() retval for passwd");
is($gecos, "Quux Foo Child 1", "checking getpwnam() retval for gecos");
like($shell, qr(tcsh$), "checking getpwnam() retval for shell");
($quota) = (Quota::query(Quota::getqcarg('/home'), $uid))[1];
$quota /= 1024;
is($quota, 10, "checking system quota (enduser)");

# test for reduction of domain admin quota after end user added
$uid = getpwnam('quuxfoo');
($quota) = (Quota::query(Quota::getqcarg('/home'), $uid))[1];
$quota /= 1024;
is($quota, 89, "checking system quota (domain admin)");

# test existence of new enduser in user:list
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><domain>quuxfoo.com</domain></vsap>!);
ok($de->find('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoochild1"]'),
   "user:list query on domain returns new end user");

# test for quota in user:list
$quota = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/quota/limit');
is($quota, 89, "checking user:list quota for domain admin (1)") || diag($de->toString(1)); 

# test for domain admin group quota in user:list
my $gq = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/group_quota/limit');
is($gq, 99, "checking domain admin allocation in user:list (1)") || diag($de->toString(1)); 

# test for comments in user:list
my $comments = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoochild1"]/comments');
is($comments, 'test adding new end user to domain admin with various invalid entries', "checking comments in user:list (1)");

# test existance of a user where the only difference is caps.
$validquery = qq!
<vsap type="user:exists">
  <login_id>quuxfooChild1</login_id>
</vsap>
!;

undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:exists']/exists");
is($value, "1", 'verifying vsap returned user exists');

# test adding N users, where N > allowed (add second child)
$validquery = qq!
<vsap type="user:add">
  <login_id>quuxfoochild2</login_id>
  <fullname>Quux Foo Child 2</fullname>
  <comments>test adding N users, where N > allowed</comments>
  <password>quuxf00childbar2</password>
  <confirm_password>quuxf00childbar2</confirm_password>
  <quota>10</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <ftp_privs/>
    <mail_privs/>
    <shell_privs/>
    <shell>/bin/tcsh</shell>
  </eu>
</vsap>
!;
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 105, "not authorized to add more end users than allowed"); 
ok(!getpwnam('quuxfoochild2'), "checking system to verify user not added");

#-----------------------------------------------------------------------------
#
# test adding webmail services 
#

# make room for more users
#
$co = new VSAP::Server::Modules::vsap::config( username => 'quuxfoo');
$co->domain('quuxfoo.com');
$co->user_limit('quuxfoo.com', 20);  # 20 is arbitrary here
$co->commit;
undef($co);

$t->quit;
undef $t;
$t = $vsap->client({ username => 'quuxfoo', password => 'quuxf00bar'});

ok(ref($t), "create new VSAP test object to test for adding webmail services");

# test 1 - adding webmail by an admin with mail privileges

$validquery = qq!
<vsap type="user:add">
  <login_id>quuxwebmail</login_id>
  <fullname>webmail child</fullname>
  <comments>test 1 - adding webmail by an admin with mail privileges</comments>
  <password>webmail1</password>
  <confirm_password>webmail1</confirm_password>
  <quota>25</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <mail_privs />
    <webmail_privs />
  </eu>
</vsap>
!;

# test adding end user with webmail privileges/service
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, 'ok', "end user added with webmail privileges");

# validate webmail service added 
undef $de;
$de = $t->xml_response(q!
  <vsap type="user:list">
    <user>quuxwebmail</user>
  </vsap>
!);
ok($de->find('/vsap/vsap[@type="user:list"]/user/capability/webmail'),
   "verified presence of webmail as capability");
ok($de->find('/vsap/vsap[@type="user:list"]/user/services/webmail'),
   "verified presence of webmail as service");

# see if 25 MB was knocked off the domain admin
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><domain>quuxfoo.com</domain></vsap>!);
$quota = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/quota/limit');
is($quota, 64, "checking user:list quota for domain admin (2)") || diag($de->toString(1));
$gq = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/group_quota/limit');
is($gq, 99, "checking domain admin allocation in user:list (2)") || diag($de->toString(1));

# test 2 - adding webmail by an admin without mail privileges

# remove the mail privileges from domain admin
$co = new VSAP::Server::Modules::vsap::config( username => 'quuxfoo');
$co->services( mail=>0 );
$co->capabilities( mail=>0 );
$co->eu_capabilities( mail=>0 );
$co->commit;
undef($co);

$t->quit;
undef $t;
$t = $vsap->client({ username => 'quuxfoo', password => 'quuxf00bar'});

$validquery = qq!
<vsap type="user:add">
  <login_id>quuxnowebmail</login_id>
  <fullname>webmail lacking child</fullname>
  <comments>test 2 - adding webmail by an admin without mail privileges</comments>
  <password>webmail1</password>
  <confirm_password>webmail1</confirm_password>
  <quota>24</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <shell_privs />
    <shell>/bin/tcsh</shell>
  </eu>
</vsap>
!;

# test adding end user with mail and webmail privileges
$badquery = $validquery;
$badquery =~ s#<shell_privs />#<shell_privs /><mail_privs /><webmail_privs />\n#;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 223, "end user added with mail and webmail privileges but should fail");

# test adding end user with webmail privileges/service
$badquery = $validquery;
$badquery =~ s#<shell_privs />#<shell_privs /><webmail_privs />#;
undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 223, "end user added with webmail privileges but should not fail");

# test adding end user with only shell privs
undef $de;
$de = $t->xml_response($validquery);
$value = $de->findvalue("/vsap/vsap[\@type='user:add']/status");
is($value, 'ok', "end user added with shell privileges");

# validate webmail service added 
undef $de;
$de = $t->xml_response(q!
  <vsap type="user:list">
    <user>quuxnowebmail</user>
  </vsap>
!);
ok(!($de->find('/vsap/vsap[@type="user:list"]/user/capability/webmail')),
   "verified webmail is not a capability");
ok(!($de->find('/vsap/vsap[@type="user:list"]/user/services/webmail')),
   "verified webmail is not a service");

# see if 24 MB was knocked off the domain admin
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><domain>quuxfoo.com</domain></vsap>!);
$quota = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/quota/limit');
is($quota, 40, "checking user:list quota for domain admin (3)") || diag($de->toString(1));
$gq = $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="quuxfoo"]/group_quota/limit');
is($gq, 99, "checking domain admin allocation in user:list (3)") || diag($de->toString(1));

#-----------------------------------------------------------------------------
#
# test adding account with UTF-8 in gecos
#
$co = new VSAP::Server::Modules::vsap::config( username => 'quuxfoo');
$co->services( mail=>1 );
$co->capabilities( mail=>1 );
$co->eu_capabilities( mail=>1 );
$co->commit;
undef($co);

$t->quit;
undef $t;
$t = $vsap->client({ username => 'quuxfoo', password => 'quuxf00bar'});

my $utf8_query = q!<vsap type="user:add">
  <login_id>quuxfoochild2</login_id>
  <fullname>Quux Foo Child 2</fullname>
  <comments>test adding account with UTF-8 in gecos</comments>
  <password>quuxf00childbar2</password>
  <confirm_password>quuxf00childbar2</confirm_password>
  <quota>10</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <mail_privs/>
  </eu>
</vsap>!;

my $utf8_gecos = "Bjørn María Usuário";
use POSIX('uname');
my ($platform, $version) = (POSIX::uname())[0,2];
if ($platform =~ /Linux/i) {
    $utf8_query =~ s!Quux Foo Child 2!$utf8_gecos!;
    undef($de);
    $de = $t->xml_response($utf8_query);
    is( $de->findvalue('/vsap/vsap[@type="user:add"]/status'), 'ok', "utf8 gecos added" )
      or diag($de->toString(1));
    is( (getpwnam('quuxfoochild2'))[6], $utf8_gecos, "gecos correctly updated" );
    undef($de);
    $de = $t->xml_response(q!<vsap type="user:list"><user>quuxfoochild2</user></vsap>!);
    is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/fullname'), Encode::decode_utf8($utf8_gecos), "fullname set") or diag($de->toString(1));
}
else {
    $utf8_query =~ s!Quux Foo Child 2!$utf8_gecos!;
    undef($de);
    $de = $t->xml_response($utf8_query);
    is( $de->findvalue('/vsap/vsap[@type="user:add"]/status'), 'ok', "utf8 gecos added" )
    or diag($de->toString(1));
    is( Encode::decode_utf8((getpwnam('quuxfoochild2'))[6]), $utf8_gecos, "gecos correctly updated" );
    undef($de);
    $de = $t->xml_response(q!<vsap type="user:list"><user>quuxfoochild2</user></vsap>!);
    is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/fullname'), $utf8_gecos, "fullname set") or diag($de->toString(1));
}

#-----------------------------------------------------------------------------
#
# stress the group quota to the limit (99 - 10 - 25 - 24 - 10 = 30)
# (i.e. cannot leave the domain admin with a zero quota)
#
$badquery = qq!
<vsap type="user:add">
  <login_id>quuxfoochild9</login_id>
  <fullname>Quux Foo Child 9</fullname>
  <comments>stress the group quota to the limit</comments>
  <password>quuxf00childbar9</password>
  <confirm_password>quuxf00childbar9</confirm_password>
  <quota>30</quota>
  <eu>
    <domain>quuxfoo.com</domain>
    <mail_privs/>
    <shell_privs/>
    <shell>/bin/tcsh</shell>
  </eu>
</vsap>
!;

undef $de;
$de = $t->xml_response($badquery);
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 221, "end user quota would result in domain admin zero quota");

#-----------------------------------------------------------------------------
#
# cleanup
#

END {
    $acctquuxroot->delete();
    getpwnam('quuxfoo') && system q(vrmuser -y quuxfoo 2>/dev/null);
    getpwnam('quuxfoochild1') && system q(vrmuser -y quuxfoochild1 2>/dev/null);
    getpwnam('quuxfoochild2') && system q(vrmuser -y quuxfoochild2 2>/dev/null);
    getpwnam('quuxfoochild9') && system q(vrmuser -y quuxfoochild9 2>/dev/null);
    getpwnam('quuxwebmail') && system q(vrmuser -y quuxwebmail 2>/dev/null);
    getpwnam('quuxnowebmail') && system q(vrmuser -y quuxnowebmail 2>/dev/null);
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if (-e "/usr/local/etc/cpx.conf.$$");
    rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf")
      if (-e "/www/conf/httpd.conf.$$");
}

# eof
