package VSAP::Server::Modules::vsap::mail::forward;

use 5.008004;
use strict;
use warnings;

use Email::Valid;

use VSAP::Server::Modules::vsap::diskspace;
use VSAP::Server::Modules::vsap::mail::helper;

##############################################################################

our $VERSION = '0.12';

# error codes specific to this module
our %_ERR_CODE = %VSAP::Server::Modules::vsap::mail::helper::_ERR_CODE;
$_ERR_CODE{'FORWARD_EMAIL_EMPTY'}          = 550;
$_ERR_CODE{'FORWARD_EMAIL_INVALID'}        = 551;
$_ERR_CODE{'FORWARD_LOCAL_USER_NOT_FOUND'} = 552;

# error messages specific to this module
our %_ERR_MESG = %VSAP::Server::Modules::vsap::mail::helper::_ERR_MESG;
$_ERR_MESG{'FORWARD_EMAIL_EMPTY'}          = 'forwarding email address(es) not found';
$_ERR_MESG{'FORWARD_EMAIL_INVALID'}        = 'email address not valid';
$_ERR_MESG{'FORWARD_LOCAL_USER_NOT_FOUND'} = 'forwarding user was not found';

our $_RC_MAILFORWARD = ".opencpx/procmail/mailforward.rc";
our $_SV_MAILFORWARD = "sieve/cpx-mailforward.sieve";

our $_MH_PROCMAILRC = $VSAP::Server::Modules::vsap::mail::helper::_MH_PROCMAILRC;
our $_MH_DOVECOTSIEVE = $VSAP::Server::Modules::vsap::mail::helper::_MH_DOVECOTSIEVE;

## FIXME: need to add loop control for sieve!

##############################################################################
#
# some default options for mail forwarding
#
##############################################################################

our %_DEFAULTS = ( savecopy => 'off' );

##############################################################################
#
# skel
#
##############################################################################

our $SKEL_FORWARD_RC = <<'_FORWARD_';
:0
* HB ?? ! $ ^X-Loop:
{
  :0fwh
  | formail -A "X-Loop: $LOGNAME@vsap.no.loop"
  :0:
  ! __EMAIL__
}
_FORWARD_

our $SKEL_SAVECOPY_RC = <<'_COPY_';
:0:
$DEFAULT
_COPY_

our $SKEL_FORWARD_SIEVE = <<'_FORWARD_';
require ["copy"];
redirect :copy "__EMAIL__";
_FORWARD_

##############################################################################
#
# supporting functions
#
##############################################################################

