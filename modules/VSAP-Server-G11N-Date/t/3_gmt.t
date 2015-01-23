use Test;
BEGIN { $|=1; plan(tests => 44); chdir 't' if -d 't'; }
use blib;
use ExtUtils::testlib;

use VSAP::Server::G11N::Date;
my $d;

## test GMT date
ok( $d = new VSAP::Server::G11N::Date( epoch => '1015631263' ) );
ok( $d->gmt->year, 2002 );
ok( $d->gmt->month, 3 );
ok( $d->gmt->day, 8 );
ok( $d->gmt->hour, 23 );
ok( $d->gmt->hour_12, 11 );
ok( $d->gmt->minute, 47 );
ok( $d->gmt->second, 43 );
ok( $d->gmt->offset, '+0000' );
ok( $d->gmt->tz, 'GMT' );
ok( $d->gmt->pm );

## test GMT date
ok( $d = new VSAP::Server::G11N::Date( date => 'Fri Mar  8 16:47:42 MST 2002' ) );
ok( $d->gmt->year, 2002 );
ok( $d->gmt->month, 3 );
ok( $d->gmt->day, 8 );
ok( $d->gmt->hour, 23 );
ok( $d->gmt->hour_12, 11 );
ok( $d->gmt->minute, 47 );
ok( $d->gmt->second, 42 );
ok( $d->gmt->offset, '+0000' );
ok( $d->gmt->tz, 'GMT' );
ok( $d->gmt->pm );

$ENV{TZ} = 'MST7MDT';
ok( $d = new VSAP::Server::G11N::Date( 'Sun, 06 Nov 1994 06:49:37 UTC' ) );
ok( $d->gmt->date, '06 Nov 1994 06:49:37 GMT' );
ok( !$d->gmt->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)' ) );
ok( $d->gmt->date, '07 Mar 2002 15:12:00 GMT' );

## try another format
ok( $d = new VSAP::Server::G11N::Date( 'date' => '2001-11-30 02:52:51 +0000' ) );
ok( $d->gmt->date, '30 Nov 2001 02:52:51 GMT' );

## try some other incoming tz
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Wed, 13 Feb 2002 10:53:14 -0700' ) );
ok( $d->gmt->date, '13 Feb 2002 17:53:14 GMT' );
ok( $d->gmt->pm );

ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
				'offset' => '+0900' ) );
ok( $d->gmt->date, '07 Mar 2002 15:12:00 GMT' );


## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->gmt->date, '14 Feb 2002 09:11:48 GMT' );

## override environment
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400',
			 'tz'   => 'EET' ) );
ok( $d->gmt->date, '14 Feb 2002 09:11:48 GMT' );

## backto HST
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->gmt->date, '14 Feb 2002 09:11:48 GMT' );

## another tz
$ENV{TZ} = 'CET';  ## central Europe
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->gmt->date, '14 Feb 2002 09:11:48 GMT' );

## epoch tests
$ENV{TZ} = 'MST';  ## mountain standard
ok( $d = new VSAP::Server::G11N::Date( 'epoch' => 1015455692 ) );
ok( $d->gmt->date, '06 Mar 2002 23:01:32 GMT');
