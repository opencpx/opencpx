package VSAP::Server::Modules::vsap::webmail::addressbook;

use 5.008001;
use strict;
use warnings;
use Data::UUID;
use XML::LibXML;
use Quota;

our $VERSION = '0.01';

our %_ERR = ( WM_NOTFOUND         => 100,
              WM_ADDRESS_REQUIRED => 101,       # Deprecated
              WM_UNIQUE_ADDRESS   => 102,       # Deprecated
              WM_XML_ERROR        => 103,
              WM_UID_REQUIRED     => 104,
              WM_CANT_UPLOAD      => 105,
              WM_BAD_UPLOAD       => 106,
              WM_FTYPE_REQUIRED   => 107,
              WM_FTYPE_INVALID    => 108,
              WM_FILE_READ_ERROR  => 109,
              WM_FILE_WRITE_ERROR => 110,
              WM_LIMIT_REACHED    => 500,
            );

our $ADDRBOOK = 'addressbook.xml';
our $ADDRLIMIT = 500;

our @VCARD_FIELDS = qw( Last_Name
                        First_Name
                        Nickname
                        Email_Address
                        Phone_Personal
                        Phone_Business
                        Phone_Mobile
                        Phone_Pager
                        Phone_Other
                        Home_Street_Address
                        Home_City
                        Home_State
                        Home_Country
                        Home_Postal_Code
                        Company_Name
                        Co_Street_Address
                        Co_City
                        Co_State
                        Co_Country
                        Co_Postal_Code
                        Birthday
                        Website
                        Other
                        Comments );

########################################################################

sub _add_uids {
    my $dom = shift; 
    my $outfile = shift;
    my $ug = new Data::UUID;
    my ($root) = $dom->findnodes('/vCardSet');

    return unless ($root);
    my $version = $root->getAttribute('version') || 0;
    return unless ($version < 1.0);

    # Loop through each vCard and add a uid attribute. 
    foreach my $vcard ($dom->findnodes('/vCardSet/vCard')) { 
            next if $vcard->hasAttribute('uid');
        $vcard->setAttribute( uid => $ug->create_str());
    }

    # Now set the version flag. 
    $root->setAttribute(version => '1.0');

    my $tmpfile = VSAP::Server::Modules::vsap::webmail::addressbook::_tmpfilename($outfile);
    eval {
        # do toFile inside of an eval to trap DIE signals
        $dom->toFile($tmpfile, 1);
    };
    if (-s "$tmpfile") {
        rename($tmpfile, $outfile);
    }
    else {
        # zero size address book probably means user quota is full
        unlink($tmpfile);
    }
}

sub _destroy_CRs {
    my $dom = shift; 
    my $outfile = shift;
    my $ug = new Data::UUID;
    my ($root) = $dom->findnodes('/vCardSet');

    return unless ($root);
    my $version = $root->getAttribute('version') || 0;
    return unless ($version < 1.1);

    # Loop through each vCard and check child nodes for carriage returns
    foreach my $vcard ($dom->findnodes('/vCardSet/vCard')) { 
        my @children = $vcard->childNodes();
        foreach my $abnode (@{$vcard->childNodes()}) {
            my $abnn = $abnode->localname;
            next unless ($abnn);
            my $abnv = $abnode->textContent;
            if ($abnv =~ /\r/) { 
                $abnv =~ s/\r//g;
                $abnv =~ s/\n/ /g;
                my $new_abnode = $dom->createElement($abnn);
                $new_abnode->appendTextNode($abnv);
                $abnode->replaceNode($new_abnode);
            }
        }
    }

    # Now set the version flag. 
    $root->setAttribute(version => '1.1');

    my $tmpfile = VSAP::Server::Modules::vsap::webmail::addressbook::_tmpfilename($outfile);
    eval {
        # do toFile inside of an eval to trap DIE signals
        $dom->toFile($outfile, 1);
    };
    if (-s "$tmpfile") {
        rename($tmpfile, $outfile);
    }
    else {
        # zero size address book probably means user quota is full
        unlink($tmpfile);
    }
}

##
## _diskspace_availability() is lifted from cpx/modules/files.pm
## any changes here must be represented there (and vice versa)
##

sub _diskspace_availability {
    my($uid, $gid, $additional_usage) = @_;

    unless(defined($additional_usage)) {
        $additional_usage = 0;  # avoid uninitialized value warning
    }

  REWT: {
        local $> = $) = 0;    ## regain root:wheel privileges for a moment

        my $dev = Quota::getqcarg('/home');
        my($usage, $quota) = (Quota::query($dev, $uid))[0,1];
        if ($quota > 0) {
            $usage *= 1024;  # convert to bytes
            $quota *= 1024;  # convert to bytes
            my $new_usage = $usage + $additional_usage;
            if ( ($usage > $quota) || ($new_usage > $quota) ) {
                # already over, or will go over
                return 0;
            }
        }

        ## most of the calls to this function send in $vsap->{gid} here,
        ## but that value is something else, apparently,
        ## so i'm just doing this instead.  improve it if you like.
        ##   -michael
        $gid = (getpwuid($uid))[3];
        my($grp_usage, $grp_quota) = (Quota::query($dev, $gid, 1))[0,1];
        if($grp_quota > 0) {
            $grp_usage *= 1024;  # convert to bytes
            $grp_quota *= 1024;  # convert to bytes
            my $new_grp_usage = $grp_usage + $additional_usage;
            if(($grp_usage > $grp_quota) || ($new_grp_usage > $grp_quota)) {
                # already over, or will go over
                return 0;
            }
        }
  }

  return 1;
}

sub _load_addrbook {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $addrbook = $vsap->{cpxbase} . "/$ADDRBOOK";

    my $ab_dom;
    if( -f $addrbook ) {
        eval {
            my $parser = new XML::LibXML;
            $ab_dom     = $parser->parse_file( $addrbook )
              or die;
        };

        if( $@ ) {
            $@ =~ s/\n//;
            $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $ADDRBOOK: $@");
            return undef;
        }
    }

    # Handle the conversion from the old version of the addressbook formats if needed. 
    VSAP::Server::Modules::vsap::webmail::addressbook::_add_uids($ab_dom, $addrbook)
            if $ab_dom;

    # Find and remove any carriage returns found in the address book
    VSAP::Server::Modules::vsap::webmail::addressbook::_destroy_CRs($ab_dom, $addrbook)
            if $ab_dom;

    ## build the dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:load' );

  BUILD_DOM: {
        last BUILD_DOM unless $ab_dom;

        my $node;
        if( $xmlobj->child('uid') && $xmlobj->child('uid')->value ) {
            my $uid = $xmlobj->child('uid')->value;
            if( ($node) = $ab_dom->findnodes("/vCardSet/vCard[\@uid='$uid']") ) {
                $root->appendChild($node);
                return $root;
            }
            else {
                $vsap->error($_ERR{WM_NOTFOUND} => "Entry '$uid' not found");
                return undef;
            }
        }
        elsif( ($node) = $ab_dom->findnodes("/vCardSet") ) {
            $root->appendChild($node);
            return $root;
        }

        else {
            ## FIXME: should show empty?
            ## no email address looked for and
            ## no vCardSet in our DOM
        }
    }

    return $root;
}

