package VSAP::Server::G11N::Mail;

=head1 NAME

VSAP::Server::G11N::Mail - Subclass for email g11n methods

=head1 SYNOPSIS

use VSAP::Server::G11N::Mail;
my $mail = VSAP::Server::G11N::Mail->new({DEFAULT_ENCODING => 'UTF-8'});

=head1 DESCRIPTION

C<VSAP::Server::G11N::Mail> is a subclass of C<VSAP::Server::G11N> which holds
email specific methods. These methods are used for getting (parsing) various
parts of an email message, as well as setting (creating) those same parts.  This
module will handle all appropriate base64 and quoted-printable (de|en)coding, as
well as charset conversions.

=head1 NOTES

The new() method is inherited from C<VSAP::Server::G11N>. Please read the
documentation for C<VSAP::Server::G11N>, if you haven't already.

The DEFAULT_ENCODING parameter of the new() method will be used in place of any
method which uses a 'default_encoding' paramenter, if it is not supplied. The
'default_encoding' parameter is optional, and should be used when a) there was
no DEFAULT_ENCODING specified with new(), and b) when you want to override what
is in DEFAULT_ENCODING.

=head1 METHODS

=cut

##############################################################################

use vars qw($VERSION);

use strict;

use utf8;
use Carp qw(carp);
use Encode;
use Encode::EUCJPMS;
use MIME::Base64;
use MIME::QuotedPrint;
use Mail::Address;
use constant DEBUG => 0;

use base 'VSAP::Server::G11N';

use VSAP::Server::Modules::vsap::string::encoding qw(guess_string_encoding);

$VERSION = "0.12";

##############################################################################
=pod

=head2  get_subject()

     Purpose     : Return decoded subject
     Parameters  : hash reference
                   {'to_encoding'      => 'UTF-8',
                    'default_encoding' => 'UTF-8', # optional
                    'subject'          => $string}
     Returns     : $scalar or undef
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub get_subject
{
    my $self             = shift;
    my $args             = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'};
    my $subject          = (ref $args->{'subject'} eq 'SCALAR') ? ${$args->{'subject'}} : $args->{'subject'};

    my $from_encoding = $default_encoding;

    my $decoded_subject = '';

    ## catch empty subjects (ends recursion)
    return '' unless $subject;

    ## decode an encoded subject (if applicable)
    $decoded_subject = "";
    if ($subject =~ /=\?/) {
        while ($subject =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*)?!!is) {
            my $at_front       = $1 || '';
            $from_encoding     = $2 || ''; # ISO-NNNN-XX
            my $mime_encoding  = $3 || ''; # B or Q
            my $encoded_string = $4 || '';
            my $leftover_bits  = $5 || '';
            print qq{\$encoded_string => $encoded_string\n} if DEBUG;
            print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;

            ## convert encodings into lower case (for convenience doing string compares)
            $from_encoding =~ tr/A-Z/a-z/;
            $mime_encoding =~ tr/A-Z/a-z/;

            ## B's and Q's need further decoding
            if ($mime_encoding eq 'b') {
                $encoded_string = MIME::Base64::decode_base64($encoded_string);
            }
            elsif ($mime_encoding eq 'q') {
                $encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
            }

            ## switch to use cp936
            if (($from_encoding eq 'gb2312') || ($from_encoding eq 'euc-cn')) {
                $from_encoding = "cp936";
            }

            ## swap "unknown-8bit" for "utf-8"
            if ($from_encoding eq 'unknown-8bit') {
                $from_encoding = "utf-8";
            }

            ## do the conversion
            my $decoded = $self->convert({'from_encoding'    => $from_encoding,
                                          'to_encoding'      => $to_encoding,
                                          'default_encoding' => $default_encoding,
                                          'string'           => $encoded_string});
            $at_front =~ s!^\s*!!;
            $decoded_subject .= $at_front . $decoded;

            ## recurse on leftover bits
            if ($leftover_bits) {
                $leftover_bits =~ s!\s*$!!;
                $decoded_subject .= $self->get_subject({'to_encoding'      => $to_encoding,
                                                        'default_encoding' => $default_encoding,
                                                        'subject'          => $leftover_bits});
            }

            if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
                $decoded_subject = $self->replace_characters({string => $decoded_subject});
            }
        }
        return $decoded_subject;
    }

    ## does string contain ctrl character?
    if ($subject =~ /\x1B/) {
        $decoded_subject = $self->convert({'from_encoding'    => $from_encoding,
                                           'to_encoding'      => $to_encoding,
                                           'default_encoding' => $default_encoding,
                                           'string'           => $subject});
        return $decoded_subject if ($decoded_subject);

        ## still here?  try the encoding for the message body?  harumph.
        if ($self->{BODY_ENCODING}) {
            $from_encoding = $self->{BODY_ENCODING};
            unless ($from_encoding = Encode::resolve_alias($from_encoding)) {
                $from_encoding = 'utf-8';
            }
            $decoded_subject = $self->convert({'from_encoding'    => $from_encoding,
                                               'to_encoding'      => $to_encoding,
                                               'default_encoding' => $default_encoding,
                                               'string'           => $subject});

            return $decoded_subject if ($decoded_subject);
        }

        ## still here?  take a guess.
        $decoded_subject = VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($subject);

        return($decoded_subject);
    }

    ## last sanity check
    if ($subject =~ /[[:^ascii:]]/ and ! Encode::is_utf8($subject, 1)) {
        ## remedial action. this will always work even on broken stuff
        ## (but it will rarely return the right encoding--it will look
        ## like the unencoded bytes in ascii)
        my $encoded = Encode::encode('UTF-8', $subject);
        $subject = Encode::decode('UTF-8', $encoded, Encode::FB_XMLCREF);
    }

    return($subject);
}

