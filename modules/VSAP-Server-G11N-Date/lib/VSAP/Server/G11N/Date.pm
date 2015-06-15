package VSAP::Server::G11N::Date;

use 5.008004;
use strict;
use warnings;

use POSIX;
use Date::Parse;
use Time::Local;

our $VERSION = '0.12';

our $_original   = undef;   ## original incoming date object
our $_gmt        = undef;   ## gmt date object
our $_local      = undef;   ## localtime object

##############################################################################

sub _offset_fmt
{
   my $seconds = shift;

   return sprintf "%s%02d%02d", (($seconds < 0) ? "-" : "+"),
                                (int(abs($seconds)) / 3600),
                                (abs($seconds) % 3600);
}

##############################################################################

sub new
{
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_)
      and return $self;

    return;
}

# ----------------------------------------------------------------------------

sub init
{
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    my %parm = ( scalar(@_) % 2 ? (@_, undef) : @_ );

    ## $_tz should be an Olson pathname relative to
    ## /usr/share/zoneinfo (e.g., MST7MDT, CET, Asia/Tokyo, etc.)
    my $_tz = ( exists $parm{'tz'} && $parm{'tz'} ? $parm{'tz'} : '' );

    my $_epoch = time();

    ## (precedence: epoch -> date)
    if (exists $parm{epoch}) {
        $_epoch = $parm{epoch};
    }
    elsif ($parm{date}) {
        $_epoch = Date::Parse::str2time($parm{date});
    }
    else {
        # presume date
        $_epoch = Date::Parse::str2time((keys(%parm))[0]);
    }

    ## build/parse original date
    $_original = VSAP::Server::G11N::Date::Original->new($_epoch);

    ## build/parse GMT
    $_gmt = VSAP::Server::G11N::Date::GMT->new($_epoch);

    ## build parse localtime
    $_local = VSAP::Server::G11N::Date::Local->new($_epoch, $_tz);

    return 1;
}

# ----------------------------------------------------------------------------

sub original { return $_original; }
sub gmt      { return $_gmt;      }
sub local    { return $_local;    }

##############################################################################
package VSAP::Server::G11N::Date::GMT;
##############################################################################

sub new
{
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_)
      and return $self;

    return;
}

# ----------------------------------------------------------------------------

sub init
{
    my $self = shift;
    my $epoch = shift;

    return 1 unless $epoch;

    # gmt (year, month, day, hour, hour_12, minute, second)
    my (@_gmt) = gmtime($epoch);
    $self->{'scalar'}  = gmtime($epoch);
    $self->{'year'}    = $_gmt[5];
    $self->{'month'}   = $_gmt[4];
    $self->{'day'}     = $_gmt[3];
    $self->{'hour'}    = $_gmt[2];
    $self->{'minute'}  = $_gmt[1];
    $self->{'second'}  = $_gmt[0];
    $self->{'hour_12'} = ($_gmt[2] > 12 ? $_gmt[2]-12 : $_gmt[2]);
    $self->{'tz'}      = 'GMT';
    $self->{'offset'}  = '+0000';
    $self->{'year'}   += 1900;
    $self->{'month'}  += 1;

    return 1;
}

# ----------------------------------------------------------------------------

sub year    { $_[0]->{'year'};       }
sub month   { $_[0]->{'month'};      }
sub day     { $_[0]->{'day'};        }
sub hour    { $_[0]->{'hour'};       }
sub pm      { $_[0]->{'hour'} >= 12; }
sub minute  { $_[0]->{'minute'};     }
sub second  { $_[0]->{'second'};     }
sub hour_12 { $_[0]->{'hour_12'};    }
sub tz      { $_[0]->{'tz'};         }
sub offset  { $_[0]->{'offset'};     }
sub scalar  { $_[0]->{'scalar'};     }

##############################################################################
package VSAP::Server::G11N::Date::Local;
##############################################################################

sub new
{
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_)
      and return $self;

    return;
}

# ----------------------------------------------------------------------------

