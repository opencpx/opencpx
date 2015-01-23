use Test::More tests => 8;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

#########################
use_ok('VSAP::Server::Test::Account');

my $user  = "joefoo";

## move existing file out of the way
rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
  if -e "/usr/local/etc/cpx.conf";

## copy existing Apache conf out of the way
system('cp', '-p', "/www/conf/httpd.conf", "/www/conf/httpd.conf.$$")
  if -e "/www/conf/httpd.conf";

## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( $acctjoefoo->exists(), "joefoo exists");

## add a hostname to httpd.conf
open CONF, ">>/www/conf/httpd.conf"
  or die "Could not write apache conf: $!\n";
print CONF <<_FOO_;
## vaddhost: ($user-domain-admin.tld) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           $user
    Group          $user
    ServerName     $user-domain-admin.tld
    ServerAlias    www.$user-domain-admin.tld
    ServerAdmin    webmaster\@$user-domain-admin.tld
    DocumentRoot   /home/$user/www/$user-domain-admin.tld
    Alias          /cgi-bin /dev/null
    Options        -ExecCGI
</VirtualHost>

_FOO_
close CONF;

## populate Apache config w/ DOS newlines
system('perl', '-pi', '-e', 's{\n}{\r\n}', '/www/conf/httpd.conf');

## create the conf object
my $co;
$co = new VSAP::Server::Modules::vsap::config( username => $user );

## run queries
ok( $co->domain_admin, "domain admin-ness" );
ok( $co->domain_admin( domain => "$user-domain-admin.tld"), "domain found" );

undef $co;

## restore files
unlink '/usr/local/etc/cpx.conf';
system('cp', '-p', "/www/conf/httpd.conf.$$", "/www/conf/httpd.conf");

##
## try accented characters in master.passwd
##
system('vuser', '--fullname=María Floja Baldasán Peña', $user);
is( (getpwnam($user))[6], "Mar\x{C3}\x{AD}a Floja Baldas\x{C3}\x{A1}n Pe\x{C3}\x{B1}a", "gecos changed" );

$co = new VSAP::Server::Modules::vsap::config( username => $user );
is( $co->fullname, "Mar\x{C3}\x{AD}a Floja Baldas\x{C3}\x{A1}n Pe\x{C3}\x{B1}a", "unicode fullname" );

## unescaped unicode - BUG14536
use utf8;
$co->comments('日本語');
is( $co->comments, '日本語'
,
"unescaped unicode in comments" );

END {
    getpwnam($user)    && system qq(vrmuser -y $user 2>/dev/null);

    ## move old files back
    if( -e "/usr/local/etc/cpx.conf.$$" ) {
	unlink "/usr/local/etc/cpx.conf";
	rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf");
    }

    if( -e "/www/conf/httpd.conf.$$" ) {
	unlink "/www/conf/httpd.conf";
	rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf");
    }

}
