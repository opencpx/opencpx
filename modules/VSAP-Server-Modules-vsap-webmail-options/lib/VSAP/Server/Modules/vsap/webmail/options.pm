package VSAP::Server::Modules::vsap::webmail::options;

use 5.008001;
use strict;
use warnings;

our $VERSION  = '0.03';

our %_ERR = ( WMO_BAD_REPLY_TO     => 102,
              WMO_WRITE_FAILED     => 106,
            );

our $OPTIONS = '/webmail_options.xml';

our $Debug = 0;

##
## These are the authoritative webmail options.
##
our %WMO = ( 
         from_name            => '',
	     preferred_from       => '',
	     reply_to             => '',
	     reply_to_toggle      => 'select',     # "select" or "input" on cpx, or "yes" "no" on signature. 
	     signature            => '',
	     signature_toggle     => 'off',        # "on" or "off"
	     outbound_encoding    => 'UTF-8',
	     fcc                  => 'no',         # "yes" or no"
	     url_highlight        => 'no',         # "yes" or "no"
         multipart_view       => 'text',       # prefer "text" or "html" multiparts
         fetch_images_remote  => 'no',         # show remote images in HTML messages
         fetch_images_local   => 'no',         # show MIME images in HTML messages
         attachment_view      => 'all',        # attachments | inlines | all | none
         messages_per_page    => 10,           # any positive integer
	     tz_display           => 'my',         # "my" or "sender"
	     display_encoding     => 'UTF-8',
	     messages_sortby      => 'date',
	     messages_order       => 'descending',
	     messages_sortby2     => 'from',
	     messages_order2      => 'descending',
	     addresses_order      => 'ascending',
	     addresses_per_page   => 10,           # 10, 25, 50 or 100
	     addresses_sortby     => 'firstname',
         sel_addressee_order  => 'firstname',
	     sel_addressee_sortby => 'descending',
	     forward_attach       => 'no',         # "yes" or "no"
	     use_mailboxlist      => 'no',         # "yes" or "no"
	     inbox_checkmail      => 0,            # minutes between auto checkmail [0 = off]
	     html_compose         => 'yes',        # use html editor when composing.
	   );

##
## use the value of the "owner" (domain admin or server admin) as
## defaults if the user has not specified anything. The owner is only
## consulted when no associated preference key is found. This should
## only occur the first time the user sets his preferences, unless the
## user deletes his preferences file somehow.
##
our @owner_lookup = qw( outbound_encoding display_encoding );

use Carp qw(carp);

sub as_hash {
    my $vsap = shift;
    my $dom  = shift || $vsap->{_result_dom};

    my @opts;
    unless($vsap->{_wm_options_loaded} and
           @opts = $dom->findnodes('/vsap/vsap/webmail_options/*')) {
	VSAP::Server::Modules::vsap::webmail::options::load::handler($vsap, '', $dom);
	
	$vsap->{_wm_options_loaded} = 1;

        @opts = $dom->findnodes('/vsap/vsap/webmail_options/*');
    }

    return { map { $_->localname => $_->textContent } @opts };
}

sub _build_dom {
    my $root    = shift;
    my $chillun = shift;
    my %keys    = map { $_ => 1 } ( $chillun ? grep { exists $WMO{$_} } @$chillun : keys %WMO );
    my $options = shift;

    my $wmo_dom;
    if( -f $options ) {
	eval {
	    my $parser = new XML::LibXML;
	    $wmo_dom   = $parser->parse_file( $options )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    carp "$@\n";
	}
    }

  FIND_KEYS: for my $key ( sort keys %keys ) {
	my $value = '';

	## lookup the node in the dom
	if( $wmo_dom ) {
	    $value = $wmo_dom->findvalue("/webmail_options/$key");
	}

	## FIXME: need to lookup the owner's values
	## use the owner's values
#	if( ! $value and read_owner( @owner_lookup ) ) {
#	    $value = $owner->string_value
#	}

	## get hard-coded defaults
	$value ||= $WMO{$key};

	$root->appendTextChild($key => $value);
    }
}

