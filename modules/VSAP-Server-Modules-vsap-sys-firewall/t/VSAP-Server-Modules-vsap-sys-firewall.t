use Test::More tests => 45;
use strict;

## $SMEId: vps2/user/local/cpx/modules/VSAP-Server-Modules-vsap-sys-firewall/t/VSAP-Server-Modules-vsap-sys-firewall.t,v 1.1 2006/12/13 16:48:06 kwhyte Exp $

BEGIN { use_ok( 'VSAP::Server::Modules::vsap::sys::firewall' ) };
BEGIN { use_ok( 'VSAP::Server::Test' ); };
BEGIN { use_ok( 'VSAP::Server::Test::Account' ); };

use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

##################################################
## initialization

my $acct;     # vsap account owner test object
my $eu;       # vsap end user test account
my $vsap;     # vsap test object
my $client;   # vsap test client object
my $euclient; # vsap end user test client object
my $resp;     # vsap response
my $node;     # vsap responce node

ok( $acct = VSAP::Server::Test::Account->create({type => 'account-owner'}), "create account owner test account" );
ok( $acct->exists, "account-owner test account exists" );
ok( $vsap = $acct->create_vsap(['vsap::sys::firewall']),"started vsapd" );
ok( $client = $vsap->client({acct => $acct}), "obtained vsap client" );

ok( $eu = VSAP::Server::Test::Account->create({ type => 'end-user', username => 'joeenduser' }), "create end user test account" );
ok( $eu->exists,"end-user account exists" );
ok( $euclient = $vsap->client({acct => $eu}), "obtained end user vsap client" );


## ----------------------------------------------------------------------
## test sys:firewall:set - set level 0, firewall off
## ----------------------------------------------------------------------

SKIP: {
    skip "set level 0, firewall off", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>0</level>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "0", "set level 0, firewall off" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get level 0, firewall off
## ----------------------------------------------------------------------

SKIP: {
    skip "get level 0, firewall off", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "0", "get level 0, firewall off" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - set level 1, firewall low
## ----------------------------------------------------------------------

SKIP: {
    skip "set level 1, firewall low", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>1</level>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "1", "set level 1, firewall low" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get level 1, firewall low
## ----------------------------------------------------------------------

SKIP: {
    skip "get level 1, firewall low", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "1", "get level 1, firewall low" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - set level 2, firewall medium
## ----------------------------------------------------------------------

SKIP: {
    skip "set level 2, firewall medium", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>2</level>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "2", "set level 2, firewall medium" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get level 2, firewall medium
## ----------------------------------------------------------------------

SKIP: {
    skip "get level 2, firewall medium", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "2", "get level 2, firewall medium" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - set level 3, firewall high
## ----------------------------------------------------------------------

SKIP: {
    skip "set level 3, firewall high", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>3</level>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "3", "set level 3, firewall high" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get level 3, firewall high
## ----------------------------------------------------------------------

SKIP: {
    skip "get level 3, firewall high", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "3", "get level 3, firewall high" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - set type m, mail server
## ----------------------------------------------------------------------

SKIP: {
    skip "set type m, mail server", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>1</level>
      <type>m</type>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "1", "set level 1, firewall low" );
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/type'), "m", "set type m, mail server" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get type m, mail server
## ----------------------------------------------------------------------

SKIP: {
    skip "get type m, mail server", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "1", "get level 1, firewall low" );
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/type'), "m", "get type m, mail server" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - set type w, web server
## ----------------------------------------------------------------------

SKIP: {
    skip "set type w, web server", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>1</level>
      <type>w</type>
    </vsap>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/level'), "1", "set level 1, firewall low" );
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:set"]/type'), "w", "set type w, web server" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - get type w, web server
## ----------------------------------------------------------------------

SKIP: {
    skip "get type w, web server", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/level'), "1", "get level 1, firewall low" );
    is( $resp->findvalue('/vsap/vsap[@type="sys:firewall:get"]/type'), "w", "get type w, web server" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - exception, ERR_NOTSUPPORTED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTSUPPORTED", 2
        if( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:get"/>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:get"]/code'), 101, "error code 101 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:get"]/message'), "Not supported on this platform", "Not supported on this platform" );
}

## ----------------------------------------------------------------------
## test sys:firewall:get - exception, ERR_NOTAUTHORIZED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTAUTHORIZED", 2
        unless( $is_linux );

    undef $resp;
    $resp = $euclient->xml_response(qq!<vsap type="sys:firewall:get"/>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:get"]/code'), 100, "error code 100 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:get"]/message'), "Not authorized to set firewall", "Not authorized to set firewall" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - exception, ERR_NOTSUPPORTED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTSUPPORTED", 2
        if( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>0</level>
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/code'), 101, "error code 101 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/message'), "Not supported on this platform", "Not supported on this platform" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - exception, ERR_NOTAUTHORIZED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTAUTHORIZED", 2
        unless( $is_linux );

    undef $resp;
    $resp = $euclient->xml_response(qq!<vsap type="sys:firewall:set">
      <level>0</level>
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/code'), 100, "error code 100 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/message'), "Not authorized to set firewall", "Not authorized to set firewall" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - exception, ERR_MISSING_FIELD
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_MISSING_FIELD", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/code'), 102, "error code 102 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/message'), "Empty or missing level", "Empty or missing level" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - exception, ERR_INVALID_FIELD
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_INVALID_FIELD", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>4</level>
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/code'), 103, "error code 103 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/message'), "Invalid value for level", "Invalid value for level" );
}

## ----------------------------------------------------------------------
## test sys:firewall:set - exception, ERR_INVALID_FIELD
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_INVALID_FIELD", 2
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:set">
      <level>0</level>
      <type>z</type>
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/code'), 103, "error code 103 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:set"]/message'), "Invalid value for type", "Invalid value for type" );
}

## ----------------------------------------------------------------------
## test sys:firewall:reset - reset
## ----------------------------------------------------------------------

SKIP: {
    skip "reset firewall", 1
        unless( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:reset">
    </vsap>!);
    ok( ! $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:reset"]/code'), "reset firewall" );
}

## ----------------------------------------------------------------------
## test sys:firewall:reset - exception, ERR_NOTSUPPORTED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTSUPPORTED", 2
        if( $is_linux );

    undef $resp;
    $resp = $client->xml_response(qq!<vsap type="sys:firewall:reset">
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:reset"]/code'), 101, "error code 101 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:reset"]/message'), "Not supported on this platform", "Not supported on this platform" );
}

## ----------------------------------------------------------------------
## test sys:firewall:reset - exception, ERR_NOTAUTHORIZED
## ----------------------------------------------------------------------

SKIP: {
    skip "exception, ERR_NOTAUTHORIZED", 2
        unless( $is_linux );

    undef $resp;
    $resp = $euclient->xml_response(qq!<vsap type="sys:firewall:reset">
    </vsap>!);

    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:reset"]/code'), 100, "error code 100 as expected" );
    is( $resp->findvalue('/vsap/vsap[@type="error"][@caller="sys:firewall:reset"]/message'), "Not authorized to reset firewall", "Not authorized to reset firewall" );
}


END { }

