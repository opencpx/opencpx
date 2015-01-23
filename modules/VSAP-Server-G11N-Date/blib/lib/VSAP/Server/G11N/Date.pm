package VSAP::Server::G11N::Date;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);
use Time::Zone ();

require DynaLoader; ## for bootstrap
require Exporter;
our @ISA = qw(Exporter DynaLoader);
our $VERSION = '2.15';

bootstrap VSAP::Server::G11N::Date $VERSION;

our $_epoch      = undef;   ## epoch object
our $_offset     = undef;   ## GMT hour offset (optional): overrides local date representation
our $_gmt_offset = undef;   ## GMT seconds offset (optional): overrides local date representation
our $_tz         = undef;   ## timezone (optional): overrides local date representation
our $_original   = undef;   ## original incoming date object
our $_gmt        = undef;   ## gmt date object
our $_local      = undef;   ## localtime object

sub new {
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_)
      and return $self;

    return;
}

## side effects: $_original, $_gmt, and $_local objects init'ed
sub init {
    my $self = shift;
    my %parm = ( scalar(@_) % 2 ? (@_, undef) : @_ );

    ## set internal $_offset member: $parm{'offset'} expected in [+/-]nnnn format
    $_offset = ( exists $parm{'offset'} && $parm{'offset'}
		 ? $parm{'offset'}
		 : '' );

    ## $_gmt_offset is seconds (+/-) from GMT
    $_gmt_offset = ( exists $parm{'gmt_offset'} && $parm{'gmt_offset'}
		     ? $parm{'gmt_offset'}
		     : ( $_offset 
			 ? Time::Zone::tz_offset($_offset)
			 : ( $parm{'tz'} 
			     ? Time::Zone::tz_offset($parm{'tz'})
			     : '' ) ) );

    ## $_tz should be an Olson pathname relative to
    ## /usr/share/zoneinfo (e.g., MST7MDT, CET, Asia/Tokyo, etc.)
    $_tz = ( exists $parm{'tz'} && $parm{'tz'}
	     ? $parm{'tz'} 
	     : ( $_offset && $_gmt_offset ? uc Time::Zone::tz_name($_gmt_offset) : '' ) );

    delete $parm{'offset'};
    delete $parm{'gmt_offset'};
    delete $parm{'tz'};

    ## set the epoch object
    $_epoch    = VSAP::Server::G11N::Date::Epoch->new( %parm )
      or return;

    ## build/parse original date
    $_original = VSAP::Server::G11N::Date::Original->new( $_epoch->date );

    ## build/parse GMT
    $_gmt      = VSAP::Server::G11N::Date::GMT->new( $_epoch->epoch );

    ## build parse localtime
    $_local    = VSAP::Server::G11N::Date::Local->new( $_epoch->epoch, $_tz );

    return 1;
}

## incoming values
sub epoch      { return $_epoch->epoch; }
sub date       { return $_epoch->date;  }
sub offset     { return $_offset;       }
sub gmt_offset { return $_gmt_offset;   }
sub tz         { return $_tz;           }

## values we set in here
sub original   { return $_original;     }
sub gmt        { return $_gmt;          }
sub local      { return $_local;        }

##################################################
package VSAP::Server::G11N::Date::Epoch;
##################################################

use HTTP::Date ();

## we can be invoked in several ways:
##
## new('Mon Mar 11 11:52:08 MST 2002')
##
## new('date'  => 'Mon Mar 11 11:52:08 MST 2002');
##
## new('epoch' => '1015872759');
## 
## (epoch takes precedence over date)
## new('date'   => 'Mon Mar 11 11:52:08 MST 2002',
##     'epoch'  => '1015872759');
##

our $_epoch    = 0;
our $_precious = '';

sub new {
    my $self = bless { }, shift;
    $self->init(@_)
      and return $self;

    return;
}

