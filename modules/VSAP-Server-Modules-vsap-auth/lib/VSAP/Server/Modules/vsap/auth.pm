package VSAP::Server::Modules::vsap::auth;

use 5.006001;
use strict;
use warnings;

use Authen::PAM;
use Crypt::CBC;
use Cwd qw(abs_path);

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our $NO_AUTH = 1;
our $DEBUG   = 0;
our $TIMEOUT = 3600;

our %_ERR = ( AUTH_INVALID         => 100,
              AUTH_EXPIRED         => 101,
              AUTH_NOROOT          => 102,
              AUTH_KEYFILE         => 103,
              AUTH_HOMEGONE        => 104,
              AUTH_HOMEPERM        => 105,
              AUTH_RESTART_REQD    => 200,
            );

##############################################################################

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    my $username  = ( $xmlobj->child('username')
                      ? $xmlobj->child('username')->value
                      : '' );
    my $password  = ( $xmlobj->child('password')
                      ? $xmlobj->child('password')->value
                      : '' );
    my $hostname  = ( $xmlobj->child('hostname') && $xmlobj->child('hostname')->value
                      ? $xmlobj->child('hostname')->value
                      : 'localhost' );
    my $sess_key  = ( $xmlobj->child('sessionkey')
                      ? $xmlobj->child('sessionkey')->value
                      : '' );

    ## be root, then be nobody
    $> = 0;
    $> = 1;

    if ($sess_key) {
        loggy("(1.0) got session key: $sess_key");
        $username ||= $1 if $sess_key =~ s/^(.*)://;  ## only set $username if not already set
        loggy("(1.5) username from session key: $username");
    }

    ## convert e-mail login to username
    $username = get_login_from_email($username) if ($username =~ /\@/);

    ## split out auth/authz
    my( $authname, $authzname ) = split(':', $username, 2);
    $authzname = $authname unless $authzname;
    $username = $authzname;

    ## no public access; this is different than Signature
    unless ($username) {
        $vsap->error($_ERR{AUTH_INVALID} => "Username required");
        return;
    }

    ## quick sanity check
    unless (getpwnam($authname) && getpwnam($authzname)) {
        $vsap->error( $_ERR{AUTH_INVALID} => "Login invalid" );
        return;
    }

    ## BUG05098: make sure the home directory exists
    unless (-d (getpwnam($username))[7]) {
        $vsap->error($_ERR{AUTH_HOMEGONE} => "Home directory missing");
        return;
    }

    ## BUG09218: make sure the home directory is accessible
  CHECK_HOMEDIR_ACCESS: {
        local $> = getpwnam($username);
        unless (-r (getpwnam($username))[7] && -w _ && -x _) {
            $vsap->error($_ERR{AUTH_HOMEPERM} => "Home directory inaccessible");
            return;
        }
    }

    ## create a cipher object if necessary
    unless ($vsap->{_cipher}) {
        $vsap->{_cipher} = get_cipher($vsap, $username)
          or return;
    }

    ## if $authname ne $authzname, then $authname must be an SA or
    ## $authzname's DA or $authzname's MA
  CHECK_AUTH: {
        ## auth is me
        last CHECK_AUTH if $authname eq $authzname;

        ## auth is an SA
        last CHECK_AUTH if grep { $_ eq $authname } split(' ', (getgrnam('wheel'))[3]);

        ## auth is authz's DA
        my $co = new VSAP::Server::Modules::vsap::config( username => $authname );
        last CHECK_AUTH if $co->domain_admin( user => $authzname );

        ## auth is authz's MA
        if ($co->mail_admin) {
            my $user_domain = $co->user_domain($authname);
            my @authuserlist = keys %{$co->users(domain => $user_domain)};
            if ( (grep(/^$authzname$/, @authuserlist)) && 
                 (!($co->domain_admin(admin => $authzname))) &&  ## mail admin cannot auth as domain admin
                 (!($co->mail_admin(admin => $authzname))) ) {   ## mail admin cannot auth as another mail admin

                last CHECK_AUTH;
            }
        }

        $vsap->error($_ERR{AUTH_INVALID} => "$authname is not authorized to become $authzname");
        return;
    }

    ###################################

    ## be root for the setuid (can't switch from one non-root user to another)
    $> = $) = 0;

    ## get euid from username and drop privileges
    $) = getgrnam($username);
    $> = getpwnam($username);

    ## have a session key
    if ( $sess_key ) {
        ($vsap->{username}, $vsap->{password}, $vsap->{logintime}) = decrypt_key($vsap, $sess_key);
        loggy("session: $sess_key");
        loggy("username:", $vsap->{username});
        loggy("password:", $vsap->{password});
        loggy("logintime:", $vsap->{logintime});

        ## load user prefs file
        my $prefs_file = (getpwuid($>))[7] . "/.cpx/user_preferences.xml";
        if ( -f $prefs_file && -r _ ) {
            open(PREFS, $prefs_file);
            my $prefs = join '', <PREFS>;
            close PREFS;
            my ($timeout) = ($prefs =~ /^\s*<logout>(.+)<\/logout>\s*$/mg);
            loggy("Should login as: $username");
            loggy("Got timeout pref for uid $> (", scalar(getpwuid($>)), "): $timeout hour\n");
            $TIMEOUT = ($timeout * 3600) if $timeout;
        }

        loggy("logintime:", $vsap->{logintime}, "; timeout: $TIMEOUT; time:", time);

        ## do session expiration
        if ( ! $vsap->{logintime} or ($vsap->{logintime} + $TIMEOUT < time)) {
            $vsap->error($_ERR{AUTH_EXPIRED} => "Session has expired");
            return;
        }

        $authzname = $vsap->{username};
        if ( $vsap->{password} ) {
            $vsap->{authenticated} = 1;  ## check for sending a bogus session key;
                                         ## does this get populated anyway?
        }

        ## populate server object here
        ## (not sure why or how this is minimal?)
    }

    ## no session key
    else {
        ##
        ## root privileges gained in this block
      AUTHENTICATE: {
            last AUTHENTICATE
                if ($vsap->{authenticated} && $vsap->{username} eq $authzname)
                    || $vsap->{preauthname} eq $authname;
            local $> = $) = 0;  ## regain privileges for a moment to authenticate
            unless (authenticate($authname, $password)) {
                # on Linux a bad auth may be due to a bad vroot-issued account reboot
                if ((POSIX::uname())[0] =~ /Linux/) {
                    ## BUG27096: check to see if recent reboot was clean
                    loggy("(2.0) checking config parse_file capability (username => $authname)");
                    my $co = new VSAP::Server::Modules::vsap::config( username => $authname );
                    unless (ref($co) && defined($co->{dom})) {
                        loggy("(2.5) could not parse dom from file (reboot required)");
                      FORK: {
                            my $pid;
                            if ($pid = fork) {
                                # parent
                                $vsap->error($_ERR{AUTH_RESTART_REQD} => "Service restart is required");
                                return;
                            }
                            elsif (defined $pid) {
                                # child
                              REWT: {
                                    local $> = $<;
                                    local $) = $( = 0;
                                    loggy("(2.6) restarting vsapd ( $> : $< ) ( $) : $( )");
                                    sleep(3);
                                    exec('/sbin/service vsapd restart');
                                }
                            }
                            else {
                                # fork failure
                                sleep(3);
                                redo FORK;
                            }
                        }
                    }
                }
                # bad login name and/or password
                $vsap->error($_ERR{AUTH_INVALID} => "Login failed.");
                return;
            }
            $vsap->{authenticated} = 1;
        }
        ## privileges drop again here
        ##

        ## populate server object here
        ## NOTE: $authzname might differ from $authname (which
        ## $password is associated with). This will cause sections of
        ## the CP that use the password to fail (e.g., webmail, which
        ## reauthenticates via IMAP).
        $vsap->{username} = $authzname;
        $vsap->{password} = $password;
    }
    $sess_key = $username . ':' . encrypt_key($vsap);
    loggy("Created new session key ($authzname): $sess_key\n");

    ## dbrian: I don't quite understand how this ever happened properly on
    ## Linux, other than the fact that $) gets non-zero values when vsapd
    ## is restarted. 

    ## disallow root/wheel logins; Linux OK
    unless( $> && ( $) || $vsap->is_linux() )  ) {
        ## set privs to uselessness
        $> = $) = 1;  ## daemon user
  
        $vsap->error($_ERR{WM_NOROOT} => "No root logins permitted");
        return;
    }

    ## NOTE: If this heuristic to determine server admin ever changes,
    ## NOTE: it will need to be changed in other locations as well
    ## NOTE: (e.g., user:list) to keep things in sync. Do grep for
    ## NOTE: 'getgrgid' in the CPX modules hierarchy for candidates.
    ## NOTE: (there is also an occurrence in FileTransfer.pm)

    ## Set the gid of wheel to 0 for FreeBSD and 10 for Linux
    my $gid = $vsap->is_linux() ? 10 : 0;
    my %admins = map { $_ => (getpwnam($_))[0] } split(' ', (getgrgid($gid))[3]);

    ##
    ## add other user variables
    ##
    $vsap->{uid}          = $>;
    $vsap->{gid}          = $);
    $vsap->{server_admin} = $admins{$vsap->{username}};
    $vsap->{hostname}     = $hostname;
    $vsap->{homedir}      = abs_path((getpwuid($>))[7]);
    $vsap->{cpxbase}      = $vsap->{homedir} . '/.cpx';
    $vsap->{tmpdir}       = $vsap->{homedir} . '/.cpx_tmp';


    ## FIXME: some of the above paths may also be found in
    ## ControlPanel/FileTransfer.pm. If you change their locations
    ## here, you should change them there also.

    ## check domains
    ## FIXME: server admin may login to any domain
    ## FIXME: domain admin may login to any domain they administer
    ## FIXME: end users may only login to their (1) domain

    ##
    ## add other login-time checks here
    ##

    ## make sure .cpx directory exists
    mkdir $vsap->{cpxbase}   unless -e $vsap->{cpxbase};  ## make base directory
    chmod 0700, $vsap->{cpxbase} if -d $vsap->{cpxbase};  ## make it private
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        chown $vsap->{uid}, (getpwuid($vsap->{uid}))[3], $vsap->{cpxbase} if -d $vsap->{cpxbase};
    }

    ## make sure .cpx_tmp exists
    mkdir $vsap->{tmpdir}   unless -e $vsap->{tmpdir};    ## make tmp directory
    chmod 0770, $vsap->{tmpdir} if -d $vsap->{tmpdir};    ## make it group writable


    ## make sure we give apache perms to read/write attachments
    my $www_gid = (getpwnam($VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP))[3];
    if ( ! -l $vsap->{tmpdir} && -d _ && ((stat(_))[5] != $www_gid) ) {
        local $> = $) = 0;  ## regain privileges for a moment
        chown -1, $www_gid, $vsap->{tmpdir};
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute('type' => 'auth');
    $root->appendTextChild('username' => $username);
    $root->appendTextChild('sessionkey' => $sess_key);
    $root->appendTextChild('platform' => lc($vsap->platform));
    $root->appendTextChild('distro' => lc($vsap->distro));
    $root->appendTextChild('product' => $vsap->product);
    $root->appendTextChild('release' => $vsap->release);
    $root->appendTextChild('version' => $vsap->version);
    
    ## do config stuff
    my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );
    if ( $co ) {
        my $domain_admin = $co->domain_admin;
        my $mail_admin = $co->mail_admin;
        my $site_prefs = $co->siteprefs;

        # services
        my $services_node = $dom->createElement('services');
        my @serv = keys %{ $co->services};
        for my $service ( @serv ) {
            next if ( $site_prefs->{'disable-shell'} && ($service eq "shell") );
            $services_node->appendTextChild($service => undef);
        }
        if ( !grep(/fileman/, @serv) && $vsap->{server_admin} ) {
            # always give fileman to server admin
            $services_node->appendTextChild('fileman' => undef);
        }
        $root->appendChild($services_node);
    
        # capabilities
        my $capabilities_node = $dom->createElement('capabilities');
        my @capa = keys %{ $co->capabilities};
        for my $capability ( @capa ) {
            next if ( $site_prefs->{'disable-shell'} && ($capability eq "shell") );
            $capabilities_node ->appendTextChild($capability => undef);
        }
        if ( !grep(/fileman/, @capa) && $vsap->{server_admin} ) {
            # always give fileman to server admin
            $capabilities_node ->appendTextChild('fileman' => undef);
        }
        $root->appendChild($capabilities_node);

        # do eu_capabilities (domain admin)
        if ( $domain_admin ) {
            my $eu_capabilities_node = $dom->createElement('eu_capabilities');
            for my $eu_capa ( keys %{ $co->eu_capabilities } ) {
                next if ( $mail_admin && ( $eu_capa ne "mail" ));
                next if ( $site_prefs->{'disable-shell'} && ($eu_capa eq "shell") );
                $eu_capabilities_node ->appendTextChild($eu_capa => undef);
            }
            $root->appendChild($eu_capabilities_node);
        }

        # do eu_capabilities (mail admin)
        if ( $mail_admin ) {
            my $eu_capabilities_node = $dom->createElement('eu_capabilities');
            my $user_domain = $co->user_domain($username);
            my $domains = $co->domains(domain => $user_domain);
            my $parent_admin = $domains->{$user_domain};  ## parent admin for mail admin
            if ( ( $vsap->is_linux() && ( $parent_admin eq "apache" ) ) || ( $parent_admin eq "www" ) ) {
                # parent admin is apache owner ... this is a mail admin for main hostname
                $eu_capabilities_node ->appendTextChild("mail" => undef);
            }
            else {
                # parent admin is a domain admin
                $co->init( username => $parent_admin );
                for my $eu_capa ( keys %{ $co->eu_capabilities } ) {
                    next if ( $eu_capa ne "mail" );
                    $eu_capabilities_node ->appendTextChild($eu_capa => undef);
                }
                $co->init( uid => $vsap->{uid}  );
            }
            $root->appendChild($eu_capabilities_node);
        }

        my $packages_node = $dom->createElement('packages');
        $packages_node ->appendTextChild($_ => undef) for keys %{ $co->packages};
        $root->appendChild($packages_node);

        my $siteprefs_node = $dom->createElement('siteprefs');
        $siteprefs_node ->appendTextChild($_ => undef) for keys %{ $site_prefs};
        $root->appendChild($siteprefs_node);

        $root->appendTextChild('domain_admin' => undef) if $vsap->{server_admin} || $domain_admin;
        $root->appendTextChild('mail_admin' => undef) if $vsap->{server_admin} || $mail_admin;
    }

    $root->appendTextChild('server_admin' => undef) if $vsap->{server_admin};

    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

