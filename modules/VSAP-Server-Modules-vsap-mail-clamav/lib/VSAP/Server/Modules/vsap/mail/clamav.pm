package VSAP::Server::Modules::vsap::mail::clamav;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::diskspace qw(user_over_quota);
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail::helper;

require VSAP::Server::Modules::vsap::config;

##############################################################################

our $VERSION = '0.12';

# error codes specific to this module
our %_ERR_CODE = %VSAP::Server::Modules::vsap::mail::helper::_ERR_CODE;
$_ERR_CODE{'CLAMAV_NOT_FOUND'} = 550;

# error messages specific to this module
our %_ERR_MESG = %VSAP::Server::Modules::vsap::mail::helper::_ERR_MESG;
$_ERR_MESG{'CLAMAV_NOT_FOUND'} = 'clamav not installed';

##############################################################################
#
# some default settings for clamav
#
##############################################################################

our %_DEFAULTS = ( virusfolder => '$HOME/Mail/Quarantine' );

if ( VSAP::Server::Modules::vsap::mail::helper::_is_installed_dovecot() ) {
    $_DEFAULTS{'virusfolder'} = '$HOME/Maildir/.Quarantine/';
}

##############################################################################
#
# skel
#
##############################################################################

our $SKEL_CLAMAV_RC = q%
## BEGIN ClamAV Scanning Block: edits inside this block may be
## reverted at upgrade. Edit at your own risk!

TMPLOGFILE=$LOGFILE
TMPLOGABSTRACT=$LOGABSTRACT
TMPVERBOSE=$VERBOSE

LOGFILE=/dev/null
LOGABSTRACT=off
VERBOSE=off

## scan
:0
CLAMAV=|__CLAMPATH__ --disable-summary --stdout -

## tag
:0 fhw
* CLAMAV ?? .*:\/.* FOUND
| formail -a"X-ClamAV: ${MATCH}"

:0E fhw
| formail -a"X-ClamAV: clean"

## deliver
:0:
* ^X-ClamAV: \/.*
* ! MATCH ?? ^^clean^^
__VIRUSFOLDER__

LOGFILE=$TMPLOGFILE
LOGABSTRACT=$TMPLOGABSTRACT
VERBOSE=$TMPVERBOSE

## END ClamAV Scanning Block
%;

##############################################################################
#
# non-vsap (nv) functions
#
##############################################################################

sub nv_status
{
    my $user = shift;

    $user = getpwuid($>) unless($user);
    my $status = _get_status($user);

    return $status;
}

sub nv_able
{
    my $user = shift;
    my $status = shift;

    $user = getpwuid($>) unless($user);

    my ($code, $mesg) = _init($user);
    if (defined($_ERR_CODE{$code})) {
        return (wantarray ? ($code, $mesg) : undef);
    }

    ($code, $mesg) = _save_status($user, $status);
    if (defined($_ERR_CODE{$code})) {
        return (wantarray ? ($code, $mesg) : undef);
    }

    return 1;
}

sub nv_disable
{
    my $user = shift;

    $user = getpwuid($>) unless($user);

    return(nv_able($user, 'off'));
}

sub nv_enable
{
    my $user = shift;

    $user = getpwuid($>) unless($user);

    return(nv_able($user, 'on'));
}

##############################################################################
#
# supporting functions
#
##############################################################################

sub _daemon_running
{
    my $enabled = 0;
    my $status = "";

    my $os = $^O;
    my $daemon_service = "/etc/rc.d/init.d/clamd";
    unless ($os eq 'linux') {
        # FreeBSD?
        $daemon_service = (-e "/usr/local/etc/rc.d/clamav-clamd.sh") ?
                              "/usr/local/etc/rc.d/clamav-clamd.sh" :
                              "/usr/local/etc/rc.d/clamav-clamd";
    }

 REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $status = `$daemon_service status`;
    }
    $enabled = ($status =~ /is running/);

    return($enabled);
}

#-----------------------------------------------------------------------------

sub _get_path
{
    my $installbin = "/usr/local/bin";
    #my $exec = VSAP::Server::Modules::vsap::mail::clamav::_daemon_running() ? "clamdscan" : "clamscan";
    my $exec = "clamdscan";  ## BUG26675: always use clamdscan per Gabe
    my $path = $installbin . "/" . $exec;
    return($path);
}

#-----------------------------------------------------------------------------

sub _get_settings
{
    my $user = shift;

    my %settings = ();
    %settings = %_DEFAULTS;

    my $home = (getpwnam($user))[7];
    my $path = "$home/.opencpx/procmail/clamav.rc";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(RCFP, "$path")) {
            while (<RCFP>) {
                s/\s+$//;
                if (/MATCH/ && /\^\^clean\^\^/) {
                    $settings{'virusfolder'} = <RCFP>;
                    $settings{'virusfolder'} =~ s/^\s+//;
                    $settings{'virusfolder'} =~ s/\s+$//;
                    last;
                }
            }
            close(RCFP);
        }
    }
    return(%settings);
}

