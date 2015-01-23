use Test::More tests => 37;
BEGIN { use_ok('VSAP::Server::Modules::vsap::domain') };

#########################

use VSAP::Server::Test::Account;

## make sure our user doesn't exist

my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', fullname => 'Joe Foo', password => 'joebarbar' });

my $PASSWD_FILE = (-f '/etc/passwd.master' ? '/etc/passwd.master' : '/etc/passwd');

ok($acctjoefoo->exists, "joefoo exists");
ok($acctjoebar->exists, "joebar exists");

my $APACHE2 = (((POSIX::uname())[0] =~ /Linux/) ? 1 : 0) || (-d '/usr/local/apache2');

system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$");
system('cp', '-p', '/usr/local/etc/cpx.conf', "/usr/local/etc/cpx.conf.$$");

## make a copy of system files
system('cp', '-p', '/www/conf/httpd.conf', "/www/conf/httpd.conf.$$");
system('cp', '-p', '/etc/crontab', "/etc/crontab.$$");

## Clean out any old stuff.
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/etc/crontab");

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

my $admin    = `sinfo | egrep -i '^account'`; chomp $admin; $admin =~ s/^account:\s*(.*)/$1/i;
my $pass = `egrep '^$admin:' $PASSWD_FILE`; chomp $pass;
die unless $pass =~ /^$admin:/;
my $password = '';

NEW_PASSWORD: {
    ## make random password
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9', '/', '.');
    $password = $chars[rand @chars] . $chars[rand @chars] . 
      $chars[rand @chars] . $chars[rand @chars] . 
        $chars[rand @chars] . $chars[rand @chars] . 
	  $chars[rand @chars] . $chars[rand @chars];
    my $salt = $chars[rand @chars] . $chars[rand @chars];
    my $newpass = crypt($password, $salt);

    print STDERR "Setting password to '$password' ($newpass)\n";
    if ($ENV{VST_PLATFORM} eq 'LVPS2') {
        system('usermod', '-p', $newpass, $admin);
    } else {
        system('chpass', '-p', $newpass, $admin);
    }
}

my $vsap = $acctjoefoo->create_vsap(['vsap::domain', 'vsap::user']);
my $t = $vsap->client({ username => $admin, password => $password } ); 
ok(ref($t));

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
ok( $de->find('/vsap/vsap[@type="domain:add"]') ) || diag $de->toString(1);

$t->quit; 
undef $t;
$t = $vsap->client( { username => 'joefoo', password => 'joefoobar' } ); 

## check host
my $vhost = `perl -ne "print if /^## DELETE THIS: vsap::domain test begins here/..-1" /www/conf/httpd.conf`;

ok( $vhost =~ /SSLEngine off/ || $vhost !~ /SSLEnable/, "ssl is disabled" );
SKIP: {
	skip "apache2 uses suexecgroup", 2 if ($APACHE2);
	like($vhost,qr/User\s*joefoo/, "user is joefoo");
	like($vhost,qr/Group\s*joefoo/, "group is joefoo");
}

SKIP: {
	skip "apache2 uses suexecgroup", 2 unless ($APACHE2);
	like($vhost,qr/SuexecUserGroup\s+joefoo\s+joefoo/, "user and group are correct");
}

like($vhost,qr/ServerName\s*fooster\.com/, "servername is correct");
like($vhost,qr/ServerAdmin\s*joefoo\@fooster\.com/, "server admin is correct");
like($vhost,qr!DocumentRoot\s*/home/joefoo/www/fooster\.com!, "docroot is correct");
like($vhost,qr!Alias\s*/cgi-bin /dev/null!, "cgi-bin is turned off");
like($vhost,qr!Options\s*-ExecCGI!, "no CGI");
like($vhost,qr!CustomLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-access_log combined!, "customlog is correct");
like($vhost,qr!ErrorLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-error_log!, "error log is correct");

