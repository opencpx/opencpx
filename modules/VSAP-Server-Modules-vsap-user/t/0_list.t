# t/3_remove.t

use Test::More tests => 89;

use VSAP::Server::Test::Account 0.02;

#-----------------------------------------------------------------------------
#
# startup
#
    
BEGIN {
  use_ok('VSAP::Server::Modules::vsap::user');
};

#-----------------------------------------------------------------------------

my $vsapd_config = "_config.$$.vsapd";

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

use POSIX qw(uname);
my $is_linux = ((POSIX::uname())[0] =~ /Linux/ ? 1 : 0);

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefooson = VSAP::Server::Test::Account->create( { username => 'joefooson', fullname => "Joe Foos Son", password => 'joefoosonbar', shell => '/sbin/noshell' });
my $acctjoefoobar = VSAP::Server::Test::Account->create( { username => 'joefoobar', fullname => 'Joe Foos Bar', password => 'joefoobarbar' });
my $acctjoefoobaz = VSAP::Server::Test::Account->create( { username => 'joefoobaz', fullname => 'Joe Foos Baz', password => 'joefoobazbar' });
my $acctjoefooblech = VSAP::Server::Test::Account->create( { username => 'joefooblech', fullname => 'Joe Foos Blech', password => 'joefooblechbar' });

## Make joefoo an administrator.
$acctjoefoo->make_sa();

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
      if -e "/usr/local/etc/cpx.conf";

ok( getpwnam('joefoo') && getpwnam('joefooson') && getpwnam('joefoobar') && getpwnam('joefoobaz') && getpwnam('joefooblech'), "All users were created." );

my $vsap = $acctjoefoo->create_vsap(["vsap::auth", "vsap::logout", "vsap::user"]);
ok(ref($vsap));

my $t = $vsap->client( { username => 'joefoo', password => 'joefoobar'});

ok(ref($t));

my $de;

##
## list a bogus user
##
$de = $t->xml_response(qq!<vsap type="user:list"><user>blah</user></vsap>!);
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user'), "no bogus user" );


##
## test list
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>joefooson</user></vsap>!);


my $domain = `hostname`; chomp $domain;

is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/login_id'), 'joefooson', "check core data" ) or diag ($de->toString()) ;
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/fullname'), "Joe Foos Son", "check fullname" );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/comments'), "", "check comments" );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/usertype'), 'eu', "user type check");
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/domain'),    $domain, "check domain" );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/limit'),    50 , 'Check quota');

ok(   $de->find('/vsap/vsap[@type="user:list"]/user/capability/mail'),  "check mail capa" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/capability/ftp'),   "check ftp capa" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/capability/shell'), "check shell capa" );

ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/ftp'),     "check ftp service" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/mail'),    "check mail service" );

##
## test whether a user exists
##
# this test should find the user
$de = $t->xml_response(qq!<vsap type="user:exists"><login_id>joefooson</login_id></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:exists"]/exists'), 1, "user:exists found valid user" );
# this test should not find the user
$de = $t->xml_response(qq!<vsap type="user:exists"><login_id>cakkjkdfjkd</login_id></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:exists"]/exists'), 0, "user:exists successfully did not find valid user" );
## make a change
system('vquota joefooson 52 >/dev/null');
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>joefooson</user></vsap>!);

is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/login_id'), 'joefooson', 'Verify login' );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/fullname'), "Joe Foos Son", 'Verify Full Name' );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/comments'), "", 'Verify Comments' );
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/limit'), 52, "new quota" );
like( $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/usage'), qr(^[\d.]+$), "usage" );

##
## remove ftp service from user
##
if ($is_linux)
{
	$acctjoefooson->set_groups(['mailgrp','joefooson']);
} else {
	$acctjoefooson->set_groups(['pop','imap','joefooson']);
}

## list again
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>joefooson</user></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/capability/mail'),  "check mail capa" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/capability/ftp'),   "check ftp capa" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/ftp'),     "check ftp service" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/mail'),    "check mail service" );

unlink '/usr/local/etc/cpx.conf';

## list again
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>joefooson</user></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/capability/mail'),  "check mail capa" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/capability/ftp'),   "check ftp capa" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/ftp'),     "check ftp service" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/mail'),    "check mail service" );

## assign user to domains
my $co = new VSAP::Server::Modules::vsap::config( username => 'joefoobar');
$co->domain('bar.com');
$co->init(username => 'joefoobaz');
$co->domain('bar.com');
$co->init(username => 'joefooblech');
$co->domain('bar.com');
$co->commit;

