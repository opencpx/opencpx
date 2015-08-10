package VSAP::Server::Modules::vsap::backup;

use 5.008004;
use strict;
use warnings;
use Digest::MD5;

use VSAP::Server::Modules::vsap::logger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(backup_system_file restore_system_file validate versions);

our $VERSION = '0.12';

our $BACKUP_DIR = '/var/backups';
our $GZIP_EXEC = (-e "/bin/gzip") ? "/bin/gzip" : "/usr/bin/gzip";

##############################################################################

sub _checksum
{
  my($fullpath) = shift;

  open(FP, $fullpath) or return({ sprintf "%d", (rand(1e6) + 0.5) });
  binmode(FP);
  my $cksum = Digest::MD5->new->addfile(*FP)->hexdigest;
  close(FP);

  return($cksum);
}

# ----------------------------------------------------------------------------

sub _compress
{
    my($fullpath) = shift;

    return if ($fullpath =~ /\.gz$/);

    my (@command);
    push(@command, $GZIP_EXEC);
    push(@command, '-9');
    push(@command, $fullpath);
    system(@command)
      and do {
          my $exit = ($? >> 8);
          if ($exit) {
              my $errmsg = "$GZIP_EXEC -9 '$fullpath' failed (exitcode $exit)";
              VSAP::Server::Modules::vsap::logger::log_error($errmsg);
              warn($errmsg);
          }
      };
}

# ----------------------------------------------------------------------------

sub _uncompress
{
    my($fullpath) = shift;

    return if ($fullpath !~ /\.gz$/);

    my (@command);
    push(@command, $GZIP_EXEC);
    push(@command, '-d');
    push(@command, $fullpath);
    system(@command)
      and do {
          my $exit = ($? >> 8);
          if ($exit) {
              my $errmsg = "gzip -d '$fullpath' failed (exitcode $exit)";
              VSAP::Server::Modules::vsap::logger::log_error($errmsg);
              warn($errmsg);
          }
      };
}

##############################################################################

sub backup_system_file
{
    my($fullpath) = shift;

    # get filename from full path
    $fullpath =~ /([^\/]+$)/;
    my $filename = $1;
    return unless ($filename);

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment

        # is this a normal file?
        return unless (-f "$fullpath");

        # only backup a file if it has non-zero length
        my ($fsize, $mtime) = (stat($fullpath))[7,9];
        return unless($fsize > 0);

        # only backup a file if it different from last backup
        my $backup = sprintf "$BACKUP_DIR/%s.0.gz", $filename;
        unless (-e $backup) {
            $backup = sprintf "$BACKUP_DIR/%s.0", $filename;
        }
        if (-e $backup) {
            my $fchksum = _checksum($fullpath);
            my $bchksum = _checksum($backup);
            return if ($fchksum eq $bchksum);
        }

        # create backup directory (if necessary)
        unless (-d $BACKUP_DIR) {
            mkdir($BACKUP_DIR, 0750) || return;
        }
        chmod(0750, $BACKUP_DIR);
        chown(0, 0, $BACKUP_DIR);

        # current epoch
        my $curtime = time();

        # prune any old backup files; but keep at least the last 10 backups
        # (account for case where user may have uncompressed some backups)
        my $index = 0;
        $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
        my $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
        while ((-e "$backup") || (-e "$gzback")) {
            my $target = (-e "$backup") ? $backup : $gzback;
            my ($lastmod) = (stat($target))[9];
            if (($curtime - $lastmod) > (90 * 24 * 60 * 60)) {
                # remove if 90 days old or older
                unlink($target) if ($index > 9);
            }
            elsif (($curtime - $lastmod) > (7 * 24 * 60 * 60)) {
                # compress if between 7 days and 90 days old
                _compress($target);
            }
            elsif ($index >= 99) {
                # only keep a maximum of 100 backups
                unlink($target);
            }
            $index++;
            $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
            $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
        }

        # look past possible gap in indexing to remove old backups (HIC-476)
        # note: the selection of the ceiling value of 200 is arbitrary
        while ($index < 200) {
            $index++;
            $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
            $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
            unlink($backup) if (-e "$backup");
            unlink($gzback) if (-e "$gzback");
        }

        # rotate
        while ($index > 0) {
            my $src = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, ($index-1);
            $backup = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
            unless (-e "$src") {
                # uncompressed?
                $src = sprintf "$BACKUP_DIR/%s.%d", $filename, ($index-1);
                $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
            }
            $index--;
            next unless (-e "$src");  # pruned (from above)
            rename($src, $backup);
        }

        # backup
        $backup = sprintf "$BACKUP_DIR/%s.0", $filename;
        my @command = ();
        push(@command, 'cp');
        push(@command, '-p');
        push(@command, '--');
        push(@command, $fullpath);
        push(@command, $backup);
        system(@command)
          and do {
              my $exit = ($? >> 8);
              if ($exit) {
                  my $errmsg = "backup '$fullpath' to '$backup' failed (exitcode $exit)";
                  VSAP::Server::Modules::vsap::logger::log_error($errmsg);
                  warn($errmsg);
                  return($exit);
              }
          };
    }
    return(0);
}

