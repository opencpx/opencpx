package VSAP::Server::Modules::vsap::webmail::distlist;

use 5.008001;
use strict;
use warnings;
use XML::LibXML;

our $VERSION = '0.02';

our %_ERR = ( WM_BAD_LIST       => 100,
	      WM_BAD_LISTID     => 101,
	      WM_UNIQUE_LISTID  => 102,
	      WM_FS_ERROR       => 103,
	      WM_LISTNAME       => 104,
	      WM_LIST_GONE      => 105,
	      WM_ADDRESS        => 106,
	      WM_LIST_PARSE     => 107,
	      WM_FS_CREATE_PATH => 108,
	    );

our $DL_PATH = '/webmail/distlists';
our $DL_REGX = qr(^\d+$);

package VSAP::Server::Modules::vsap::webmail::distlist::add;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $home   = $vsap->{homedir};

    ## check required fields
    my $listid   = ( $xmlobj->child('listid') && $xmlobj->child('listid')->value
		     ? $xmlobj->child('listid')->value
		     : sprintf("%s", time() . sprintf("%05d", $$)) );
    my $listname = ( $xmlobj->child('name') && $xmlobj->child('name')->value
		     ? $xmlobj->child('name')->value
		     : '' );

    my $distlistdir = $vsap->{cpxbase} . $DL_PATH;

    unless( $listname && $xmlobj->children('entry') ) {
	$vsap->error($_ERR{WM_BAD_LIST} => "Need a listname and at least one address");
	return;
    }

    ## validate user data
    unless( $listid =~ $DL_REGX ) {
	$vsap->error($_ERR{WM_BAD_LISTID} => "Bad listid found");
	return;
    }

  CHECK_LISTS: {
	if( -f "$distlistdir/$listid" ) {
	    do {
		$vsap->error($_ERR{WM_UNIQUE_LISTID} => "listid '$listid' already exists");
		return;
	    } unless $xmlobj->child('edit');
	}

	## file does not exist; make sure this list name isn't already being used
	else {
	    unless( -d $distlistdir ) {
		system('mkdir', '-p', $distlistdir)
		  and do {
		      $vsap->error($_ERR{WM_FS_CREATE_PATH} => "Could not create distlist path");
		      return;
		  };
		chmod 0755, $distlistdir;
		last CHECK_LISTS;
	    }

	    ## KLUDGE: we do a fs grep rather than a pure XML search
	    ## KLUDGE: because of potential expenses incurred when we
	    ## KLUDGE: have lots of XML files to search through
	    opendir DIR, $distlistdir
	      or do {
		  $vsap->error($_ERR{WM_FS_ERROR} => "Could not open '$distlistdir': $!");
		  return;
	      };
	    for my $file ( grep { /$DL_REGX/ } readdir DIR ) {
		unless( system("grep", "-q",  "<name>$listname</name>", "$distlistdir/$file") ) {
		    closedir DIR;
		    $vsap->error($_ERR{WM_LISTNAME} => "'$listname' already exists");
		    return;
		}
	    }
	    closedir DIR;
	}
    }

    ## we're either overwriting an existing distlist, or creating a new one
    my $dl_dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    ## FIXME: is it ok to put in a fictional dtd?
    $dl_dom->createInternalSubset( 'distlist', undef, 'distlist.dtd' );

    ## FIXME: should we check values for anything special here?
    my $dl_node = $dl_dom->createElement('distlist');

    ## add 'listid' node
    my $node = $dl_dom->createElement('listid');
    $node->appendTextNode($listid);
    $dl_node->appendChild($node);

    ## add 'name' node
    $node = $dl_dom->createElement('name');
    $node->appendTextNode($listname);
    $dl_node->appendChild($node);

    ## add 'nickname' node
    if( $xmlobj->child('nickname') && $xmlobj->child('nickname')->value ) {
	$node = $dl_dom->createElement('nickname');
	$node->appendTextNode($xmlobj->child('nickname')->value);
	$dl_node->appendChild($node);
    }

    ## add 'description' node
    if( $xmlobj->child('description') && $xmlobj->child('description')->value ) {
	$node = $dl_dom->createElement('description');
	$node->appendTextNode($xmlobj->child('description')->value);
	$dl_node->appendChild($node);
    }

    ## add addresses node and subnodes
    my $entries_node = $dl_dom->createElement('entries');
    for my $entry ( $xmlobj->children('entry') ) {
	my $entry_node = $dl_dom->createElement('entry');

	## do first
	if( my $first = $entry->child('first')->value ) {
	    my $first_node = $dl_dom->createElement('first');
	    $first_node->appendTextNode($first);
	    $entry_node->appendChild($first_node);
	}

	## do last
	if( my $last = $entry->child('last')->value ) {
	    my $last_node = $dl_dom->createElement('last');
	    $last_node->appendTextNode($last);
	    $entry_node->appendChild($last_node);
	}

	## do address
	if( my $addr = $entry->child('address')->value ) {
	    my $addr_node = $dl_dom->createElement('address');
	    $addr_node->appendTextNode($addr);
	    $entry_node->appendChild($addr_node);
	}
	else {
	    $vsap->error($_ERR{WM_ADDRESS} => 'Email address bad or missing');
	    return;
	}

	$entries_node->appendChild($entry_node);
    }
    $dl_node->appendChild($entries_node);
    $dl_dom->setDocumentElement($dl_node);

    $dl_dom->toFile("$distlistdir/$listid", 1);


    # dbrian - took this out to prevent duplicate nodes in distlist XSLT;
    # it's not needed anyway:

    #my $return_dom = $vsap->{_result_dom}->createElement('vsap');
    #$return_dom->setAttribute( type => 'webmail:distlist:add' );
    #$return_dom->appendChild($dl_node->cloneNode(1));
    #$vsap->{_result_dom}->documentElement->appendChild($return_dom);

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:distlist:add' );
    $root->appendTextChild('status' => 'ok');
    $dom->documentElement->appendChild($root);

    return;
}

