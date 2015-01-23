package VSAP::Server::Modules::vsap::web::rss;

use 5.008004;
use strict;
use warnings;
use Data::UUID;
use File::Path qw(mkpath);
use LWP::UserAgent;
use MIME::Types;
use URI::URL;
use XML::LibXML;

our $VERSION = '0.01';

our %_ERR = ( RSS_NOTFOUND         => 100,
              RSS_XML_ERROR        => 101,
              RSS_RUID_REQUIRED    => 102,
              RSS_IUID_REQUIRED    => 103,
              RSS_RUID_NOTFOUND    => 104,
              RSS_IUID_NOTFOUND    => 105,
              RSS_MKDIR_ERROR      => 106,
              RSS_DOMAIN_NOTFOUND  => 107,
              RSS_DOCROOT_ERROR    => 108,
	    );

our $RSSFEEDS = 'rssfeeds.xml';

our @RSS_RFIELDS = qw( title
                       link
                       description
                       language
                       copyright
                       pubdate_day
                       pubdate_date
                       pubdate_month
                       pubdate_year
                       pubdate_hour
                       pubdate_minute
                       pubdate_second
                       pubdate_zone
                       category
                       generator
                       ttl
                       image_url
                       image_title
                       image_link
                       image_width
                       image_height
                       image_description
                       itunes_author
                       itunes_subtitle
                       itunes_summary
                       itunes_explicit
                       itunes_owner_name
                       itunes_owner_email
                       itunes_image
                       itunes_category
                       itunes_new-feed-url
                       itunes_keywords
                       itunes_block
                       directory
                       filename
                       domain );

our @RSS_IFIELDS = qw( title
                       description
                       author
                       pubdate_day
                       pubdate_date
                       pubdate_month
                       pubdate_year
                       pubdate_hour
                       pubdate_minute
                       pubdate_second
                       pubdate_zone
                       guid
                       itunes_subtitle
                       itunes_author
                       itunes_summary
                       itunes_duration_hour
                       itunes_duration_minute
                       itunes_duration_second
                       itunes_keywords
                       itunes_explicit
                       itunes_category
                       itunes_block
                       fileurl );

