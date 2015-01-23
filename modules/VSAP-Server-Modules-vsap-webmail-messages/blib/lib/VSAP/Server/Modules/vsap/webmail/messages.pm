package VSAP::Server::Modules::vsap::webmail::messages;

use 5.008001;

use strict;
use warnings;
use Encode qw/encode decode from_to/;
use Encode::IMAPUTF7;
use Encode::Guess;
use Encode::HanExtra;  # for GB18030 support (BUG35211)

our $VERSION = '0.01';

our %_ERR = ( WM_CCLIENT              => 100,
              WM_FOLDER_OPEN          => 101,
              WM_DELETE               => 102,
              WM_FOLDER_MISSING       => 103,
              WM_FOLDER_EXIST         => 104,
              WM_FLAG                 => 105,
              WM_UID_MISSING          => 106,
              WM_APPEND_FAILED        => 108,
              WM_MESSAGE_MISSING      => 109,
              WM_ATTACH_ID_MISSING    => 110,
              WM_BAD_UID              => 111,
              WM_FOLDER_SRC_NOREAD    => 112,
              WM_FOLDER_SRC_NOWRITE   => 113,
              WM_FOLDER_DEST_NOWRITE  => 114,
              WM_MOVE_FAILED          => 115,
              WM_MESSAGEDIR           => 116,
              WM_QUOTA                      => 117,
            );

our $Debug = 0;
use POSIX('uname');

use constant VPS2 => -d '/skel' || ((POSIX::uname())[0] =~ /Linux/)? 1 : 0;

BEGIN { 
    require VSAP::Server::Modules::vsap::user::prefs
        if (VPS2);
}

our $SYS_FOLDER_REGEX = qr(^(?:INBOX|Sent Items|Trash|Drafts|Quarantine|Junk)$)o;


##############################################################################

