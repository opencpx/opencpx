package VSAP::Server::G11N::Mail;


=head1 NAME

VSAP::Server::G11N::Mail - Subclass for email g11n methods

=head1 SYNOPSIS

    use VSAP::Server::G11N::Mail;
    
    my $mail = VSAP::Server::G11N::Mail->new({DEFAULT_ENCODING => 'UTF-8'});

=head1 DESCRIPTION

C<VSAP::Server::G11N::Mail> is a subclass of C<VSAP::Server::G11N> which holds email specific 
methods. These methods are used for getting (parsing) various parts of an email
message, as well as setting (creating) those same parts. This module will handle
all appropriate base64 and quoted-printable (de|en)coding, as well as charset
conversions.

=head1 NOTES

The new() method is inherited from C<VSAP::Server::G11N>. Please read the documentation
for C<VSAP::Server::G11N>, if you haven't already. 

The DEFAULT_ENCODING parameter of the new() method will be used in place of any
method which uses a 'default_encoding' paramenter, if it is not supplied. The
'default_encoding' parameter is optional, and should be used when a) there was
no DEFAULT_ENCODING specified with new(), and b) when you want to override what
is in DEFAULT_ENCODING.

=head1 REQUIRED LIBRARIES

        Native      : strict
                    : vars
                    : base
                    : constant
                    : Carp
                    : VSAP::Server::G11N 

        CPAN        : MIME::Base64
                    : MIME::QuotedPrint 
                    : Mail::Address 


=head1 MAJOR REVISIONS

	* Feb, 2002 - Initial Creation.

=head1 ENVIRONMENTAL SETTINGS

    None

=head1 METHODS

=cut

use utf8;
use Encode;
use Encode::EUCJPMS;
use vars qw($VERSION $CVS_VERSION);
use strict;
use Carp qw(carp);
use base 'VSAP::Server::G11N';
use constant DEBUG => 0;

$VERSION = "0.1";

use MIME::Base64;
use MIME::QuotedPrint;
use Mail::Address;

# ------------------------------------------------------------------------------
=pod

=head2  get_subject()

     Purpose     : Return decoded subject
     Parameters  : hash reference
		   {to_encoding => 'UTF-8',
		    default_encoding => 'UTF-8', # optional
		    subject => $string}
     Returns     : $scalar or undef
     Author/Date : Kevin Meltzer, Feb. 2002
     Comments    :

=cut
# ------------------------------------------------------------------------------

