use Test::More tests => 33;
BEGIN { use_ok('VSAP::Server::Modules::vsap::sys::logs') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Modules::vsap::config;

my $vsapd_config = "_config.$$.vsapd";

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up a user
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    system( 'vadduser --quiet --login=joefoo --password=joefoobar --home=/home/joefoo --fullname="Joe Foo" --services=ftp,mail --quota=100' )
        and die "Could not create user 'joefoo'\n";
    system('pw', 'groupmod', '-n', 'wheel', '-m', 'joefoo');  ## make us an administrator

    system( 'vadduser --quiet --login=joebar --password=joebarbar --home=/home/joebar --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joebar'\n";
    system( 'vadduser --quiet --login=joebaz --password=joebazbar --home=/home/joebaz --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joebaz'\n";
    system( 'vadduser --quiet --login=joeblech --password=joeblechbar --home=/home/joeblech --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joeblech'\n";
    system( 'vadduser --quiet --login=joesablech --password=joeblechbar --home=/home/joesablech --fullname="Joe SA Blech" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joesablech'\n";
}
ok( getpwnam('joefoo') && getpwnam('joebar') && 
    getpwnam('joebaz') && getpwnam('joeblech') && getpwnam('joeblech') );

## FIXME: added new users; assign these to domains now for later tests

system('cp', '-p', '/etc/crontab', "/etc/crontab.$$");
system('cp', '-p', '/etc/mail/local-host-names', "/etc/mail/local-host-names.$$");

## fix Apache
{
    rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
      if -e "/usr/local/etc/cpx.conf";

    ## a-patch-y fix
    my $ip    = `sinfo | egrep '^ip' | awk '{print \$2}'`; chomp $ip;
    my $admin = `sinfo | egrep '^account'    | awk '{print \$2}'`; chomp $admin;
    print STDERR "Using '$ip' for ip address\n" if $ENV{VSAPD_DEBUG};
    print STDERR "Using '$admin' for admin\n"   if $ENV{VSAPD_DEBUG};

    ## move apache config file
    system('cp', '-rp', "/www/conf/httpd.conf", "/www/conf/httpd.conf.$$")
      if -e "/www/conf/httpd.conf";

    open CONF, ">>/www/conf/httpd.conf"
      or die "Could not open Apache conf for append: $!\n";
    print CONF <<_CONFFILE_;

## vaddhost: (foo-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    ServerName     foo-$$.com
    ServerAlias    www.foo-$$.com
    ServerAdmin    webmaster\@foo-$$.com
    ScriptAlias    /cgi-bin/ "/home/joefoo/www/cgi-bin/"
    TransferLog    /www/logs/joefoo/foo-$$.com-access_log
    ErrorLog       /dev/null
</VirtualHost>

## vaddhost: (bar-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/bar-$$.com
    ServerName     bar-$$.com
    ServerAlias    www.bar-$$.com
</VirtualHost>

## vaddhost: (baz-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/baz-$$.com
    ServerName     baz-$$.com
    ServerAlias    www.baz-$$.com
</VirtualHost>

## vaddhost: (baz-$$.com) at $ip:443
<VirtualHost $ip:443>
    SSLEnable
    User           joefoo
    Group          joefoo
    DocumentRoot   /home/joefoo/www/baz-$$.com
    ServerName     baz-$$.com
    ServerAlias    www.baz-$$.com
</VirtualHost>

## vaddhost: (blech-$$.com) at $ip:80
<VirtualHost $ip:80>
    SSLDisable
    User           $admin
    Group          $admin
    ServerName     blech-$$.com
    ServerAlias    www.blech-$$.com
</VirtualHost>
_CONFFILE_
    close CONF;
}

mkdir "/www/logs/joefoo";

## put some stuff in a log
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log" or die $!;
print FILE <<EOF;
64.173.22.123 - - [18/Jul/2005:00:42:32 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 3819 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)"
64.173.22.123 - - [18/Jul/2005:00:43:12 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 32768 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)"
66.249.64.36 - - [18/Jul/2005:00:46:18 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.36 - - [18/Jul/2005:00:46:23 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
67.183.165.70 - - [18/Jul/2005:00:47:34 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 40952 "http://profile.myspace.com/index.cfm?fuseaction=user.viewProfile&friendID=436564&Mytoken=20050717234105" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705)"
12.226.21.216 - - [18/Jul/2005:00:53:01 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "AppleSyndication/38"
68.142.251.94 - - [18/Jul/2005:00:54:20 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
68.142.251.169 - - [18/Jul/2005:00:54:20 -0600] "GET /Blogs/2003/1062643953-entry.xml-comment.1080713954.5476 HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
68.142.249.99 - - [18/Jul/2005:00:55:42 -0600] "GET /Blogs/2003/7/1059278568-entry.xml-comment.1059500751.47181 HTTP/1.0" 200 260 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
208.55.254.110 - - [18/Jul/2005:00:56:25 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.5) Gecko/20041206 Thunderbird/1.0"
66.249.71.50 - - [18/Jul/2005:00:58:04 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.49 - - [18/Jul/2005:01:00:18 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.49 - - [18/Jul/2005:01:00:18 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
68.142.251.196 - - [18/Jul/2005:01:01:26 -0600] "GET /Blogs/2003/1071770223-entry.xml-comment.1071851379.15274 HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
166.70.98.187 - - [18/Jul/2005:01:04:07 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "AppleSyndication/38"
64.242.88.50 - - [18/Jul/2005:01:10:45 -0600] "GET /Blogs/2005/2/1108003911-entry.xml HTTP/1.1" 200 7598 "-" "Mozilla/4.0 compatible ZyBorg/1.0 Dead Link Checker (wn.dlc\@looksmart.net; http://www.WISEnutbot.com)"
64.246.165.210 - - [18/Jul/2005:01:14:39 -0600] "GET /robots.txt HTTP/1.1" 404 2889 "http://www.whois.sc/" "SurveyBot/2.3 (Whois Source)"
64.246.165.210 - - [18/Jul/2005:01:14:40 -0600] "GET / HTTP/1.1" 200 19429 "http://www.whois.sc/improvist.org" "SurveyBot/2.3 (Whois Source)"
66.249.71.28 - - [18/Jul/2005:01:19:15 -0600] "GET /Media/2004/1/index.xml HTTP/1.0" 200 5215 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
EOF
close FILE;
chown 0, 0, "/www/logs/joefoo/foo-$$.com-access_log";
#die;

## touch some fake archives
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log.1024.gz" or die $!; print FILE "\n"; close FILE;
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log.1025.gz" or die $!; print FILE "\n"; close FILE;
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log.1026.gz" or die $!; print FILE "\n"; close FILE;
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log.1027.gz" or die $!; print FILE "\n"; close FILE;

## write a simple config file
open VSAPD, ">$vsapd_config"
    or die "Couldn't open '$vsapd_config': $!\n";
print VSAPD <<_CONFIG_;
LoadModule    vsap::auth
LoadModule    vsap::logout
LoadModule    vsap::sys::logs
LoadModule    vsap::domain
_CONFIG_
close VSAPD;

my $vsap = new VSAP::Server::Test( { vsapd_config => $vsapd_config } );

# First try a domain admin
my $t = $vsap->client({ username => 'joefoo', password => 'joefoobar' }); 
ok(ref($t));

my $de;
my $co;
for my $user qw(joebar joebaz joeblech) {
    $co = new VSAP::Server::Modules::vsap::config( username => $user );
    $co->domain("foo-$$.com");
    undef $co;
}

$co = new VSAP::Server::Modules::vsap::config( username => 'joesablech' );
undef $co;

# list domains
undef $de;
$de = $t->xml_response(qq!<vsap type="domain:list"/>!);
my @domains = $de->findnodes('/vsap/vsap[@type="domain:list"]/domain');
ok( scalar(@domains) >= 5, "domain count" ); ## server domain + our vhosts + (any existing vhosts)
my $admin = `sinfo | egrep '^account'    | awk '{print \$2}'`; chomp $admin;

is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='foo-$$.com']/admin"), 'joefoo', );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='bar-$$.com']/admin"), 'joefoo', );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='baz-$$.com']/admin"), 'joefoo', );
is( $de->findvalue("/vsap/vsap[\@type='domain:list']/domain[name='blech-$$.com']/admin"), $admin, );

# first try the get_vhost_logs function
my %logs = VSAP::Server::Modules::vsap::sys::logs::get_vhost_logs("foo-$$.com");
is ($logs{ErrorLog}, "/dev/null");

# list logs for one of the domains
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:logs:list"><domain>foo-$$.com</domain></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='sys:logs:list']/log[domain='foo-$$.com'][description='TransferLog']/path"), "/www/logs/joefoo/foo-$$.com-access_log");
is($de->findvalue("/vsap/vsap[\@type='sys:logs:list']/log[domain='foo-$$.com'][description='TransferLog']/number_archived"), "4");

# page log contents for one of the logs
$de = $t->xml_response(qq!<vsap type="sys:logs:show"><path>/www/logs/joefoo/foo-$$.com-access_log</path><range>10</range><page>2</page></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='sys:logs:show']/page"), "2");

# check for badly-ordered first line (BUG08492)
$de = $t->xml_response(qq!<vsap type="sys:logs:show"><path>/www/logs/joefoo/foo-$$.com-access_log</path><range>200</range><page>1</page></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='sys:logs:show']/page"), "1");
my @lines = split /\n/, $de->findvalue("/vsap/vsap[\@type='sys:logs:show']/content");
ok ($lines[0] =~ m{18/Jul/2005:00:42:32 -0600});

# search log 

# try to list logs as not domain admin
undef $t;
$t = $vsap->client({ username => 'joebar', password => 'joebarbar' });
ok(ref($t));
$de = $t->xml_response(qq!<vsap type="sys:logs:list"><domain>foo-$$.com</domain></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:logs:list']/message"), "Not authorized");
# now try a domain admin
undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar' });
ok(ref($t));

# list archives
$de = $t->xml_response(qq!<vsap type="sys:logs:list_archives"><path>/usr/local/apache/logs/joefoo/foo-$$.com-access_log</path></vsap>!);
my @archives = $de->findnodes("/vsap/vsap[\@type='sys:logs:list_archives']/archive");
ok(scalar(@archives) == 4);

# test double-slashes
my @paths = $de->findvalue("/vsap/vsap[\@type='sys:logs:list_archives']/archive/path");
ok($paths[0] !~ m|//|);

# archive now as an end user
undef $t;
$t = $vsap->client({ username => 'joebar', password => 'joebarbar' });
ok(ref($t));
$de = $t->xml_response(qq!<vsap type="sys:logs:archive_now"><domain>foo-$$.com</domain><path>/www/logs/joefoo/foo-$$.com-access_log</path></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:logs:archive_now']/message"), "Not authorized");

# now try as admin
undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar' });
ok(ref($t));
$de = $t->xml_response(qq!<vsap type="sys:logs:archive_now"><domain>foo-$$.com</domain><path>/www/logs/joefoo/foo-$$.com-access_log</path></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='sys:logs:archive_now']/status"), "ok");

$de = $t->xml_response(qq!<vsap type="sys:logs:list_archives"><path>/www/logs/joefoo/foo-$$.com-access_log</path></vsap>!);
@archives = $de->findnodes("/vsap/vsap[\@type='sys:logs:list_archives']/archive");
ok(scalar(@archives) == 5);

# test for server domain
$co = new VSAP::Server::Modules::vsap::config( username => "joefoo" );
$host = $co->primary_domain();
undef $co;
ok($host);
$de = $t->xml_response(qq!<vsap type="sys:logs:list"><domain>$host</domain></vsap>!);
@logs = $de->findnodes("/vsap/vsap[\@type='sys:logs:list']/log[domain='$host']/path");
ok(scalar(@logs) > 0);

## re-create the log for the delete test
open FILE, ">/www/logs/joefoo/foo-$$.com-access_log" or die $!;
print FILE <<EOF;
64.173.22.123 - - [18/Jul/2005:00:42:32 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 3819 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)"
64.173.22.123 - - [18/Jul/2005:00:43:12 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 32768 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)"
66.249.64.36 - - [18/Jul/2005:00:46:18 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.36 - - [18/Jul/2005:00:46:23 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
67.183.165.70 - - [18/Jul/2005:00:47:34 -0600] "GET /Blogs/Images/pedro.jpg HTTP/1.1" 200 40952 "http://profile.myspace.com/index.cfm?fuseaction=user.viewProfile&friendID=436564&Mytoken=20050717234105" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705)"
12.226.21.216 - - [18/Jul/2005:00:53:01 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "AppleSyndication/38"
68.142.251.94 - - [18/Jul/2005:00:54:20 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
68.142.251.169 - - [18/Jul/2005:00:54:20 -0600] "GET /Blogs/2003/1062643953-entry.xml-comment.1080713954.5476 HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
68.142.249.99 - - [18/Jul/2005:00:55:42 -0600] "GET /Blogs/2003/7/1059278568-entry.xml-comment.1059500751.47181 HTTP/1.0" 200 260 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
208.55.254.110 - - [18/Jul/2005:00:56:25 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.5) Gecko/20041206 Thunderbird/1.0"
66.249.71.50 - - [18/Jul/2005:00:58:04 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.49 - - [18/Jul/2005:01:00:18 -0600] "GET /robots.txt HTTP/1.0" 404 2889 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
66.249.64.49 - - [18/Jul/2005:01:00:18 -0600] "GET / HTTP/1.0" 200 19387 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
68.142.251.196 - - [18/Jul/2005:01:01:26 -0600] "GET /Blogs/2003/1071770223-entry.xml-comment.1071851379.15274 HTTP/1.0" 404 2889 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
166.70.98.187 - - [18/Jul/2005:01:04:07 -0600] "GET /rss.xml HTTP/1.1" 200 26484 "-" "AppleSyndication/38"
64.242.88.50 - - [18/Jul/2005:01:10:45 -0600] "GET /Blogs/2005/2/1108003911-entry.xml HTTP/1.1" 200 7598 "-" "Mozilla/4.0 compatible ZyBorg/1.0 Dead Link Checker (wn.dlc\@looksmart.net; http://www.WISEnutbot.com)"
64.246.165.210 - - [18/Jul/2005:01:14:39 -0600] "GET /robots.txt HTTP/1.1" 404 2889 "http://www.whois.sc/" "SurveyBot/2.3 (Whois Source)"
64.246.165.210 - - [18/Jul/2005:01:14:40 -0600] "GET / HTTP/1.1" 200 19429 "http://www.whois.sc/improvist.org" "SurveyBot/2.3 (Whois Source)"
66.249.71.28 - - [18/Jul/2005:01:19:15 -0600] "GET /Media/2004/1/index.xml HTTP/1.0" 200 5215 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
EOF
close FILE;

# delete archive
@archives = `ls /www/logs/joefoo/foo-$$.com-access_log*gz`;
ok(scalar(@archives) == 5);

my $testarchive = $archives[0];
chomp $testarchive;
undef $t;
$t = $vsap->client({ username => 'joebar', password => 'joebarbar' });
ok(ref($t));
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:logs:del_archive"><domain>foo-$$.com</domain><path>$testarchive</path></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='error' and \@caller='sys:logs:del_archive']/message"), "Not authorized");
undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar' });
ok(ref($t));
undef $de;
# chown just to test a permissions case
# `chown joefoo:joefoo /www/logs/joefoo/foo-$$.com-access_log`;
ok (-e $testarchive);
$de = $t->xml_response(qq!<vsap type="sys:logs:del_archive"><domain>foo-$$.com</domain><path>$testarchive</path></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='sys:logs:del_archive']/success/path/status"), "ok");
ok(! -e $testarchive);

END {
    getpwnam('joefoo')     && system q(vrmuser -y joefoo 2>/dev/null);
    getpwnam('joebar')     && system q(vrmuser -y joebar 2>/dev/null);
    getpwnam('joebaz')     && system q(vrmuser -y joebaz 2>/dev/null);
    getpwnam('joeblech')   && system q(vrmuser -y joeblech 2>/dev/null);
    getpwnam('joesablech') && system q(vrmuser -y joesablech 2>/dev/null);

    getpwnam('joefoo1') && system q(vrmuser -y joefoo1 2>/dev/null);
    getpwnam('joefoo2') && system q(vrmuser -y joefoo2 2>/dev/null);
    getpwnam('joefoo3') && system q(vrmuser -y joefoo3 2>/dev/null);
    getpwnam('joebar1') && system q(vrmuser -y joebar1 2>/dev/null);
    getpwnam('joebar2') && system q(vrmuser -y joebar2 2>/dev/null);

    unlink $vsapd_config;
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
    rename("/www/conf/httpd.conf.$$", "/www/conf/httpd.conf")
      if -e "/www/conf/httpd.conf.$$";
    rename("/etc/mail/virtusertable.$$", "/etc/mail/virtusertable");
    my $wd = `pwd`; chomp $wd;
    chdir('/etc/mail');
    system('make', 'maps');
    chdir($wd);
    rename("/etc/mail/local-host-names.$$", "/etc/mail/local-host-names")
      if -e "/etc/mail/local-host-names.$$";

    unlink ("/www/logs/joefoo/foo-$$.com-access_log");
    unlink ("/www/logs/joefoo/foo-$$.com-access_log.1024.gz");
    unlink ("/www/logs/joefoo/foo-$$.com-access_log.1025.gz");
    unlink ("/www/logs/joefoo/foo-$$.com-access_log.1026.gz");
    unlink ("/www/logs/joefoo/foo-$$.com-access_log.1027.gz");
    `rm -rf /www/logs/joefoo`;

    system('perl', '-ni', '-e', "print unless /^## DELETE THIS: vsap::domain test begins here/..-1", 
	   "/www/conf/httpd.conf");
    system('apachectl graceful 2>&1 >/dev/null');
    rename "/etc/crontab.$$", '/etc/crontab'
	if -f "/etc/crontab.$$";
}