sub init {
    my $self = shift;
    my %parm = ( scalar(@_) % 2 ? (@_, undef) : @_ );

    unless( $parm{epoch} || $parm{date} ) {
	$parm{date} = (keys %parm)[0];
    }

    ## (precedence: epoch -> date)
    ## named parameters: epoch
    if( exists $parm{epoch} ) {
	$_precious = ( $parm{epoch} ? scalar gmtime($parm{epoch}) : '' );
	$_epoch    = ( $parm{epoch} ? $parm{epoch} : 0 )
	  or do {
	      warn "Could not parse '" . $parm{date} . "' as date\n";
	      return;
	  };
    }

    ## named paramters: date
    elsif( $parm{date} ) {
	$_precious = $parm{date};
	$_epoch    = HTTP::Date::str2time( $parm{date}, 'GMT' );
      BAD_DATE_FORMAT: {
	    unless( $_epoch ) {
		## malformed tz: assume gmt west
		if( $parm{date} =~ /^(.*?)\s+\d(\d\d\d\d)$/ ) {
		    $_epoch = HTTP::Date::str2time( $1, "-$2" )
		      and do {
			  $_precious = "$1 -$2";
			  last BAD_DATE_FORMAT;
		      };
		}

		## other malformed dates here
		## ...
	    }
	}

	unless( $_epoch ) {
	    warn "Could not parse '" . $parm{date} . "' as date\n";
	    return;
	}
    }

    ## don't know...
    else {
	## huh?
    }

    return 1;
}

sub epoch  { return $_epoch;    }
sub date   { return $_precious; }

##################################################
package VSAP::Server::G11N::Date::Simple;
##################################################

use constant DEF_FORMAT => '%02d %s %d %02d:%02d:%02d%s';  ## sprintf

our %mon  = ( 1 => 'Jan',   2  => 'Feb',   3  => 'Mar',   4  => 'Apr', 
	      5 => 'May',   6  => 'Jun',   7  => 'Jul',   8  => 'Aug', 
	      9 => 'Sep',   10 => 'Oct',   11 => 'Nov',   12 => 'Dec', );

sub new {
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_);

    return $self;
}

sub init {
    my $self = shift;

    $_[0]->{'year'}    = 0;
    $_[0]->{'month'}   = 0;
    $_[0]->{'day'}     = 0;
    $_[0]->{'hour'}    = 0;
    $_[0]->{'hour_12'} = 0;
    $_[0]->{'minute'}  = 0;
    $_[0]->{'second'}  = 0;

    $_[0]->{'offset'}         = '';
    $_[0]->{'tz'}             = '';
    $_[0]->{'gmt_offset'}     = '';
    $_[0]->{'pm'}             = '';

    return 1;
}

sub year       	   { $_[0]->{'year'};       	}
sub month      	   { $_[0]->{'month'};      	}
sub day        	   { $_[0]->{'day'};        	}
sub hour       	   { $_[0]->{'hour'};       	}
sub hour_12    	   { $_[0]->{'hour_12'};    	}
sub minute     	   { $_[0]->{'minute'};     	}
sub second     	   { $_[0]->{'second'};     	}
sub offset     	   { $_[0]->{'offset'};     	}
sub tz         	   { $_[0]->{'tz'};         	}
sub gmt_offset 	   { $_[0]->{'gmt_offset'};     }
sub pm             { $_[0]->{'hour'} >= 12;     }

## notes: this was implemented with sprintf instead of strftime
## because strftime always returns 'GMT' as the offset when $ENV{'TZ'}
## is numeric (which is what we used to get strftime to get it right).
##
## Now, perhaps something besides $ENV{'TZ'} will work. Please let me
## know if you figure out a reliable way to get strftime to work like
## we want it to.
sub date {
    return sprintf( DEF_FORMAT,
		    $_[0]->day, $mon{$_[0]->month}, $_[0]->year, 
		    $_[0]->hour, $_[0]->minute, $_[0]->second, 
		    ( $_[0]->tz 
		      ## use timezone
		      ? ' ' . $_[0]->tz

		      ## no timezone, check offset
		      : ( defined $_[0]->offset 
			  ? ( $_[0]->offset

			      ## use non-zero offset
			      ? ' ' . $_[0]->offset

			      ## zero offset is really GMT
			      : ' GMT' 
			    )

			  ## no offset either
			  : ''
			)
		    )
		  );
}

