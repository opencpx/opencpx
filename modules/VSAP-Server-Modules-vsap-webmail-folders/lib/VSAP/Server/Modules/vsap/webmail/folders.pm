package VSAP::Server::Modules::vsap::webmail::folders;

use 5.008001;
use strict;
use warnings;
use VSAP::Server::Modules::vsap::webmail;

our $Debug = 0;
our $VERSION = '0.01';

our %_ERR = ( WM_BAD_CHARACTERS       => 100,
	      WM_CCLIENT              => 101,
	      WM_FOLDER_MISSING       => 102,
	      WM_DELETE_INBOX         => 103,
	      WM_FOLDER_RENAME        => 104,
	      WM_SYSTEM_RENAME        => 105,
	      WM_RENAME               => 106,
	      WM_MOVE_FAILED          => 107,
	      WM_FOLDER_DELETE        => 108,
	      WM_FOLDER_EXISTS        => 109,
	      WM_FOLDER_CREATE        => 110,
	      WM_FOLDER_SUBSCRIBE     => 111,
	      WM_FOLDER_UNSUBSCRIBE   => 112,
	      WM_UNSUBSCRIBE_INBOX    => 113,
	      WM_SUBDIR_MISSING       => 114,
	      WM_SUBDIR_EXISTS        => 115,
	      WM_FOLDER_MKDIR         => 116,
	      WM_FOLDER_NOT_FOUND     => 117,
	    );

use Encode;

our $VPS;
BEGIN { 
    use POSIX('uname');
    $VPS = ( ( -d '/skel' ) || ( (POSIX::uname())[0] =~ /Linux/ ) );
    require VSAP::Server::Modules::vsap::config
       if ($VPS);
}

## sort order
our %System_Folders = ( 'Sent Items' => 3,
                        INBOX        => 1,
                        Trash        => 4,
                        Drafts       => 2,
                        Quarantine   => 6,
                        Junk         => 5, );

# Don't create Junk folder on signature. BUG07498
delete($System_Folders{'Junk'}) unless ($VPS);

our $System_Folder_RE = '(?:' . join('|', keys %System_Folders) . ')';
$System_Folder_RE = qr(^$System_Folder_RE$)o;


## here, then, is the complete list of illegal characters for IMAP
## (rfc 3501) mailbox names:
##
## "(" / ")" / "{" / SP / CTL / "%" / "*" / DQUOTE / "\" / "]"
sub folder_legal {
    my $folder = shift;

    my $illegal = '/(){%*]';  ## except backslash, DQUOTE, and SP
    if( $folder =~ m![\Q$illegal\E\\]! ) {  ## backslash tested here
        return;
    }

    if( $folder =~ /[[:cntrl:]]/ ) {
        return;
    }

    return 1;
}

sub subdir_legal {
    my $subdir = shift;

    my $illegal = '(){%*]';  ## except backslash, DQUOTE, and SP
    if( $subdir =~ m![\Q$illegal\E\\]! ) {  ## backslash tested here
        return;
    }

    if( $subdir =~ /[[:cntrl:]]/ ) {
        return;
    }

    return 1;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::clear;

use Quota;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    my $folders = $wm->folder_list;

    ## make sure Trash exists
    unless( $folders->{Trash} ) {
	$wm->folder_create('Trash')
	  or do {
	      $vsap->error($_ERR{WM_FOLDER_CREATE} => "Could not create Trash folder: " . $wm->log );
	      return;
	  };
    }

    ## is quota defined for this user?  if so, then remove quota info
    ## temporarily to allow enough space for move to complete (BUG27576)
    my($uquota, $gquota) = (0, 0);
    my($gid) = (getpwuid($vsap->{uid}))[3];
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        ($uquota) = (Quota::query(Quota::getqcarg('/home'), $vsap->{uid}))[1];
        ($gquota) = (Quota::query(Quota::getqcarg('/home'), $gid, 1))[1];
        if ($uquota || $gquota) {
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, $vsap->{uid}, 0, 0, 0, 0, 0, 0);
            Quota::setqlim($dev, $gid, 0, 0, 0, 0, 0, 1);
            Quota::sync($dev);
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:folders:clear' );

    ## put the Trash last, so that clearing multiple folders,
    ## including Trash, will actually move all messages to Trash, then
    ## empty the Trash
    my $error = 0;
    for my $folder ( sort { return -1 if $a eq 'Trash' or $b eq 'Trash'; $a cmp $b }
		     grep { $_ } map { $_->value } $xmlobj->children("folder") ) {

        # convert to modified utf7
        use Encode("encode");
        use Encode::IMAPUTF7;
        my $utf7_folder = encode('IMAP-UTF-7',$folder);

	my $status = $wm->folder_status($utf7_folder);
	if ( $status->{messages} ) {
	    ## delete messages from Trash
	    if ($folder eq 'Trash') {
		$wm->folder_delete($folder)
		  or do {
		      $vsap->error($_ERR{WM_FOLDER_DELETE} => "Could not delete folder: " . $wm->log);
		      $error = 1;
                      next;
		  };
		$wm->folder_create($folder);
	    }

	    ## move messages to Trash
	    else {
		$wm->messages_move_seq(join(',', (1 .. $status->{messages})), $utf7_folder => 'Trash')
		  or do {
		      $vsap->error($_ERR{WM_MOVE_FAILED} => 'Could not move items to Trash: ' . $wm->log);
		      $error = 1;
                      next;
		  };
	    }
	}

	$root_node->appendTextChild('folder' => $folder);
    }

    # restore quota from above if necessary (BUG27576)
    if ($uquota || $gquota) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, $vsap->{uid}, $uquota, $uquota, 0, 0, 0, 0);
            Quota::setqlim($dev, $gid, $gquota, $gquota, 0, 0, 0, 1);
            Quota::sync($dev);
        }
    }

    return if ($error);

    $dom->documentElement->appendChild($root_node);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::create;