sub _tmpfilename {
    my $filename = shift;
    my $tmpfilename = $filename;
    $tmpfilename =~ s/.xml$//;
    $tmpfilename .= "-" . time() . "-" . $$ . ".xml";
    return($tmpfilename);
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::load;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $root = VSAP::Server::Modules::vsap::webmail::addressbook::_load_addrbook($vsap, $xmlobj, $dom);
    $dom->documentElement->appendChild($root) if (defined $root);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::add;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $addrbook = $vsap->{cpxbase} . "/$ADDRBOOK";

    ## see if the document exists; load it
    my $ab_dom;
    if( -f $addrbook ) {
        eval {
            my $parser = new XML::LibXML;
            $ab_dom     = $parser->parse_file( $addrbook )
              or die;
        };

        if( $@ ) {
            $@ =~ s/\n//;
            $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $ADDRBOOK: $@");
            return;
        }
    }

    # Handle the conversion from the old version of the addressbook formats if needed. 
    VSAP::Server::Modules::vsap::webmail::addressbook::_add_uids($ab_dom,$addrbook)
        if ($ab_dom);

    ## build the new document
    unless( $ab_dom ) {
        $ab_dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
        $ab_dom->createInternalSubset( "vCard", undef, 'vcard.dtd' );
    }

    ## look for the vCardSet node
    my $vcard_set;
    unless( ($vcard_set) = $ab_dom->findnodes("/vCardSet") ) {
        $vcard_set = $ab_dom->createElement('vCardSet');
        $vcard_set->setAttribute( name => "Address Book" );
        $vcard_set->setAttribute( version => "1.0" );
    }

    # are we in edit mode?
    my $edit_mode;
    $edit_mode = ($xmlobj->child('edit')) ? 1 : 0;

    if (! $edit_mode) {
        # count number of contacts currently in address book; error out if limit reached
        my $count = 0;
        foreach ($ab_dom->findnodes('vCardSet/vCard')) {
            $count++;
        }
        if ( ($count + 1) > $ADDRLIMIT ) {
            $vsap->error($_ERR{WM_LIMIT_REACHED} => "addressbook limit of $ADDRLIMIT reached");
            return;
        }
    }

    my $vcard; 

    # If we are editing this node, we need to load the vcard using the provided uid. 
    # or error out if we don't have that element. 
    if ($edit_mode) {
        unless ($xmlobj->child('uid') && $xmlobj->child('uid')->value) { 
            $vsap->error($_ERR{WM_UID_REQUIRED} => "uid attribute is required.");
            return;
        }

        my $uid = $xmlobj->child('uid')->value;

        unless( ($vcard) = $vcard_set->findnodes(qq!./vCard[\@uid='$uid']!)) { 
            $vsap->error($_ERR{WM_NOTFOUND} => "Entry not found with specified uid.");
            return;
        }
    }
    else { 
        my $ug = new Data::UUID; 
        ## add new node, creating the uuid. 
        $vcard = $ab_dom->createElement('vCard');
        $vcard->setAttribute( version => '3.0' );
        $vcard->setAttribute( uid => $ug->create_str());
    }

    # Remove all the children nodes. We will re-add them below. 
    $vcard->removeChildNodes();

    # By here we havea vcard either by locating the old one, or by creating a new one. 
    for my $field ( @VCARD_FIELDS ) {
        next unless $xmlobj->child($field) && $xmlobj->child($field)->value;
        my $new = $ab_dom->createElement($field);
        ## FIXME: should encode this stuff?
        $new->appendTextNode($xmlobj->child($field)->value);
        $vcard->appendChild($new);
    }

    ## FIXME: any validation checks we need to do?

    ## only do this if vcard is valid
    $vcard_set->appendChild($vcard);

    ## append this address book set to this document
    $ab_dom->setDocumentElement($vcard_set);

    ## write out dom to file
    my $tmpfile = VSAP::Server::Modules::vsap::webmail::addressbook::_tmpfilename($addrbook);

  REWT: {
        local $> = $) = 0;    ## regain root:wheel privileges for a moment

        if (open my $addrbookfh, ">", $tmpfile) {
            binmode $addrbookfh;
            $ab_dom->toFH($addrbookfh, 1);
            close($addrbookfh);
            my ($addrbooksize) = (stat("$tmpfile"))[7] if (-e "$tmpfile");
            if ( (-e "$tmpfile") && ($addrbooksize > 0) ) {
                if ( VSAP::Server::Modules::vsap::webmail::addressbook::_diskspace_availability($vsap->{uid}, $vsap->{gid}, $addrbooksize) ) {
                    chmod 0644, $tmpfile;
                    chown $vsap->{uid}, (getpwuid($vsap->{uid}))[3], $tmpfile;
                    rename $tmpfile, $addrbook;
                }
                else {
                    unlink($tmpfile);
                    $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: quota exceeded");
                    return;
                }
            }
            else {
                unlink($tmpfile) if (-e "$tmpfile");
                $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: cause unknown (disk space exceeded?)");
                return;
            }
        }
        else {
            ## do something with the error ($!) here... 
            $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error opening address book $tmpfile: $!");
            return;
        }
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:add');
    $root->appendChild($vcard_set);
    $dom->documentElement->appendChild($root);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::delete;

use Carp qw(carp);

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};
    my $addrbook = $vsap->{cpxbase} . "/$ADDRBOOK";

    my $ab_dom;
    return unless -f $addrbook;

    eval {
        my $parser = new XML::LibXML;
        $ab_dom     = $parser->parse_file( $addrbook )
          or die;
    };

    if( $@ ) {
        $@ =~ s/\n//;
        $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $ADDRBOOK: $@");
        return;
    }

    # Handle the conversion from the old version of the addressbook formats if needed. 
    VSAP::Server::Modules::vsap::webmail::addressbook::_add_uids($ab_dom,$addrbook)
        if ($ab_dom);

    my @uids = ();
    for my $uid ( map { $_->value } $xmlobj->children('uid') ) {
        if( my($node) = $ab_dom->findnodes("/vCardSet/vCard[\@uid='$uid']") ) {
            if( my($orphan) = $node->parentNode->removeChild($node) ) {
                push @uids, $uid;
            }
            else {
                $vsap->error($_ERR{WM_XML_ERROR} => "Error removing node for '$uid': $!");
                return;
            }
        }
        else {
            $vsap->error($_ERR{WM_NOTFOUND} => "XML node for '$uid' not found");
            return;
        }
    }

  REWT: {
        local $> = $) = 0;    ## regain root:wheel privileges for a moment
        my $tmpfile = VSAP::Server::Modules::vsap::webmail::addressbook::_tmpfilename($addrbook);
        if (open my $addrbookfh, ">", $tmpfile) {
            binmode $addrbookfh;
            $ab_dom->toFH($addrbookfh, 1);
            close($addrbookfh);
            my ($addrbooksize) = (stat("$tmpfile"))[7] if (-e "$tmpfile");
            if ( (-e "$tmpfile") && ($addrbooksize > 0) ) {
                if ( VSAP::Server::Modules::vsap::webmail::addressbook::_diskspace_availability($vsap->{uid}, $vsap->{gid}, $addrbooksize) ) {
                    chmod 0644, $tmpfile;
                    chown $vsap->{uid}, (getpwuid($vsap->{uid}))[3], $tmpfile;
                    rename $tmpfile, $addrbook;
                }
                else {
                    unlink($tmpfile);
                    $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: quota exceeded");
                    return;
                }
            }
            else {
                unlink($tmpfile) if (-e "$tmpfile");
                $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: cause unknown (disk space exceeded?)");
                return;
            }
        }
        else {
            ## do something with the error ($!) here... 
            $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error opening address book $tmpfile: $!");
            return;
        }
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:delete');
    $root->appendTextChild('uid', $_) for ( @uids );
    $dom->documentElement->appendChild($root);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::list;

use Carp qw(carp);

our %SORT_BY = ( 
    firstname => 1, 
    lastname  => 1, 
    nickname  => 1, 
    email     => 1 
); 

