package ControlPanel2;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

use Apache2::Const qw(OK HTTP_NOT_FOUND HTTP_FORBIDDEN);
use Apache2::Request ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Cookie ();
use Apache2::Connection ();
use Apache2::Log ();

use XML::LibXML;
use File::Spec::Functions 'canonpath';

use ControlPanel::MetaProc;
use ControlPanel::Transform;
use ControlPanel2::FileTransfer;

sub new ()
{
  my $self = bless {}, $_[0];
  $self->{r}           = $_[1];
  $self->{req}         = Apache2::Request->new($_[1],
                                              POST_MAX => 1024 * 1024 * 10 + 1024 * 4,  # 10 MB plus slop
                                              TEMP_DIR => "/tmp");
  $self->{cookies}     = Apache2::Cookie::Jar->new($_[1]);
  $self->{debugLevel}  = $ENV{CPDebugLevel} || 0;
  $self->{template_dir}= $ENV{Template_Dir} || "/usr/local/cp/templates/default/";
  $self->{strings_dir} = $ENV{Strings_Dir}  || '/usr/local/cp/strings';
  $self->{domdump_dir} = $ENV{Dom_Dump_Dir} || "/tmp/doms";

  $self->{xmlparser} = XML::LibXML->new();
  # There is something wrong with the way Apache2 or mp2 frees memory for 
  # a parser constructed later that leaves nodes sitting around after 
  # the parser is destroyed, so letting this last the life of the request
  # for now.

  my $filename         = $_[1]->uri();

  # Filename fixup: first strip off the leading /ControlPanel/ 
  # To support file downloading via a url such as 
  #   /ControlPanel/mail/message.xsl/VSAPDOWNLOAD/hello.txt?etc etc,
  # we need to grab the filename as the .xsl file before the VSAPDOWNLOAD. 
  # We do this because we WANT message.xsl to run because it will do the 
  #   vsap necessary to move the file around

  $filename =~ s#^/ControlPanel(.*?(?:\.xsl)?)(/VSAPDOWNLOAD.*)?$#$1#;
  
  # Removed enhancement junk

  # Add an initial / if needed
  $filename !~ m#^/# && ($filename = "/$filename");

  ## BUG05945: Content Error when trailing / is missing from url
  if( $filename !~ m#/$# and -d canonpath($self->{template_dir} . $filename) ) {
      $filename .= '/';
  }

  # Now add an index.xsl if needed
  $filename =~ m#/$# && ($filename .= 'index.xsl');
  $self->{filename}    = $filename;

  return $self;
}

sub debug ($$$)
{
  my ($self,$level,$message) = @_;
  
  # Notice that debug is used mainly for development and debugging, and not to 
  # relay critical or fatal errors. 
  
  # Levels of severity, 10 being the most verbose:
  #
  # 10 - messages unimportant to basic debugging, function call notices.
  #  8 - useful for development debugging, including printing the complete 
  #      DOM source trees and XSLT source.
  #  5 - This is the best setting for basic debugging to still avoid huge 
  #      amounts of text (as in 8).
  #  3 - information important to debugging, including form parameters.
  #  1 - critical debugging information
  
  my $subroutine = (caller(1))[3];
  if ($level <= $self->{debugLevel}) {
    $self->{r}->warn("[CP] $subroutine: $message");
  }
}