## Rated PG-13 for intense scenes of reaching deep into an
## undocumented object and horking it. Don't do this in production,
## please.
my $node = $co->{dom}->createElement('domain');
$node->appendTextChild(name => 'bar.com');
$node->appendTextChild(admin => 'joefooson');
my ($dnode) = $co->{dom}->findnodes('/config/domains');
$dnode->appendChild($node);
$co->{is_dirty} = 1;
undef $co;

## list all users for a domain
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><domain>bar.com</domain></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobar"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobaz"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooblech"]') );
my @users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 4, "count users for domain" );

## brief listing
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><brief/><domain>bar.com</domain></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]'), 'Got user joefooson' );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobar"]'), 'Got user joefoobar' );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobaz"]'), 'Got user joefoobaz' );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooblech"]'), 'Got user joefooblech' );
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 4, "count users for domain (brief)" );


## list all users for a domain admin
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><admin>joefooson</admin></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobar"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobaz"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooblech"]') );
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 4, "count users for domain" );

## list all users for a domain admin, without admin arg, logged in as a domain admin
$t->quit; 
undef $t;

$t = $vsap->client({ username => 'joefooson', password => 'joefoosonbar'});

$co = new VSAP::Server::Modules::vsap::config( username => 'joefoobar');
$node = $co->{dom}->createElement('domain_admin');
($dnode) = $co->{dom}->findnodes('/config/users/user[@name="joefooson"]');
$dnode->appendChild($node);
$co->{is_dirty} = 1;
undef $co;

undef $de;
$de = $t->xml_response(q!<vsap type="user:list"/>!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]'), 'Got user joefooson' );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobar"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobaz"]') );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooblech"]') );
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 4, "count users for da list all" );


##
## list all users (via non-server admin)
##
ok($acctjoefoo->exists, 'User joefoo exists');
$acctjoefoo->delete();
ok( ! $acctjoefoo->exists, 'User joefoo has been removed');
my $acctjoefoo1 = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });

## remove the domain_admin setting for joefoo
## NOTE: illegal! If the config.pm API changes, it's our own fault if
## NOTE: this breaks. Internal parts are not covered by our external
## NOTE: API warranty.
$co = new VSAP::Server::Modules::vsap::config( username => 'joefoobar');
$co->init( username => 'joefoo' );
while( ($node) = $co->{dom}->findnodes('/config/users/user[@name="joefoo"]') ) {
    $node->parentNode->removeChild( $node );
}
$co->{is_dirty} = 1;
undef $co;

undef $t;
$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

undef $de;
$de = $t->xml_response(q!<vsap type="user:list"/>!);
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 1, "only self user for non-admin" );
is( $de->findvalue('/vsap/vsap/user/login_id'), 'joefoo' );
#print STDERR $de->toString(1);

## make joefoo a server admin
$acctjoefoo1->make_sa();
undef $t;

$t = $vsap->client({ username => 'joefoo', password => 'joefoobar'});

undef $de;
$de = $t->xml_response(q!<vsap type="user:list"/>!);
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
ok( scalar @users >= 5, "all users for admin" );
my $count_users = scalar @users;

##
## <brief> tests
##

## remove some services, etc
for my $user qw( joefooson joefoobaz ) {
    my @groups = grep { $_ !~ /^(?:$user|ftp)$/ } split(' ', `id -Gn $user`);
	if ($user eq 'joefooson')
	{
		$acctjoefooson->set_groups(\@groups);
	} else {
		$acctjoefoobaz->set_groups(\@groups);
	}
}

## fast listing
undef $de;
$de = $t->xml_response(q!<vsap type="user:list"><brief/></vsap>!);
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
ok( scalar @users == $count_users, "all users for admin (brief)" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user[login_id="nobody"]'), "nobody ain't home" );
## FIXME: just removed 'nobody' line in the .pm, now test to see if 'nobody' is in the user list
## FIXME: then undo the fix to config.pm where the high uids are filtered, and see if 'nobody' comes back

## check for service nodes
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoo"]/services/ftp'), "ftp user" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]/services/ftp'), "ftp user" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobar"]/services/ftp'), "ftp user" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefoobaz"]/services/ftp'), "ftp user" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user[login_id="joefooblech"]/services/ftp'), "ftp user" );

## domains
undef $de;
## The value assigned to admin assumes an admin in cpx is 
## the first part of the domain name - if this is not the case, assign
## the value of of your server admin to $admin (otherwise an error will result)
## For example - 'joe' is the server admin on the server from which these
## tests are being run  (note that it is commented out)
my $admin = `sinfo | egrep -i '^account'`; chomp $admin; $admin =~ s/^account:\s*(.*)/$1/i;
#$admin = 'joe';
my $webGroup ;
if ($is_linux)
{
	$webGroup = "apache";
} else {
	$webGroup = "www";
}
my $hostname = `hostname`; chomp $hostname;
# $de = $t->xml_response(qq!<vsap type="user:list"><user>www</user></vsap>!);
$de = $t->xml_response(qq!<vsap type="user:list"><user>$webGroup</user></vsap>!);
is( $de->findvalue(qq!/vsap/vsap[\@type="user:list"]/user/domains/domain[name="$hostname"]/admin!), $webGroup, "hostname/admin check" );

