use Test::More tests => 99;

use VSAP::Server::Test::Account;
use POSIX;

my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar', type => 'account-owner' });
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', fullname => 'Joe Foo', password => 'joebarbar' });
my $acctjoebaz = VSAP::Server::Test::Account->create( { username => 'joebaz', fullname => 'Joe Foo', password => 'joebazbar' });
my $acctjoeblech = VSAP::Server::Test::Account->create( { username => 'joeblech', fullname => 'Joe Foo', password => 'joebazbar' });

ok($acctjoefoo->exists, "joefoo exists");
ok($acctjoebar->exists, "joebar exists");
ok($acctjoebaz->exists, "joebaz exists");
ok($acctjoeblech->exists, "joeblech exists");

system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$");
system('cp', '-p', '/usr/local/etc/cpx.conf', "/usr/local/etc/cpx.conf.$$");

my $APACHE2 = (((POSIX::uname())[0] =~ /Linux/) ? 1 : 0) || (-d '/usr/local/apache2');

my $vsap = $acctjoefoo->create_vsap(['vsap::domain', 'vsap::user']);

## copy system files
system('cp', '-p', '/www/conf/httpd.conf', "/www/conf/httpd.conf.$$");
system('cp', '-p', '/etc/crontab', "/etc/crontab.$$");

## mark our spot in httpd.conf
open HTTPD, ">>/www/conf/httpd.conf"
  or die "Could not open httpd.conf: $!\n";
print HTTPD <<_FOO_;
## DELETE THIS: vsap::domain test begins here
#</VirtualHost>
_FOO_
close HTTPD;

## mark our spot in crontab
open CRONTAB, ">>/etc/crontab"
  or die "Could not open /etc/crontab: $!\n";
print CRONTAB "## DELETE THIS: vsap::domain test begins here\n";
close CRONTAB;

my $t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

ok(ref($t), "obtained a vsap client.");

##
## happy add w/ log scheduling
##
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <domain_contact>joefoo\@fooster.com</domain_contact>
  <website_logs>1</website_logs>
  <log_rotate>weekly</log_rotate>
  <log_save>8</log_save>
  <mail_catchall>reject</mail_catchall>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]'), "added domain with log scheduling") 
	|| diag $de->toString(1);

## check host
my $vhost = `perl -ne "print if /^## DELETE THIS: vsap::domain test begins here/..-1" /www/conf/httpd.conf`;
ok( $vhost =~ /SSLEngine off/ || $vhost !~ /SSLEnable/, "ssl is disabled" );

SKIP: {
        skip "apache 1.3 uses User Group", 2 if ($APACHE2);
        like($vhost,qr/User\s*joefoo/, "user is joefoo");
        like($vhost,qr/Group\s*joefoo/, "group is joefoo");
}

SKIP: {
        skip "apache 2 uses SuExecUserGroup", 2 unless ($APACHE2);
        like($vhost,qr/SuexecUserGroup\s+joefoo\s+joefoo/, "user and group are correct");
}

like($vhost,qr/ServerName\s*fooster\.com/, "servername is correct");
like($vhost,qr/ServerAdmin\s*joefoo\@fooster\.com/, "server admin is correct");
like($vhost,qr!DocumentRoot\s*/home/joefoo/www/fooster\.com!, "docroot is correct");
like($vhost,qr!Alias\s*/cgi-bin /dev/null!, "cgi-bin is turned off");
like($vhost,qr!Options\s*-ExecCGI!, "no CGI");
like($vhost,qr!CustomLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-access_log combined!, "customlog is correct");
like($vhost,qr!ErrorLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-error_log!, "error log is correct");

