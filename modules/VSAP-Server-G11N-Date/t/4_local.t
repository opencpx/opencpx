use Test;
BEGIN { $|=1; plan(tests => 47, todo => []); chdir 't' if -d 't'; }
use blib;
use ExtUtils::testlib;

use VSAP::Server::G11N::Date;
my $d;

## test local date
$ENV{'TZ'} = 'MET';
ok( $d = new VSAP::Server::G11N::Date( epoch => '1015631263' ) );
ok( $d->local->year, 2002 );
ok( $d->local->month, 3 );
ok( $d->local->day, 9 );
ok( $d->local->hour, 0 );
ok( $d->local->hour_12, 0 );
ok( $d->local->minute, 47 );
ok( $d->local->second, 43 );
ok( $d->local->offset, '+0100' );
ok( $d->local->gmt_offset, 3600 );
ok( $d->local->tz, 'MET' );
ok( !$d->local->pm );

## test local date
ok( $d = new VSAP::Server::G11N::Date( date => 'Fri Mar  8 16:47:42 MST 2002' ) );
ok( $d->local->year, 2002 );
ok( $d->local->month, 3 );
ok( $d->local->day, 9 );
ok( $d->local->hour, 0 );
ok( $d->local->hour_12, 0 );
ok( $d->local->minute, 47 );
ok( $d->local->second, 42 );
ok( $d->local->offset, '+0100' );
ok( $d->local->gmt_offset, 3600 );
ok( $d->local->tz, 'MET' );
ok( !$d->local->pm );

## try a GMT date
$ENV{TZ} = 'MST7MDT';
ok( $d = new VSAP::Server::G11N::Date( date => 'Sun, 06 Nov 1994 06:49:37 UTC' ) );
ok( $d->local->date, '05 Nov 1994 23:49:37 ' . ( $d->local->dst ? 'MDT' : 'MST' ) );

ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)' ) );
ok( $d->local->date, '07 Mar 2002 08:12:00 ' . ( $d->local->dst ? 'MDT' : 'MST' ) );

## coercion with tz
ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
				'tz'     => 'HST' ) );
ok( $d->local->date, '07 Mar 2002 05:12:00 HST' );

## coercion with offset
ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
				'offset' => '-1000' ) );
ok( $d->local->date, '07 Mar 2002 05:12:00 HST' );

## Pacific/Norfolk has a 30 minute offset
#ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Fri Mar 16 12:31:29 GMT 2002',
#				'tz'   => 'Pacific/Norfolk' ) );
#ok( $d->local->date, '17 Mar 2002 00:01:29 NFT' );

## Asia/Gaza
#ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Fri Mar 16 22:01:29 GMT 2002',
#				'tz' => 'Asia/Gaza' ) );
#ok( $d->local->date, '17 Mar 2002 00:01:29 ' . ( $d->local->dst ? 'EEST' : 'EET' ) );

## coercion with long tz
#ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
#				'tz'     => 'Asia/Tokyo' ) );
#ok( $d->local->date, '08 Mar 2002 00:12:00 JST' );

## try another format
ok( $d = new VSAP::Server::G11N::Date( 'date' => '2001-11-30 02:52:51 +0000' ) );
ok( $d->local->date, '29 Nov 2001 19:52:51 ' . ( $d->local->dst ? 'MDT' : 'MST' ) );

## try some other incoming tz
ok( $d = new VSAP::Server::G11N::Date( 'Wed, 13 Feb 2002 10:53:14 -0700' ) );
ok( $d->local->date, '13 Feb 2002 10:53:14 ' . ( $d->local->dst ? 'MDT' : 'MST' ) );

## TODO
## this will fail because there is no reverse mapping from +900 ->
## JST -> Asia/Tokyo to set $ENV{TZ} correctly
ok( $d = new VSAP::Server::G11N::Date( 'date'   => 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)',
				'offset' => '+0900' ) );
#skip( !$d->local->has_tz, $d->local->date, '08 Mar 2002 00:12:00 JST' );

## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->local->date, '13 Feb 2002 23:11:48 HST');

## override environment
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400',
			 'tz'   => 'EET' ) );
ok( $d->local->date, '14 Feb 2002 11:11:48 EET');

## backto HST
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->local->date, '13 Feb 2002 23:11:48 HST');

## another tz
$ENV{TZ} = 'MET';  ## central Europe
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 14 Feb 2002 13:11:48 +0400' ) );
ok( $d->local->date, '14 Feb 2002 10:11:48 MET');

## epoch tests
$ENV{TZ} = 'MST';  ## mountain standard
ok( $d = new VSAP::Server::G11N::Date( 'epoch' => 1015455692 ) );
ok( $d->local->date, '06 Mar 2002 16:01:32 ' . ( $d->local->dst ? 'MDT' : 'MST' ) );
