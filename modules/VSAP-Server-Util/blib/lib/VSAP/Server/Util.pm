package VSAP::Server::Util;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(xml_escape gmt2local);
$VERSION = '1.01';

## module stuff here
## FIXME: conditionally require this only for VPS kernels
require 'sys/syscall.ph'; ## this is needed because in vsapd we call setuid
use HTTP::Date ();
use Time::Zone ();

sub size_string
{
  if (!$_[0])               { "0k" }
  elsif ($_[0] < 1024)      { "1k" }
  elsif ($_[0] < 1048576)   { printf("%4dk", ($_[0] + 512) / 1024) }
  elsif ($_[0] < 103809024) { printf("%4.1fM", $_[0] / 1048576.0) }
  else                      { printf("%4dM", ($_[0] + 524288) / 1048576) }
}

## In: any string to be escaped
## Returns: an escaped string
## Side Effects: none (original string untouched)
sub xml_escape {
    my $str = shift;

    $str =~ s/\&/\&amp;/g;           ## ampersand
    $str =~ s/</\&lt;/g;             ## less than
    $str =~ s/>/\&gt;/g;             ## greater than
    $str =~ s/\r/\&#013;/g;          ## carriage return
    $str =~ s/\n/\&#010;/g;          ## newline

    $str =~ s/([\x00-\x17\x7f])//g;  ## other non-printables go away (this should be last)

    return $str;
}

