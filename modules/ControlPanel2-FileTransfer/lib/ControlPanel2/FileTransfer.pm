package ControlPanel2::FileTransfer;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.12';

use Apache2::Const qw(OK HTTP_NOT_FOUND);
use Apache2::Upload;
use Cwd qw(abs_path);

use ControlPanel::MetaProc;

my $AUTH_FILENAME = "auth.xsl";
my $TMP_DIRECTORY = ".opencpx_tmp";

##############################################################################

sub authenticated
{
    my $dom = shift;
    my $cp = shift;

    $cp->debug(10, "Calling MetaProc for an upload/download authentication with dom:\n" . $dom->toString);
    my $mp = ControlPanel::MetaProc->new(DOM => $dom, CP => $cp);
    my $document_file = $mp->process($AUTH_FILENAME);
    $cp && $cp->debug(10,"Meta data processed, returned '$document_file'");
    if ($document_file ne $AUTH_FILENAME) {
        # User did not authenticate successfully
        return 0;
    }

    return 1;
}

##############################################################################

sub default_response_format
{
    my $mime_type = shift;
    my $extension = shift;

    my @pr_mime_types = ("text/plain", "text/htm", "text/html",
                         "image/gif", "image/png", "image/jpg",
                         "image/jpe", "image/jpeg", "image/pjpeg");

    my @pr_extensions = ("txt", "htm", "html", "gif", "png", "jpg",
                         "jpe", "jpeg", "pjpeg");

    $mime_type =~ tr/A-Z/a-z/;
    $extension =~ tr/A-Z/a-z/;

    my $pr_mt_expr = '^' . $mime_type . '$';
    my $pr_ext_expr = '^' . $extension . '$';

    my $default = "download";  # possible values: "download" or "print"
    if ($mime_type && (grep(/$pr_mt_expr/, @pr_mime_types))) {
        $default = "print";
    }
    elsif ($extension && (grep(/$pr_ext_expr/, @pr_extensions))) {
        $default = "print";
    }
    return($default);
}

##############################################################################

sub download
{
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

    # Determine the nature of their download (owner, share, or vsap)
    my $path = $cp->{req}->path_info();

    # get the local file (and path) information including mime type (if defined)
    # also set the download request format ("print" or "download") if applicable
    my ($filename, $url_filename, $enc_filename, $mime_type, $local_path, $response_format);
    $filename = $url_filename = $enc_filename = $mime_type = $local_path = "";
    if ($dom->findvalue('/cp/form/path')) {
        $url_filename = $dom->findvalue('/cp/form/path');
        ($filename) = $path =~ m{/([^/]+)$};
        $enc_filename = "utf-8''$filename";
        $local_path = (getpwnam($login_id))[7] . "/$url_filename";
        $response_format = "download";
    }
    else {
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
        $response_format = $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/format') ||
                           $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/format') || "download";
        $local_path = $dom->findvalue('/cp/vsap/vsap[@type="webmail:messages:attachment"]/attachment/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="webmail:addressbook:export"]/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="files:download"]/path') ||
                      $dom->findvalue('/cp/vsap/vsap[@type="sys:logs:download"]/path');
    }

    $cp->debug(5, "download(): path='$path', filename='$filename', mime_type='$mime_type'");
    $cp->debug(5, "download(): url_filename='$url_filename', enc_filename='$enc_filename'");
    $cp->debug(5, "download(): response_format='$response_format'");
    if ($local_path) {
        $cp->debug(5, "download(): local_path='$local_path'");
    }
    else {
        $cp->debug(2, "download(): could not get attachment local path from vsap");
        return 0;
    }

    eval {
        $local_path = abs_path($local_path);
        # does file exist?
        if (!-e $local_path) {
            $cp && $cp->debug(1, "download(): file not found... $local_path");
            die "File not found: $local_path";
        }
        else {
            $cp && $cp->debug(10, "download(): found local_path... $local_path");
        }

        # figure out the extension
        my $extension = "";
        if ( ($filename =~ /.*\.(.*)$/) || ($enc_filename =~ /.*\.(.*)$/) ) {
            $extension = $1;
        }
        if ($extension) {
            $cp->debug(10, "download(): found extension from filename -> $extension");
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
        }
        else {
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

        # assume any download is a temp file that should be deleted
        unlink($local_path);
    };

    # trap on error
    if ($@) {
        $cp->debug(2, "Error while trying to download: $@");
        return 0;
    }

    # it worked!
    return 1;
}

##############################################################################

sub upload
{
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

    my $upload_dir = (getpwnam($login_id))[7] . '/' . $TMP_DIRECTORY;
    if (!-e $upload_dir) {
        $cp && $cp->debug(10, "creating upload_dir: $upload_dir");
        mkdir($upload_dir) or
          ($cp && $cp->debug(2, "ERROR creating tmp directory ($upload_dir): $!"));
    }

    ## get a target filename on the local filesystem
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

    # receive the file and write it to disk
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

    use bytes;
    my $local_file = $upload_dir . "/" . $local_filename;
    $cp && $cp->debug(10, "Uploading to $local_file");
    open (OUT, ">$local_file") or
        ($cp && $cp->debug(2, "ERROR opening file to write ($local_file): $!"));
    $! = '';  # clear error variable... to check over quota
    while (<$fh>) {
        print OUT;
    }
    close OUT;
    no bytes;
    close ($fh);

    if ($!) {
        $cp && $cp->debug(2, "ERROR uploading file: $!");
        if ($! =~ /quota exceeded/) {
            # if quota exceeded, set /cp/request/upload_over_quota to true
            my ($form_node) = $dom->findnodes("/cp/request");
            $form_node->appendTextChild("upload_over_quota", "true");
        }
    }

    # Add the name of the locally stored file in /cp/request/upload_file
    my ($form_node) = $dom->findnodes("/cp/request");
    $form_node->appendTextChild("uploaded_file", $local_filename);
}

##############################################################################

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