sub post_feed {
    my $vsap   = shift;
    my $ruid   = shift;
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    my $rss_dom;
    if( -f $rssfeeds ) {
	eval {
	    my $parser = new XML::LibXML;
	    $rss_dom   = $parser->parse_file( $rssfeeds )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
	    return;
	}
    }

    ## look for the rss set node
    my $rss_set;
    unless( ($rss_set) = $rss_dom->findnodes("/rssSet") ) {
        $vsap->error($_ERR{RSS_NOTFOUND} => "Could not locate rss set node");
        return;
    }

    ## load the rss using the provided ruid. 
    unless ($ruid) { 
        $vsap->error($_ERR{RSS_RUID_REQUIRED} => "ruid attribute is required.");
        return;
    }
    my $rss; 
    unless( ($rss) = $rss_set->findnodes(qq!./rss[\@ruid='$ruid']!)) { 
        $vsap->error($_ERR{RSS_RUID_NOTFOUND} => "Entry not found with specified ruid.");
        return;
    }

    ## determine document root
    my $doc_root;
    if ($vsap->is_vps()) {
        if ($rss->find('./domain') && $rss->findvalue('./domain')) {
            $doc_root = VSAP::Server::Modules::vsap::domain::get_docroot($rss->findvalue('./domain')) || VSAP::Server::Modules::vsap::domain::get_server_docroot();
            unless ($doc_root) {
                $vsap->error($_ERR{RSS_DOCROOT_ERROR} => "Could not determine document root");
                return;
            }
        }
        else {
            $vsap->error($_ERR{RSS_DOMAIN_NOTFOUND} => "Could not locate domain node");
            return;
        }
    }
    else {
        $doc_root = '/www/htdocs';
    }

    ## assemble feed to post
    my $feed_dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $feed_rss = $feed_dom->createElement('rss');
    $feed_rss->setAttribute( version => '2.0' );
    $feed_rss->setAttribute( 'xmlns:itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd');
    my $feed_channel = $feed_dom->createElement('channel');

    ## assemble channel
    if ($rss->find('./title') && $rss->findvalue('./title')) {
        $feed_channel->appendTextChild('title', $rss->findvalue('./title'));
    }
    if ($rss->find('./link') && $rss->findvalue('./link')) {
        $feed_channel->appendTextChild('link', $rss->findvalue('./link'));
    }
    if ($rss->find('./description') && $rss->findvalue('./description')) {
        $feed_channel->appendTextChild('description', $rss->findvalue('./description'));
    }
    if ($rss->find('./language') && $rss->findvalue('./language')) {
        $feed_channel->appendTextChild('language', $rss->findvalue('./language'));
    }
    if ($rss->find('./copyright') && $rss->findvalue('./copyright')) {
        $feed_channel->appendTextChild('copyright', $rss->findvalue('./copyright'));
    }
    if ($rss->find('./generator') && $rss->findvalue('./generator')) {
        $feed_channel->appendTextChild('generator', $rss->findvalue('./generator'));
    }
    if ($rss->find('./ttl') && $rss->findvalue('./ttl')) {
        $feed_channel->appendTextChild('ttl', $rss->findvalue('./ttl'));
    }
    if (
        ($rss->find('./image_url') && $rss->findvalue('./image_url'))
        && ($rss->find('./image_title') && $rss->findvalue('./image_title'))
        && ($rss->find('./image_link') && $rss->findvalue('./image_link'))
       ) {
        my $new = $feed_channel->appendChild($feed_dom->createElement('image'));
        if ($rss->find('./image_url')) {
            $new->appendTextChild('url', $rss->findvalue('./image_url'));
        }
        if ($rss->find('./image_title')) {
            $new->appendTextChild('title', $rss->findvalue('./image_title'));
        }
        if ($rss->find('./image_link')) {
            $new->appendTextChild('link', $rss->findvalue('./image_link'));
        }
        if ($rss->find('./image_width')) {
            $new->appendTextChild('width', $rss->findvalue('./image_width'));
        }
        if ($rss->find('./image_height')) {
            $new->appendTextChild('height', $rss->findvalue('./image_height'));
        }
        if ($rss->find('./image_description')) {
            $new->appendTextChild('description', $rss->findvalue('./image_description'));
        }
    }
    if ($rss->find('./category') && $rss->findvalue('./category')) {
        $feed_channel->appendTextChild('category', $rss->findvalue('./category'));
    }
    if (
        ($rss->find('./pubdate_day') && $rss->findvalue('./pubdate_day'))
        && ($rss->find('./pubdate_date') && $rss->findvalue('./pubdate_date'))
        && ($rss->find('./pubdate_month') && $rss->findvalue('./pubdate_month'))
        && ($rss->find('./pubdate_year') && $rss->findvalue('./pubdate_year'))
        && ($rss->find('./pubdate_hour') && $rss->findvalue('./pubdate_hour'))
        && ($rss->find('./pubdate_minute') && $rss->findvalue('./pubdate_minute'))
        && ($rss->find('./pubdate_second') && $rss->findvalue('./pubdate_second'))
        && ($rss->find('./pubdate_zone') && $rss->findvalue('./pubdate_zone'))
       ) {
        $feed_channel->appendTextChild('pubDate', $rss->findvalue('./pubdate_day').', '.$rss->findvalue('./pubdate_date').' '.$rss->findvalue('./pubdate_month').' '.$rss->findvalue('./pubdate_year').' '.$rss->findvalue('./pubdate_hour').':'.$rss->findvalue('./pubdate_minute').':'.$rss->findvalue('./pubdate_second').' '.$rss->findvalue('./pubdate_zone'));
    }
    if ($rss->find('./itunes_author') && $rss->findvalue('./itunes_author')) {
        $feed_channel->appendTextChild('itunes:author', $rss->findvalue('./itunes_author'));
    }
    if ($rss->find('./itunes_subtitle') && $rss->findvalue('./itunes_subtitle')) {
        $feed_channel->appendTextChild('itunes:subtitle', $rss->findvalue('./itunes_subtitle'));
    }
    if ($rss->find('./itunes_summary') && $rss->findvalue('./itunes_summary')) {
        $feed_channel->appendTextChild('itunes:summary', $rss->findvalue('./itunes_summary'));
    }
    if ($rss->find('./itunes_explicit') && $rss->findvalue('./itunes_explicit')) {
        $feed_channel->appendTextChild('itunes:explicit', $rss->findvalue('./itunes_explicit'));
    }
    if (
        ($rss->find('./itunes_owner_name') && $rss->findvalue('./itunes_owner_name'))
        || ($rss->find('./itunes_owner_email') && $rss->findvalue('./itunes_owner_email'))
       ) {
        my $new = $feed_channel->appendChild($feed_dom->createElement('itunes:owner'));
        if ($rss->find('./itunes_owner_name')) {
            $new->appendTextChild('itunes:name', $rss->findvalue('./itunes_owner_name'));
        }
        if ($rss->find('./itunes_owner_email')) {
            $new->appendTextChild('itunes:email', $rss->findvalue('./itunes_owner_email'));
        }
    }
    if ($rss->find('./itunes_image') && $rss->findvalue('./itunes_image')) {
        my $new = $feed_dom->createElement('itunes:image');
        $new->setAttribute( 'href' => $rss->findvalue('./itunes_image'));
        $feed_channel->appendChild($new);
    }
    if ($rss->find('./itunes_new-feed-url') && $rss->findvalue('./itunes_new-feed-url')) {
        $feed_channel->appendTextChild('itunes:new-feed-url', $rss->findvalue('./itunes_new-feed-url'));
    }
    if ($rss->find('./itunes_keywords') && $rss->findvalue('./itunes_keywords')) {
        $feed_channel->appendTextChild('itunes:keywords', $rss->findvalue('./itunes_keywords'));
    }
    if ($rss->find('./itunes_block') && $rss->findvalue('./itunes_block')) {
        $feed_channel->appendTextChild('itunes:block', $rss->findvalue('./itunes_block'));
    }
    if ($rss->find('./itunes_category') && $rss->findvalue('./itunes_category')) {
        my %categories;
        foreach ($rss->findnodes('./itunes_category')) {
            if ($_->findvalue('.')) {
                my ($group, $value) = split /::/, $_->findvalue('.');
                if ($value) {
                    push @{$categories{$group}}, $value;
                }
                else {
                    $categories{$group} = ();
                }
            }
        }
        foreach my $group (sort keys %categories) {
            my $new = $feed_dom->createElement('itunes:category');
            $new->setAttribute( 'text' => $group);
            foreach (@{$categories{$group}}) {
                my $sub = $feed_dom->createElement('itunes:category');
                $sub->setAttribute( 'text' => $_);
                $new->appendChild($sub);
            }
            $feed_channel->appendChild($new);
        }
    }

    ## assemble item(s)
    foreach my $item ($rss->findnodes('./item')) {
        my $feed_item = $feed_channel->appendChild($feed_dom->createElement('item'));

        if ($item->find('./title') && $item->findvalue('./title')) {
            $feed_item->appendTextChild('title', $item->findvalue('./title'));
        }
        if ($item->find('./description') && $item->findvalue('./description')) {
            $feed_item->appendTextChild('description', $item->findvalue('./description'));
        }
        if ($item->find('./author') && $item->findvalue('./author')) {
            $feed_item->appendTextChild('author', $item->findvalue('./author'));
        }
        if (
            ($item->find('./pubdate_day') && $item->findvalue('./pubdate_day'))
            && ($item->find('./pubdate_date') && $item->findvalue('./pubdate_date'))
            && ($item->find('./pubdate_month') && $item->findvalue('./pubdate_month'))
            && ($item->find('./pubdate_year') && $item->findvalue('./pubdate_year'))
            && ($item->find('./pubdate_hour') && $item->findvalue('./pubdate_hour'))
            && ($item->find('./pubdate_minute') && $item->findvalue('./pubdate_minute'))
            && ($item->find('./pubdate_second') && $item->findvalue('./pubdate_second'))
            && ($item->find('./pubdate_zone') && $item->findvalue('./pubdate_zone'))
           ) {
            $feed_item->appendTextChild('pubDate', $item->findvalue('./pubdate_day').', '.$item->findvalue('./pubdate_date').' '.$item->findvalue('./pubdate_month').' '.$item->findvalue('./pubdate_year').' '.$item->findvalue('./pubdate_hour').':'.$item->findvalue('./pubdate_minute').':'.$item->findvalue('./pubdate_second').' '.$item->findvalue('./pubdate_zone'));
        }
        if ($item->find('./guid') && $item->findvalue('./guid')) {
            $feed_item->appendTextChild('guid', $item->findvalue('./guid'));
        }
        if ($item->find('./itunes_subtitle') && $item->findvalue('./itunes_subtitle')) {
            $feed_item->appendTextChild('itunes:subtitle', $item->findvalue('./itunes_subtitle'));
        }
        if ($item->find('./itunes_author') && $item->findvalue('./itunes_author')) {
            $feed_item->appendTextChild('itunes:author', $item->findvalue('./itunes_author'));
        }
        if ($item->find('./itunes_summary') && $item->findvalue('./itunes_summary')) {
            $feed_item->appendTextChild('itunes:summary', $item->findvalue('./itunes_summary'));
        }
        if (
            ($item->find('./itunes_duration_hour') && $item->findvalue('./itunes_duration_hour'))
            && ($item->find('./itunes_duration_minute') && $item->findvalue('./itunes_duration_minute'))
            && ($item->find('./itunes_duration_second') && $item->findvalue('./itunes_duration_second'))
           ) {
            $feed_item->appendTextChild('itunes:duration', $item->findvalue('./itunes_duration_hour').':'.$item->findvalue('./itunes_duration_minute').':'.$item->findvalue('./itunes_duration_second'));
        }
        if ($item->find('./itunes_keywords') && $item->findvalue('./itunes_keywords')) {
            $feed_item->appendTextChild('itunes:keywords', $item->findvalue('./itunes_keywords'));
        }
        if ($item->find('./itunes_explicit') && $item->findvalue('./itunes_explicit')) {
            $feed_item->appendTextChild('itunes:explicit', $item->findvalue('./itunes_explicit'));
        }
        if ($item->find('./itunes_block') && $item->findvalue('./itunes_block')) {
            $feed_item->appendTextChild('itunes:block', $item->findvalue('./itunes_block'));
        }
        if ($item->find('./fileurl') && $item->findvalue('./fileurl')) {
            # set url
            my $url = new URI::URL $item->findvalue('./fileurl');
            my $filename = ($vsap->{user_dir} || '')
                           . $doc_root
                           . $url->path;

            # set length
            my $length;
            if (-f $filename) {
                $length = (stat $filename)[7];
            } else {
                my $ua = new LWP::UserAgent;
                if (defined $ua) {
                    my $resp = $ua->head($url);
                    $length = $resp->header('content-length') if defined $resp;
                }
            }
            $length ||= 1;

            # set type
            my ($type) = MIME::Types::by_suffix($filename);
            unless ($type) {
                if ($filename =~ /\.m4a/) {
                    $type = 'audio/x-m4a';
                }
                elsif ($filename =~ /\.m4b/) {
                    $type = 'audio/x-m4b';
                }
                elsif ($filename =~ /\.m4v/) {
                    $type = 'video/x-m4v';
                }
                else {
                    $type = 'application/unknown';
                }
            }

            my $new = $feed_dom->createElement('enclosure');
                $new->setAttribute( 'url' => $url->abs );
                $new->setAttribute( 'length' => $length );
                $new->setAttribute( 'type' => $type );
                $feed_item->appendChild($new);
        }
    }

    ## append this channel to rss
    $feed_rss->appendChild($feed_channel);

    ## append this rss to this document
    $feed_dom->setDocumentElement($feed_rss);

    ## write out dom to file
    if (
        ($rss->find('./directory') && $rss->findvalue('./directory'))
        && ($rss->find('./filename') && $rss->findvalue('./filename'))
       ) {
        my $directory = $rss->findvalue('./directory');
        $directory = '/' . $directory if ($directory =~ /^[^\/]/);
        $directory .= '/' if ($directory =~ /[^\/]$/);
        $directory = ($vsap->{user_dir} || '')
                        . $doc_root
                        . $directory;
        my $feed_file = $directory . $rss->findvalue('./filename');
        REWT: {
            local $> = 0;
            local $> = (stat($doc_root))[4] || $>;
            unless (-d $directory) {
                eval { mkpath($directory) };
                if ($@) {
                    $vsap->error($_ERR{RSS_MKDIR_ERROR} => "Error making dir $directory: $@");
                    return;
                }
            }
            $feed_dom->toFile($feed_file, 1);
        }
    }

    return 1;
}