## FIXME: this call must be done after calls to get_value because this messes up the dom
sub _write_dom {
    my $vsap  = shift;
    my $dom   = shift;
    my $thing = shift;

    return unless ref($thing);

    ## load DOM from disk
    my $wmo_dom;
    eval {
	my $parser = new XML::LibXML;
	($wmo_dom) = $parser->parse_file($vsap->{cpxbase} . $OPTIONS)->findnodes('/webmail_options');
    };

    ## have an uninitialized dom
    if( $@ ) {
	## FIXME: need to test this w/ bogus parse_file
	$wmo_dom = $dom->createElement('webmail_options');
    }

    ## make our DOM nice and fresh
    for my $key ( sort keys %WMO ) {
	my $have_val = ( UNIVERSAL::isa($thing, 'UNIVERSAL') 
			 ? $thing->child($key) 
			 : exists $thing->{$key} );
	my $value    = ( UNIVERSAL::isa($thing, 'UNIVERSAL') 
			 ? ( $thing->child($key) && $thing->child($key)->value
			     ? $thing->child($key)->value : '')
			 : $thing->{$key} );

	## this node exists; update it (or leave it alone)...
	if( my ($node) = $wmo_dom->findnodes("./$key") ) {
	    ## and we have a replacement value for it...
	    if( $have_val ) {
		my $new = $dom->createElement($key);
		$new->appendTextNode( $value );
		$wmo_dom->replaceChild( $new, $node );
	    }
	}

	## ... node does not exist; create one
	else {
	    $wmo_dom->appendTextChild( $key => ( $have_val ? $value : $WMO{$key} ) );
	}
    }

    ## flush DOM to file (Why doesn't toFile() work? Because we don't have a valid XML file)
    ## FIXME: should have locks on this file
    my $new_options_path = $vsap->{cpxbase} . $OPTIONS . "_hot_pepper_sauce";
    open OPTIONS, ">" . $new_options_path
      or do {
          $vsap->error( $_ERR{WMO_WRITE_FAILED} => "Could not open options file: $!" );
	  return(0);
      };
    binmode OPTIONS, ":utf8";
    print OPTIONS $wmo_dom->toString(1)
      or do {
          $vsap->error( $_ERR{WMO_WRITE_FAILED} => "Could not write to options file: $!" );
          return(0);
      };
    close OPTIONS;

    if (-z $new_options_path) {
        unlink($new_options_path);
        $vsap->error( $_ERR{WMO_WRITE_FAILED} => "Could not save options file: over quota" );
        return(0);
    }
    else {
        my $options_path = $vsap->{cpxbase} . $OPTIONS;
        rename($new_options_path, $options_path);
    }

    ## fixup cache
    if( my ($del) = $dom->findnodes('/vsap/vsap/webmail_options') ) {
	$del->parentNode->removeChild($del);
	$vsap->{_wm_options_loaded} = undef;
    }

    return(1);
}

sub get_value {
    my $values = as_hash(shift, shift);
    my $key = shift;

    return $values->{$key};
}

sub set_values ($$@) {
    my $vsap  = shift;
    my $dom   = shift;
    my %prefs = @_;

    unless( $vsap->{_wm_options_loaded} ) {
	VSAP::Server::Modules::vsap::webmail::options::load::handler($vsap, '', $dom);
	$vsap->{_wm_options_loaded} = 1;
    }
    _write_dom($vsap, $dom, \%prefs);
}

##
## fetch all options
##
package VSAP::Server::Modules::vsap::webmail::options::load;

## load from disk webmail options and attach them to the dom

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $root = $dom->createElement('vsap');
    $root->setAttribute(type => 'webmail:options:load');

    my $wm_node = $dom->createElement('webmail_options');
    $root->appendChild($wm_node);

    # Set the Signature default for multipart_view to html.
    $WMO{'multipart_view'}='html' if ($vsap->is_signature());

    VSAP::Server::Modules::vsap::webmail::options::_build_dom($wm_node, undef, $vsap->{cpxbase} . $OPTIONS );

    $dom->documentElement->appendChild($root);
    $vsap->{_wm_options_loaded} = 1;

    return;
}

