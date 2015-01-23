use Test;
BEGIN { $|=1; plan(tests => 22); chdir 't' if -d 't'; }
use blib;
use ExtUtils::testlib;

use VSAP::Server::G11N::Date;
my $d;

## compare two zones DST settings
$ENV{TZ} = 'PST8PDT';
ok( $d = new VSAP::Server::G11N::Date('Thu, 18 Apr 2002 13:11:48 JST'));
ok( $d->gmt->date, '18 Apr 2002 04:11:48 GMT');
ok( $d->local->date, '17 Apr 2002 21:11:48 PDT' );
ok( $d->original->date, '18 Apr 2002 13:11:48 JST');
ok( $d->local->dst );

## another tz
$ENV{TZ} = 'HST';  ## Hawaii standard
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 18 Apr 2002 13:11:48 +0400' ) );
ok( $d->gmt->date, '18 Apr 2002 09:11:48 GMT' );
ok( $d->local->date, '17 Apr 2002 23:11:48 HST' );
ok( $d->original->date, '18 Apr 2002 13:11:48 ZP4' );

## another tz
$ENV{TZ} = 'MET';  ## central Europe DST starts on Sunday March 31, 2002 at 2:00:00 AM
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 18 Apr 2002 13:11:48 +0400' ) );
ok( $d->gmt->date, '18 Apr 2002 09:11:48 GMT' );
ok( $d->local->date =~ /18 Apr 2002 11:11:48 ME.*ST/ );
ok( $d->original->date, '18 Apr 2002 13:11:48 ZP4' );

## epoch tests
$ENV{TZ} = 'MST7MDT';  ## mountain standard; DST starts on Sunday April 7, 2002 at 2:00:00 AM
ok( $d = new VSAP::Server::G11N::Date( 'epoch' => 1019702907 ) );
ok( $d->gmt->date, '25 Apr 2002 02:48:27 GMT' );
ok( $d->local->date, '24 Apr 2002 20:48:27 MDT' );
ok( $d->original->date, '25 Apr 2002 02:48:27 GMT' );

## override environment
ok( $d = new VSAP::Server::G11N::Date( 'date' => 'Thu, 18 Apr 2002 13:11:48 +0400',
			 'tz'   => 'EET' ) );
ok( $d->gmt->date, '18 Apr 2002 09:11:48 GMT' );
ok( $d->local->date =~ /18 Apr 2002 12:11:48 EE.*ST/ );
ok( $d->original->date, '18 Apr 2002 13:11:48 ZP4' );
ok( $d->local->dst );
