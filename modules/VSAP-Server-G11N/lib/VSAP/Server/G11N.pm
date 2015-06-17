package VSAP::Server::G11N;

=head1 NAME

VSAP::Server::G11N - Base class for globalization methods

=head1 SYNOPSIS

use VSAP::Server::G11N;
my $g  = VSAP::Server::G11N->new(DEFAULT_ENCODING => 'UTF-8');

To subclass:

  use base 'VSAP::Server::G11N';

=head1 DESCRIPTION

C<VSAP::Server::G11N> is a base class which holds generic g11n methods.

=head1 METHODS

=cut

##############################################################################

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use strict;

use Carp qw(carp);
use Encode;

@ISA = qw(Exporter);

@EXPORT = qw();

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = "0.12";

##############################################################################

=pod

=head2  new()

     Purpose     : Create VSAP::Server::G11N object
     Parameters  : hash reference
                   {DEFAULT_ENCODING => 'UTF-8'}
     Returns     : Object
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    : Any parameter can be passed to new() to create a property on
                   the object. DEFAULT_ENCODING is meant to be a consistant one
                   across subclasses. This feature may change in the future.
                   The LAST_ERROR property is currently created to hold an error
                   message.

=cut

# ----------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my $args = shift;

    my $self = {};
    bless ($self, $class);

    $self->{'DEFAULT_ENCODING'} = $args->{'default_encoding'} || 'UTF-8';
    $self->{'LAST_ERROR'} = "";
    delete $args->{'default_encoding'};

    for my $arg (keys %$args) {
        $self->{"$arg"} = $args->{"$arg"};
    }

    return $self;
}

##############################################################################

=pod

=head2  convert()

     Purpose     : Encode from X to Y
     Parameters  : hash reference
                   {to_encoding => 'UTF-8',
                    from_encoding => 'ISO-2022-JP',
                    default_encoding => 'UTF-8', # optional
                    string => $string}
     Returns     : $scalar or undef
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    : Wrapper for Encode module

=cut

# ----------------------------------------------------------------------------

sub convert
{
    my $self = shift;
    my $args = shift;

    my $default_encoding = $args->{'default_encoding'} || "UTF-8";
    my $from_encoding = $args->{'from_encoding'} || $default_encoding;;
    my $to_encoding = $args->{'to_encoding'} || $default_encoding;;
    my $string = (ref $args->{'string'} eq 'SCALAR') ? ${$args->{'string'}} : $args->{'string'};

    # What happens here is this:
    # Perl's native encoding conversions use a flag on scalars to
    # indicate whether they are assumed utf-8 or not. This flag is set
    # by the decode() function, and unset by the encode() function. So
    # if we just return the same string when from and to encodings are the
    # same, we lose the flag that would otherwise be present, and introduce
    # wide character errors. The only solution I have found is to not
    # call convert in the first place, unfortunately.

    ## make sure we have a valid target encoding
    unless (Encode::resolve_alias($from_encoding)) {
        $from_encoding = 'UTF-8';
    }

    if (!$from_encoding) {
        #carp "No base encoding given";
        $self->{'LAST_ERROR'} = "No base encoding given";
        return undef;
    }
    elsif (!$to_encoding) {
        #carp "No to encoding given";
        $self->{'LAST_ERROR'} = "No to_encoding given";
        return undef;
    }
    elsif (!$string) {
        #carp "No string to convert given";
        $self->{'LAST_ERROR'} = "No string to convert given";
        return undef;
    }

    if ($to_encoding eq $from_encoding) {
        if ($to_encoding =~ /UTF\-8/i) {
            Encode::_utf8_on($string);
        }
        return $string;
    }

    my $encoded;
    # for sanity, we take a different approach with UTF-8
    if ($to_encoding =~ /^UTF-*8$/i) {
        $encoded = Encode::decode($from_encoding, $string);
        $encoded = Encode::encode_utf8($encoded);
    }
    elsif ($from_encoding =~ /^UTF-*8$/i) {
        #$encoded = Encode::from_to(
        $encoded = Encode::decode_utf8($string);
        $encoded = Encode::encode($to_encoding, $encoded);
    }
    else {
        $encoded = Encode::from_to($string, $from_encoding, $to_encoding);
    }

    if ($encoded) {
        return $encoded;
    }
    else {
        return undef;
    }
}

##############################################################################

=pod

=head2  replace_characters()

     Purpose     : Replace characters from a string with another
     Parameters  : hash reference
                   {string => $strinig,
                    extra => '\x00', # optional extra characters
                    no_default => 0, # or 1.. optional
                    new_char => 'X'} # optional, defaults to ?
     Returns     : $scalar
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    : This is meant to be used to convert certain characters to ?
                   when they do not display correctly. Currently the default
                   character(s) replaced are:
                   \x1B - Control character

                   Setting no_default to a true value will cause only what is in
                   'extra' to be substituted. In that case, may as well just use
                   a regular expression :) The 'new_char' arg will allow you to
                   override the default ? replacement character.

                   This is probably unused with the Iconv -> Encode conversion.

=cut

# ----------------------------------------------------------------------------

sub replace_characters
{
    my $self = shift;
    my $args = shift;

    my $string = $args->{'string'};
    my $extra = $args->{'extra'} || "";
    my $no_default = $args->{'no_default'} || 0;
    my $new_char = $args->{'new_char'} || "?";
    my $default_chars = qq{\x1B};

    if ($no_default) {
        $string =~ s![${extra}]!$new_char!g;
    }
    else {
        $string =~ s![${default_chars}${extra}]!$new_char!g;
    }

    return $string;
}

##############################################################################

1;
__END__