sub loggy
{
    return unless $DEBUG;
    my $data = join('', @_);
    ($data) = $data =~ /(.*)/s;
    VSAP::Server::Modules::vsap::logger::log_debug($data);
}

##############################################################################

sub get_cipher
{
    my $vsap = shift;
    my $user = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    my $keypath = (getpwnam($user))[7] . '/.cpx_key';
    my $uid = getpwnam($user);

    local $> = $uid;    ## drop privileges while mucking with the key file

    my $key     = 0;

    loggy("(3.0) No cipher object: keypath: $keypath");

    ## read a key, if we have one
    if ( -e $keypath ) {
        unless( -f $keypath ) {
            $vsap->error($_ERR{AUTH_KEYFILE} => "Keyfile is not a regular file");
            return;
        }

        open KEY, $keypath
          or do {
              $vsap->error($_ERR{AUTH_KEYFILE} => "Could not read from keyfile: $!");
              return;
          };
        $key = <KEY>; chomp $key;  ## noam?

        ## NOTICE: We need to untaint this variable. This is a
        ## NOTICE: workaround to an incompatibility in Perl and
        ## NOTICE: Crypt::Rijndael that occurs after a uid/euid swap
        ## NOTICE: and swapback. A demonstration of the bug is located
        ## NOTICE: in CVS in the cpx README file. 
        ## NOTICE: The actual trigger (the setreuid) used to exist in
        ## NOTICE: webmail:send.pm but has since been removed, so ths
        ## NOTICE: untainting is no longer necessary, but it doesn't
        ## NOTICE: hurt to have it here (lest someone else does it).
        ($key) = $key =~ /(.*)/s;

        close KEY;
        loggy("(3.2) Reading key from existing key file: $key");
    }

    unless( $key ) {
        my @chars = map chr($_), (32..126);       ## printable ascii
        $key .= $chars[rand @chars] for (1..32);  ## count 'em: 32

        warn "Generated new key: '$key'\n" if $DEBUG;

        ## write the key file as root, then chown it.  this fixes the
        ## somewhat obscure error that occurs when a first time user
        ## logs into CPX that also happens to be over quota (BUG12812)

      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            ## write key back
            open KEY, ">$keypath"
              or do {
                  $vsap->error($_ERR{AUTH_KEYFILE} => "Could not write to keyfile ($keypath): $!");
                  return;
              };
            print KEY $key;
            close KEY;
            loggy("(3.4) Created a new key: $key");
            my $uid = getpwnam($user);
            my $gid = getgrnam($user);
            chown($uid, $gid, $keypath)
              or do {
                loggy("(3.E) chown($uid, $gid, $keypath) failed: $!");
              };
        }
    }

    return new Crypt::CBC($key, "Rijndael");
}