sub get_subject {
	my $self             = shift;
	my $args             = shift;
	my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
	my $to_encoding      = $args->{'to_encoding'};
	my $subject          = (ref $args->{'subject'} eq 'SCALAR') ? ${$args->{'subject'}} : $args->{'subject'};
	my $from_encoding = $default_encoding;
	my $return_subject;

	return $subject unless $subject;  ## catch empty subjects

	# Is the subject encoded? If so, how?
      DECODE: {
	    last DECODE unless $subject =~ /=\?/;

	    while ($subject =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*)?!!is) { 
		my $new_subject    = $1;
		$from_encoding     = $2; # ISO-NNNN-XX
		my $mime_encoding  = $3; # B or Q
		my $encoded_string = $4;
		print qq{\$encoded_string => $encoded_string\n} if DEBUG;
		print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;

		# convert encodings into lower case (for convenience doing string compares)
		$from_encoding =~ tr/A-Z/a-z/;
		$mime_encoding =~ tr/A-Z/a-z/;
		
                # B's and Q's need further checking
		if ( $mime_encoding eq 'b') {
			$encoded_string = MIME::Base64::decode_base64($encoded_string);
		} elsif ( $mime_encoding eq 'q') {
			$encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
		}

		# switch to use cp936
		if ( $from_encoding eq 'GB2312' || $from_encoding eq 'gb2312' || $from_encoding eq 'euc-cn' ) {
			$from_encoding = "cp936" 
		}

		# swap "unknown-8bit" for "utf-8" (BUG26930)
		if ( $from_encoding eq 'unknown-8bit' ) {
			$from_encoding = "utf-8";
		}

		if ($encoded_string) {
			$new_subject .= $self->convert({from_encoding    => $from_encoding,
							to_encoding      => $to_encoding,
							default_encoding => $default_encoding,
							string           => $encoded_string});
		}

		$new_subject .= $self->get_subject({'to_encoding' => $to_encoding,
						    'default_encoding' => $default_encoding,
						    'subject' => $5});
		$new_subject =~ s!^\s+!!;

		if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
			$new_subject = $self->replace_characters({string => $new_subject});
		}

		$return_subject .= $new_subject;
	    } 
	} ## DECODE

	## successfully decoded
	return $return_subject if $return_subject;

	## try the encoding that worked for the body
	if( $self->{USED_BODY_ENCODING} ) {
	    $from_encoding = $self->{USED_BODY_ENCODING};
	    unless( $from_encoding = Encode::resolve_alias($from_encoding) ) {
		$from_encoding = 'UTF-8';
	    }

	    my $octets = '';
	  DO_ENCODE: {
		## convert octets in $from_encoding to Perl's internal form
	        my $stuff = $subject;
	        eval{
		    $stuff = Encode::decode($from_encoding, $subject);
	        };

		## convert data in Perl's internal form to $to_encoding octets
		$octets = Encode::encode($to_encoding, $stuff);

		## scott- this is the only real hack we have; it works
		## most of the time. I suspect we'll still get others
		## that would break; we can account for them in this way.
		if( $octets =~ /\x{1B}/ ) {
		    if( $from_encoding eq 'ISO-2022-JP' ) {
			last DO_ENCODE;
		    }
		    $from_encoding = 'ISO-2022-JP';
		    redo DO_ENCODE;
		}
	    }
	    return $octets;
	}

	## remedial action. This will always work even on broken stuff
	## (but it will rarely return the right encoding--it will look
	## like the unencoded bytes in ascii
	if( $subject =~ /[[:^ascii:]]/ and ! Encode::is_utf8($subject, 1) ) {
	    my $tmp = Encode::encode('UTF-8', $subject);
	    $subject = Encode::decode('UTF-8', $tmp, Encode::FB_XMLCREF);
	}
	return $subject;
}

# ------------------------------------------------------------------------------
=pod

=head2  set_subject()

     Purpose     : Create encoded subject line
     Parameters  : hash reference 
                   {to_encoding => 'UTF-8',
		    from_encoding => 'ISO-2022-JP', 
                    default_encoding => 'UTF-8', # optional
                    subject => $string}
     Returns     : $scalar or undef 
     Author/Date : Kevin Meltzer, Feb. 2002 
     Comments    :

=cut
# ------------------------------------------------------------------------------