package VSAP::Server::Modules::vsap::webmail::distlist::list;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $root = load_distlists($vsap, $xmlobj, $dom);
    $dom->documentElement->appendChild($root) if (defined $root);

    return;
}

sub load_distlists {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $home   = (getpwuid($>))[7];

    my $limit  = ($xmlobj->child('limit') && $xmlobj->child('limit')->value =~ $DL_REGX
		  ? $xmlobj->child('limit')->value
		  : 0 );
    my $listid = ($xmlobj->child('listid') && $xmlobj->child('listid')->value
		  ? $xmlobj->child('listid')->value
		  : '' );

    my $distlistdir = $vsap->{cpxbase} . $DL_PATH;

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:distlist:list' );

    ## just load the listid
    if( $listid ) {
	unless( $listid =~ $DL_REGX ) {
	    $vsap->error($_ERR{WM_BAD_LISTID} => "Bad listid found");
	    return undef;
	}

	## load the list w/ this list id
	unless( -f "$distlistdir/$listid" && -r _ ) {
	    $vsap->error($_ERR{WM_LIST_GONE} => "No list by this name");
	    return undef;
	}

	my $dom;
	eval {
	    my $parser = new XML::LibXML;
	    $dom       = $parser->parse_file( "$distlistdir/$listid" )
	      or die;
	};

	if( $@ ) {
            $@ =~ s/\n//;
	    $vsap->error($_ERR{WM_LIST_PARSE} => "Parse error: $@");
	    return undef;
        }

        my $dl_node;
	if( ($dl_node) = $dom->findnodes('/distlist') ) {
            $root->appendChild($dl_node);
            return $root;
        }
        else {
	    $vsap->error($_ERR{WM_LIST_PARSE} => "Could not find distlist node in distlist");
	    return undef;
	}
    }

    ## no distlists?
    unless( -d $distlistdir ) {
	return $root;
    }

    ## read list of potential distlists
    opendir DIR, $distlistdir
      or do {
	  $vsap->error($_ERR{WM_BAD_LIST} => "Could not open distlist directory");
	  return undef;
      };

    ## parse distlists
    for my $list ( grep { /$DL_REGX/ } readdir DIR ) {
	my $dom;
	eval {
	    my $parser = new XML::LibXML;
	    $dom       = $parser->parse_file( "$distlistdir/$list" )
	      or die;
	};

	if( $@ ) {
	    $@ =~ s/\n//;
	    $vsap->error($_ERR{WM_LIST_PARSE} => "Error parsing list: $@");
            closedir DIR;
	    return undef;
	}

	next unless $dom;

	## FIXME: the 'limit' should truncate some of the addresses here

        my($dl_node) = $dom->findnodes('/distlist');
        unless( $dl_node ) {
            $vsap->error($_ERR{WM_LIST_PARSE} => "Could not find distlist node in distlist");
            next;
        }
        $root->appendChild($dl_node);
    }
    closedir DIR;

    return $root;
}