is( $de->findvalue(qq!/vsap/vsap[\@type="user:list"]/user/usertype!), 'da', "www domain admin check" );

## admin quotas
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><user>$admin</user></vsap>!);
# eh... don't do this... 
#ok( $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/limit') > 1200 &&
#    $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/limit') < 6000, "server admin disk quota" ) || diag $de->toString(1);
# just check if greater than zero.  --rus.
ok( $de->findvalue('/vsap/vsap[@type="user:list"]/user/quota/limit') > 0, "server admin disk quota" ) || diag $de->toString(1);

##
## list_da as admin
##
undef $de;
$de = $t->xml_response(q!<vsap type="user:list_da"/>!);
my %admins = map { $_->findvalue('.') => 1 } $de->findnodes('/vsap/vsap[@type="user:list_da"]/admin');
ok( $admins{$admin}, 'Checking that account owner is listed' );
ok( $admins{$webGroup}, "Verifying that $webGroup is an admin" );
ok( scalar(keys %admins) >= 3, "Should be at least 3 admins" );


##
## list_da_eligible
##
undef $de;
$de = $t->xml_response(q!<vsap type="user:list_da_eligible"/>!);
#print STDERR $de->toString(1);
%admins = map { $_->findvalue('.') => 1 } $de->findnodes('/vsap/vsap[@type="user:list_da_eligible"]/admin');
ok( scalar(keys %admins) >= 3, "admins" );

##
## login as an unprivileged user
##
$t->quit;
undef $t;
$t = $vsap->client( { username     => 'joefoobaz', password     => 'joefoobazbar'});

undef $de;
$de = $t->xml_response(q!<vsap type="user:list"/>!);
@users = $de->findnodes('/vsap/vsap[@type="user:list"]/user');
is( scalar @users => 1, "self user for non-privileged user" );
is( $de->findvalue('/vsap/vsap/user/login_id'), 'joefoobaz' );
#print STDERR $de->toString(1);

##
## list_da as unauthorized user
##
undef $de;
$de = $t->xml_response(q!<vsap type="user:list_da"/>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Permission denied)i );

##
## list:eu
##
$t = $vsap->client( { username => 'joefooson', password => 'joefoosonbar'});
ok(ref($t));
undef $de;
$de = $t->xml_response(q!<vsap type="user:list:eu"/>!);
ok(   $de->find('/vsap/vsap[@type="user:list:eu"][user="joefooson"]') );
ok(   $de->find('/vsap/vsap[@type="user:list:eu"][user="joefoobar"]') );
ok(   $de->find('/vsap/vsap[@type="user:list:eu"][user="joefoobaz"]') );
ok(   $de->find('/vsap/vsap[@type="user:list:eu"][user="joefooblech"]') );
@users = $de->findnodes('/vsap/vsap[@type="user:list:eu"]/user');
is(scalar @users => 4, "count endusers for domain admin");

##
## list:system
##
$t = $vsap->client( { username => 'joefoo', password => 'joefoobar'});
ok(ref($t));
undef $de;
$de = $t->xml_response(q!<vsap type="user:list:system"/>!);
ok(   $de->find('/vsap/vsap[@type="user:list:system"][user="root"]') );
ok(   $de->find('/vsap/vsap[@type="user:list:system"][user="joefoo"]') );
undef $de;
$de = $t->xml_response(q!<vsap type="user:list:system"><system_only/></vsap>!);
ok(   $de->find('/vsap/vsap[@type="user:list:system"][user="root"]') );
ok(   !$de->find('/vsap/vsap[@type="user:list:system"][user="joefoo"]') );


END {
	$acctjoefoo->delete();
    ok( ! $acctjoefoo->exists, 'User joefoo has been removed');
	$acctjoefooson->delete();
    ok( ! $acctjoefooson->exists, 'User joefooson has been removed');
	$acctjoefoobar->delete();
    ok( ! $acctjoefoobar->exists, 'User joefoobar has been removed');
	$acctjoefoobaz->delete();
    ok( ! $acctjoefoobaz->exists, 'User joefoobaz has been removed');
	$acctjoefooblech->delete();
    ok( ! $acctjoefooblech->exists, 'User joefooblech has been removed');
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf");
}
