package VSAP::Server::Modules::vsap::mail::autoreply;

use 5.008004;
use strict;
use warnings;
use Quota;
use Encode;

use VSAP::Server::Modules::vsap::mail qw(addr_genericstable);

require VSAP::Server::Modules::vsap::config;
require VSAP::Server::Modules::vsap::logger;
require VSAP::Server::Modules::vsap::mail::helper;
require VSAP::Server::Modules::vsap::webmail::options;

our $VERSION = '0.01';

# error codes and messages for this module
our %_ERR = %VSAP::Server::Modules::vsap::mail::helper::_ERR;
our %_ERR_MSG = %VSAP::Server::Modules::vsap::mail::helper::_ERR_MSG;
$_ERR{'AUTOREPLY_NOT_FOUND'} =           550;
$_ERR{'VACATION_NOT_FOUND'} =            551;
$_ERR{'AUTOREPLY_MESSAGE_EMPTY'} =       555;
$_ERR_MSG{'AUTOREPLY_NOT_FOUND'} =       'autoreply(1) not found';
$_ERR_MSG{'VACATION_NOT_FOUND'} =        'vacation(1) not found';
$_ERR_MSG{'AUTOREPLY_MESSAGE_EMPTY'} =   'autoreply message empty';

our $_RC_AUTOREPLY = ".cpx/procmail/autoreply.rc";
our $_SV_AUTOREPLY = "sieve/cpx-autoreply.sieve";

our $_MH_PROCMAILRC = $VSAP::Server::Modules::vsap::mail::helper::_MH_PROCMAILRC;
our $_MH_DOVECOTSIEVE = $VSAP::Server::Modules::vsap::mail::helper::_MH_DOVECOTSIEVE;

## FIXME: need to add loop control for sieve!

##############################################################################
#
# some default options 
#
##############################################################################

# note: specify filenames with respect to a theoretical home directory.

our %_DEFAULTS =
(
  encoding                    => 'UTF-8',
  interval                    => 7,
  logfilename                 => '.cpx/autoreply/vacation.db',
  msgfilename                 => '.cpx/autoreply/message.txt',
);

our $_VPATH = "/usr/bin/vacation";
our $_APATH = "/usr/local/bin/autoreply";

##############################################################################
#
# skel
#
##############################################################################

our $SKEL_AUTOREPLY_RC = <<'_AUTOREPLY_';
:0 c
* ! ^FROM_DAEMON
* ! ^FROM_MAILER
* HB ?? ! ^X-Loop:
| __APATH __ALIASES__ -f __FROM__ -m $HOME/__MSGFILE__
_AUTOREPLY_

our $SKEL_VACATION_RC = <<'_VACATION_';
:0 c
* ! ^FROM_DAEMON
* ! ^FROM_MAILER
* ! ^X-Loop:
| __VPATH __ALIASES__ -R __FROM__ -f $HOME/__LOGFILE__ -m $HOME/__MSGFILE__ $LOGNAME
_VACATION_

our $SKEL_AUTOREPLY_MESSAGE = <<'_MESSAGE_';
Subject: Lorem ipsum...

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id
est laborum.
_MESSAGE_

our $SKEL_AUTOREPLY_SEIVE = <<'_AUTOREPLY_';
require "vacation-seconds";
vacation
:days __DAYS__
:subject "__SUBJECT__"
:from "__FROM__"
:addresses [__ALIASES__]
:mime text:
__TEXT__
.
;
_AUTOREPLY_

##############################################################################
#
# supporting functions
# 
##############################################################################

sub _alias_list
{
    my $rhs = shift;
    my $type = shift;

    my $list = "";
    require VSAP::Server::Modules::vsap::mail;
    foreach my $address (@{VSAP::Server::Modules::vsap::mail::addr_virtusertable($rhs)}) {
        if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
            $list .= ", " if ($list ne "");
            $list .= "\"$address\"";
        }
        else {
            if ($type eq "vacation") {
                # build alias arg list compatible with vacation(1)
                my $name = $address;
                $name =~ s/\@.*$//g;
                next if ($name eq $rhs);
                $list .= "-a $name ";
            }
            else {
                # build alias arg list compatible with autoreply(1)
                $list .= "-a $address ";
            }
            chop($list) if ($list);
        }
    }
    return($list);
}