my $crontab = `egrep -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(root\s+savelogs.+apacheconf.+--apachehost=fooster\.com) );

##
## delete the host w/o permission
##
$de = $t->xml_response(qq!<vsap type='domain:delete'><domain>fooster.com</domain></vsap>!);
like( $de->toString(1), qr(permission denied)i );

##
## add a user and try to delete as admin
##
$co = new VSAP::Server::Modules::vsap::config(username => 'joebar');
$co->domain('fooster.com');
$co->commit;
undef $co;

## become admin again
$t->quit; 
undef $t;
$t = $vsap->client({ username => $admin,  password => $password });

$de = $t->xml_response(qq!<vsap type='domain:delete'><domain>fooster.com</domain></vsap>!);
like( $de->toString(1), qr(may not delete a domain with subusers)i );


## remove the user
system q(vrmuser -y joebar 2>/dev/null);

##
## delete no domain
##
$de = $t->xml_response(qq!<vsap type='domain:delete'/>!);
## FIXME: need a test, but there is not outward sign of problem except STDERR

##
## happy delete
##
$de = $t->xml_response(qq!<vsap type='domain:delete'><domain>fooster.com</domain></vsap>!);
like( $de->toString, qr(<vsap type=.domain:delete./>) );

ok( -s '/www/conf/httpd.conf', "zero length conf file" );

my $httpdconf = `grep 'fooster\.com' /www/conf/httpd.conf`;
is( $httpdconf, '');

$crontab = `grep 'fooster\.com' /etc/crontab`;
is( $crontab, '' );

my $hostname = `hostname`; chomp $hostname;
$co = new VSAP::Server::Modules::vsap::config(username => 'joefoo');
is( $co->domain, $hostname );
undef $co;

##
## test multiple deletes
##
## add some new hosts
$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>fooster.com</domain>
  <domain_contact>joefoo\@fooster.com</domain_contact>
  <log_rotate>weekly</log_rotate>
  <log_save>8</log_save>
  <mail_catchall>reject</mail_catchall>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>joefoo</admin>
  <domain>foosterfernando.com</domain>
  <domain_contact>joefoo\@fooster.com</domain_contact>
  <log_rotate>monthly</log_rotate>
  <log_save>3</log_save>
  <mail_catchall>reject</mail_catchall>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

$de = $t->xml_response(qq!<vsap type="domain:add">
  <admin>$admin</admin>
  <domain>foosterjust.com</domain>
  <domain_contact>joefoo\@foosterjust.com</domain_contact>
  <log_rotate>weekly</log_rotate>
  <log_save>8</log_save>
  <mail_catchall>reject</mail_catchall>
</vsap>!);
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

## we're a DA
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );
ok( $co->domain_admin( user => 'joefoo' ), 'joefoo is a domain admin' );
undef $co;

## delete the hosts
$de = $t->xml_response(qq!<vsap type='domain:delete'>
  <domain>fooster.com</domain>
  <domain>foosterjust.com</domain>
</vsap>!);
like( $de->toString, qr(<vsap type=.domain:delete./>) );

sleep 1;

## update our object
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );

## domains go bye-bye
my $domains = $co->domains;
ok( ! $domains->{'fooster.com'}, "fooster.com is gone" );
ok( ! $domains->{'foosterjust.com'}, "foosterjust.com is gone" );

## we're still a DA
ok( $co->domain_admin( user => 'joefoo' ), "joefoo is no longer a domain admin" );
undef $co;

## delete last remaining domain for joefoo
$de = $t->xml_response(qq!<vsap type='domain:delete'>
  <domain>foosterfernando.com</domain>
</vsap>!);

sleep 1;

$co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );

## and we're not a DA anymore
ok( ! $co->domain_admin( user => 'joefoo' ), "joefoo is no longer a domain admin" );

#print STDERR $co->{dom}->toString(1);

## test the hosts
$httpdconf = `grep 'fooster\.com' /www/conf/httpd.conf`;
is( $httpdconf, '');
$httpdconf = `grep 'foosterjust\.com' /www/conf/httpd.conf`;
is( $httpdconf, '');

$crontab = `grep 'fooster\.com' /etc/crontab`;
is( $crontab, '' );
$crontab = `grep 'foosterjust\.com' /etc/crontab`;
is( $crontab, '' );

system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/etc/crontab");

END {
    print STDERR "Restoring account password entry...\n";
    system('chpass', '-a', $pass);

    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    rename "/www/conf/httpd.conf.$$", '/www/conf/httpd.conf';
    rename "/etc/crontab.$$", '/etc/crontab';
    system('apachectl graceful 2>&1 >/dev/null');
}