sub handler ($)
{
  my $r = shift;
  my $self = new ControlPanel2($r);
  
  # test post size
  my $status = $self->{req}->body_status;
  if ($status) {
    $self->debug(5, "HTTP status error: '$status'");
    if ($status eq "Exceeds configured maximum limit") {
      $self->{req}->discard_request_body;
      return 413;
    }
  }

  # If the file we're processing is .css or .js, we need to decline it. 
  # TODO: Watch out for a security risk here
  if (($self->{filename} =~ /\.(css|js|jar|conf)$/) && ($self->{req}->uri() !~ /DOWNLOAD/)) {
    # Send 404 if the file doesn't exist
    if (!-e $self->{template_dir} . $self->{filename}) {
      return Apache2::Const::HTTP_NOT_FOUND();
    }
    ($self->{filename} =~ /\.css$/) && ($r->content_type('text/css'));
    ($self->{filename} =~ /\.js$/) && ($r->content_type('text/plain'));
    open (FH, $self->{template_dir} . $self->{filename});
    while (<FH>) {
      $r->print($_);
    }
    close FH;
    return Apache2::Const::OK();
  }
  
  $self->{debugLevel} && $self->debug(10,"Initiated new ControlPanel2 object"); 
  
  # Set content-type to HTML for now. If non-HTML data is going to be served, 
  # we should decline the request. Later.
  $r->content_type('text/html; charset=utf-8');
  
  # Build the initial DOM. 
  my $xmldom = $self->buildDOM();
  $self->{debugLevel} && $self->debug(10,"Completed initial DOM");
  $self->{debugLevel} && $self->debug(8,"DOM:\n" . $xmldom->toString(1));
  
  # Handle an upload request
  if ($xmldom->documentElement->findnodes("/cp/form/fileupload")) {
    eval {
      ControlPanel2::FileTransfer->upload (CP => $self, DOM => $xmldom);
      # Here we won't return because after an upload, a regular page must be processed and displayed
    };
    if ($@) {
      return $self->print_error_page('File Upload', $@);
    }
  }
  
  # Call the meta processor. This takes the DOM, processes XSLT metadata files,
  # and generates the final XSLT.
  my $document_file;
  eval {
    my $mp = ControlPanel::MetaProc->new (DOM => $xmldom, CP => $self);
    $document_file = $mp->process;
    $self->{debugLevel} && $self->debug(10,"Meta data processed, returned '$document_file'");
  };
  if ($@) {
    # Send 403 if we get a forbidden error from metaproc
    if ($@ =~ /forbidden/s) {
      return Apache2::Const::HTTP_FORBIDDEN();
    }
    return $self->print_error_page('MetaProc', $@);
  }
  
  # Handle a download request
  # This is done AFTER .meta processing because a VSAP download requires that VSAP be
  # called to move the file over to /tmp
  if ($self->{req}->uri() =~ /DOWNLOAD/) {
    my $r = eval {
      if (ControlPanel2::FileTransfer->download (CP => $self, DOM => $xmldom)) {
        # Exit here, since the download handler should have done everything
        return Apache2::Const::OK();
      } else {
        # Not sure what to do here, if the file download fails.. (like it couldn't find the file,
        # bad permissions, etc)
      }
    };
    return Apache2::Const::OK() if ($r == Apache2::Const::OK());
    if ($@) {
      return $self->print_error_page('File Download', $@);
    }
  }
  
  # Add the strings (placeholder for the real branding calls)
  $self->addStrings($xmldom, $document_file);
  
  # Transform the resulting document.
  my $transform;
  $self->{debugLevel} && $self->debug(10,"Transforming document '$document_file'");
  eval {
    $transform = ControlPanel::Transform->new (DOM => $xmldom,
            base_path => $self->{template_dir}, filename => $document_file);
    $transform->process;
    $self->{debugLevel} && $self->debug(10,"Transformed document '$document_file'");
  };
  if ($@) {
    $self->debug(5, "Transform error: $@");
    # Send 404 if the file doesn't exist
    if (!-e $self->{template_dir} . $document_file) {
      $self->debug(5, "No such file");
      return Apache2::Const::HTTP_NOT_FOUND();
    }
    return $self->print_error_page('Transform', $@);
  }

  # check for force SSL pref
  my $secure = 0;
  my $config_file = (-e "/www/conf.d/cpx.conf") ?
                        "/www/conf.d/cpx.conf" : "/www/conf/httpd.conf";
  if (open(CONF, "$config_file")) {
      my @conf = ();
      while (<CONF>) {
        push @conf, $_;
      }
      close(CONF);
      $secure = grep(/CPX: force ssl redirect start/i, @conf);
  }
  
  # Check for cookies
  foreach my $newcookie ($xmldom->findnodes("/cp/request/setcookies/*")) {
    my $cookiename  = $newcookie->getName;
    my $cookievalue = $newcookie->textContent;
    my $cookie = Apache2::Cookie->new($self->{r},
              -name    => $cookiename,
              -value   => $cookievalue,       
              -path    => "/",
              -secure  => $secure,
          );
    $cookie->bake($self->{r});
    $self->{debugLevel} && $self->debug(9,"Set cookie: /cp/request/setcookies/$cookiename = '$cookievalue'");
  }
  
  # Dump the DOM if necessary
  if ($self->{debugLevel} >= 10) {
    $self->{debugLevel} && $self->debug(10, "Dumping DOM to $self->{domdump_dir}/$document_file");
    dumpDOM($xmldom, $document_file, $self);
  }
  
  # Output the document
  $r->headers_out->set('Cache-Control' => 'max-age=0, must-revalidate');
  $self->{debugLevel} && $self->debug(10,"Outputting content!");
  $r->print($transform->result_html);
  return Apache2::Const::OK();
}

sub dumpDOM
{
  my ($dom, $file, $self) = @_;
 
  $file =~ s/^(.*)\.xsl$/$1.xml/;
  unless( open (DOMDUMP, ">:utf8", "$self->{domdump_dir}/$file") ) {
      $self->debug(10,"Couldn't dump DOM: $!");
      return;
  }
  print DOMDUMP $dom->toString(1);
  close DOMDUMP;
}

