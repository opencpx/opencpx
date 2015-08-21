package VSAP::Server::Modules::vsap::logger;

use 5.008004;
use strict;
use warnings;

use POSIX qw(strftime uname);
use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(log_debug log_error log_message);

##############################################################################

our $VERSION = '0.12';

use constant LOCK_EX => 2;

# where do the logs live?
our $VSAPD_DEBUG_LOG    = '/var/log/vsapd_debug.log';
our $VSAPD_ERROR_LOG    = '/var/log/vsapd_error.log';
our $VSAPD_MESSAGE_LOG  = '/var/log/vsapd.log';

# total amount of old logfiles to keep, besides the current logfile
our $NUM_BACK_LOGS = 9;

# number of old logfiles, amongst the recent ones, not to be compressed
our $NUM_BACK_LOGS_UNZIPPED = 2;

# maximum logfile size before rotate is made
our $MAX_SIZE = 10*1024*1024;  ## 10MB

# minimum logfile age before rotate is made
our $MIN_TIME = 24*60*60;  ## 1d

# strftime format string ('yy/mm/dd hh:mm:ss')
our $TIMESTAMP_FMT = '%Y/%m/%d %H:%M:%S';

# log errors to both error and message logs?
our $DUP_ERR = 1;  ## for the benefit of support

# where is gzip?
our $GZIP_PATH = (-e "/bin/gzip") ? "/bin/gzip" : "/usr/bin/gzip";

##############################################################################

sub _log_write
{
    my $location = shift;
    my $message = shift;

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment

        my $date = strftime($TIMESTAMP_FMT, localtime(time));
        my ($host) = (split(/\./,(uname())[1]))[0];

        unless (-e $location) {
            open(LOG, ">", $location);
            close(LOG);
        }

        open(LOG, ">>", $location) || return;
        flock(LOG, LOCK_EX) || return;
        print LOG "$date $host vsapd[$$]: ";
        print LOG $message;
        close(LOG);

        # is a rotate required?
        my $ctime;
        $ctime = 0;
        open(LOG, "$location");
        while(<LOG>) {
            if (m#^(\d*)/(\d*)/(\d*) (\d*):(\d*):(\d*)#) {
                $ctime = timelocal($6,$5,$4,$3,($2-1),$1);
                last if ($ctime);
            }
        }
        close(LOG);
        return unless($ctime);  ## create time could not be determined
        my ($fsize, $mtime) = (stat($location))[7,9];
        if (($fsize > $MAX_SIZE) && (($mtime - $ctime) > $MIN_TIME)) {
            # rotate old logs
            for (my $index=$NUM_BACK_LOGS; $index>1; $index--) {
                my $target = sprintf "%s.%d", $location, $index;
                my $source = sprintf "%s.%d", $location, ($index-1);
                my $gzipped_target = $target . ".gz";
                my $gzipped_source = $source . ".gz";
                if (-e "$gzipped_source") {
                    rename($gzipped_source, $gzipped_target);
                }
                else {
                    rename($source, $target);
                    # only gzip once (to avoid re-gzipping un-gzipped files)
                    system($GZIP_PATH, $target) if ( $index == ($NUM_BACK_LOGS_UNZIPPED + 1) );
                }
            }
            # rotate current log
            my $target = sprintf "%s.%d", $location, 1;
            rename($location, $target);
            close(LOG) if (open(LOG, ">> $location"));
        }
    }
}

##############################################################################

sub log_debug
{
  my $message = shift;

  $message .= "\n" unless ($message =~ /\n$/);
  _log_write($VSAPD_DEBUG_LOG, $message);
}

##############################################################################

sub log_error
{
  my $message = shift;

  $message .= "\n" unless ($message =~ /\n$/);
  _log_write($VSAPD_ERROR_LOG, $message);
  _log_write($VSAPD_MESSAGE_LOG, $message) if ($DUP_ERR);
}

##############################################################################

sub log_message
{
  my $info = shift;

  $info .= "\n" unless ($info =~ /\n$/);
  _log_write($VSAPD_MESSAGE_LOG, $info);
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::logger - Perl extension for VSAP logging

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::logger;

=head1 DESCRIPTION

vsap::logger contains some subroutines that perform logging functionality.

=head2 log_debug($mesg)

Append message to vsap debug log (/var/log/vsap_debug.log)

=head2 log_error($mesg)

Append message to vsap error log (/var/log/vsap_error.log)

=head2 log_message($mesg)

Append message to vsap message log (/var/log/vsap.log)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

