package ControlPanel2::FileTransfer;

use 5.006001;
use strict;
#use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our $VERSION = '3.1';
our $UID     = (getpwuid($>))[2];

use Text::Iconv;
use ControlPanel::MetaProc;
#use VSAP::Server::Util;
use Apache2::Upload;
use Apache2::Const -compile => qw(:common :http :log OK DECLINED M_GET M_POST M_OPTIONS);

use POSIX('uname');
use constant IS_LINUX => ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;
use constant IS_VPS => (-d '/skel' || IS_LINUX) ? 1 : 0;
use constant IS_SIGNATURE => ( ! IS_VPS );

my $auth_filename = "auth.xsl";
my $client_encoding_name = "clientencoding";
my $mime_file = ( IS_VPS ? "/www/conf/mime.types" : "/usr/local/apache-cp/conf/mime.types" );

sub authenticated {
  my $dom = shift;
  my $cp = shift;
  
  $cp->debug(10, "Calling MetaProc for an upload/download authentication with dom:\n" . $dom->toString);
  my $mp = ControlPanel::MetaProc->new (DOM => $dom, CP => $cp);
  my $document_file = $mp->process($auth_filename);
  $cp && $cp->debug(10,"Meta data processed, returned '$document_file'");
  if ($document_file ne $auth_filename) {
    # User did not authenticate successfully
    return 0;
  }
  
  return 1;
}