##################################################
package VSAP::Server::G11N::Date::Original;
our @ISA = qw(VSAP::Server::G11N::Date::Simple);
##################################################

use HTTP::Date ();
use Time::Zone ();

sub init {
    my $self = shift;
    my $date = shift;

    $self->SUPER::init;
    return 1 unless $date;

    ( $self->{'year'}, $self->{'month'}, $self->{'day'},
      $self->{'hour'}, $self->{'minute'}, $self->{'second'},
      $self->{'offset'} ) = HTTP::Date::parse_date($date);

    ## check for bonafide offset
    if( $self->{'offset'} && $self->{'offset'} =~ /^[\-\+]\d\d?\d\d$/ ) {
	$self->{'gmt_offset'} = Time::Zone::tz_offset($self->{'offset'});  ## convert to seconds
	$self->{'tz'}         = uc Time::Zone::tz_name($self->{'gmt_offset'});
    }

    ## prolly a symbolic offset (time zone name)
    else {
	$self->{'tz'}         = ( $self->{'offset'} ? $self->{'offset'} : 'GMT' );
	$self->{'gmt_offset'} = Time::Zone::tz_offset($self->{'tz'});
	$self->{'offset'}     = sprintf( "%s%04d",
					 ( $self->{'gmt_offset'} < 0 ? '-' : '+' ),
					 ( $self->{'gmt_offset'} % 3600
					   ## half hour offset (rare)
					   ? ($self->{'gmt_offset'}<0?-1:1)*($self->{'gmt_offset'}-18)/36
					   ## full hour offset
					   : ($self->{'gmt_offset'}<0?-1:1)*$self->{'gmt_offset'}/36 ) );
    }
    $self->{'hour_12'} = ( $self->{'hour'} > 12 ? $self->{'hour'}-12 : $self->{'hour'} );

    return 1;
}

##################################################
package VSAP::Server::G11N::Date::GMT;
our @ISA = qw(VSAP::Server::G11N::Date::Simple);
##################################################

sub init {
    my $self  = shift;
    my $epoch = shift;

    $self->SUPER::init;
    return 1 unless $epoch;

    ( $self->{'second'}, $self->{'minute'}, $self->{'hour'},
      $self->{'day'},    $self->{'month'},  $self->{'year'},
      $self->{'wday'}, $self->{'yday'} ) = gmtime($epoch);
    $self->{'year'} += 1900; $self->{'month'} += 1;

    $self->{'offset'}     = '+0000';
    $self->{'tz'}         = 'GMT';
    $self->{'gmt_offset'} = 0;
    $self->{'hour_12'} = ( $self->{'hour'} > 12 ? $self->{'hour'}-12 : $self->{'hour'} );

    return 1;
}

sub wday {
    return $_[0]->{'wday'};
}

sub yday {
    return $_[0]->{'yday'};
}

##################################################
package VSAP::Server::G11N::Date::Local;
our @ISA = qw(VSAP::Server::G11N::Date::Simple);
##################################################

use Time::Zone ();
use POSIX qw(tzname);

