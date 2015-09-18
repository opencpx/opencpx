package VSAP::Server::Modules::vsap::mail::helper;

use 5.008004;
use strict;
use warnings;
use Quota;
use POSIX;

use VSAP::Server::Modules::vsap::diskspace qw(user_over_quota);
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::monitor;

##############################################################################

our $VERSION = '0.12';

# shared error codes and messages for helper module
our %_ERR_CODE = (
                   AUTH_FAILED    => 100,
                   QUOTA_EXCEEDED => 200,
                   OPEN_FAILED    => 510,
                   WRITE_FAILED   => 511,
                   MKDIR_FAILED   => 512,
                   RENAME_FAILED  => 513,
                 );

our %_ERR_MESG = (
                   AUTH_FAILED    => 'not authorized to modify user settings',
                   QUOTA_EXCEEDED => 'quota exceeded',
                   OPEN_FAILED    => 'open() failed',
                   WRITE_FAILED   => 'write() failed',
                   MKDIR_FAILED   => 'mkdir() failed',
                   RENAME_FAILED  => 'rename() failed',
                 );

our $_MH_PROCMAILRC = ".procmailrc";
our $_MH_DOVECOTSIEVE = ".dovecot.sieve";

##############################################################################
#
# skel
#
##############################################################################

our $_SKEL_PROCMAILRC = <<'_PROCMAILRC_';
## NOTICE: Begin Control Panel Section (do not remove these comments)
##
## This chunk of recipes is maintained by the Control Panel; please leave
## intact.  These are not the recipes you are looking for... move along.
##

CPXDIR=$HOME/.cpx/procmail

## virus scanning
#INCLUDERC=$CPXDIR/clamav.rc

## spam filtering
#INCLUDERC=$CPXDIR/spamassassin.rc

## autoreply
#INCLUDERC=$CPXDIR/autoreply.rc

## mail forward
#INCLUDERC=$CPXDIR/mailforward.rc

##
## NOTICE: End Control Panel Section (do not remove these comments)

_PROCMAILRC_

our $_SKEL_DOVECOTSIEVE = <<'_DOVECOTSIEVE_';
## NOTICE: Begin Control Panel Section (do not remove these comments)
##
## This chunk of recipes is maintained by the Control Panel; please leave
## intact.  These are not the recipes you are looking for... move along.
##

require ["include"];
#include :personal "cpx-autoreply";
#include :personal "cpx-mailforward";

##
## NOTICE: End Control Panel Section (do not remove these comments)

_DOVECOTSIEVE_

##############################################################################
#
# function library
#
##############################################################################

sub _init
{
    my $user = shift;

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();
    if ($filter eq "sieve") {
        ## sieve handles autoreply and mail forwarding
        $_SKEL_PROCMAILRC =~ s/^(.*)## autoreply\n.*(##\n##.*)$/$1$2/s;
    }

    my %files = ( $_MH_PROCMAILRC => $_SKEL_PROCMAILRC,
                  $_MH_DOVECOTSIEVE => $_SKEL_DOVECOTSIEVE );

    my ($uid,$gid,$home) = (getpwnam($user))[2,3,7];

    foreach my $file (keys(%files)) {
        my $skel = $files{$file};
        my $path = "$home/$file";
        # check for proper ownership and perms (BUG29057)
      REWT: {
            local $> = $) = 0;
            chown($uid, $gid, $path);
            chmod(0600, $path);
        }

        my $existing = "";
      EFFECTIVE: {
            local $> = $) = 0;
            local $) = getgrnam($user);
            local $> = getpwnam($user);
            if (-e "$path") {
                # path exists; scan for CPX block
                unless (open(RCFP, "$path")) {
                    return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $path : $!");
                }
                my $found = 0;
                while (<RCFP>) {
                    if (/^## NOTICE: Begin Control Panel Section/) {
                        $found = 1;
                        last;
                    }
                    $existing .= $_;
                }
                close(RCFP);
                # drop out if found
                return('SUCCESS', '') if ($found);
            }
        }

        # check user's quota... be sure there is enough room for writing
        unless(VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
            # not good
            return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
        }

        # write out a Control Panel recipe block
      EFFECTIVE: {
            local $> = $) = 0;
            local $) = getgrnam($user);
            local $> = getpwnam($user);
            # write new file
            my $newpath = "$path.$$";
            unless (open(RCFP, ">$newpath")) {
                # open failed... drat!
                return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
            }
            unless (print RCFP $skel) {
                # write failed... drat!
                close(RCFP);
                unlink($newpath);
                return('WRITE_FAILED', "$_ERR_MESG{'WRITE_FAILED'} ... $newpath : $!");
            }
            if ($existing) {
                unless (print RCFP $existing) {
                    close(RCFP);
                    unlink($newpath);
                    return('WRITE_FAILED', "$_ERR_MESG{'WRITE_FAILED'} ... $newpath : $!");
                }
            }
            close(RCFP);
            # out with old; in with the new
            unless (rename($newpath, $path)) {
                # rename failed... drat!
                unlink($newpath);
                return('RENAME_FAILED', "$_ERR_MESG{'RENAME_FAILED'} ... $newpath -> $path: $!");
            }
        }
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _is_installed_dovecot
{
    return VSAP::Server::Modules::vsap::sys::monitor::_is_installed_dovecot();
}

