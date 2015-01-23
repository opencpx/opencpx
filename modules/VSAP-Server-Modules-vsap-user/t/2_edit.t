# t/2_edit.t

use Test::More tests => 39;

use VSAP::Server::Test::Account 0.02;

#-----------------------------------------------------------------------------
#
# startup
#

BEGIN { 
  use_ok('VSAP::Server::Modules::vsap::user');
  use_ok('VSAP::Server::Modules::vsap::config');
};

#-----------------------------------------------------------------------------

my $vsapd_config = "_config.$$.vsapd";

## make sure our user doesn't exist
if( getpwnam('joefoo') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });
my $acctjoefooson = VSAP::Server::Test::Account->create( { username => 'joefooson', fullname => 'Joe Foos Son', ftp => 'n', mail => 'n', webmail => 'n', spamassassin => 'n', clamav => 'n', fileman => 'n', password => 'joefoosonbar' });

rename("/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$$")
      if -e "/usr/local/etc/cpx.conf";

ok( getpwnam('joefoo') );
ok( getpwnam('joefooson') );

my $vsap = $acctjoefoo->create_vsap(["vsap::auth", "vsap::user"]);
my $t = $vsap->client({ username => 'joefoo', password =>'joefoobar'});
ok(ref($t));

## test joefoo has permissions to edit joefooson
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <fullname>Joseph Fooson</fullname>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"]/message'), "Not authorized" );

## try again
$acctjoefoo->make_sa(); ## make us an administrator
$t->quit;
undef $t;
$t = $vsap->client({ username => 'joefoo', password =>'joefoobar'});
##
## test fullname
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <fullname>Joseph Fooson</fullname>
</vsap>
!);

isnt( (getpwnam('joefooson'))[6], "Joseph Fooson", "gecos unchanged" );
my @qData = split(/\s+/, (split(/\n/,`vquota joefooson`))[2]);
is( $qData[3], 51200, "check quota" );

undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/fullname'), "Joseph Fooson", "verify fullname" );

## change gecos
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <fullname>Joseph Fooson</fullname>
  <change_gecos/>
</vsap>
!);
is( (getpwnam('joefooson'))[6], "Joseph Fooson", "gecos changed" );

##
## test comments
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <fullname>Joseph Fooson</fullname>
  <comments>The quick brown fox jumped over the lazy dog.</comments>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'edit user comments' );

undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/comments'), "The quick brown fox jumped over the lazy dog.", "verify comments" );

##
## test quota
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <quota>10</quota>
</vsap>
!);
@qData = split(/\s+/, (split(/\n/,`vquota joefooson`))[2]);
is( $qData[3], 10240, "check new quota" );

##
## stress quota
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <quota>100000</quota>
</vsap>
!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Quota value out of bounds), "stress quota" ) || diag($de->toString(1));

##
## test services
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/mail'), "ain't gots mail" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/ftp'), "ain't gots ftp" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/webmail'), "ain't gots webmail" );

## set services
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <services>
    <mail>1</mail>
    <ftp>0</ftp>
    <bogus>1</bogus>
    <webmail>1</webmail>
  </services>
</vsap>
!);

## list
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/mail'), "gots mail" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/ftp'), "ain't gots ftp" );
ok(   $de->find('/vsap/vsap[@type="user:list"]/user/services/webmail'), "gots webmail" );
ok( ! $de->find('/vsap/vsap[@type="user:list"]/user/services/bogus'), "ain't gots bogus" );

##
## disable
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <status>disable</status>
</vsap>
!);

undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/status'), 'disabled', "status disabled" );

##
## enable
##
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <status>enable</status>
</vsap>
!);

undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
</vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/status'), 'enabled', "status enabled" );