sub init {
    my $self  = shift;
    my $epoch = shift;
    my $tz    = shift;  ## This should be a path relative to the
			## system zoneinfo directory. See tzset(3)
                        ## for details on how this works.

    $self->SUPER::init;
    return 1 unless $epoch;

    ## this must be a valid entry in the zoneinfo database; we made
    ## symlinks for most common offsets
    local $ENV{'TZ'} = ( $tz ? $tz : ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) );

    ( $self->{'second'}, $self->{'minute'}, $self->{'hour'}, 
      $self->{'day'},    $self->{'month'},  $self->{'year'}, 
      $self->{'wday'},   $self->{'yday'},   $self->{'dst'}, 
      $self->{'tz'},     $self->{'gmt_offset'}, ) = VSAP::Server::G11N::Date::localtime($epoch);

    $self->{'offset'} = sprintf( "%s%04d",
				 ( $self->{'gmt_offset'} < 0 ? '-' : '+' ),
				 ( $self->{'gmt_offset'} % 3600
				   ## half hour offset (rare)
				   ? ($self->{'gmt_offset'}<0?-1:1)*($self->{'gmt_offset'}-18)/36
				   ## full hour offset
				   : ($self->{'gmt_offset'}<0?-1:1)*$self->{'gmt_offset'}/36 ) );
    $self->{'hour_12'} = ( $self->{'hour'} > 12 ? $self->{'hour'}-12 : $self->{'hour'} );

    return 1;
}

sub wday {
    return $_[0]->{'wday'};
}

sub yday {
    return $_[0]->{'yday'};
}

sub dst {
    return $_[0]->{'dst'};
}

1;
__END__

=head1 NAME

VSAP::Server::G11N::Date - Perl globalization date module does date conversions between timezones

=head1 SYNOPSIS

  use VSAP::Server::G11N::Date;

  my $date = new VSAP::Server::G11N::Date('Fri Mar  8 16:15:55 MST 2002');

  print "The local date is " . $date->local->date . "\n";

  print "The local year is " . $date->local->year . "\n";

=head1 DESCRIPTION

VSAP::Server::G11N::Date is a Perl class that uses HTTP::Date and Time::Zone
to convert dates into the desired (local) representation and GMT.

VSAP::Server::G11N::Date contains a VSAP::Server::G11N::Date::Epoch object and three
VSAP::Server::G11N::Date::Simple objects, whose interfaces are described
below.  VSAP::Server::G11N::Date objects have just a few methods of their
own:

=over 4

=item B<new>

The constructor for this object. You may initialize it with epoch
seconds or a date string:

  $d = new VSAP::Server::G11N::Date( epoch => 1015631263 );
  $d = new VSAP::Server::G11N::Date( date  => 'Fri Mar  8 16:47:42 MST 2002' );
  $d = new VSAP::Server::G11N::Date( 'Fri Mar  8 16:47:42 MST 2002' );  ## date is implied

You may also pass along a timezone or offset to coerce the B<Local>
date object:

  ## use central european time regardless of $ENV{TZ}
  $d = new VSAP::Server::G11N::Date( date  => 'Fri Mar  8 16:47:42 MST 2002',
                              tz    => 'CET' );

  ## same thing
  $d = new VSAP::Server::G11N::Date( date   => 'Fri Mar  8 16:47:42 MST 2002',
                              offset => '+0100' );
  
=item B<epoch>

Returns epoch seconds derived from the object initialization (i.e.,
if you initialized the object with epoch seconds, those will be
returned here. If you initialized with a date, the date will be
converted to epoch seconds and returned here).

=item B<date>

The original "pristine" date string used to initialize this object.
If the object was initialized with epoch seconds, this will return
the result of I<scalar gmtime($obj->epoch)> (which is a GMT date
string). Due to the variety of format options, this may or may not
look exactly like the date returned by the
B<VSAP::Server::G11N::Date::Original> object.

=item B<offset>

If an offset was used to initialize the object, that will be returned
here. If a timezone was used to initialize the object, it will be
translated to an offset via Time::Zone(3) and returned here. Returns
undefined if it was never initialized.

=item B<tz>

If an timezone was used to initialize the object, that will be
returned here. If an offset was used to initialize the object, it will
be translated to an timezone via Time::Zone(3) and returned here.
Returns undefined if it was never initialized.

=item B<original>