#-----------------------------------------------------------------------------

sub _get_default_domain_name
{
    my $vsap = shift;
    my $user = shift;

    my $co = new VSAP::Server::Modules::vsap::config( username => $user );
    my $domain = $co->user_domain() || $vsap->{hostname};
    return($domain);
}

#-----------------------------------------------------------------------------

sub _get_default_reply_to
{
    my $vsap = shift;
    my $user = shift;
    my $dom = $vsap->dom;

    my $address = "";

    # first try webmail options
    $address = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "preferred_from");

    # next try generics table
    unless ($address) {
        local $> = $) = 0;  ## regain privileges for a moment
        $address = VSAP::Server::Modules::vsap::mail::addr_genericstable($vsap->{username});
    }

     # fail over to "user@domain"
    unless ($address) {
        my $domain = VSAP::Server::Modules::vsap::mail::autoreply::_get_default_domain_name($vsap, $user);
        $address = $user . '@' . $domain;
    }

    return($address);
}

#-----------------------------------------------------------------------------

sub _get_encoding 
{
    my $vsap = shift;
    my $dom = shift;
    my $user = shift;

    # default setting
    my $encoding = VSAP::Server::Modules::vsap::webmail::options::get_value($vsap, $dom, "outbound_encoding");
    $encoding ||= $_DEFAULTS{'encoding'};

    # extract current encoding setting from stored message
    my $message = "";
    my $msgpath = VSAP::Server::Modules::vsap::mail::autoreply::_message_path($user);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(MFP, '<', $msgpath)) {
            read(MFP, $message, -s $msgpath);
            close(MFP);
            #########################################################
            # if an existing autoreply message file is found, then  #
            # presume the encoding is in UTF-8 unless the message   #
            # otherwise specifies.  this is necessary since legacy  #
            # messages generated and stored by autoreply.pm did not #
            # include encoding information (UTF-8 was presumed).    #
            #########################################################
            $encoding = "UTF-8";
        }
    }
    if ($message =~ m#Content-Type: text/plain; charset="(.*)"; format="flowed"#is) {
        $encoding = $1;
    }

    return($encoding);
}

#-----------------------------------------------------------------------------

sub _get_interval
{
    my $user = shift;

    my $interval = $_DEFAULTS{'interval'};

    my $home = (getpwnam($user))[7];
    my $path = "$home/.cpx/autoreply/options.xml";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(OPTIONS, "$path")) {
            while (<OPTIONS>) {
                if (m#<interval>([0-9]*)</interval>#) {
                  $interval = $1;
                  last;
                }
            }
            close(OPTIONS);
        }
    }
    return($interval);
}

#-----------------------------------------------------------------------------

sub _get_message 
{
    my $user = shift;

    my $message = "";
    my $msgpath = VSAP::Server::Modules::vsap::mail::autoreply::_message_path($user);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(MFP, '<', $msgpath)) {
            read(MFP, $message, -s $msgpath);
            close(MFP);
        }
    }
    return($message);
}

#-----------------------------------------------------------------------------