sub set_subject {
        my $self             = shift;
        my $args             = shift;
        my $to_encoding      = $args->{'to_encoding'} || "UTF-8"; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $subject          = ( ref($args->{'subject'}) eq 'SCALAR'
				 ? ${$args->{'subject'}}
				 : $args->{'subject'} );
	my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $from_encoding    = $args->{'from_encoding'} || "UTF-8";

	return '' unless $subject;

        # since most users will have default ASCII, this is a check to force
        # utf-8 if the string contains non-ascii chars.  
        if ($to_encoding =~ /ASCII/i && $subject =~ /[[:^ascii:]]/) {
	    $to_encoding = "UTF-8";

	    ## add the utf8 flag to this string unless it has it already
	    unless( utf8::is_utf8($subject) ) {
		$subject = Encode::decode_utf8($subject);
	    }
        }
	## plain ascii should be left as plain ascii
	elsif( $subject =~ /^[[:ascii:]]+$/ ) {
	    return $subject;
	}

	## canonical encoding name
	unless( $to_encoding = Encode::resolve_alias($to_encoding) ) {
	    $to_encoding = 'UTF-8';
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
	my $return_subject = '';
	if( $to_encoding eq 'US-ASCII' ) {
	    ## pass thru
	}
	elsif( $to_encoding =~ /\b8859\b/ ) {  ## any iso-8859 gets qp
	    $return_subject = Encode::encode( $to_encoding, $subject );
	    my $encoded_string = MIME::QuotedPrint::encode_qp( $return_subject );
	    $encoded_string =~ s/[\r\n]$//g;
	    $return_subject = qq{=?$to_encoding?Q?$encoded_string?=};
	}
	else {
	    my $to_enc = $to_encoding;
	    my $subject_orig = $subject; 

	    # switch to use cp936
	    if ( $to_encoding eq 'euc-cn' || $to_encoding eq 'gb2312' ) {
	        $to_enc = "cp936" ;
	        $to_encoding = "gb2312" ;
	    }

	    # Hack for Windows-Unicode mapping (BUG24616)
	    # encoding to cp50221 was succeeded -> assumed windows mapping
	    # failed -> mac or unix. Take legacy encoding.
	    if ( $to_encoding eq 'iso-2022-jp' ){
		$subject_orig =~ s/\x{301c}/\x{ff5e}/g;
	        $return_subject = eval { Encode::encode( "cp50221", $subject_orig, 1 ); };
		if ( $@ ne "" | $return_subject =~ /\\x{/ ) {
		    $return_subject = Encode::encode( $to_enc, $subject );
		};
	     } else {
		 $return_subject = Encode::encode( $to_enc, $subject );
	     };		     
	
	    # try cp936 encoding when failed with iso-2022-jp
	    if ( $return_subject =~ /\\x{/ ) {
		if ( $to_encoding eq 'iso-2022-jp' ) {
		    $to_enc = "cp936"; # real encoding
		    $to_encoding = "gb2312";
		    $return_subject = Encode::encode( $to_enc, $subject_orig );
		}
	    }

	    my $encoded_string = MIME::Base64::encode_base64( $return_subject, "" );
	    $encoded_string =~ s/[\r\n]$//g;
	    $return_subject = qq{=?$to_encoding?B?$encoded_string?=};
	}
	return $return_subject;
}

# ------------------------------------------------------------------------------
=pod

=head2  get_address()

     Purpose     : Return a decoded email address phrase
     Parameters  : hash reference
		   {'to_encoding' => 'ISO-2022-JP',
	            'default_encoding' => 'UTF-8',
                    'address' => [$address1, $address2]}
     Returns     : array ref of decoded addresses. undef for failed addresses.    
     Author/Date : Kevin Meltzer, Feb. 2002 
     Comments    :

=cut
# ------------------------------------------------------------------------------

sub get_address {
	my $self             = shift;
	my $args             = shift;
	my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $address_ref      = $args->{'address'}; # array ref
        my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'}; 

	my $from_encoding    = $default_encoding;
	my $mime_encoding;
	my $encoding_string;
	my $encoded_string;
	my @return_address;
	my $new_address;

	for my $address (@$address_ref) {
	        # Is the address encoded? If so, how?
		# KM: Changed line below slightly from above. retest to see if I can
		# move out to share code
       		while ($address =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*)!!is) {
		        my $at_front   = $1 || '';
                	$from_encoding = $2 || ''; # ISO-NNNN-XX
                	$mime_encoding = $3 || ''; # B or Q - 8
                	$encoded_string = $4 || '';;
			my $at_end = $5 || "";
                	print qq{\$encoded_string => $encoded_string\n} if DEBUG;
			print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;

			# convert encodings into lower case (for convenience doing string compares)
			$from_encoding =~ tr/A-Z/a-z/;
			$mime_encoding =~ tr/A-Z/a-z/;
		
                	if ($mime_encoding eq 'b') {
                        	$encoded_string = MIME::Base64::decode_base64($encoded_string);
                	} elsif ($mime_encoding eq 'q') {
                        	$encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
                	}

                	my $conv = $self->convert({from_encoding    => $from_encoding,
						   to_encoding      => $to_encoding,
						   default_encoding => $default_encoding,
						   string           => $encoded_string})
			  || '';
			$new_address .= $at_front . $conv;

			if ($at_end) {
				$at_end =~ s!^\s+!!;
				my $sub_phrase = $self->get_address({default_encoding => $default_encoding,
						    	  	     address => [$at_end],
						    		     to_encoding => $to_encoding});
				$new_address .= $sub_phrase->[0];
			}

			if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
				$new_address = $self->replace_characters({string => $new_address});
			}
        	}

		## if encoding was successful, push it here.
		if ($new_address) {
		    push(@return_address, $new_address);
		    next;
		}

		## do we have a body encoding we can try?
		if( $self->{USED_BODY_ENCODING} ) {
		    $from_encoding = $self->{USED_BODY_ENCODING};
		    unless( $from_encoding = Encode::resolve_alias($from_encoding) ) {
			$from_encoding = 'UTF-8';
		    }

		    my $octets = '';
		  DO_ENCODE: {
			## convert octets in $from_encoding to Perl's internal form
	                my $stuff = $address;
	                eval {
			    $stuff = Encode::decode($from_encoding, $address);
	                };

			## convert data in Perl's internal form to $to_encoding octets
			$octets = Encode::encode($to_encoding, $stuff);

			## scott- this is the only real hack we have; it works
			## most of the time. I suspect we'll still get others
			## that would break; we can account for them in this way.
			if( $octets =~ /\x{1B}/ ) {
			    if( $from_encoding eq 'ISO-2022-JP' ) {
				last DO_ENCODE;
			    }
			    $from_encoding = 'ISO-2022-JP';
			    redo DO_ENCODE;
			}
		    }
		    push @return_address, $octets;
		    next;
		}

		## remedial action. This will always work even on broken stuff
		## (but it will rarely return the right encoding--it will look
		## like the unencoded bytes in ascii
		if( $address =~ /[[:^ascii:]]/ and ! Encode::is_utf8($address, 1) ) {
		    my $tmp = Encode::encode('UTF-8', $address);
		    $address = Encode::decode('UTF-8', $tmp, Encode::FB_XMLCREF);
		}
		push @return_address, $address;
	    }

	return \@return_address;
}

# ------------------------------------------------------------------------------
=pod

=head2  set_address()

     Purpose     : Return an encoded email address (phrase)
     Parameters  : hash ref
                   {'to_encoding'      => 'ISO-8859-1',
                    'from_encoding'    => 'UTF-8',
                    'default_encoding' => 'UTF-8',
                    'address'          => [$address1, $address1]}    
     Returns     : array reference of encoded email addresses. undef for failed ones.    
     Author/Date : Kevin Meltzer, Feb. 2002 
     Comments    :

=cut
# ------------------------------------------------------------------------------

sub set_address {
	my $self             = shift;
	my $args             = shift;
        my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
	my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
	my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $address_ref      = $args->{'address'}; # array ref
	my @return_address;

	for my $address (@$address_ref) {

		if (!$address) {
			push(@return_address, undef); 
			next;
		}

		my $ma = (Mail::Address->parse($address))[0];

		if ($ma->phrase) {
			#my $encoded_phrase = $self->convert({from_encoding    => $from_encoding,
                        #                                    to_encoding      => $to_encoding,
                        #                                    default_encoding => $default_encoding,
                        #                                    string           => $ma->phrase});
			# KM: If the following works, consolidate code accoridingly
			my $encoded_phrase = $self->set_subject({to_encoding  => $to_encoding,
                                            from_encoding => $from_encoding,
                                            subject      => $ma->phrase});
			$encoded_phrase =~ s!\n!!g;
			push(@return_address, $encoded_phrase . " <" . $ma->address . ">");
		} else {
			push(@return_address, $address);
		}
	}

	return \@return_address;

}

# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

sub get_attachment_name {
	my $self = shift;
	my $args = shift;
        my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $attachment_ref   = $args->{'attachments'}; # array ref
        my @return_attachments;

        for my $attachment (@$attachment_ref) {
	        my $return_filename = '';
		my $new_filename    = '';

	      DECODE: {
		    last DECODE unless $attachment =~ /=\?/;

		    # Has =?iso-NNNN-XX?=XXXX?= sequence
		    while ($attachment =~ s!(.*?)=\?(.+?)\?(.)\?(.*?)\?=(.*?)!!is) { 
			my $preface = $1;
			$from_encoding = $2; # ISO-NNNN-XX
			my $mime_encoding = $3; # B or Q
			my $encoded_string = $4;
			my $postface = $5;

			print qq{\$encoded_string => $encoded_string\n} if DEBUG;
			print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n" if DEBUG;
		
			# convert encodings into lower case (for convenience doing string compares)
			$from_encoding =~ tr/A-Z/a-z/;
			$mime_encoding =~ tr/A-Z/a-z/;
		
			if ($mime_encoding eq 'b') {
			    $encoded_string = MIME::Base64::decode_base64($encoded_string);
			} elsif($mime_encoding eq 'q') {
			    $encoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
			}

			$preface =~ s!^\s*!!;
			$postface =~ s!\s*$!!;

			$new_filename = $preface . $self->convert({from_encoding    => $from_encoding,
								   to_encoding      => $to_encoding,
								   default_encoding => $default_encoding,
								   string           => $encoded_string}) . $postface;

			if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
			    $new_filename = $self->replace_characters({string => $new_filename});
			}

			$return_filename .= $new_filename;
		    }

		    if ($return_filename) {
			push(@return_attachments, $return_filename);
			next;
		    }
		}

		## do we have a body encoding we can try?
	      TRY_BODY_ENCODING: {
		    if( $self->{USED_BODY_ENCODING} ) {
			$from_encoding = $self->{USED_BODY_ENCODING};
			unless( $from_encoding = Encode::resolve_alias($from_encoding) ) {
			    $from_encoding = 'UTF-8';
			}

			my $octets = '';
		      DO_ENCODE: {
			    ## convert octets in $from_encoding to Perl's internal form
			    my $stuff = '';
			    eval {
				$stuff = Encode::decode($from_encoding, $attachment);
			    };
			    if( $@ ) {
				system('logger', '-p', 'daemon.notice', "Conversion died $from_encoding ($attachment)");
				last TRY_BODY_ENCODING;
			    }
			    ## convert data in Perl's internal form to $to_encoding octets
			    $octets = Encode::encode($to_encoding, $stuff);

			    ## scott- this is the only real hack we have; it works
			    ## most of the time. I suspect we'll still get others
			    ## that would break; we can account for them in this way.
			    if( $octets =~ /\x{1B}/ ) {
				if( $from_encoding eq 'ISO-2022-JP' ) {
				    last DO_ENCODE;
				}
				$from_encoding = 'ISO-2022-JP';
				redo DO_ENCODE;
			    }
			}

			push @return_attachments, $octets;
			next;
		    }
		}

		## remedial action. This will always work even on broken stuff
		## (but it will rarely return the right encoding--it will look
		## like the unencoded bytes in ascii
		if( $attachment =~ /[[:^ascii:]]/ and ! Encode::is_utf8($attachment, 1) ) {
		    my $tmp = Encode::encode('UTF-8', $attachment);
		    $attachment = Encode::decode('UTF-8', $tmp, Encode::FB_XMLCREF);
		}
		push @return_attachments, $attachment;

		## NOTREACHED

		if( 0 ) {
			# This may be ASCII, or it may not be
			# Check is not ASCII, or has an escape
			#if ($attachment !~ /[\x20-\x7E]/ || $attachment =~ /\x1B/) {
			#if ($attachment !~ /[[:ascii:]]/ || $attachment =~ /\x1B/) {
			if ($attachment =~ /[[:^ascii:]]/ || $attachment =~ /\x1B/) {
				push(@return_attachments, undef);
			# Now it is ASCII, and ISO-NNNN-XX format (but not MIME)
			} elsif($attachment =~ /(iso\-\w+\-\w+)'(\w*)?'([\x20-\x7E]*)/si) {
				print "\$1: $1\n\$2: $2\n\$3: $3\n" if DEBUG;
				$from_encoding = $1;
				my $language = $2 || "";
				my $encoded_string = $3;
				$encoded_string =~ s!%!=!g;

				my $decoded_string = MIME::QuotedPrint::decode_qp($encoded_string);
				
       		                $new_filename =  $self->convert({from_encoding    => $from_encoding,
                                                            to_encoding      => $to_encoding,
                                                            default_encoding => $default_encoding,
                                                            string           => $decoded_string});

				if ($from_encoding =~ /(ASCII|ISO\-8859)/i) {
					$new_filename = $self->replace_characters({string => $new_filename});
				}
			
				push(@return_attachments, $new_filename);
			# Plain old ASCII
			} else {
				$attachment = $self->replace_characters({'string' => $attachment});
				push(@return_attachments, $attachment);
			}
		}
	}

        return \@return_attachments;

}