Returns a handle to the B<VSAP::Server::G11N::Date::Original> object (which
is a subclass of B<VSAP::Server::G11N::Date::Simple> described below).

=item B<gmt>

Returns a handle to the B<VSAP::Server::G11N::Date::GMT> object (which is a
subclass of B<VSAP::Server::G11N::Date::Simple> described below).

=item B<local>

Returns a handle to the B<VSAP::Server::G11N::Date::Local> object (which is
a subclass of B<VSAP::Server::G11N::Date::Simple> described below).

=back

=head2 VSAP::Server::G11N::Date::Epoch

VSAP::Server::G11N::Date uses a VSAP::Server::G11N::Date::Epoch object to store the
epoch of the incoming date. This epoch object is later used for date
conversions.

You may access VSAP::Server::G11N::Date::Epoch objects directly or as part
of a VSAP::Server::G11N::Date object (which is more common).
VSAP::Server::G11N::Date::Epoch converts a time representation into epoch
seconds and epoch seconds to GMT time.

=over 4

=item B<new>

Creates a new VSAP::Server::G11N::Date::Epoch object from a date or existing
epoch time.

    $e = new VSAP::Server::G11N::Date::Epoch( 'Wed Mar 13 15:11:24 MST 2002' );
    $e = new VSAP::Server::G11N::Date::Epoch( 'date' => 'Wed Mar 13 15:11:24 MST 2002' );
    $e = new VSAP::Server::G11N::Date::Epoch( 'epoch' => 1016057763 );

Valid date formats are the same as those found in the
HTTP::Date::parse_date function.

=item B<epoch>

Depending on what you initialized the object with, B<epoch> returns
the original epoch seconds you passed in or the epoch seconds obtained
from the date you passed as a parameter.

=item B<date>

Returns the original date passed in. If no date was passed in as a
parameter, a date string in GMT will be returned (gmtime is used to
generate this string).

=back

=head2 VSAP::Server::G11N::Date::Simple

VSAP::Server::G11N::Date uses three instances of VSAP::Server::G11N::Date::Simple
to store the original incoming date, the GMT representation of the
original date, and the localtime representation of the original date.

VSAP::Server::G11N::Date::Simple does not have an initialization or parsing
routine--it's sort of a 'virtual' base class, never meant to be used
directly but inherited.

The three instances of VSAP::Server::G11N::Date::Simple are:

=over 4

=item B<VSAP::Server::G11N::Date::Original>

=item B<VSAP::Server::G11N::Date::GMT>

=item B<VSAP::Server::G11N::Date::Local>

=back

These three classes each have the following accessor methods:

=over 4

=item B<new>

Creates a new object which inherits from VSAP::Server::G11N::Date::Simple:

=over 4

=item B<VSAP::Server::G11N::Date::Original>

Creates a new VSAP::Server::G11N::Date::Original object. This object contains
the original date with timezone cannonicalization. The first argument
is a date string that can be parsed by HTTP::Date.

    $o = new VSAP::Server::G11N::Date::Original( $e->date );  ## $e is an epoch object

=item B<VSAP::Server::G11N::Date::GMT>

Creates a new VSAP::Server::G11N::Date::GMT object. This object contains the
original date adjusted to GMT time. The first object is GMT seconds
(this method uses gmtime to populate its data members).

    $o = new VSAP::Server::G11N::Date::GMT( $e->epoch );  ## $e is an epoch object

=item B<VSAP::Server::G11N::Date::Local>

Creates a new VSAP::Server::G11N::Date::Local object. This object contains
the original date adjusted for localtime settings. $ENV{TZ} is used
to determine the localtime preference. The first argument is an epoch
time. If a second argument (a timezone string) is present, the object
will use that instead of $ENV{TZ}.

The timezone string should be a path relative to the zoneinfo
directory (/usr/share/zoneinfo on FreeBSD).

    $o = new VSAP::Server::G11N::Date::Local( $e->epoch, 'Asia/Tokyo' );  ## $e is an epoch object

