package VSAP::Server::Modules::vsap::mail::spamassassin;

use 5.008004;
use strict;
use warnings;
use Quota;

use VSAP::Server::Modules::vsap::diskspace qw(user_over_quota);
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail::helper;

require VSAP::Server::Modules::vsap::config;

##############################################################################

our $VERSION = '0.12';

# error codes and messages for this module
our %_ERR_CODE = %VSAP::Server::Modules::vsap::mail::helper::_ERR_CODE;
$_ERR_CODE{'SPAMASSASSIN_NOT_FOUND'} = 550;
$_ERR_CODE{'SPAMASSASSIN_SCORE_INVALID'} = 555;

# error codes and messages for this module
our %_ERR_MESG = %VSAP::Server::Modules::vsap::mail::helper::_ERR_MESG;
$_ERR_MESG{'SPAMASSASSIN_NOT_FOUND'} = 'spamassassin not installed';
$_ERR_MESG{'SPAMASSASSIN_SCORE_INVALID'} = 'spamassassin score invalid';

##############################################################################
#
# some default settings and user_prefs for spamassassin
#
##############################################################################

our %_DEFAULT_SETTINGS =
(
  logabstract                 => 'yes',
  logfile                     => '$HOME/log.spam',
  spamfolder                  => '$HOME/Mail/Junk',
);

if ( VSAP::Server::Modules::vsap::mail::helper::_is_installed_dovecot() ) {
    $_DEFAULT_SETTINGS{'spamfolder'} = '$HOME/Maildir/.Junk/';
}

our %_DEFAULT_USERPREFS =
(
  required_score              => 5,
);

##############################################################################
#
# skel
#
##############################################################################

our $SKEL_SPAMASSASSIN_RC = <<'_RCFILE_';
TMPLOGFILE=$LOGFILE
TMPLOGABSTRACT=$LOGABSTRACT
TMPVERBOSE=$VERBOSE

LOGFILE=__LOGFILE__
LOGABSTRACT=__LOGABSTRACT__
VERBOSE=no

## scan and tag
:0 fw
|__SPAMASSASSINPATH__ -U /var/run/spamd.sock

## deliver
:0:
* ^X-Spam-Status: Yes
__SPAMFOLDER__

LOGFILE=$TMPLOGFILE
LOGABSTRACT=$TMPLOGABSTRACT
VERBOSE=$TMPVERBOSE
_RCFILE_

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

sub _add_list_patterns
{
    my $user = shift;
    my %patterns = @_;

    # patterns hash should look something like:
    #   %patterns = (
    #                  'whitelist_from', '*@quuxfoo.com',
    #                  'whitelist_from', '*@fooquux.com',
    #                  'whitelist_to',   '*@foo.com',
    #                  'blacklist_from', '*@berrett.org',
    #                  'blacklist_from', '*@berrett.net',
    #               );

    # get old config from user_prefs
    my %userprefs = VSAP::Server::Modules::vsap::mail::spamassassin::_get_user_prefs($user);
    foreach my $type (keys(%patterns)) {
        foreach my $pattern (keys(%{$patterns{$type}})) {
            if ($pattern !~ /\@/) {
                # domain names must be prepended with a wildcard (BUG27353)
                $pattern = '*@' . $pattern
            }
            $userprefs{$type}->{$pattern} = "到!";
        }
    }

    # write new config to user_prefs file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_save_user_prefs($user, %userprefs);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _daemon_enabled
{
    my $enabled = 0;
    my $status = "";

    my $os = $^O;
    my $daemon_service = "/etc/rc.d/init.d/spamassassin";
    unless ($os eq 'linux') {
        # FreeBSD?
        $daemon_service = (-e "/usr/local/etc/rc.d/sa-spamd.sh") ?
                              "/usr/local/etc/rc.d/sa-spamd.sh" :
                              "/usr/local/etc/rc.d/sa-spamd";
    }

 REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $status = `$daemon_service status`;
    }
    $enabled = ($status =~ /is running/);

    return($enabled);
}