our %SORT_TYPE = ( 
    ascending  => 1,
    descending => 1
); 

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $page = ( $xmlobj->child('page')
                 && $xmlobj->child('page')->value
                 && $xmlobj->child('page')->value =~ /^\d+$/
                 ? $xmlobj->child('page')->value
                 : 1 );

    my $sort_by = ( $xmlobj->child('sort_by')
                    && $xmlobj->child('sort_by')->value
                    && $SORT_BY{$xmlobj->child('sort_by')->value}
                    ? $xmlobj->child('sort_by')->value
                    : '' );

    my $sort_type = ( $xmlobj->child('sort_type')
                      && $xmlobj->child('sort_type')->value
                      && $SORT_TYPE{$xmlobj->child('sort_type')->value}
                      ? $xmlobj->child('sort_type')->value
                      : '' );

    my $search_value = ( $xmlobj->child('search_value')
                      && $xmlobj->child('search_value')->value
                      ? $xmlobj->child('search_value')->value
                      : '' );

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:list' );

  BUILD_LIST: {
      # 1. load source lists
      my $addresses = [];

      # load address book
      my $addressbook = VSAP::Server::Modules::vsap::webmail::addressbook::_load_addrbook($vsap, $xmlobj, $dom);
      if (defined $addressbook) {
          foreach ($addressbook->findnodes('vCardSet/vCard')) {
              push @{$addresses}, {
                  type          => 'individual',
                  listid        => '',
                  uid           => $_->hasAttribute('uid') ? $_->getAttribute('uid') : '',
                  firstname     => $_->findvalue('First_Name'),
                  lastname      => $_->findvalue('Last_Name'),
                  nickname      => $_->findvalue('Nickname'),
                  email         => [$_->findvalue('Email_Address')],
              };
          }
      }
        
      # load distribution list
      my $distlist = VSAP::Server::Modules::vsap::webmail::distlist::list::load_distlists($vsap, $xmlobj, $dom);
      if (defined $distlist) {
          foreach ($distlist->findnodes('distlist')) {
              my $email = [];
              foreach ($_->findnodes("entries/entry")) {
                  push @{$email}, $_->findvalue('address'); 
              }
              push @{$addresses}, {
                  type          => 'group',
                  listid        => $_->findvalue('listid'),
                  uid           => '', 
                  firstname     => $_->findvalue('name'),
                  lastname      => $_->findvalue('name'),
                  nickname      => $_->findvalue('nickname'),
                  email         => $email,
              };
          }
      }

      # 2. filter on search string
      my $filtered_addresses = [];

      if ($search_value) {
          foreach (@{$addresses}) {
               my @search_list = ($_->{firstname}, $_->{lastname}, $_->{nickname}, @{$_->{email}});
               push @{$filtered_addresses}, $_ if (grep {/$search_value/i} @search_list);
          }
      }
      else {
          $filtered_addresses = $addresses;
      }

      # 3. sort filtered list 
      unless ($sort_by) {
          $sort_by = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, 'addresses_sortby') || 'firstname';
      }
      unless ($sort_type) {
          $sort_type = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, 'addresses_order') || 'ascending';
      }
      my $sorted_addresses = [];
      my $sort_scheme; 
      if ($sort_type eq 'descending') {
          if ($sort_by eq 'email') {
              $sort_scheme = sub { lc $b->{$sort_by}[0] cmp lc $a->{$sort_by}[0]; };
          }
          else {
              $sort_scheme = sub { lc $b->{$sort_by} cmp lc $a->{$sort_by}; };
          }
      }
      else {
          if ($sort_by eq 'email') {
              $sort_scheme = sub { lc $a->{$sort_by}[0] cmp lc $b->{$sort_by}[0]; };
          }
          else {
              $sort_scheme = sub { lc $a->{$sort_by} cmp lc $b->{$sort_by}; };
          }
      }
      @{$sorted_addresses} = sort $sort_scheme @{$filtered_addresses};

      # 4. calculate paging

      my $view_length = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, 'addresses_per_page') || 10;
      $dom->documentElement->removeChild($dom->documentElement->findnodes("/vsap/vsap[\@type='webmail:options:load']"));
      my $num_addresses = @{$sorted_addresses} || 0;
      my $total_pages = ( $view_length > 0 && $num_addresses > 0)
                          ? ( ($num_addresses % $view_length)
                              ? (int ($num_addresses / $view_length) + 1)
                              : int ($num_addresses / $view_length) )
                          : 1;
      $total_pages ||= 1;
      $page ||= 1;
      $page = 1 if ($page > $total_pages);
      my $prev_page = ($page == 1) ? '' : $page - 1;
      my $next_page = ($page == $total_pages) ? '' : $page + 1;
      my $first_address = 1 + ($view_length * ($page - 1));
      $first_address = 0 if ($num_addresses < 1);
      my $last_address = $first_address + $view_length - 1;
      $last_address = $num_addresses if ($last_address > $num_addresses);
      $last_address = 0 if ($last_address < 1);

      # 5. assemble results

      $root->appendTextChild('num_addresses', $num_addresses);
      $root->appendTextChild('page', $page);
      $root->appendTextChild('total_pages', $total_pages);
      $root->appendTextChild('prev_page', $prev_page);
      $root->appendTextChild('next_page', $next_page);
      $root->appendTextChild('first_address', $first_address);
      $root->appendTextChild('last_address', $last_address);
      $root->appendTextChild('sort_by', $sort_by);
      $root->appendTextChild('sort_type', $sort_type);
      $root->appendTextChild('search_value', $search_value);
      if ($num_addresses) {
          for (my $i=$first_address-1; $i<=$last_address-1; $i++) {
              my $addr_node = $root->appendChild($dom->createElement('address'));
              $addr_node->appendTextChild('type', $sorted_addresses->[$i]->{type});
              $addr_node->appendTextChild('listid', $sorted_addresses->[$i]->{listid});
              $addr_node->appendTextChild('lastname', $sorted_addresses->[$i]->{lastname});
              $addr_node->appendTextChild('firstname', $sorted_addresses->[$i]->{firstname});
              $addr_node->appendTextChild('uid', $sorted_addresses->[$i]->{uid});
              $addr_node->appendTextChild('nickname', $sorted_addresses->[$i]->{nickname});
              foreach (@{$sorted_addresses->[$i]->{email}}) {
                  $addr_node->appendTextChild('email', $_);
              }
          }
      }

    }

    $dom->documentElement->appendChild($root);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::import;

use Carp qw(carp);
use Cwd qw(abs_path);
use Encode;
use Text::vCard::Addressbook;
use Text::ParseWords;

