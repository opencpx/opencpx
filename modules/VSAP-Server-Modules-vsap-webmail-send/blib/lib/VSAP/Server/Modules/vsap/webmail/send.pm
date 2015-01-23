package VSAP::Server::Modules::vsap::webmail::send;

use 5.008001;
use strict;
use warnings;

use VSAP::Server::G11N::Mail;
use MIME::Lite;
use MIME::Types;
use Mail::Address;
use Text::Wrap;
use Email::Valid;
use Encode qw/encode decode/;
use Encode::IMAPUTF7;
use POSIX qw/tzset/;

use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

use constant MAX_ATTACHMENT_SIZE => 10*1024*1024;

our $VERSION = '0.01';

our $Debug = 0;

our %_ERR = ( WM_MISSING_TO           => 100,
              WM_BAD_TO               => 101,
              WM_BAD_REPLYTO          => 102,
              WM_BAD_CC               => 103,
              WM_BAD_BCC              => 104,
              WM_BAD_SUBJECT          => 105,
              WM_BAD_TEXT             => 106,
              WM_MISSING_ATTACH       => 107,
              WM_SEND_FAILED          => 108,
              WM_INVALID_ADDR         => 109,
              WM_BAD_FROM             => 110,
              WM_ATTACH_DIR           => 111,
              WM_ATTACH_COPY          => 112,
              WM_ATTACH_TOO_BIG       => 113,
              WM_CCLIENT              => 114,
              WM_BAD_UID              => 115,
              WM_ATTACH_MOVE_FAILED   => 116,
            );

sub delete_message_dir {
    my $vsap = shift;
    my $messageid = shift;
    $messageid =~ s/[^a-zA-Z0-9_]//g;  ## consult randomid()
    my $composedir = $vsap->{tmpdir} . "/$messageid";
    return unless $messageid;
    return unless -d $composedir;
    system('rm', '-rf', $composedir)
      and return;
    return 1;
}

our $gmail = VSAP::Server::G11N::Mail->new( { 'DEFAULT_ENCODING' => 'UTF-8' } );