sub _get_settings
{
    my $user = shift;
    my $default_email = shift;

    # some defaults
    my %settings = ();
    $settings{'encoding'} = $_DEFAULTS{'encoding'};
    $settings{'interval'} = $_DEFAULTS{'interval'};
    $settings{'from'} = $_DEFAULTS{'from'};
    $settings{'enc_subject'} = "";
    $settings{'subject'} = "";
    $settings{'enc_body'} = "";
    $settings{'body'} = "";

    # get message
    my $message = VSAP::Server::Modules::vsap::mail::autoreply::_get_message($user);

    # get encoding
    if ($message =~ m#Content-Type: text/plain; charset="(.*)"; format="flowed"#is) {
        $settings{'encoding'} = $1;
    }

    # get interval, subject, from, and body
    if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        # parse message for interval, reply-to, subject, and message text
        if ($message =~ /^\:days (.*)\n/im) {
            $settings{'interval'} = $1;
        }
        if ($message =~ /^\:seconds (.*)\n/im) {
            $settings{'interval'} = $1;
        }
        if ($message =~ /^\:from \"(.*)\"\n/im) {
            $settings{'from'} = $1;
        }
        if ($message =~ /^\:subject \"(.*)\"\n/im) {
            $settings{'enc_subject'} = $1;
        }
        if ($message =~ /.*?\n\n(.*)\.\n\;\n/is) {
            $settings{'enc_body'} = $1;
        }
    }
    else {
        # get stored interval from file
        $settings{'interval'} = VSAP::Server::Modules::vsap::mail::autoreply::_get_interval($user);
        # parse message for reply-to, subject, and message text
        if ($message =~ /^Reply-To: (.*)\n/im) {
            $settings{'from'} = $1;
        }
        # parse message for encoded subject
        if ($message =~ /^Subject: (.*)\n/im) {
            $settings{'enc_subject'} = $1;
        }
        if ($message =~ /.*?\n\n(.*)/im) {
            $settings{'enc_body'} = $1;
        }
    }

    # decode subject
    my $gmail = VSAP::Server::G11N::Mail->new( { 'DEFAULT_ENCODING' => 'UTF-8' } );
    $settings{'subject'} = $gmail->get_subject( { from_encoding => $settings{'encoding'},
                                                  to_encoding   => 'UTF-8',
                                                  subject       => $settings{'enc_subject'} } );

    # decode the message body
    Encode::from_to($settings{'enc_body'}, $settings{'encoding'}, "UTF-8");
    $settings{'body'} = Encode::decode_utf8($settings{'enc_body'});

    return(%settings);
}

#-----------------------------------------------------------------------------

sub _get_status
{
    my $user = shift;

    my $status = "off";  # default

    # helper file
    my $file = ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) ?
                   $_MH_DOVECOTSIEVE : $_MH_PROCMAILRC;

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
                if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
                    # look for 'include :personal "cpx-autoreply";'
                    if ($curline =~ m!^(#)?(include \:personal \"cpx-autoreply\"\;)!) {
                        $status = ($1 ? 'off' : 'on');
                        last;
                    }
                }
                else {
                    # look for 'INCLUDERC=$CPXDIR/autoreply.rc'
                    if ($curline =~ m!^(#)?INCLUDERC=\$CPXDIR/autoreply.rc!) {
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

    unless ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        # check for autoreply installation
        unless ((-e "$_VPATH") && (-e "$_APATH")) {
            return('AUTOREPLY_NOT_FOUND', $_ERR_MSG{'AUTOREPLY_NOT_FOUND'});
        }
    }

    # check to see if some useful directories exist
    my $home = (getpwnam($user))[7];
    my @paths = ("$home/.cpx");
    if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        push(@paths, "$home/sieve");
    }
    else {
        push(@paths, "$home/.cpx/procmail");
        push(@paths, "$home/.cpx/autoreply");
    }
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily
        foreach my $path (@paths) {
            unless (-e "$path") {
                unless (mkdir("$path", 0700)) {
                    return('MAIL_MKDIR_FAILED', "$_ERR_MSG{'MAIL_MKDIR_FAILED'} ... $path : $!");
                }
            }
            my($uid, $gid) = (getpwnam($user))[2,3];
            chown($uid, $gid, $path);
        }
    }

    # make sure CPX recipe block is found in helper file
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::helper::_audit_helper_file($user);
    return($err, $str) if (defined($_ERR{$err}));

    # init files specific to autoreply if not found
    if (( $VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD && (!(-e "$home/$_SV_AUTOREPLY"))) ||
        (!$VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD && (!(-e "$home/$_RC_AUTOREPLY")))) {
        ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_write_settings($user);
        return($err, $str) if (defined($_ERR{$err}));
    }
    unless ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        my $path = VSAP::Server::Modules::vsap::mail::autoreply::_message_path($user);
        unless (-e "$path") {
            # no outgoing message found; create a default
            VSAP::Server::Modules::vsap::mail::autoreply::_write_message($user);
        }
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _message_path
{
    my $user = shift;

    my $home = (getpwnam($user))[7];
    if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        return("$home/$_SV_AUTOREPLY");
    }
    return("$home/$_DEFAULTS{'msgfilename'}");
}

#-----------------------------------------------------------------------------