sub _guess_string_encoding
{
    my $string = shift;

    # -----------------------------------------------------------------------
    # NOTE: there is a guess_string_encoding() in string/encoding.pm in CPX
    #       which is considered authoritative.  be sure any updates here are
    #       also represented there or changes here may get clobbered.
    # -----------------------------------------------------------------------

    # remove evil spirits
    $string =~ s/[\x01-\x08\x0B\x0C\x0E-\x1F]//g;

    my $converter = Text::Iconv->new("UTF-8", "UTF-8");
    my $converted = $converter->convert($string);
    if ($string eq $converted) {
        return($string, "utf-8")
    }

    # try and guess the encoding
    my $charset;
    if ($string =~ m![^\011\012\015\040-\176]!) {
        # string contains "high-byte" characters; see if we can't guess what
        # the encoding is (it could just be utf8; it could be anything)
        my $enc;
        # first guess... iso-8859-1
        $enc = guess_encoding($string, qw/iso-8859-1/);
        # next guess... japanese
        $enc = guess_encoding($string, qw/iso-2022-jp euc-jp shiftjis 7bit-jis/) unless (ref($enc));
        # next guess... chinese
        $enc = guess_encoding($string, qw/iso-2022-cn euc-cn big5-eten/) unless (ref($enc));
        if (ref($enc)) {
            $charset = $enc->name;
            $charset =~ tr/A-Z/a-z/;
            if (($charset eq "utf8") || ($charset eq "utf-8")) {
                return($string, "utf-8") 
            }
            # decode
            warn("decoding contents from $charset to utf-8");
            from_to($string, $charset, "utf-8");
            undef($enc);
        }
        else {
            # punt
            $charset = "UNKNOWN";
            warn("suspect encoding could not be guessed... punting!");
            $string =~ s![^\011\012\015\040-\176]!?!go;
        }
    }
    return($string, $charset);
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::list;

use VSAP::Server::G11N::Mail;
use POSIX('uname');
use Encode qw/encode decode/;

use constant VPS2 => -d '/skel' || ((POSIX::uname())[0] =~ /Linux/)? 1 : 0;

sub handler {
    my $vsap = shift;    # the VSAP server object
    my $xmlobj = shift;  # the top-level XML element object
    my $dom    = shift || $vsap->{_result_dom};

    my $reload_prefs = $xmlobj->child('reload_prefs') ? 1 : 0;

    my $folder = ( $xmlobj->child("folder") && $xmlobj->child('folder')->value
                   ? $xmlobj->child("folder")->value 
                   : 'INBOX' );

    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $encoding = ( $xmlobj->child('encoding') && $xmlobj->child('encoding')->value
                     ? $xmlobj->child('encoding')->value
                     : 'UTF-8' );

    my $page = ( $xmlobj->child('page') && $xmlobj->child('page')->value
                 ? $xmlobj->child('page')->value
                 : 1 );

    ## FIXME: this should all be consolidated with 'messages::read'

    ## these view settings are saved as preferenes
    my %sort_prefs = ( messages_sortby  => 'date',        ## date | arrival | from | subject | to | cc | size
                       messages_order   => 'descending',  ## descending | ascending
                       messages_sortby2 => 'from',        ## date | arrival | from | subject | to | cc | size
                       messages_order2  => 'descending',  ## descending | ascending
                     );

    for my $pref ( keys %sort_prefs ) {
        (my $s_pref = $pref) =~ s/messages_//;
        $sort_prefs{$pref} = ( $xmlobj->child($s_pref) && $xmlobj->child($s_pref)->value
                               ? $xmlobj->child($s_pref)->value
                               : VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, $pref) );
    }

    ## FIXME: make old sortby become sortby2 field for safe sorts
    ## FIXME: (except where the field is the same)

    ## fix defaults for sorting
    if( $sort_prefs{messages_sortby} eq 'from' && $sort_prefs{messages_sortby2} eq 'from' ) {
        $sort_prefs{messages_sortby2} = 'date';
    }

    ## read some preferences and settings
    my $timezone;
    if (VPS2) { 
        $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone', $reload_prefs) || 'GMT';
    } 
    else { 
        $timezone = $vsap->{prefs}->{timeZoneInfo} || 'GMT';
    }

    my $msgs_per_page = int(VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, 'messages_per_page'))
      || 10;

    ## FIXME: this 'set_values' call must be after the last get_value call in this method.
    ## save prefs back out to file
    VSAP::Server::Modules::vsap::webmail::options::set_values( $vsap, $dom, %sort_prefs );

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }


    ## make sure folder exists
    my $fl = $wm->folder_list;
    unless( $fl->{$utf7_folder} ) {
        unless( $folder =~ $SYS_FOLDER_REGEX ) {
            $vsap->error($_ERR{WM_FOLDER_EXIST} => "Folder does not exist");
            return;
        }

        $wm->folder_create($utf7_folder);
    }

    my $msgs = $wm->messages_sort($utf7_folder,
                                  $sort_prefs{messages_sortby}  => 
                                  ( $sort_prefs{messages_order}  eq 'descending' ? 1 : 0 ),
                                  $sort_prefs{messages_sortby2} => 
                                  ( $sort_prefs{messages_order2} eq 'descending' ? 1 : 0 ) );

    # check for negative UIDs (BUG26825)
    # note: at 2147483647, a 32-bit signed int will wrap to negative integer
    for my $muid ( @$msgs ) {
        if (($muid < 0) || ($muid >= 2147483647)) {
            # remove X-UID headers from mailbox and re-sort
            system('logger', '-p', 'daemon.notice', "bad UID found for $folder") if $Debug;
            use bytes;
            my $path = ($utf7_folder eq "INBOX") ? $wm->{_inboxpath} : 
                                  $wm->{_homedir} . "/Mail/" . $utf7_folder;
            no bytes;
            my @command = ();
            my $sed = (-e "/bin/sed") ? "/bin/sed" : "/usr/bin/sed";
            push(@command, $sed);
            push(@command, "-i");
            push(@command, "'/^X-UID:/d;s/X-IMAP:.*/X-IMAP: 1 0000000001/g;s/X-IMAPbase:.*/X-IMAPbase: 1 0000000001/g'");
            push(@command, $path);
            my $command = join(" ", @command);
            open(COMMAND, "$command 2>&1 |");
            my $output = "";
            while (<COMMAND>) {
                $output .= $_;
            }
            close(COMMAND);
            system('logger', '-p', 'daemon.notice', "sed output=$output") if $Debug && $output; 
            # reload messages from folder
            system('logger', '-p', 'daemon.notice', "reloading messages") if $Debug;
            $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
            $msgs = $wm->messages_sort($utf7_folder,
                                          $sort_prefs{messages_sortby}  => 
                                          ( $sort_prefs{messages_order}  eq 'descending' ? 1 : 0 ),
                                          $sort_prefs{messages_sortby2} => 
                                          ( $sort_prefs{messages_order2} eq 'descending' ? 1 : 0 ) );
            last;
        }
    }

    my $num_messages = @$msgs || 0;
    my $total_pages = ( $msgs_per_page > 0 && $num_messages > 0 
                        ? ( $num_messages % $msgs_per_page
                            ? int($num_messages / $msgs_per_page) + 1
                            : int($num_messages / $msgs_per_page) )
                        : 1);

    if ($page > $total_pages) { $page = 1; }
    my $prev_page = ($page == 1) ? '' : $page - 1;
    my $next_page = ($page == $total_pages) ? '' : $page + 1;
    my $first_message = 1 + ($msgs_per_page * ($page - 1));
    if ($num_messages < 1) { $first_message = 0; }
    my $last_message = $first_message + $msgs_per_page - 1;
    if ($last_message > $num_messages) { $last_message = $num_messages; }
    if ($last_message < 1) { $last_message = 0; }

    ## build DOM
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:list' );

    $root_node->appendTextChild( num_messages  => $num_messages );
    $root_node->appendTextChild( page          => $page );
    $root_node->appendTextChild( total_pages   => $total_pages );
    $root_node->appendTextChild( prev_page     => $prev_page );
    $root_node->appendTextChild( next_page     => $next_page );
    $root_node->appendTextChild( first_message => $first_message );
    $root_node->appendTextChild( last_message  => $last_message );
    $root_node->appendTextChild( folder        => $folder );
    $root_node->appendTextChild( url_folder    => VSAP::Server::Base::url_encode($folder) );
    $root_node->appendTextChild( sortby        => $sort_prefs{messages_sortby} );
    $root_node->appendTextChild( order         => $sort_prefs{messages_order} );
    $root_node->appendTextChild( sortby2       => $sort_prefs{messages_sortby2} );
    $root_node->appendTextChild( order2        => $sort_prefs{messages_order2} );

    if( $num_messages ) {
        for my $uid ( @$msgs[($first_message-1 .. $last_message-1)] ) {
            my $msg = $wm->message($utf7_folder, $uid, 1)
              or do {
                  ## FIXME: do something...
                  next;
              };

            my $msg_node = $dom->createElement('message');
            $msg_node->appendTextChild( uid  => $uid );

            ##
            ## date
            ##
            my $date_node = $dom->createElement('date');
          DO_DATE: {
                my $datestr = $msg->{date};
                $datestr =~ s![^\011\012\015\040-\176]!!go;
                last DO_DATE unless $datestr;
                system('logger', '-p', 'daemon.notice', "DATE: $datestr") if $Debug;
                my $d = new VSAP::Server::G11N::Date( date => $datestr,
                                                      tz   => $timezone );
                last DO_DATE unless $d;

                $date_node->appendTextChild( year   => $d->local->year    );
                $date_node->appendTextChild( month  => $d->local->month   );
                $date_node->appendTextChild( day    => $d->local->day     );
                $date_node->appendTextChild( hour   => $d->local->hour    );
                $date_node->appendTextChild( hour12 => $d->local->hour_12 );
                $date_node->appendTextChild( minute => $d->local->minute  );
                $date_node->appendTextChild( second => $d->local->second  );
                $date_node->appendTextChild( tz     => $d->local->tz      );

                $date_node->appendTextChild( o_year   => $d->original->year    );
                $date_node->appendTextChild( o_month  => $d->original->month   );
                $date_node->appendTextChild( o_day    => $d->original->day     );
                $date_node->appendTextChild( o_hour   => $d->original->hour    );
                $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
                $date_node->appendTextChild( o_minute => $d->original->minute  );
                $date_node->appendTextChild( o_second => $d->original->second  );
                $date_node->appendTextChild( o_offset => $d->original->offset  );
            }
            $msg_node->appendChild($date_node);

            my @flags = @{$msg->{flags}};
            if( @flags ) {
                my $flag_node = $dom->createElement('flags');
                $flag_node->appendTextChild( flag => $_ ) for @flags;
                $msg_node->appendChild($flag_node);
            }

            my $g11n_mail = VSAP::Server::G11N::Mail->new({default_encoding => 'UTF-8'});

            for my $elem qw( to from ) {
                next unless ref($msg->{$elem});

                my $elem_node = $dom->createElement($elem);

                for my $hdr ( @{ $msg->{$elem} } ) {
                    my $addr_node = $dom->createElement('address');

                    ## personal
                    my $personal = ( $hdr->{personal}
                                     ? $g11n_mail->get_address( { default_encoding => $encoding,
                                                                  to_encoding => 'UTF-8',
                                                                  address => [ $hdr->{personal} ] } )->[0]
                                                                    || $hdr->{personal}
                                     : '' );
                    system('logger', '-p', 'daemon.notice', "PERSONAL: $personal") if $Debug;
                    if ($encoding eq 'UTF-8') {
                       $personal = Encode::decode_utf8( $personal );
                    }
                    $addr_node->appendTextChild( personal => $personal );  ## FIXME

                    ## mailbox
                    my $mailbox = ( $hdr->{mailbox}
                                    ? $g11n_mail->get_address( { default_encoding => $encoding,
                                                                 to_encoding => 'UTF-8',
                                                                 address => [ $hdr->{mailbox} ] } )->[0]
                                                                   || $hdr->{mailbox}
                                    : '' );
                    system('logger', '-p', 'daemon.notice', "MAILBOX: $mailbox") if $Debug;
                    $addr_node->appendTextChild( mailbox => $mailbox );

                    ## hostname
                    my $host    = ( $hdr->{host}
                                    ? $g11n_mail->get_address( { default_encoding => $encoding,
                                                                 to_encoding => 'UTF-8',
                                                                 address => [ $hdr->{host} ] } )->[0]
                                                                   || $hdr->{host}
                                    : '' );
                    system('logger', '-p', 'daemon.notice', "HOST: $host") if $Debug;
                    $addr_node->appendTextChild( host => $host );
                    $addr_node->appendTextChild( full_address => ( $mailbox && $host 
                                                                   ? $mailbox . '@' . $host
                                                                   : '' ) );
                    $elem_node->appendChild($addr_node);
                }
                $msg_node->appendChild($elem_node);
            }

          CONVERT_SUBJECT: {
                system('logger', '-p', 'daemon.notice', 'Original subject: ' . $msg->{subject}) if $Debug;
                # Attempt to display non-ascii characters in the subject and if
                # they can't be displayed at least keep from showing a vsap error.

              my $subject;
              if ($msg->{subject} =~ m![^\011\012\015\040-\176]!) {
                  # guess encoding
                  my ($guess, $name) = VSAP::Server::Modules::vsap::webmail::messages::_guess_string_encoding($msg->{subject});
                  $msg->{subject} = $guess if ($guess ne $msg->{subject});
                  $subject = $msg->{subject};
              } 
              else { 
                if ($msg->{subject} =~ /[^[:ascii:]]/) {
                    $msg->{subject} =~ s/([^[:ascii:]])/$g11n_mail->set_subject({default_encoding => 'ISO-8859-1', to_encoding => 'ISO-8859-1', subject => $1})/ge;
                }
                $msg->{subject} =~ s/[^[:ascii:]]/?/;

                $subject = ( $msg->{subject} 
                                ? $g11n_mail->get_subject( { default_encoding => $encoding,
                                                             to_encoding   => 'UTF-8',
                                                             subject       => $msg->{subject}} )
                                                               || $msg->{subject}
                                : '' );
                system('logger', '-p', 'daemon.notice', "SUBJECT: $subject") if $Debug;
              }

              $msg_node->appendTextChild( subject => $subject );
            }

            ## check for attachments
            $msg_node->appendTextChild( attachments => $msg->{numattachments} );
            $msg_node->appendTextChild( inline_attachments => $msg->{numinline} );
            $msg_node->appendTextChild( rfc822_size => $msg->{rfc822_size} );

            $root_node->appendChild($msg_node);
        }
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::delete;

use Encode qw/encode decode/;
use Quota;

sub handler {
    my $vsap    = shift;  # the VSAP server object
    my $xmlobj  = shift;  # the top-level XML element object
    my $dom     = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child("folder") && $xmlobj->child('folder')->value
                   ? $xmlobj->child("folder")->value 
                   : '' );

    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    unless( $folder ) {
        $vsap->error($_ERR{WM_FOLDER_MISSING} => "Specify a folder for delete" );
        return;
    }

    my @uids = ( $xmlobj->children('uid')
                 ? grep { defined $_ and /^\d+$/ } map { $_->value } $xmlobj->children('uid')
                 : () );

    unless( @uids ) {
        $vsap->error($_ERR{WM_UID_MISSING} => "UID missing" );
        return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error( $_ERR{WM_CCLIENT} => "Error creating c-client object" );
        return;
    }

    ## is quota defined for this user?  if so, then remove quota info 
    ## temporarily to allow enough space for move to Trash to execute 
    ## successfully (BUG27576, BUG31872)
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

    $wm->messages_delete($utf7_folder, join(',', @uids));

    # restore quota from above if necessary (BUG27576, BUG31872)
    if ($uquota || $gquota) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, $vsap->{uid}, $uquota, $uquota, 0, 0, 0, 0);
            Quota::setqlim($dev, $gid, $gquota, $gquota, 0, 0, 0, 1);
            Quota::sync($dev);
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:delete' );
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::move;