## check crontab
my $crontab = `egrep -C2 -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(root\s+savelogs.+apacheconf.+--apachehost=fooster\.com), "entry is in crontab");

##
## now start editing the vhost
##

## add a foreign scriptalias
system('perl', '-pi', '-0777', '-e', 
	's{(## vaddhost: \(fooster\.com\).+?ExecCGI$)}{$1\n    ScriptAlias    /blarney-bin/ /home/joefoo/www/blarney-bin/}ms', '/www/conf/httpd.conf');

## add foreign serveralias
system('perl', '-pi', '-0777', '-e', 
	's{(## vaddhost: \(fooster\.com\).+?ServerName.+?$)}{$1\n    ServerAlias    bnarph.fooster.com}ms', '/www/conf/httpd.conf');

$vhost = `perl -ne "print if /^## DELETE THIS: vsap::domain test begins here/..-1" /www/conf/httpd.conf`;

ok( $vhost =~ /SSLEngine off/ || $vhost !~ /SSLEnable/, "ssl is disabled" );

SKIP: {
        skip "apache 2 uses User/Group", 2 if ($APACHE2);
        like($vhost,qr/User\s*joefoo/, "user is joefoo");
        like($vhost,qr/Group\s*joefoo/, "group is joefoo");
}

SKIP: {
        skip "apache 2 uses SuExecUserGroup", 2 if (!$APACHE2);
        like($vhost,qr/SuexecUserGroup\s+joefoo\s+joefoo/, "user and group are correct");
}

like($vhost,qr/ServerName\s*fooster\.com/, "servername is correct");
like($vhost,qr/ServerAdmin\s*joefoo\@fooster\.com/, "server admin is correct");
like($vhost,qr/ServerAlias\s*bnarph\.fooster\.com/, "foreign serveralias is correct");
like($vhost,qr!DocumentRoot\s*/home/joefoo/www/fooster\.com!, "docroot is correct");
like($vhost,qr!Alias\s*/cgi-bin /dev/null!, "cgi-bin is turned off");
like($vhost,qr!ScriptAlias\s*/blarney-bin/ /home/joefoo/www/blarney-bin!, "foreign scriptalias was setup");
like($vhost,qr!Options\s*-ExecCGI!, "no CGI");
like($vhost,qr!CustomLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-access_log combined!, "customlog is correct");
like($vhost,qr!ErrorLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-error_log!, "error log is correct");

## add www alias
my $alias = `egrep 'ServerAlias[ ]+www\.fooster\.com' /www/conf/httpd.conf`;
is( $alias, '', "no such alias exists" );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <www_alias>1</www_alias>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "added a www alias" );

$alias = `egrep -i 'ServerAlias' /www/conf/httpd.conf`;
like( $alias, qr(ServerAlias.+\bwww\.fooster\.com\b)i, "www serveralias added" );
$crontab = `egrep -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(root\s+savelogs.+apacheconf.+--apachehost=fooster\.com), "crontab entry exists.." );

## remove server alias
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <www_alias>0</www_alias>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "server alias removed" );

$alias = `egrep -i 'ServerAlias' /www/conf/httpd.conf`;
unlike( $alias, qr(ServerAlias.*\bwww\.fooster\.com\b)i, "www serveralias removed" );

$vhost = `perl -ne "print if /^## DELETE THIS: vsap::domain test begins here/..-1" /www/conf/httpd.conf`;
like( $vhost, qr(/blarney-bin/), "foreign scriptalias left alone" );
like( $vhost, qr(ServerAlias\s+.*\bbnarph\.fooster\.com\b), "foreign serveralias left alone" );

## set domain contact
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <domain_contact>glarch\@hork.tld</domain_contact>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "domain contact set" );

my $contact = `egrep -i 'ServerAdmin' /www/conf/httpd.conf`;
like( $contact, qr(glarch\@hork\.tld), "domain contact set" );

## turn on cgi
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <cgi>1</cgi>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "turned on cgi" );

my $cgi = `egrep -i 'cgi-bin' /www/conf/httpd.conf`;
like( $cgi, qr(/cgi-bin/ "(?:/home/joefoo/www/cgi-bin/|/var/www/joefoo/cgi-bin)"), "cgi is enabled" );
ok( -d "/var/www/joefoo/cgi-bin" || -d '/home/joefoo/www/cgi-bin', "cgi-bin directory exists");

## turn off cgi
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <cgi>0</cgi>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "turned off cgi" );