sub default_response_format {
  my $mime_type = shift;
  my $extension = shift;

  $mime_type =~ tr/A-Z/a-z/;
  $extension =~ tr/A-Z/a-z/;
  my $default = "download";  # possible values: "download" or "print"
  if ($mime_type && 
      (($mime_type =~ m#text/plain#) || ($mime_type =~ m#text/htm#) ||
       ($mime_type =~ m#image/jpeg#) || ($mime_type =~ m#image/pjpeg#) ||
       ($mime_type =~ m#image/jpg#) || ($mime_type =~ m#image/jpe#) ||
       ($mime_type =~ m#image/gif#) || ($mime_type =~ m#image/png#))) {
    $default = "print";
  }
  elsif ($extension &&
         (($extension eq "txt") || ($mime_type eq "gif") ||
          ($extension eq "htm") || ($mime_type eq "html") ||
          ($extension eq "jpe") || ($mime_type eq "jpg") ||
          ($extension eq "jpeg") || ($extension eq "pjpeg") || 
          ($mime_type eq "png"))) {
    $default = "print";
  }
  return($default);
}

# Sets the uid to the user so the web server can access their files
sub switch_to_user {
    return unless ( IS_SIGNATURE );
    my $uid = getpwnam(shift);
    syscall(&VSAP::Server::Util::SYS_setresuid, $uid, $uid, -1);
}

# Switches the process back to the nobody user
sub switch_to_nobody {
    return unless ( IS_SIGNATURE );
    syscall(&VSAP::Server::Util::SYS_setresuid, 65534, 65534, -1);
}

sub encode {
  # Use like this:
  # if ($error = encode ($from_encoding, $to_encoding, $text, \$new_text)) {
  #   print $error;
  # }
  
  my ($from_encoding, $to_encoding, $text, $new_text) = @_;
  
  my ($converter, $converted);
  
  Text::Iconv->raise_error(1);
  eval { $converter = Text::Iconv->new($from_encoding, $to_encoding); };
  if ($@) {
    return "Text::Iconv->new(): $@";
  }
  
  eval { $converted = $converter->convert($text); };
  if ($@) {
    return "Text::Iconv::convert: $@";
  }
  
  $$new_text = $converted;
  return 0;
}

sub upload {
  my $self = shift;
  my %options = @_;
  my $dom = $options{DOM};
  my $cp = $options{CP};
  
  # Make sure user is authenticated
  if (!authenticated($dom, $cp)) {
    return 0;
  }
      
  my $login_id = $dom->findvalue('/cp/vsap/vsap[@type="auth"]/username') or
    do {
        $cp->debug(2, "Could not retrieve login id from DOM");
        return 0;
    };
  my $user_id = ( IS_VPS ? $login_id : $dom->findvalue('/cp/request/userid') ) or
    do {
        $cp->debug(2, "Could not retrieve userid from DOM");
        return 0;
    };

  ## TODO: find a way to get the tmpdir from auth.pm.
  my $upload_dir = ( IS_VPS 
                     ? (getpwnam($login_id))[7]
                     : "/usr/home/$user_id/users/$login_id" ) . '/.cpx_tmp';

  ## come up with a filename to save it as
  my $local_filename = $cp->{req}->param('fileupload');
  $local_filename =~ s/(.*)(\/|\\)//g;
  my $inc = 0;
  my $new_local_filename = $local_filename;
  use bytes;
  while (-e "$upload_dir/$new_local_filename") {
    $new_local_filename = "$inc.$local_filename";
    $inc++;
  }
  $local_filename = $new_local_filename;
  $cp && $cp->debug(10, "going to save uploaded file as $local_filename");
  no bytes;

  my $remote_filename = $cp->{req}->param('fileupload');
  $remote_filename =~ s/(.*)(\/|\\)//g;
  $cp && $cp->debug(10, "remote_filename = $remote_filename");
  $cp && $cp->debug(10, "remote_filename (from dom) = " . $dom->documentElement->findvalue("/cp/form/fileupload"));
  $cp && $cp->debug(10, "remote_filename (coded) = " .  pack 'U*', unpack('U*', $remote_filename));
  
  # Here we actually receive the file and write it to disk
  my $upload = $cp->{req}->upload("fileupload");
  if (!defined($upload)) {
    $cp && $cp->debug(2, "ERROR uploading file, could not get file handle");
    return 0;
  }

  $cp && $cp->debug(4, "upload->name: " . $upload->name);
  $cp && $cp->debug(4, "upload->filename: " . $upload->filename);
  my $info = $upload->info;
  while (my($key, $val) = each %$info) {
    $cp && $cp->debug(4, "upload->info: ($key, $val)");  
  }
  my $fh = $upload->fh;

  # Clear out the error var... (We need to catch the over quota error later)
  $! = '';

  # Switch to the user and write the file into their tmp directory
  switch_to_user($user_id);

  if (!-e $upload_dir) {
    $cp && $cp->debug(10, "creating upload_dir: $upload_dir");
    mkdir $upload_dir;
  }

  use bytes;
  my $local_file = $upload_dir . "/" . $local_filename;
  $cp && $cp->debug(10, "Uploading to $local_file");
  open (OUT, ">$local_file") or
    ($cp && $cp->debug(2, "ERROR opening file to write ($local_file): $!"));
  while (<$fh>) {
    print OUT;
  }
  close OUT;
  no bytes;
  switch_to_nobody();
  close ($fh);
  
  if ($!) {
    $cp && $cp->debug(2, "ERROR uploading file: $!");
    if ($! =~ /quota exceeded/) {
      # If their quota was exceeded, set /cp/request/upload_over_quota to true
      my ($form_node) = $dom->findnodes("/cp/request");
      $form_node->appendTextChild("upload_over_quota", "true");
    }
  }

  # Add the name of the locally stored file in /cp/request/upload_file
  my ($form_node) = $dom->findnodes("/cp/request");
  $form_node->appendTextChild("uploaded_file", $local_filename);
}

sub download {
  my $self = shift;
  my %options = @_;
  my $dom = $options{DOM};
  my $cp = $options{CP};
  
  # make sure user is authenticated
  if (!authenticated($dom, $cp)) {
    return 0;
  }
  
  my $login_id = $dom->findvalue('/cp/vsap/vsap[@type="auth"]/username') or
    do {
        $cp->debug(2, "download(): could not retrieve login id from DOM");
        return 0;
    };

  my $user_id = ( IS_VPS ? $login_id : $dom->findvalue('/cp/request/userid') ) or
    do {
        $cp->debug(2, "download(): ould not retrieve userid from DOM");
        return 0;
    };

  # Determine the nature of their download (owner, share, or vsap)
  my $path = $cp->{req}->path_info();

  my ($owner, $shared, $vsap);
  if ($path =~ /VSAPDOWNLOAD/) {
    $vsap = 1;
  }
  elsif ($path =~ /SHAREDOWNLOAD/) {
    $shared = 1;
  }
  elsif ($path =~ /DOWNLOAD/) {
    $owner = 1;
  }
  
  # grab the filename... and mime type (if defined)
  my ($filename, $url_filename, $enc_filename, $mime_type);
  $filename = $url_filename = $enc_filename = $mime_type = "";
  if ($vsap) {
        $filename = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/filename');
        $url_filename = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/url_filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/url_filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/url_filename') || $filename;
        $enc_filename = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/enc_filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/enc_filename') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/enc_filename') || "utf-8''$filename";
        $mime_type = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/mime_type') || 
                            $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/mime_type') ||
                            $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/mime_type');
  } else {
        $url_filename = $dom->findvalue('/cp/form/path');
        ($filename) = $path =~ m{/([^/]+)$};
        $enc_filename = "utf-8''$filename";
  }

  $cp->debug(5, "download(): path='$path', filename='$filename', mime_type='$mime_type'");
  $cp->debug(5, "download(): url_filename='$url_filename', enc_filename='$enc_filename'");
  
  # get the local download path... and the download request format ("print" or "download") if applicable
  my $local_path = "";
  my $response_format = "";
  if ($vsap) {
        $response_format = ( IS_VPS ?
                                ($dom->findvalue('/cp/vsap/vsap[@type="files:download"]/format') || 
                                 $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/format') || "" ) 
                                : "" );
                         
        $local_path = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="webmail:addressbook:export"]/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/path')
        or do {
            $cp->debug(2, "download(): could not get attachment local path from vsap");
            return 0;
        };
  } 
  elsif ($shared) {
    # get the username of the .shared directory
    my $shared_username = $dom->findvalue('/cp/form/user');
    $local_path = "/usr/home/$user_id/users/$shared_username/.shared/$url_filename";
    $local_path = readlink($local_path) if (-l $local_path);
  } 
  else {
      $local_path = ( IS_VPS ? (getpwnam($login_id))[7] : "/usr/home/$user_id" ) . "/$url_filename";
      if ($user_id ne $login_id) {
          $local_path = "/usr/home/$user_id/users/$login_id/$url_filename";
      }
  }

  switch_to_user($user_id);

  # We need to do the next block in an eval, because if ANYTHING goes wrong we need to make sure to
  # switch back to 'nobody'
  eval {
    # NOTE: the below regex is just a quick fix. We need to change this to use CWD::abs_path 
    # or something similar. This path check will probably only need to be done for end users, and 
    # probably should not resolve symlinks. This check should also be done in the upload and 
    # thumbnail functions.
    #
    # remove any ../ stuff from the path
    while ($local_path =~ s!^\.\./|/\.\./|^\.\.$|/\.\.$!!g) {}

    # Check for existence of file.. 
    if (!-e $local_path) {
      $cp && $cp->debug(1, "download(): file not found... $local_path");
      die "File not found: $local_path";
    } 
    else {
      $cp && $cp->debug(10, "download(): found local_path... $local_path");
    }
    
    # TODO: Add a security check here so users don't download files they're not supposed to
    ## scottw: VPS is always running as Apache; this limits what people can download

    # figure out the extension
    my $extension = "";
    if ( ($filename =~ /.*\.(.*)$/) || ($enc_filename =~ /.*\.(.*)$/) ) {
      $extension = $1;
    }
    if ($extension) {
      $cp->debug(10, "download(): found extension from filename -> $extension");
    }
    elsif (!$extension && $mime_type) {
      # no extension could be extracted from the filename;
      # determine a default extension from the mime_type
      ##
      ## BEGIN COMMENT
      ##
      ## 10/27/10
      ## this section was added and then removed per OCN (BUG26821)
      ##
      ##    "OCN'd like to restore it as before UAT#5 , because 
      ##     this is caused for the specification of I.E. 
      ##     Therefore this is not a bug of CPX. If modified, it 
      ##     is no good from the point of view of universal CPX 
      ##     functions. Verio needs nothing to do and OCN would 
      ##     desire Verio does nothing. This item was caused by 
      ##     OCN originally but OCN cancels this bug report 
      ##     formally."
      ##
      ## leaving it here (but commented out) in case they decide to
      ## change their mind
      ##
      ## $cp->debug(10, "download(): could not find extension from filename");
      ## if (open (MIME, $mime_file)) {
      ##   while (<MIME>) {
      ##     next if /^\s*#/;
      ##     s/\s+/ /g;
      ##     my ($type, @exts) = split(' ', $_);
      ##     if (($type =~ /^$mime_type$/i) && ($#exts > -1)) {
      ##       $extension = $exts[0];  ## use the first one
      ##       last;
      ##     }
      ##   }
      ##   close MIME;
      ## }
      ## if (!$extension && ($ENV{'HTTP_USER_AGENT'} =~ /MSIE/)) {
      ##   # no extension for the filename found with given mime type.  
      ##   # MSIE mangles extensionless filenames that are composed of 
      ##   # multi-byte characters, so add extension here (BUG26821).
      ##   $extension = (-T $local_path) ? "txt" : "bin";
      ## }
      ## if ($extension) {
      ##   $cp->debug(10, "download(): found extension from mime-type -> $extension");
      ##   $cp->debug(10, "download(): adjusting enc_filename -> $enc_filename");
      ##   $filename .= "." . $extension;
      ##   $enc_filename .= "." . $extension;
      ## }
      ##
      ## END COMMENT
      ##
    }

    # if a mime_type has been specified by vsap, then simply use it.
    # otherwise (signature), look through the mime_file for the type
    # matching the extracted extension.
    if (!$mime_type && $extension && IS_SIGNATURE ) {
      if (open (MIME, $mime_file)) {
        while (<MIME>) {
          next if /^\s*#/;
          s/\s+/ /g;
          my ($type, @exts) = split(' ', $_);
          if ( grep(/^$extension$/, @exts) ) {
            $mime_type = $type;
            last;
          }
        }
        close MIME;
      }
    }

    # set the default mime type if one not found
    my $default_mime_type = "application/octet-stream";
    $mime_type ||= $default_mime_type; 

    # set the default response format if not found
    $response_format ||= default_response_format($mime_type, $extension);
    $cp->debug(10, "download(): setting response format -> $response_format");

    # add charset to mime type if required (BUG14572)
    if (($mime_type =~ m#text/plain#) || ($mime_type =~ m#text/htm#)) {
      $mime_type .= "; charset=utf-8";
    }

    if ($response_format eq "print") {
        # display the file inline (i.e. "print ready")
        if (($ENV{'HTTP_USER_AGENT'} =~ /MSIE/) || ($ENV{'HTTP_USER_AGENT'} =~ /Safari/)) {
            # kludge for MSIE not implementing RFC2231 correctly; Safari doesn't work at all (BUG20350)
            # this may change sometime in the future; please see <http://greenbytes.de/tech/tc2231/>
            ($enc_filename) = (split(/'/, $enc_filename))[2];
            $cp->{req}->headers_out->{'Content-Disposition'} = "inline; filename=\"$enc_filename\"";
        }
        else {
            $cp->{req}->headers_out->{'Content-Disposition'} = "inline; filename*=\"$enc_filename\"";
        }
    } else {
        # normal download
        if (($ENV{'HTTP_USER_AGENT'} =~ /MSIE/) || ($ENV{'HTTP_USER_AGENT'} =~ /Safari/)) {
            # kludge for MSIE not implementing RFC2231 correctly; Safari doesn't work at all (BUG20350)
            # this may change sometime in the future; please see <http://greenbytes.de/tech/tc2231/>
            ($enc_filename) = (split(/'/, $enc_filename))[2];
            $cp->{req}->headers_out->{'Content-Disposition'} = "attachment; filename=\"$enc_filename\"";
        }
        else {
            $cp->{req}->headers_out->{'Content-Disposition'} = "attachment; filename*=\"$enc_filename\"";
        }
        $cp->{req}->headers_out->{'Content-Length'} = -s $local_path if (-s _);
    }
    $cp->{req}->content_type($mime_type);
    $cp->debug(10, "download(): sending file... $filename, with mime: $mime_type.");
    $cp->debug(10, "download(): user_agent == $ENV{'HTTP_USER_AGENT'}");
    
    # Send the actual file
    $cp->{req}->sendfile($local_path);

    # assume any vsap download is a temp file that should be deleted
    unlink($local_path) if $vsap; 
  };

  switch_to_nobody();
  
  # Errors while trying to send the file??
  if ($@) {
    $cp->debug(2, "Error while trying to download: $@");
    return 0;
  }
  
  return 1;
}

sub thumbnail {
  my $self = shift;
  my %options = @_;
  my $dom = $options{DOM};
  my $cp = $options{CP};
  
  # make sure user is authenticated
  if (!authenticated($dom, $cp)) {
    return 0;
  }
  
  my $user_id = $dom->findvalue('/cp/request/userid') or
    ($cp->debug(2, "Could not retrieve userid from DOM") && return 0);
  my $login_id = $dom->findvalue('/cp/vsap/vsap[@type="auth"]/username') or
    ($cp->debug(2, "Could not retrieve login id from DOM") && return 0);
  my $image = $dom->findvalue('/cp/form/path') or
    ($cp->debug(2, "Could not find path for thumbdain in DOM") && return 0);
  
  # Get the image path
#  my $image = $dom->findvalue("/cp/request/filename");
#  $image =~ s#^.*CPTHUMBNAILS/(.*)$#$1#;
  
  # Shared thumbnail?
  my $shared = $dom->findvalue("/cp/form/shared") || 0;
  my $sh_user = $dom->findvalue("/cp/form/user") || 0;
  
  my $thumbnailpath = "/usr/home/" . (($login_id eq $user_id) ? $user_id : $user_id . "/users/" . $login_id) . "/" . $image;
  if ($shared) {
    $thumbnailpath = "/usr/home/$user_id/users/$login_id/.shared/$image";
  }
  
  # remove any ../ stuff from the path
  while ($thumbnailpath =~ s!^\.\./|/\.\./|^\.\.$|/\.\.$!!g) {}
  
  my ($type, $src_image);
  switch_to_user($user_id);
  # Do the following in an eval so we can switch back in case anything happens
  my $r = eval {
    my $opened = 1;
    open (IN, $thumbnailpath) or
      ($cp->debug(2, "Error opening $thumbnailpath: $!") && return Apache2::Const::NOT_FOUND());
    
    $cp->debug(10, "Opened $thumbnailpath for thumbnailing");
    
    if ($image =~ /\.jpg$/i || $image =~ /\.jpeg$/i) {
      $type = "jpg";
      $cp->{req}->content_type("image/jpeg");
      $src_image = GD::Image->newFromJpeg(*IN);
      
    } elsif ($image =~ /\.png$/i) {
      $type = "png";
      $cp->{req}->content_type("image/png");
      $src_image = GD::Image->newFromPng(*IN);
      
    } elsif ($image =~ /\.gif$/i) {
      $type = "gif";
      # GD does not do gifs...
      $cp->{req}->content_type("image/gif");
      close IN;
      $cp->{req}->sendfile($thumbnailpath);
      return Apache2::Const::OK();
    } else {
      # ERROR: unsupported file type
      $cp->debug(2, "Error opening thumbnail file [$thumbnailpath]: unsupported file type");
      close IN;
      return Apache2::Const::NOT_FOUND();
    }
    close IN;
    $cp->debug(10, "Read in file for converting");
    return 0;
  };
  switch_to_nobody();
  
  return $r if ($r);
  
  my ($show_X, $show_Y) = ($dom->findvalue("/cp/form/mX"), $dom->findvalue("/cp/form/mY"));
  my ($orig_X, $orig_Y) = $src_image->getBounds();
  my ($div_X, $div_Y) = (0, 0);
  
  if ($show_X) {
    $div_X = $orig_X / $show_X;
  }
  if ($show_Y) {
    $div_Y = $orig_Y / $show_Y;
  }
  
  my $div = ($div_X > $div_Y) ? $div_X : $div_Y;
  
  my $thumb;
  if ($div <= 1) {
    $thumb = $src_image;
  } else {
    $thumb = new GD::Image($orig_X / $div, $orig_Y / $div);
    $thumb->copyResized($src_image, 0, 0, 0, 0, $orig_X / $div, $orig_Y / $div, $orig_X, $orig_Y);
  }
  
  $cp->debug(10, "Outputting thumbnail");
  $cp->{req}->print($thumb->jpeg) if ($type eq "jpg");
  $cp->{req}->print($thumb->png)  if ($type eq "png");
  return Apache2::Const::OK();
}

1;
__END__

=head1 NAME

ControlPanel2::FileTransfer - ControlPanel extension to handle file uploads/downloads

=head1 SYNOPSIS

  use ControlPanel2::FileTransfer;
  ControlPanel2::FileTransfer->download(DOM => $xmldom, CP => $cp);
  ControlPanel2::FileTransfer->upload(DOM => $xmldom, $CP => $cp);

=head1 DESCRIPTION

ControlPanel2::FileTransfer will handle file uploads/downloads within the Signature
ControlPanel environment. The DOM passed in is the pre-built DOM with /cp/request and
/cp/form information filled in. The CP passed in is the ControlPanel object itself (with
access to the Apache::Request object for this request.)

The upload and download subroutines will return 0 upon a failure, and 1 upon success. 

=head2 EXPORT

None by default.


=head1 AUTHOR

Zachary Wily

=head1 SEE ALSO

L<ControlPanel>, L<ControlPanel::MetaProc>.

=cut
