package VSAP::Server::Modules::vsap::user::messages;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

##############################################################################

our $VERSION = '0.12';

our $MESSAGE_PATH = ".opencpx/messages";

##############################################################################

sub _get_summary
{
    my $user = shift;

    my %info = ();
    my $mdir = (getpwnam($user))[7] . "/" . $MESSAGE_PATH;
    if (opendir(MDIR, $mdir)) {
        my @files = grep !/^\.\.?$/, readdir(MDIR);   ## skip '.' and '..'
        foreach my $filename (@files) {
            my $mpath = $mdir . "/" . $filename;
            my $mtime = (stat($mpath))[9];
            my $curtime = time();
            if ( ($curtime - $mtime) > (24 * 60 * 60) ) {
                ## 24 hrs w/o an update?  time for a harvest.
                unlink($mpath);
                next;
            }
            my $pid = $filename;
            my $prune = 0;
            if (open(MFP, "$mpath")) {
                $info{$pid}->{'mtime'} = $mtime;
                while (<MFP>) {
                    chomp;
                    if (/(.*)\|\|\|(.*)/) {
                        $info{$pid}->{$1} = $2;
                        $prune = 1 if (($1 eq "status") && ($2 eq "complete"));
                    }
                }
                close(MFP);
            }
            unless (kill(0, $pid)) {
                # the process is no longer running
                $info{$pid}->{'status'} = 'complete';
                $prune = 1;
            }
            if ($prune) {
                unlink($mpath);
                if (kill(0, $pid)) {
                    # child process is still in the process table... send signal
                  REWT: {
                        local $> = $) = 0;  ## regain privileges for a moment
                        unless (kill(17, $info{$pid}->{'parent_pid'})) {
                            # SIGCHLD failed, try SIGINT
                            unless (kill(2, $pid)) {
                                # SIGKILL!
                                kill(9, $pid);
                            }
                        }
                    }
                }
            }
        }
        closedir(MDIR);
    }
    return(%info);
}

# ----------------------------------------------------------------------------

sub _get_tz
{
    my $user = shift;

    my $user_tz = "";
    my $system_tz = VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
    my $default_tz = "GMT";

    my $ppath = (getpwnam($user))[7] . "/.opencpx" . $VSAP::Server::Modules::vsap::user::prefs::PREFS;
    if (open(PFH, $ppath)) {
        local $/;
        my $prefs = <PFH>;
        close(PFH);
        if ($prefs =~ m#<time_zone>(.*?)</time_zone>#is) {
            $user_tz = $1;
        }
    }

    my $timezone = $user_tz || $system_tz || $default_tz;
    return($timezone);
}

# ----------------------------------------------------------------------------

sub _job_complete
{
    my $user = shift;
    my $pid = shift;

    my ($euid,$egid) = (getpwnam($user))[2,3];

  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily
        local $) = $egid;
        local $> = $euid;
        my $mpath = (getpwnam($user))[7] . "/" . $MESSAGE_PATH . "/" . $pid;
        open(MFP, ">>$mpath") || return;
        print MFP "status|||complete\n";
        close(MFP);
    }
}

# ----------------------------------------------------------------------------

sub _job_load
{
    my $user = shift;
    my $pid = shift;

    my %info = ();
    my $mpath = (getpwnam($user))[7] . "/" . $MESSAGE_PATH . "/" . $pid;
    if (open(MFP, "$mpath")) {
        while (<MFP>) {
            chomp;
            if (/(.*)\|\|\|(.*)/) {
                $info{$1} = $2;
            }
        }
        close(MFP);
    }
    return(%info);
}

# ----------------------------------------------------------------------------

sub _queue_add
{
    my $user = shift;
    my $pid = shift;
    my $parent_pid = shift;
    my $task = shift;
    my %data = @_;

    my ($euid,$egid) = (getpwnam($user))[2,3];

  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily
        local $) = $egid;
        local $> = $euid;
        my $mdir = (getpwnam($user))[7] . "/" . $MESSAGE_PATH;
        mkdir($mdir, 0755) unless (-e "$mdir");
        my $mpath = $mdir . "/" . $pid;
        open(MFP, ">$mpath") || return;
        print MFP "epoch|||" . time . "\n";
        print MFP "parent_pid|||$parent_pid\n";
        print MFP "task|||$task\n";
        foreach my $key (sort(keys(%data))) {
            print MFP "$key|||$data{$key}\n";
        }
        close(MFP);
    }
}

# ----------------------------------------------------------------------------

sub _queue_remove
{
    my $user = shift;
    my $pid = shift;

    my ($euid,$egid) = (getpwnam($user))[2,3];

  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily
        local $) = $egid;
        local $> = $euid;
        my $mpath = (getpwnam($user))[7] . "/" . $MESSAGE_PATH . "/" . $pid;
        unlink($mpath);
    }
}

# ----------------------------------------------------------------------------