sub _get_settings
{
    my $user = shift;

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();

    # helper file
    my $file = ($filter eq "sieve") ? $_SV_MAILFORWARD : $_RC_MAILFORWARD;

    # some defaults
    my %settings = ();
    $settings{'email'} = "";
    $settings{'savecopy'} = $_DEFAULTS{'savecopy'};

    my $home = (getpwnam($user))[7];
    my $path = "$home/$file";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(RCFP, "$path")) {
            while (<RCFP>) {
                my $curline = $_;
                $curline =~ s/\s+$//;
                $curline =~ s/^\s+//;
                if ($filter eq "sieve") {
                    if ($curline =~ /^redirect\s+\:copy\s+"(.*?)"/) {
                        $settings{'email'} .= ", " if ($settings{'email'} ne "");
                        $settings{'email'} .= $1;
                    }
                    elsif ($curline =~ /^keep\;$/) {
                        $settings{'savecopy'} = "on";
                    }
                }
                else {
                    if ($curline =~ /^!\s+(.*)/) {
                        $settings{'email'} = $1;
                    }
                    elsif ($curline =~ /^\$DEFAULT/) {
                        $settings{'savecopy'} = "on";
                    }
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

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();

    # helper file
    my $file = ($filter eq "sieve") ? $_MH_DOVECOTSIEVE : $_MH_PROCMAILRC;

    # load status ... 'on' or 'off'
    my $home = (getpwnam($user))[7];
    my $path = "$home/$file";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(RCFP, "$path")) {
            while (<RCFP>) {
                my $curline = $_;
                $curline =~ s/\s+$//;
                if ($filter eq "sieve") {
                    # look for 'include :personal "cpx-mailforward";'
                    if ($curline =~ m!^(#)?(include \:personal \"cpx-mailforward\"\;)!) {
                        $status = ($1 ? 'off' : 'on');
                        last;
                    }
                }
                else {
                    # look for 'INCLUDERC=$CPXDIR/mailforward.rc'
                    if ($curline =~ m!^(#)?INCLUDERC=\$CPXDIR/mailforward.rc!) {
                        $status = ($1 ? 'off' : 'on');
                        last;
                    }
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

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();

    # check to see if some useful directories exist
    my $home = (getpwnam($user))[7];
    my @paths = ("$home/.opencpx");
    if ($filter eq "sieve") {
        push(@paths, "$home/sieve");
    }
    else {
        push(@paths, "$home/.opencpx/procmail");
    }
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

    # make sure CPX mail filtering block is found in helper file
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::helper::_init($user);
    return($err, $str) if (defined($_ERR_CODE{$err}));

    # init files specific to mail forwarding if not found
    if ((($filter eq "sieve") && (!(-e "$home/$_SV_MAILFORWARD"))) ||
        (($filter eq "procmail") && (!(-e "$home/$_RC_MAILFORWARD")))) {
        ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_write_settings($user);
        return($err, $str) if (defined($_ERR_CODE{$err}));
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_settings
{
    my $user = shift;
    my %settings = @_;

    # write new settings to includerc file
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_write_settings($user, %settings);
    return($err, $str) if (defined($_ERR_CODE{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_status
{
    my $user = shift;
    my $newstatus = shift;

    # write new status
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_write_status($user, $newstatus);
    return($err, $str) if (defined($_ERR_CODE{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_settings
{
    my $user = shift;
    my %settings = @_;

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();

    # check user's quota... be sure there is enough room for writing
    unless(VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
        # not good
        return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
    }

    # load default settings if not specified
    foreach my $setting (keys(%_DEFAULTS)) {
        unless (defined($settings{$setting})) {
            $settings{$setting} = $_DEFAULTS{$setting};
        }
    }
    unless (defined($settings{'email'})) {
        $settings{'email'} = $user . '\@localhost';
    }

    # build a comma delimited addresslist from input
    my $addresslist = $settings{'email'};
    $addresslist =~ s/^\s+//g;
    $addresslist =~ s/\s+$//g;
    $addresslist =~ s/,/ /g;
    $addresslist =~ s/\s+/, /g;

    # build contents from settings
    my $content = "";
    if ($filter eq "sieve") {
        $content = $SKEL_FORWARD_SIEVE;
        $addresslist =~ s/\s+//g;
        my @addresses = split(/\,/, $addresslist);
        $content =~ s/__EMAIL__/$addresses[0]/;
        for (my $index=1; $index<=$#addresses; $index++) {
            $content .= "redirect :copy \"$addresses[$index]\";\n";
        }
        # forwarding only... or saving a local copy?
        my $action = ($settings{'savecopy'} eq "on") ? "keep" : "discard";
        $content .= "$action;\n";
    }
    else {
        $content = $SKEL_FORWARD_RC;
        $content =~ s/__EMAIL__/$addresslist/;
        # forwarding only... or saving a local copy?
        if ($settings{'savecopy'} eq "on") {
            $content =~ s/:0/:0 c/;
            $content .= "\n" . $SKEL_SAVECOPY_RC;
        }
    }

    # helper file
    my $file = ($filter eq "sieve") ? $_SV_MAILFORWARD : $_RC_MAILFORWARD;

    # write new contents to file
    my $home = (getpwnam($user))[7];
    my $path = "$home/$file";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $content) {
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
    unless(VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
        # not good
        return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
    }

    # are we using procmail or sieve?
    my $filter = VSAP::Server::Modules::vsap::mail::helper::_which_filter();

    # helper file
    my $file = ($filter eq "sieve") ? $_MH_DOVECOTSIEVE : $_MH_PROCMAILRC;

    # write status ('on' or 'off') to helper file
    my $home = (getpwnam($user))[7];
    my $path = "$home/$file";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        # read in the old
        unless (open(RCFP, "$path")) {
          return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $path: $!");
        }
        my $content = "";
        while (<RCFP>) {
            my $curline = $_;
            if ($filter eq "sieve") {
                if ($curline =~ m!^(#)?(include \:personal \"cpx-mailforward\"\;)!) {
                    $content .= ($status eq "on") ? "$2" : "\#$2";
                    $content .= "\n";
                }
                else {
                    $content .= $curline;
                }
            }
            else {
                if ($curline =~ m!^(#)?(INCLUDERC=\$CPXDIR/mailforward.rc)!) {
                    $content .= ($status eq "on") ? "$2" : "\#$2";
                    $content .= "\n";
                }
                else {
                    $content .= $curline;
                }
            }
        }
        close(RCFP);
        # write out the new
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $content) {
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
# forward::disable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::forward::disable;

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::webmail::options;

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

    # do some sanity checking
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_init($user);
    if (defined($_ERR_CODE{$err})) {
        $vsap->error($_ERR_CODE{$err} => $str);
        return;
    }

    # save the settings (ignore errors)
    my %settings = ();
    $settings{'savecopy'} = $xmlobj->child('savecopy') ?  $xmlobj->child('savecopy')->value : 'off';
    $settings{'email'} = $xmlobj->child('email') ? $xmlobj->child('email')->value : '';
    if ($settings{'email'} eq "") {
        # build an outgoing e-mail address
        $settings{'email'} = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "preferred_from");
        $settings{'email'} ||= $vsap->{username} . "@" . $vsap->{hostname};
    }
    VSAP::Server::Modules::vsap::mail::forward::_save_settings($user, %settings);

    # save the status
    ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_save_status($user, "off");
    if (defined($_ERR_CODE{$err})) {
        $vsap->error($_ERR_CODE{$err} => $str);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled mail forward for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:forward:enable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# forward::enable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::forward::enable;

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail qw(addr_genericstable);

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

    # do some sanity checking
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_init($user);
    if (defined($_ERR_CODE{$err})) {
        $vsap->error($_ERR_CODE{$err} => $str);
        return;
    }

    # check validity of forwarding e-mail address and save the settings
    my %settings;
    %settings = ();
    $settings{'savecopy'} = $xmlobj->child('savecopy') ?  $xmlobj->child('savecopy')->value : 'off';
    $settings{'email'} = $xmlobj->child('email') ? $xmlobj->child('email')->value : '';
    unless ($settings{'email'}) {
        $vsap->error($_ERR_CODE{'FORWARD_EMAIL_EMPTY'} => $_ERR_MESG{'FORWARD_EMAIL_EMPTY'});
        return;
    }
    $settings{'email'} =~ s/\s//g;

    my $addresslist;
    $addresslist = "";
    my @addrs = grep { $_ } split(/\s*[\r\n,]+\s*/, $settings{'email'});
    foreach my $addr (@addrs) {
        if ($addr =~ /\@/) {
            my $emailValid = ( eval { Email::Valid->address( $addr ) } ) ? $addr : 0;
            unless( $emailValid ) {
                my $details = Email::Valid->details();
                $vsap->error($_ERR_CODE{FORWARD_EMAIL_INVALID} => $addr);
                return;
            }
        }
        else {
            # no '@' found; presume local username
            my $username = $addr;
            unless( defined(getpwnam($username)) ) {
                $vsap->error($_ERR_CODE{FORWARD_LOCAL_USER_NOT_FOUND} => "User '$username' not found");
                return;
            }
            # load up genericstable and substitute gentab entry for username (if defined)
            my $genericsaddr = VSAP::Server::Modules::vsap::mail::addr_genericstable($username);
            $addr = $genericsaddr if ($genericsaddr);
        }
        $addresslist .= ", " unless ($addresslist eq "");
        $addresslist .= $addr;
    }
    $settings{'email'} = $addresslist;
    ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_save_settings($user, %settings);
    if (defined($_ERR_CODE{$err})) {
        $vsap->error($_ERR_CODE{$err} => $str);
        return;
    }

    # save the status
    ($err, $str) = VSAP::Server::Modules::vsap::mail::forward::_save_status($user, "on");
    if (defined($_ERR_CODE{$err})) {
        $vsap->error($_ERR_CODE{$err} => $str);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled mail forward for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:forward:enable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# forward::status
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::forward::status;

use VSAP::Server::Modules::vsap::config;

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


    my $status = VSAP::Server::Modules::vsap::mail::forward::_get_status($user);
    my %settings = VSAP::Server::Modules::vsap::mail::forward::_get_settings($user);

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:forward:status');
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(status => $status);
    $root_node->appendTextChild(email => $settings{'email'});
    $root_node->appendTextChild(savecopy => $settings{'savecopy'});
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail::forward - VSAP module to configure a
mail forward for incoming e-mail messages

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::forward;

=head1 DESCRIPTION

The VSAP forward mail module allows users (and administrators) to
configure a mail forward incoming e-mail messages.  An option to allow a
user to save a local copy of the incoming message is also available (see
below).

=head2 mail:forward:disable

The disable method changes the status of the mail forward to inactive.
The method will also accept any valid mail forward options (forwarding
e-mail address, save copy) and update the options as part of the disable
request.  Specifying mail forward options as part of a mail forward
disable rquest is not required.

The following template represents the generic form of a disable query:

    <vsap type="mail:forward:disable">
        <user>user name</user>
        <email>e-mail address(es)</email>
        <savecopy>on|off</savecopy>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are disabling the mail forward functionality
on behalf of the enduser.

The e-mail address (if defined) is presumed to represent the e-mail
address that will used to forward any incoming e-mail message (when the
mail forward is re-enabled).  If more than one forwarding address is
desired, the addresses must be separated by commas.

The 'savecopy' option (if defined) indicates whether a local copy of
each incoming e-mail message should be saved.  The values of the
'savecopy' option can be either 'on' or 'off'.

If the disable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:forward:enable

The enable method changes the status of the mail forward to active.  The
method will also accept any valid mail forward options (forwarding
e-mail address, save copy) and update the options as part of the enable
request.  When enabling the mail forward, the forwarding e-mail address
is required.

The following template represents the generic form of a enable query:

    <vsap type="mail:forward:enable">
        <user>user name</user>
        <email>e-mail address(es)</email>
        <savecopy>on|off</savecopy>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are disabling the mail forward functionality
on behalf of the enduser.

The e-mail address is presumed to represent the e-mail address that will
used to forward any incoming e-mail message.  If more than one
forwarding address is desired, the addresses must be separated by
commas.

The 'savecopy' option (if defined) indicates whether a local copy of
each incoming e-mail message should be saved.  The values of the
'savecopy' option can be either 'on' or 'off'.

If the enable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:forward:status

The status method can be used to get the properties of the current mail
forward configuration.

The following template represents the generic form of a status query:

    <vsap type="mail:forward:status">
        <user>user name</user>
        <email>e-mail address(es)</email>
        <savecopy>on|off</savecopy>
    </vsap>

The optional user name can be specified by domain and server
administrators interested in performing a query on the status of the
mail forward status of an enduser.

If the status query is successful, then the mail forward status, the
mail forwarding e-mail address(es), and 'savecopy' status will all be
returned.  For example:

    <vsap type="mail:forward:status">
        <user>user name</user>
        <email>e-mail address(es)</email>
        <savecopy>on|off</savecopy>
    </vsap>

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