sub _save_interval
{
    my $user = shift;
    my $interval = shift;

    $interval = sprintf "%d", $interval;
    $interval = 0 if ($interval < 0);

    # write new interval
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_write_options($user, "interval", $interval);
    return($err, $str) if (defined($_ERR{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_message
{
    my $user = shift;
    my $message = shift;

    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_write_message($user, $message);
    return($err, $str) if (defined($_ERR{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_settings
{
    my $user = shift;
    my %settings = @_;

    # write new settings to includerc file
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_write_settings($user, %settings);
    return($err, $str) if (defined($_ERR{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_status
{
    my $user = shift;
    my $newstatus = shift;

    # write new status
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_write_status($user, $newstatus);
    return($err, $str) if (defined($_ERR{$err}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_message
{
    my $user = shift;
    my $message = shift;
    my $from = shift;

    # check user's quota... be sure there is enough room for writing
    unless(_diskspace_availability($user)) {
            # not good
            return('QUOTA_EXCEEDED', $_ERR_MSG{'QUOTA_EXCEEDED'});
    }

    # load default message if not specified
    unless (defined($message)) {
        $message = $SKEL_AUTOREPLY_MESSAGE;
    }

    # remove evil spirits
    $message =~ s/\r\n/\n/g;
    $message =~ s/\r//g;
    $message =~ s/^\s+//;

    # write new message file
    my $path = VSAP::Server::Modules::vsap::mail::autoreply::_message_path($user);
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        my $newpath = "$path.$$";
        unless (open(MFP, ">$newpath")) {
            # open failed... drat! 
            return('OPEN_FAILED', "$_ERR_MSG{'OPEN_FAILED'} ... $newpath : $!");
        }
        # insert loop protection into the message
        $message =~ s/^X-Loop: .*\n//igm;
        unless (print MFP "X-Loop: $user\@vsap.no.loop\n") {
            # write failed
            close(MFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
        }
        unless ($message =~ /^[\x21-\x39\x3b-\x7e]+:/) {
            # message doesn't start with header line; insert blank line
            unless (print MFP "\n") {
                # write failed
                close(MFP);
                unlink($newpath);
                return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
            }
        }
        # now write the message
        unless (print MFP $message) {
            # write failed
            close(MFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(MFP);
        # out with old; in with the new
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MSG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }

    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_options
{
    my $user = shift;
    my %options = @_;

    # check user's quota... be sure there is enough room for writing
    unless(_diskspace_availability($user)) {
            # not good
            return('QUOTA_EXCEEDED', $_ERR_MSG{'QUOTA_EXCEEDED'});
    }

    # load default options if not specified
    unless (defined($options{'interval'})) {
        $options{'interval'} = VSAP::Server::Modules::vsap::mail::autoreply::_get_interval($user);
    }

    my $options = "<autoreply_options>\n  <interval>$options{'interval'}</interval>\n</autoreply_options>\n";

    # write new autoreply options file 
    my $home = (getpwnam($user))[7];
    my $path = "$home/.cpx/autoreply/options.xml";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        # write new options file 
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MSG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $options) {
            # write failed
            close(RCFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(RCFP);
        # out with old; in with the new
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MSG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _write_settings
{
    my $user = shift;
    my %settings = @_;

    # check user's quota... be sure there is enough room for writing
    unless(_diskspace_availability($user)) {
            # not good
            return('QUOTA_EXCEEDED', $_ERR_MSG{'QUOTA_EXCEEDED'});
    }

    # load default settings if not specified
    unless (defined($settings{'interval'})) {
      $settings{'interval'} = VSAP::Server::Modules::vsap::mail::autoreply::_get_interval($user);
    }
    foreach my $setting (keys(%_DEFAULTS)) {
        unless (defined($settings{$setting})) {
            $settings{$setting} = $_DEFAULTS{$setting};
        }
    }

    # build appropriate content from settings (based on platform)
    my $content = "";
    if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
        $content = $SKEL_AUTOREPLY_SEIVE;
        if (($settings{'enc_subject'} eq "") && ($settings{'enc_body'} eq "")) {
            $SKEL_AUTOREPLY_MESSAGE =~ /(.*?)\n\n(.*)/im;
            $settings{'enc_subject'} = $1;
            $settings{'enc_body'} = $2;
        }
        $settings{'enc_body'} = "Content-Type: text/plain; charset=\"$settings{'encoding'}\"; format=\"flowed\"\n" .
                                "MIME-Version: 1.0\n\n" . $settings{'enc_body'}; 
        my $aliases = VSAP::Server::Modules::vsap::mail::autoreply::_alias_list($user);
        if ( $aliases eq '' ) { # :addresses cannot be empty
            $content =~ s/\n:addresses \[__ALIASES__\]\n/\n/s;
        } else {
            $content =~ s/__ALIASES__/$aliases/;
        }
        $content =~ s/__FROM__/$settings{'from'}/;
        if ($settings{'interval'} == 0) {
            $content =~ s/\:days/\:seconds/;
        }
        $content =~ s/__DAYS__/$settings{'interval'}/;
        $content =~ s/__SUBJECT__/$settings{'enc_subject'}/;
        $content =~ s/__TEXT__/$settings{'enc_body'}/;
    }
    else {
        # build message
        my $message = $SKEL_AUTOREPLY_MESSAGE;
        if ($settings{'enc_subject'} || $settings{'enc_body'}) {
            $message = "Subject: $settings{'enc_subject'}\n";
            $message .= "Reply-To: $settings{'from'}\n";
            $message .= "Content-Type: text/plain; charset=\"$settings{'encoding'}\"; format=\"flowed\"\n";
            $message .= "MIME-Version: 1.0\n";
            $message .= "\n";
            $message .= "$settings{'enc_body'}\n";
        }
        # save message in separate file
        my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_save_message($user, $message);
        return($err, $str) if (defined($_ERR{$err}));
        # also save the autoreply interval in separate file
        ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_save_interval($user, $settings{'interval'});
        return($err, $str) if (defined($_ERR{$err}));
        # build content from procmailrc recipes
        my $aliases = VSAP::Server::Modules::vsap::mail::autoreply::_alias_list($user, "vacation");
        if ($settings{'interval'}) {
            $content = $SKEL_VACATION_RC;
            $content =~ s/__VPATH/$_VPATH/;
        }
        else {
            $content = $SKEL_AUTOREPLY_RC;
            $content =~ s/__APATH/$_APATH/;
            $aliases = VSAP::Server::Modules::vsap::mail::autoreply::_alias_list($user, "autoreply");
        }
        $content =~ s/__LOGFILE__/$settings{'logfilename'}/;
        $content =~ s/__MSGFILE__/$settings{'msgfilename'}/;
        $content =~ s/__ALIASES__/$aliases/;
        $content =~ s/__FROM__/$settings{'from'}/;
    }

    # helper file
    my $file = ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) ?
                   $_SV_AUTOREPLY : $_RC_AUTOREPLY;

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
            return('OPEN_FAILED', "$_ERR_MSG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $content) {
            # write failed
            close(RCFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(RCFP);
        # out with old; in with the new
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MSG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }
        # legacy support
        unless ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
            unlink("$home/$settings{'logfilename'}") if (-e "$home/$settings{'logfilename'}");
            if ($settings{'interval'}) {  ## interval is non-zero, re-initialize vacation.db
              FORK: {
                    my $pid;
                    if ($pid = fork) {
                        # parent
                        wait();
                      REWT: {
                            local $> = $) = 0;  ## regain privileges for a moment
                            my $uid = getpwnam($user);   
                            chown($uid, -1, "$home/$settings{'logfilename'}");
                        }
                    }
                    elsif (defined $pid) {
                        # child
                        ($>, $<) = ($<, $>);
                        system("$_VPATH", '-i', '-r', "$settings{'interval'}", '-f', "$home/$settings{'logfilename'}")
                            and do {
                                my $exit = ($? >> 8);
                                warn("init of vacation db failed (\"$_VPATH -i -r $settings{'interval'} -f $home/$settings{'logfilename'}\"); exitcode $exit");
                            };
                        exit(0);
                    }
                    else {
                        # fork failure
                        sleep(5);
                        redo FORK;
                    }
                }
            }
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
    unless(_diskspace_availability($user)) {
            # not good
            return('QUOTA_EXCEEDED', $_ERR_MSG{'QUOTA_EXCEEDED'});
    }

    # helper file
    my $file = ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) ?
                   $_MH_DOVECOTSIEVE : $_MH_PROCMAILRC;

    # write status ('on' or 'off') to helper file 
    my $home = (getpwnam($user))[7];
    my $path = "$home/$file";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        # read in the old
        unless (open(RCFP, "$path")) {
          return('OPEN_FAILED', "$_ERR_MSG{'OPEN_FAILED'} ... $path: $!");
        }
        my $content = "";
        while (<RCFP>) {
            my $curline = $_;
            if ($VSAP::Server::Modules::vsap::mail::helper::IS_CLOUD) {
                if ($curline =~ m!^(#)?(include \:personal \"cpx-autoreply\"\;)!) {
                    $content .= ($status eq "on") ? "$2" : "\#$2";
                    $content .= "\n";
                }
                else {
                    $content .= $curline;
                }
            }
            else {
                if ($curline =~ m!^(#)?(INCLUDERC=\$CPXDIR/autoreply.rc)!) {
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
            return('OPEN_FAILED', "$_ERR_MSG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $content) {
            # write failed
            close(RCFP);
            unlink($newpath);
            return('WRITE_FAILED', "$_ERR_MSG{'WRITE_FAILED'} ... $newpath : $!");
        }
        close(RCFP);
        # replace
        unless (rename($newpath, $path)) {
            unlink($newpath);
            return('RENAME_FAILED', "$_ERR_MSG{'RENAME_FAILED'} ... $newpath -> $path: $!");
        }
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _diskspace_availability
{
  my($user) = @_;

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $dev = Quota::getqcarg('/home');
        my($uid, $gid) = (getpwnam($user))[2,3];   
        my($usage, $quota) = (Quota::query($dev, $uid))[0,1];
        if(($quota > 0) && ($usage > $quota)) {
            return 0;
        }
        my($grp_usage, $grp_quota) = (Quota::query($dev, $gid, 1))[0,1];
        if(($grp_quota > 0) && ($grp_usage > $grp_quota)) {
            return 0;
        }
   }

   return 1;
}

##############################################################################
#
# autoreply::disable
#
##############################################################################
    
package VSAP::Server::Modules::vsap::mail::autoreply::disable;
      
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
            $vsap->error($_ERR{'AUTH_FAILED'} => $_ERR_MSG{'AUTH_FAILED'});
            return;
        }
    }

    # do some sanity checking
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_init($user);
    if (defined($_ERR{$err})) {
        $vsap->error($_ERR{$err} => $str);
        return;
    }

    # encoding
    my $encoding = $xmlobj->child('encoding') ? $xmlobj->child('encoding')->value : 
                   VSAP::Server::Modules::vsap::mail::autoreply::_get_encoding($vsap, $dom, $user);

    # subject
    require VSAP::Server::G11N::Mail;
    my $subject = $xmlobj->child('subject') ? $xmlobj->child('subject')->value : '';
    my $gmail = VSAP::Server::G11N::Mail->new( { 'DEFAULT_ENCODING' => 'UTF-8' } );
    my $enc_subject = $gmail->set_subject( { from_encoding    => 'UTF-8',
                                             to_encoding      => $encoding,
                                             subject          => $subject } );
    $enc_subject =~ s/\n//g;  ## remove evil spirits

    # reply-to
    my $replyto = $xmlobj->child('replyto') ? $xmlobj->child('replyto')->value : '';
    $replyto ||= VSAP::Server::Modules::vsap::mail::autoreply::_get_default_reply_to($vsap, $user);

    # message body
    my $messagetext = $xmlobj->child('message') ? $xmlobj->child('message')->value : '';
    my $enc_messagetext = Encode::encode_utf8($messagetext);
    Encode::from_to($enc_messagetext, "UTF-8", $encoding);

    # interval
    my $interval = $xmlobj->child('interval') ? $xmlobj->child('interval')->value : $_DEFAULTS{'interval'};

    # save the settings (ignore errors)
    my %settings = ();
    $settings{'encoding'} = $encoding;
    $settings{'subject'} = $subject;
    $settings{'enc_subject'} = $enc_subject;
    $settings{'from'} = $replyto;
    $settings{'body'} = $messagetext;
    $settings{'enc_body'} = $enc_messagetext;
    $settings{'interval'} = $interval;
    VSAP::Server::Modules::vsap::mail::autoreply::_save_settings($user, %settings);
  
    # save the status
    ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_save_status($user, "off");
    if (defined($_ERR{$err})) {
        $vsap->error($_ERR{$err} => $str);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled autoreply for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:autoreply:disable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# autoreply::enable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::autoreply::enable;

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
            $vsap->error($_ERR{'AUTH_FAILED'} => $_ERR_MSG{'AUTH_FAILED'});
            return;
        }
    }

    # do some sanity checking
    my ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_init($user);
    if (defined($_ERR{$err})) {
        $vsap->error($_ERR{$err} => $str);
        return;
    }

    # encoding
    my $encoding = $xmlobj->child('encoding') ? $xmlobj->child('encoding')->value : 
                   VSAP::Server::Modules::vsap::mail::autoreply::_get_encoding($vsap, $dom, $user);

    # subject
    require VSAP::Server::G11N::Mail;
    my $subject = $xmlobj->child('subject') ? $xmlobj->child('subject')->value : '';
    my $gmail = VSAP::Server::G11N::Mail->new( { 'DEFAULT_ENCODING' => 'UTF-8' } );
    my $enc_subject = $gmail->set_subject( { from_encoding    => 'UTF-8',
                                             to_encoding      => $encoding,
                                             subject          => $subject } );
    $enc_subject =~ s/\n//g;  ## remove evil spirits

    # reply-to
    my $replyto = $xmlobj->child('replyto') ? $xmlobj->child('replyto')->value : '';
    $replyto ||= VSAP::Server::Modules::vsap::mail::autoreply::_get_default_reply_to($vsap, $user);

    # message body
    my $messagetext = $xmlobj->child('message') ? $xmlobj->child('message')->value : '';
    unless ($messagetext) {
        $vsap->error($_ERR{'AUTOREPLY_MESSAGE_EMPTY'} => $_ERR_MSG{'AUTOREPLY_MESSAGE_EMPTY'});
        return;
    }
    my $enc_messagetext = Encode::encode_utf8($messagetext);
    Encode::from_to($enc_messagetext, "UTF-8", $encoding);

    # interval
    my $interval = $xmlobj->child('interval') ? $xmlobj->child('interval')->value : $_DEFAULTS{'interval'};

    # save the settings
    my %settings = ();
    $settings{'encoding'} = $encoding;
    $settings{'subject'} = $subject;
    $settings{'enc_subject'} = $enc_subject;
    $settings{'from'} = $replyto;
    $settings{'body'} = $messagetext;
    $settings{'enc_body'} = $enc_messagetext;
    $settings{'interval'} = $interval;
    ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_save_settings($user, %settings);
    if (defined($_ERR{$err})) {
        $vsap->error($_ERR{$err} => $str);
        return;
    }

    # save the status
    ($err, $str) = VSAP::Server::Modules::vsap::mail::autoreply::_save_status($user, "on");
    if (defined($_ERR{$err})) {
        $vsap->error($_ERR{$err} => $str);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled autoreply for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:autoreply:enable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# autoreply::status
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::autoreply::status;

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
            $vsap->error($_ERR{'AUTH_FAILED'} => $_ERR_MSG{'AUTH_FAILED'});
            return;
        }
    }

    # establish some defaults
    my $replyto = VSAP::Server::Modules::vsap::mail::autoreply::_get_default_reply_to($vsap, $user);
    $_DEFAULTS{'from'} = $replyto;

    # get the settings
    my %settings = VSAP::Server::Modules::vsap::mail::autoreply::_get_settings($user);

    # get the status
    my $status = VSAP::Server::Modules::vsap::mail::autoreply::_get_status($user);

    # need to return:
    #   <vsap type="mail:autoreply:status">
    #     <status>(on|off)</status>
    #     <interval>integer</interval>
    #     <subject>string</replyto>
    #     <replyto>email@address</replyto>
    #     <message>text</message>
    #   </vsap>

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:autoreply:status');
    $root_node->appendTextChild(user => $user);
    $root_node->appendTextChild(status => $status);
    $root_node->appendTextChild(encoding => $settings{'encoding'});
    $root_node->appendTextChild(interval => $settings{'interval'});
    $root_node->appendTextChild(subject => $settings{'subject'});
    $root_node->appendTextChild(replyto => $settings{'from'});
    $root_node->appendTextChild(message => $settings{'body'});

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail::autoreply - VSAP module to configure an
autoresponder for incoming e-mail messages

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::autoreply;

=head1 DESCRIPTION

The VSAP autoreply mail module allows users (and administrators) to 
configure an autoresponder for incoming e-mail messages.  The 
autoresponder will operate in two different modes: a pure autoreply mode 
and a vacation mode.  The operational mode is dependent on the users 
preference for the reply interval (see below).  

=head2 mail:autoreply:disable

The disable method changes the status of the autoresponder to inactive.
The method will also accept any autoresponder options (message text, 
reply interval) and update the options as part of the disable request.
Specifying autoreply options as part of an autoreply disable request is 
not required.

The following template represents the generic form of a disable query:

    <vsap type="mail:autoreply:disable">
        <user>user name</user>
        <message>text</message>
        <interval>integer value</interval>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are disabling the autoresponder functionality 
on behalf of the enduser.

The message text (if defined) is presumed to represent the message that
will be returned to any incoming e-mail message (when the autoreply
feature is re-enabled).  The message text may contain e-mail headers
(such as a subject header) separated from the body of the message by a
single blank line.

The reply interval (if defined) must be an integer value and represents 
the number of days in which an incoming e-mail address will receive an 
autoreply.  If the reply interval (which is specified in number of days) 
is non-zero, then the autoresponder operates in a vacation mode and will 
only send out one response per incoming e-mail address per interval.  
For example, if the interval value is set to '7', then each incoming 
e-mail address encountered will only receive, at most, one response per 
week.  If the interval is zero (or negative), the autoresponder will 
operate in a pure autoreply mode and send a response to every incoming 
e-mail message.

If the disable request is successful, a status node with a value of 'ok' 
is returned.  An error is returned if the request could not be completed.

=head2 mail:autoreply:enable

The enable method changes the status of the autoresponder to active.
The method will also accept any autoresponder options (message text, 
reply interval) and update the options as part of the enable request.
When enabling the autoresponder, the text of the outgoing message is
required.

The following template represents the generic form of a enable query:

    <vsap type="mail:autoreply:enable">
        <user>user name</user>
        <message>text</message>
        <interval>integer value</interval>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are enabling the autoresponder functionality 
on behalf of the enduser.

The message text is presumed to represent the message that will be 
returned to any incoming e-mail message.  The message text may contain 
e-mail headers (such as a subject header) separated from the body of the 
message by a single blank line.

The reply interval (if defined) must be an integer value and represents 
the number of days in which an incoming e-mail address will receive an 
autoreply.  If the reply interval (which is specified in number of days) 
is non-zero, then the autoresponder operates in a vacation mode and will 
only send out one response per incoming e-mail address per interval.  
For example, if the interval value is set to '7', then each incoming 
e-mail address encountered will only receive, at most, one response per 
week.  If the interval is zero (or negative), the autoresponder will 
operate in a pure autoreply mode and send a response to every incoming 
e-mail message.

If the enable request is successful, a status node with a value of 'ok' 
is returned.  An error is returned if the request could not be completed.

=head2 mail:autoreply:status

The status method can be used to get the properties of the current 
autoresponder configuration.

The following template represents the generic form of a status query:

    <vsap type="mail:autoreply:status">
        <user>user name</user>
        <message>text</message>
        <interval>integer value</interval>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are inquiring after the status of the
autoresponder functionality on behalf of an enduser.

If the status query is successful, then the autoresponder status, 
autoresponder message text, and autoresponder reply interval will all
be returned.  For example:

    <vsap type="mail:autoreply:status">
        <user>user name</user>
        <status>on|off</status>
        <message>text</message>
        <interval>integer value</interval>
    </vsap>

=head1 SEE ALSO

L<autoreply(1)>, L<vacation(1)>

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