## scottw:2002-02-07
## usage:
##    my $dref = gmt2local( "12:34:56 7 Aug 2008 GMT" );   ## - or below -
##    my $dref = gmt2local( {'date' => "12:34:56 7 Aug 2008 GMT", 
##                           'zone' => 'JST', }
##                        );
##    print "The message date is $dref->{'local'} but GMT is $dref->{'gmt'}\n";
##
## returns:
##    epoch,
##    gmt,   gyear, gmon, gday, ghour, g12hour, gmin, gsec, gwday,       goff
##    orig,  oyear, omon, oday, ohour, o12hour, omin, osec, owday, odst, ooff
##    local, year,  mon,  day,  hour,  12hour,  min,  sec,  wday,  dst,  off
##
sub gmt2local {
    my $params  = shift;

    my %wday = ( 0 => 'Sun', 1  => 'Mon', 2  => 'Tue', 3  => 'Wed', 
		 4 => 'Thu', 5  => 'Fri', 6  => 'Sat', 7  => 'Sun' );
    my %mon  = ( 1 => 'Jan', 2  => 'Feb', 3  => 'Mar', 4  => 'Apr', 
		 5 => 'May', 6  => 'Jun', 7  => 'Jul', 8  => 'Aug', 
		 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dec', );

    use constant DATE_FMT => '%02d %s %d %02d:%02d:%02d %s';

    ## init default
    my $date_str = $params;
    my $timezone = ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' );

    ## init from $params
    if( 'HASH' eq ref($params) ) {
	$date_str = $params->{'date'};
	$timezone = ( $params->{'zone'} ? $params->{'zone'} : $timezone );
    }
    my %date;

    ##############################################
    ## convert original date to GMT
    ##############################################
    ## convert date to epoch seconds
    $date{'epoch'}= ( ref($params) && $params->{'epoch'} 
		      ? $params->{'epoch'} 
		      : HTTP::Date::str2time($date_str, 'GMT') );

    ## split out date elements from gmt epoch seconds
    ( $date{'gsec'}, $date{'gmin'}, $date{'ghour'}, $date{'gday'}, 
      $date{'gmon'}, $date{'gyear'}, $date{'gwday'} ) = gmtime($date{'epoch'});

    ## make adjustments to gmtime return values
    $date{'gyear'}+=1900; $date{'gmon'}+=1; $date{'goff'}='GMT';

    $date{'goff'} = Time::Zone::tz2zone($date{'goff'});

    ## fixup 12 hour values
    $date{'g12hour'} = ( $date{'ghour'} > 12 ? $date{'ghour'}-12 : $date{'ghour'} );

    ## set gmt date string
    $date{'gmt'} = sprintf( DATE_FMT,
			    $date{'gday'}, $mon{$date{'gmon'}}, $date{'gyear'}, 
			    $date{'ghour'}, $date{'gmin'}, $date{'gsec'}, $date{'goff'} );

    ##############################################
    ## parse original date string
    ##############################################
    if( $date_str ) {
	( $date{'oyear'}, $date{'omon'}, $date{'oday'},
	  $date{'ohour'}, $date{'omin'}, $date{'osec'}, 
	  $date{'ooff'} ) = HTTP::Date::parse_date($date_str);
    }

    ## get it from epoch as GMT
    else {
	( $date{'osec'}, $date{'omin'}, $date{'ohour'}, $date{'oday'}, $date{'omon'}, 
	  $date{'oyear'}, $date{'owday'}, undef, $date{'odst'} ) = gmtime($date{'epoch'});

	$date{'oyear'}+=1900; $date{'omon'}+=1; $date{'ooff'}='GMT';
    }

    $date{'ooff'} = Time::Zone::tz2zone($date{'ooff'}, undef, $date{'odst'});

    ## fixup 12 hour values
    $date{'o12hour'} = ( $date{'ohour'} > 12 ? $date{'ohour'}-12 : $date{'ohour'} );

    $date{'orig'} = sprintf( DATE_FMT,
			     $date{'oday'}, $mon{$date{'omon'}}, $date{'oyear'}, 
			     $date{'ohour'}, $date{'omin'}, $date{'osec'}, $date{'ooff'} );

    ##############################################
    ## convert our GMT date to localtime
    ##############################################

    ## set timezone variable
    local $ENV{'TZ'} = $timezone;

    ## split out date elements from local epoch seconds
    ( $date{'sec'}, $date{'min'}, $date{'hour'}, $date{'day'}, $date{'mon'}, 
      $date{'year'}, $date{'wday'}, undef, $date{'dst'} ) = localtime($date{'epoch'});

    ## make adjustments to gmtime return values
    $date{'year'}+=1900; $date{'mon'}+=1;
#    $date{'off'} = Time::Zone::tz2zone($ENV{'TZ'}, undef, $date{'dst'});
    $date{'off'} = Time::Zone::tz2zone;

    ## fixup 12 hour values
    $date{'12hour'} = ( $date{'hour'} > 12 ? $date{'hour'}-12 : $date{'hour'} );

    ## set local date string
    $date{'local'} = sprintf(DATE_FMT,
			    $date{'day'}, $mon{$date{'mon'}}, $date{'year'}, 
			    $date{'hour'}, $date{'min'}, $date{'sec'}, $date{'off'});


    ##############################################
    ## return hashref
    ##############################################
    return \%date;
}
1;


1;
__END__

=head1 NAME

VSAP::Server::Util - Miscellaneous VSAP functions

=head1 SYNOPSIS

  use VSAP::Server::Util qw(xml_esacpe gmt2local);

=head1 DESCRIPTION

=head2 B<size_string>

FIXME

=head2 B<xml_escape>

Returns an xml escaped string, suitable for running through an xml
parser like XML::SimpleObject.

  my $unsafe = "joe & bob \n are after << you!\x00`cat /etc/passwd`\n";
  my $safe   = VSAP::Server::Util::xml_escape($unsafe);  ## now $safe is safe

Currently escaped entities:

=over 4

=item B<ampersand>

\&    => &amp;

=item B<less than>

<     => &lt;

=item B<greater than>

>     => &gt;

=item B<carriage return>

\r    => &#013;

=item B<newline>

\n    => &#010;

=item B<other non-printables are removed>

[\x00-\x17\x7f]

=back

=head2 B<gmt2local>

Parses dates via HTTP::Date and Time::Zone and returns a large hash
reference containing the date/time elements for GMT, the original date, and the localtime date with DST considerations.

DST handling may be done in two ways: set $ENV{'TZ'} or pass an
abbreviated timezone as a named parameter (see below for example).
When both environment variable and paramter are present, the parameter
takes precedence. When neither are present, GMT is assumed.

Example:

  my $dref;

  $dref = gmt2local( { 'epoch' => 123457689,
                       'zone'  => 'JST' } );
  $dref = gmt2local( { 'date'  => "12:34:56 7 Aug 2008 GMT",
                       'zone'  => 'MST7MDT' } );
  $dref = gmt2local( { 'date'  => "12:34:56 7 Aug 2008 GMT" } );
  $dref = gmt2local( '12:34:56 7 Aug 2008 GMT' );

  print "Local hour is $dref->{'hour'}\n";

The following fields are available:

=over 4

=item B<epoch>

date string converted to epoch seconds (GMT). An epoch may also be
used as a named parameter, in which case that epoch will be returned.
All epoch seconds are assumed to be in GMT. This might change if I
think about it more.

=item B<orig, local, gmt>

Original date string, localtime date string, and GMT date string.
These are formatted using the following format:

    06 Nov 1994 06:49:37 UTC

=item B<oyear, year, gyear>

Original year, localtime year, and GMT year. The year is expressed as
a four-digit year with century.

=item B<omon, mon, gmon>

Original month, localtime month, and GMT month as integers. These are
already adjusted from 1 so January = 1, etc.

=item B<oday, day, gday>

Original day of month, localtime day of month, and GMT day of month

=item B<ohour, hour, ghour>

Original 24 hour, localtime 24 hour, and GMT 24 hour

=item B<o12hour, 12hour, g12hour>

Original 12 hour, localtime 12 hour, and GMT 12 hour

=item B<omin, min, gmin>

Original minutes, localtime minutes, and GMT minutes

=item B<osec, sec, gsec>

Original seconds, localtime seconds, and GMT seconds

=item B<owday, wday, gwday>

Day of week as an integer (e.g., Sun = 1, Mon = 1, Tue = 2, Wed = 3,
etc.)

=item B<odst, dst>

Daylight Saving Time flag. True if the date falls during a DST time
for the given date.

  $d = gmt2local({'date' => 'Thu, 18 Apr 2002 13:11:48 JST',
		  'zone' => 'PST8PDT'});
  print "In California, the date is " . ($d->{'dst'} ? '' : 'not ') . "DST\n";
  print "And in Japan, the date is " . ($d->{'odst'} ? '' : 'not ') . "DST\n";

=item B<ooff, off, goff>

Original offset, localtime offset, and GMT offset (which is always '+0000')

=back

=head1 AUTHOR

gmt2local, Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 SEE ALSO

perl(1).

=cut