##############################################################################
=pod

=head2  set_subject()

     Purpose     : Create encoded subject line
     Parameters  : hash reference
                   {'to_encoding'      => 'UTF-8',
                    'from_encoding'    => 'ISO-2022-JP',
                    'default_encoding' => 'UTF-8', # optional
                    'subject'          => $string}
     Returns     : $scalar or undef
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub set_subject
{
    my $self             = shift;
    my $args             = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'} || "UTF-8";
    my $from_encoding    = $args->{'from_encoding'} || "UTF-8";
    my $subject          = (ref($args->{'subject'}) eq 'SCALAR') ? ${$args->{'subject'}} : $args->{'subject'};

    return '' unless $subject;

    $default_encoding =~ tr/A-Z/a-z/;
    $to_encoding =~ tr/A-Z/a-z/;
    $from_encoding =~ tr/A-Z/a-z/;

    my $encoded_subject = '';

    ## since most users will have default ASCII, this is a check to force
    ## utf-8 if the string contains non-ascii chars.
    if (($to_encoding =~ /ascii/i) && ($subject =~ /[[:^ascii:]]/)) {
        $to_encoding = "utf-8";
        ## add the utf8 flag to this string unless it has it already
        unless (utf8::is_utf8($subject)) {
            $subject = Encode::decode_utf8($subject);
        }
    }
    elsif ($subject =~ /^[[:ascii:]]+$/) {
        ## plain ascii should be left as plain ascii
        return $subject;
    }

    ## check for non-existent encoding
    unless ($to_encoding = Encode::resolve_alias($to_encoding)) {
        $to_encoding = 'utf-8';
    }

    if ($to_encoding =~ /^big5-eten/) {
        ## BIG5 (traditional) is a case where mail clients need a lie,
        ## because Perl's Encode forces too much strictness with
        ## regards to naming the encoding. It's not *real* BIG5
        ## (it's the MS variant), but ubiquity here prevails.
        $to_encoding = 'BIG5';
        ## Encode is smart enough to know what this means, but we
        ## preserve the name for use in the MIME.
    }

    $to_encoding =~ s/utf8/utf-8/i;
    $to_encoding =~ s/\-strict//i;

    if ($to_encoding eq 'us-ascii') {
        ## pass thru
        $encoded_subject = $subject;
    }
    elsif ($to_encoding =~ /\b8859\b/) {
        ## any iso-8859 gets qp
        my $encoded_string = MIME::QuotedPrint::encode_qp($encoded_subject);
        $encoded_string =~ s/[\r\n]$//g;
        $encoded_subject = qq{=?$to_encoding?Q?$encoded_string?=};
    }
    else {
        my $encode_encoding = $to_encoding;

        ## switch to use cp936
        if (($to_encoding eq 'gb2312') || ($to_encoding eq 'euc-cn')) {
            $encode_encoding = "cp936" ;
            $to_encoding = "gb2312" ;
        }

        $encoded_subject = Encode::encode($encode_encoding, $subject);

        ## check for characters not found in character encoding map
        if ($encoded_subject =~ /\\x\{[0-9a-zA-Z]{4}\}/) {
            if ($to_encoding eq 'iso-2022-jp') {
                ## try cp936 encoding when failed with iso-2022-jp
                $encode_encoding = "cp936";
                $to_encoding = "gb2312";
                $encoded_subject = Encode::encode($encode_encoding, $subject);
            }
        }

        my $encoded_string = MIME::Base64::encode_base64($encoded_subject, "");
        $encoded_string =~ s/[\r\n]$//g;
        $encoded_subject = qq{=?$to_encoding?B?$encoded_string?=};
    }
    return $encoded_subject;
}