$cgi = `egrep -i 'cgi-bin' /www/conf/httpd.conf`;
unlike( $cgi, qr(^[^\#].*/cgi-bin/ "/var/www/joefoo/cgi-bin"), "cgi disabled" );

## turn on cgi again
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <cgi>1</cgi>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>)," turn on cgi again" );

$cgi = `egrep -i 'cgi-bin' /www/conf/httpd.conf`;
like( $cgi, qr(/cgi-bin/ "(?:/home/joefoo/www/cgi-bin/|/var/www/joefoo/cgi-bin)"), "cgi re-enabled" );

## check ssl before
my $ssl = `perl -ne 'print if m!## vaddhost.*fooster\.com!..m!</VirtualHost>!' /www/conf/httpd.conf`;
ok( $ssl =~ /SSLEngine off/ || $ssl !~ /SSLEnable/, "ssl is disabled" );
unlike( $ssl, qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio, "no rewrite rule." );

## add ssl
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <ssl>1</ssl>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "adding ssl" );

$ssl = `perl -ne 'print if m!## vaddhost.*fooster\.com.*:443!..m!</VirtualHost>!' /www/conf/httpd.conf`;

SKIP: {
        skip "freebsd doesn't add SSLEnable on edit", 1 unless ($ENV{VST_PLATFORM} eq 'LVPS2');
	like( $ssl, qr(SSLEngine\s+on)i, "ssl enabled" );
}
	
like( $ssl, qr/:443/, "ssl has 443 on port");

## check duplicates
## FIXME: add a 443 virtualhost before this test is run
## NOTE: this occurs only for virtualhost blocks that appear after an
## NOTE: existing 443 virtualhost block in httpd.conf
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <www_alias>1</www_alias>
  <cgi>0</cgi>
  <ssl>1</ssl>
  <end_users>0</end_users>
  <email_addrs>0</email_addrs>
  <website_logs>no</website_logs>
  <log_rotate>weekly</log_rotate>
  <log_save>30</log_save>
  <domain_contact>webmaster\@fooster.com</domain_contact>
  <mail_catchall>reject</mail_catchall>
</vsap>!);

#system('apachectl', 'configtest');
#system('less', '/www/conf/httpd.conf');

my @ssl = `grep '## vaddhost.*fooster\.com.*:443' /www/conf/httpd.conf`;
is( scalar(@ssl), 1, "has virtualhost block");

## FIXME: remove cgi from both vhosts

## remove ssl
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <ssl>0</ssl>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "ssl removed" );

$ssl = `perl -ne 'print if m!## vaddhost.*fooster\.com.*:443!..m!</VirtualHost>!' /www/conf/httpd.conf`;
like( $ssl, qr((?:SSLDisable|SSLEngine off))i, "ssl disabled" );
like( $ssl, qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio, "rewrite rule added" );

## enable ssl again
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <ssl>1</ssl>
</vsap>!);
like( $de->toString(1), qr(<vsap type=.domain:add./>), "ssl enabled" );

$ssl = `perl -ne 'print if m!## vaddhost.*fooster\.com.*:443!..m!</VirtualHost>!' /www/conf/httpd.conf`;
like( $ssl, qr((?:SSLEngine on|SSLEnable))i, "ssl enabled again" );
unlike( $ssl, qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio, "rewrite rule removed" );

## set end users/email
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/users/limit'), 0 , "has 0 users limit");
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/mail_aliases/limit'), 0, "has 0 mail aliases limit" );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <end_users>15</end_users>
  <email_addrs>10</email_addrs>
</vsap>!);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/users/limit'), 15, "has 15 users limit" );
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/mail_aliases/limit'), 10, "has 10 mail aliases limit" );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <end_users>0</end_users>
  <email_addrs>0</email_addrs>
</vsap>!);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/users/limit'), 0, "has 0 users limit" );
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/mail_aliases/limit'), 0, "has 0 mail aliases limit" );

## edit log rotation
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/log_rotation'), 'weekly', "log rotation is now weekly" );

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <website_logs>1</website_logs>
  <log_rotate>daily</log_rotate>