##
## fetch one or more options
##
package VSAP::Server::Modules::vsap::webmail::options::fetch;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $root = $dom->createElement('vsap');
    $root->setAttribute(type => 'webmail:options:fetch');

    my $wm_node = $dom->createElement('webmail_options');
    $root->appendChild($wm_node);

    # Set the Signature default for multipart_view to html.
    $WMO{'multipart_view'}='html' if ($vsap->is_signature());
	
    VSAP::Server::Modules::vsap::webmail::options::_build_dom( $wm_node, 
							       [$xmlobj->children_names], 
							       $vsap->{cpxbase} . $OPTIONS );

    $dom->documentElement->appendChild($root);
    return;
}

##
## save the current values in the dom to disk
##
package VSAP::Server::Modules::vsap::webmail::options::save;

use Email::Valid;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    $vsap->{_wm_options_loaded} = 0;
    # we should unload the webmail_options subtree if it exists; but we aren't.
    
    my $reply_to = $xmlobj->child("reply_to") ? $xmlobj->child("reply_to")->value : 0;
    if ($reply_to) {
        unless( Email::Valid->address( -address => $reply_to, -fqdn => 0 ) ) {
            $vsap->error($_ERR{WMO_BAD_REPLY_TO}, "Invalid address in reply_to field.");
            return;
        }
    }

    ## FIXME: should write out all keys each time so defaults are
    ## stored in the file; we'll also look up the "owner" preferences
    ## for certain unset values (such as encodings, etc.)
    my $status = "ok";
    unless (VSAP::Server::Modules::vsap::webmail::options::_write_dom($vsap, $dom, $xmlobj)) {
        $status = "fail";
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute(type => 'webmail:options:save');
    $root->appendTextChild('status', $status);
    $dom->documentElement->appendChild($root);

    return;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::options - VSAP module for webmail preferences

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::options;

=head1 DESCRIPTION

This module implements webmail options storage and retrieval for VSAP.
Users' individual preferences are stored in F<~/.opencpx/webmail_options.xml>.

If the file does not exist, defaults are read from hard-coded values
from this module itself first; the "owner" (e.g., if this is an
end-user, the domain admin is the owner; if this is a domain admin,
the server admin is the owner) preferences are consulted next and will
override the hard-coded values set.

=head2 webmail:options:load

Loads webmail_options node from F<$HOME/.opencpx/webmail_options.xml> and
appends this node into the main DOM.

=head2 webmail:options:save

Saves webmail_options node from the DOM to F<$HOME/.opencpx/webmail_options.xml>.

Example:

  <vsap type='webmail:options:save'>
    <webmail_options>
      <from_name>Joseph Schmoe, Esquire</from_name>
    </webmail_options>
  </vsap>

returns:

    <vsap type='webmail:options:save'><status>ok</status></vsap>

=head2 webmail:options:fetch

Fetch one or more values from the webmail options settings

Example:

  <vsap type='webmail:options:fetch'>
    <from_name/>
    <display_encoding/>
  </vsap>

returns:

  <vsap type="webmail:options:fetch">
    <webmail_options>
      <display_encoding>ISO-2022jp</display_encoding>
      <from_name>Joseph Schmoe, Esquire</from_name>
    </webmail_options>
  </vsap>

=head2 Sample webmail_options node

This is roughly what the F<webmail_options.xml> file looks like:

  <webmail_options>
    <from_name>Joe Schmoe, Jr.</from_name>
    <preferred_from>jschmoe@schmoe.org</preferred_from>
    <reply_to>jschmoe@schmoe.org</reply_to>
    <signature>Joe Schmoe, Jr.
  Root Beer Drinkers Anonymous
      &lt;joe@schmoe.org&gt;</signature>
    <outbound_encoding>US-ASCII</outbound_encoding>
    <fcc>Sent Items</fcc>
    <url_highlight>yes</url_highlight>
    <messages_per_page>10</messages_per_page>
    <tz_display></tz_display> (use message tz)
    <display_encoding>ISO-2022</display_encoding>
    <forward_attach>no</forward_attach>
  </webmail_options>

=head2 For developers

Field names and their default values are found in the public %WMO hash
near the top of the module.

The list of fields to lookup in the owner preferences is a public
array called C<@owner_lookup> near the top of the module and may be
modified at runtime.

See the test file for (ugly) code examples.

=head1 SEE ALSO

VSAP(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