##############################################################################
=pod

=head2  get_address()

     Purpose     : Return a decoded email address phrase
     Parameters  : hash reference
                   {'to_encoding'      => 'ISO-2022-JP',
                    'default_encoding' => 'UTF-8',
                    'address'          => [$address1, $address2]}
     Returns     : array ref of decoded addresses. undef for failed addresses.
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub get_address
{
    my $self             = shift;
    my $args             = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'};
    my $address_ref      = $args->{'address'};

    my $from_encoding = $default_encoding;

    my @return_address = ();
    my $decoded_address;

    for my $address (@$address_ref) {
        $decoded_address = '';
        if ($address =~ /=\?/) {
            while ($address =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*)!!is) {
                my $at_front       = $1 || '';
                $from_encoding     = $2 || ''; # ISO-NNNN-XX
                my $mime_encoding  = $3 || ''; # B or Q
                my $encoded_string = $4 || '';;
                my $leftover_bits  = $5 || "";
                print qq{\$encoded_string => $encoded_string\n} if DEBUG;
                print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;

                ## convert encodings into lower case (for convenience doing string compares)
                $from_encoding =~ tr/A-Z/a-z/;
                $mime_encoding =~ tr/A-Z/a-z/;

                ## B's and Q's need further decoding
                if ($mime_encoding eq 'b') {
                    $encoded_string = MIME::Base64::decode_base64($encoded_string);
                }
                elsif ($mime_encoding eq 'q') {
                    $encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
                }

                ## switch to use cp936
                if (($from_encoding eq 'gb2312') || ($from_encoding eq 'euc-cn')) {
                    $from_encoding = "cp936";
                }

                ## swap "unknown-8bit" for "utf-8"
                if ($from_encoding eq 'unknown-8bit') {
                    $from_encoding = "utf-8";
                }

                ## do the conversion
                my $decoded = $self->convert({'from_encoding'    => $from_encoding,
                                              'to_encoding'      => $to_encoding,
                                              'default_encoding' => $default_encoding,
                                              'string'           => $encoded_string}) || '';
                $at_front =~ s!^\s*!!;
                $decoded_address .= $at_front . $decoded;

                ## recurse on leftover bits
                if ($leftover_bits) {
                    $leftover_bits =~ s!\s*$!!;
                    my $sub_phrase = $self->get_address({'to_encoding' => $to_encoding,
                                                         'default_encoding' => $default_encoding,
                                                         'address' => [$leftover_bits]});
                    $decoded_address .= $sub_phrase->[0];
                }

                if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
                    $decoded_address = $self->replace_characters({string => $decoded_address});
                }
            }
            push(@return_address, $decoded_address);
            next;
        }

        ## does string contain ctrl character?
        if ($address =~ /\x1B/) {
            $decoded_address = $self->convert({'from_encoding'    => $default_encoding,
                                               'to_encoding'      => $to_encoding,
                                               'default_encoding' => $default_encoding,
                                               'string'           => $address});
            if ($decoded_address) {
                push(@return_address, $decoded_address);
                next;
            }

            ## still here?  try the encoding for the message body?  harumph.
            if ($self->{BODY_ENCODING}) {
                $from_encoding = $self->{BODY_ENCODING};
                unless ($from_encoding = Encode::resolve_alias($from_encoding)) {
                    $from_encoding = 'utf-8';
                }
                $decoded_address = $self->convert({'from_encoding'    => $default_encoding,
                                                   'to_encoding'      => $to_encoding,
                                                   'default_encoding' => $default_encoding,
                                                   'string'           => $address});
                if ($decoded_address) {
                    push(@return_address, $decoded_address);
                    next;
                }
            }

            ## still here?  take a guess.
            $decoded_address = VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($address);

            push(@return_address, $decoded_address);
            next;
        }

        ## last sanity check
        if ($address =~ /[[:^ascii:]]/ and ! Encode::is_utf8($address, 1)) {
            ## remedial action. This will always work even on broken stuff
            ## (but it will rarely return the right encoding--it will look
            ## like the unencoded bytes in ascii
            my $encoded = Encode::encode('UTF-8', $address);
            $address = Encode::decode('UTF-8', $encoded, Encode::FB_XMLCREF);
        }
        push @return_address, $address;
    }

    return \@return_address;
}