use VSAP::Server::Modules::vsap::webmail;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child("folder") && $xmlobj->child("folder")->value
		   ? $xmlobj->child("folder")->value
		   : '' );
    my $maildir; 

    if (!$vsap->{mail_dir}) { 
	my $home = (getpwuid($>))[7];
	my $mail = $VSAP::Server::Modules::vsap::webmail::MDIR || 'Mail';
	$maildir = "${home}/$mail";
    } else { 
	$maildir = $vsap->{mail_dir};
    }

    unless( $folder ) {
	$vsap->error($_ERR{WM_FOLDER_MISSING} => "You must specify a folder name to create");
	return;
    }

    # if folder includes '/' then split
    my $subdir = "";
    my $subfolder = $folder;
    my $ri = rindex($folder, '/');
    if ($ri >= 0) {
        $subdir = substr($folder, 0, $ri);
        $subfolder = substr($folder, $ri+1);
    }

    if ($subdir) {
        unless (VSAP::Server::Modules::vsap::webmail::folders::subdir_legal($subdir)) { 
            $vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in folder name');
            return;
        }
    }

    unless (VSAP::Server::Modules::vsap::webmail::folders::folder_legal($subfolder)) { 
        $vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in folder name');
        return;
    }

    # convert to modified utf7
    use Encode("encode");
    use Encode::IMAPUTF7;
    my $utf7_folder = encode('IMAP-UTF-7',$folder);
    my $utf7_subdir = encode('IMAP-UTF-7',$subdir) if ($subdir);

    if( -e "$maildir/$utf7_folder" ) {
	$vsap->error($_ERR{WM_FOLDER_EXISTS} => "File '$folder' already exists");
	return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    if ($subdir) {
        unless( $wm->directory_create($utf7_subdir) ) {
            $vsap->error( $_ERR{WM_FOLDER_MKDIR} => "C-client could not mkdir '$subdir': " . $wm->log );
            return;
        }
    }

    unless( $wm->folder_create($utf7_folder) ) {
	$vsap->error( $_ERR{WM_FOLDER_CREATE} => "C-client could not create '$folder': " . $wm->log );
	return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'webmail:folders:create');
    $root_node->appendTextChild(folder => $folder);
    $dom->documentElement->appendChild($root_node);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::delete;

BEGIN {
    if( $VPS ) {
        require VSAP::Server::Modules::vsap::mail::spamassassin;
        require VSAP::Server::Modules::vsap::mail::clamav;
    }
}

sub handler {
    my $vsap   = shift;     # the VSAP server object
    my $xmlobj = shift;     # the top-level XML element object
    my $dom    = shift || $vsap->{_result_dom};

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    ## get config object
    my ($co, $packages, $siteprefs);
    if ($VPS) {
        $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
        $packages  = join( ',', keys %{$co->packages} );
        $siteprefs  = join( ',', keys %{$co->siteprefs} );
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:folders:delete' );

    for my $folder ( grep { $_ } map { $_->value } $xmlobj->children("folder") ) {

        # convert to modified utf7
        use Encode("encode");
        use Encode::IMAPUTF7;
        my $utf7_folder = encode('IMAP-UTF-7',$folder);

	## INBOX is special case
	if( $folder eq 'INBOX' ) {
	    $vsap->error($_ERR{WM_DELETE_INBOX} => "Cannot delete INBOX");
	    return;
	}

	$wm->folder_delete($utf7_folder)
	  or do {
	      $vsap->error($_ERR{WM_FOLDER_DELETE} => "Error deleting '$folder': " . $wm->log);
	      return;
	  };

	## re-create system folders; this behaves exactly like "clear"
	if( $folder =~ $System_Folder_RE ) {
            ## BUG22834: re-create Junk/Quarantine folders only if SpamAssassin/ClamAV available (respectively)
            if ($VPS) { 
                if( $folder eq 'Junk' ) {
                    next unless ( $packages =~ /mail-spamassassin/ );
                    next if ( $siteprefs =~ /disable-spamassassin/ );
                }
                if( $folder eq 'Quarantine' ) {
                    next unless ( $packages =~ /mail-clamav/ );
                    next if ( $siteprefs =~ /disable-clamav/ );
                }
            } 
	    $wm->folder_create($folder);
	}
	$root_node->appendTextChild('folder' => $folder);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::list;

use VSAP::Server::Base;

BEGIN {
    if( $VPS ) {
        require VSAP::Server::Modules::vsap::mail::spamassassin;
        require VSAP::Server::Modules::vsap::mail::clamav;
    }
    require VSAP::Server::Modules::vsap::webmail::options;
}

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    ## this object has a lot of overhead for login
    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password}, 'readonly');
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "Could not create c-client object");
	return;
    }

    # load all folders or only subscribed folders?
    my $use_mailboxlist = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "use_mailboxlist");

    ## get folders
    my $folders = ($use_mailboxlist eq 'yes') ? $wm->folder_list_subscribed : $wm->folder_list;

    ## get config object; load packages and siteprefs
    my ($co, $packages, $siteprefs);
    $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
    $packages  = join( ',', keys %{$co->packages} );
    $siteprefs  = join( ',', keys %{$co->siteprefs} );

    ## BUG22834: suppress listing of Junk/Quarantine folders if necessary
    if ($VPS) {
        if ( ($packages !~ /mail-spamassassin/) || ($siteprefs =~ /disable-spamassassin/) ) {
            delete($System_Folders{'Junk'});
        }
        else {
            $System_Folders{'Junk'} = 5;
        }
        if ( ($packages !~ /mail-clamav/) || ($siteprefs =~ /disable-clamav/) ) {
            delete($System_Folders{'Quarantine'});
        }
        else {
            $System_Folders{'Quarantine'} = 6;
        }
    }

    ## create folders if needed. Do this before we filter on the incoming children.
    my $reload = 0;
    my %system_folder_count = ();
    for my $system_folder ( keys %System_Folders ) {
        $system_folder_count{$system_folder} = 1;
        unless( $folders->{$system_folder}) {
            $wm->folder_create($system_folder);
            # make sure system folders are in the subscription list; this 
            # will silently (and harmlessly) fail if already subscribed
            $wm->folder_subscribe($system_folder);
            $reload = 1;
        }
    }

    ## reload (if required)
    if ($reload) {
        $folders = ($use_mailboxlist eq 'no') ? $wm->folder_list : $wm->folder_list_subscribed;
    }

    ## folder names sent to VSAP are in Unicode, but those returned from 
    ## IMAP are modified utf-7; so we convert those in the list first
    use Encode qw/encode decode/;
    use Encode::IMAPUTF7;
    %$folders = map {decode('IMAP-UTF-7',$_) => $folders->{$_}} keys %$folders;

    my %folders = ( $xmlobj->children('folder')
		    ? map { $_ => $folders->{$_} } grep { $folders->{$_} } map { $_->value } $xmlobj->children('folder')
		    : %$folders );

    my $fast   = ( $xmlobj->child('fast') ? 1 : 0 );

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:folders:list' );

  FOLDERS: 
    for my $folder ( keys %folders ) {
        next if ($folder eq ".mailboxlist");
        if ($VPS && ($folder eq "Junk") ) {
            ## do not list Junk folder if applicable (BUG22834)
            next if ( ($packages !~ /mail-spamassassin/) || ($siteprefs =~ /disable-spamassassin/) );
        }
        if ($VPS && ($folder eq "Quarantine") ) {
            ## do not list Quarantine folder if applicable (BUG22834)
            next if ( ($packages !~ /mail-clamav/) || ($siteprefs =~ /disable-clamav/) );
        }
        # convert to modified utf7
        my $utf7_folder = encode('IMAP-UTF-7',$folder);
        my $url_folder = $folder;  # url_encode is broken when handling multi-byte chars.
        $url_folder =~ s/&/%26/g; 

	my $f_node = $dom->createElement('folder');
        $f_node->appendTextChild( name     => $folder );
	$f_node->appendTextChild( url_name => $url_folder ); 

      FAST: {
            last FAST if $fast;

            ## this is a slow operation
            my $status = $wm->folder_status($utf7_folder) || next FOLDERS;

            $f_node->appendTextChild( num_messages    => $status->{messages} );
            $f_node->appendTextChild( recent_messages => $status->{recent} );
            $f_node->appendTextChild( unseen_messages => (($utf7_folder eq 'Sent Items' or
                                                           $utf7_folder eq 'Drafts')
                                                          ? 0
                                                          : $status->{unseen}) );
            $f_node->appendTextChild( size            => ($status->{messages} ? $status->{size} : 0) );
        }

	## mark true system folders (Junk and Quarantine are sometimes
	## not system folders if the corresponding feature is disabled)
	if( $system_folder_count{$folder} ) {
	    $f_node->setAttribute( flag => 'immutable' );
	}

	$f_node->setAttribute( type  => ($System_Folders{$folder}
					 ? 'system'
					 : 'user') );
	$f_node->setAttribute( order => ($System_Folders{$folder} 
					 ? $System_Folders{$folder}
					 : 2147483648) );

	$root_node->appendChild($f_node);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::mkdir;

use VSAP::Server::Modules::vsap::webmail;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $subdir = ( $xmlobj->child("subdirectory") && $xmlobj->child("subdirectory")->value
		   ? $xmlobj->child("subdirectory")->value
		   : '' );
    my $maildir; 

    if (!$vsap->{mail_dir}) { 
	my $home = (getpwuid($>))[7];
	my $mail = $VSAP::Server::Modules::vsap::webmail::MDIR || 'Mail';
	$maildir = "${home}/$mail";
    } else { 
	$maildir = $vsap->{mail_dir};
    }

    unless( $subdir ) {
	$vsap->error($_ERR{WM_SUBDIR_MISSING} => "You must specify a subdirectory name");
	return;
    }

    unless (VSAP::Server::Modules::vsap::webmail::folders::subdir_legal($subdir)) { 
	$vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in subdirectory name');
	return;
    }

    # convert to modified utf7
    use Encode qw/encode decode/;
    use Encode::IMAPUTF7;
    my $utf7_subdir = encode('IMAP-UTF-7',$subdir);

    if( -e "$maildir/$utf7_subdir" ) {
	$vsap->error($_ERR{WM_SUBDIR_EXISTS} => "File '$subdir' already exists");
	return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    unless( $wm->directory_create($utf7_subdir) ) {
	$vsap->error( $_ERR{WM_FOLDER_MKDIR} => "C-client could not mkdir '$subdir': " . $wm->log );
	return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'webmail:folders:mkdir');
    $root_node->appendTextChild(subdirectory => $subdir);
    $dom->documentElement->appendChild($root_node);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::rename;

BEGIN {
    if( $VPS ) {
        require VSAP::Server::Modules::vsap::mail::spamassassin;
        require VSAP::Server::Modules::vsap::mail::clamav;
    }
}

sub handler {
    my $vsap   = shift;     # the VSAP server object
    my $xmlobj = shift;     # the top-level XML element object
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
		   ? $xmlobj->child('folder')->value
		   : '' );

    my $new_folder = ( $xmlobj->child("new_folder") && $xmlobj->child("new_folder")->value
		       ? $xmlobj->child("new_folder")->value
		       : '' );

    my $maildir; 

    if (!$vsap->{mail_dir}) { 
	my $home = (getpwuid($>))[7];
	my $mail = $VSAP::Server::Modules::vsap::webmail::MDIR || 'Mail';
	$maildir = "${home}/$mail";
    } else { 
	$maildir = $vsap->{mail_dir};
    }

    # convert to modified utf7
    use Encode qw/encode decode/;
    use Encode::IMAPUTF7;
    my $utf7_folder = encode('IMAP-UTF-7',$folder);
    my $utf7_new_folder = encode('IMAP-UTF-7',$new_folder);

    unless( $folder && $new_folder ) {
	$vsap->error($_ERR{WM_FOLDER_RENAME} => "Old and new folder names required for rename");
	return;
    }

    unless (VSAP::Server::Modules::vsap::webmail::folders::folder_legal($new_folder)) { 
	$vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in folder name');
	return;
    }

    ## get config object
    my ($co, $packages, $siteprefs);
    if ($VPS) {
        $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
        $packages  = join( ',', keys %{$co->packages} );
        $siteprefs  = join( ',', keys %{$co->siteprefs} );
    }


  CHECK_SYSTEM: {
	if( $folder =~ $System_Folder_RE or $new_folder =~ $System_Folder_RE ) {
            ## BUG22834: rename Junk/Quarantine folders only allowed if SpamAssassin/ClamAV not installed (respectively)
            if ($VPS) { 
                if( $folder eq 'Junk' or $new_folder eq 'Junk' ) {
                    last CHECK_SYSTEM unless ( $packages =~ /mail-spamassassin/ );
                    last CHECK_SYSTEM if ( $siteprefs =~ /disable-spamassassin/ );
                }
                if( $folder eq 'Quarantine' or $new_folder eq 'Quarantine' ) {
                    last CHECK_SYSTEM unless ( $packages =~ /mail-clamav/ );
                    last CHECK_SYSTEM if ( $siteprefs =~ /disable-clamav/ );
                }
            }
	    $vsap->error( $_ERR{WM_SYSTEM_RENAME} => "System folders may not be the old or new folder to rename");
	    return;
	}
    }

    if( -e "$maildir/$utf7_new_folder" ) {
	$vsap->error($_ERR{WM_FOLDER_EXISTS} => "File '$new_folder' already exists");
	return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
        return;
    }

    $wm->folder_rename($utf7_folder => $utf7_new_folder)
      or do {
	  $vsap->error($_ERR{WM_RENAME} => "Error renaming folder: " . $wm->log);
	  return;
      };

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'webmail:folders:rename');
    $root_node->appendTextChild(folder => $folder);
    $root_node->appendTextChild(new_folder => $new_folder);
    $dom->documentElement->appendChild($root_node);
    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::subscribe;

use VSAP::Server::Modules::vsap::webmail;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child("folder") && $xmlobj->child("folder")->value
		   ? $xmlobj->child("folder")->value
		   : '' );
    my $maildir; 
    my $dovecot_maildir;

    if (!$vsap->{mail_dir}) { 
	my $home = (getpwuid($>))[7];
	my $mail = $VSAP::Server::Modules::vsap::webmail::MDIR || 'Mail';
	$maildir = "${home}/$mail";
        $dovecot_maildir = "$home/Maildir/";
    } else { 
	$maildir = $vsap->{mail_dir};
    }

    unless( $folder ) {
	$vsap->error($_ERR{WM_FOLDER_MISSING} => "You must specify a folder name to subscribe");
	return;
    }

    # if folder includes '/' then split
    my $subdir = "";
    my $subfolder = $folder;
    my $ri = rindex($folder, '/');
    if ($ri >= 0) {
        $subdir = substr($folder, 0, $ri);
        $subfolder = substr($folder, $ri+1);
    }

    if ($subdir) {
        unless (VSAP::Server::Modules::vsap::webmail::folders::subdir_legal($subdir)) { 
            $vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in folder name');
            return;
        }
    }

    unless (VSAP::Server::Modules::vsap::webmail::folders::folder_legal($subfolder)) { 
        $vsap->error( $_ERR{WM_BAD_CHARACTERS} => 'Illegal character in folder name');
        return;
    }

    # convert to modified utf7
    use Encode qw/encode decode/;
    use Encode::IMAPUTF7;
    my $utf7_folder = encode('IMAP-UTF-7',$folder);
    $dovecot_maildir .= '.' . $utf7_folder;

    unless( -e "$maildir/$utf7_folder" || -e "$dovecot_maildir" ) {
	$vsap->error($_ERR{WM_FOLDER_NOT_FOUND} => "File '$folder' not found");
	return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    unless( $wm->folder_subscribe($utf7_folder) ) {
	$vsap->error( $_ERR{WM_FOLDER_SUBSCRIBE} => "C-client could not subscribe to '$folder': " . $wm->log );
	return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'webmail:folders:subscribe');
    $root_node->appendTextChild(folder => $folder);
    $dom->documentElement->appendChild($root_node);

    return;
}