## make a domain admin
## Rated PG-13 for intense scenes of reaching deep into an
## undocumented object and horking it. Don't do this in production, please.
my $co = new VSAP::Server::Modules::vsap::config( username => 'joefoo' );
my $node = $co->{dom}->createElement('domain');
$node->appendTextChild(name => 'bar.com');
$node->appendTextChild(admin => 'joefoo');
my ($dnode) = $co->{dom}->findnodes('/config/domains');
$dnode->appendChild($node);
$co->{is_dirty} = 1;
$co->init( username => 'joefooson' );
$co->domain('bar.com');  ## make us part of bar.com
undef $co;  ## implicit commit

undef $de;
$de = $t->xml_response(qq!<vsap type="user:list"><admin>joefoo</admin></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user[login_id="joefooson"]/login_id'), 'joefooson' );

##
## editing user domain name
##
# should fail for da
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefoo</user>
  <da>
    <domain>invalid.com</domain>
  </da>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:edit"]/code'), 105, 'da unable to edit domain' );

#
# should fail for eu with invalid domain name
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <eu>
    <domain>invalid.com</domain>
  </eu>
  </vsap>
!);
##print $de->toString(1);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:edit"]/code'), 222, 'eu unable to change to invalid domain' );

#
# should work for eu with valid domain name
#
chomp(my $host = `hostname`);
undef $de;
$de = $t->xml_response(qq!<vsap type="user:edit">
  <user>joefooson</user>
  <eu>
    <domain>$host</domain>
  </eu>
  </vsap>
!);
#print $de->toString(1);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'eu able to change to valid domain' );

#
# make sure domain name changed
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:list"]/user/domain'), $host, 'eu domain name matches new modified domain' );

#
#  test removing/adding webmail service/capabilities  (and set back to original domain)
#

# remove webmail service
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <webmail>0</webmail>
    </services>
    <capabilities>
      <webmail>0</webmail>
    </capabilities>
    <eu>
      <domain>bar.com</domain>
    </eu>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'remove webmail service and capability via user:edit' );

#
# make sure webmail gone as service and capability
#
undef $de;
$de = $t->xml_response(qq!<vsap type="user:list">
  <user>joefooson</user>
  </vsap>
!);
ok(!($de->find('/vsap/vsap[@type="user:list"]/user/services/webmail')), 
   "webmail service removed" );
ok(!($de->find('/vsap/vsap[@type="user:list"]/user/capability/webmail')), 
   "webmail capability removed" );

# remove mail service to prepare for test of adding webmail back in
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <mail>0</mail>
    </services>
    <capabilities>
      <mail>0</mail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'remove mail service and capability via user:edit' );

# add webmail service (should fail)
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <webmail>1</webmail>
    </services>
    <capabilities>
      <webmail>1</webmail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="error"][@caller="user:edit"]/code'), 223, 'cannot add webmail without mail active' );

# add mail and webmail service (should succeed)
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <mail>1</mail>
      <webmail>1</webmail>
    </services>
    <capabilities>
      <mail>1</mail>
      <webmail>1</webmail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'able to add webmail service with mail added' );

# remove webmail and mail services/capabilities, then add one at a time
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <mail>0</mail>
      <webmail>0</webmail>
    </services>
    <capabilities>
      <mail>0</mail>
      <webmail>0</webmail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 'able to remove webmail and mail services/capabilities' );

# add mail services/capabilities back in 
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <mail>1</mail>
    </services>
    <capabilities>
      <mail>1</mail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 're-adding mail service/capability' );

# add webmail mail services/capabilities back in 
undef $de;
$de = $t->xml_response(qq!
  <vsap type="user:edit">
    <user>joefooson</user>
    <services>
      <webmail>1</webmail>
    </services>
    <capabilities>
      <webmail>1</webmail>
    </capabilities>
  </vsap>
!);
is( $de->findvalue('/vsap/vsap[@type="user:edit"]/status'), 'ok', 're-adding webmail service/capability' );

## FIXME: disable joefoo, make sure joefooson gets disabled too

END {
	$acctjoefoo->delete();
	ok(! $acctjoefoo->exists, 'User joefoo was deleted');
	$acctjoefooson->delete();
	ok(! $acctjoefooson->exists, 'User joefooson was deleted');

    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$$", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$$";
}
