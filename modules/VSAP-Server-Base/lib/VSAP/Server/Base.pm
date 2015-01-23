package VSAP::Server::Base;

our $VERSION = '1.01';
use Quota;

BEGIN {
    eval { require Digest::Elf };
}

sub format_error {
    my ($code, $message, $extradata, $type) = @_;
    $message = xml_escape($message);
    $code = xml_escape($code);
    my $base = ( $INC{'Digest/Elf.pm'} ? Digest::Elf::elf($type) : 0 );
    my $xml = qq{<vsap type="error" caller="$type">\n};
    $xml .=   qq{  <code>$code</code>\n};
    $xml .=   qq{  <message>$message</message>\n};
    $xml .=   "  <info>" . xml_escape($extradata) . "</info>\n" if $extradata;
    $xml .=   qq{  <base>$base</base>\n};
    $xml .=   qq{</vsap>\n};
    return $xml;
}

sub xml_dubescape {
  my $text = $_[0];
  $text = xml_escape($_[0]);
  $text =~ s/\&/\&amp;/g;
  $text;
}
     
sub xml_escape {
  my $text = $_[0];
  $text =~ s/\&/\&amp;/g;
  $text =~ s/</\&lt;/g;
  $text =~ s/>/\&gt;/g;
  $text =~ s/\r/\&#013;/g;
  $text =~ s/\n/\&#010;/g;
  $text =~ s/"/\&#034;/g;
  $text;
}

sub xml_unescape {
  my $text = $_[0];
  $text =~ s/\&amp\;/\&/g;
  $text =~ s/\&lt\;/</g;
  $text =~ s/\&#013\;/\r/g;
  $text =~ s/\&#010\;/\n/g;
  $text;
}

sub encode {
  # Use like this:
  # unless ($new_text = vsap_encode ($from_encoding, $to_encoding, $text, $error)) {
  #   print $error;
  # }

  my ($from_encoding, $to_encoding, $text) = @_;
  $_[3] = 0; # just in case it isn't empty

  return $text if ($from_encoding eq $to_encoding);

  my $converter;
  my $converted;

  eval {
      require Text::Iconv;
  };
  if( $@ ) {
      warn "No Text::Iconv loaded in VSAP::Server::Base\n";
      return $text;
  }

  eval {
    $converter = Text::Iconv->new($from_encoding,$to_encoding);
  };
  if ($@) {
    $_[3] = "Text::Iconv->new() [$@]";
    return 0;
  } else {
    eval {
      $converted = $converter->convert($text);
    };
    if ($@) {
      $_[3] = "Text::Iconv::convert [$@]";
      return 0;
    } else {
      return $converted;
    }
  }
  return 0;
}

sub url_encode{
  my $str = shift;
  if ($str ne "") {
    $str =~ s/([^0-9A-Za-z_])/"%".unpack("H2",$1)/ge;
    # replacing /'s with %2f has been a problem so let's put those back.
    $str =~ s/%2f/\//g;
  }
  return $str;
}

sub over_quota {
  my $dev = Quota::getqcarg('/usr/home');
  my ($currBlocks,$softBlock,$hardBlock,undef,$numFiles,$fileSoft,$fileHard) = Quota::query($dev);
  return ($currBlocks > $softBlock) ? 1 : 0;
}

1;

