use Test;
BEGIN { $|=1; plan(tests => 58, todo => [38]); chdir 't' if -d 't'; }
use blib;
use ExtUtils::testlib;

use VSAP::Server::G11N::Date;
my $d;

$ENV{'TZ'} = 'GMT';

## test original date
ok( $d = new VSAP::Server::G11N::Date( epoch => '1015631263' ) );
ok( $d->original->year, 2002 );
ok( $d->original->month, 3 );
ok( $d->original->day, 8 );
ok( $d->original->hour, 23 );
ok( $d->original->hour_12, 11 );
ok( $d->original->minute, 47 );
ok( $d->original->second, 43 );
ok( $d->original->offset, '+0000' );
ok( $d->original->tz, 'GMT' );
ok( $d->original->pm );

## test original date
ok( $d = new VSAP::Server::G11N::Date( date => 'Fri Mar  8 16:47:42 MST 2002' ) );
ok( $d->original->year, 2002 );
ok( $d->original->month, 3 );
ok( $d->original->day, 8 );
ok( $d->original->hour, 16 );
ok( $d->original->hour_12, 4 );
ok( $d->original->minute, 47 );
ok( $d->original->second, 42 );
ok( $d->original->offset, '-0700' );
ok( $d->original->gmt_offset, '-25200' );
ok( $d->original->tz, 'MST' );
ok( $d->original->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Sun, 06 Nov 1994 06:49:37 UTC' ) );
ok( $d->original->date, '06 Nov 1994 06:49:37 UTC');
ok( !$d->original->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date' => '05 Nov 1994 23:49:37 -0700' ) );
ok( $d->original->date, '05 Nov 1994 23:49:37 MST');
ok( $d->original->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date' => '30 Nov 2001 02:52:51 GMT' ) );
ok( $d->original->date, '30 Nov 2001 02:52:51 GMT');
ok( !$d->original->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date' => '30 Nov 2001 02:52:51 +0000' ) );
ok( $d->original->date, '30 Nov 2001 02:52:51 GMT');

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)' ) );
ok( $d->original->date, '07 Mar 2002 08:12:00 MST' );

## TODO: 38
## fails because IST is not in Time::Zone reverse mapping
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 16 Mar 2002 02:52:33 +0530' ) );
ok( $d->original->date, '16 Mar 2002 02:52:33 IST' );

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Wed, 13 Feb 2002 10:53:14 MST' ) );
ok( $d->original->date, '13 Feb 2002 10:53:14 MST' );
ok( $d->original->gmt_offset, ( (localtime)[8] ? '-21600' : '-25200' ) );

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Wed, 13 Feb 2002 10:53:14 -0700' ) );
ok( $d->original->date, '13 Feb 2002 10:53:14 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );
ok( $d->original->tz, ( (localtime)[8] ? 'MDT' : 'MST' ) );

ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
				'offset' => '+0900' ) );
ok( $d->original->date, '07 Mar 2002 08:12:00 ' . ( (localtime)[8] ? 'MDT' : 'MST' ) );

## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->original->date, '14 Feb 2002 13:11:48 ZP4' );
ok( $d->original->pm );

## override environment
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400',
	                        'tz'   => 'EET', ) );
ok( $d->original->date, '14 Feb 2002 13:11:48 ZP4' );
ok( $d->original->pm );

## backto HST
ok($d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok($d->original->date, '14 Feb 2002 13:11:48 ZP4' );

## another tz
$ENV{TZ} = 'CET';  ## central Europe
ok($d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok($d->original->date, '14 Feb 2002 13:11:48 ZP4' );

## epoch tests
$ENV{TZ} = 'MST';  ## mountain standard
ok($d = new VSAP::Server::G11N::Date( 'epoch' => 1015455692 ) );
ok($d->original->date, '06 Mar 2002 23:01:32 GMT');
