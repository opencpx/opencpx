use Test::More tests => 33;
BEGIN { use_ok('VSAP::Server::Modules::vsap::user::prefs') };

#########################

use VSAP::Server::Test::Account;
use VSAP::Server::Modules::vsap::sys::timezone;

## set up a user
my $acctjoefoo = VSAP::Server::Test::Account->create( { username => 'joefoo', fullname => 'Joe Foo', password => 'joefoobar' });

ok( getpwnam('joefoo') );

my $t = $acctjoefoo->create_vsap(['vsap::user::prefs']);

$t = $t->client({ username     => 'joefoo', password     => 'joefoobar'});

ok(ref($t));

##
## test load empty
##

## should not be empty
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);

## these should be from the defaults
my $default_tz = VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), $default_tz );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/date_format'), '%m-%d-%Y');
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_format'), '%l:%M');
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/dt_order'), 'time');
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/logout'), 1 );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_startpath'), '' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_hidden_file_default'), 'hide' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/sa_packages_per_page'), '10' );

##
## test load happy
##

## give joe some webmail options
system('mkdir', '-p', "/home/joefoo/.cpx");
system('touch', "/home/joefoo/.cpx/user_preferences.xml");
system('chown', '-R', 'joefoo:joefoo', "/home/joefoo/.cpx");

open OPTIONS, ">>/home/joefoo/.cpx/user_preferences.xml"
  or die "Could not open user_preferences.xml: $!\n";
print OPTIONS <<'_OPTIONS_';
<user_preferences>
  <time_zone>MST7MDT</time_zone>
  <date_format>%m-%d-%Y</date_format>
  <logout>4</logout>
  <fm_startpath>/</fm_startpath>
  <fm_hidden_file_default>show</fm_hidden_file_default>
  <sa_packages_per_page>50</sa_packages_per_page>
</user_preferences>
_OPTIONS_
close OPTIONS;

$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'MST7MDT' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/date_format'), '%m-%d-%Y' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/logout'), '4' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_startpath'), '/' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_hidden_file_default'), 'show' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/sa_packages_per_page'), '50' );

## FIXME: test get_value (need to make a $vsap object)
#is( VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone'), 'MST7MDT', "get_value" );

##
## test fetch happy
##
undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:fetch'>
<logout/><date_format/></vsap>!);

is( $de->findvalue('/vsap/vsap[@type="user:prefs:fetch"]/user_preferences/logout'), '4' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:fetch"]/user_preferences/date_format'), '%m-%d-%Y' );
my @nodes = $de->findnodes('/vsap/vsap[@type="user:prefs:fetch"]/user_preferences/*');
is( @nodes, 2 );


##
## test save happy
##
undef $de;

$de = $t->xml_response(qq!<vsap type='user:prefs:save'>
<user_preferences>
  <time_zone>CDT6CST</time_zone>
</user_preferences>
</vsap>!);

undef $de;
## check to see that the new name was saved
$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'CDT6CST' );

##
## unlink the defaults and start again
##
unlink "/home/joefoo/.cpx/user_preferences.xml";

## should return hard-coded defaults
undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:load'/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/logout'), '1' );

ok( !-f "/home/joefoo/.cpx/user_preferences.xml" );

## save some new settings
undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:save'>
  <user_preferences>
    <time_zone>CET</time_zone>
    <logout>8</logout>
    <fm_hidden_file_default>show</fm_hidden_file_default>
  </user_preferences>
</vsap>!);

## should be a mix of our settings and defaults
undef $de;

$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'CET' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/logout'), '8' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/date_format'), '%m-%d-%Y' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_format'), '%l:%M' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_startpath'), '' );
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/fm_hidden_file_default'), 'show' );


## crashme
undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:save'>
  <user_preferences>
    <time_zone>CET#</time_zone>
  </user_preferences>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Error in value for time_zone) );

undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:save'>
  <user_preferences>
    <logout>d</logout>
  </user_preferences>
</vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Error in value for logout) );

## test time zone with '/' 
undef $de;
$de = $t->xml_response(qq!<vsap type='user:prefs:save'>
  <user_preferences>
    <time_zone>America/Nome</time_zone>
  </user_preferences>
</vsap>!);

## should be a mix of our settings and defaults
undef $de;

$de = $t->xml_response(qq!<vsap type="user:prefs:load"/>!);
is( $de->findvalue('/vsap/vsap[@type="user:prefs:load"]/user_preferences/time_zone'), 'America/Nome' );



END {
	$acctjoefoo->delete();
	ok( ! $acctjoefoo->exists(), 'User joefoo was deleted');
}