##############################################################################
=pod

=head2  set_address()

     Purpose     : Return an encoded email address (phrase)
     Parameters  : hash ref
                   {'to_encoding'      => 'ISO-8859-1',
                    'from_encoding'    => 'UTF-8',
                    'default_encoding' => 'UTF-8',
                    'address'          => [$address1, $address2]}
     Returns     : array reference of encoded email addresses. undef for failed ones.
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub set_address
{
    my $self             = shift;
    my $args             = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'} || "UTF-8";
    my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $address_ref      = $args->{'address'}; # array ref

    $default_encoding =~ tr/A-Z/a-z/;
    $to_encoding =~ tr/A-Z/a-z/;
    $from_encoding =~ tr/A-Z/a-z/;

    my @return_address = ();

    for my $address (@$address_ref) {
        if (!$address) {
            push(@return_address, undef);
            next;
        }
        my $ma = (Mail::Address->parse($address))[0];

        if ($ma->phrase) {
            my $encoded_phrase = $self->set_subject({'to_encoding'  => $to_encoding,
                                                     'from_encoding' => $from_encoding,
                                                     'subject'      => $ma->phrase});
            $encoded_phrase =~ s!\n!!g;
            push(@return_address, $encoded_phrase . " <" . $ma->address . ">");
        }
        else {
            push(@return_address, $address);
        }
    }
    return \@return_address;
}

##############################################################################
=pod

