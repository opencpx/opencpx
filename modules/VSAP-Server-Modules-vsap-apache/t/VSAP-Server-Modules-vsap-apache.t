use Test::More tests => 10;
BEGIN { use_ok('VSAP::Server::Modules::vsap::apache') };

#########################

my $pwd = `pwd`; chomp $pwd;

##
## make backup of httpd.conf
##
if( -e '/www/conf/httpd.conf' ) {
    system('cp', '-p', '/www/conf/httpd.conf', "/www/conf/httpd.conf-$$");
}

##
## loadmodule
##

## add loadmodule directive to blank file
rename("/www/conf/httpd.conf", "/www/conf/httpd.conf-testfoo");
open HTTPD, "> /www/conf/httpd.conf";
close HTTPD;

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite.so',
						 action => 'enable');
like(`cat /www/conf/httpd.conf`, qr(^LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so) );

## add loadmodule to a file that already has loadmodule
open HTTPD, "> /www/conf/httpd.conf";
print HTTPD <<_CONF_;
LoadModule    rewrite_module    libexec/mod_rewrite.so
#LoadModule    rewrite_module    libexec/mod_rewrite.so
_CONF_
close HTTPD;

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite.so',
						 action => 'enable');
like(`cat /www/conf/httpd.conf`, qr(\A^LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so
#LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so)xm );

## add loadmodule to a file that already has loadmodule
open HTTPD, "> /www/conf/httpd.conf";
print HTTPD <<_CONF_;
#LoadModule    rewrite_module    libexec/mod_rewrite.so
LoadModule    rewrite_module    libexec/mod_rewrite.so
_CONF_
close HTTPD;

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite.so',
						 action => 'enable');
like(`cat /www/conf/httpd.conf`, qr(^#LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so
LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so)xm );


## add loadmodule to a file that already has loadmodule
open HTTPD, "> /www/conf/httpd.conf";
print HTTPD <<_CONF_;
#LoadModule    rewrite_module    libexec/mod_rewrite.so
#LoadModule    rewrite_module    libexec/mod_rewrite.so
_CONF_
close HTTPD;

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite.so',
						 action => 'enable');
like(`cat /www/conf/httpd.conf`, qr(^#LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so
LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so)xm );

## disable a loadmodule entry
VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 action => 'disable');
like(`cat /www/conf/httpd.conf`, qr(\A^#LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so
				    ^#LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so)xm );

open HTTPD, "> /www/conf/httpd.conf";
close HTTPD;

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite.so',
						 action => 'enable');
like(`cat /www/conf/httpd.conf`, qr(^LoadModule\s+rewrite_module\s+libexec/mod_rewrite\.so)xm );

VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 action => 'delete');
is(`cat /www/conf/httpd.conf`, '' );

open HTTPD, "> /www/conf/httpd.conf";
print HTTPD <<_CONF_;
#LoadModule    rewrite_module    libexec/mod_rewrite.so
LoadModule    rewrite_module    libexec/mod_rewrite.so


## some comments 'n' stuff
<VirtualHost foo.com>
  ServerName foo.com
</VirtualHost>
_CONF_
close HTTPD;

## disable module
VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 action => 'disable');
like( `cat /www/conf/httpd.conf`, qr(#LoadModule\s+rewrite_module.*


## some comments)m );

## enable a different module
VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
						 module => 'libexec/mod_rewrite-1.3.so',
						 action => 'enable' );
like( `cat /www/conf/httpd.conf`, qr(#LoadModule\s+rewrite_module.*
LoadModule\s+rewrite_module\s+libexec/mod_rewrite\-1\.3\.so


## some comments)m );

END {
    unlink '/www/conf/httpd.conf-testfoo';
    if( -e "/www/conf/httpd.conf-$$" ) {
	rename "/www/conf/httpd.conf-$$", "/www/conf/httpd.conf";
	system('apachectl', 'graceful');
    }
}
