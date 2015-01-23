use Test::More tests => 24;
BEGIN { use_ok('VSAP::Server::Modules::vsap::domain') };

#########################

use VSAP::Server::Test::Account;
use VSAP::Server::Modules::vsap::config;


my $SHADOW;
if ($ENV{VST_PLATFORM} eq 'LVPS2') { 
       $SHADOW = '/etc/shadow';
} else {
       $SHADOW = '/etc/master.passwd';
}

my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoebar = VSAP::Server::Test::Account->create( { username => 'joebar', fullname => 'Joe Foo', password => 'joebarbar' });

ok( getpwnam('joefoo') && getpwnam('joebar') );

system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$");
system('cp', '-p', '/usr/local/etc/cpx.conf', "/usr/local/etc/cpx.conf.$$");

## make a copy of system files
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

my $admin    = `sinfo | egrep -i '^account'`; chomp $admin; $admin =~ s/^account:\s*(.*)/$1/i;
my $pass = `egrep '^$admin:' $SHADOW`; chomp $pass;
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

my $vsap = $acctjoefoo->create_vsap(['vsap::domain']);
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
ok( $de->find('/vsap/vsap[@type="domain:add"]') );

$t->quit;
undef $t;
$t = $vsap->client( { username => 'joefoo', password => 'joefoobar' });

## check host
my $vhost = `perl -ne "print if /^## DELETE THIS: vsap::domain test begins here/..-1" /www/conf/httpd.conf`;

like($vhost,qr/ServerName\s*fooster\.com/, "servername is correct");
like($vhost,qr/ServerAdmin\s*joefoo\@fooster\.com/, "server admin is correct");
like($vhost,qr!DocumentRoot\s*/home/joefoo/www/fooster\.com!, "docroot is correct");
like($vhost,qr!Alias\s*/cgi-bin /dev/null!, "cgi-bin is turned off");
like($vhost,qr!Options\s*-ExecCGI!, "no CGI");
like($vhost,qr!CustomLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-access_log combined!, "customlog is correct");
like($vhost,qr!ErrorLog\s*(?:/var/log/httpd|/usr/local/apache2?/logs)/joefoo/fooster\.com-error_log!, "error log is correct");

## check crontab
my $crontab = `egrep -- "--apachehost=fooster.com" /etc/crontab`; chomp $crontab;
like( $crontab, qr(root\s+savelogs.+apacheconf.+--apachehost=fooster\.com) );

## add a user to this domain
my $co = new VSAP::Server::Modules::vsap::config(username => 'joebar');
$co->domain('fooster.com');
undef $co;

##
## disable the host w/o permission
##
$de = $t->xml_response(qq!<vsap type='domain:disable'><domain>fooster.com</domain></vsap>!);
like( $de->toString(1), qr(permission denied)i );

## become admin now
$t->quit; 
undef $t;
$t = $vsap->client( { username => $admin, password => $password } ); 

##
## happy disable
##
$de = $t->xml_response(qq!<vsap type='domain:disable'><domain>fooster.com</domain></vsap>!);
like( $de->toString, qr(<vsap type=.domain:disable./>) );

my $htconf = `perl -ne 'print if m!## vaddhost.*fooster\.com!..m!</VirtualHost>!' /www/conf/httpd.conf`;
like( $htconf, qr(\QRewriteRule   ^/ - [F,L]\E) );

## make sure we're only disabled once
my @lines = grep { /RewriteRule.*\[F,L\]/ } split "\n", $htconf;
is( scalar(@lines), 1 );

## disable again
$de = $t->xml_response(qq!<vsap type='domain:disable'><domain>fooster.com</domain></vsap>!);
like( $de->toString, qr(<vsap type=.domain:disable./>) );

@lines = grep { /RewriteRule.*\[F,L\]/ } split "\n", $htconf;
is( scalar(@lines), 1 );

$crontab = `grep 'fooster\.com' /etc/crontab`;
like( $crontab, qr(^#) );

## check user
my $passwd = `egrep '^joebar:' $SHADOW`;
(undef,$passwd,undef) = split(':', $passwd, 3);
like( $passwd, qr(^\*) );

## FIXME: check local-host-names

##
## happy enable
##
$de = $t->xml_response(qq!<vsap type='domain:enable'><domain>fooster.com</domain></vsap>!);
like( $de->toString, qr(<vsap type=.domain:enable./>) );

## check apache
$htconf = `perl -ne 'print if m!## vaddhost.*fooster\.com!..m!</VirtualHost>!' /www/conf/httpd.conf`;
unlike( $htconf, qr(\QRewriteRule   ^/ - [F,L]\E) );

## check crontab
$crontab = `grep 'fooster\.com' /etc/crontab`;
like( $crontab, qr(^[^#]) );

## check user
$passwd = `egrep '^joebar:' $SHADOW`;
(undef,$passwd,undef) = split(':', $passwd, 3);
like( $passwd, qr(^[^\*]) );


system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/www/conf/httpd.conf");
system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
       "/etc/crontab");

END {
    system('chpass', '-a', $pass);

    unlink $vsapd_config;
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    rename "/www/conf/httpd.conf.$$", '/www/conf/httpd.conf';
    rename "/etc/crontab.$$", '/etc/crontab';
    system('apachectl graceful 2>&1 >/dev/null');
}