##############################################################################

sub restore_system_file
{
    my($fullpath) = shift;
    my($version) = shift || '0';

    # get filename from full path
    $fullpath =~ /([^\/]+$)/;
    my $filename = $1;
    return unless ($filename);

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $version;
        my $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $version;
        if ((-e "$backup") || (-e "$gzback")) {
            _uncompress($gzback) if (-e "$gzback");
            my @command = ();
            push(@command, 'cp');
            push(@command, '-p');  # preserve perms/ownership/etc
            push(@command, '--');
            push(@command, $backup);
            push(@command, $fullpath);
            my $command = join(' ', @command);
            system(@command)
              and do {
                  my $exit = ($? >> 8);
                  if ($exit) {
                      my $errmsg = "restore '$backup' to '$fullpath' failed (command=$command, exitcode=$exit)";
                      VSAP::Server::Modules::vsap::logger::log_error($errmsg);
                      warn($errmsg);
                      return($exit);
                  }
              };
            # touch the file (HIC-746)
            my $mtime = time();
            utime($mtime, $mtime, $fullpath);
        }
    }
    return(0);
}

##############################################################################

sub validate
{
    my($fullpath) = shift;
    my($version) = shift;
    my($ctf) = shift;  # create temp file

    # get filename from full path
    $fullpath =~ /([^\/]+$)/;
    my $filename = $1;
    return unless ($filename);

    my $tmpfile = "";

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $version;
        my $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $version;
        if ((-e "$backup") || (-e "$gzback")) {
            return(1) unless ($ctf);
            _uncompress($gzback) if (-e "$gzback");
            $tmpfile = "/tmp/" . $filename . "-" . time() . "." . $$;
            my @command = ();
            push(@command, 'cp');
            push(@command, '-p');
            push(@command, '--');
            push(@command, $backup);
            push(@command, $tmpfile);
            system(@command);
        }
    }

    return($tmpfile);
}

##############################################################################

sub versions
{
    my($fullpath) = shift;

    # get filename from full path
    $fullpath =~ /([^\/]+$)/;
    my $filename = $1;
    return unless ($filename);

    my %versions = ();

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        return unless ( -f $fullpath );
        my $index = 0;
        my $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
        my $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
        while ((-e "$backup") || (-e "$gzback")) {
            my $target = (-e "$backup") ? $backup : $gzback;
            $versions{$index} = $target;
            $index++;
            $backup = sprintf "$BACKUP_DIR/%s.%d", $filename, $index;
            $gzback = sprintf "$BACKUP_DIR/%s.%d.gz", $filename, $index;
        }
    }

    return(%versions);
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::backup - VSAP string encoding utilities

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::backup;

=head1 DESCRIPTION

vsap::backup contains some subroutines that perform backup tasks; tasks
that are required by more than one vsap module.

=head2 backup_system_file($fullpath)

Backup system file specified by $fullpath.  At least the 10 most recent
backup copies of the file are kept (regardless of age).  Backup copies
beyond 10 are pruned if they become 60 days old.  Backup copies are
compressed if older than 7 days.

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

