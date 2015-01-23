use Test::More tests => 33;
BEGIN { use_ok('VSAP::Server::Modules::vsap::domain') };

#########################

use VSAP::Server::Test::Account;

my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar', type => 'account-owner' });
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', fullname => 'Joe Foo', password => 'joebarbar' });
my $acctjoebaz = VSAP::Server::Test::Account->create( { username => 'joebaz', fullname => 'Joe Foo', password => 'joebazbar' });
my $acctjoeblech = VSAP::Server::Test::Account->create( { username => 'joeblech', fullname => 'Joe Foo', password => 'joebazbar' });
my $acctjoeglarch = VSAP::Server::Test::Account->create( { username => 'joeglarch', fullname => 'Joe Foo', password => 'joeglarchbar' });

ok($acctjoefoo->exists, "joefoo exists");
ok($acctjoebar->exists, "joebar exists");
ok($acctjoebaz->exists, "joebaz exists");
ok($acctjoeblech->exists, "joeblech exists");
ok($acctjoeglarch->exists, "joeglarch sexists");

system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$");
system('cp', '-p', '/usr/local/etc/cpx.conf', "/usr/local/etc/cpx.conf.$$");

my $vsap = $acctjoefoo->create_vsap(['vsap::domain']);

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

my $t = $vsap->client( { username => 'joefoo', password => 'joefoobar' });

ok(ref($t), 'obtained a client');

my $de;

my $co;
for my $user qw(joebar joebaz joeblech) {
    $co = new VSAP::Server::Modules::vsap::config( username => $user );
    $co->domain("foo-$$.com");
    undef $co;
}

##
## test missing data for add
##
## missing domain admin
$de = $t->xml_response(qq!<vsap type="domain:add">
<domain>fooster.com</domain>
<domain_contact>joe\@fooster.com</domain_contact>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(missing domain admin)i, "missing domain admin" );

## missing domain
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain_contact>joe\@fooster.com</domain_contact>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(missing domain$)i, "missing domain" );

## missing contact info
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>fooster.com</domain>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(missing contact)i, "missing contact" );

## bad contact info
$de = $t->xml_response(q!<vsap type="domain:add">
<admin>joefoo</admin>
<domain_contact>webmaster@ horseysauce.com</domain_contact>
<domain>fooster.com</domain>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(bad domain contact)i, "bad domain contact" );

## domain admin nonexistent
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoot</admin>
<domain>fooster.com</domain>
<domain_contact>joefoot\@fooster.com</domain_contact>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(admin does not exist)i, "admin does not exist" );

## illegal rotation period
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>fooster.com</domain>
<domain_contact>joefoo\@fooster.com</domain_contact>
<website_logs>1</website_logs>
<log_rotate>fishly</log_rotate>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(illegal rotation period)i, "illegal rotation period" );

##
## happy add
##
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <domain_contact>joefoo\@fooster.com</domain_contact>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]'), "happy add" );

$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->add_domain('fooster.com');
ok( ! system('egrep', '-C2','-q','^fooster\.com$', '/etc/mail/local-host-names') );
undef $co;

##
## existing domain in httpd.conf
##
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>fooster.com</domain>
<domain_contact>joefoo\@fooster.com</domain_contact>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Domain already exists in httpd\.conf)i, "existing httpd domain check" );

# tweak the domain add
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>foo.ter.com</domain>
<domain_contact>joefoo\@foo.ter.com</domain_contact>
</vsap>!);
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo.ter.com</domain></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/name'), 'foo.ter.com' );

# tweak the domain add (again)
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>foo-ter.com</domain>
<domain_contact>joefoo\@foo-ter.com</domain_contact>
</vsap>!);
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>foo-ter.com</domain></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/name'), 'foo-ter.com' );

## clean up new host
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");

## mark our spot in httpd.conf again
open HTTPD, ">>/www/conf/httpd.conf"
  or die "Could not open httpd.conf: $!\n";
print HTTPD <<_FOO_;
## DELETE THIS: vsap::domain test begins here
#</VirtualHost>
_FOO_
close HTTPD;