#-----------------------------------------------------------------------------

sub _get_config
{
    my $user = shift;

    my $config = "";
    my $home = (getpwnam($user))[7];
    my $path = "$home/.spamassassin/user_prefs";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(CFP, $path)) {
            local $/;
            $config = <CFP>;
            close CFP;
        }
    }
    return($config);
}

#-----------------------------------------------------------------------------

sub _get_path
{
    my $installbin = "/usr/local/bin";
    my $exec = "spamc";
    my $path = $installbin . "/" . $exec;
    return($path);
}

#-----------------------------------------------------------------------------

sub _get_settings
{
    my $user = shift;

    my %settings = ();
    %settings = %_DEFAULT_SETTINGS;

    my $home = (getpwnam($user))[7];
    my $path = "$home/.cpx/procmail/spamassassin.rc";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        if (open(RCFP, "$path")) {
            while (<RCFP>) {
                s/\s+$//;
                if (/^LOGABSTRACT=(.*)/) {
                    $settings{'logabstract'} = $1;
                }
                elsif (/^LOGFILE=(.*)/) {
                    $settings{'logfile'} = $1;
                }
                elsif (/^\* \^X-Spam-Status: Yes/) {
                    $settings{'spamfolder'} = <RCFP>;
                    $settings{'spamfolder'} =~ s/^\s+//;
                    $settings{'spamfolder'} =~ s/\s+$//;
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
            # scan for 'INCLUDERC=$CPXDIR/spamassassin.rc'
            while (<RCFP>) {
                s/\s+$//;
                if (m!^(#)?INCLUDERC=\$CPXDIR/spamassassin.rc!) {
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

sub _get_user_prefs
{
    my $user = shift;

    require Mail::SpamAssassin;

    my %userprefs = ();
    %userprefs = %_DEFAULT_USERPREFS;

  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        my $sa = Mail::SpamAssassin->new( { username => $user } );
        $sa->init(1);
        $userprefs{'required_score'} = $sa->{'conf'}->{'required_score'};
        %{$userprefs{'whitelist_from'}} = %{$sa->{'conf'}->{'whitelist_from'}};
        %{$userprefs{'blacklist_from'}} = %{$sa->{'conf'}->{'blacklist_from'}};
        %{$userprefs{'whitelist_to'}} = %{$sa->{'conf'}->{'whitelist_to'}};
        %{$userprefs{'blacklist_to'}} = %{$sa->{'conf'}->{'blacklist_to'}};
        $sa->finish();
        undef($sa);
    }
    return(%userprefs);
}

#-----------------------------------------------------------------------------

sub _get_version
{
  my $version = "???";
  my $sapath = (-e "/usr/local/bin/spamassassin" ? "/usr/local/bin/spamassassin" : "/usr/bin/spamassassin");

  return $version unless (-e $sapath);

  if (open(PIPE, "$sapath -V |")) {
      my $output = <PIPE>;
      close(PIPE);
      chomp($output);
      if ($output =~ /spamassassin version (.*)/i) {
          $version = $1;
      }
  }
  return($version);
}

#-----------------------------------------------------------------------------

sub _init
{
    my $user = shift;

    # check to see if some useful directories exist
    my $home = (getpwnam($user))[7];
    my @paths = ("$home/.cpx", "$home/.cpx/procmail", "$home/.spamassassin");
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily
        foreach my $path (@paths) {
            unless (-e "$path") {
                unless (mkdir("$path", 0700)) {
                    return('MKDIR_FAILED', "$_ERR_MESG{'MKDIR_FAILED'} ... $path : $!");
                }
            }
            my($uid, $gid) = (getpwnam($user))[2,3];
            chown($uid, $gid, $path);
        }
    }

    # make sure CPX recipe block is found in helper file (.procmailrc)
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::helper::_init($user);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # init files specific to spamassassin if not found
    unless (-e "$home/.cpx/procmail/spamassassin.rc") {
        ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_write_includerc($user);
        return($code, $mesg) if (defined($_ERR_CODE{$code}));
    }

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _is_installed_globally
{
    my $os = $^O;

    my $egrep = '/bin/egrep';          ## default on linux
    my $pmrc = '/etc/procmailrc';      ## default on linux
    if( $os eq 'freebsd' ) {
        $egrep = '/usr/bin/egrep';
        $pmrc = "/usr/local/etc/procmailrc";
    }

    ## careful that this stays up to date with spamassassin.vinstall!
    return 1 if( !system( $egrep, '-iqs', '## begin spamassassin vinstall', $pmrc ) );
    return 0;
}

#-----------------------------------------------------------------------------

sub _remove_list_patterns
{
    my $user = shift;
    my %patterns = @_;

    # patterns hash should look something like:
    #   %patterns = (
    #                  'whitelist_from', 'quuxfoo.com',
    #                  'whitelist_from', 'fooquux.com',
    #                  'whitelist_to',   'foo.com',
    #                  'blacklist_from', 'berrett.org',
    #                  'blacklist_from', 'berrett.net',
    #               );

    # get old config from user_prefs
    my %userprefs = VSAP::Server::Modules::vsap::mail::spamassassin::_get_user_prefs($user);
    foreach my $type (keys(%patterns)) {
        my $okc = keys(%{$userprefs{$type}});
        foreach my $pattern (keys(%{$patterns{$type}})) {
            delete($userprefs{$type}->{$pattern});
        }
        # if original key count (okc) > 0 and current key count == 0; then
        # set flag to indicate that all of the current defs need to be wiped
        my $ckc = keys(%{$userprefs{$type}});
        if (($okc > 0) && ($ckc == 0)) {
            $userprefs{$type}->{'__DELETE_ME'} = "到!";
        }
    }

    # write new config to user_prefs file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_save_user_prefs($user, %userprefs);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_settings
{
    my $user = shift;
    my %settings = @_;

    # write new settings to includerc file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_write_includerc($user, %settings);
    return($code, $mesg) if (defined($_ERR_CODE{$code}));

    # return success
    return('SUCCESS', '');
}

#-----------------------------------------------------------------------------

sub _save_user_prefs
{
    my $user = shift;
    my %userprefs = @_;

    # write new settings to user_prefs file
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_write_user_prefs($user, %userprefs);
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
        # check global install status
        if ( VSAP::Server::Modules::vsap::mail::spamassassin::_is_installed_globally() ) {
            # return success
            return('SUCCESS', '');
        }
    }

    # write new status
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_write_status($user, $newstatus);
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
    foreach my $setting (keys(%_DEFAULT_SETTINGS)) {
        unless (defined($settings{$setting})) {
            $settings{$setting} = $_DEFAULT_SETTINGS{$setting};
        }
    }

    # build recipe from settings
    my $recipe = $SKEL_SPAMASSASSIN_RC;
    $recipe =~ s/__LOGFILE__/$settings{'logfile'}/;
    $recipe =~ s/__LOGABSTRACT__/$settings{'logabstract'}/;
    $recipe =~ s/__SPAMFOLDER__/$settings{'spamfolder'}/;
    my $sapath = VSAP::Server::Modules::vsap::mail::spamassassin::_get_path();
    $recipe =~ s/__SPAMASSASSINPATH__/$sapath/g;

    # write new recipe file
    my $home = (getpwnam($user))[7];
    my $path = "$home/.cpx/procmail/spamassassin.rc";
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
            if (m!^(#)?(INCLUDERC=\$CPXDIR/spamassassin.rc)!) {
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

#-----------------------------------------------------------------------------

sub _write_user_prefs
{
    my $user = shift;
    my %userprefs = @_;

    # check user's quota... be sure there is enough room for writing
    unless (VSAP::Server::Modules::vsap::diskspace::user_over_quota($user)) {
        # not good
        return('QUOTA_EXCEEDED', $_ERR_MESG{'QUOTA_EXCEEDED'});
    }

    # get currently existing user_prefs from file
    my $config = VSAP::Server::Modules::vsap::mail::spamassassin::_get_config($user);

    # swap out old prefs in config for the new ones
    if (defined($userprefs{'required_score'})) {
        $config =~ s/^required_(hits|score) .*\n//igm;
        unless ($config =~ s/(^#*\s*required_(hits|score).*?\n)/$1required_score $userprefs{'required_score'}\n/im) {
            $config .= "required_score $userprefs{'required_score'}\n";
        }
    }
    if (keys(%{$userprefs{'blacklist_to'}})) {
        $config =~ s/^blacklist_to .*\n//igm;
        my $blacklist = "";
        foreach my $entry (keys(%{$userprefs{'blacklist_to'}})) {
            next if ($entry eq "__DELETE_ME");
            $blacklist .= "blacklist_to $entry\n";
        }
        if ($blacklist ne "") {
        # try and insert after '# whitelist_from' comment
        unless ($config =~ s/(^#*\s*whitelist_from.*?\n)/$1$blacklist/im) {
            # just append to the end of the config file
            $config .= "$blacklist";
        }
        }
    }
    if (keys(%{$userprefs{'blacklist_from'}})) {
        $config =~ s/^blacklist_from .*\n//igm;
        my $blacklist = "";
        foreach my $entry (keys(%{$userprefs{'blacklist_from'}})) {
            next if ($entry eq "__DELETE_ME");
            $blacklist .= "blacklist_from $entry\n";
        }
        if ($blacklist ne "") {
            # try and insert after '# whitelist_from' comment
            unless ($config =~ s/(^#*\s*whitelist_from.*?\n)/$1$blacklist/im) {
                # just append to the end of the config file
                $config .= "$blacklist";
            }
        }
    }
    if (keys(%{$userprefs{'whitelist_to'}})) {
        $config =~ s/^whitelist_to .*\n//igm;
        my $whitelist = "";
        foreach my $entry (keys(%{$userprefs{'whitelist_to'}})) {
            next if ($entry eq "__DELETE_ME");
            $whitelist .= "whitelist_to $entry\n";
        }
        if ($whitelist ne "") {
            # try and insert after '# whitelist_from' comment
            unless ($config =~ s/(^#*\s*whitelist_from.*?\n)/$1$whitelist/im) {
                # just append to the end of the config file
                $config .= "$whitelist";
            }
        }
    }
    if (keys(%{$userprefs{'whitelist_from'}})) {
        $config =~ s/^whitelist_from .*\n//igm;
        my $whitelist = "";
        foreach my $entry (keys(%{$userprefs{'whitelist_from'}})) {
            next if ($entry eq "__DELETE_ME");
            $whitelist .= "whitelist_from $entry\n";
        }
        if ($whitelist ne "") {
            # try and insert after '# whitelist_from' comment
            unless ($config =~ s/(^#*\s*whitelist_from.*?\n)/$1$whitelist/im) {
                # just append to the end of the config file
                $config .= "$whitelist";
            }
        }
    }

    # write new config to file
    my $home = (getpwnam($user))[7];
    my $path = "$home/.spamassassin/user_prefs";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        my $newpath = "$path.$$";
        unless (open(RCFP, ">$newpath")) {
            # open failed... drat!
            return('OPEN_FAILED', "$_ERR_MESG{'OPEN_FAILED'} ... $newpath : $!");
        }
        unless (print RCFP $config) {
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
# spamassassin::add_patterns
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::add_patterns;

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

    my %additions = ();

    if ($xmlobj->child('whitelist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_from');
        foreach my $pattern (@patterns) {
          $additions{'whitelist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('whitelist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_to');
        foreach my $pattern (@patterns) {
            $additions{'whitelist_to'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_from');
        foreach my $pattern (@patterns) {
            $additions{'blacklist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_to');
        foreach my $pattern (@patterns) {
            $additions{'blacklist_to'}->{$pattern} = "到!";
        }
    }

    if (keys(%additions)) {
        my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_add_list_patterns($user, %additions);
        if (defined($_ERR_CODE{$code})) {
            $vsap->error($_ERR_CODE{$code} => $mesg);
            return;
        }
    }

    # build the result
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:spamassassin:add_patterns');
    $root_node->appendTextChild(status => 'happy');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::disable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::disable;

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

    # disable the spamassassin service
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::nv_disable($user);
    if (defined($_ERR_CODE{$code})) {
        $vsap->error($_ERR_CODE{$code} => $mesg);
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled spamassassin for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:spamassassin:disable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::enable
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::enable;

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

    # enable the spamassassin service
    my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::nv_enable($user);
    if (defined($_ERR_CODE{$code})) {
        $vsap->error($_ERR_CODE{$code} => $mesg);
        return;
    }

    # create mailbox
    require VSAP::Server::Modules::vsap::webmail;
    my $wm = new VSAP::Server::Modules::vsap::webmail( $vsap->{username}, $vsap->{password}, 'readonly' );
    if (ref($wm)) {
        my $fold = $wm->folder_list;
        $wm->folder_create('Junk') unless $fold->{'Junk'};
    }

    # init spamassasin config for user
    require Mail::SpamAssassin;
    my $home = (getpwnam($user))[7];
    my $config = "$home/.spamassassin/user_prefs";
  EFFECTIVE: {
        local $> = $) = 0;  ## regain root privs temporarily to switch to another non-root user
        local $) = getgrnam($user);
        local $> = getpwnam($user);
        unless (-s "$config") {
            my $sa = Mail::SpamAssassin->new( { username => $user } );
            $sa->init(1);
            $sa->finish();
            undef($sa);
        }
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} enabled spamassassin for user '$user'");

    # build the result dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'mail:spamassassin:enable');
    $root_node->appendTextChild('user', $user);
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::globally_installed
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::globally_installed;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $global = 'no';
    if ( VSAP::Server::Modules::vsap::mail::spamassassin::_is_installed_globally() ) {
        $global = 'yes';
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:spamassassin:globally_installed');
    $root_node->appendTextChild(global => $global);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::remove_patterns
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::remove_patterns;

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

    my %subtractions = ();

    if ($xmlobj->child('whitelist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_from');
        foreach my $pattern (@patterns) {
          $subtractions{'whitelist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('whitelist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_to');
        foreach my $pattern (@patterns) {
            $subtractions{'whitelist_to'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_from');
        foreach my $pattern (@patterns) {
            $subtractions{'blacklist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_to');
        foreach my $pattern (@patterns) {
            $subtractions{'blacklist_to'}->{$pattern} = "到!";
        }
    }

    if (keys(%subtractions)) {
        my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_remove_list_patterns($user, %subtractions);
        if (defined($_ERR_CODE{$code})) {
            $vsap->error($_ERR_CODE{$code} => $mesg);
            return;
        }
    }

    # build the result
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:spamassassin:remove_patterns');
    $root_node->appendTextChild(status => 'happy');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::set_user_prefs
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::set_user_prefs;

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

    my %newprefs = ();

    if ($xmlobj->child('required_score')) {
      $newprefs{'required_score'} = $xmlobj->child('required_score')->value;
        if ($newprefs{'required_score'} =~ /[^0-9\.]/) {
            $vsap->error($_ERR_CODE{'SPAMASSASSIN_SCORE_INVALID'} => $_ERR_MESG{'SPAMASSASSIN_SCORE_INVALID'});
            return;
      }
    }
    if ($xmlobj->child('whitelist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_from');
        foreach my $pattern (@patterns) {
          $newprefs{'whitelist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('whitelist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('whitelist_to');
        foreach my $pattern (@patterns) {
            $newprefs{'whitelist_to'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_from')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_from');
        foreach my $pattern (@patterns) {
            $newprefs{'blacklist_from'}->{$pattern} = "到!";
        }
    }
    if ($xmlobj->child('blacklist_to')) {
        my @patterns = grep { $_ } map { $_->value } grep { $_ } $xmlobj->children('blacklist_to');
        foreach my $pattern (@patterns) {
            $newprefs{'blacklist_to'}->{$pattern} = "到!";
        }
    }

    if (keys(%newprefs)) {
        my ($code, $mesg) = VSAP::Server::Modules::vsap::mail::spamassassin::_save_user_prefs($user, %newprefs);
        if (defined($_ERR_CODE{$code})) {
            $vsap->error($_ERR_CODE{$code} => $mesg);
            return;
        }
    }

    # build the result
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:spamassassin:set_user_prefs');
    $root_node->appendTextChild(status => 'happy');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
#
# spamassassin::status
#
##############################################################################

package VSAP::Server::Modules::vsap::mail::spamassassin::status;

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

    my $status = VSAP::Server::Modules::vsap::mail::spamassassin::_get_status($user);
    my %settings = VSAP::Server::Modules::vsap::mail::spamassassin::_get_settings($user);
    my %userprefs = VSAP::Server::Modules::vsap::mail::spamassassin::_get_user_prefs($user);
    my $version = VSAP::Server::Modules::vsap::mail::spamassassin::_get_version();

    # disable SpamAssassin on user level if globally installed (BUG27354)
    if ( ($status eq "on") && VSAP::Server::Modules::vsap::mail::spamassassin::_is_installed_globally() ) {
        VSAP::Server::Modules::vsap::mail::spamassassin::nv_disable($user);
        $status = "off";
    }

    # build the result
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'mail:spamassassin:status');
    $root_node->appendTextChild(version => $version);
    $root_node->appendTextChild(status => $status);
    $root_node->appendTextChild(logabstract => $settings{'logabstract'});
    $root_node->appendTextChild(logfile => $settings{'logfile'});
    $root_node->appendTextChild(spamfolder => $settings{'spamfolder'});
    $root_node->appendTextChild(required_score => $userprefs{'required_score'});
    my %additions;     # placeholder to save corrected patterns (BUG27353)
    my %subtractions;  # placeholder to remove bad patterns (BUG27353)
    %subtractions = %additions = ();
    foreach my $key (sort(keys(%userprefs))) {
        if ($key =~ /^(black|white)/) {
            foreach my $entry (keys(%{$userprefs{$key}})) {
                # check whitelst and blacklist domain names for '*@' glob-style patterns (BUG27353)
                if ($entry !~ /\@/) {
                    # remove bad entry
                    $subtractions{$key}->{$entry} = "到!";
                    # add good entry in its place
                    $entry = '*@' . $entry;
                    $additions{$key}->{$entry} = "到!";
                }
                $root_node->appendTextChild($key => $entry);
            }
        }
    }

    # make any adjustments to the patterns as required (BUG27353)
    if (keys(%additions)) {
        VSAP::Server::Modules::vsap::mail::spamassassin::_add_list_patterns($user, %additions);
    }
    if (keys(%subtractions)) {
        VSAP::Server::Modules::vsap::mail::spamassassin::_remove_list_patterns($user, %subtractions);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail::spamassassin - VSAP extension for SpamAssassin(tm)

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::spamassassin;

=head1 DESCRIPTION

The VSAP spamassassin modules allows users (and administrators)  to
the configure SpamAssassin status, preferences, and settings.

=head2 mail:spamassassin:add_patterns

Use the add_patterns method to add patterns to any of the blacklists and
whitelists found in the SpamAssassin user_prefs file.  Supported list
types include 'whitelist_from', 'whitelist_to', 'blacklist_from', and
'blacklist_to'.  The following is an example of an add_patterns query:

    <vsap type="mail:spamassassin:add_patterns">
        <user>user name</user>
        <whitelist_from>pattern</whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <blacklist_from>pattern</blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <whitelist_to>pattern</whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <blacklist_to>pattern</whitelist_to>
        <blacklist_to>   .   </whitelist_to>
        <blacklist_to>   .   </whitelist_to>
    </vsap>

The optional user name can be specified by domain administrators and
server administrators that are adding patterns on behalf of an
enduser.

=head2 mail:spamassassin:disable

The disable method changes the SpamAssassin filtering status to inactive
status.  The following is an example of the disable query:

    <vsap type="mail:spamassassin:disable">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain administrator and
server administrators that are disabling the SpamAassassin
functionality on behalf of the enduser.

If the disable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:spamassassin:enable

The enable method changes the SpamAassassin filtering status to active.
The following is an example of the enable query:

    <vsap type="mail:spamassassin:enable">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain administrators and
server administrators that are enabling the SpamAssassin functionality
on behalf of the enduser.

If the enable request is successful, a status node with a value of 'ok'
is returned.  An error is returned if the request could not be
completed.

=head2 mail:spamassassin:remove_patterns

Use the remove_patterns method to remove patterns to any of the
blacklists and whitelists found in the SpamAssassin user_prefs file.
Supported list types include 'whitelist_from', 'whitelist_to',
'blacklist_from', and 'blacklist_to'.  The following is an example of
a remove_patterns query:

    <vsap type="mail:spamassassin:remove_patterns">
        <user>user name</user>
        <whitelist_from>pattern</whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <blacklist_from>pattern</blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <whitelist_to>pattern</whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <blacklist_to>pattern</whitelist_to>
        <blacklist_to>   .   </whitelist_to>
        <blacklist_to>   .   </whitelist_to>
    </vsap>

The optional user name can be specified by domain administrators and
server administrators that are removing patterns on behalf of an
enduser.

=head2 mail:spamassassin:set_user_prefs

The set_user_prefs method can be used to set SpamAssassin user
preferences including 'required_score', 'whitelist_from', 'whitelist_to',
'blacklist_from', and 'blacklist_to'.  The options specified in a
set_user_prefs query will replace whatever is currently in the user
preferences file.  If whitelist or blacklist pattern are specified,
then those patterns will replace whatever is found in the user_prefs
file.  Use the B<add_patterns> and B<remove_patterns> methods to add
and remove one or more patterns.

=head2 mail:spamassassin:status

The status method can be used to get the properties of the current state
of the SpamAssassin filtering system.

The following template represents the generic form of a status query:

    <vsap type="mail:spamassassin:status">
        <user>user name</user>
    </vsap>

The optional user name can be specified by domain and server
administrators interested in performing a query on the status of the
SpamAssassin filtering status of an enduser.

If the status query is successful, then the current state of the
SpamAssassin filtering engine will be returned.  Some settings and
user preferences will also be returned.  For example:

    <vsap type="mail:spamassassin:status">
        <status>on|off</status>
        <user>user name</user>
        <version>version #</version>
        <logfile>path to log file</logfile>
        <spamfolder>path to spam folder</spamfolder>
        <required_score>spam threshold #</required_score>
        <whitelist_from>pattern</whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <whitelist_from>   .   </whitelist_from>
        <blacklist_from>pattern</blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <blacklist_from>   .   </blacklist_from>
        <whitelist_to>pattern</whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <whitelist_to>   .   </whitelist_to>
        <blacklist_to>pattern</whitelist_to>
        <blacklist_to>   .   </whitelist_to>
        <blacklist_to>   .   </whitelist_to>
    </vsap>

=head1 SEE ALSO

L<http://www.spamassassin.org/>

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