=head2  get_attachment_name()

     Purpose     : Return decoded attachment filenames.
     Parameters  : hash reference
                   {'to_encoding'      => 'Shift_JIS',
                    'from_encoding'    => 'UTF-8',
                    'default_encoding' => 'UTF-8',
                    'attachments'      => [$file1, $file2]}
     Returns     : array ref of decoded filenames. undef for failed ones.
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub get_attachment_name
{
    my $self = shift;
    my $args = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'};
    my $attachment_ref   = $args->{'attachments'};

    my $from_encoding = $default_encoding;

    my @return_attachments = ();
    my $decoded_filename;

    for my $attachment (@$attachment_ref) {
        $decoded_filename = '';
        if ($attachment =~ /=\?/) {
            while ($attachment =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*?)!!is) {
                my $at_front       = $1 || '';
                $from_encoding     = $2 || ''; # ISO-NNNN-XX
                my $mime_encoding  = $3 || ''; # B or Q
                my $encoded_string = $4 || '';
                my $leftover_bits  = $5 || '';
                print qq{\$encoded_string => $encoded_string\n} if DEBUG;
                print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;

                ## convert encodings into lower case (for convenience doing string compares)
                $from_encoding =~ tr/A-Z/a-z/;
                $mime_encoding =~ tr/A-Z/a-z/;

                ## B's and Q's need further decoding
                if ($mime_encoding eq 'b') {
                    $encoded_string = MIME::Base64::decode_base64($encoded_string);
                }
                elsif ($mime_encoding eq 'q') {
                    $encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
                }

                ## switch to use cp936
                if (($from_encoding eq 'gb2312') || ($from_encoding eq 'euc-cn')) {
                    $from_encoding = "cp936";
                }

                ## swap "unknown-8bit" for "utf-8"
                if ($from_encoding eq 'unknown-8bit') {
                    $from_encoding = "utf-8";
                }

                ## do the conversion
                my $decoded = $self->convert({from_encoding    => $from_encoding,
                                              to_encoding      => $to_encoding,
                                              default_encoding => $default_encoding,
                                              string           => $encoded_string}) || '';
                $at_front =~ s!^\s*!!;
                $decoded_filename .= $at_front . $decoded;

                ## recurse on leftover bits
                if ($leftover_bits) {
                    $leftover_bits =~ s!\s*$!!;
                    my $sub_phrase = $self->get_attachment({to_encoding => $to_encoding,
                                                            default_encoding => $default_encoding,
                                                            attachments => [$leftover_bits]});
                    $decoded_filename .= $sub_phrase->[0];
                }

                if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
                    $decoded_filename = $self->replace_characters({string => $decoded_filename});
                }
            }

            push(@return_attachments, $decoded_filename);
            next;
        }

        ## does string contain ctrl character?
        if ($attachment =~ /\x1B/) {
            $decoded_filename = $self->convert({'from_encoding'    => $default_encoding,
                                                'to_encoding'      => $to_encoding,
                                                'default_encoding' => $default_encoding,
                                                'string'           => $attachment});
            if ($decoded_filename) {
                push(@return_attachments, $decoded_filename);
                next;
            }

            ## still here?  try the encoding for the message body?  harumph.
            if ($self->{BODY_ENCODING}) {
                $from_encoding = $self->{BODY_ENCODING};
                unless ($from_encoding = Encode::resolve_alias($from_encoding)) {
                    $from_encoding = 'utf-8';
                }
                $decoded_filename = $self->convert({'from_encoding'    => $default_encoding,
                                                    'to_encoding'      => $to_encoding,
                                                    'default_encoding' => $default_encoding,
                                                    'string'           => $attachment});
                if ($decoded_filename) {
                    push(@return_attachments, $decoded_filename);
                    next;
                }
            }

            ## still here?  take a guess.
            $decoded_filename = VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($attachment);

            push(@return_attachments, $decoded_filename);
            next;
        }

        ## last sanity check
        if ($attachment =~ /[[:^ascii:]]/ and ! Encode::is_utf8($attachment, 1)) {
            ## remedial action. This will always work even on broken stuff
            ## (but it will rarely return the right encoding--it will look
            ## like the unencoded bytes in ascii
            my $encoded = Encode::encode('UTF-8', $attachment);
            $attachment = Encode::decode('UTF-8', $encoded, Encode::FB_XMLCREF);
        }
        push @return_attachments, $attachment;

    }

    return \@return_attachments;

}

##############################################################################
=pod

=head2  set_attachment_name()

     Purpose     : Return an encoded attachment filename
     Parameters  : hash ref
                   {'to_encoding'      => 'ISO-8859-1',
                    'from_encoding'    => 'UTF-8',
                    'default_encoding' => 'UTF-8',
                    'attachments'      => [$file1, $file2]}
     Returns     : array reference of encoded attachment filenames.  Undef for failed ones.
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ----------------------------------------------------------------------------

sub set_attachment_name
{
    my $self = shift;
    my $args = shift;
    my $default_encoding  = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding       = $args->{'to_encoding'} || "UTF-8";
    my $from_encoding     = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $mime_encoding     = $args->{'mime_encoding'}; # How to encode? B, Q, none
    my $filename_encoding = $args->{'filename_encoding'}; # MIME, US-ASCII, RFC2231
    my $attachment_ref    = $args->{'attachments'};

    my $encoded_string;
    my $encoded_filename;
    my $return_filename;

    my @return_attachments = ();

    $from_encoding =~ tr/A-Z/a-z/;
    $mime_encoding =~ tr/A-Z/a-z/;

    for my $attachment (@$attachment_ref) {
        $encoded_filename = $self->convert({'from_encoding'    => $from_encoding,
                                            'to_encoding'      => $to_encoding,
                                            'default_encoding' => $default_encoding,
                                            'string'           => $attachment});

        if ($mime_encoding eq 'b') {
            $encoded_string = MIME::Base64::encode_base64($encoded_filename, "");
        }
        elsif ($mime_encoding eq 'q') {
            $encoded_string = MIME::QuotedPrint::encode_qp($encoded_filename);
        }
        else {
            $encoded_string = $encoded_filename;
        }

        $encoded_string =~ s!\n!!g;
        chomp($encoded_string);

        if ($filename_encoding =~ /^MIME$/i) {
            $return_filename = qq{=?$to_encoding?$mime_encoding?$encoded_string?=};
            push(@return_attachments, $return_filename);
        }
        elsif ($filename_encoding =~ /^RFC2231$/i) {
            $return_filename = qq{*0=$to_encoding''$encoded_string};
            push(@return_attachments, $return_filename);
        }
        else {
            push(@return_attachments, $encoded_string);
        }
    }
    return \@return_attachments;
}