use Encode qw/encode decode/;
use Quota;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child("folder") && $xmlobj->child('folder')->value
                   ? $xmlobj->child("folder")->value 
                   : 'INBOX' );

    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $dest_folder = ( $xmlobj->child("dest_folder") && $xmlobj->child('dest_folder')->value
                        ? $xmlobj->child("dest_folder")->value 
                        : '' );

    # folder encodings
    my $utf7_dest_folder = encode('IMAP-UTF-7',$dest_folder);

    unless( $folder && $dest_folder ) {
        $vsap->error($_ERR{WM_FOLDER_MISSING} => "Source or destination folder missing");
        return;
    }

    my @uids = ( $xmlobj->children('uid')
                 ? grep { defined $_ and /^\d+$/ } map { $_->value } $xmlobj->children('uid')
                 : () );

    unless( @uids ) {
        $vsap->error($_ERR{WM_UID_MISSING} => "UID missing" );
        return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) { $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }

    ## make sure destination folder exists (create system folder if necessary)
    my $fl = $wm->folder_list();
    unless( $fl->{$utf7_dest_folder} ) {  ## folder not in our list
        unless( $dest_folder =~ $SYS_FOLDER_REGEX ) {
            $vsap->error($_ERR{WM_FOLDER_EXIST} => "Destination folder does not exist");
            return;
        }

        ## system folders should be created
        $wm->folder_create($utf7_dest_folder);
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

    my $error = 0;
    $wm->messages_move(join(',', @uids), $utf7_folder, $utf7_dest_folder)
      or do {
          $error = 1;
      };

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

    if ($error) {
        if ( $wm->log =~ /(?:open destination mailbox|not writable)/io ) {
            $vsap->error($_ERR{WM_FOLDER_DEST_NOWRITE} => "Destination folder not writable");
        }

        elsif ( $wm->log =~ /(?:not readable|is empty)/ ) {
            $vsap->error($_ERR{WM_FOLDER_SRC_NOREAD} => "Source folder not readable");
        }

        elsif ( $wm->log =~ /(?:Disc quota exceeded)/ ) {
            $vsap->error($_ERR{WM_QUOTA} => "Disc Quota exceeded");
        }

        else {
            $vsap->error($_ERR{WM_MOVE_FAILED} => "Failed moving message: " . $wm->log);
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:move' );
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::flag;

use Encode qw/encode decode/;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
                   ? $xmlobj->child('folder')->value 
                   : 'INBOX' );

    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $flag   = ( $xmlobj->child('flag') && $xmlobj->child('flag')->value
                   ? $xmlobj->child('flag')->value
                   : '' );

    my @uids   = ( $xmlobj->children('uid')
                   ? grep { defined $_ and /^\d+$/ } map { $_->value} $xmlobj->children('uid')
                   : () );

    unless( $flag && @uids ) {
        $vsap->error($_ERR{WM_FLAG} => 'Missing flag or uid');
        return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object" );
        return;
    }

    $wm->messages_flag($utf7_folder, join(',',@uids), $flag);
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:flag' );
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::attachment;

use Encode qw/encode decode/;
use HTML::Scrubber::StripScripts;
use VSAP::Server::G11N::Mail;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
                   ? $xmlobj->child('folder')->value 
                   : 'INBOX' );
    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $uid    = ( $xmlobj->child('uid') && $xmlobj->child('uid')->value
                   ? $xmlobj->child('uid')->value
                   : '' );

    unless( $uid ) {
        $vsap->error( $_ERR{WM_UID_MISSING} => "UID missing in read message");
        return;
    }

    ## get the requested attachment ids for this $uid
    my %attach_ids = ( $xmlobj->children('attach_id')
                      ? map { $_->value => 1 } $xmlobj->children('attach_id')
                      : () );

    unless( keys(%attach_ids) ) {
        $vsap->error($_ERR{WM_ATTACH_ID_MISSING} => 'No attach_id specified');
        return;
    }

    ## get the messageid foldername where we'll save this attachment
    my $messageid = ( $xmlobj->child('messageid') && $xmlobj->child('messageid')->value
                      ? $xmlobj->child('messageid')->value
                      : '' );
    $messageid =~ s/[^a-zA-Z0-9_]//g;  ## this set comes from messages::send::messageid::randomid()

    ## open mailbox
    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object" );
        return;
    }

    ## fetch this message
    my $message = $wm->message($utf7_folder, $uid);
    unless( $message ) {
        $vsap->error($_ERR{WM_BAD_UID} => "Error reading message '$uid'");
        return;
    }

    ## build dom
    my $root_node = $dom->createElement( 'vsap' );
    $root_node->setAttribute( type => 'webmail:messages:attachment' );

    my $attach_dir = $vsap->{tmpdir} . ( $messageid ? "/$messageid" : '' );
    if( $messageid && ! -d $attach_dir ) {
        $vsap->error($_ERR{WM_MESSAGEDIR} => "Message dir not a directory" );
        return;
    }

    ## we'll use this object for any internationalization garbage
    my $g11n_mail = VSAP::Server::G11N::Mail->new({default_encoding => 'UTF-8'});

    for my $attachment ( @{$message->{attachments}} ) {
        my $aid = $attachment->{attach_id};
        next unless (defined($attach_ids{$aid}));  ## not interested... skip
        # get decoded attachment name from original character set (if defined)
        my $default_encoding = 'UTF-8';
        my $from_encoding = $attachment->{name_encoding} || '';
        my $attach_name;
        if ( $attachment->{name} ) {
            if ( $from_encoding =~ /^utf-8$/i ) {
                $attach_name = $attachment->{name};
            }
            else {

                $attach_name = $g11n_mail->get_attachment_name( { default_encoding => 'UTF-8',
                                                                  from_encoding => $from_encoding,
                                                                  to_encoding => 'UTF-8',
                                                                  attachments => [ $attachment->{name} ] } )->[0] 
                                 || $attachment->{name};
            }
        }
        else {
            $attach_name = VSAP::Server::Base::xml_escape( $attachment->{discrete} . '-' . $attachment->{composite} );
        }
        system('logger', '-p', 'daemon.notice', "Decoded filename: " . $attach_name) if $Debug;

        # encode attachment name into hex for apache response headers
        my $enc_filename = $attach_name;
        utf8::encode($enc_filename) if (utf8::is_utf8($enc_filename));
        if ($attach_name =~ m![^\011\012\015\040-\176]!) {
            $enc_filename =~ s/([^\011\012\015\040-\176])/uc sprintf("%%%02x",ord($1))/eg;
            $enc_filename = "utf-8''" . $enc_filename
        }
        else {
            $enc_filename = "us-ascii'en-us'" . $enc_filename
        }
        # save the attachment for this $aid to file
        my $target = $attach_dir;
        if ($messageid) {
            use bytes;
            $target = $attach_dir . "/" . $attach_name;
            no bytes;
            # check for multiple attachments that have the same name
            my $inc = 1;
            while (-e "$target") {  
                use bytes;
                $target =  $attach_dir . "/" . $inc . "_" . $attach_name;
                no bytes;
                $inc++;
            }
        }
        my ($filename, $mime_type) = $wm->save_message_attachment_to_file($utf7_folder, $uid, $aid, $target);

        # rub-a-dub scrub (ENH23615)
        my $path = "$attach_dir/$filename";
        if ($filename =~ /\.htm(l?)$/i) {
            my $original_html = "";
            open(HTML, "$path");
            $original_html .= $_ while (<HTML>);
            close(HTML);
            my $hss = HTML::Scrubber::StripScripts->new( Allow_src      => 1,
                                                         Allow_href     => 1,
                                                         Allow_a_mailto => 1,
                                                         Whole_document => 1 );
            my $clean_html = $hss->scrub( $original_html );
            if ( $clean_html ne $original_html ) {
                open(HTML, ">$path");
                print HTML $clean_html;
                close(HTML);
            }
        }

        # append attachment info to dom
        my $attach_node = $dom->createElement('attachment');
        $attach_node->appendTextChild( attach_id    => $aid );
        $attach_node->appendTextChild( path         => $path );
        #$attach_node->appendTextChild( name         => $attach_name );
        $attach_node->appendTextChild( filename     => $filename );
        $attach_node->appendTextChild( url_filename => VSAP::Server::Base::url_encode($attach_name) );
        $attach_node->appendTextChild( enc_filename => $enc_filename );
        $attach_node->appendTextChild( mime_type    => $mime_type );
        $root_node->appendChild($attach_node);
    }

    $dom->documentElement->appendChild( $root_node );
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::forward;

