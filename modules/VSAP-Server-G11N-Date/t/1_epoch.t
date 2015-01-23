use Test;
BEGIN { $|=1; plan(tests => 36); chdir 't' if -d 't'; }
use blib;
use ExtUtils::testlib;

use VSAP::Server::G11N::Date;
ok(1);
my $d;

## test various empty constructors
ok( $d = new VSAP::Server::G11N::Date );
ok( $d->date, '' );
ok( $d->epoch, 0 );

ok( $d = new VSAP::Server::G11N::Date() );
ok( $d->date, '' );
ok( $d->epoch, 0 );

ok( $d = new VSAP::Server::G11N::Date('') );
ok( $d->date, '' );
ok( $d->epoch, 0 );

## these sets fail because of warnings
#ok( $d = new VSAP::Server::G11N::Date( date => '' ) );
#ok( $d->date, '' );
#ok( $d->epoch, 0 );

#ok( $d = new VSAP::Server::G11N::Date( epoch => undef ) );
#ok( $d->date, '' );
#ok( $d->epoch, 0 );

#ok( $d = new VSAP::Server::G11N::Date( epoch => 0 ) );
#ok( $d->date, '' );
#ok( $d->epoch, 0 );

ok( $d = new VSAP::Server::G11N::Date('Fri Mar  8 16:47:42 MST 2002') );
ok( $d->date, 'Fri Mar  8 16:47:42 MST 2002' );
ok( $d->epoch, '1015631262' );

ok( $d = new VSAP::Server::G11N::Date( date => 'Fri Mar  8 16:47:42 MST 2002' ) );
ok( $d->date, 'Fri Mar  8 16:47:42 MST 2002' );
ok( $d->epoch, '1015631262' );

ok( $d = new VSAP::Server::G11N::Date( 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)' ) );
ok( $d->date, 'Thu, 7 Mar 2002 08:12:00 -0700 (MST)' );
ok( $d->epoch, '1015513920' );

## alter epoch seconds by one; test parameter precedence (epoch -> date)
ok( $d = new VSAP::Server::G11N::Date( date  => 'Fri Mar  8 16:47:42 MST 2002',
			 epoch => '1015631263' ) );
ok( $d->date, 'Fri Mar  8 23:47:43 2002' );
ok( $d->epoch, '1015631263' );

## use epoch paramter
ok( $d = new VSAP::Server::G11N::Date( epoch => '1015631263' ) );
ok( $d->date, 'Fri Mar  8 23:47:43 2002' );
ok( $d->epoch, '1015631263' );

ok( $d = new VSAP::Server::G11N::Date( epoch => '1015631263',
			 tz    => 'CET' ) );
ok( $d->date, 'Fri Mar  8 23:47:43 2002' );
ok( $d->epoch, '1015631263' );
ok( $d->tz, 'CET' );

ok( $d = new VSAP::Server::G11N::Date( epoch  => '1015631263',
			 offset => '+0100' ) );
ok( $d->date, 'Fri Mar  8 23:47:43 2002' );
ok( $d->epoch, '1015631263' );
ok( $d->offset, '+0100' );

## try a mal-formatted date (we're trying to accomodate some of these)
ok( $d = new VSAP::Server::G11N::Date( date => 'Sun, 07 Mar 2004 15:03:02 00700' ) );
ok( $d->date, 'Sun, 07 Mar 2004 15:03:02 -0700' );

## what to do with a bogus date...
$d = new VSAP::Server::G11N::Date( date => "2003-11-13 \x{BF}\x{C0}\x{C8}\x{C4} 10:36:36" );
ok( ! $d );