##
## existing domain in cpx.conf
##
$de = $t->xml_response(qq!<vsap type="domain:add">
<admin>joefoo</admin>
<domain>fooster.com</domain>
<domain_contact>joefoo\@fooster.com</domain_contact>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Domain already exists in cpx\.conf)i, "existing cpx domain check" );
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");
undef $co;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
$co->remove_domain('fooster.com');
undef $co;

## mark our spot in httpd.conf again
open HTTPD, ">>/www/conf/httpd.conf"
  or die "Could not open httpd.conf: $!\n";
print HTTPD <<_FOO_;
## DELETE THIS: vsap::domain test begins here
#</VirtualHost>
_FOO_
close HTTPD;


##
## try another happy add w/ log scheduling and cgi
##
$cgi = `egrep -C2 -i 'cgi-bin' /www/conf/httpd.conf`;
unlike( $cgi, qr(^[^\#].*/cgi-bin/ "/home/joefoo/www/cgi-bin/") );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <domain_contact>joefoo\@fooster.com</domain_contact>
  <website_logs>1</website_logs>
  <log_rotate>weekly</log_rotate>
  <log_save>8</log_save>
  <mail_catchall>reject</mail_catchall>
  <cgi>1</cgi>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

my $crontab = `egrep -C2 -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(root\s+savelogs.+apacheconf.+--apachehost=fooster\.com) );

$cgi = `egrep -C2 -i 'cgi-bin' /www/conf/httpd.conf`;
like( $cgi, qr!/cgi-bin/ "(?:/var/www/joefoo/cgi-bin/|/home/joefoo/www/cgi-bin/)"! );

my $ca = `egrep -C2 '^\@fooster.com' /etc/mail/virtusertable`; chomp $ca;
like( $ca, qr(error:nouser) );

## test catchall
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>fooster.com</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap/domain/catchall'), 'reject' );
ok(-C '/etc/mail/virtusertable' <= -C '/etc/mail/virtusertable.db', "newer virtusertable file");

##
## add a new host via vaddhost and see if we can detect it
##
my @vaddhost = qw(vaddhost --defaults);
push @vaddhost, "--user=joeglarch";
push @vaddhost, "--hostname=uglysmart.tld";
push @vaddhost, "--admin=joeglarch\@uglysmart.tld";
push @vaddhost, '--cgibin=1';
push @vaddhost, '--transferlog=1';
push @vaddhost, '--errorlog=1';
system(@vaddhost);

undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"><domain>uglysmart.tld</domain><properties/></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="domain:list"]/domain[name="uglysmart.tld"]/admin'), 'joeglarch', "correct domain admin for new domain" );

## make sure we're an admin too
$co = new VSAP::Server::Modules::vsap::config( username => 'joeglarch' );
ok( $co->domain_admin, "joeglarch is a domain admin" );

my $domains = $co->domains;
is( $domains->{'uglysmart.tld'}, 'joeglarch', "joeglarch is admin for uglysmart.tld" );
undef $co;

## addition alias side effect
ok( system('/usr/bin/egrep','-C2','-q', 'www.fooster2.net', '/etc/mail/local-host-names'), "No alias in local-host-names" );

##
## add domain w/ additional aliases
##
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>fooster2.com</domain>
  <domain_contact>joefoo\@fooster2.com</domain_contact>
  <other_aliases>fooster2.net www.fooster2.net fooster2.org www.fooster2.org</other_aliases>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

like( `egrep -i -C2 serveralias.*fooster2 /www/conf/httpd.conf`, qr(fooster2.net www.fooster2.net fooster2.org www.fooster2.org), "new server aliases found" );
like( `egrep -i -C2 www.fooster2.net /etc/mail/local-host-names`,qr(www.fooster2.net), "Alias in local-host-names" );

END {
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
	   "/www/conf/httpd.conf");
    system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
	   "/etc/crontab");
    system('apachectl graceful 2>&1 >/dev/null');
}