## Functional summary: webmail:send takes UTF-8 data from the webmail
## form fields (we coerce this in the webmail HTML) and encodes it in
## the user's preferred outbound encoding using Perl's Encode module.
## Encode handles glyphs that exist in utf8, but do not exist in the
## target encoding by replacing them with Unicode \x{FFFD}. (see
## Encode(3) for details).
##
## In the previous Signature webmail, we used Iconv for encoding, and
## a special hack was put in the iconv library to replace unencodable
## glyphs with a '?' character.
##
sub handler {
  my $vsap = shift;    # the VSAP server object 
  my $xmlobj = shift;  # the top-level XML element object
  my $dom = shift || $vsap->{_result_dom};

  my %mail_elements;
  my $send_encoding = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "outbound_encoding") 
    || "UTF-8";
  my $save_out = $xmlobj->child("SaveOut") ? $xmlobj->child("SaveOut")->value : '';
  my $drafts = $xmlobj->child("SaveDraft") ? $xmlobj->child("SaveDraft")->value : '';
  my $to     = $xmlobj->child("To") ? $xmlobj->child("To")->value : '';
  if (!$to && !$drafts) {
    $vsap->error($_ERR{WM_MISSING_TO} => "Missing 'To' address.");
    return;
  }

  my $from = $xmlobj->child("From") ? $xmlobj->child("From")->value : '';
  my $from_def = ( $xmlobj->child("From_Addr") ? $xmlobj->child("From_Addr")->value : '' );

  ## $from supplied; make sure we have quotes for phrase portions
  if( $from ) {
      ## split phrase part from whitespace+address part
      if( $from =~ /^([^<]+?)(\s*<[^@]+\@.+>)/ ) {
          my $phrase = $1; my $addr = $2;
          unless( $phrase =~ /^".*"$/ ) {
              $from = qq!"$phrase"! . $addr;
          }
      }
  }

  ## $from not set; create it here from supplied data
  else {
    my $from_name = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "from_name");
    $from_def   ||= VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "preferred_from");

    # Set default user@domain
    $from_def ||= $vsap->{username} . "@" . $vsap->{hostname};
    if($from_name =~ /^".*"$/ ) {
        $from       = ( $from_name ? qq!$from_name! . " <$from_def>" : $from_def );
    } else { 
        $from       = ( $from_name ? qq!"$from_name"! . " <$from_def>" : $from_def );
    }
  }

  ## set timezone based on user pref
  my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') ||
                 VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
  my $tmptimezone = $ENV{'TZ'};
  $ENV{'TZ'} = $timezone;
  POSIX::tzset();

  ## we build a copy of our message in utf8 also for sending over the
  ## dom and saving to file. No data is lost this way, and we don't
  ## break our (utf8-only) dom.
  $mail_elements{From} = build_addresses($vsap->{hostname}, $from, $send_encoding);
  my $utf8_from        = build_addresses($vsap->{hostname}, $from, 'UTF-8');
  $mail_elements{Subject} = $xmlobj->child("Subject") ? $xmlobj->child("Subject")->value : '';
  my $utf8_subject = $gmail->set_subject( { default_encoding => 'UTF-8',
                                            to_encoding      => 'UTF-8',
                                            subject          => $mail_elements{Subject} } );

  $mail_elements{Subject} = $gmail->set_subject (
    {
      'default_encoding' => 'UTF-8',
      'to_encoding' => $send_encoding,
      'subject' => $mail_elements{Subject}
    }
  );

  my $text = $xmlobj->child("Text") ? $xmlobj->child("Text")->value : '';
  my $converted_text = '';
  if( $text ) {
      $converted_text = $gmail->set_body ( { default_encoding => 'UTF-8',
                                             to_encoding      => $send_encoding,
                                             content_encoding => '',
                                             string           => $text } );

      ## make a safe copy for drafts and saved copies
      $text = $gmail->set_body ( { default_encoding => 'UTF-8',
                                   to_encoding      => 'UTF-8',
                                   content_encoding => '',
                                   string           => $text } );
  }

  else {
      $text = { string => ' ',
                encoding => '',
                charset => '' };
  }

  # build initial outgoing e-mail MIME::Lite header
  my $msg;
  my $text_type = $xmlobj->child('TextType') ? $xmlobj->child('TextType')->value : 'TEXT';

  ## create body
  $msg = MIME::Lite->new( From     => $mail_elements{From},
                          Type     => $text_type,
                          Data     => ( $converted_text
                                        ? $converted_text->{string} 
                                        : ' ' ), ## must be non-empty
                          ( $converted_text 
                            ? (Encoding => $converted_text->{encoding})
                            : () ) );

  if( $converted_text ) {
      $msg->attr("content-type.charset" => $converted_text->{charset});
      $msg->attr("content-type.format"  => 'flowed');
  }

  ## make a copy for sending over XML or saving to a file
  my $msg_utf8;
  if( $drafts || $save_out ) {
      $msg_utf8 = MIME::Lite->new( From     => $mail_elements{From},
                                   Type     => $text_type,
                                   Data     => $text->{string},
                                   Encoding => $text->{encoding}, );

      $msg_utf8->attr("content-type.charset" => $text->{charset});
      $msg_utf8->attr("content-type.format"  => 'flowed');
  }

  # split up addresses, validate each, do any header encoding needed for 
  # g11n and add to MIME::Lite object if populated

  my $valid_address_check = 1;
  my %utf8_mail_elements = ();
  foreach my $field (qw(ReplyTo To Cc Bcc)) {
    $mail_elements{$field} = $xmlobj->child($field) ? $xmlobj->child($field)->value : '';
    unless ($mail_elements{$field}) { next; }
    $utf8_mail_elements{$field} = build_addresses($vsap->{hostname}, $mail_elements{$field}, 'UTF-8', $drafts);
    $mail_elements{$field} = build_addresses($vsap->{hostname}, $mail_elements{$field}, $send_encoding, $drafts);

    if( !$mail_elements{$field} ) {
      my $code = "WM_BAD_" . $field;
      $code =~ s/-//g;
      $code = uc($code);
      $vsap->error($_ERR{$code}, "Invalid address in $field field.");
      $valid_address_check = 0;
    } else {
      # hack to retain current ReplyTo input format
      if ($field eq "ReplyTo") { 
        $msg->add("Reply-To" => $mail_elements{$field});
        $msg_utf8->add("Reply-To" => $utf8_mail_elements{$field}) if $drafts || $save_out;
      } else {
        $msg->add($field => $mail_elements{$field});
        $msg_utf8->add($field => $utf8_mail_elements{$field}) if $drafts || $save_out;
      }
    }
  }

  return if(!$valid_address_check);

  # add subject to MIME::Lite object
  $msg->add('Subject' => $mail_elements{Subject}) if($mail_elements{Subject});
  $msg_utf8->add('Subject' => $utf8_subject) if $utf8_subject && ($drafts || $save_out);

  # rfc822 Message attachment
  my $uid = $xmlobj->child("Message/uid") ? $xmlobj->child("Message/uid")->value : '';

  ## FIXME: when is this used? Make some notes please
  if ($uid) {
    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password});
    unless( ref($wm) ) {
        $vsap->error($_ERR{WM_CCLIENT} => "Error creating c-client object");
        return;
    }

    my $folder = $xmlobj->child("Message/folder") ? $xmlobj->child("Message/folder")->value : 'INBOX';
    # folder encodings
    my $utf7_folder = encode('IMAP-UTF-7',$folder);
    $wm->folder_open($utf7_folder);

    my $message = $wm->message_raw($uid);
    unless( $message ) {
        $vsap->error($_ERR{WM_BAD_UID} => "Error reading message '$uid'");
        return;
    }

    system('logger', '-p', 'daemon.notice', "Loading message '$uid' from $utf7_folder") if $Debug;

    $msg->attach( Type        => 'message/rfc822',
                  Data        => $message,
                  Encoding    => '7bit',
                  Disposition => 'attachment'
                );

    $msg_utf8->attach( Type        => 'message/rfc822',
                       Data        => $message,
                       Encoding    => '7bit',
                       Disposition => 'attachment'
                     ) if $drafts || $save_out;
  } 

  ## Attachment time
  my $messageid = $xmlobj->child("messageid") ? $xmlobj->child("messageid")->value : 0;
  $vsap->{composingdir} = ( $messageid ? $vsap->{tmpdir} . "/$messageid" : '' );
  mkdir $vsap->{composingdir} if ($vsap->{composingdir});

  ## load up mime types
  my $mimetypes = MIME::Types->new;

  for my $attachment ( grep { $_ } map { $_->value } $xmlobj->children("Attachment") ) {
      my ($mime_type, $encoding) = $mimetypes->mimeTypeOf($attachment);
      $mime_type = "application/x-unknown" if !$mime_type;
      system('logger', '-p', 'daemon.notice', "($mime_type, $encoding) for $attachment") if $Debug;

      my( $at_file ) = $attachment =~ m!^.*?([^/]+)$!;
      my $utf8_at_file = $at_file; 

      $at_file = $gmail->set_subject( { default_encoding => 'utf-8',
                                        to_encoding      => $send_encoding,
                                        subject => Encode::decode_utf8($at_file) || $at_file } );

      $utf8_at_file = $gmail->set_subject( { default_encoding => 'utf-8',
                                        to_encoding      => 'utf-8',
                                        subject => Encode::decode_utf8($utf8_at_file) || $utf8_at_file } );


      system('logger', '-p', 'daemon.notice', "Attaching $attachment") if $Debug;

      use bytes;
      my $attach_path = $vsap->{composingdir} . "/$attachment";
      no bytes;

      # MIME::Types thinks xlsx should be encoded in 'binary' (BUG29544)
      $encoding = 'base64' if ($mime_type eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

      # MIME::Types thinks xps should be sent in plain '8bit' encoding (BUG31587)
      $encoding = 'base64' if ($mime_type eq "application/vnd.ms-xpsdocument");

      $msg->attach( Type        => $mime_type,
                    Filename    => $at_file,
                    Path        => $attach_path,
                    Encoding    => $encoding,
                    Disposition => 'attachment'
                  );

      $msg_utf8->attach( Type        => $mime_type,
                         Filename    => $utf8_at_file,
                         Path        => $attach_path,
                         Encoding    => $encoding,
                         Disposition => 'attachment'
                       ) if $drafts || $save_out;
  }

  # now loop for attachments in the $messageid dir
 DO_ATTACH: {
      last DO_ATTACH unless $messageid;

      unless( opendir ATTACHDIR, $vsap->{composingdir} ) {
          $vsap->error( $_ERR{WM_ATTACH_DIR} => "Could not open attachment directory: $!" );
          return;
      }

      for my $attachment ( grep { !/^\.\.?$/ } readdir(ATTACHDIR) ) {
          my $attachName = $attachment;
          my ($mime_type, $encoding) = $mimetypes->mimeTypeOf($attachName);
          $mime_type = "application/x-unknown" if ! $mime_type;
          system('logger', '-p', 'daemon.notice', "($mime_type, $encoding) for $attachment") if $Debug;

          my( $at_file ) = $attachName =~ m!^.*?([^/]+)$!;
          my $utf8_at_file = $at_file;

          $at_file = $gmail->set_subject( { default_encoding => 'utf-8',
                                            to_encoding => $send_encoding,
                                            subject => Encode::decode_utf8($at_file) || $at_file } );

          $utf8_at_file = $gmail->set_subject( { default_encoding => 'utf-8',
                                            to_encoding => 'utf-8',
                                            subject => Encode::decode_utf8($utf8_at_file) || $utf8_at_file } );

          system('logger', '-p', 'daemon.notice', "Attaching $attachName") if $Debug;

          use bytes;
          my $attach_path = $vsap->{composingdir} . "/$attachment";
          no bytes;

          # MIME::Types thinks xlsx should be encoded in 'binary' (BUG29544)
          $encoding = 'base64' if ($mime_type eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

          # MIME::Types thinks xps should be sent in plain '8bit' encoding (BUG31587)
          $encoding = 'base64' if ($mime_type eq "application/vnd.ms-xpsdocument");

          $msg->attach( Type        => $mime_type,
                        Filename    => $at_file,
                        Path        => $attach_path,
                        Encoding    => $encoding,
                        Disposition => 'attachment'
                      );

          $msg_utf8->attach( Type        => $mime_type,
                             Filename    => $utf8_at_file,
                             Path        => $attach_path,
                             Encoding    => $encoding,
                             Disposition => 'attachment'
                           ) if $drafts || $save_out;
      }

      closedir ATTACHDIR;
  }  ## DO_ATTACH

  # send with sendmail, and send as the user
  if( !$drafts ) {
      my $send_success = 0;

      ## have a $from_def, use it (sendmail allows ruid root to do -f)
      if( $from_def ) {
          $msg->send("sendmail", "/usr/sbin/sendmail -t -oi -oem -f$from_def");
          $send_success = $msg->last_send_successful;
      }

      ## do a safe-pipe open. Long story short: we used to do a
      ## setreuid here (see the cvs diffs). Swapping *back* to our
      ## euid and root real uid causes Perl to unset the POK flag on
      ## otherwise good scalar strings (and enables taint and magic
      ## flags on the scalar) henceforth and forever for the life of
      ## the process. We avoid the double setreuid by forking and
      ## letting the child die with its privileges
      else {
          my $pid = open(READER, "-|");
          local $SIG{PIPE} = 'IGNORE';
          if( $pid ) {
              $send_success = <READER>;
              close READER;
              ($send_success) = $send_success =~ /(.*)/s;  ## just in case
          }

          ## use the looked up username from /etc/passwd (sendmail does
          ## this using the realuid of the process, hence the setreuid)
          else {
              ($>, $<) = ($<, $>);     ## make real uid the authz user
              $msg->send("sendmail", "/usr/sbin/sendmail -t -oi -oem");
              print $msg->last_send_successful;
              exit;
          }
      }

      unless( $send_success ) {
          my $rnode = $dom->createElement('vsap');
          $rnode->setAttribute( type => 'webmail:send' );
          $rnode->appendTextChild( status => 'not ok' );
          $dom->documentElement->appendChild($rnode);
          return;
      }
  }


  ##
  ## if saving copy to Sent Items folder or saving to Drafts folder, 
  ## return full email message as formatted by MIME::Lite to caller
  ##
  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute( type => 'webmail:send' );

  ## Notice: as_string can croak when the body is empty (e.g., from
  ## encoding errors). We should consider wrapping as_string in an eval,
  ## but for now we catch the problem when we create the message body
  $root_node->appendTextChild( email_msg => $msg_utf8->as_string )
    if $save_out || $drafts;
  $root_node->appendTextChild( status => 'ok');
  $dom->documentElement->appendChild($root_node);

  ## clean up composition directory
  delete_message_dir($vsap, $messageid);

  ## reset time zone
  $ENV{'TZ'} = $tmptimezone;
  POSIX::tzset();

  return;
}

sub build_addresses {
    my $hostname = shift;
    my $address_string = shift;
    my $send_encoding  = shift;
    my $save_draft  = shift;

    my $return_string = '';

        # This is done here, so we can send email to multiple addresses seperated by a ;
        # Address->parse does not parse based on semicolons, so if we catch it here, it will, and validation
        # still is done below

        $address_string =~ s/;/,/g;

    for my $addr_obj ( Mail::Address->parse($address_string) ) {
        my $address = $addr_obj->address;
        my $phrase  = $addr_obj->phrase;

        ## unqualified address
        unless( $address =~ /\@/ ) {
            $address .= '@' . $hostname;
        }

        ## replace localhost domains with hostname
        if( $address =~ /\@localhost$/ ) {
            $address =~ s/\@localhost$/\@$hostname/;
        }

        ## FIXME: throw a better error here
        unless ( $save_draft ) {
            next unless Email::Valid->address( -address => $address, -fqdn => 0 );
        }
        else {
            ## impose some miscellaneous clean up to the draft copy in order to 
            ## avoid sendmail replacing mangled e-mail addresses in the draft 
            ## with the somewhat befuddling "MISSING_MAILBOX@MISSING_DOMAIN"
            $address =~ s/^\.+//g;  # strip leading periods (BUG27706)
        }

        $addr_obj->address($address);

        ## encode the phrase part
        if( $phrase ) {
            $phrase =~ s/^\s*"//;
            $phrase =~ s/"\s*$//;
            $phrase = $gmail->set_subject( { to_encoding   => $send_encoding,
                                             from_encoding => 'UTF-8',
                                             subject       => $phrase, } );
            $phrase = qq("$phrase");
            $addr_obj->phrase($phrase);
        }

        $return_string .= ( $return_string ? ', ' : '' ) . $addr_obj->format;
    }

    return $return_string;
}


package VSAP::Server::Modules::vsap::webmail::send::messageid;

use strict;

sub handler {
  my $vsap = shift;
  my $xmlobj = shift;
  my $dom = shift || $vsap->{_result_dom};
  my $messageid = randomid();
  while (-e $vsap->{tmpdir} . "/$messageid") {
    $messageid = randomid();
  }
  $vsap->{composingdir} = $vsap->{tmpdir} . "/$messageid";
  mkdir $vsap->{composingdir};

  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute( type => 'webmail:send:messageid' );
  $root_node->appendTextChild('messageid', $messageid);
  $dom->documentElement->appendChild($root_node);

  return;
}

## Note: fix delete_message_dir() and messages::attachment() if you
## Note: change this @chars set
sub randomid {
  my $messageid;
  my @chars=('a'..'z','A'..'Z','0'..'9','_');
  foreach (0..20) {
     $messageid .= $chars[rand @chars];
  }
  return $messageid;
}

package VSAP::Server::Modules::vsap::webmail::send::attachment::add;

use File::Copy;
use VSAP::Server::Modules::vsap::webmail::messages;

sub handler {
  my $vsap = shift;     # the VSAP server object
  my $xmlobj = shift;     # the top-level XML element object
  my $dom = shift || $vsap->{_result_dom};

  my $messageid = $xmlobj->child("messageid") ? $xmlobj->child("messageid")->value : 0;
  my $filename = $xmlobj->child("filename") ? $xmlobj->child("filename")->value : 0;

  my $destfile = $filename;
  $destfile =~ s/(.*)(\/|\\)//g;
  ($destfile) = (VSAP::Server::Modules::vsap::webmail::messages::_guess_string_encoding($destfile))[0];

  my $origfilepath = $vsap->{tmpdir} . "/$destfile";
  my $origfilesize = -s $origfilepath || 0;

  $vsap->{composingdir} = $vsap->{tmpdir} . "/$messageid";
  mkdir $vsap->{composingdir};

  if ($origfilesize > VSAP::Server::Modules::vsap::webmail::send::MAX_ATTACHMENT_SIZE) { 
    $vsap->error($_ERR{WM_ATTACH_TOO_BIG} => "'$filename' is too large.");
    return;
  }

  unless( opendir ATTACHDIR, $vsap->{composingdir} ) {
      $vsap->error( $_ERR{WM_ATTACH_DIR} => "Could not open attachment directory: $!" );
      return;
  }

  my $totalsize = 0;
  use bytes;
  foreach my $attach (sort grep { !/^\.\.?$/ } readdir ATTACHDIR) {
    $totalsize += -s $vsap->{composingdir} . "/$attach";
  }
  no bytes;
  closedir ATTACHDIR;

  if ($totalsize + $origfilesize >= VSAP::Server::Modules::vsap::webmail::send::MAX_ATTACHMENT_SIZE) { 
      $vsap->error($_ERR{WM_ATTACH_TOO_BIG} => "'$filename' would make attachments too large.");
      return;
  }

  use bytes;
  my $attach_path = $vsap->{composingdir} . "/$destfile";
  no bytes;
  File::Copy::move($origfilepath, $attach_path) or do {
      $vsap->error($_ERR{WM_ATTACH_MOVE_FAILED} => "move of '$origfilepath' to '$attach_path' failed: " . $!);
  };

  system('logger', '-p', 'daemon.notice', "adding attachment: $destfile") if $Debug;

  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute( type => 'webmail:send:attachment:add');
  $root_node->appendTextChild( filename => $destfile );
  $root_node->appendTextChild( status   => 'ok' );
  $dom->documentElement->appendChild($root_node);

  return;
}

package VSAP::Server::Modules::vsap::webmail::send::attachment::list;

use VSAP::Server::Base;

sub handler {
  my $vsap = shift;
  my $xmlobj = shift;
  my $dom = shift || $vsap->{_result_dom};

  my $messageid = $xmlobj->child("messageid") ? $xmlobj->child("messageid")->value : 0;
  $vsap->{composingdir} = $vsap->{tmpdir} . "/$messageid";
  mkdir $vsap->{composingdir};

  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute( type => 'webmail:send:attachment:list' );

  unless( opendir ATTACHDIR, $vsap->{composingdir} ) {
      $vsap->error( $_ERR{WM_ATTACH_DIR} => "Could not open attachment directory: $!" );
      return;
  }

  for my $attach (sort grep { !/^\.\.?$/ } readdir ATTACHDIR) {
      use bytes;
      my $size = -s $vsap->{composingdir} . "/$attach";
      no bytes;

      my $attach_name = Encode::decode_utf8($attach) || $attach;
      my $attachment_node = $dom->createElement('attachment');
      $attachment_node->appendTextChild( filename     => $attach_name );
      $attachment_node->appendTextChild( url_filename => VSAP::Server::Base::url_encode($attach) );
      $attachment_node->appendTextChild( size         => $size );
      $root_node->appendChild($attachment_node);
  }
  closedir ATTACHDIR;

  $dom->documentElement->appendChild($root_node);
  return;
}

package VSAP::Server::Modules::vsap::webmail::send::attachment::delete;

sub handler {
  my $vsap = shift;
  my $xmlobj = shift;
  my $dom = shift || $vsap->{_result_dom};

  my $filename = $xmlobj->child("filename") ? $xmlobj->child("filename")->value: 0;
  my $messageid = $xmlobj->child("messageid") ? $xmlobj->child("messageid")->value : 0;
  $vsap->{composingdir} = $vsap->{tmpdir} . "/$messageid";

  unless( opendir ATTACHDIR, $vsap->{composingdir} ) {
      $vsap->error( $_ERR{WM_ATTACH_DIR} => "Could not open attachment directory: $!" );
      return;
  }

  close ATTACHDIR;

  my $root_node = $dom->createElement('vsap');
  $root_node->setAttribute( type => 'webmail:send:attachment:delete' );
  use bytes;
  system('logger', '-p', 'daemon.notice', "Trying to delete $filename") if $Debug;
  unlink $vsap->{composingdir} . "/" . $filename;
  no bytes;
  $root_node->appendTextChild( status => 'ok' );
  $dom->documentElement->appendChild($root_node);
  return;
}

package VSAP::Server::Modules::vsap::webmail::send::attachment::delete_all;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $messageid = ( $xmlobj->child('messageid')
                      ? $xmlobj->child('messageid')->value
                      : '' );

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'webmail:send:attachment:delete_all' );

    if( VSAP::Server::Modules::vsap::webmail::send::delete_message_dir($vsap, $messageid) ) {
        $root->appendTextChild( status => 'ok' );
    }
    else {
        $root->appendTextChild( status => 'failed' );
    }

    $dom->documentElement->appendChild($root);

    return;
}

__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail::send - VSAP webmail sending module.

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail::send;

=head1 DESCRIPTION

  <vsap type="webmail:send">
    <To>"Jimbo" &lt;jim@plush.com&gt;</To>
    <From/>
    <ReplyTo/>
    <Cc/>
    <Bcc/>
    <Subject>Hey</Subject>
    <Text>Hi There.</Text>
    <Message>
      <uid>11</uid>
      <folder>INBOX</folder>
    </Message>
    <Attachment/>
    <SaveOut>yes</SaveOut>
  </vsap>

This module sends a mail message. A user's outbound mail encoding preference is used to encode mail headers and body content.

When the Message node is set, the specified message will be fetched and included as an rfc822 message attachment.

When the SaveOut attribute is sent (any non-zero value will suffice), an additional value is added to the xml response returned to the caller:

<email_msg>[complete email message sent to recipient]</email_msg>

When the SaveDraft attribute is set, a full copy of the MIME::Lite-formatted email message is added (without sending it to any recipient) to the xml response returned to the caller:

<email_msg>[complete email message sent to recipient]</email_msg>

=head1 AUTHOR

Dan Brian E<lt>dbrian@improvist.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