##############################################################################
=pod

=head2  get_body()

     Purpose     : Return message body base64/quoted-printable decoded (if needed)
     Parameters  : hash ref
                   {'to_encoding'      => 'US-ASCII',
                    'from_encoding'    => 'UTF-8',
                    'default_encoding' => 'US-ASCII',
                    'content_encoding' => 'B'}
     Returns     : scalar of body contents, undef on failure.
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    : content_encoding B<must> be B, Q or something else. Only B and Q
                   are recognized to do appropriate decoding.
                   B - base64
                   Q - quoted-printable
                   others - no decoding done

                   This can be obtained via the message header: Content-Transfer-Encoding

=cut
# ----------------------------------------------------------------------------

sub get_body
{
    my $self             = shift;
    my $args             = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'} || "UTF-8";
    my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $content_encoding = $args->{'content_encoding'} || ''; # B or Q or ''
    my $body             = $args->{'string'};

    my $decoded_body = '';

    $from_encoding =~ tr/A-Z/a-z/;
    $content_encoding =~ tr/A-Z/a-z/;

    if ($content_encoding eq 'b') {
        $decoded_body = MIME::Base64::decode_base64($body);
    }
    elsif ($content_encoding eq 'q') {
        $decoded_body = MIME::QuotedPrint::decode_qp($body);
    }
    else {
        $decoded_body = $body;
    }

    ## try to find an encoding in the HTML
    if ($decoded_body =~ m#<meta\b.*content-type.*\bcharset="?([^\>\"]+)#i) {
        $from_encoding = $1;
    }

    ## check for non-existent encoding
    unless ($from_encoding = Encode::resolve_alias($from_encoding)) {
        $from_encoding = 'UTF-8';
    }

    my $decoded = '';

    ## switch to use cp936
    if (($from_encoding eq 'gb2312') || ($from_encoding eq 'euc-cn')) {
        $from_encoding = "cp936";
    }

    ## swap "unknown-8bit" for "utf-8"
    if ($from_encoding eq 'unknown-8bit') {
        $from_encoding = "utf-8";
    }

    ## switch to use cp936
    if ( $from_encoding eq 'euc-cn' ) {
        $from_encoding = "cp936";
    }

    ## convert octets in $from_encoding to Perl's internal form
    my $octets = $decoded_body;
    eval {
        $octets = Encode::decode($from_encoding, $decoded_body);
    };

    ## convert data in Perl's internal form to $to_encoding octets
    $decoded = Encode::encode($to_encoding, $octets);

    ## does string contain ctrl character?
    if ($decoded =~ /\x{1B}/) {
        ## take a guess.
        $decoded = VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($decoded_body);
    }

    $self->{'BODY_ENCODING'} = $from_encoding;

    ## this is not the same as decode_utf8($decoded)!
    return(Encode::decode('UTF-8', $decoded));
}

##############################################################################
=pod

=head2  set_body()

     Purpose     : Create message body with proper encodings.
     Parameters  : hash ref
                   {'to_encoding' => 'ISO-2022-JP',
                    'from_encoding' => 'UTF-8',
                    'default_encoding' => 'UTF-8',}
     Returns     : hash ref, or undef on failure
                   {string => $new_body, encoding '7bit'}
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    : The returned 'encoding' should be used for the message
                   header: Content-Transfer-Encoding

=cut