########################################################################

package VSAP::Server::Modules::vsap::webmail::folders::unsubscribe;

sub handler {
    my $vsap   = shift;     # the VSAP server object
    my $xmlobj = shift;     # the top-level XML element object
    my $dom    = shift || $vsap->{_result_dom};

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
	$vsap->error($_ERR{WM_CCLIENT} => "C-client error: $@");
	return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:folders:unsubscribe' );

    for my $folder ( grep { $_ } map { $_->value } $xmlobj->children("folder") ) {

        # convert to modified utf7
        use Encode qw/encode decode/;
        use Encode::IMAPUTF7;
        my $utf7_folder = encode('IMAP-UTF-7',$folder);

	## INBOX is special case
	if( $folder eq 'INBOX' ) {
	    $vsap->error($_ERR{WM_UNSUBSCRIBE_INBOX} => "Cannot unsubscribe from INBOX");
	    return;
	}

	$wm->folder_unsubscribe($utf7_folder)
	  or do {
	      $vsap->error($_ERR{WM_FOLDER_UNSUBSCRIBE} => "Error unsubsribing from '$folder': " . $wm->log);
	      return;
	  };

	$root_node->appendTextChild('folder' => $folder);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

########################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::folders - CPX webmail folder manipulation

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::folders;
  blah blah blah

=head1 DESCRIPTION

=head2 VSAP::Server::Modules::vsap::webmail::folders::clear;

Example:

  <vsap type="webmail:folders:clear"><folder>INBOX</folder></vsap>

Returns:

  <vsap type="webmail:folders:clear">
    <folder>INBOX</folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::create;

Example:

  <vsap type="webmail:folders:create"><folder>Barkis</folder></vsap>

Returns:

  <vsap type="webmail:folders:create">
    <folder>Barkis</folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::delete;

Example:

  <vsap type="webmail:folders:delete"><folder>Em'lee</folder></vsap>

Returns:

  <vsap type="webmail:folders:delete">
    <folder>Em'lee</folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::list;

Examples:

  <vsap type="webmail:folders:list><folder>INBOX</folder></vsap>

  <vsap type="webmail:folders:list"/>

Returns:

  <vsap type="webmail:folders:list">
    <folder>
      <name>INBOX</name>
      <url_name>INBOX</url_name>
      <size>0</size>
      <num_messages>0</num_messages>
      <recent_messages>0</recent_messages>
      <unseen_messages>0</unseen_messages>
    </folder>
    <folder>
      <name>Trash</name>
      <url_name>Trash</url_name>
      <size>512</size>
      <num_messages>0</num_messages>
      <recent_messages>0</recent_messages>
      <unseen_messages>0</unseen_messages>
    </folder>
    <folder>
      <name>Drafts</name>
      <url_name>Drafts</url_name>
      <size>512</size>
      <num_messages>0</num_messages>
      <recent_messages>0</recent_messages>
      <unseen_messages>0</unseen_messages>
    </folder>
    <folder>
      <name>Sent Items</name>
      <url_name>Sent%20Items</url_name>
      <size>512</size>
      <num_messages>0</num_messages>
      <recent_messages>0</recent_messages>
      <unseen_messages>0</unseen_messages>
    </folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::mkdir;

Example:

  <vsap type="webmail:folders:mkdir"><subdirectory>Barkis</subdirectory></vsap>

Returns:

  <vsap type="webmail:folders:mkdir">
    <subdirectory>Barkis</subdirectory>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::rename;

Example:

  <vsap type="webmail:folders:rename"><folder>David</folder><new_folder>Copperfield</new_folder></vsap>

Returns:

  <vsap type="webmail:folders:rename">
    <folder>David</folder>
    <new_folder>Copperfield</new_folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::subscribe;

Example:

  <vsap type="webmail:folders:subscribe"><folder>Barkis</folder></vsap>

Returns:

  <vsap type="webmail:folders:subscribe">
    <folder>Barkis</folder>
  </vsap>

=head2 VSAP::Server::Modules::vsap::webmail::folders::unsubscribe;

Example:

  <vsap type="webmail:folders:unsubscribe"><folder>Barkis</folder></vsap>

Returns:

  <vsap type="webmail:folders:unsubscribe">
    <folder>Barkis</folder>
  </vsap>

=head1 SEE ALSO

vsap::webmail(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

Based on the original F<folders.pm> for Signature.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