package VSAP::Server::Modules::vsap::webmail::distlist::delete;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $home   = $vsap->{homedir};

    my $distlistdir = $vsap->{cpxbase} . $DL_PATH;

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:distlist:delete' );

    for my $listid ( grep { /$DL_REGX/ } map { $_->value } $xmlobj->children('listid') ) {
	next unless     -f "$distlistdir/$listid";
	next unless unlink "$distlistdir/$listid";

	my $node = $root->ownerDocument->createElement('listid');
	$node->appendTextNode($listid);
	$root->appendChild($node);
    }

    $dom->documentElement->appendChild($root);
    return;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::distlist - VSAP webmail distribution list management

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::distlist;
  blah blah blah

=head1 DESCRIPTION

This module handles distribution list manipulation. Distribution lists
are not mailing lists; they are simply groups of email addresses for
use in webmail.

When an email address is removed from the addressbook, it will no
longer appear in the list of available addresses for a distribution
list, but it will still be in the distribution list itself until it
is removed; there is no inherent linkage between a distribution
list once it is created and the addressbook: each distribution list
keeps its own copy of email addresses.

This means that when an address is changed in the addressbook, it will
not be changed in the distribution list(s) it was once a member of.

=head2 VSAP::Server::Modules::vsap::webmail::distlist::add

Add a distribution list. With the E<lt>edit/E<gt> node, this can be
used to add or remove individual addresses from the list (the address
manipulation is done client-side, so we only see the net effect).

Example:

  <vsap type="vsap:webmail:distlist:add">
    <name>My Friends</name>
    <description>some of my friends</description>
    <entry>
      <address>joe@friend.com</address>
    </entry>
    <entry>
      <first>Bob</first>
      <last>Smith</last>
      <address>bob@friend.com</address>
    </entry>
    <entry>
      <first>Sally</first>
      <last>Satterfield</last>
      <address>sally@friend.com</address>
    </entry>
  </vsap>

Returns:

  <vsap type="vsap:webmail:distlist:add">
    <name>My Friends</name>
    <description>some of my friends</description>
    <entries>
      <entry>
        <address>joe@friend.com</address>
      </entry>
      <entry>
        <first>Bob</first>
        <last>Smith</last>
        <address>bob@friend.com</address>
      </entry>
      <entry>
        <first>Sally</first>
        <last>Satterfield</last>
        <address>sally@friend.com</address>
      </entry>
    </entries>
  </vsap>

