use Test;
BEGIN { $|=1; plan(tests => 74); chdir 't' if -d 't'; }

use blib;

use VSAP::Server::Util qw();
ok(1);

##################################################
## xmlescape tests
##################################################
my $str  = 'joe & bob';
my $nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, 'joe &amp; bob' );

## test to make sure the original string is untouched
ok( $str ne $nstr );

$str  = '10 < 100<';
$nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, '10 &lt; 100&lt;' );

$str  = '100 > 10>';
$nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, '100 &gt; 10&gt;' );

$str  = "new\rline\r";
$nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, 'new&#013;line&#013;' );

$str  = "new\nline\n";
$nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, 'new&#010;line&#010;' );

$str  = "null\x00bytes\x00";
$nstr = VSAP::Server::Util::xml_escape($str);
ok( $nstr, 'nullbytes');

##################################################
## gmt2local tests
##################################################

my $d;

## try a GMT date
$ENV{TZ} = 'MST7MDT';
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Sun, 06 Nov 1994 06:49:37 UTC'} ) );
ok($d->{'gmt'}, '06 Nov 1994 06:49:37 GMT');
ok($d->{'local'}, '05 Nov 1994 23:49:37 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok($d->{'orig'}, '06 Nov 1994 06:49:37 UTC');

## try another format
ok($d = VSAP::Server::Util::gmt2local( {'date' => '2001-11-30 02:52:51 +0000'} ) );
ok($d->{'gmt'}, '30 Nov 2001 02:52:51 GMT');
ok($d->{'local'}, '29 Nov 2001 19:52:51 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok($d->{'orig'}, '30 Nov 2001 02:52:51 +0000');

## try some other incoming tz
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Wed, 13 Feb 2002 10:53:14 -0700'} ) );
ok($d->{'gmt'}, '13 Feb 2002 17:53:14 GMT');
ok($d->{'local'}, '13 Feb 2002 10:53:14 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok($d->{'orig'}, '13 Feb 2002 10:53:14 -0700' );

## some elements
ok( $d->{'off'},  ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok( $d->{'12hour'}, 10 );
ok( $d->{'g12hour'}, 5 );
ok( $d->{'min'}, 53 );
ok( $d->{'gmon'}, 2 );
ok( $d->{'ohour'}, 10 );
ok( $d->{'wday'}, 3 );

## try some other incoming tz
$ENV{TZ} = 'PST8PDT';
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Fri, 08 Mar 2002 13:32:43 -0700'} ) );
ok($d->{'gmt'}, '08 Mar 2002 20:32:43 GMT');
ok($d->{'local'}, '08 Mar 2002 12:32:43 ' . ( (localtime)[8] ? 'PDT' : 'PST' ) );
ok($d->{'orig'}, '08 Mar 2002 13:32:43 -0700' );

## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Thu, 14 Feb 2002 13:11:48 +0400'} ) );
ok($d->{'gmt'}, '14 Feb 2002 09:11:48 GMT');
ok($d->{'local'}, '13 Feb 2002 23:11:48 HST');
ok($d->{'orig'}, '14 Feb 2002 13:11:48 +0400' );

## override environment
ok($d = VSAP::Server::Util::gmt2local({
				       'date' => 'Thu, 14 Feb 2002 13:11:48 +0400',
				       'zone'  => 'EET',
				      } ) );
ok($d->{'gmt'}, '14 Feb 2002 09:11:48 GMT');
ok($d->{'local'}, '14 Feb 2002 11:11:48 EET');
ok($d->{'orig'}, '14 Feb 2002 13:11:48 +0400' );

## backto HST
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Thu, 14 Feb 2002 13:11:48 +0400'} ) );
ok($d->{'gmt'}, '14 Feb 2002 09:11:48 GMT');
ok($d->{'local'}, '13 Feb 2002 23:11:48 HST');
ok($d->{'orig'}, '14 Feb 2002 13:11:48 +0400' );

## another tz
$ENV{TZ} = 'CET';  ## central Europe
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Thu, 14 Feb 2002 13:11:48 +0400'} ) );
ok($d->{'gmt'}, '14 Feb 2002 09:11:48 GMT');
ok($d->{'local'}, '14 Feb 2002 10:11:48 CET');
ok($d->{'orig'}, '14 Feb 2002 13:11:48 +0400' );

## epoch tests
$ENV{TZ} = 'MST';  ## mountain standard
ok($d = VSAP::Server::Util::gmt2local( {'epoch' => 1015455692} ) );
ok($d->{'gmt'}, '06 Mar 2002 23:01:32 GMT');
ok($d->{'local'}, '06 Mar 2002 16:01:32 MST');
ok($d->{'orig'}, '06 Mar 2002 23:01:32 GMT');

########################################
## DST tests
########################################

## compare two zones DST settings
$ENV{TZ} = 'PST8PDT';
ok($d = VSAP::Server::Util::gmt2local('Thu, 18 Apr 2002 13:11:48 JST'));
ok($d->{'gmt'}, '18 Apr 2002 04:11:48 GMT');
ok($d->{'local'}, '17 Apr 2002 21:11:48 ' . ( (localtime)[8] ? 'PDT' : 'PST' ) );
ok($d->{'orig'}, '18 Apr 2002 13:11:48 JST');
ok(!$d->{'odst'});  ## no dst
ok($d->{'dst'});    ## yes dst

## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Thu, 18 Apr 2002 13:11:48 +0400'} ) );
ok($d->{'gmt'}, '18 Apr 2002 09:11:48 GMT');
ok($d->{'local'}, '17 Apr 2002 23:11:48 HST');
ok($d->{'orig'}, '18 Apr 2002 13:11:48 +0400' );

## another tz
$ENV{TZ} = 'CET';  ## central Europe DST starts on Sunday March 31, 2002 at 2:00:00 AM
ok($d = VSAP::Server::Util::gmt2local( {'date' => 'Thu, 18 Apr 2002 13:11:48 +0400'} ) );
ok($d->{'gmt'}, '18 Apr 2002 09:11:48 GMT');
ok($d->{'local'}, '18 Apr 2002 11:11:48 CET');
ok($d->{'orig'}, '18 Apr 2002 13:11:48 +0400' );

## epoch tests
$ENV{TZ} = 'MST7MDT';  ## mountain standard; DST starts on Sunday April 7, 2002 at 2:00:00 AM
ok($d = VSAP::Server::Util::gmt2local( {'epoch' => 1019702907} ) );
ok($d->{'gmt'}, '25 Apr 2002 02:48:27 GMT');
ok($d->{'local'}, '24 Apr 2002 20:48:27 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok($d->{'orig'}, '25 Apr 2002 02:48:27 GMT');

## override environment
ok($d = VSAP::Server::Util::gmt2local({
				       'date' => 'Thu, 18 Apr 2002 13:11:48 +0400',
				       'zone' => 'EET',
				      } ) );
ok($d->{'gmt'}, '18 Apr 2002 09:11:48 GMT');
ok($d->{'local'}, '18 Apr 2002 12:11:48 EET');
ok($d->{'orig'}, '18 Apr 2002 13:11:48 +0400' );
ok($d->{'dst'});

exit;