##############################################################################

sub authenticate
{
    my $username = shift;
    my $password = shift;

    my $pam = new Authen::PAM( 'login', $username,
                               sub {
                                   my @res;

                                   while( @_ ) {
                                       my $code = shift;
                                       my $msg  = shift;
                                       my $ans  = '';

                                       if ( $code == PAM_PROMPT_ECHO_ON() ) {
                                           $ans = $username;
                                       }
                                       elsif ( $code == PAM_PROMPT_ECHO_OFF() ) {
                                           $ans = $password;
                                       }

                                       push @res, (PAM_SUCCESS(), $ans);
                                   }
                                   push @res, PAM_SUCCESS();
                                   return @res;
                               } );

    unless (ref($pam)) {
        warn "Error code $pam during PAM init\n";
        return;
    }

    my $res = $pam->pam_authenticate;

    unless ($res == PAM_SUCCESS()) {
        ## authentication error
        warn "Other auth error: " . $pam->pam_strerror($res) . "($res)\n";
        return;
    }

    return 1;
}

##############################################################################

sub encrypt_key
{
    my $password = $_[0]->{password};
    $password =~ (s!\\!\\\\!g);  # make any \ into \\
    $password =~ (s!:!\\:!g);  # make any : into \:
    return $_[0]->{_cipher}->encrypt_hex( join '::', $_[0]->{username}, $password, time);
}