#-----------------------------------------------------------------------------

sub _is_using_procmail
{
    return ! VSAP::Server::Modules::vsap::mail::helper::_is_using_sieve();
}

#-----------------------------------------------------------------------------

sub _is_using_sieve
{
    return _is_installed_dovecot && -e "/etc/dovecot/conf.d/90-sieve.conf";
}

#-----------------------------------------------------------------------------

sub _which_filter
{
    my $sieve = VSAP::Server::Modules::vsap::mail::helper::_is_using_sieve;
    return( ($sieve ? "sieve" : "dovecot") );
}

##############################################################################
#
# mail::helper::init
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::helper::init;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $user = $xmlobj->child('user') ? 
               $xmlobj->child('user')->value : $vsap->{username};

    unless ($vsap->{server_admin}) {
        my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
        my @ulist = keys %{$co->users(admin => $vsap->{username})};
        # add self to list
        push(@ulist, $vsap->{username});
        # check authorization
        my $authorized = 0;
        foreach my $validuser (@ulist) {
            if ($user eq $validuser) {
                $authorized = 1;
                last;
            }
        }
        unless ($authorized) {
            # fail
            $vsap->error($_ERR_CODE{'AUTH_FAILED'} => $_ERR_MESG{'AUTH_FAILED'});
            return;
        }
    }

    # make sure CPX mail filtering block is found in helper file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::helper::_init($user);
    if (defined($_ERR_CODE{$code})) {
        $vsap->error($_ERR_CODE{$code} => $mesg);
        return;
    }

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:helper:init');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail::helper - VSAP extension for mail helper

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::helper;

=head1 DESCRIPTION

The VSAP mail helper module allows users and administrators to perform
various CPX related tasks in the procmail/sieve recipe file.

=head2 mail:helper:init

The init method audits a user's helper recipe file for the existence of
the CPX recipes.  If the recipes are not found, then they will be added.

The following template represents the generic form of an init request:

    <vsap type="mail:helper:init">
        <user>username</user>
    </vsap>

If a user name is not supplied, then the current user performing the
request is presumed.  Domain Administrators are allowed only to
invoke an init request on the behalf of end users in their respective
group.  System Administrators may perform an init request on any user.

If the CPX was either previously found or if it was successfully added
to the user's helper recipe file, then a success status is returned.
For example:

    <vsap type="mail:helper:init">
        <user>biff</user>
        <status>ok</status>
    </vsap>



If the request was not successful, then a descriptive error indicating
the cause of the failure is returned.


=head1 SEE ALSO

L<procmail(1)>, L<procmailrc(5)>, L<sieve-connect(1)>, L<sievec(1)>

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