#-----------------------------------------------------------------------------

sub _get_status
{
    my $user = shift;

    my $status = "off";  # default

    # load status ... 'on' or 'off'
    my $home = (getpwnam($user))[7];
    my $path = "$home/.procmailrc";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(RCFP, "$path")) {
            # scan for 'INCLUDERC=$CPXDIR/clamav.rc'
            while (<RCFP>) {
                s/\s+$//;
                if (m!^(#)?INCLUDERC=\$CPXDIR/clamav.rc!) {
                    $status = ($1 ? 'off' : 'on');
                    last;
                }
            }
            close(RCFP);
        }
    }
    return($status);
}

#-----------------------------------------------------------------------------

sub _init
{
    my $user = shift;

    # check to see if some useful directories exist
    my $home = (getpwnam($user))[7];
    my @paths = ("$home/.opencpx", "$home/.opencpx/procmail");
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily
        foreach my $path (@paths) {
            unless (-e "$path") {
                unless (mkdir("$path", 0700)) {
                    return('MAIL_MKDIR_FAILED', "$_ERR_MESG{'MAIL_MKDIR_FAILED'} ... $path : $!");
                }
            }
            my($uid, $gid) = (getpwnam($user))[2,3];
            chown($uid, $gid, $path);
        }
    }

    # make sure CPX recipe block is found in helper file (.procmailrc)
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::helper::_init($user);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # init files specific to clamav if not found
    unless (-e "$home/.opencpx/procmail/clamav.rc") {
        ($code, $mesg) = VSAP::Server::Modules::vsap::mail::clamav::_write_includerc($user);
        return($code, $mesg) if (defined($_ERR_CODE{$code}));
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _is_installed_milter
{
    my $os = $^O;

    my $egrep = '/bin/egrep';          ## default on linux
    my $mc = '/etc/mail/sendmail.mc';  ## default on linux
    if( $os eq 'freebsd' ) {
        $egrep = '/usr/bin/egrep';
        my $host = `/usr/local/sbin/sinfo -h`;
        chomp($host);
        $mc = "/etc/mail/$host.mc";
    }

    ## lifted from check_for_milter() in clamav.install
    return 1 if( !system( "$egrep 'confINPUT_MAIL_FILTERS' $mc | $egrep -qs clamav" ) );
    return 0;
}

#-----------------------------------------------------------------------------

sub _save_settings
{
    my $user = shift;
    my %settings = @_;

    # write new settings to includerc file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::clamav::_write_includerc($user, %settings);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_status
{
    my $user = shift;
    my $newstatus = shift;

    if ($newstatus eq "on") {
        # check milter status
        if ( VSAP::Server::Modules::vsap::mail::clamav::_is_installed_milter() ) {
            # return success
            return('SUCCESS', '');
        }
    }

    # write new status
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::clamav::_write_status($user, $newstatus);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_includerc
{
    my $user = shift;
    my %settings = @_;

    # check user's quota... be sure there is enough room for writing
    unless (VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
        # not good
        return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
    }

    # load default settings if not specified
    foreach my $setting (keys(%_DEFAULTS)) {
        unless (defined($settings{$setting})) {
            $settings{$setting} = $_DEFAULTS{$setting};
        }
    }

    # build recipe from settings
    my $recipe = $SKEL_CLAMAV_RC;
    $recipe =~ s/__VIRUSFOLDER__/$settings{'virusfolder'}/g;
    my $clampath = VSAP::Server::Modules::vsap::mail::clamav::_get_path();
    $recipe =~ s/__CLAMPATH__/$clampath/g;

    # write new recipe file
    my $home = (getpwnam($user))[7];
    my $path = "$home/.opencpx/procmail/clamav.rc";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $recipe) {
            # write failed
            close(RCFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MESG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(RCFP);
        # out with old; in with the new
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MESG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_status
{
    my $user = shift;
    my $status = shift;

    # check user's quota... be sure there is enough room for writing
    unless (VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
        # not good
        return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
    }

    # write status ('on' or 'off') to procmail recipe file
    my $home = (getpwnam($user))[7];
    my $path = "$home/.procmailrc";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        # read in the old
        unless (open(RCFP, "$path")) {
          return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $path: $!");
        }
        my $recipes = "";
        while (<RCFP>) {
            if (m!^(#)?(INCLUDERC=\$CPXDIR/clamav.rc)!) {
                $recipes .= ($status eq "on") ? "$2" : "\#$2";
                $recipes .= "\n";
            }
            else {
                $recipes .= $_;
            }
        }
        close(RCFP);
        # write out the new
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $recipes) {
            # write failed
            close(RCFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MESG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(RCFP);
        # replace
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MESG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }
    }

    # return success
    return('SUCCESS', '');
}

##############################################################################
#
# clamav::disable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::clamav::disable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $user = $xmlobj->child('user') ? $xmlobj->child('user')->value :
                                        $vsap->{username};

    unless ($vsap->{server_admin}) {
        my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
        my @ulist = ();
        if ($co->domain_admin) {
            @ulist = keys %{$co->users(admin => $vsap->{username})};
        }
        elsif ($co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            @ulist = keys %{$co->users(domain => $user_domain)};
        }
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

    # disable the clamav service
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::clamav::nv_disable($user);
    if (defined($_ERR_CODE{$code})) {
        $vsap->error($_ERR_CODE{$code} => $mesg);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled clamav for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:clamav:disable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# clamav::enable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::clamav::enable;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $user = $xmlobj->child('user') ? $xmlobj->child('user')->value :
                                        $vsap->{username};

    unless ($vsap->{server_admin}) {
        my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
        my @ulist = ();
        if ($co->domain_admin) {
            @ulist = keys %{$co->users(admin => $vsap->{username})};
        }
        elsif ($co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            @ulist = keys %{$co->users(domain => $user_domain)};
        }
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

    # enable the clamav service
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::clamav::nv_enable($user);
    if (defined($_ERR_CODE{$code})) {
        $vsap->error($_ERR_CODE{$code} => $mesg);
        return;
    }

    # create mailbox
    require VSAP::Server::Modules::vsap::webmail;
    my $wm = new VSAP::Server::Modules::vsap::webmail($vsap->{username}, $vsap->{password}, 'readonly');
    if (ref($wm)) {
        my $fold = $wm->folder_list;
        $wm->folder_create('Quarantine') unless $fold->{'Quarantine'};
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled clamav for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:clamav:enable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# clamav::milter_installed
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::clamav::milter_installed;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $installed = 'no';
    if ( VSAP::Server::Modules::vsap::mail::clamav::_is_installed_milter() ) {
        $installed = 'yes';
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:clamav:milter_installed');
    $root_node->appendTextChild(installed => $installed);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# clamav::status
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::clamav::status;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $user = $xmlobj->child('user') ? $xmlobj->child('user')->value :
                                        $vsap->{username};

    unless ($vsap->{server_admin}) {
        my $co = new VSAP::Server::Modules::vsap::config(uid => $vsap->{uid});
        my @ulist = ();
        if ($co->domain_admin) {
            @ulist = keys %{$co->users(admin => $vsap->{username})};
        }
        elsif ($co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            @ulist = keys %{$co->users(domain => $user_domain)};
        }
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

    my $status = VSAP::Server::Modules::vsap::mail::clamav::_get_status($user);
    my %settings = VSAP::Server::Modules::vsap::mail::clamav::_get_settings($user);

    # disable ClamAV if milter is installed (BUG26718)
    if ( ($status eq "on") &&
          VSAP::Server::Modules::vsap::mail::clamav::_is_installed_milter() ) {
        VSAP::Server::Modules::vsap::mail::clamav::nv_disable($user);
        $status = "off";
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:clamav:status');
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(status => $status);
    $root_node->appendTextChild(quarantinefolder => $settings{'virusfolder'});
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail::clamav - VSAP module to configure
the Clam AntiVirus filtering engine

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::clamav;

=head1 DESCRIPTION

The VSAP clamav mail module allows users (and administrators) to
the configure Clam AntiVirus status.

=head2 mail:clamav:disable

The disable method changes the ClamAV filtering status to inactive
status.  The following is an example of the disable query:

    <vsap type="mail:clamav:disable">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are disabling the ClamAV functionality
on behalf of the enduser.

If the disable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:clamav:enable

The enable method changes the ClamAV filtering status to active status.
The following is an example of the enable query:

    <vsap type="mail:clamav:enable">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain administrators and
server administrators that are enabling the ClamAV functionality
on behalf of the enduser.

If the enable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:clamav:status

The status method can be used to get the properties of the current state
of the ClamAV filtering system.

The following template represents the generic form of a status query:

    <vsap type="mail:clamav:status">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain and server
administrators interested in performing a query on the status of the
ClamAV filtering status of an enduser.

If the status query is successful, then the current state of the ClamAV
filtering engine will be return.  The current definition of the
quarantine folder will also be returned.  For example:

    <vsap type="mail:clamav:status">
        <status>on|off</status>
        <user>user name</user>
        <quarantinefolder>on|off</quarantinefolder>
    </vsap>

=head1 SEE ALSO

L<http://www.clamav.net/>

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
