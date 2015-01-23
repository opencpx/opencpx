use Test::More tests => 8;
BEGIN { use_ok('VSAP::Server::Modules::vsap::config') };

#########################
use_ok('VSAP::Server::Test::Account');

my $user                                         = 'joefoo';
$VSAP::Server::Modules::vsap::config::CONFIG     = "cpx.conf.$$";
$VSAP::Server::Modules::vsap::config::HTTPD_CONF = "httpd.conf.$$";
$VSAP::Server::Modules::vsap::config::TRACE      = 0;

## set up a user w/ mail, ftp
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
ok( getpwnam($user) );

my $co = new VSAP::Server::Modules::vsap::config(username => $user);
ok( ! $co->domain_admin, "not a domain admin" );
my $domains = $co->domains;
is( scalar keys %$domains, 0, "no domains for eu" );
undef $co;

## time passes...
sleep 1;

##
## make sure a user is upgraded to a DA after external httpd.conf change
##
open CONF, ">>$VSAP::Server::Modules::vsap::config::HTTPD_CONF"
  or die "Could not write new conf file: $!\n";
print CONF <<_CONF_;

## vaddhost: (glarch.com) at 204.200.222.9:80
<VirtualHost 204.200.222.9:80>
    SSLDisable
    User           $user
    Group          $user
    ServerName     glarch.com
    ServerAlias    www.glarch.com
    ServerAdmin    webmaster\@glarch.com
    DocumentRoot   /home/$user/www/glarch.com
    ScriptAlias    /cgi-bin/ "/home/$user/www/cgi-bin/"
    <Directory /home/$user/www/cgi-bin>
        AllowOverride None
        Options ExecCGI
        Order allow,deny
        Allow from all
    </Directory>
    CustomLog      /usr/local/apache/logs/$user/glarch.com-access_log combined
    ErrorLog       /usr/local/apache/logs/$user/glarch.com-error_log
</VirtualHost>
_CONF_
close CONF;

## time passes...
sleep 1;

## reparse config
$co = new VSAP::Server::Modules::vsap::config( username => $user );
ok( $co->domain_admin, "is a domain admin" );
$domains = $co->domains(admin => $user);
is( scalar keys %$domains, 1, "has one domain" );
is( $domains->{'glarch.com'}, $user, "domain admin for domain" );

#undef $co;
#$co = new VSAP::Server::Modules::vsap::config( username => $user );

END {
    getpwnam($user)      && system qq(vrmuser -y $user 2>/dev/null);
    unlink "httpd.conf.$$";
    unlink "cpx.conf.$$";
}