Editing an existing entry (e.g., adding/removing users, changing
description, etc.):

  <vsap type="vsap:webmail:distlist:add">
    <edit/>
    <name>My Friends</name>
    <description>some of my friends</description>
    <entry>
      <first>michelle</first>
      <address>michelle@friend.com</address>
    </entry>
    <entry>
      <first>Dallman</first>
      <last>Ross</last>
      <address>dallman@friend.com</address>
    </entry>
    <entry>
      <first>David</first>
      <last>Tamkin</last>
      <address>david@friend.com</address>
    </entry>
  </vsap>

Returns:

  <vsap type="vsap:webmail:distlist:add">
    <name>My Friends</name>
    <description>some of my friends</description>
    <entries>
      <entry>
        <first>michelle</first>
        <address>michelle@friend.com</address>
      </entry>
      <entry>
        <first>Dallman</first>
        <last>Ross</last>
        <address>dallman@friend.com</address>
      </entry>
      <entry>
        <first>David</first>
        <last>Tamkin</last>
        <address>david@friend.com</address>
      </entry>
    </entries>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::distlist::list

Returns a list of distribution list nicknames and a specified number
of email addresses in that list. If no limit is given, no addresses
are returned.

If a list name is specified, only that list information will be
returned. If no limit is given and a listname is specified, all
addresses will be returned for that list.

Example:

  <vsap type="vsap:webmail:distlist:list">
    <limit>3</limit>
  </vsap>

Returns:

  <vsap type="vsap:webmail:distlist:list">
    <distlist>
      <listid>1234567890</listid>
      <name>Friends</name>
      <entries>
        <entry>
          <address>joe@friend.com</address>
        </entry>
        <entry>
          <first>Bob</first>
          <last>Smith</last>
          <address>bob@friend.com</address>
        </entry>
        <entry>
          <first>Sally</first>
          <last>Satterfield</last>
          <address>sally@friend.com</address>
        </entry>
      </entries>
    </distlist>

    <distlist>
      ...
    </distlist>
  </vsap>

Example:

  <vsap type="vsap:webmail:distlist:list">
    <listid>1234567890</listid>
  </vsap>

Returns:

  <vsap type="vsap:webmail:distlist:list">
    <distlist>
      <name>My Friends</name>
      <nickname>friends</nickname>
      <entries>
        <entry>
          <address>joe@friend.com</address>
        </entry>
        <entry>
          <first>Bob</first>
          <last>Smith</last>
          <address>bob@friend.com</address>
        </entry>
        <entry>
          <first>Sally</first>
          <last>Satterfield</last>
          <address>sally@friend.com</address>
        </entry>
        <entry>
          <first>michelle</first>
          <address>michelle@friend.com</address>
        </entry>
        <entry>
          <first>Dallman</first>
          <last>Ross</last>
          <address>dallman@friend.com</address>
        </entry>
        <entry>
          <first>David</first>
          <last>Tamkin</last>
          <address>david@friend.com</address>
        </entry>
      </entries>
      <description>This is a list of my friends</description>
    </distlist>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::distlist::delete

Removes one or more distribution lists. Individual email addresses are
not affected.

Example:

  <vsap type="vsap:webmail:distlist:delete">
    <listid>1234567890</listid>
  </vsap>

Returns:

  <vsap type="vsap:webmail:distlist:delete">
    <listid>1234567890</listid>
  </vsap>

=head1 NOTES

Some technical details. Distribution lists are stored in
F<~/.opencpx/distlists/> with a timestamp as the name of the file
containing XML data. By having non-smart keys, this will allow us (if
this were ever a requirement) someone to change the name of a list
during editing.

Advantages to using smart keys:

- quick lookup; we immediately know which list to use for edits, etc.

Disadvantages

- may have filesystem issues with some names (e.g., no "/" characters)
- renaming lists is a little extra work

Advantages to using non-smart keys:

- trivial renaming of lists

Disadvantages

- need to pass the "real" name of the list around (hidden form variable)
- when creating a new list, need to make sure listname is not
  duplicated anywhere (expensive, unless we use filesystem)

=head1 SEE ALSO

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