our %FILE_TYPE = ( 
    csv => 1,
    vcf => 1
); 

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $file_name = ( $xmlobj->child('file_name')
                      && $xmlobj->child('file_name')->value
                      ? $xmlobj->child('file_name')->value
                      : '' );

    my $file_type = ( $xmlobj->child('file_type')
                      && $xmlobj->child('file_type')->value
                      ? $xmlobj->child('file_type')->value
                      : '' );

    my $file_encoding = ( $xmlobj->child('file_encoding')
                          && $xmlobj->child('file_encoding')->value
                          ? $xmlobj->child('file_encoding')->value
                          : 'utf-8' );

    my $addrbook = $vsap->{cpxbase} . "/$ADDRBOOK";
    my $processed = 0;
    my $imported = 0;
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:import' );

    ## check for infile
    my $root_source_dir = $vsap->{tmpdir};
    my $full_path = abs_path("$root_source_dir/$file_name");
    if ( ($full_path !~ m!^\Q$root_source_dir\E!) || (!-e $full_path) ) {
        # if !$full_path, likely culprit is quota has been exceeded
        $vsap->error($_ERR{WM_CANT_UPLOAD} => "Invalid file name: $file_name");
        return;
    }

    ## validate infile, basic
    if ( (-z $full_path) || (-B $full_path) ) {
        unlink($full_path);
        $vsap->error($_ERR{WM_BAD_UPLOAD} => "Invalid file format: $file_name");
        return;
    }

    ## check for file type
    unless( $file_type ) {
        unlink($full_path);
        $vsap->error($_ERR{WM_FTYPE_REQUIRED} => "Empty or missing file type");
        return;
    }

    ## validate file type
    unless( $FILE_TYPE{$file_type} ) {
        unlink($full_path);
        $vsap->error($_ERR{WM_FTYPE_INVALID} => "Invalid file type: $file_type");
        return;
    }

    ## see if the document exists; load it
    my $ab_dom;
    if ( -f $addrbook ) {
        eval {
            my $parser = new XML::LibXML;
            $ab_dom     = $parser->parse_file( $addrbook )
              or die;
        };
        if ( $@ ) {
            unlink($full_path);
            $@ =~ s/\n//;
            $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $ADDRBOOK: $@");
            return;
        }
    }

    ## handle the conversion from the old version of the addressbook formats if needed. 
    VSAP::Server::Modules::vsap::webmail::addressbook::_add_uids($ab_dom,$addrbook)
        if ( $ab_dom );

    ## build the new document
    unless ( $ab_dom ) {
        $ab_dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
        $ab_dom->createInternalSubset( "vCard", undef, 'vcard.dtd' );
    }

    ## look for the vCardSet node
    my $vcard_set;
    unless ( ($vcard_set) = $ab_dom->findnodes("/vCardSet") ) {
        $vcard_set = $ab_dom->createElement('vCardSet');
        $vcard_set->setAttribute( name => "Address Book" );
        $vcard_set->setAttribute( version => "1.0" );
    }

    ## count number of contacts currently in address book
    my $count = 0;
    foreach ($ab_dom->findnodes('vCardSet/vCard')) {
        $count++;
    }

    ## process infile

    ## csv file type
    if ( $file_type eq 'csv' ) {

        ## open csv infile
        my $csv_infile;
        unless ( open (INFILE, "<:encoding($file_encoding)", $full_path) ) {
            unlink($full_path);
            $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $full_path");
            return;
        }
        while (<INFILE>) {
            my $curline = $_;
            chomp($curline);
            # check double quote count... if count is an odd number, 
            # then it is likely that the current entry spans multiple
            # lines where one (or more) carriage returns may be found
            # before the ending double quote is found.  (BUG22677)  
            my $double_quote_count = $curline =~ tr/"/"/;
            while ( ($double_quote_count % 2) == 1 ) {
                $curline .= <INFILE>;
                chomp($curline);
                $double_quote_count = $curline =~ tr/"/"/;
            }
            $curline =~ s/\r//g;
            push @$csv_infile, $curline;
        }
        close INFILE;

        ## parse field from the first line
        my $firstline = shift(@$csv_infile);
        if (($firstline =~ /\'/) && ($firstline !~ /\"/)) {
          # uh, oh... single quotes in fields that are not enclosed by double 
          # quotes; Text::ParseWords::parse_line() doesn't like this (BUG22677)
          $firstline =~ s/,/\",\"/g;
          $firstline = "\"$firstline\"";
        }
        my $fields;
        @$fields = parse_line(',', 0, $firstline);  ## Text::ParseWords::parse_line()

        ## process each csv infile record
        for ( @$csv_infile ) {
            ## parse the current line and hash the field values (if any)
            my @vals = parse_line(',', 0, $_);  ## Text::ParseWords::parse_line()
            next if ($#vals == -1);
            my $csv;
            for ( my $i=0; $i <=$#vals; $i++ ) {
                next unless ( defined($vals[$i]) );
                next if ( $vals[$i] eq '' );
                next if ( $vals[$i] eq '0/0/00' );
                $csv->{$fields->[$i]} = Encode::encode_utf8($vals[$i]);
            }

            ## add new node, creating the uuid. 
            my $ug = new Data::UUID;
            my $vcard = $ab_dom->createElement('vCard');
            $vcard->setAttribute( version => '3.0' );
            $vcard->setAttribute( uid => $ug->create_str() );

            ## name
            if ( $csv->{'First Name'} ) {
                $vcard->appendTextChild('First_Name', $csv->{'First Name'});
            }
            if ( $csv->{'Last Name'} ) {
                $vcard->appendTextChild('Last_Name', $csv->{'Last Name'});
            }
            if ($csv->{'Name'}) {
                $csv->{'Name'} =~ s/\s+$//g;
                if ($csv->{'Name'} =~ /(.*) (\S*?)$/) { 
                    $vcard->appendTextChild('First_Name', $1);
                    $vcard->appendTextChild('Last_Name', $2);
                }
                else {
                    # no white space ... presume first name only
                    $vcard->appendTextChild('First_Name', $csv->{'Name'});
                }
            }

            ## nickname
            $vcard->appendTextChild('Nickname', $csv->{'Nickname'})
                if ( $csv->{'Nickname'} );

            ## email
            $vcard->appendTextChild('Email_Address', $csv->{'E-mail Address'})
                if ( $csv->{'E-mail Address'} );
            $vcard->appendTextChild('Email_Address', $csv->{'Email'})
                if ( $csv->{'Email'} );

            ## phone
            $vcard->appendTextChild('Phone_Personal', $csv->{'Home Phone'})
                if ( $csv->{'Home Phone'} );
            $vcard->appendTextChild('Phone_Business', $csv->{'Business Phone'})
                if ( $csv->{'Business Phone'} );
            $vcard->appendTextChild('Phone_Mobile', $csv->{'Mobile Phone'})
                if ( $csv->{'Mobile Phone'} );
            $vcard->appendTextChild('Phone_Mobile', $csv->{'Home Mobile'})
                if ( $csv->{'Home Mobile'} );
            $vcard->appendTextChild('Phone_Pager', $csv->{'Pager'})
                if ( $csv->{'Pager'} );
            $vcard->appendTextChild('Phone_Other', $csv->{'Other Phone'})
                if ( $csv->{'Other Phone'} );

            ## address, home
            if ( $csv->{'Home Street'} ) {
                $vcard->appendTextChild('Home_Street_Address', $csv->{'Home Street'})
            }
            elsif ( $csv->{'Home Address'} ) {
                $vcard->appendTextChild('Home_Street_Address', $csv->{'Home Address'})
            }
            $vcard->appendTextChild('Home_City', $csv->{'Home City'})
                if ( $csv->{'Home City'} );
            $vcard->appendTextChild('Home_State', $csv->{'Home State'})
                if ( $csv->{'Home State'} );
            if ( $csv->{'Home Country'} ) {
                $vcard->appendTextChild('Home_Country', $csv->{'Home Country'});
            }
            elsif ( $csv->{'Home Country/Region'} ) {
                $vcard->appendTextChild('Home_Country', $csv->{'Home Country/Region'});
            }
            $vcard->appendTextChild('Home_Postal_Code', $csv->{'Home Postal Code'})
                if ( $csv->{'Home Postal Code'} );

            ## company name
            $vcard->appendTextChild('Company_Name', $csv->{'Company'})
                if ( $csv->{'Company'} );

            ## address, work
            $vcard->appendTextChild('Co_Street_Address', $csv->{'Business Street'})
                if ( $csv->{'Business Street'} );
            $vcard->appendTextChild('Co_Street_Address', $csv->{'Business Address'})
                if ( $csv->{'Business Address'} );
            $vcard->appendTextChild('Co_Street_Address', $csv->{'Work Address'})
                if ( $csv->{'Work Address'} );
            $vcard->appendTextChild('Co_City', $csv->{'Business City'})
                if ( $csv->{'Business City'} );
            $vcard->appendTextChild('Co_City', $csv->{'Work City'})
                if ( $csv->{'Work City'} );
            $vcard->appendTextChild('Co_State', $csv->{'Business State'})
                if ( $csv->{'Business State'} );
            $vcard->appendTextChild('Co_State', $csv->{'Work State'})
                if ( $csv->{'Work State'} );
            if ( $csv->{'Business Country'} ) {
                $vcard->appendTextChild('Co_Country', $csv->{'Business Country'});
            }
            elsif ( $csv->{'Business Country/Region'} ) {
                $vcard->appendTextChild('Co_Country', $csv->{'Business Country/Region'});
            }
            elsif ( $csv->{'Work Country'} ) {
                $vcard->appendTextChild('Co_Country', $csv->{'Work Country'});
            }
            $vcard->appendTextChild('Co_Postal_Code', $csv->{'Business Postal Code'})
                if ( $csv->{'Business Postal Code'} );
            $vcard->appendTextChild('Co_Postal_Code', $csv->{'Business Zip'})
                if ( $csv->{'Business Zip'} );
            $vcard->appendTextChild('Co_Postal_Code', $csv->{'Work Zip'})
                if ( $csv->{'Work Zip'} );

            ## birthday
            $vcard->appendTextChild('Birthday', $csv->{'Birthday'})
                if ( $csv->{'Birthday'} );
            $vcard->appendTextChild('Birthday', $csv->{'Date of Birth'})
                if ( $csv->{'Date of Birth'} );

            ## website
            $vcard->appendTextChild('Website', $csv->{'Web Page'})
                if ( $csv->{'Web Page'} );
            $vcard->appendTextChild('Website', $csv->{'URL'})
                if ( $csv->{'URL'} );

            ## other
            $vcard->appendTextChild('Other', $csv->{'Categories'})
                if ( $csv->{'Categories'} );
            $vcard->appendTextChild('Other', $csv->{'Other'})
                if ( $csv->{'Other'} );

            ## comments
            $vcard->appendTextChild('Comments', $csv->{'Notes'})
                if ( $csv->{'Notes'} );
            $vcard->appendTextChild('Comments', $csv->{'Info'})
                if ( $csv->{'Info'} );

            ## append to address book set only if vcard has content
            if ( $vcard->hasChildNodes() ) {
                $vcard_set->appendChild($vcard);
                $imported++;
            }

            # reset some key variables
            @vals = ();
            undef($csv);
        }

    }
    ## vcf file type
    elsif ( $file_type eq 'vcf' ) {

        ## open vcf infile
        my $vcf_infile;
        eval {
            $vcf_infile = Text::vCard::Addressbook->new({ 'source_file' => $full_path, });
        };
        if ( $@ ) {
            unlink($full_path);
            $@ =~ s/\n//;
            $vsap->error($_ERR{WM_XML_ERROR} => "Error parsing $full_path: $@");
            return;
        }

        ## process each vcf infile record
        foreach my $vcf ( $vcf_infile->vcards() ) {
            $processed++;

            ## add new node, creating the uuid. 
            my $ug = new Data::UUID;
            my $vcard = $ab_dom->createElement('vCard');
            $vcard->setAttribute( version => '3.0' );
            $vcard->setAttribute( uid => $ug->create_str() );

            ## name
            my $name = $vcf->get({ 'node_type' => 'N' });
            if ( $name && $name->[0]->given ) {
                $vcard->appendTextChild('First_Name', Encode::encode_utf8($name->[0]->given));
            }
            elsif ( (split / /, $vcf->FN)[0] ) {
                $vcard->appendTextChild('First_Name', Encode::encode_utf8((split / /, $vcf->FN)[0]));
            }
            if ( $name && $name->[0]->family ) {
                $vcard->appendTextChild('Last_Name', Encode::encode_utf8($name->[0]->family));
            }
            elsif ( (split / /, $vcf->FN)[1] ) {
                $vcard->appendTextChild('Last_Name', Encode::encode_utf8((split / /, $vcf->FN)[1]));
            }

            ## nickname
            my $nickname = $vcf->NICKNAME;
            $vcard->appendTextChild('Nickname', Encode::encode_utf8($nickname))
                if ( $nickname );

            ## email
            my $email = $vcf->EMAIL;
            $vcard->appendTextChild('Email_Address', Encode::encode_utf8($email))
                if ( $email );

            ## phone
            my $home = $vcf->get({ 'node_type' => 'TEL', 'types' => ['home', 'voice'], });
            $vcard->appendTextChild('Phone_Personal', Encode::encode_utf8($home->[0]->value))
                if ( $home && $home->[0]->value );
            my $work = $vcf->get({ 'node_type' => 'TEL', 'types' => ['work', 'voice'], });
            $vcard->appendTextChild('Phone_Business', Encode::encode_utf8($work->[0]->value))
                if ( $work && $work->[0]->value );
            my $cell = $vcf->get({ 'node_type' => 'TEL', 'types' => ['cell', 'voice'], });
            $vcard->appendTextChild('Phone_Mobile', Encode::encode_utf8($cell->[0]->value))
                if ( $cell && $cell->[0]->value );
            my $pager = $vcf->get({ 'node_type' => 'TEL', 'types' => ['pager'], });
            $vcard->appendTextChild('Phone_Pager', Encode::encode_utf8($pager->[0]->value))
                if ( $pager && $pager->[0]->value );
            my $fax = $vcf->get({ 'node_type' => 'TEL', 'types' => ['fax'], });
            $vcard->appendTextChild('Phone_Other', Encode::encode_utf8($fax->[0]->value))
                if ( $fax && $fax->[0]->value );

            ## address, home
            my $adr_home = $vcf->get({ 'node_type' => 'ADR', 'types' => ['home'],  });
            if ( $adr_home ) {
                $vcard->appendTextChild('Home_Street_Address', Encode::encode_utf8($adr_home->[0]->street))
                    if ( $adr_home->[0]->street );
                $vcard->appendTextChild('Home_City', Encode::encode_utf8($adr_home->[0]->city))
                    if ( $adr_home &&  $adr_home->[0]->city );
                $vcard->appendTextChild('Home_State', Encode::encode_utf8($adr_home->[0]->region))
                    if ( $adr_home->[0]->region );
                $vcard->appendTextChild('Home_Country', Encode::encode_utf8($adr_home->[0]->county))
                    if ( $adr_home->[0]->county );
                $vcard->appendTextChild('Home_Postal_Code', Encode::encode_utf8($adr_home->[0]->post_code))
                    if ( $adr_home->[0]->post_code );
            }

            ## company name
            my $org = $vcf->get({ 'node_type' => 'ORG' });
            $vcard->appendTextChild('Company_Name', Encode::encode_utf8($org->[0]->name))
                if ( $org && $org->[0]->name );

            ## address, work
            my $adr_work = $vcf->get({ 'node_type' => 'ADR', 'types' => ['work'], });
            if ( $adr_work ) {
                $vcard->appendTextChild('Co_Street_Address', Encode::encode_utf8($adr_work->[0]->street))
                    if ( $adr_work->[0]->street );
                $vcard->appendTextChild('Co_City', Encode::encode_utf8($adr_work->[0]->city))
                    if ( $adr_work->[0]->city );
                $vcard->appendTextChild('Co_State', Encode::encode_utf8($adr_work->[0]->region))
                    if ( $adr_work->[0]->region );
                $vcard->appendTextChild('Co_Country', Encode::encode_utf8($adr_work->[0]->country))
                    if ( $adr_work->[0]->country );
                $vcard->appendTextChild('Co_Postal_Code', Encode::encode_utf8($adr_work->[0]->post_code))
                    if ( $adr_work->[0]->post_code );
            }

            ## birthday
            my $bday = $vcf->BDAY;
            $vcard->appendTextChild('Birthday', Encode::encode_utf8($bday))
                if ( $bday );

            ## website
            my $url = $vcf->URL;
            $vcard->appendTextChild('Website', Encode::encode_utf8($url))
                if ( $url );

            ## comments
            my $x_other = $vcf->get({ 'node_type' => 'X-OTHER' });
            if ( $x_other ) {
                my $other = $x_other->[0]->value();
                $vcard->appendTextChild('Other', Encode::encode_utf8($other))
                    if ( $other );
            }

            ## comments
            my $note = $vcf->NOTE;
            $vcard->appendTextChild('Comments', Encode::encode_utf8($note))
                if ( $note );

            ## append to address book set only if vcard has content
            if ( $vcard->hasChildNodes() ) {
                $vcard_set->appendChild($vcard);
                $imported++;
            }
        }

    }
    ## invalid file type
    else {
        unlink($full_path);
        $vsap->error($_ERR{WM_FTYPE_INVALID} => "Invalid file type: [$file_type]");
        return;
    }

    ## remove infile
    unlink($full_path);

    ## check if limit has been reached
    if ( ($count + $imported) > $ADDRLIMIT ) {
        $vsap->error($_ERR{WM_LIMIT_REACHED} => "addressbook limit of $ADDRLIMIT reached");
        return;
    }

    ## append this address book set to this document
    $ab_dom->setDocumentElement($vcard_set);

    ## write out dom to file
  REWT: {
        local $> = $) = 0;    ## regain root:wheel privileges for a moment

        my $tmpfile = VSAP::Server::Modules::vsap::webmail::addressbook::_tmpfilename($addrbook);
        if (open my $addrbookfh, ">", $tmpfile) {
            binmode $addrbookfh;
            $ab_dom->toFH($addrbookfh, 1);
            close($addrbookfh);
            my ($addrbooksize) = (stat("$tmpfile"))[7] if (-e "$tmpfile");
            if ( (-e "$tmpfile") && ($addrbooksize > 0) ) {
                if ( VSAP::Server::Modules::vsap::webmail::addressbook::_diskspace_availability($vsap->{uid}, $vsap->{gid}, $addrbooksize) ) {
                    chmod 0644, $tmpfile;
                    chown $vsap->{uid}, (getpwuid($vsap->{uid}))[3], $tmpfile;
                    rename $tmpfile, $addrbook;
                }
                else {
                    unlink($tmpfile);
                    $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: quota exceeded");
                    return;
                }
            }
            else {
                unlink($tmpfile) if (-e "$tmpfile");
                $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error writing to address book $addrbook: cause unknown (disk space exceeded?)");
                return;
            }
        }
        else {
            ## do something with the error ($!) here... 
            $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error opening address book $tmpfile: $!");
            return;
        }
    }

    $root->appendTextChild('processed', $processed);
    $root->appendTextChild('imported', $imported);
    $dom->documentElement->appendChild($root);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::addressbook::export;

use Carp qw(carp);

our $EXPORT = 'addressbook_export.';

our %FILE_TYPE = ( 
    csv => 1,
    vcf => 1
); 

sub _bubble_wrap {
    my $value = shift;
    $value = "\"$value\"" if ($value =~ /,/);
    return($value);
}

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $file_type = ( $xmlobj->child('file_type')
                      && $xmlobj->child('file_type')->value
                      ? $xmlobj->child('file_type')->value
                      : '' );

    my $processed = 0;
    my $exported = 0;
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:addressbook:export' );

    ## check for file type
    unless( $file_type ) {
        $vsap->error($_ERR{WM_FTYPE_REQUIRED} => "Empty or missing file type");
        return;
    }

    ## validate file type
    unless( $FILE_TYPE{$file_type} ) {
        $vsap->error($_ERR{WM_FTYPE_INVALID} => "Invalid file type: $file_type");
        return;
    }

    ## load address book
    my $addressbook = VSAP::Server::Modules::vsap::webmail::addressbook::_load_addrbook($vsap, $xmlobj, $dom);
    if (! defined ($addressbook)) {
        # vsap error set in load_addrbook
        return;
    }

    ## open export file
    my $full_path =  $vsap->{tmpdir} .  "/$EXPORT" . $file_type;
    unless ( open (OUTFILE, ">:utf8", $full_path) ) {
        $vsap->error($_ERR{WM_FILE_WRITE_ERROR} => "Error opening $full_path");
        return;
    }

    ## csv file type
    if ( $file_type eq 'csv' ) {

        ## print csv header
        print OUTFILE "First Name,Last Name,Nickname,E-mail Address,Home Phone,Business Phone,Mobile Phone,Pager,Other Phone,Home Street,Home City,Home State,Home Country,Home Country/Region,Home Postal Code,Company,Business Street,Business City,Business State,Business Country,Business Country/Region,Business Postal Code,Birthday,Web Page,Notes,Other\n";

        ## process each addressbook vcard
        foreach my $vcard ($addressbook->findnodes('vCardSet/vCard')) {
            $processed++;

            ## new csv entry
            my $csv;

            ## name
            $csv .= _bubble_wrap($vcard->findvalue('First_Name'))
                if ( $vcard->findvalue('First_Name') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Last_Name'))
                if ( $vcard->findvalue('Last_Name') );
            $csv .= ",";

            ## nickname
            $csv .= _bubble_wrap($vcard->findvalue('Nickname'))
                if ( $vcard->findvalue('Nickname') );
            $csv .= ",";

            ## email
            $csv .= _bubble_wrap($vcard->findvalue('Email_Address'))
                if ( $vcard->findvalue('Email_Address') );
            $csv .= ",";

            ## phone
            $csv .= _bubble_wrap($vcard->findvalue('Phone_Personal'))
                if ( $vcard->findvalue('Phone_Personal') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Phone_Business'))
                if ( $vcard->findvalue('Phone_Business') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Phone_Mobile'))
                if ( $vcard->findvalue('Phone_Mobile') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Phone_Pager'))
                if ( $vcard->findvalue('Phone_Pager') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Phone_Other'))
                if ( $vcard->findvalue('Phone_Other') );
            $csv .= ",";

            ## address, home
            $csv .= _bubble_wrap($vcard->findvalue('Home_Street_Address'))
                if ( $vcard->findvalue('Home_Street_Address') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Home_City'))
                if ( $vcard->findvalue('Home_City') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Home_State'))
                if ( $vcard->findvalue('Home_State') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Home_Country'))
                if ( $vcard->findvalue('Home_Country') );
            $csv .= ",";
            ## empty space for Home Country/Region 
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Home_Postal_Code'))
                if ( $vcard->findvalue('Home_Postal_Code') );
            $csv .= ",";

            ## company name
            $csv .= _bubble_wrap($vcard->findvalue('Company_Name'))
                if ( $vcard->findvalue('Company_Name') );
            $csv .= ",";

            ## address, work
            $csv .= _bubble_wrap($vcard->findvalue('Co_Street_Address'))
                if ( $vcard->findvalue('Co_Street_Address') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Co_City'))
                if ( $vcard->findvalue('Co_City') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Co_State'))
                if ( $vcard->findvalue('Co_State') );
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Co_Country'))
                if ( $vcard->findvalue('Co_Country') );
            $csv .= ",";
            ## empty space for Business Country/Region 
            $csv .= ",";
            $csv .= _bubble_wrap($vcard->findvalue('Co_Postal_Code'))
                if ( $vcard->findvalue('Co_Postal_Code') );
            $csv .= ",";

            ## birthday
            $csv .= _bubble_wrap($vcard->findvalue('Birthday'))
                if ( $vcard->findvalue('Birthday') );
            $csv .= ",";

            ## website
            $csv .= _bubble_wrap($vcard->findvalue('Website'))
                if ( $vcard->findvalue('Website') );
            $csv .= ",";

            ## comments
            $csv .= _bubble_wrap($vcard->findvalue('Comments'))
                if ( $vcard->findvalue('Comments') );
            $csv .= ",";

            ## other
            $csv .= _bubble_wrap($vcard->findvalue('Other'))
                if ( $vcard->findvalue('Other') );

            ## export only if csv entry has content
            if ( (length $csv) > 24 ) {
                print OUTFILE $csv;
                print OUTFILE "\n";
                $exported++;
            }
        }

    }
    ## vcf file type
    elsif ( $file_type eq 'vcf' ) {

        ## process each addressbook vcard
        foreach my $vcard ($addressbook->findnodes('vCardSet/vCard')) {
            $processed++;

            ## new vcf entry
            my $vcf;

            ## name & fullname
            if ( $vcard->findvalue('First_Name') || $vcard->findvalue('Last_Name') ) {
                $vcf .= "N:";
                $vcf .= $vcard->findvalue('Last_Name') if ( $vcard->findvalue('Last_Name') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('First_Name') if ( $vcard->findvalue('First_Name') );
                $vcf .= ";;;\n";

                $vcf .= "FN:";
                if ( $vcard->findvalue('First_Name') ) {
                    $vcf .= $vcard->findvalue('First_Name');
                    if ( $vcard->findvalue('Last_Name') ) {
                        $vcf .= " ";
                    }
                    else {
                        $vcf .= "\n";
                    }
                }
                $vcf .= $vcard->findvalue('Last_Name') . "\n" if ( $vcard->findvalue('First_Name') );
            }
            else {
                $vcf .= "N:;;;;\n";
            }

            ## nickname
            $vcf .= "NICKNAME:" . $vcard->findvalue('Nickname') . "\n"
                if ( $vcard->findvalue('Nickname') );

            ## email
            $vcf .= "EMAIL;TYPE=internet:" . $vcard->findvalue('Email_Address') . "\n"
                if ( $vcard->findvalue('Email_Address') );

            ## phone
            $vcf .= "TEL;TYPE=home,voice:" . $vcard->findvalue('Phone_Personal') . "\n"
                if ( $vcard->findvalue('Phone_Personal') );
            $vcf .= "TEL;TYPE=work,voice:" . $vcard->findvalue('Phone_Business') . "\n"
                if ( $vcard->findvalue('Phone_Business') );
            $vcf .= "TEL;TYPE=cell,voice:" . $vcard->findvalue('Phone_Mobile') . "\n"
                if ( $vcard->findvalue('Phone_Mobile') );
            $vcf .= "TEL;TYPE=pager:" . $vcard->findvalue('Phone_Pager') . "\n"
                if ( $vcard->findvalue('Phone_Pager') );
            $vcf .= "TEL;TYPE=fax:" . $vcard->findvalue('Phone_Other') . "\n"
                if ( $vcard->findvalue('Phone_Other') );

            ## address, home
            if ( $vcard->findvalue('Home_Street_Address')
                 || $vcard->findvalue('Home_City')
                 || $vcard->findvalue('Home_State')
                 || $vcard->findvalue('Home_Postal_Code')
                 || $vcard->findvalue('Home_Country') ) {
                $vcf .= "ADR;TYPE=home:;;";
                $vcf .= $vcard->findvalue('Home_Street_Address')
                    if ( $vcard->findvalue('Home_Street_Address') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Home_City')
                    if ( $vcard->findvalue('Home_City') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Home_State')
                    if ( $vcard->findvalue('Home_State') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Home_Postal_Code')
                    if ( $vcard->findvalue('Home_Postal_Code') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Home_Country')
                    if ( $vcard->findvalue('Home_Country') );
                $vcf .= "\n";
            }

            ## company name
            $vcf .= "ORG:" . $vcard->findvalue('Company_Name') . ";;\n"
                if ( $vcard->findvalue('Company_Name') );

            ## address, work
            if ( $vcard->findvalue('Co_Street_Address')
                 || $vcard->findvalue('Co_City')
                 || $vcard->findvalue('Co_State')
                 || $vcard->findvalue('Co_Postal_Code')
                 || $vcard->findvalue('Co_Country') ) {
                $vcf .= "ADR;TYPE=work:;;";
                $vcf .= $vcard->findvalue('Co_Street_Address')
                    if ( $vcard->findvalue('Co_Street_Address') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Co_City')
                    if ( $vcard->findvalue('Co_City') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Co_State')
                    if ( $vcard->findvalue('Co_State') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Co_Postal_Code')
                    if ( $vcard->findvalue('Co_Postal_Code') );
                $vcf .= ";";
                $vcf .= $vcard->findvalue('Co_Country')
                    if ( $vcard->findvalue('Co_Country') );
                $vcf .= "\n";
            }

            ## birthday
            $vcf .= "BDAY:" . $vcard->findvalue('Birthday') . "\n"
                if ( $vcard->findvalue('Birthday') );

            ## website
            $vcf .= "URL:" . $vcard->findvalue('Website') . "\n"
                if ( $vcard->findvalue('Website') );

            ## comments
            $vcf .= "NOTE:" . $vcard->findvalue('Comments') . "\n"
                if ( $vcard->findvalue('Comments') );

            $vcf .= "X-OTHER:" . $vcard->findvalue('Other') . "\n"
                if ( $vcard->findvalue('Other') );

            ## export only if vcf entry has content
            if ( $vcf ) {
                print OUTFILE "BEGIN:VCARD\n";
                print OUTFILE "VERSION:3.0\n";
                print OUTFILE $vcf;
                print OUTFILE "END:VCARD\n\n";
                $exported++;
            }
        }

    }
    ## invalid file type
    else {
        unlink($full_path);
        $vsap->error($_ERR{WM_FTYPE_INVALID} => "Invalid file type: [$file_type]");
        return;
    }

    close OUTFILE;

    $root->appendTextChild('path', $full_path);
    $root->appendTextChild('processed', $processed);
    $root->appendTextChild('exported', $exported);
    $dom->documentElement->appendChild($root);
    return;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::addressbook - VSAP webmail address book

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::addressbook;
  blah blah blah

=head1 DESCRIPTION

The following fields are used in the addressbook:

Last_Name, First_Name, Nickname, Email_Address, Phone_Personal,
Phone_Business Phone_Mobile, Phone_Pager, Phone_Other,
Home_Street_Address, Home_City, Home_State Home_Country,
Home_Postal_Code, Company_Name, Co_Street_Address, Co_City, Co_State
Co_Country, Co_Postal_Code, Birthday, Website, Other, Comments

Any of the following packages may be used to access addressbook entries:

=head2 webmail:addressbook:load

Returns one or all addresses in the address book.

Example:

  <vsap type="webmail:addressbook:load"/>

Returns:

  <vsap type="webmail:addressbook:load">
    <vCardSet name="Address Book">
      <vCard version="3.0" uid="58f202ac-22cf-11d1-b12d-002035b29092">
        <Last_Name>Wiersdorf</Last_Name>
        <First_Name>Scott</First_Name>
        <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
        <Email_Address>scott@somewhere.tld</Email_Address>
        <Phone_Business>801-111-2222</Phone_Business>
      </vCard>
      ...
    </vCardSet>
  </vsap>

Example:

  <vsap type="webmail:addressbook:load">
    <uid>58f202ac-22cf-11d1-b12d-002035b29092</uid>
  </vsap>

Returns:

  <vsap type="webmail:addressbook:load">
    <vCard version="3.0" uid="58f202ac-22cf-11d1-b12d-002035b29092">
      <Last_Name>Wiersdorf</Last_Name>
      <First_Name>Scott</First_Name>
      <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
      <Email_Address>scott@somewhere.tld</Email_Address>
      <Phone_Business>801-111-2222</Phone_Business>
    </vCard>
  </vsap>

=head2 webmail:addressbook:add

Adds one address to the addressbook. If a vCard entry already exists
in the addressbook with the same email address, the add will fail
(unless an E<lt>edit/E<gt> node is passed in as well).

Example:

  <vsap type="webmail:addressbook:add">
    <Last_Name>Wiersdorf</Last_Name>
    <First_Name>Scott</First_Name>
    <Nickname>That one guy who likes root beer and Tabasco sauce</Nickname>
    <Email_Address>scott@somewhere.tld</Email_Address>
    <Phone_Business>801-111-2222</Phone_Business>
  </vsap>

To edit an addressbook entry, add an E<lt>edit/E<gt> node:

  <vsap type="webmail:addressbook:add">
    <edit/>
    <uid>58f202ac-22cf-11d1-b12d-002035b29092</uid>
    <Last_Name>Wiersdorf</Last_Name>
    <First_Name>Scott</First_Name>
    <Nickname>tabasco</Nickname>
    <Email_Address>scott@somewhere.tld</Email_Address>
    <Phone_Business>801-111-2222</Phone_Business>
  </vsap>

The vCardSet node containg all vCards is returned on a successful add:

  <vsap type="webmail:addressbook:add">
    <vCardSet name="Address Book">
      <vCard version="3.0" uid="58f202ac-22cf-11d1-b12d-002035b29092">
        <Last_Name>Wiersdorf</Last_Name>
        <First_Name>Scott</First_Name>
        <Nickname>tabasco</Nickname>
        <Email_Address>scott@somewhere.tld</Email_Address>
        <Phone_Business>801-111-2222</Phone_Business>
      </vCard>
      ... 
    </vCardSet>
  </vsap>

=head2 webmail:addressbook:delete

Deletes one or more addresses from the address book

Example:

  <vsap type="webmail:addressbook:delete">
    <uid>58f202ac-22cf-11d1-b12d-765431b29092</uid>
    <uid>2395abef-22cf-11d1-b12d-123456b29092</uid>
    <uid>7ace7342-22cf-11d1-b12d-193478563293</uid>
  </vsap>

Returns:

  <vsap type="webmail:addressbook:delete">
    <uid>58f202ac-22cf-11d1-b12d-765431b29092</uid>
    <uid>2395abef-22cf-11d1-b12d-123456b29092</uid>
    <uid>7ace7342-22cf-11d1-b12d-193478563293</uid>
  </vsap>

=head2 webmail:addressbook:list

Returns address list compiled from the address book and distribution
lists. Will processes the sorting, filtering and paging of results.

Input:

Standard:

  <vsap type="webmail:addressbook:list"/>

Optional:

  <vsap type="webmail:addressbook:list">
    <page>2</page>
    <sort_by>firstname</sort_by>
    <sort_type>ascending</sort_type>
    <search_value>joe</search_value>
  </vsap>

Values (default):

  <sort_by>(firstname|lastname|nickname|email)</sort_by>
  <sort_type>(ascending|descending)</sort_type>

Example:

  <vsap type="webmail:addressbook:list"/>

Returns:

  <vsap type="webmail:addressbook:list">
    <num_addresses>5</num_addresses>
    <page>1</page>
    <total_pages>1</total_pages>
    <prev_page/>
    <next_page/>
    <first_address>1</first_address>
    <last_address>5</last_address>
    <sort_by>firstname</sort_by>
    <sort_type>ascending</sort_type>
    <search_value/>
    <address>
      <type>group</type>
      <listid>110969299693884</listid>
      <lastname>Crew</lastname>
      <firstname>Crew</firstname>
      <nickname>My Team</nickname>
      <email>scott@somewhere.tld</email>
      <email>kwhyte@somewhere.tld</email>
      <email>vonheinz@yahoo.com</email>
    </address>
    <address>
      <type>individual</type>
      <listid/>
      <lastname>Whyte</lastname>
      <firstname>Kevin</firstname>
      <nickname>insert cool nickname here</nickname>
      <email>kwhyte@somewhere.tld</email>
    </address>
    <address>
      <type>individual</type>
      <listid/>
      <lastname>Wiersdorf</lastname>
      <firstname>Scott</firstname>
      <nickname>tabasco cool nickname here</nickname>
      <email>scott@somewhere.tld</email>
    </address>
    ...
  </vsap>

Example:

  <vsap type="webmail:addressbook:list">
    <page>1</page>
    <sort_by>lastname</sort_by>
    <sort_type>descending</sort_type>
    <search_value>somewhere.tld</search_value>
  </vsap>

Returns:

  <vsap type="webmail:addressbook:list">
    <num_addresses>3</num_addresses>
    <page>1</page>
    <total_pages>1</total_pages>
    <prev_page/>
    <next_page/>
    <first_address>1</first_address>
    <last_address>3</last_address>
    <sort_by>lastname</sort_by>
    <sort_type>descending</sort_type>
    <search_value>somewhere.tld</search_value>
    <address>
      <type>individual</type>
      <listid/>
      <lastname>Wiersdorf</lastname>
      <firstname>Scott</firstname>
      <nickname>tabasco cool nickname here</nickname>
      <email>scott@somewhere.tld</email>
    </address>
    <address>
      <type>individual</type>
      <listid/>
      <lastname>Whyte</lastname>
      <firstname>Kevin</firstname>
      <nickname>insert cool nickname here</nickname>
      <email>kwhyte@somewhere.tld</email>
    </address>
    <address>
      <type>group</type>
      <listid>110969299693884</listid>
      <lastname>Crew</lastname>
      <firstname>Crew</firstname>
      <nickname>My Team</nickname>
      <email>scott@somewhere.tld</email>
      <email>kwhyte@somewhere.tld</email>
      <email>vonheinz@yahoo.com</email>
    </address>
  </vsap>

=head2 webmail:addressbook:import

Imports addressbook entries from upload file.
Supports Outlook/Outlook Express .csv and vCard .vcf file types.

Input:

  <vsap type="webmail:addressbook:import">
    <file_name>C:\tmp\myfile.csv</file_name>
    <file_type>csv</file_type>
  </vsap>

  <vsap type="webmail:addressbook:import">
    <file_name>C:\tmp\myfile.vcf</file_name>
    <file_type>vcf</file_type>
  </vsap>

Example:

  <vsap type="webmail:addressbook:import">
    <file_name>C:\tmp\myfile.csv</file_name>
    <file_type>csv</file_type>
  </vsap>

Returns:

  <vsap type="webmail:addressbook:import">
    <processed>10</processed>
    <imported>10</imported>
  </vsap>

=head2 webmail:addressbook:export

Exports the addressbook to VPSDOWNLOAD file.
Supports Outlook/Outlook Express .csv and vCard .vcf file types.

Input:

  <vsap type="webmail:addressbook:export">
    <file_type>csv</file_type>
  </vsap>

  <vsap type="webmail:addressbook:export">
    <file_type>vcf</file_type>
  </vsap>

Example:

  <vsap type="webmail:addressbook:export">
    <file_type>csv</file_type>
  </vsap>

Returns:

  <vsap type="webmail:addressbook:export">
    <path>/usr/home/kwhyte/users/kwhyte/.opencpx_tmp/addressbook_export.csv</path>
    <processed>10</processed>
    <exported>10</exported>
  </vsap>

=head1 NOTES

This example from L<SEE ALSO/2>:

   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE vCard PUBLIC "-//IETF//DTD vCard v3.0//EN">

   <vCardSet name="Mailing List">
   <vCard version="3.0">
   <fn>John Smith</fn>
   <n>  <family>Smith</family>
        <given>John</given>
   <email email.type="INTERNET">jsmith@host.com</email>
   </vCard>
   <vCard version="3.0">
   <fn>Fred Stone</fn>
   <n>  <family>Stone</family>
        <given>Fred</given>
   <email email.type="INTERNET">fstone@host1.com</email>
   </vCard>
   </vCardSet>

=head1 SEE ALSO

=over 4

=item 1

F<http://www.w3.org/TR/2001/NOTE-vcard-rdf-20010222/>

=item 2

F<http://www.watersprings.org/pub/id/draft-dawson-vcard-xml-dtd-03.txt>

=item 3

F<http://www.ietf.org/rfc/rfc2426.txt>

=back

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