=back

=item B<date>

Returns a string representation of the object in the following format:

    13 Feb 2002 23:11:48 HST

=item B<year>

Returns the year represented in this object.

=item B<month>

Returns the month number (1 = January, 12 = December) represented in
this object.

=item B<day>

Returns the day of month (1 - 28, 29, 30, 31) represented in this
object.

=item B<hour>

Returns the 24-hour portion represented in this object (e.g., 2pm is
14:00 hours so $obj->hour returns '14').

=item B<hour_12>

Returns the 12-hour portion represented in this object (e.g., 14:00
= 2:00 so $obj->hour returns '14' and $obj->hour_12 returns '2').

=item B<minute>

Returns the minute portion represented in this object.

=item B<second>

Returns the second portion represented in this object.

=item B<offset>

Returns the GMT offset in hours for the date represented in this
object as a RFC 822-style offset (e.g., +0100).

=item B<gmt_offset>

Returns the number of seconds offset from GMT time.

=item B<tz>

Returns the timezone abbreviation for the date represented in this
object (e.g., CET, MST, PDT, etc.).

=item B<pm>

Returns true if the 24-hour value is greater than or equal to 12.

=item B<wday>

B<VSAP::Server::G11N::Date::GMT> and B<VSAP::Server::G11N::Date::Local> objects
only. Returns weekday (e.g., Sun, Mon, Tue, etc.).

=item B<yday>

B<VSAP::Server::G11N::Date::GMT> and B<VSAP::Server::G11N::Date::Local> objects
only. Returns day of year (0-365).

=item B<dst>

B<VSAP::Server::G11N::Date::Local> objects only. Set if the date represented
in this object falls during daylight saving time.

=back

=head1 EXAMPLES

    my $d = new VSAP::Server::G11N::Date( 'Thu, 14 Feb 2002 13:11:48 +0400' );

    print "The original year is " . $d->original->year . "\n";
    print "The original hour is " . $d->original->hour . "\n";

    print "The local year is " . $d->local->year . "\n";
    print "The local hour is " . $d->local->hour . "\n";

    print "FYI, the GMT representation of " . $d->original->date . 
        " is " . $d->gmt->date . "\n";


    my $e = new VSAP::Server::G11N::Date( epoch => 1015631263 );

    print "The original date was " . $e->original->date . "\n";
    $ENV{TZ} = 'MST7MDT';
    print "In Utah, that date is " . $e->local->date . "\n";
    print "In Utah, it is " . ($d->local->dst ? '' : 'not ') . "daylight saving time\n";

    $ENV{TZ} = 'CET';
    print "In Barcelona, that date is " . $e->local->date . "\n";

=head1 CAVEATS

=over 4

=item *

If the incoming date has no offset, '+0000' (GMT) is assumed.

=item *

If the incoming date does not use a timezone string but does use an
offset instead, it is possible that the reverse offset->zone mapping
in Time::Zone is incorrect (multiple zone names cover the same
offsets). Sorry.

Also, if an known timezone abbreviation is used in the original
(incoming) date, the date will not translate correctly for localtime
and will show GMT instead (though the TZ might be correct--this is a
bug).

=item *

The B<pm> field in B<VSAP::Server::G11N::Date::Simple> should really be a
quad-state variable instead of a boolean. What we call '12 am' is
really '12 midnight' (if you're speaking of hours) since it is neither
ante-meridian nor post-meridian; '12 pm' is really '12 noon' by the
same token. We keep with colloquial usage of '12 am' and '12 pm' for
simplicity's sake.

=item *

B<VSAP::Server::G11N::Date> can handle half-offsets (1800 seconds) also, but
cannot do third-offsets (1200 seconds). This is a todo item. (If you
live somewhere with a 20 minute offset, please accept my apologies).

=back

=head1 SEE ALSO

HTTP::Date(3), Time::Zone(3)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