##############################################################################

sub decrypt_key
{
    my @results;
    if ( $_[0]->{_cipher}->decrypt_hex($_[1])  =~ m/(.+)::(.+)::(\d+)/ ) {
        push(@results, $1);
        push(@results, $2);
        push(@results, $3);
    }
   
    $results[1] =~ (s!\\\\!\\!g); # make double backslashes single back slashes. 
    $results[1] =~ (s!\\:!:!g); # turn \: into :
    return @results;
}

##############################################################################

sub get_login_from_email
{
    my $email = shift;
    my ($name, $domain) = split(/\@/, $email);

    my $login;
    my $virtmaps = VSAP::Server::Modules::vsap::mail::all_virtusertable();
    foreach my $virtmap (sort {$b cmp $a} (keys(%{$virtmaps}))) {
        my $virtmap_lhs = $virtmap;
        my $virtmap_rhs = $virtmaps->{$virtmap};
        if (($virtmap_lhs eq $email) || ($virtmap_lhs eq "\@$domain")) {
            ($login) = (split(/\@/, $virtmap_rhs))[0];
            return($login) if (getpwnam($login));
            my $alias_lhs = $virtmap_rhs;
            my $alias_rhs = VSAP::Server::Modules::vsap::mail::get_alias_rhs($alias_lhs);
            ($login) = (split(/\@/, $alias_rhs))[0];
            return($login) if (getpwnam($login));
            last if ($virtmap_lhs eq "\@$domain");
        }
    }
  
    # check aliases file 
    my $alias_rhs = VSAP::Server::Modules::vsap::mail::get_alias_rhs($email);
    ($login) = (split(/\@/, $alias_rhs))[0];
    return($login) if (getpwnam($login));

    # check name in e-mail address
    return($name) if (getpwnam($name));

    # no match
    $login = "";
    return($login);
}

##############################################################################
1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::auth - VSAP Control Panel authentication

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::auth;

=head1 DESCRIPTION

VSAP control panel authentication module.

## some login methods

1) normal login

  authzname
  authzpass

2) su login

  authname:authzname
  authpass

3) normal session key

  authzname:(authzname,authzpass,time)

4) su session key

  authzname:(authaname,authpass,time)

=head1 SEE ALSO

VSAP

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