# ------------------------------------------------------------------------------
=pod

=head2  set_attachment_name()

     Purpose     : 
     Parameters  :     
     Returns     :     
     Author/Date : Kevin Meltzer, Feb. 2002 
     Comments    :

=cut
# ------------------------------------------------------------------------------

sub set_attachment_name {
	my $self = shift;
	my $args = shift;
        my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $attachment_ref   = $args->{'attachments'}; # array ref
        my $mime_encoding    = $args->{'mime_encoding'}; # How to encode? B, Q, none
	my $filename_encoding = $args->{'filename_encoding'}; # MIME, US-ASCII, RFC2231
        my $encoded_string;
        my $new_filename;
        #my $preface = "";
        #my $postface = "";
        my $return_filename;
        my @return_attachments;

	for my $attachment (@$attachment_ref) {
		$new_filename = $self->convert({from_encoding    => uc($from_encoding),
                                               to_encoding      => $to_encoding,
                                               default_encoding => $default_encoding,
                                               string           => $attachment});

		if (($mime_encoding eq 'b') || ($mime_encoding eq 'B')) {
			$encoded_string = MIME::Base64::encode_base64($new_filename, "");
		} elsif(($mime_encoding eq 'q') || ($mime_encoding eq 'Q')) {
			$encoded_string = MIME::QuotedPrint::encode_qp($new_filename);
		} else {
			$encoded_string = $new_filename;
		}

		$encoded_string =~ s!\n!!g;
		chomp $encoded_string;

		if ($filename_encoding =~ /^MIME$/i) {
			$return_filename = qq{=?$to_encoding?$mime_encoding?$encoded_string?=};
			push(@return_attachments, $return_filename);	
		} elsif($filename_encoding =~ /^RFC2231$/i) {
			# Not folding right now
			$return_filename = qq{*0=$to_encoding''$encoded_string};
			push(@return_attachments, $return_filename);	
		} else {
			push(@return_attachments, $encoded_string);
		}
	}
	return \@return_attachments;
}

# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

sub get_body {
        my $self = shift;
        my $args = shift;
        my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $content_encoding = $args->{'content_encoding'} || ''; # B or Q or ''
        my $string = $args->{'string'}; 
	my $decoded_string;

        if ($content_encoding eq 'B') {
	    $decoded_string = MIME::Base64::decode_base64($string);
        } elsif($content_encoding eq 'Q') {
	    $decoded_string = MIME::QuotedPrint::decode_qp($string);
        } else {
	    $decoded_string = $string;
	}

	## try to find an encoding in the HTML
	if( $decoded_string =~ m#<meta\b.*content-type.*\bcharset="?([^\>\"]+)#i ) {
	    $from_encoding = $1;
	}

	## make sure we can decode
	unless( $from_encoding = Encode::resolve_alias($from_encoding) ) {
	    $from_encoding = 'UTF-8';
	}


	my $octets = '';
	DO_ENCODE: {
	      # switch to use cp936
	      if ( $from_encoding eq 'euc-cn' ) {
	          $from_encoding = "cp936" 
	      }

	      ## convert octets in $from_encoding to Perl's internal form
	      my $stuff = $decoded_string;
	      eval {
	          $stuff = Encode::decode($from_encoding, $decoded_string);
	      };

	      ## convert data in Perl's internal form to $to_encoding octets
	      $octets = Encode::encode($to_encoding, $stuff);

	      ## scott- this is the only real hack we have; it works
	      ## most of the time. I suspect we'll still get others
	      ## that would break; we can account for them in this way.
	      if( $octets =~ /\x{1B}/ ) {
		  if( $from_encoding eq 'ISO-2022-JP' ) {
		      last DO_ENCODE;
		  }
		  $from_encoding = 'ISO-2022-JP';
		  redo DO_ENCODE;
	      }
	  }


	$self->{'USED_BODY_ENCODING'} = $from_encoding;

	## this is not the same as decode_utf8($octets)!
	return Encode::decode( 'UTF-8', $octets );
}

# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

## - if to_encoding is ascii and contains utf8, *upgrade to utf8*
## - if to_encoding is ascii and contains only ascii, *do no conversion*
## - if to_encoding is utf8, *do no conversion*
## - if to_encoding is set to *any* other non-ascii/utf8 supported encoding,
##   AND all UTF-8 characters can convert to to_encoding, *convert*
## - if to_encoding is set to *any* other non-ascii/utf8 supported encoding,
##   AND the message contains UTF-8 glyphs that do not map into to_encoding,
##   *use Encoding to convert what we can; remaining glyphs will be changed to 0xFFFD
sub set_body {
        my $self = shift;
        my $args = shift;

        my $to_encoding      = $args->{'to_encoding'}; # ISO-2022-JP, US-ASCII, ISO-8859-1
        my $from_encoding    = $args->{'from_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $default_encoding = $args->{'default_encoding'} || $self->{'DEFAULT_ENCODING'};
        my $string           = $args->{'string'};
        my $decoded_string = $string;


        if( $to_encoding ne 'UTF-8' ) {
            unless( $to_encoding = Encode::resolve_alias($to_encoding) ) {
                $to_encoding = 'UTF-8';
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
        }

        # since most users will have default ASCII, this is a check to force 
        # utf-8 if the string contains non-ascii chars.
        if ($to_encoding =~ /ASCII/i && $string =~ /[[:^ascii:]]/) {
             $to_encoding = 'UTF-8';

	     unless( utf8::is_utf8($string) ) {
		 $string = Encode::decode_utf8($string);
	     }
        }

	## plain ascii should be left as plain ascii
	elsif( $string =~ /^[[:ascii:]]+$/ ) {
	    $to_encoding = "US-ASCII";
	}

	##
	## set the transfer_encoding
	##
	my $transfer_encoding = '8bit';
	if ($to_encoding =~ /(iso\-2022\-|US\-ASCII)/i) {
		$transfer_encoding = '7bit';
	}


	my $string_orig = $string;
	my $to_enc = $to_encoding; 

	# switch to use cp936
	if ( $to_encoding eq 'euc-cn' || $to_encoding eq 'gb2312' ) {
		$to_enc = "cp936";
		$to_encoding = "gb2312";
	}
	
	# Hack for Windows-Unicode mapping (BUG24616)
	# encoding to cp50221 was succeeded -> assumed windows mapping
	# failed -> assumed mac or unix. Take legacy encording.
	my $new_string;
	if ( $to_encoding eq 'iso-2022-jp' ) {
	    $string_orig =~ s/\x{301c}/\x{ff5e}/g;
	    $new_string = eval { Encode::encode( "cp50221", $string_orig, 1 );};
	    if ($@ ne "" | $new_string =~ /\\x{/ ) {
		$new_string = Encode::encode( $to_enc, $string, 0 );
	    };	
	} else {
	    $new_string = Encode::encode( $to_enc, $string, 0 );
	};

	# try cp936 encoding when failed with iso-2022-jp 
	if ( $new_string =~ /\\x{/ ) {
		if ( $to_encoding eq 'iso-2022-jp' ) {
			$to_enc = "cp936"; # real encoding
			$to_encoding = "gb2312";
			$new_string = Encode::encode( $to_enc, $string_orig, 1 );
			$transfer_encoding = '8bit';
		}
	}
	return ( defined($new_string) 
		 ? { string => $new_string,
		     encoding => $transfer_encoding,
		     enc => $to_enc,
		     charset  => $to_encoding }
		 : undef );

}

1;