sub init
{
    my $self = shift;
    my $epoch = shift;
    my $tz_zone = shift;

    return 1 unless $epoch;

    # local (year, month, day, hour, hour_12, minute, second, tz, offset)
    local $ENV{'TZ'} = $tz_zone;
    my (@_local) = localtime($epoch);
    my $_local_tz = POSIX::tzname();
    my $_local_offset = VSAP::Server::G11N::Date::_offset_fmt(Time::Local::timegm(@_local) - Time::Local::timelocal(@_local));
    $self->{'scalar'}  = localtime($epoch);
    $self->{'year'}    = $_local[5];
    $self->{'month'}   = $_local[4];
    $self->{'day'}     = $_local[3];
    $self->{'hour'}    = $_local[2];
    $self->{'minute'}  = $_local[1];
    $self->{'second'}  = $_local[0];
    $self->{'hour_12'} = ($_local[2] > 12 ? $_local[2]-12 : $_local[2]);
    $self->{'tz'}      = $_local_tz;
    $self->{'offset'}  = $_local_offset;
    $self->{'year'}   += 1900;
    $self->{'month'}  += 1;

    return 1;
}

# ----------------------------------------------------------------------------

sub year    { $_[0]->{'year'};       }
sub month   { $_[0]->{'month'};      }
sub day     { $_[0]->{'day'};        }
sub hour    { $_[0]->{'hour'};       }
sub pm      { $_[0]->{'hour'} >= 12; }
sub minute  { $_[0]->{'minute'};     }
sub second  { $_[0]->{'second'};     }
sub hour_12 { $_[0]->{'hour_12'};    }
sub tz      { $_[0]->{'tz'};         }
sub offset  { $_[0]->{'offset'};     }
sub scalar  { $_[0]->{'scalar'};     }

##############################################################################
package VSAP::Server::G11N::Date::Original;
##############################################################################

sub new
{
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(@_)
      and return $self;

    return;
}

# ----------------------------------------------------------------------------

sub init
{
    my $self = shift;
    my $epoch = shift;

    return 1 unless $epoch;

    # original (year, month, day, hour, hour_12, minute, second, tz, offset)
    my (@_orig) = localtime($epoch);
    my $_orig_tz = POSIX::tzname();
    my $_orig_offset = VSAP::Server::G11N::Date::_offset_fmt(Time::Local::timegm(@_orig) - Time::Local::timelocal(@_orig));
    $self->{'scalar'}  = localtime($epoch);
    $self->{'year'}    = $_orig[5];
    $self->{'month'}   = $_orig[4];
    $self->{'day'}     = $_orig[3];
    $self->{'hour'}    = $_orig[2];
    $self->{'minute'}  = $_orig[1];
    $self->{'second'}  = $_orig[0];
    $self->{'hour_12'} = ($_orig[2] > 12 ? $_orig[2]-12 : $_orig[2]);
    $self->{'tz'}      = $_orig_tz;
    $self->{'offset'}  = $_orig_offset;
    $self->{'year'}   += 1900;
    $self->{'month'}  += 1;

    return 1;
}

# ----------------------------------------------------------------------------

sub year    { $_[0]->{'year'};       }
sub month   { $_[0]->{'month'};      }
sub day     { $_[0]->{'day'};        }
sub hour    { $_[0]->{'hour'};       }
sub pm      { $_[0]->{'hour'} >= 12; }
sub minute  { $_[0]->{'minute'};     }
sub second  { $_[0]->{'second'};     }
sub hour_12 { $_[0]->{'hour_12'};    }
sub tz      { $_[0]->{'tz'};         }
sub offset  { $_[0]->{'offset'};     }
sub scalar  { $_[0]->{'scalar'};     }

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::G11N::Date - Simple date conversions between timezones

=head1 SYNOPSIS

  use VSAP::Server::G11N::Date;

  my $date = new VSAP::Server::G11N::Date('Fri Mar  8 16:15:55 MST 2002');

  print "The local date is " . $date->local->date . "\n";

  print "The local year is " . $date->local->year . "\n";

=head1 DESCRIPTION

VSAP::Server::G11N::Date is a Perl class that will convert dates into the
desired (local) representation and GMT.

=over 4

=item B<new>

The constructor for this object. You may initialize it with epoch
seconds or a date string:

  $d = new VSAP::Server::G11N::Date(epoch => 1015631263);
  $d = new VSAP::Server::G11N::Date(date  => 'Fri Mar  8 16:47:42 MST 2002');
  $d = new VSAP::Server::G11N::Date('Fri Mar  8 16:47:42 MST 2002');  ## date is implied

You may also pass along a timezone that you prefer.

  ## use central european time regardless of $ENV{TZ}
  $d = new VSAP::Server::G11N::Date(date  => 'Fri Mar  8 16:47:42 MST 2002',
                                    tz    => 'CET' );

=back

=head1 SEE ALSO

Date::Parse(3)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