</vsap>!);
$crontab = `egrep -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(^\@daily\s+root\s+savelogs.+apacheconf.+--apachehost=fooster\.com), "log rotation schedule changed" );

## list via :list
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/log_rotation'), 'daily', "log rotation is now daily" );

## change log files (should affect rotation also)
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <website_logs>nicht</website_logs>
</vsap>!);
my $logs = `perl -ne 'print if m!## vaddhost.*fooster\.com.*:443!..m!</VirtualHost>!' /www/conf/httpd.conf`;
like($logs, qr(TransferLog\s+/dev/null), 'logs disabled');
unlike($logs, qr(CustomLog\s+), "no customlog directive");

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <website_logs>yah sure you betcha</website_logs>
</vsap>!);
$logs = `perl -ne 'print if m!## vaddhost.*fooster\.com.*:443!..m!</VirtualHost>!' /www/conf/httpd.conf`;
like($logs, qr(CustomLog\s+/www/logs/joefoo/fooster.com-access_log), "logs enabled");
unlike($logs, qr(TransferLog\s+/dev/null), "transfer log is not /dev/null");
ok( -d '/www/logs/joefoo', "the www logs directory exists" );

## verify da can edit the domain contact and mail catchall fields
#
# need to construct a 'da' user
#
undef $de;
$de = $t->xml_response(qq!
<vsap type="user:remove"><user>joeda</user></vsap>
<vsap type="user:add">
  <login_id>joeda</login_id>
  <fullname>Joe the Domain Admin</fullname>
  <password>joedais1</password>
  <confirm_password>joedais1</confirm_password>
  <quota>20</quota>
  <da>
    <domain>joedasite.com</domain>
    <ftp_privs />
    <eu_capa_ftp />
  </da>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:add"]/status'), 'ok', 'added domain admin joeda' ) ||
    diag $de->toString(1);

#
# add the domain for 'joeda'
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joeda</admin>
  <domain>joedasite.com</domain>
  <domain_contact>joeda\@joedasite.com</domain_contact>
  <www_alias>1</www_alias>
  <cgi>1</cgi>
  <ssl>1</ssl>
  <end_users>10</end_users>
  <email_addrs>10</email_addrs>
  <website_logs>yes</website_logs>
  <mail_catchall>reject</mail_catchall>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:add"]'), '', 'added domain joedasite.com' );

#
# check user:list to make sure joefoo shows up as domain_admin
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefoo</user>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/domains/domain[name="fooster.com"]/admin'), 'joefoo', 'verifying joefoo admins fooster.com' ) ||
	diag $de->toString(1);

#
# check user:list to make sure joefoo shows up as admin in domain:list for domain fooster.com
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain/admin'), 
    'joefoo', 
    'verifying domain fooster.com admined by joefoo' );
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/other_aliases'),
    'bnarph.fooster.com',
    'no other aliases' );

$vhost = `perl -ne "print if m!^## DELETE THIS: vsap::domain test begins here!..m!ErrorLog!" /www/conf/httpd.conf`;

##
## add one alias
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <other_aliases>foo.fooster.com</other_aliases>
</vsap>!);

$vhost = `perl -ne "print if m!^## DELETE THIS: vsap::domain test begins here!..m!ErrorLog!" /www/conf/httpd.conf`;
like( $vhost, qr(ServerAlias.*\bwww\.fooster\.com), "www alias preserved" );

##
## test additional server alias changes
##
is(`egrep -C2 xyz.fooster.com /etc/mail/local-host-names`, '', "no alias in local-host-names" );

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <other_aliases>abc.fooster.com, bnarph.fooster.com, xyz.fooster.com, fooster.net, www.fooster.org, aaa.fooster.net</other_aliases>
</vsap>!);
like(`egrep xyz.fooster.com /etc/mail/local-host-names`, qr(xyz.fooster.com), "alias in local-host-names" );

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/other_aliases'),
    'abc.fooster.com, bnarph.fooster.com, xyz.fooster.com, fooster.net, aaa.fooster.net, www.fooster.org',
    'have other aliases' );

##
## remove other aliases
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <other_aliases>bnarph.fooster.com</other_aliases>
</vsap>!);
ok( system('/usr/bin/egrep', '-q', 'xyz.fooster.com', '/etc/mail/local-host-names'), "no alias in local-host-names" );undef $de;

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/other_aliases'),
    'bnarph.fooster.com',
    'removed other aliases' );

##
## make sure nothing's removed when we don't supply an <other_aliases/> node
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
</vsap>!);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/other_aliases'),
    'bnarph.fooster.com',
    'other aliases left alone' );

##
## remove all other aliases left
##
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <other_aliases />
</vsap>!);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="fooster.com"]/other_aliases'),
    '',
    'all other aliases gone' );

##
## remove www alias
##
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <domain>fooster.com</domain>
  <www_alias>0</www_alias>
</vsap>!);

## side-effect check
$vhost = `perl -ne "print if m!^## DELETE THIS: vsap::domain test begins here!..m!ErrorLog!" /www/conf/httpd.conf`;
unlike( $vhost, qr(ServerAlias), "no server alias found" );

#
# login as domain admin
#
$t->quit;
undef $t;
$t = $vsap->client({ username => 'joeda', password => 'joedais1' });
                  
#
# check user:list to make sure joeda shows up as domain_admin
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>joeda</user></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/domains/domain[name="joedasite.com"]/admin'), 'joeda', 'verifying joeda admins joedasite.com' );

#
# check user:list to make sure joeda shows up as admin in domain:list for domain joedasite.com
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <admin>joeda</admin>
  <domain>joedasite.com</domain>
  <properties />
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="joedasite.com"]/admin'), 'joeda', 'verifying domain joedasite.com admined by joeda ' );
#print STDERR $de->toString(1);

#
# try editing domain that the da does not administer
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <admin>joeda</admin>
  <domain>fooster.com</domain>
  <domain_contact>joeda\@joedasite.com</domain_contact>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="domain:add"]/code'), 101, 'verifying domain fooster.com cannot be edited by joeda' );
#print STDERR $de->toString(1);

#
# try adding domain by the domain admin
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joeda</admin>
  <domain>joeda.com</domain>
  <domain_contact>joeda\@joedasite.com</domain_contact>
  <cgi>1</cgi>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="domain:add"]/code'), 101, 'verifying domain admin joeda cannot add domain' );
#print STDERR $de->toString(1);

#
# try editing domain that the da administers, but for a prohibited editable field
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <admin>joeda</admin>
  <domain>joedasite.com</domain>
  <domain_contact>joeda\@joedasite.com</domain_contact>
  <cgi>1</cgi>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="domain:add"]/code'), 101, 'verifying field cgi cannot be edited by domain admin joeda' );
#print STDERR $de->toString(1);

#
# try editing domain for legitimage fields that the da administers 
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
  <edit>1</edit>
  <admin>joeda</admin>
  <domain>joedasite.com</domain>
  <domain_contact>joesbro\@joedasite.com</domain_contact>
  <mail_catchall>delete</mail_catchall>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="domain:add"]'), '', 'verifying legitimate editable fields for domain admin can be edited' );

## make sure dev-null entries are active in aliases file after setting mail_catchall to delete.
## Note that this test will only fail if dev-null is commented out to begin with. (BUG04482)
my $null = `egrep 'dev\-null:' /etc/aliases`; chomp $null;
my $bit  = `egrep 'bit\-bucket:' /etc/aliases`; chomp $bit;
like ($null, qr(^dev\-null:\s), 'dev-null is active' );
like ($bit, qr(^bit\-bucket:\s), 'bit bucket is active' );


#
# make sure changes took
#
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list">
  <domain>joedasite.com</domain>
  <properties/>
</vsap>
!);

is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="joedasite.com"]/domain_contact'),
	'joesbro@joedasite.com',
	'verifying edited domain contact name changed' );
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="joedasite.com"]/catchall'),
	'delete',
	'verifying edited mail_catchall changed' );

# Remove the joeda user. 
$t->quit;
undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

$de = $t->xml_response(qq!<vsap type="user:remove"><user>joeda</user></vsap>!);
is($de->findvalue('/vsap/vsap[@type="user:remove"]/status'), 'ok','removed joeda user');

system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/etc/crontab");

END {

    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";

    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    rename "/www/conf/httpd.conf.$$", '/www/conf/httpd.conf';
    rename "/etc/crontab.$$", '/etc/crontab';
    system('apachectl graceful 2>&1 >/dev/null');
}