# ----------------------------------------------------------------------------
# - if to_encoding is ascii and contains utf8, *upgrade to utf8*
# - if to_encoding is ascii and contains only ascii, *do no conversion*
# - if to_encoding is utf8, *do no conversion*
# - if to_encoding is set to *any* other non-ascii/utf8 supported encoding,
#   AND all UTF-8 characters can convert to to_encoding, *convert*
# - if to_encoding is set to *any* other non-ascii/utf8 supported encoding,
#   AND the message contains UTF-8 glyphs that do not map into to_encoding,
#   *use Encoding to convert what we can; remaining glyphs will be changed to 0xFFFD
# ----------------------------------------------------------------------------

sub set_body
{
    my $self = shift;
    my $args = shift;
    my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $to_encoding      = $args->{'to_encoding'} || "UTF-8";
    my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
    my $body             = $args->{'string'};

    return '' unless $body;

    $default_encoding =~ tr/A-Z/a-z/;
    $to_encoding =~ tr/A-Z/a-z/;
    $from_encoding =~ tr/A-Z/a-z/;

    my $encoded_body = '';

    ## since most users will have default ASCII, this is a check to force
    ## utf-8 if the string contains non-ascii chars.
    if (($to_encoding =~ /ASCII/i) && ($body =~ /[[:^ascii:]]/)) {
         $to_encoding = 'utf-8';
         unless (utf8::is_utf8($body)) {
             $body = Encode::decode_utf8($body);
         }
    }
    elsif ($body =~ /^[[:ascii:]]+$/) {
        ## plain ascii should be left as plain ascii
        $to_encoding = "US-ASCII";
    }

    ## check for non-existent encoding
    unless( $to_encoding = Encode::resolve_alias($to_encoding) ) {
        $to_encoding = 'utf-8';
    }

    if ($to_encoding =~ /^big5-eten/) {
        ## BIG5 (traditional) is a case where mail clients need a lie,
        ## because Perl's Encode forces too much strictness with
        ## regards to naming the encoding. It's not *real* BIG5
        ## (it's the MS variant), but ubiquity here prevails.
        $to_encoding = 'BIG5';
        ## Encode is smart enough to know what this means, but we
        ## preserve the name for use in the MIME.
    }

    $to_encoding =~ s/utf8/utf-8/i;
    $to_encoding =~ s/\-strict//i;

    ## set the transfer_encoding
    my $transfer_encoding = '8bit';
    if ($to_encoding =~ /(iso\-2022\-|US\-ASCII)/i) {
        $transfer_encoding = '7bit';
    }

    my $encode_encoding = $to_encoding;

    ## switch to use cp936
    if (($to_encoding eq 'gb2312') || ($to_encoding eq 'euc-cn')) {
        $encode_encoding = "cp936" ;
        $to_encoding = "gb2312" ;
    }

    ## encode the body
    if ($to_encoding eq 'iso-2022-jp') {
        ## hack for MS Windows unicode mapping (BUG24616)
        ## if (encoding to cp50221) successful 
        ##   then assume data originated from MS windows
        ## else
        ##   then assume data originated from mac or unix client
        my $body_copy = $body;
        $encode_encoding = "cp50221";
        $body_copy =~ s/\x{301c}/\x{ff5e}/g;
        $encoded_body = eval { Encode::encode($encode_encoding, $body_copy, 1); };
        if (($@ ne "") || ($encoded_body =~ /\x{1B}/)) {
            $encode_encoding = $to_encoding;
            $encoded_body = Encode::encode($encode_encoding, $body, 0);
        }
    }
    else {
        $encoded_body = Encode::encode($encode_encoding, $body, 0);
    }

    ## try cp936 encoding when failed with iso-2022-jp
    if ($encoded_body =~ /\\x\{[0-9a-zA-Z]{4}\}/) {
        if ($to_encoding eq 'iso-2022-jp' ) {
            ## try cp936 encoding when failed with iso-2022-jp
            $encode_encoding = "cp936";
            $to_encoding = "gb2312";
            $encoded_body = Encode::encode($encode_encoding, $body, 1);
            $transfer_encoding = '8bit';
        }
    }

    return( defined($encoded_body) ?  
              { string => $encoded_body,
                encoding => $transfer_encoding,
                enc => $encode_encoding,
                charset  => $to_encoding }
              : undef );

}

##############################################################################
1;