sub buildDOM ($) 
{
  my $self = shift;
  my $r    = $self->{req};
  
  my $filename    = $self->{filename};
  my $user_agent = $self->{r}->headers_in->{"User-Agent"};
  my $remote_addr = $self->{r}->connection->remote_ip();

  # Various headers we may need to know about for some reason or another
  my $content_length = $self->{r}->headers_in->{"Content-length"};

  my $xmldom = XML::LibXML->createDocument( "1.0", "UTF-8" );
  my $root_node = $xmldom->createElement('cp');
  $xmldom->setDocumentElement($root_node);
  my $req_node  = $root_node->appendChild($xmldom->createElement('request'));

  $req_node->appendTextChild( base_path => $self->{template_dir} );
  $req_node->appendTextChild( filename => $filename );
  $req_node->appendTextChild( hostname => $r->hostname );
  $req_node->appendTextChild( content_length => $content_length )
    if defined $content_length;
  $req_node->appendTextChild( user_agent => $user_agent );
  $req_node->appendTextChild( remote_addr => $remote_addr );

  my @locales = $self->get_locales();
  $req_node->appendTextChild( locale => $locales[0] );

  $req_node->appendChild( $xmldom->createElement('cookies') );
  $root_node->appendChild( $xmldom->createElement('form') );

  # Populate request parameters
  my ($form) = $xmldom->findnodes("/cp/form");
  my $table = $self->{req}->param;
  while (my($param,$value) = each %{$table}) {
    $self->{debugLevel} && $self->debug(9, "/cp/request/form/$param = '$value'");
    $form->appendTextChild($param,$value);
  }

  # Populate cookies
  my ($cookies_node) = $xmldom->findnodes("/cp/request/cookies");
  foreach my $name ( $self->{cookies}->cookies ) {
    if ($name eq "CP-sessionkey") {
      my @tmpArray = $self->{cookies}->cookies($name);
      $self->{debugLevel} && $self->debug(9, "/cp/request/cookies/$name = '" . ($self->{cookies}->cookies($name))[$#tmpArray]->value . "'");
      $cookies_node->appendTextChild($name, ($self->{cookies}->cookies($name))[$#tmpArray]->value);
    } 
    else {
      foreach my $value ( $self->{cookies}->cookies($name) ) {
        my $cval = ($value && $value->value) ? $value->value : '';
        $self->{debugLevel} && $self->debug(9, "/cp/request/cookies/$name = '" . $cval . "'");
        $cookies_node->appendTextChild($name, $cval);
      }
    }
  }

  return $xmldom;
}

sub addStrings ($$$) {
    my $self   = shift;
    my $xmldom = shift;
    my $document_file = shift;

    # Determine the section from the $document_file path
    $document_file =~ m#^(.+?)/(.*\.xsl)$#;

    $self->debug(10, "\$document_file == $document_file");
    my $section = $1 || '';

    $self->debug(10, "Adding strings for section $section");

    # Determine a secondary section, if any
    $document_file =~ m{^/*(.+)/[^/]+\.xsl$};
    my $section2 = $1 || '';

    if( $section2 =~ m!/! ) {
        $self->debug(10, "Adding strings for second section /$section2 , if they exist");
        $section2 =~ s{/+}{_}g;
    }
    else {
        $section2 = '';
    }

    ## set strings_dir
    unless( $self->{strings_dir} ) {
        $self->{strings_dir} = '/usr/local/cp/strings';
    }

    ## get locale from browser language preference list
    my @locales = $self->get_locales();

    ## set strings dir based on highest preference; we don't do any
    ## language merging here. If you haven't translated all your
    ## strings, you'll see some blank spots I guess. What about new
    ## strings, then? We should do the same kind of merging as we
    ## would for "branding" (a reseller or SA changes selected
    ## strings)

    ## for deeper strings, for now we'll make everybody do the entire
    ## level-1 element (e.g., look at the <regions> node in
    ## cp_prefs.xml). This will allow us to keep our merges flat and
    ## not have to build in special cases for these deeper string
    ## areas.

    ##
    ## set the strings_dir to the preferred locale
    ##
    my $strings_dir_base = $self->{strings_dir};
    $self->{strings_dir} .= '/' . $locales[0];  ## FIXME: just the first one for now

    $self->debug(10, "Using strings in $self->{strings_dir}");

    my $globalstrings = $self->{xmlparser}->parse_file($self->{strings_dir} . "/global.xml");
    my $gimport = $xmldom->importNode($globalstrings->documentElement);
    $xmldom->documentElement->appendChild($gimport);

    $self->debug(10, "Now parsing '$section' section and '$section2' (section 2)");

    if( $section && ( -f $self->{strings_dir} . "/$section.xml" ) ) {
        eval {
            my $sectionstrings = $self->{xmlparser}->parse_file($self->{strings_dir} . "/$section.xml");
            my $import = $xmldom->importNode($sectionstrings->documentElement);
            $xmldom->documentElement->appendChild($import);
        };
        if( $@ ) {
            return $self->print_error_page('Branding', $@);
        }
    }

    else {
        return Apache2::Const::HTTP_NOT_FOUND();
    }
    $self->debug(10, "Still here");

    if( $section2 && ( -f $self->{strings_dir} . "/$section2.xml" ) ) {
        eval {
            my $sectionstrings = $self->{xmlparser}->parse_file($self->{strings_dir} . "/$section2.xml");
            my $import = $xmldom->importNode($sectionstrings->documentElement);
            $xmldom->documentElement->appendChild($import);
        };
        if( $@ ) {
            return $self->print_error_page('Branding', $@);
        }
    }

    ## FIXME: this should look in $locales[1], etc.
    elsif( $section2 && ( -f "$strings_dir_base/en_US" . "/$section2.xml" ) ) {
        $self->debug(10, "Now using strings in $strings_dir_base for $section2");
        eval {
            my $sectionstrings = $self->{xmlparser}->parse_file("$strings_dir_base/en_US" . "/$section2.xml");
            my $import = $xmldom->importNode($sectionstrings->documentElement);
            $xmldom->documentElement->appendChild($import);
        };
        if( $@ ) {
            return $self->print_error_page('Branding', $@);
        }
    }
}

sub get_locales {
    my $self = shift;

    ##
    ## determine locale preference. See Apache's content negotiation
    ## reference: <http://httpd.apache.org/docs/content-negotiation.html>,
    ## RFC 1766 (tags for the identification of languages), ISO 639
    ## (language code pages) and ISO 3166 (country code pages) for
    ## details
    ##
    ## get browser language preference list; one side-effect is that
    ## the "; q=x.y" scoring is effectively ignored and the order the
    ## headers are passed in becomes the only thing we look at.
    ## 
    my @locales = ();
    my %langs   = (); ## prefs we've already seen
    if( $self->{r}->headers_in->{'Accept-Language'} ) {
        @locales = grep { $_ && ! $langs{$_}++ } 
          map { /^([^;]+)/ }          ## remove 'q' scores
            map { lc($_) } 
              split( ',', ($self->{r}->headers_in->{'Accept-Language'}) );

    }
    $self->debug(10, "Still here");

    ## normalize to lang_COUNTRY; we use underscore because FreeBSD's
    ## locale tree (and other apps) uses it too.
    for my $blocale ( @locales ) {
        my($lang) = $blocale =~ /^(\w+)/;
        my($co)   = $blocale =~ /^\w+\-(\w*)/; $co ||= '';
        $lang = lc($lang); $co = uc($co);
        $blocale = $lang . ( $co ? '_' : '' ) . $co;
    }

    ## get platform locales
    my %platform_locale = ();
    if( opendir LOC, $self->{strings_dir} ) {
        %platform_locale = map { $_ => 1 } grep { /^\w+$/ } readdir LOC;
        closedir LOC;
    }

    ## preen any language we don't support
    @locales = grep { $platform_locale{$_} } @locales;

    ##
    ## FIXME: we should push the reseller/sa/da/eu platform pref
    ## FIXME: before the en_US default. This might come from Apache,
    ## FIXME: or we could do it on a per-domain admin basis...
    ##

    ## if no preferences set, use en_US
    unless( @locales ) {
        @locales = qw(en_US);
    }

    return(@locales);
}

sub print_error_page {
  my ($self, $step, $error) = @_;
  
  # We probably don't want to show all this information in the production environment. Fix later.
  $self->debug(10, "Printing error page for step $step: $error");
  my $page =<<"  END";
    <html>
      <head>
        <title>Control Panel Content Error</title>
      </head>
      
      <body>
        <h1>Control Panel Error:</h1>
        <h2>A general error has occurred during $step.</h2>
        <h3>Error: $error</h3>
        <h3>Please contact your system administrator.</h3>
      </body>
    </html>
  END
  $self->{req}->print($page);
  
  return Apache2::Const::OK();
}


1;
__END__

=head1 NAME

ControlPanel2 - VSAP based Control Panel (aka "CPX")

=head1 SYNOPSIS

  use ControlPanel2;

=head1 DESCRIPTION

This is a mod_perl2 content handler.

=head1 SEE ALSO

vsap(1), ControlPanel::MetaProc(3)

=head1 AUTHOR

Dan Brian

=head1 COPYRIGHT AND LICENSE

No part of this module may be duplicated in any form without written
consent of the author or his employer.

=cut