sub _queue_update
{
    my $user = shift;
    my $pid = shift;
    my %data = @_;

    my ($euid,$egid) = (getpwnam($user))[2,3];

  EFFECTIVE: {
        local $> = $) = 0;  ## must regain root privs temporarily
        local $) = $egid;
        local $> = $euid;
        my $mpath = (getpwnam($user))[7] . "/" . $MESSAGE_PATH . "/" . $pid;
        return unless (-e "$mpath");
        my %info = VSAP::Server::Modules::vsap::user::messages::_job_load($user, $pid);
        foreach my $key (keys(%data)) {
            $info{$key} = $data{$key};
        }
        open(MFP, ">$mpath") || return;
        foreach my $key (sort(keys(%info))) {
            print MFP "$key|||$data{$key}\n";
        }
        close(MFP);
    }
}

##############################################################################
#
# VSAP::Server::Modules::vsap::user::messages::list
#
##############################################################################

package VSAP::Server::Modules::vsap::user::messages::list;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $user = $xmlobj->child('user') ? $xmlobj->child('user')->value :
                                        $vsap->{username};

    my %info = VSAP::Server::Modules::vsap::user::messages::_get_summary($user);

    my $timezone = VSAP::Server::Modules::vsap::user::messages::_get_tz($user);

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'user:messages:list');
    $root_node->appendTextChild('user', $user);

    my @pids = keys(%info);
    $root_node->appendTextChild('numjobs', ($#pids + 1));
    if ($#pids >= 0) {
        foreach my $pid (sort {$info{$a}->{'epoch'} <=> $info{$b}->{'epoch'}} (@pids)) {
            my $job_node = $dom->createElement('job');
            $job_node->appendTextChild( 'pid', $pid );
            # append details to job node
            foreach my $key (keys(%{$info{$pid}})) {
                $job_node->appendTextChild( $key, $info{$pid}->{$key} );
                # add time strings (if applicable)
                if ( ($key eq "epoch") || ($key eq "mtime") ) {
                    my $mtime = $info{$pid}->{$key};
                    my $d = new VSAP::Server::G11N::Date( epoch => $mtime, tz => $timezone );
                    if ($d) {
                        my $name = $key . "_date";
                        my $date_node = $job_node->appendChild($dom->createElement($name));
                        $date_node->appendTextChild( year   => $d->local->year    );
                        $date_node->appendTextChild( month  => $d->local->month   );
                        $date_node->appendTextChild( day    => $d->local->day     );
                        $date_node->appendTextChild( hour   => $d->local->hour    );
                        $date_node->appendTextChild( hour12 => $d->local->hour_12 );
                        $date_node->appendTextChild( minute => $d->local->minute  );
                        $date_node->appendTextChild( second => $d->local->second  );
                        $date_node->appendTextChild( o_year   => $d->original->year    );
                        $date_node->appendTextChild( o_month  => $d->original->month   );
                        $date_node->appendTextChild( o_day    => $d->original->day     );
                        $date_node->appendTextChild( o_hour   => $d->original->hour    );
                        $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
                        $date_node->appendTextChild( o_minute => $d->original->minute  );
                        $date_node->appendTextChild( o_second => $d->original->second  );
                        $date_node->appendTextChild( o_offset => $d->original->offset  );
                    }
                }
            }
            # append job to root node
            $root_node->appendChild($job_node);
        }
    }

    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::user::messages - VSAP extension that handles system message to user

=head1 SYNOPSIS
  use VSAP::Server::Modules::vsap::user::messages;

=head1 DESCRIPTION

The VSAP procmail module is used to update/summarize the queued messages 
about jobs that the system is working on for the user in the background.
These system jobs usually take longer than the apache timeout will allow;
e.g. removing lots of users at one time, or compressing/uncompressing 
large files.

=head2 mail:messages

Only one method is included in this module:

    <vsap type="user:messages">
        <user>user name</user>
    </vsap>

If a user name is not supplied, then the current user performing the 
request is presumed.  Domain Administrators are allowed only to
invoke an init request on the behalf of end users in their respective
group.  System Administrators may perform an init request on any user. 

If authorized, a list of jobs that the user is currently running in the
background will be returned.  Included with each job is the the job type
(a static string - see below), the job epoch (the epoch date when the 
job was started), and a set of data:value string that are applicable to 
the job based on the job type.

    <vsap type="user:messages">
        <user>user name</user>
        <job>
            <pid>PID</pid>
            <type>job type</epoch>
            <epoch>epoch at which job was started</epoch>
            <type>job type</type>
            <data>data</data>
            <data>data</data>
            <data>data</data>
            <data>data</data>
        </job>
        <job>
            <pid>PID</pid>
            <type>job type</epoch>
            <epoch>epoch at which job was started</epoch>
            <type>job type</type>
            <data>data</data>
            <data>data</data>
            <data>data</data>
            <data>data</data>
        </job>
    </vsap>

Current valid "job types" include the following:

	REMOVE_USER	User has requested to remove <total> users.  As the
			job is processed, <completed> will be updated.


=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