use Encode qw/encode decode/;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = $xmlobj->child("folder") ? $xmlobj->child("folder")->value :
      'INBOX';
    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object" );
        return;
    }

    my $uid = $xmlobj->child("uid") ? $xmlobj->child("uid")->value : '';
    return unless $uid;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:forward' );
    $root_node->appendTextChild('uid', $uid);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::read;

use VSAP::Server::G11N::Date;
use Text::Wrap;
use POSIX('uname');
use Encode qw/encode decode/;
use HTML::Scrubber::StripScripts;
use HTML::Parser 3.00 ();

use constant VPS2 => -d '/skel' || ((POSIX::uname())[0] =~ /Linux/)? 1 : 0;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
                   ? $xmlobj->child('folder')->value
                   : 'INBOX' );

    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $uid    = ( $xmlobj->child('uid') && $xmlobj->child('uid')->value
                   ? $xmlobj->child('uid')->value
                   : '' );

    my $beautify =   ( $xmlobj->child('beautify') && $xmlobj->child('beautify')->value
                       ? $xmlobj->child('beautify')->value 
                       : 'yes' );

    my $quotestring = ( $xmlobj->child('quote') && $xmlobj->child('quote')->value
                     ? $xmlobj->child('quote')->value : '' );

    my $strip_html  = ( $xmlobj->child('strip_html')
                        ? $xmlobj->child('strip_html')->value
                        : '' );

    my $save_attach = ( $xmlobj->child('save_attach') && 
                $xmlobj->child('save_attach')->value   ? 
                $xmlobj->child('save_attach')->value : 'no' );

    # we don't want an encoding unless it's incoming
    my $encoding = ( $xmlobj->child('encoding') && $xmlobj->child('encoding')->value
                     ? $xmlobj->child('encoding')->value
                     : '' );

    ## fetch all webmail options
    my $wm_options = VSAP::Server::Modules::vsap::webmail::options::as_hash($vsap, $dom);

    ## possible: 'plain' or 'html'
    my $viewpref = ( $xmlobj->child('viewpref') && $xmlobj->child('viewpref')->value
                     ? $xmlobj->child('viewpref')->value
                     : $wm_options->{multipart_view} || '' );

    my $attachview = ( $xmlobj->child('attachview') && $xmlobj->child('attachview')->value
                       ? $xmlobj->child('attachview')->value
                       : $wm_options->{attachment_view} || 'attachments' );

    my $local_images = ( $xmlobj->child('localimages') && $xmlobj->child('localimages')->value
                         ? $xmlobj->child('localimages')->value
                         : $wm_options->{fetch_images_local} || 'yes' );

    my $remote_images = ( $xmlobj->child('remoteimages') && $xmlobj->child('remoteimages')->value
                          ? $xmlobj->child('remoteimages')->value
                          : $wm_options->{fetch_images_remote} || 'no' );

    unless( $uid ) {
        $vsap->error( $_ERR{WM_UID_MISSING} => "UID missing in read message");
        return;
    }

    ## these view settings are saved as preferenes
    my %sort_prefs = ( messages_sortby  => 'date',        ## date | arrival | from | subject | to | cc | size
                       messages_order   => 'descending',  ## descending | ascending
                       messages_sortby2 => 'from',        ## date | arrival | from | subject | to | cc | size
                       messages_order2  => 'descending',  ## descending | ascending
                     );

    for my $pref ( keys %sort_prefs ) {
        (my $s_pref = $pref) =~ s/messages_//;
        $sort_prefs{$pref} = ( $xmlobj->child($s_pref) && $xmlobj->child($s_pref)->value
                               ? $xmlobj->child($s_pref)->value
                               : $wm_options->{$pref} );
    }

    ## fix defaults for sorting
    if( $sort_prefs{messages_sortby} eq 'from' && $sort_prefs{messages_sortby2} eq 'from' ) {
        $sort_prefs{messages_sortby2} = 'date';
    }

    ## save prefs back out to file
    VSAP::Server::Modules::vsap::webmail::options::set_values( $vsap, $dom, %sort_prefs );

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => "webmail:messages:read" );

    my $msgs = $wm->messages_sort($utf7_folder,
                                  $sort_prefs{messages_sortby}  => 
                                  ( $sort_prefs{messages_order}  eq 'descending' ? 1 : 0 ),
                                  $sort_prefs{messages_sortby2} => 
                                  ( $sort_prefs{messages_order2} eq 'descending' ? 1 : 0 ) );

    $root_node->appendTextChild( num_messages => scalar @$msgs );

    ## do navigation: determine previous and next messages
    my $prev = '';
    my $next = '';
    my $msgno = 0;
    for my $mno ( 0 .. $#$msgs ) {
        next unless $uid == $msgs->[$mno];
        $prev = $msgs->[$mno-1] unless ($mno-1) < 0;
        $next = $msgs->[$mno+1] unless ($mno+1) > $#$msgs;
        $msgno = $mno;
        last;
    }

    $root_node->appendTextChild( folder   => $folder );
    $root_node->appendTextChild( msgno    => $msgno + 1);  ## not used as an index; only for
                                                           ## display "Viewing message N of M"
    $root_node->appendTextChild( prev_uid => $prev );
    $root_node->appendTextChild( next_uid => $next );
    $root_node->appendTextChild( uid      => $uid );

    ## now read the message itself
    my $timezone;
    my $autohl = $wm_options->{url_highlight};

    if (VPS2) { 
        $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') || 'GMT';
    } 
    else { 
        $timezone = $vsap->{prefs}->{timeZoneInfo} || 'GMT';
    }

    system('logger', '-p', 'daemon.notice', "About to read the message in messages:read") if $Debug;
    my $message = $wm->message($utf7_folder, $uid);
    system('logger', '-p', 'daemon.notice', "message charset: " . $message->{charset}) if $Debug;

    my $body_charset = ( $message->{charset}
                         ? $message->{charset}
                         : ( $message->{body}->{'text/plain'}->{charset} 
                             ? $message->{body}->{'text/plain'}->{charset}
                             : ( $message->{body}->{'text/html'}->{charset}
                                 ? $message->{body}->{'text/html'}->{charset}
                                 : '' ) ) );

    ## we'll use this object for any internationalization garbage
    my $g11n_mail = VSAP::Server::G11N::Mail->new({default_encoding => 'UTF-8'});

    system('logger', '-p', 'daemon.notice', "About to parse date headers in messages:read") if $Debug;

    ##
    ## date
    ##
    my $date_node = $dom->createElement('date');
  DO_DATE: {
        last DO_DATE unless $message->{date};
        my $d = new VSAP::Server::G11N::Date( date => $message->{date},
                                              tz   => $timezone );
        last DO_DATE unless $d;

        $date_node->appendTextChild( year   => $d->local->year    );
        $date_node->appendTextChild( month  => $d->local->month   );
        $date_node->appendTextChild( day    => $d->local->day     );
        $date_node->appendTextChild( hour   => $d->local->hour    );
        $date_node->appendTextChild( hour12 => $d->local->hour_12 );
        $date_node->appendTextChild( minute => $d->local->minute  );
        $date_node->appendTextChild( second => $d->local->second  );
        $date_node->appendTextChild( tz     => $d->local->tz      );

        $date_node->appendTextChild( o_year   => $d->original->year    );
        $date_node->appendTextChild( o_month  => $d->original->month   );
        $date_node->appendTextChild( o_day    => $d->original->day     );
        $date_node->appendTextChild( o_hour   => $d->original->hour    );
        $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
        $date_node->appendTextChild( o_minute => $d->original->minute  );
        $date_node->appendTextChild( o_second => $d->original->second  );
        $date_node->appendTextChild( o_offset => $d->original->offset  );
    }
    $root_node->appendChild($date_node);

    ##
    ## flags
    ##
    my $flag_node = $dom->createElement('flags');
    $flag_node->appendTextChild( flag => $_ ) for @{$message->{flags}};
    $root_node->appendChild($flag_node);

    $root_node->appendTextChild( rfc822_size => $message->{rfc822_size} );

    ##
    ## message body
    ##
    sub beautify { 
        $_[0] =~ s/(\n||&#010;)/$1<br>/g;
        ## ... add more beautification here ...
        $_[0];
    }

    system('logger', '-p', 'daemon.notice', "encoding: $encoding, body_charset: $body_charset") if $Debug;

    ## elaborate multipart/alternative selection
    ## Email           Prefs           Result
    ## ======================================
    ## plain only      plain           plain
    ## plain only      html            plain
    ## plain/html      plain           plain
    ## plain/html      html            html
    ## html only       plain           html
    ## html only       html            html

    my %viewpref = ();
    for my $alt qw( plain html ) {
        if( $message->{body}->{"text/$alt"}->{text} ) {
            $viewpref{$alt} = 1;
        }
    }

    ## select one of the parts
    if( scalar keys %viewpref > 1 ) {
        my $alt_parts_node = $dom->createElement('alt_parts');
        $alt_parts_node->appendTextChild( alt => $_ ) for keys %viewpref;
        $root_node->appendChild( $alt_parts_node );

        ## from incoming user options in $xmlobj
        if( $viewpref ) {
            unless( $viewpref =~ /^(?:plain|html)$/ ) {
                $viewpref = 'plain';
            }
        }
        $viewpref ||= 'plain';
    }

    ## only one part to view
    else {
        ($viewpref) = keys %viewpref;
    }
    $viewpref ||= 'plain'; ## for messages w/ empty bodies

    $root_node->appendTextChild( alt_view => $viewpref );

    if( $viewpref eq 'plain' ) {
        system('logger', '-p', 'daemon.notice', "About to process text body messages:read") if $Debug;
        # the text portion will be text even if the message is multipart
        my $text = '';
        if( defined($message->{body}->{'text/plain'}->{text}) ) {
            # guess encoding for body
            if ($body_charset =~ "ASCII" and ($message->{body}->{'text/plain'}->{text} =~ m![^\011\012\015\040-\176]! ) ) {
                my ($guess, $name) = VSAP::Server::Modules::vsap::webmail::messages::_guess_string_encoding( $message->{body}->{'text/plain'}->{text} );
                $encoding = uc($name);
                $text = $guess if ($guess ne $text);
            }
            $text = $g11n_mail->get_body( { default_encoding => $encoding,
                                            from_encoding    => ( $encoding ? $encoding : ( $body_charset ? $body_charset : 'UTF-8' ) ),
                                            to_encoding      => 'UTF-8',
                                            string           => $message->{body}->{'text/plain'}->{text} } ) || 
                    $message->{body}->{'text/plain'}->{text};
            # remove evil spirits from message body
            $text =~ s/[\x01-\x09\x0B\x0C\x0E-\x1F]//g;
        }

        ## wrap and quote text, if quoting
        if( $quotestring ) {
            $Text::Wrap::columns = 75;
            $quotestring = Encode::decode_utf8( $quotestring );
            $text = Text::Wrap::wrap($quotestring, $quotestring, $text); 
        }


        # Here, we use ~l~ to represent the < and ~g~ to represent >, 
        # and ~'~' to represent " We do this so they don't get stompped 
        # by the xml_escape function. 

        if ($autohl eq 'yes') {
            $text =~ s{\b(([a-z]*tps?):[\w/#~:.?+=&%@!\-]+?)(?=[.:?\-]*(?:[^\w/#~:.? +=&%@! \-]|$))}
                            {~l~la target=~'~'newWin~'~' href=~'~'$1~'~'~g~g$1~l~l/a~g~g}igx;
        }

        $text = VSAP::Server::Base::xml_escape($text);

        # Turn the < > and " back into the right chars. 
        $text =~ s/~l~l/</g;
        $text =~ s/~g~g/>/g;
        $text =~ s/~'~'/"/g;

        $text = beautify($text) if $beautify eq "yes";

        my $text_node = $dom->createElement('body');
        $text_node->appendText($text);
        $text_node->setAttribute("orig_charset", uc($body_charset));
        $root_node->appendChild($text_node);
    }

    elsif( $viewpref eq 'html' ) {
        system('logger', '-p', 'daemon.notice', "About to process html body messages:read") if $Debug;
        my $text = '';
        if( defined($message->{body}->{'text/html'}->{text}) ) {
           $text    = $g11n_mail->get_body( { default_encoding => $encoding,
                                              from_encoding    => ( $encoding 
                                                                    ? $encoding 
                                                                    : ( $body_charset 
                                                                        ? $body_charset 
                                                                        : 'UTF-8' ) ),
                                              to_encoding      => 'UTF-8',
                                              string => $message->{body}->{'text/html'}->{text} } )
          || $message->{body}->{'text/html'}->{text};
        }

        ## strip some evil characters
        $text =~ s/[\r]//g;

        system('logger', '-p', 'daemon.notice', "Got html body: $text") if $Debug;

        ## wipe dis stinkin' HTML
        ## section pretty much taken from HTML::Parser/eg/htext
        if( $strip_html ) {
            my %intag   = ();
            my $outtext = '';
            system('logger', '-p', 'daemon.notice', "Stripping all HTML from text") if $Debug;
            HTML::Parser->new( api_version => 3,
                               handlers    => [ start => [sub { $intag{$_[0]} += $_[1]; $outtext .= ' ' },
                                                          "tagname, '+1'"],
                                                end   => [sub { $intag{$_[0]} += $_[1]; $outtext .= ' ' },
                                                          "tagname, '-1'"],
                                                text  => [sub { return if $intag{script} || $intag{style};
                                                                $outtext .= $_[0] },
                                                          "text"],
                                              ], marked_sections => 1, )->parse($text);
            $text = $outtext;
            system('logger', '-p', 'daemon.notice', "Stripped HTML results: $text") if $Debug;
        }

        ## make this HTML safe for most purposes
        else {
            my %inline_cid  = map { $_->{cid}      => $_ } grep { $_->{cid} }      @{$message->{attachments}};
            my %inline_name = map { $_->{name}     => $_ }                         @{$message->{attachments}};
            my %inline_loc  = map { $_->{location} => $_ } grep { $_->{location} } @{$message->{attachments}};
            my $mime_loc = $message->{body}->{'text/html'}->{location} || '';
            my $allow_local_src  = ($local_images  eq 'yes');
            my $allow_remote_src = ($remote_images eq 'yes');

            $root_node->appendTextChild( localimages  => $local_images );
            $root_node->appendTextChild( remoteimages => $remote_images );

            ## we're overriding HTML::Scrubber::StripScripts' defaults here
            local $HTML::Scrubber::StripScripts::re{a_mailto} = qr#^(?:ht|f)tps?://#;
            local $HTML::Scrubber::StripScripts::re{url}      = qr#.*#;

            my $scrubber = new HTML::Scrubber::StripScripts( Allow_src      => 1,
                                                             Allow_href     => 1,
                                                             Allow_a_mailto => 1, );

            my $has_local_images  = '';
            my $has_remote_images = '';
            $scrubber->{_p}->handler( default => sub {
                                          my (undef, $e, $t, $a) = @_;
                                          if( $e eq 'start' ) {

                                              ## find images and rewrite them
                                              if( $t eq 'img' ) {
                                                  my $src = $a->{src} || '';
                                                  my $inline = 0;
                                                  my $basename = $src;
                                                  $basename =~ s{$mime_loc}{};

                                                FIND_INLINE: {
                                                      ## look for a cid tag
                                                      if( $src =~ s/^cid:(.+)/<$1>/i &&
                                                          exists $inline_cid{$src} ) {
                                                          $inline = $inline_cid{$src};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      ## look for an attachment name
                                                      if( exists $inline_name{$src} ) {
                                                          $inline = $inline_name{$src};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      ## look for a mime location
                                                      if( exists $inline_loc{$src} ) {
                                                          $inline = $inline_loc{$src};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      ## look for a relative mime location
                                                      if( exists $inline_loc{$mime_loc . $src} ) {
                                                          $inline = $inline_loc{$mime_loc . $src};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      ## look for a relative mime location by name
                                                      if( exists $inline_name{$basename} ) {
                                                          $inline = $inline_name{$basename};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      ## look for it without the uri
                                                      if( $inline_loc{$basename} ) {
                                                          $inline = $inline_loc{$basename};
                                                          last FIND_INLINE if $inline;
                                                      }

                                                      else {
#system('logger', '-p', 'daemon.notice', "not found: $mime_loc / $src");
#system('logger', '-p', 'daemon.notice', "loc: $_") for keys %inline_loc;
#system('logger', '-p', 'daemon.notice', "name: $_") for keys %inline_name;
                                                      }
                                                  }

                                                  ## show images if settings allow it
                                                REWRITE_IMAGES: {
                                                      $a->{src} = '';

                                                      if( $inline ) {
                                                          $has_local_images = 1;
                                                          last REWRITE_IMAGES unless $allow_local_src;

                                                        if (VPS2) {
                                                          $a->{src} = "wm_viewmessage.xsl/VSAPDOWNLOAD/?uid=$uid" . 
                                                            "&attach_id=" . $inline->{attach_id} . 
                                                              "&folder=$folder&download=true";
                                                        } 
                                                        else {
                                                          $a->{src} = "message.xsl/VSAPDOWNLOAD/?uid=$uid" . 
                                                            "&attachment_num=" . $inline->{attach_id} . 
                                                              "&folder=$folder&download=true";
                                                        }
                                                      }

                                                      elsif( $src =~ $HTML::Scrubber::StripScripts::re{url} ) {
                                                          $has_remote_images = 1;
                                                          last REWRITE_IMAGES unless $allow_remote_src;

                                                          $a->{src} = $src;
                                                      }
                                                  }
                                              }
                                          }
                                          ## NOTICE: if we upgrade HTML::Scrubber, make sure we
                                          ## NOTICE: stay API compatible with this private call
                                          return &HTML::Scrubber::_scrub;  ## call the default handler
                                      }, 'self, event, tagname, attr, attrseq, text' );

            ## this was pulled from HTML::Scrubber
            $scrubber->_optimize();
            $scrubber->{_p}->parse($text);
            $scrubber->{_p}->eof();
            $text = delete $scrubber->{_r};

            ## NOTE: $has_*_images won't be set until after we call $scrubber->{_p}->_parse()
            $root_node->appendTextChild( has_local_images  => ($has_local_images  ? 'yes' : 'no') );
            $root_node->appendTextChild( has_remote_images => ($has_remote_images ? 'yes' : 'no') );
        }

        ## append this node if we can successfully convert it
        system('logger', '-p', 'daemon.notice', "Final HTML body: $text") if $Debug;
        $root_node->appendTextChild( body => $text );
    }

    ##
    ## from/to/cc
    ##
    for my $elem qw( to from cc bcc reply_to ) {
        my $hdr_node = $dom->createElement($elem);

        for my $hdr ( @{ $message->{$elem} } ) {
            my $elem_node = $dom->createElement('address');
            
            my $personal = ( $hdr->{personal}
                             ? $g11n_mail->get_address( { default_encoding => ( $encoding 
                                                                                ? $encoding 
                                                                                : ( $body_charset
                                                                                    ? $body_charset
                                                                                    : ( $g11n_mail->{USED_BODY_ENCODING}
                                                                                        ? $g11n_mail->{USED_BODY_ENCODING}
                                                                                        : 'UTF-8' ) ) ),
                                                          to_encoding => 'UTF-8',
                                                          address => [ $hdr->{personal} ] } )->[0] 
                             || $hdr->{personal}
                             : '' );

            # guess encoding for personal
            if ($personal =~ m![^\011\012\015\040-\176]!) {
                my ($guess, $name) = VSAP::Server::Modules::vsap::webmail::messages::_guess_string_encoding($personal);
                $body_charset = $name;
                $personal = $guess if ($guess ne $personal);
            }

            $elem_node->appendTextChild( personal => $personal );

            my $mailbox = ( $hdr->{mailbox}
                            ? $g11n_mail->get_address( { default_encoding => ( $encoding 
                                                                                ? $encoding 
                                                                                : ( $body_charset
                                                                                    ? $body_charset
                                                                                    : ( $g11n_mail->{USED_BODY_ENCODING}
                                                                                        ? $g11n_mail->{USED_BODY_ENCODING}
                                                                                        : 'UTF-8' ) ) ),
                                                         to_encoding => 'UTF-8',
                                                         address => [ $hdr->{mailbox} ] } )->[0]
                                                           || $hdr->{mailbox}
                            : '' );

            $elem_node->appendTextChild( mailbox => $mailbox );

            my $host    = ( $hdr->{host}
                            ? $g11n_mail->get_address( { default_encoding => ( $encoding 
                                                                                ? $encoding 
                                                                                : ( $body_charset
                                                                                    ? $body_charset
                                                                                    : ( $g11n_mail->{USED_BODY_ENCODING}
                                                                                        ? $g11n_mail->{USED_BODY_ENCODING}
                                                                                        : 'UTF-8' ) ) ),
                                                         to_encoding => 'UTF-8',
                                                         address => [ $hdr->{host} ] } )->[0]
                                                           || $hdr->{host}
                            : '' );
            $elem_node->appendTextChild( host => $host );

            $elem_node->appendTextChild( full => ( $mailbox && $host
                                                   ? $mailbox . '@' . $host
                                                   : '' ) );
            $hdr_node->appendChild($elem_node);
        }
        $root_node->appendChild($hdr_node);
    }

    ## we put the headers after we do the body encoding;
    ## some HTML messages hint the encoding in a <meta> tag.

    ##
    ## subject
    ##
    system('logger', '-p', 'daemon.notice', "About to decode subject in messages:read") if $Debug;
        # Attempt to display non-ascii characters in the subject and if
        # they can't be displayed at least keep from showing a vsap error.

       my $subject;

       if ($message->{subject} =~ m![^\011\012\015\040-\176]!) { #guess encoding for subject
       my ($guess, $name) = VSAP::Server::Modules::vsap::webmail::messages::_guess_string_encoding($message->{subject});
       $message->{subject} = $guess if ($guess ne $message->{subject});
       $subject = $message->{subject};
    } 
    else {
        if ($message->{subject} =~ /[^[:ascii:]]/) {
                $message->{subject} =~ s/([^[:ascii:]])/$g11n_mail->set_subject({default_encoding => 'ISO-8859-1', to_encoding => 'ISO-8859-1', subject => $1})/ge;
        }
        $message->{subject} =~ s/[^[:ascii:]]/?/;

        $subject = ( $message->{subject}
                    ? $g11n_mail->get_subject( { default_encoding => ( $encoding 
                                                                       ? $encoding 
                                                                       : ( $body_charset
                                                                           ? $body_charset
                                                                           : ( $g11n_mail->{USED_BODY_ENCODING}
                                                                               ? $g11n_mail->{USED_BODY_ENCODING}
                                                                               : 'UTF-8' ) ) ),
                                                 to_encoding   => 'UTF-8',
                                                 subject       => $message->{subject}} ) 
                    || $message->{subject}
                    : '' );

        }
    $root_node->appendTextChild( subject => $subject );

    ##
    ## get attachments
    ##
    my $attachments_node = $dom->createElement('attachments');

    for my $attachment ( @{$message->{attachments}} ) {
        ## apply attachment view policies
        last if $attachview eq 'none';
        next if $attachview eq 'inlines'     && $attachment->{disposition} ne 'inline';
        next if $attachview eq 'attachments' && $attachment->{disposition} ne 'attachment';

        my $attach_node = $dom->createElement('attachment');
        $attach_node->appendTextChild( attach_id => $attachment->{attach_id} );
        system('logger', '-p', 'daemon.notice', "Decoding filename: " . $attachment->{name}) if $Debug;
        my $default_encoding = 'UTF-8';
        my $from_encoding = $attachment->{name_encoding} || '';
        my $attachment_name;
        if ( $attachment->{name} ) {
            if ( $from_encoding =~ /^utf-8$/i ) {
                $attachment_name = $attachment->{name};
            }
            else {
               my $default_value = $default_encoding ? $default_encoding : 
                                       ( $body_charset ? $body_charset : 
                                           ( $g11n_mail->{USED_BODY_ENCODING} ? 
                                               $g11n_mail->{USED_BODY_ENCODING} : 'UTF-8' ) );
               $attachment_name = $g11n_mail->get_attachment_name( { default_encoding => $default_value,
                                                                     from_encoding => $from_encoding,
                                                                     to_encoding => 'UTF-8',
                                                                     attachments => [ $attachment->{name} ] } )->[0]
                                    || $attachment->{name};
            }
        }
        else {
            $attachment_name = VSAP::Server::Base::xml_escape( $attachment->{discrete} . '-' . $attachment->{composite} );
        }
        system('logger', '-p', 'daemon.notice', "Decoded filename: " . $attachment_name) if $Debug;

        $attach_node->appendTextChild( name      => $attachment_name );
        $attach_node->appendTextChild( discrete  => VSAP::Server::Base::xml_escape( $attachment->{discrete} ) );
        $attach_node->appendTextChild( composite => VSAP::Server::Base::xml_escape( $attachment->{composite} ) );
        $attach_node->appendTextChild( encoding  => VSAP::Server::Base::xml_escape( $attachment->{encoding} ) );
        $attach_node->appendTextChild( size      => $attachment->{size} );

        ## save attachments if required
        if ($save_attach eq "yes") {
            my $fullpath;
            my $attach_dir = $vsap->{tmpdir};
            use bytes;
            $fullpath = $attach_dir . "/" . $attachment_name;
            no bytes;
            # check for multiple attachments that have the same name
            my $inc = 1;
            while (-e "$fullpath") {  
                use bytes;
                $fullpath =  $attach_dir . "/" . $inc . "_" . $attachment_name;
                no bytes;
                $inc++;
            }
            # retrieve attachment and save it to local filesystem
            my ($filename) = ($wm->save_message_attachment_to_file($utf7_folder, $uid, $attachment->{attach_id}, $fullpath))[0];
            $attach_node->appendTextChild( filepath    => "$filename" );  
        }

        $attachments_node->appendChild($attach_node);
    }
    $root_node->appendChild($attachments_node);

    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::raw;

use Encode qw/encode decode/;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $folder = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
                   ? $xmlobj->child('folder')->value
                   : 'INBOX' );
    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    my $uid    = ( $xmlobj->child('uid') && $xmlobj->child('uid')->value
                   ? $xmlobj->child('uid')->value
                   : '' );

    unless( $uid ) {
        $vsap->error( $_ERR{WM_UID_MISSING} => "UID missing in read message");
        return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }

    $wm->folder_open($utf7_folder);

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => "webmail:messages:raw" );
    my $body_node = $dom->createElement('body');

    my $body = $wm->message_raw($uid);
    ## FIXME: this clobbers all unicode stuff too
    $body = VSAP::Server::Base::xml_escape($body);
    $body =~ s![^\011\012\015\040-\176]!?!go;  ## non-printables go bye-bye
    $body =~ s/\r/\&#013;/g;
    $body =~ s/\n/\&#010;/g;

    my $body_cdata = $dom->createCDATASection($body);
    $body_node->addChild($body_cdata);
    $root_node->addChild($body_node);
    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::webmail::messages::save;

use Encode qw/encode decode/;

sub handler {
    my $vsap    = shift;
    my $xmlobj  = shift;
    my $dom     = shift || $vsap->{_result_dom};

    my $folder  = ( $xmlobj->child('folder') && $xmlobj->child('folder')->value
                    ? $xmlobj->child('folder')->value
                    : '' );
    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);

    unless( $folder ) {
        $vsap->error($_ERR{WM_FOLDER_MISSING} => "Folder missing for save");
        return;
    }

    my $message = ( $xmlobj->child('message') && $xmlobj->child('message')->value
                    ? $xmlobj->child('message')->value
                    : '' );

    unless( $message ) {
        $vsap->error($_ERR{WM_MESSAGE_MISSING} => "Message missing for save");
        return;
    }

    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }

    ## create special folders if necessary
    unless( exists $wm->folder_list->{$utf7_folder} ) {
        if( $folder =~ $SYS_FOLDER_REGEX ) {
            $wm->folder_create($utf7_folder);
        }

        else {
            $vsap->error($_ERR{WM_FOLDER_EXIST} => "Destination folder does not exist");
            return;
        }
    }

    ## be sure message is properly encoded in utf8
    my $utf8_message;
    eval {
      $utf8_message = Encode::encode('UTF-8', Encode::decode('UTF-8', $message)); 
    };
    if ($@ =~ /Cannot decode/) {
      $utf8_message = $message;
    }

    $wm->message_save($utf7_folder, $utf8_message) 
      or do {
          $vsap->error($_ERR{WM_APPEND_FAILED} => "Could not append message to '$folder': " . $wm->log);
          return;
      };

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'webmail:messages:save' );
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::messages - VSAP webmail message handling

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::messages;

=head1 DESCRIPTION

=head2 list

Returns an XML list of messages as well as some summary information
about the specified mailbox.

  <vsap type="webmail:messages:list"/>

  <vsap type="webmail:messages:list"><folder>Trash</folder></vsap>

=head2 delete

Deletes messages from the specified folder.

  <vsap type="webmail:messages:delete">
    <folder>Trash</folder>
    <uid>1</uid>
    <uid>3</uid>
  </vsap>

=head2 move

Move messages from one mailbox to another.

  <vsap type="webmail:messages:move">
    <uid>1</uid>
    <uid>4</uid>
    <folder>INBOX</folder>
    <dest_folder>Trash</dest_folder>
  </vsap>

=head2 flag

Sets the specified flag on the sequence of messages in the specified
mailbox.

  <vsap type="webmail:messages:flag">
    <folder>INBOX</folder>
    <uid>1</uid>
    <uid>4</uid>
    <flag>\Deleted</flag>
  </vsap>

=head2 attachment

Detaches the specified attachment I<attach_id> from message I<uid> in
the specified folder. Returns the pathname to the file.

  <vsap type="webmail:messages:attachment">
    <folder>INBOX</folder>
    <uid>4</uid>
    <attach_id>1</attach_id>
    <attach_id>...</attach_id>
  </vsap>

returns:

  <vsap type="webmail:messages:attachment">
    <attachment>
      <attach_id>1</attach_id>
      <path>/path/to/attachment.tgz</path>
    </attachment>
    <attachment>...</attachment>
  </vsap>

=head2 forward

=head2 read

Returns the contents of the specified message in the specified folder.

=head2 save

Saves a specified message to the specified folder.

  <vsap type="webmail:messages:save">
    <folder>Drafts</folder>
    <message>Date: Fri, 26 Jun 2004 17:30:25 GMT&#010;From: Charlie Root &lt;root@thursday.securesites.net>&#010;To: joe@thursday.securesites.net&#010;Subject: Joe Rocks!&#010;&#010;Your good friends in system administration wish you a happy birthday.&#010;&#010;Charlie&#010;</message>
  </vsap>

=head1 SEE ALSO

vsap(1), VSAP::Server::Modules::vsap::webmail(3)

=head1 AUTHOR

Scott Wiersdorf E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