package VSAP::Server::Modules::vsap::web::rss::get::parameters;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    ## build the dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:get:parameters' );

    # append current year to dom for benefit of publication date
    my ($curyear) = (gmtime(time()))[5];
    $curyear += 1900;
    $root->appendTextChild(current_year => $curyear);

    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::load::feed;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    my $rss_dom;
    if( -f $rssfeeds ) {
	eval {
	    my $parser = new XML::LibXML;
	    $rss_dom   = $parser->parse_file( $rssfeeds )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
	    return;
	}
    }

    ## build the dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:load:feed' );

  BUILD_DOM: {
	last BUILD_DOM unless $rss_dom;

	my $node;
	if( $xmlobj->child('ruid') && $xmlobj->child('ruid')->value ) {
	    my $ruid = $xmlobj->child('ruid')->value;
	    if( ($node) = $rss_dom->findnodes("/rssSet/rss[\@ruid='$ruid']") ) {
                $root->appendChild($node);
	    }
	    else {
		$vsap->error($_ERR{RSS_RUID_NOTFOUND} => "Entry '$ruid' not found");
		return;
	    }
	}
	elsif( ($node) = $rss_dom->findnodes("/rssSet") ) {
            $root->appendChild($node);
	}
    }

    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::load::item;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    my $rss_dom;
    if( -f $rssfeeds ) {
	eval {
	    my $parser = new XML::LibXML;
	    $rss_dom   = $parser->parse_file( $rssfeeds )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
	    return;
	}
    }

    ## build the dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:load:item' );

  BUILD_DOM: {
	last BUILD_DOM unless $rss_dom;

	my $node;
	if( $xmlobj->child('iuid') && $xmlobj->child('iuid')->value ) {
	    my $iuid = $xmlobj->child('iuid')->value;
	    if( ($node) = $rss_dom->findnodes("/rssSet/rss/item[\@iuid='$iuid']") ) {
                $root->appendChild($node);
	    }
	    else {
		$vsap->error($_ERR{RSS_IUID_NOTFOUND} => "Entry '$iuid' not found");
		return;
	    }
	}
	elsif( ($node) = $rss_dom->findnodes("/rssSet") ) {
            $root->appendChild($node);
	}
    }

    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::add::feed;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    ## see if the document exists; load it
    my $rss_dom;
    if( -f $rssfeeds ) {
	eval {
	    my $parser = new XML::LibXML;
	    $rss_dom   = $parser->parse_file( $rssfeeds )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
	    return;
	}
    }

    ## build the new document
    unless( $rss_dom ) {
	$rss_dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
        $rss_dom->createInternalSubset( "rss", undef, 'rss.dtd' );
    }

    ## look for the rss set node
    my $rss_set;
    unless( ($rss_set) = $rss_dom->findnodes("/rssSet") ) {
	$rss_set = $rss_dom->createElement('rssSet');
	$rss_set->setAttribute( name => "Pod Casts" );
	$rss_set->setAttribute( version => "1.0" );
    }

    my $rss; 

    # If we are editing this node, we need to load the rss using the provided ruid. 
    # or error out if we don't have that element. 
    if ($xmlobj->child('edit')) { 
    	unless ($xmlobj->child('ruid') && $xmlobj->child('ruid')->value) { 
	    $vsap->error($_ERR{RSS_RUID_REQUIRED} => "ruid attribute is required.");
	    return;
	}

	my $ruid = $xmlobj->child('ruid')->value;

	unless( ($rss) = $rss_set->findnodes(qq!./rss[\@ruid='$ruid']!)) { 
            $vsap->error($_ERR{RSS_RUID_NOTFOUND} => "Entry not found with specified ruid.");
            return;
        }
    }
    else { 
    	my $ug = new Data::UUID; 
        ## add new node, creating the ruid. 
        $rss = $rss_dom->createElement('rss');
        $rss->setAttribute( version => '2.0' );
        $rss->setAttribute( ruid => $ug->create_str());
    }

    ## By here we have an rss either by locating the old one, or by creating a new one. 
    for my $field ( @RSS_RFIELDS ) {
        next unless $xmlobj->child("$field");
        foreach ($rss->findnodes("./$field")) {
            $rss->removeChild($_);
        }
        foreach ($xmlobj->children("$field")) {
            ## FIXME: should encode this stuff?
            $rss->appendTextChild("$field", $_->value || '');
        }
    }

    ## record epoch create
    unless ($xmlobj->child('edit')) { 
        if( my($epoch_create) = $rss->findnodes('./epoch_create') ) {
            $rss->removeChild($epoch_create);
        }
        $rss->appendTextChild('epoch_create', time);
    }

    ## record epoch modify
    if( my($epoch_modify) = $rss->findnodes('./epoch_modify') ) {
        $rss->removeChild($epoch_modify);
    }
    $rss->appendTextChild('epoch_modify', time);

    ## FIXME: any validation checks we need to do?

    ## only do this if rss is valid
    $rss_set->appendChild($rss);

    ## append this rss set to this document
    $rss_dom->setDocumentElement($rss_set);

    ## write out dom to file
    $rss_dom->toFile($rssfeeds, 1);

    ## post feed
    my $feed_uid = $rss->getAttribute('ruid');
    unless (VSAP::Server::Modules::vsap::web::rss::post_feed($vsap, $feed_uid)) {
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:add:feed');
    $root->appendChild($rss_set);
    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::add::item;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    ## see if the document exists; load it
    my $rss_dom;
    if( -f $rssfeeds ) {
	eval {
	    my $parser = new XML::LibXML;
	    $rss_dom   = $parser->parse_file( $rssfeeds )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
	    return;
	}
    }
    else {
        $vsap->error($_ERR{RSS_XML_ERROR} => "Could not locate $RSSFEEDS");
        return;
    }

    ## look for the rss set node
    my $rss_set;
    unless( ($rss_set) = $rss_dom->findnodes("/rssSet") ) {
        $vsap->error($_ERR{RSS_NOTFOUND} => "Could not locate rss set node");
        return;
    }

    ## look for the rss node
    unless ($xmlobj->child('ruid') && $xmlobj->child('ruid')->value) { 
	    $vsap->error($_ERR{RSS_RUID_REQUIRED} => "ruid attribute is required.");
	    return;
	}
    my $ruid = $xmlobj->child('ruid')->value;
    my $rss;
    unless( ($rss) = $rss_set->findnodes(qq!./rss[\@ruid='$ruid']!) ) {
        $vsap->error($_ERR{RSS_NOTFOUND} => "Could not locate rss node");
        return;
    }

    my $item; 

    # If we are editing this node, we need to load the rss using the provided iuid. 
    # or error out if we don't have that element. 
    if ($xmlobj->child('edit')) {
    	unless ($xmlobj->child('iuid') && $xmlobj->child('iuid')->value) { 
	    $vsap->error($_ERR{RSS_IUID_REQUIRED} => "iuid attribute is required.");
	    return;
	}

	my $iuid = $xmlobj->child('iuid')->value;

	unless( ($item) = $rss->findnodes(qq!./item[\@iuid='$iuid']!)) { 
            $vsap->error($_ERR{RSS_IUID_NOTFOUND} => "Entry not found with specified iuid.");
            return;
        }
    }
    else { 
    	my $ug = new Data::UUID; 
        ## add new node, creating the iuid. 
        $item = $rss_dom->createElement('item');
        $item->setAttribute( iuid => $ug->create_str());
    }

    ## By here we have an item either by locating the old one, or by creating a new one. 
    for my $field ( @RSS_IFIELDS ) {
        next unless $xmlobj->child("$field");
        foreach ($item->findnodes("./$field")) {
            $item->removeChild($_);
        }
        foreach ($xmlobj->children("$field")) {
            ## FIXME: should encode this stuff?
            $item->appendTextChild("$field", $_->value || '');
        }
    }

    ## record epoch create
    unless ($xmlobj->child('edit')) { 
        if( my($epoch_create) = $item->findnodes('./epoch_create') ) {
            $item->removeChild($epoch_create);
        }
        $item->appendTextChild('epoch_create', time);
    }

    ## record epoch modify
    if( my($epoch_modify) = $item->findnodes('./epoch_modify') ) {
        $item->removeChild($epoch_modify);
    }
    $item->appendTextChild('epoch_modify', time);

    ## FIXME: any validation checks we need to do?

    ## only do this if item is valid
    $rss->appendChild($item);

    ## append this rss to the rss set node
    $rss_set->appendChild($rss);

    ## append this rss set to this document
    $rss_dom->setDocumentElement($rss_set);

    ## write out dom to file
    $rss_dom->toFile($rssfeeds, 1);

    ## post feed
    my $feed_uid = $rss->getAttribute('ruid');
    unless (VSAP::Server::Modules::vsap::web::rss::post_feed($vsap, $feed_uid)) {
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:add:item');
    $root->appendChild($rss_set);
    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::delete::feed;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    my $rss_dom;
    return unless -f $rssfeeds;

    eval {
        my $parser = new XML::LibXML;
        $rss_dom     = $parser->parse_file( $rssfeeds )
          or die;
    };

    if( $@ ) {
        $@ =~ s/\n//;
        $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
        return;
    }

    my @ruids = ();
    for my $ruid ( map { $_->value } $xmlobj->children('ruid') ) {
        if( my($node) = $rss_dom->findnodes("/rssSet/rss[\@ruid='$ruid']") ) {
            ## determine document root
            my $doc_root;
            if ($vsap->is_vps()) {
                if ($node->find('./domain') && $node->findvalue('./domain')) {
                    $doc_root = VSAP::Server::Modules::vsap::domain::get_docroot($node->findvalue('./domain')) || VSAP::Server::Modules::vsap::domain::get_server_docroot();
                    unless ($doc_root) {
                        $vsap->error($_ERR{RSS_DOCROOT_ERROR} => "Could not determine document root");
                        return;
                    }
                }
                else {
                    $vsap->error($_ERR{RSS_DOMAIN_NOTFOUND} => "Could not locate domain node");
                    return;
                }
            }
            else {
                $doc_root = '/www/htdocs';
            }

            ## unlink existing feed file
            my $directory = $node->findvalue('./directory');
            $directory = '/' . $directory if ($directory =~ /^[^\/]/);
            $directory .= '/' if ($directory =~ /[^\/]$/);
            $directory = ($vsap->{user_dir} || '')
                         . $doc_root
                         . $directory;
            my $feed_file = $directory . $node->findvalue('./filename');
            REWT: {
                local $> = 0;
                local $> = (stat($feed_file))[4] || $>;
                unlink $feed_file if (-f $feed_file);
            }

            ## remove child node
            if( my($orphan) = $node->parentNode->removeChild($node) ) {
                push @ruids, $ruid;
            }
            else {
                $vsap->error($_ERR{RSS_XML_ERROR} => "Error removing node for '$ruid': $!");
                return;
            }
        }
        else {
            $vsap->error($_ERR{RSS_NOTFOUND} => "XML node for '$ruid' not found");
            return;
        }
    }

    ## write out dom to file
    $rss_dom->toFile($rssfeeds, 1);

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:delete:feed');
    $root->appendTextChild('ruid', $_) for ( @ruids );
    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::delete::item;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $rssfeeds = $vsap->{cpxbase} . "/$RSSFEEDS";

    my $rss_dom;
    return unless -f $rssfeeds;

    eval {
        my $parser = new XML::LibXML;
        $rss_dom     = $parser->parse_file( $rssfeeds )
          or die;
    };

    if( $@ ) {
        $@ =~ s/\n//;
        $vsap->error($_ERR{RSS_XML_ERROR} => "Error parsing $RSSFEEDS: $@");
        return;
    }

    my @ruids = ();
    my @iuids = ();
    for my $iuid ( map { $_->value } $xmlobj->children('iuid') ) {
        if( my($node) = $rss_dom->findnodes("/rssSet/rss/item[\@iuid='$iuid']") ) {
            push @ruids, $node->parentNode->getAttribute('ruid');
            if( my($orphan) = $node->parentNode->removeChild($node) ) {
                push @iuids, $iuid;
            }
            else {
                $vsap->error($_ERR{RSS_XML_ERROR} => "Error removing node for '$iuid': $!");
                return;
            }
        }
        else {
            $vsap->error($_ERR{RSS_NOTFOUND} => "XML node for '$iuid' not found");
            return;
        }
    }

    ## write out dom to file
    $rss_dom->toFile($rssfeeds, 1);

    ## repost feed(s)
    for ( @ruids ) {
        unless (VSAP::Server::Modules::vsap::web::rss::post_feed($vsap, $_)) {
            return;
        }
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:delete:item');
    $root->appendTextChild('iuid', $_) for ( @iuids );
    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::web::rss::post::feed;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    unless ($xmlobj->child('ruid') && $xmlobj->child('ruid')->value) {
        $vsap->error($_ERR{RSS_RUID_REQUIRED} => "ruid attribute is required.");
        return;
    }
    my $ruid = $xmlobj->child('ruid')->value;
    unless (VSAP::Server::Modules::vsap::web::rss::post_feed($vsap, $ruid)) {
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'web:rss:post:feed' );
    $dom->documentElement->appendChild($root);

    return;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::web::rss - VSAP rss podcast

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::web::rss;
  blah blah blah

=head1 DESCRIPTION

The following fields are used in the rssfeeds:

title, link, description, language, copyright, pubdate_day
pubdate_date, pubdate_month, pubdate_year, pubdate_hour
pubdate_minute, pubdate_second, pubdate_zone, category
generator, ttl, image_url, image_title, image_link, image_width
image_height, image_description, itunes_author, itunes_subtitle
itunes_summary, itunes_explicit, itunes_owner_name, itunes_owner_email
itunes_image, itunes_category, itunes_new-feed-url, itunes_keywords
itunes_block, directory, filename, epoch_create, epoch_modify

item fields:

title, description, author, pubdate_day, pubdate_date, 
pubdate_month, pubdate_year, pubdate_hour, pubdate_minute, 
pubdate_second, pubdate_zone, guid, itunes_subtitle, itunes_author, 
itunes_summary, itunes_duration_hour, itunes_duration_minute, 
itunes_duration_second, itunes_keywords, itunes_explicit, 
itunes_block, fileurl, epoch_create, epoch_modify

Any of the following packages may be used to access rssfeeds entries:

=head2 web:rss:load:feed

Returns one or all rss entries in the rssfeeds.

Example:

  <vsap type="web:rss:load:feed"/>

Returns:

  <vsap type="web:rss:load:feed">
    <rssSet name="Pod Casts" version="1.0">
      <rss version="2.0" ruid="067AC368-9A50-11DA-83C9-E82CC6822D09">
        <title>My New Podcast</title>
        <link>http://www.mypodcastsite.com</link>
        <description>We talk about all kinds of stuff and then some.</description>
        <language>en-us</language>
        <copyright>2006 mpc media ventures</copyright>
        <pubdate_day>Mon</pubdate_day>
        <pubdate_date>13</pubdate_date>
        <pubdate_month>Feb</pubdate_month>
        <pubdate_year>2006</pubdate_year>
        <pubdate_hour>08</pubdate_hour>
        <pubdate_minute>30</pubdate_minute>
        <pubdate_second>01</pubdate_second>
        <pubdate_zone>-0500</pubdate_zone>
        <category>Comedy</category>
        <itunes_author>Joe Nobody</itunes_author>
        <itunes_subtitle>A Show about nothing.</itunes_subtitle>
        <itunes_summary>We talk about all kinds of stuff and then some.</itunes_summary>
        <itunes_explicit>no</itunes_explicit>
        <itunes_owner_name>mpc media ventures</itunes_owner_name>
        <itunes_owner_email>podcast@mypodcastsite.com</itunes_owner_email>
        <itunes_image/>
        <itunes_category>Comedy::</itunes_category>
        <itunes_category>Movies &amp; Television::</itunes_category>
        <itunes_category>Technology::Podcasting</itunes_category>
        <itunes_block/>
        <directory>podcast</directory>
        <filename>my_new_podcast.rss</filename>
        <epoch_create>1139587945</epoch_create>
        <epoch_modify>1139587945</epoch_modify>
        <item iuid="64514444-9A50-11DA-83C9-E82CC6822D09">
          <title>Show 101 - Talk Talk</title>
          <description>We talk about the show, we may need to get a life.</description>
          <author>Joe Nobody</author>
          <pubdate_day>Wen</pubdate_day>
          <pubdate_date>15</pubdate_date>
          <pubdate_month>Feb</pubdate_month>
          <pubdate_year>2006</pubdate_year>
          <pubdate_hour>18</pubdate_hour>
          <pubdate_minute>30</pubdate_minute>
          <pubdate_second>00</pubdate_second>
          <pubdate_zone>-0500</pubdate_zone>
          <itunes_subtitle>Our first show.</itunes_subtitle>
          <itunes_author>Joe Nobody</itunes_author>
          <itunes_summary>We talk about the show, we may need to get a life.</itunes_summary>
          <itunes_duration_hour>00</itunes_duration_hour>
          <itunes_duration_minute>53</itunes_duration_minute>
          <itunes_duration_second>26</itunes_duration_second>
          <itunes_keywords>talk, show, nothing</itunes_keywords>
          <itunes_explicit>no</itunes_explicit>
          <itunes_block/>
          <fileurl>http://www.mypodcastsite.com/podcast/show101.mp3</fileurl>
          <epoch_create>1139588103</epoch_create>
          <epoch_modify>1139588398</epoch_modify>
        </item>
      </rss>
    </rssSet>
  </vsap>    

Example:

  <vsap type="web:rss:load:feed">
    <ruid>067AC368-9A50-11DA-83C9-E82CC6822D09</ruid>
  </vsap>

Returns:

  <vsap type="web:rss:load:feed">
    <rss version="2.0" ruid="067AC368-9A50-11DA-83C9-E82CC6822D09">
      <title>My Other Podcast</title>
      <link>http://www.mypodcastsite.com</link>
      <description>This is a show.</description>
      <directory>podcast</directory>
      <filename>my_other_podcast.rss</filename>
    </rss>
  </vsap>

=head2 web:rss:load:item

Returns one item entry from the rss in the rssfeeds.

Example:

  <vsap type="web:rss:load:item">
    <iuid>64514444-9A50-11DA-83C9-E82CC6822D09</iuid>
  </vsap>

Returns:

  <vsap type="web:rss:load:item">
    <item iuid="64514444-9A50-11DA-83C9-E82CC6822D09">
      <title>Show 101 - Talk Talk</title>
      <description>We talk about the show, we may need to get a life.</description>
      <author>Joe Nobody</author>
      <pubdate_day>Wen</pubdate_day>
      <pubdate_date>15</pubdate_date>
      <pubdate_month>Feb</pubdate_month>
      <pubdate_year>2006</pubdate_year>
      <pubdate_hour>18</pubdate_hour>
      <pubdate_minute>30</pubdate_minute>
      <pubdate_second>00</pubdate_second>
      <pubdate_zone>-0500</pubdate_zone>
      <itunes_subtitle>Our first show.</itunes_subtitle>
      <itunes_author>Joe Nobody</itunes_author>
      <itunes_summary>We talk about the show, we may need to get a life.</itunes_summary>
      <itunes_duration_hour>00</itunes_duration_hour>
      <itunes_duration_minute>53</itunes_duration_minute>
      <itunes_duration_second>26</itunes_duration_second>
      <itunes_keywords>talk, show, nothing</itunes_keywords>
      <itunes_explicit>no</itunes_explicit>
      <itunes_block/>
      <fileurl>http://www.mypodcastsite.com/podcast/show101.mp3</fileurl>
      <epoch_create>1139588103</epoch_create>
      <epoch_modify>1139588398</epoch_modify>
    </item>
  </vsap>    

=head2 web:rss:add:feed

Adds one rss entry to the rssfeeds. Supports optional 'edit', will
edit that rss entry in the rssfeeds.

Example:

  <vsap type="web:rss:add:feed">
    <title>Yet Another Podcast</title>
    <link>http://www.mypodcastsite.com</link>
    <description>This is yet another show.</description>
    <directory>podcast</directory>
    <filename>yet_another_podcast.rss</filename>
  </vsap>

To edit an rss entry, add an E<lt>edit/E<gt> node:

  <vsap type="web:rss:add:feed">
    <edit/>
    <ruid>58f202ac-22cf-11d1-b12d-002035b29092</ruid>
    <title>My Newest Podcast</title>
  </vsap>

The rssSet node containg all rss entries is returned on a successful add:

  <vsap type="web:rss:add:feed">
    <rssSet name="Pod Casts" version="1.0">
      <rss version="2.0" ruid="067AC368-9A50-11DA-83C9-E82CC6822D09">
        <title>My New Podcast</title>
        <link>http://www.mypodcastsite.com</link>
        <description>We talk about all kinds of stuff and then some.</description>
        <language>en-us</language>
        ...
      </rss>
      ... 
    </rssSet>
  </vsap>

=head2 web:rss:add:item

Adds one item entry entry to an rss entry in the rssfeeds. Supports 
optional 'edit', will edit that item entry in the rssfeeds.

Example:

  <vsap type="web:rss:add:item">
    <ruid>58f202ac-22cf-11d1-b12d-002035b29092</ruid>
    <title>Show 101 - Talk Talk</title>
    <description>We talk about the show, we may need to get a life.</description>
    <author>Joe Nobody</author>
    <fileurl>http://www.mypodcastsite.com/podcast/show101.mp3</fileurl>
    ...
  </vsap>

To edit an item entry, add an E<lt>edit/E<gt> node:

  <vsap type="web:rss:add:feed">
    <edit/>
    <ruid>58f202ac-22cf-11d1-b12d-002035b29092</ruid>
    <iuid>64514444-9A50-11DA-83C9-E82CC6822D09</iuid>
    <title>Show 101 - This is a new title</title>
  </vsap>

The rssSet node containg all rss entries is returned on a successful add:

  <vsap type="web:rss:add:item">
    <rssSet name="Pod Casts" version="1.0">
      <rss version="2.0" ruid="58f202ac-22cf-11d1-b12d-002035b29092">
        <title>My New Podcast</title>
        <link>http://www.mypodcastsite.com</link>
        <description>We talk about all kinds of stuff and then some.</description>
        <language>en-us</language>
        ...
        <item>
          <iuid>64514444-9A50-11DA-83C9-E82CC6822D09</iuid>
          <title>Show 101 - This is a new title</title>
        ...
        </item>
      </rss>
      ... 
    </rssSet>
  </vsap>

=head2 web:rss:delete:feed

Deletes one or more rss entries from the rssfeeds

Example:

  <vsap type="web:rss:delete:feed">
    <ruid>58f202ac-22cf-11d1-b12d-765431b29092</ruid>
    <ruid>2395abef-22cf-11d1-b12d-123456b29092</ruid>
  </vsap>

Returns:

  <vsap type="web:rss:delete:feed">
    <ruid>58f202ac-22cf-11d1-b12d-765431b29092</ruid>
    <ruid>2395abef-22cf-11d1-b12d-123456b29092</ruid>
  </vsap>

=head2 web:rss:delete:item

Deletes one or more rss items from the rssfeeds

Example:

  <vsap type="web:rss:delete:item">
    <iuid>64514444-9A50-11DA-83C9-E82CC6822D09</iuid>
    <iuid>893DA444-9A50-11DA-83C9-E82CC6822D09</iuid>
  </vsap>

Returns:

  <vsap type="web:rss:delete:item">
    <iuid>64514444-9A50-11DA-83C9-E82CC6822D09</iuid>
    <iuid>893DA444-9A50-11DA-83C9-E82CC6822D09</iuid>
  </vsap>

=head2 web:rss:post:feed

Posts rss entry into an RSS 2.0 syndication outfile.

Example:

  <vsap type="web:rss:post:feed">
    <ruid>58f202ac-22cf-11d1-b12d-002035b29092</ruid>
  </vsap>

Returns:

  <vsap type="web:rss:post:feed" />

=head1 NOTES

=head1 SEE ALSO

=over 4

=item 1

F<http://blogs.law.harvard.edu/tech/rss/>

=item 2

F<http://www.apple.com/itunes/podcasts/techspecs.html>

=item 3

F<http://asg.web.cmu.edu/rfc/rfc822.html>

=back

=head1 AUTHOR

Kevin Whyte

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.
  
=cut
