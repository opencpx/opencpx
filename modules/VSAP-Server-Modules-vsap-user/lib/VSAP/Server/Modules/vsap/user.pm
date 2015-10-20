package VSAP::Server::Modules::vsap::user;

use 5.008004;
use strict;
use warnings;

use Email::Valid;
use Quota;

use VSAP::Server::Base;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;
use VSAP::Server::Modules::vsap::mail::clamav;
use VSAP::Server::Modules::vsap::mail::spamassassin;

##############################################################################

our $VERSION = '0.12';

our %_ERR    = (
                 USER_NAME_MISSING                   => 100,
                 USER_REMOVE_ERR                     => 101,
                 USER_DOM_FAILED                     => 102,
                 USER_NAME_BOGUS                     => 103,
                 USER_DELETE_SELF                    => 104,
                 USER_PERMISSION                     => 105,
                 USER_ADD__FULLNAME_MISSING          => 200,
                 USER_ADD__FULLNAME_TOO_LONG         => 201,
                 USER_ADD__FULLNAME_BAD_CHARS        => 202,
                 USER_ADD__LOGIN_MISSING             => 203,
                 USER_ADD__LOGIN_TOO_LONG            => 204,
                 USER_ADD__LOGIN_BAD_CHARS           => 205,
                 USER_ADD__LOGIN_ERR                 => 206,
                 USER_ADD__PASSWORD_MISSING          => 207,
                 USER_ADD__PASSWORD_TOO_SHORT        => 208,
                 USER_ADD__PASSWORD_ALL_LETTERS      => 209,
                 USER_ADD__PASSWORD_ALL_NUMBERS      => 2091,
                 USER_ADD__PASSWORD_LOGIN_SAME       => 210,
                 USER_ADD__PASSWORD_MISMATCH         => 211,
                 USER_ADD__QUOTA_MISSING             => 212,
                 USER_ADD__QUOTA_NOT_ZERO            => 213,
                 USER_ADD__QUOTA_NOT_INTEGER         => 214,
                 USER_ADD__DOMAIN_MISSING            => 215,
                 USER_ADD__DOMAIN_INVALID            => 216,
                 USER_ADD__SERVICES_MISSING          => 217,
                 USER_ADD__SHELL_INVALID             => 218,
                 USER_ADD__CAPA_MISSING              => 219,
                 USER_ADD__CAPA_INVALID              => 220,
                 USER_ADD__EU_QUOTA_EXCEEDED         => 221,
                 USER_ADD__EU_UNKNOWN_DOMAIN         => 222,
                 USER_ADD__EU_SERVICE_VERBOTEN       => 223,
                 USER_ADD__EU_VADDUSER_ERROR         => 224,
                 USER_ADD__LOGIN_EXISTS              => 225,
                 USER_ADD__QUOTA_OUT_OF_BOUNDS       => 226,
                 USER_ADD__QUOTA_ALLOCATION_FAILURE  => 227,
                 USER_ADD__HOME_DIR_EXISTS           => 228,
                 USER_ADD__EMAIL_PREFIX_INVALID      => 229,
                 EU_PREFIX_TOO_LONG                  => 230,
                 EU_PREFIX_BAD_CHARS                 => 231,
                 EU_PREFIX_ERR                       => 232,
                 EU_PREFIX_DUPLICATE                 => 233,
                 USER_REMOVE__THRESHOLD_EXCEEDED     => 250,
               );

our $FTPUSERS = '/etc/vsftpd/ftpusers';

our $APACHE_ADMIN = $VSAP::Server::Modules::vsap::globals::APACHE_RUN_USER;
our $APACHE_CONFIG = $VSAP::Server::Modules::vsap::globals::APACHE_CONF;

our $IS_LINUX = $VSAP::Server::Modules::vsap::globals::IS_LINUX;

our $DEBUG = 1;

##############################################################################

sub _adduser
{
    my($vsap, $login, $group, $fullname, $crypted, $quota, $homedir, $services, $shell) = @_;

    local $> = $) = 0;  ## regain privileges for a moment

    # Set groups from enabled services
    my $groups = '';
    $groups .= 'mailgrp,' if $services =~ /--mail=y/;
    $groups .= 'ftp,' if $services =~ /--ftp=y/;
    chop $groups;

    # Make sure the shell is valid.
    # Don't complain if it isn't - just set it to nologin
    my %shells;
    open my $sh, '/etc/shells';
    while(<$sh>) {
        chomp;
        $shells{$1} = 1 if m=^(/.*[^/])$=;
    }
    close $sh;
    grep $shells{$_} = 1, qw(/bin/sh /bin/bash) unless %shells;

    if (!exists $shells{$shell}) {
        foreach my $shl (keys %shells) {
            if ($shl =~ /$shell$/) {
                $shell = $shl;
                last;
            }
        }
        $shell = '/sbin/nologin' if !exists $shells{$shell};
    }

    # Actually add the user
    my @cmd = ();
    if ($IS_LINUX) {
        # Linux useradd
        push @cmd, '/usr/sbin/useradd';
        push @cmd, '-m';
        push @cmd, '-d', $homedir;
        push @cmd, '-g', $group if $group;
        push @cmd, '-G', $groups if $groups;
        push @cmd, '-p', $crypted;
        push @cmd, '-c', $fullname;
        push @cmd, '-s', $shell;
        push @cmd, $login;
    }
    else {
        # FIXME: FreeBSD
    }
    if (system(@cmd) != 0) {
        VSAP::Server::Modules::vsap::logger::log_error("useradd command: @cmd");
        return;
    }

    chmod 0755, $homedir;
    my($uid, $gid) = (stat $homedir)[4,5];

    # Create mail folder for user for future use
    my $mailfolder = $homedir . "/Maildir";
    mkdir($mailfolder, 0700);
    chown $uid, $gid, $mailfolder;

    # Set the quota
    my $kquota = $quota * 1024;
    my $dev = Quota::getqcarg('/home');
    Quota::setqlim($dev, $uid, $kquota, $kquota, 0, 0, 0, 0);
    Quota::sync($dev);

    # Add possible ftp restriction
    if ($services !~ /--ftp=y/) {
        open my $fu, '>>', $FTPUSERS;
        print $fu "$login\n";
        close $fu;
    }
    return 1;
}

#----------------------------------------------------------------------------#

sub _change_fullname
{
    my($vsap, $user, $fullname) = @_;

    local $> = $) = 0;  ## regain privileges for a moment
    if ($IS_LINUX) {
        open my $so, '>&STDOUT';
        open STDOUT, '>/dev/null';
        system('/usr/bin/chfn', '-f', $fullname, $user);
        open STDOUT, '>&', $so;
        close $so;
    }
    else {
        ## FIXME: FreeBSD
    }
}

#----------------------------------------------------------------------------#

sub _check_auth
{
    my $vsap   = shift;
    my $co     = shift;
    my $admin  = shift;
    my $domain = shift;
    my $user   = shift;

    my @users = ();

  AUTHZ: {
        ## we are server admin: do whatever we want
        if ($vsap->{server_admin}) {
            @users = ( $domain
                       ? keys %{$co->users(domain => $domain)}
                       : ( $admin
                           ? keys %{$co->users(admin => $admin)}
                           : ( $user
                               ? $user
                               : keys %{$co->users} ) ) );

            ## if admin provided, push admin (if necessary)
            push (@users, $admin) if ($admin && (!grep(/^$admin$/, @users)));

            ## if domain provided, push domain admin (if necessary)
            if ($domain && !$admin) {
                my $domains = $co->domains(domain=>$domain);
                push(@users,$domains->{$domain}) unless (grep(/^$domains->{$domain}$/, @users));
            }

            ## may select a da for a domain which administered by different da
            if ($domain && $admin) {
                my $domains = $co->domains(domain=>$domain);
                if ($domains->{$domain} ne $admin) {
                    @users = ();
                }
            }
            last AUTHZ;
        }

        ## we are domain admin of this domain: list users of this domain
        ## (this will be covered soon in the xsl with javascript limiting filter choices)
        if ( $domain && $co->domain_admin(domain => $domain) ) {
            @users = keys %{$co->users(domain => $domain)};
            ## need to push domain admin on as user because da admin may be in
            ## the primary server and would otherwise not appear in user list
            push (@users, $vsap->{username}) if (!grep(/^$vsap->{username}$/, @users));
            last AUTHZ;
        }

        ## we are mail admin of this domain: list users of this domain
        if ($domain && $co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            if ($user_domain eq $domain) {
                @users = keys %{$co->users(domain => $user_domain)};
                ## need to push domain admin on as user because da admin may be in
                ## the primary server and would otherwise not appear in user list
                my $domains = $co->domains(domain => $user_domain);
                my $da = $domains->{$user_domain};
                push (@users, $da) if (!grep(/^$da$/, @users));
                last AUTHZ;
            }
            else {
                $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
                return;
            }
        }

        ## $user is one of domain admin's users
        if ( $user && $co->domain_admin(user => $user) ) {
            @users = ($user);
            last AUTHZ;
        }

        ## $user is one of mail admin's end users
        if ($user && $co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            my @authuserlist = keys %{$co->users(domain => $user_domain)};
            if ((grep(/^$user$/, @authuserlist))) {
                push (@users, $user);
                last AUTHZ;
            }
            else {
                $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
                return;
            }
        }

        ## user is a domain admin, but no args supplied
        if ($co->domain_admin) {
            foreach my $ldomain (keys %{$co->domains(admin => $vsap->{username})}) {
                push(@users,keys %{$co->users(domain => $ldomain)});
            }
            ## need to push domain admin on as user because da admin may be in
            ## the primary server and would otherwise not appear in user list
            push (@users, $vsap->{username}) if (!grep(/^$vsap->{username}$/, @users));
            last AUTHZ;
        }

        ## user is a mail admin, but no args supplied
        elsif ($co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            @users = keys %{$co->users(domain => $user_domain)};
            ## need to push domain admin on as user because da admin may be in
            ## the primary server and would otherwise not appear in user list
            my $domains = $co->domains(domain => $user_domain);
            my $da = $domains->{$user_domain};
            push (@users, $da) if (!grep(/^$da$/, @users));
            last AUTHZ;
        }

        ## user is an end-user, so just return self
        else {
            push @users, $vsap->{username};
            last AUTHZ;
        }

        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;

    }
    return @users;
}

#----------------------------------------------------------------------------#

sub _config_info
{
    my $user_node = shift;
    my $dom = shift;
    my $co = shift;
    my $user = shift;
    my $server_admin = shift;
    my $groups       = shift;

    ###########################
    ##
    ## this section takes about 20% of this subrs time

    $co->init( username => $user );

    my $domain_admin = $co->domain_admin;
    my $mail_admin = $co->mail_admin;

    my $fullname = $co->user_gecos($user);
    $user_node->appendTextChild( fullname => $fullname );
    my $comments = $co->comments;
    $user_node->appendTextChild( comments => $comments );
    if ($domain_admin || $mail_admin) {
        if ($mail_admin) {
            my $user_domain = $co->user_domain($user);
            my $domains = $co->domains(domain => $user_domain);
            my $parent_admin = $domains->{$user_domain};  ## domain admin for mail admin
            $co->init( username => $parent_admin );
        }
        my $eu_prefix = $co->eu_prefix;
        $user_node->appendTextChild( eu_prefix => $eu_prefix );
        if ($mail_admin) {
            $co->init( username => $user );
        }
    }
    my $domain = $co->domain;
    $user_node->appendTextChild( domain => $domain );
    $user_node->appendTextChild( status   => ($co->disabled ? 'disabled' : 'enabled') );
    $user_node->appendTextChild( usertype => ($server_admin ? 'sa'
                                              : ($domain_admin ? 'da'
                                              : ($mail_admin ? 'ma'
                                              : 'eu'))) );

    ##
    ###########################

    ## calculate group quota and total quota
    my ($euu, $euq) = (0, 0);
    if ($domain_admin && !$server_admin) {
        my @ulist = keys %{$co->users(admin => $user)};
        foreach my $eu (@ulist) {
          REWT: {
              local $> = $) = 0;  ## regain privileges for a moment
              my $eu_uid = $co->user_uid($eu);
              my ($uu, $uq) = (Quota::query(Quota::getqcarg('/home'), $eu_uid))[0,1];
              $uu /= 1024 if $uu;
              $uq /= 1024 if $uq;
              $euu += $uu;
              $euq += $uq;
          }
        }
        my $quota_node = $dom->createElement('end_user_quota');
        $quota_node->appendTextChild( usage => $euu );
        $quota_node->appendTextChild( limit => $euq );
        $quota_node->appendTextChild( units => 'MB'   );
        $user_node->appendChild( $quota_node );
    }

    ## get user capability information
    my $capa_node = $dom->createElement('capability');
    my $user_capabilities = $co->capabilities;
    for my $capa ( keys %{ $user_capabilities } ) {
        $capa_node->appendChild($dom->createElement($capa));
    }
    ## add system capability information
    unless ($user_capabilities->{'mail-clamav'}) {
        if ( VSAP::Server::Modules::vsap::mail::clamav::_is_installed_milter() ) {
            $capa_node->appendChild($dom->createElement('mail-clamav'));
        }
    }
    unless ($user_capabilities->{'mail-spamassassin'}) {
        if ( VSAP::Server::Modules::vsap::mail::spamassassin::_is_installed_globally() ) {
            $capa_node->appendChild($dom->createElement('mail-spamassassin'));
        }
    }
    $user_node->appendChild($capa_node);

    ## get enduser capability information
    if ($domain_admin || $mail_admin) {
        my $eu_capa_node = $dom->createElement('eu_capability');
        if ($mail_admin) {
            my $user_domain = $co->user_domain($user);
            my $domains = $co->domains(domain => $user_domain);
            my $parent_admin = $domains->{$user_domain};  ## domain admin for mail admin
            $co->init( username => $parent_admin );
        }
        for my $eu_capa ( keys %{ $co->eu_capabilities } ) {
            next if ( $mail_admin && ( $eu_capa ne "mail" ));
            $eu_capa_node->appendChild($dom->createElement($eu_capa));
        }
        $user_node->appendChild($eu_capa_node);
        if ($mail_admin) {
            $co->init( username => $user );
        }
    }

    ## get current service information
    my $serv_node = $dom->createElement('services');
    for my $serv ( keys %{ $co->services } ) {
        $serv_node->appendChild($dom->createElement($serv));
    }
    $user_node->appendChild($serv_node);

    ##
    ## add domains for this SA/DA
    ##
    my %domains = ();
    if ($groups->{wheel}) {
        %domains = %{$co->domains};
    }
    elsif ($domain_admin) {
        %domains = %{$co->domains(admin => $user)};
    }

    if (keys %domains) {
        my $domains_node = $dom->createElement('domains');
        for my $domain ( keys %domains ) {
            my $d_node = $dom->createElement('domain');
            $d_node->appendTextChild( name  => $domain );
            $d_node->appendTextChild( admin => $domains{$domain} );
            $domains_node->appendChild($d_node);
        }
        $user_node->appendChild($domains_node);
    }
    return($euq, $euu);
}

#----------------------------------------------------------------------------#

sub _debug
{
    return unless $DEBUG;
    my $data = join('', @_);
    ($data) = $data =~ /(.*)/s;
    VSAP::Server::Modules::vsap::logger::log_debug($data);
}

#----------------------------------------------------------------------------#

sub _quota_node
{
    my $quota_node   = shift;
    my $uid          = shift;

    ## is quota defined for this user?
    my($usage, $quota, $grp_usage, $grp_quota) = (0, 0, 0, 0);
    my($gid) = (getpwuid($uid))[3];
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        ($usage, $quota) = (Quota::query(Quota::getqcarg('/home'), $uid))[0,1];
        ($grp_usage, $grp_quota) = (Quota::query(Quota::getqcarg('/home'), $gid, 1))[0,1];
        $usage /= 1024;  # convert to MB
        $quota /= 1024;  # convert to MB
        $grp_usage /= 1024;  # convert to MB
        $grp_quota /= 1024;  # convert to MB
    }

    $quota_node->appendTextChild( usage => $usage );
    $quota_node->appendTextChild( limit => $quota );
    $quota_node->appendTextChild( grp_usage => $grp_usage );
    $quota_node->appendTextChild( grp_limit => $grp_quota );
    $quota_node->appendTextChild( units => 'MB'   );

    return($quota, $usage, $grp_quota, $grp_usage);
}

#----------------------------------------------------------------------------#

sub _server_quota_node
{
    my $quota_node   = shift;

    ## calculate disk limits for server
    my( $total, $used, $percent );

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment

        system('sync');  ## commit any outstanding soft updates

        my $df;
        local $_;
        for (`df -P -m /home`) {
            chomp;
            next unless m!\d+\s+\d+\s+\d+\s+\d+%!;
            $df = $_;
            last;
        }
        $df = "0 0 0 0 0 0" unless $df;

        (undef, $total, $used, undef, $percent, undef) = split(' ', $df);
        $percent =~ s/%//g;

        $quota_node->appendTextChild( limit => $total );
        $quota_node->appendTextChild( usage => $used  );
        $quota_node->appendTextChild( units => 'MB'   );
    }

    return($total, $used);
}

#----------------------------------------------------------------------------#

sub _rmuser
{
    my($vsap, $user) = @_;

    local $> = $) = 0;  ## regain privileges for a moment
    if ($IS_LINUX) {
        return if system('/usr/sbin/userdel', '-r', $user) != 0;
        VSAP::Server::Modules::vsap::mail::genericstable(action => 'delete', user => $user);
        VSAP::Server::Modules::vsap::mail::delete_user($user);
        # Remove any ftp restriction
        my $fu;
        if (open $fu, $FTPUSERS) {
            my @lines = <$fu>;
            close $fu;
            if (grep /^$user$/, @lines) {
                open $fu, '>', $FTPUSERS;
                print $fu grep !/^$user$/, @lines;
                close $fu;
            }
        }
    }
    else {
        # FIXME: FreeBSD
    }
    return 1;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::add;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # load up the config for the user
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    # get the domain (required for authentication check)
    my $domain = "";
    my %domains = ();
    if ($xmlobj->child('da')) {
      # adding new domain admin
      $domain = ( $xmlobj->child('da')->child('domain') && $xmlobj->child('da')->child('domain')->value
                  ? $xmlobj->child('da')->child('domain')->value : '' );
      $domain =~ tr/A-Z/a-z/;
    }
    elsif ($xmlobj->child('eu')) {
      # adding new end user
      $domain = ( $xmlobj->child('eu')->child('domain') && $xmlobj->child('eu')->child('domain')->value
                  ? $xmlobj->child('eu')->child('domain')->value : '' );
      $domain =~ tr/A-Z/a-z/;
      # cannot add new end user to an unknown domain name
      %domains = %{ $co->domains };
      unless (defined($domains{$domain})) {
          $vsap->error( $_ERR{USER_ADD__EU_UNKNOWN_DOMAIN} => "unknown domain name: $domain" );
          return;
      }
    }

    # make sure *this* vsap user has permissions to add new user
    my $admin_type;
    CHECK_AUTHZ: {

        if ($vsap->{server_admin}) {
            $admin_type = "sa";
            last CHECK_AUTHZ;
        }

        if (($co->domain_admin || $co->mail_admin) && $domain && defined($domains{$domain})) {
            my $numusers = scalar grep { ! /^(?:$domains{$domain})$/ } keys %{$co->users( domain => $domain )};
            my $maxusers = $co->user_limit($domain);
            if (($maxusers eq 'unlimited') || (($numusers + 1) <= $maxusers )) {
                if ($co->domain_admin) {
                    $admin_type = "da";
                    last CHECK_AUTHZ;
                }
                else {
                    my $user_domain = $co->user_domain($vsap->{username});
                    if ($domain eq $user_domain) {
                        $admin_type = "ma";
                        last CHECK_AUTHZ;
                    }
                }
            }
        }

        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;
    }

    # fullname checks
    my $fullname = ( $xmlobj->child('fullname') && $xmlobj->child('fullname')->value
                     ? $xmlobj->child('fullname')->value : '' );
    if ($fullname eq '') {
        $vsap->error( $_ERR{USER_ADD__FULLNAME_MISSING} => "fullname cannot be empty" );
        return;
    }
    if (length($fullname) > 100) {
        $vsap->error( $_ERR{USER_ADD__FULLNAME_TOO_LONG} => "fullname must be 100 chars or shorter" );
        return;
    }
    if ($fullname =~ /:/) {
        $vsap->error( $_ERR{USER_ADD__FULLNAME_BAD_CHARS} => "fullname contains invalid characters" );
        return;
    }

    # comments checks
    my $comments = ( $xmlobj->child('comments') && $xmlobj->child('comments')->value
                     ? $xmlobj->child('comments')->value : '' );

    # login ID checks
    my $login_id = ( $xmlobj->child('login_id') && $xmlobj->child('login_id')->value
                     ? $xmlobj->child('login_id')->value : '' );
    unless ($login_id) {
        $vsap->error( $_ERR{USER_ADD__LOGIN_MISSING} => "login ID cannot be empty" );
        return;
    }
    if (length($login_id) > 16) {
        $vsap->error( $_ERR{USER_ADD__LOGIN_TOO_LONG} => "login ID must be 16 chars or shorter" );
        return;
    }

    if ($login_id =~ /[^a-z0-9_\.\-]/) {
        $vsap->error( $_ERR{USER_ADD__LOGIN_BAD_CHARS} => "login ID contains invalid characters" );
        return;
    }
    if ($login_id =~ /^[^a-z0-9_]/) {
        $vsap->error( $_ERR{USER_ADD__LOGIN_ERR} => "login ID begins with an invalid character" );
        return;
    }
    my $login_uid = getpwnam($login_id);
    if (defined($login_uid)) {
       $vsap->error( $_ERR{USER_ADD__LOGIN_EXISTS} => "User $login_id already exists" );
       return;
    }

    my $eu_prefix;
    if ($xmlobj->child('da')) {
        # eu prefix checks
        $eu_prefix = ( $xmlobj->child('eu_prefix') && $xmlobj->child('eu_prefix')->value
                       ? $xmlobj->child('eu_prefix')->value : '' );
        if (length($eu_prefix) > 10) {
            $vsap->error( $_ERR{EU_PREFIX_TOO_LONG} => "login prefix must be 10 chars or shorter" );
            return;
        }
        if ($eu_prefix =~ /[^a-z0-9_\.\-]/) {
            $vsap->error( $_ERR{EU_PREFIX_BAD_CHARS} => "login prefix contains invalid characters" );
            return;
        }
        if ($eu_prefix =~ /^[^a-z0-9_]/) {
            $vsap->error( $_ERR{EU_PREFIX_ERR} => "login prefix begins with an invalid character" );
            return;
        }
        # does eu_prefix already exist?
        my $duplicate = 0;
        my @prefix_list = @{$co->eu_prefix_list};
        foreach my $prefix (@prefix_list) {
          if ($prefix eq $eu_prefix) {
            $vsap->error( $_ERR{EU_PREFIX_DUPLICATE} => "login prefix already exists" );
            return;
          }
        }
    }

    # password checks
    my $password = ( $xmlobj->child('password') && $xmlobj->child('password')->value
                     ? $xmlobj->child('password')->value : '' );
    if ($password eq '') {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_MISSING} => "password cannot be empty" );
        return;
    }
    if (length($password) < 8) {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_TOO_SHORT} => "password cannot be less than 8 characters" );
        return;
    }
    if ($password !~ /[^a-zA-Z]/) {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_ALL_LETTERS} => "password must contain one non-letter character" );
        return;
    }
    if ($password !~ /[^0-9]/) {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_ALL_NUMBERS} => "password must contain one letter character" );
        return;
    }
    if ($password eq $login_id) {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_LOGIN_SAME} => "password cannot be same as login ID" );
        return;
    }
    my $confirm_password = ( $xmlobj->child('confirm_password') && $xmlobj->child('confirm_password')->value
                             ? $xmlobj->child('confirm_password')->value
                             : '' );
    if ($password ne $confirm_password) {
        $vsap->error( $_ERR{USER_ADD__PASSWORD_MISMATCH} => "password and confirm_password must match" );
        return;
    }

    # email checks
    my $lhs = ( $xmlobj->child('email_prefix') &&
                $xmlobj->child('email_prefix')->value
                ? $xmlobj->child('email_prefix')->value
                : '' );
    if ($lhs =~ /\@/) {
        $vsap->error( $_ERR{USER_ADD__EMAIL_PREFIX_INVALID} => "email prefix is invalid" );
        return;
    }
    my $dest = ($lhs || $login_id) . '@' . $domain;
    unless (Email::Valid->address( $dest )) {
        $vsap->error($_ERR{USER_ADD__EMAIL_PREFIX_INVALID} => "email prefix is badly formed");
        return;
    }

    # set up some vars for services, capabilities, and shell checks
    my $ftp_privs = 0;
    my $sftp_privs = 0;
    my $fileman_privs = 0;
    my $podcast_privs = 0;
    my $mail_privs = 0;
    my $webmail_privs = 0;
    my $shell_privs = 0;
    my $shell = "";
    my $capa_ftp = 0;
    my $capa_sftp = 0;
    my $capa_fileman = 0;
    my $capa_mail = 0;
    my $capa_shell = 0;
    my $capa_zeroquota = 0;
    if ($xmlobj->child('da')) {
        # adding new domain admin
        $ftp_privs = $xmlobj->child('da')->child('ftp_privs') ? 1 : 0;
        $sftp_privs = $xmlobj->child('da')->child('sftp_privs') ? 1 : 0;
        $fileman_privs = $xmlobj->child('da')->child('fileman_privs') ? 1 : 0;
        $podcast_privs = $xmlobj->child('da')->child('podcast_privs') ? 1 : 0;
        $mail_privs = $xmlobj->child('da')->child('mail_privs') ? 1 : 0;
        $webmail_privs = $xmlobj->child('da')->child('webmail_privs') ? 1 : 0;
        $shell_privs = $xmlobj->child('da')->child('shell_privs') ? 1 : 0;
        $shell = ( $xmlobj->child('da')->child('shell') && $xmlobj->child('da')->child('shell')->value
                 ? $xmlobj->child('da')->child('shell')->value : '' );
        $capa_ftp = $xmlobj->child('da')->child('eu_capa_ftp') ? 1 : 0;
        $capa_sftp = $xmlobj->child('da')->child('eu_capa_sftp') ? 1 : 0;
        $capa_fileman = $xmlobj->child('da')->child('eu_capa_fileman') ? 1 : 0;
        $capa_mail = $xmlobj->child('da')->child('eu_capa_mail') ? 1 : 0;
        $capa_shell = $xmlobj->child('da')->child('eu_capa_shell') ? 1 : 0;
        $capa_zeroquota = $xmlobj->child('da')->child('eu_capa_zeroquota') ? 1 : 0;
    }
    elsif ($xmlobj->child('eu')) {
        # adding new end user
        $ftp_privs = $xmlobj->child('eu')->child('ftp_privs') ? 1 : 0;
        $sftp_privs = $xmlobj->child('eu')->child('sftp_privs') ? 1 : 0;
        $fileman_privs = $xmlobj->child('eu')->child('fileman_privs') ? 1 : 0;
        $mail_privs = $xmlobj->child('eu')->child('mail_privs') ? 1 : 0;
        $webmail_privs = $xmlobj->child('eu')->child('webmail_privs') ? 1 : 0;
        $shell_privs = $xmlobj->child('eu')->child('shell_privs') ? 1 : 0;
        $shell = ( $xmlobj->child('eu')->child('shell') && $xmlobj->child('eu')->child('shell')->value
                   ? $xmlobj->child('eu')->child('shell')->value : '' );
        if (defined($xmlobj->child('mail_admin')) && $xmlobj->child('mail_admin')->value) {
            # mail admin must have mail privs (BUG25586)
            $mail_privs = 1;
        }
    }


    # domain checks
    if ($domain eq '') {
        $vsap->error( $_ERR{USER_ADD__DOMAIN_MISSING} => "domain cannot be empty" );
        return;
    }
    if ( $domain !~ m{^(((?!-)[a-zA-Z\d\-]+(?<!-)\.)+[a-zA-Z]{2,}|\[(((?(?<!\[)\.)(25[0-5]|2[0-4]\d|[01]?\d?\d)){4}|[a-zA-Z\d\-]*[a-zA-Z\d]:((?=[\x01-\x7f])[^\\\[\]]|\\[\x01-\x7f])+)\])$} ) {
        $vsap->error( $_ERR{USER_ADD__DOMAIN_INVALID} => "domain must be in a valid format" );
        return;
    }
    if ($xmlobj->child('da')) {
        # domain must be unique to system (e.g. not already assigned to another user)
    }
    elsif ($xmlobj->child('eu')) {
        # domain must exist in config and be assigned to parent admin
    }

    # services checks
    unless ($ftp_privs || $sftp_privs || $mail_privs || $shell_privs || $fileman_privs || $podcast_privs) {
        $vsap->error( $_ERR{USER_ADD__SERVICES_MISSING} => "must select at least one non-dependent service" );
        return;
    }
    my $services = "";
    if ($vsap->is_linux()) {
        $services .= "--ftp=y " if ( $ftp_privs );
        $services .= "--sftp=y " if ( $sftp_privs );
        $services .= "--mail=y " if ( $mail_privs );
    }
    else {
        $services = "--services=";
        $services .= "ftp," if ( $ftp_privs );
        $services .= "sftp," if ( $sftp_privs );
        $services .= "mail," if ( $mail_privs );
        $services .= "shell," if ( $shell_privs );
    }
    chop($services);

    # end user capability checks
    if ($xmlobj->child('da')) {
        unless ($capa_ftp || $capa_sftp || $capa_fileman || $capa_mail || $capa_shell) {
            $vsap->error( $_ERR{USER_ADD__CAPA_MISSING} => "must select at least one end user capability" );
            return;
        }
        if ($capa_ftp && !$ftp_privs) {
            $vsap->error( $_ERR{USER_ADD__CAPA_INVALID} => "end user capability not possible without corresponding service (ftp)" );
            return;
        }
        if ($capa_sftp && !$sftp_privs) {
            $vsap->error( $_ERR{USER_ADD__CAPA_INVALID} => "end user capability not possible without corresponding service (sftp)" );
            return;
        }
        if ($capa_fileman && !$fileman_privs) {
            $vsap->error( $_ERR{USER_ADD__CAPA_INVALID} => "end user capability not possible without corresponding service (fileman)" );
            return;
        }
        if ($capa_mail && !$mail_privs) {
            $vsap->error( $_ERR{USER_ADD__CAPA_INVALID} => "end user capability not possible without corresponding service (mail)" );
            return;
        }
        if ($capa_shell && !$shell_privs) {
            $vsap->error( $_ERR{USER_ADD__CAPA_INVALID} => "end user capability not possible without corresponding service (shell)" );
            return;
        }
    }

    # shell checks
    if ($shell_privs) {
        if ($shell eq "") {
            $vsap->error( $_ERR{USER_ADD__SHELL_INVALID} => "shell invalid" );
            return;
        }
        # FreeBSD doesn't like full path specifications... make a happier version
        if (! $vsap->is_linux() ) {
            $shell =~ s#(.*)/[^/]*?##;
        }
    }
    else {
        $shell = "";
    }

    # homedir check
    my $homedir = "/home/$login_id";
    if (-e $homedir) {
        $vsap->error( $_ERR{USER_ADD__HOME_DIR_EXISTS} => "Home directory already exists" );
        return;
    }

    # quota checks
    my $quota = ( ($xmlobj->child('quota') && $xmlobj->child('quota')->value )
                  ? $xmlobj->child('quota')->value
                  : defined($xmlobj->child('quota')->value)
                  ? $xmlobj->child('quota')->value : '' );
    if ($quota eq '') {
        $vsap->error( $_ERR{USER_ADD__QUOTA_MISSING} => "quota cannot be empty" );
        return;
    }
    if ($quota =~ /[^0-9]/) {
        $vsap->error( $_ERR{USER_ADD__QUOTA_NOT_INTEGER} => "quota must be an integer" );
        return;
    }

    ## end user checks
    my ($new_da_quota, $group);
    $new_da_quota = $group = 0;
    if ($xmlobj->child('eu')) {
        my $admin = (values(%{$co->domains(domain=>$domain)}))[0];
        if ($quota > 0) {
            ## cannot add end user if quota will exceed domain admin total quota
            my ($current_da_usage, $current_da_quota);
            if ($admin ne $APACHE_ADMIN) {
              REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    ($current_da_usage, $current_da_quota) = (Quota::query(Quota::getqcarg('/home'), (getpwnam($admin))[2]))[0,1];
                    $current_da_usage /= 1024;
                    $current_da_quota /= 1024;
                }
                if ($current_da_quota) {
                    if ($quota >= $current_da_quota) {
                        $vsap->error( $_ERR{USER_ADD__EU_QUOTA_EXCEEDED} => "quota exceeds domain admin allotment" );
                        return;
                    }
                    elsif ($quota >= ($current_da_quota - $current_da_usage)) {
                        $vsap->error( $_ERR{USER_ADD__QUOTA_ALLOCATION_FAILURE} => "quota exceeds free space available for domain admin" );
                        return;
                    }
                    else {
                        # decrease domain admin allocation by enduser quota
                        $new_da_quota = $current_da_quota - $quota;
                    }
                }
            }
        }
        else {
            ## can a zeroquota user be added to this domain?
            ## a server admin domain can't have zeroquota users, currently...
            if ($admin eq $APACHE_ADMIN) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (zeroquota) is denied by config" );
                return;
            }
            ## need to get eu_capa of domain admin
            $co->init( username => $admin );
            my $eu_capa = $co->eu_capabilities;
            ## reset
            $co->init( username => $vsap->{username} );
            ## check domain admin zeroquota capa
            if ($eu_capa->{'zeroquota'}) {
                $group = (getpwnam($admin))[2];
            }
            else {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (zeroquota) is denied by config" );
                return;
            }
        }

        ## cannot add new end user with a service that is forbidden by config
        unless($vsap->{server_admin}) {
            if ($admin_type eq "ma") {
                # need to get eu_capa of domain admin... not mail admin
                $co->init( username => $admin );
            }
            my $eu_capa = $co->eu_capabilities;
            if ($admin_type eq "ma") {
                # reset to mail admin
                $co->init( username => $vsap->{username} );
            }
            if ($ftp_privs && !$eu_capa->{'ftp'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (ftp) is denied by config" );
                return;
            }
            if ($sftp_privs && !$eu_capa->{'sftp'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (sftp) is denied by config" );
                return;
            }
            if ($fileman_privs && !$eu_capa->{'fileman'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (fileman) is denied by config" );
                return;
            }
            if ($mail_privs && !$eu_capa->{'mail'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (mail) is denied by config" );
                return;
            }
            if ($webmail_privs && (!$mail_privs || !$eu_capa->{'mail'})) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (webmail) is denied by config" );
                return;
            }
            if ($shell_privs && !$eu_capa->{'shell'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (shell) is denied by config" );
                return;
            }
        }
    }

    if ( $vsap->is_linux() ) {
        $shell = ($shell) ? $shell : "/sbin/noshell";
        $shell_privs=1;
    }
    else {
        $shell = ($shell) ? $shell : "/bin/sh";
    }

    # crypt the password; first try md5
    my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9, qw(. /) );
    my $salt  = "\$1\$" . join("", @chars[ map { rand @chars} ( 1 .. 8) ]);
    my $crypted = crypt($password, $salt);
    if (substr($crypted, 0, 11) ne $salt) {
        # md5 crypted password failed
        $salt  = join("", @chars[ map { rand @chars} ( 1 .. 2) ]);
        $crypted = crypt($password, $salt);
    }
    undef @chars;

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling user:add for user '$login_id'");

    # backup affected system file(s)
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/passwd");
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/group");
    if ( $vsap->is_linux() ) {
        VSAP::Server::Modules::vsap::backup::backup_system_file($FTPUSERS);     ## ftp
        VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/fstab");  ## sftp
    }
    VSAP::Server::Modules::vsap::mail::backup_system_file("genericstable");

    # add user to system (as quietly as possible)
    if ( !VSAP::Server::Modules::vsap::user::_adduser($vsap, $login_id, $group, $fullname, $crypted, 
                                                      $quota, $homedir, $services, $shell_privs && $shell) ) {
        $vsap->error( $_ERR{USER_ADD__EU_VADDUSER_ERROR} => "_adduser error: $@" );
        VSAP::Server::Modules::vsap::logger::log_error("_adduser error: $@");
        return;
    }
    VSAP::Server::Modules::vsap::logger::log_message("_adduser() for '$login_id' successful");

    if ($new_da_quota) {
        my $admin = (values(%{$co->domains(domain=>$domain)}))[0];
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, (getpwnam($admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 0);
            ## group quota too
            Quota::setqlim($dev, (getgrnam($admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 1);
            Quota::sync($dev);
        }
    }

    ## set group quota if the DA has been setup with zeroquota capability
    if ($capa_zeroquota) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, (getgrnam($login_id))[2], ($quota * 1024), ($quota * 1024), 0, 0, 0, 1);
            Quota::sync($dev);
        }
    }

    # add genericstable entry
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::genericstable( user => $login_id, dest => $dest );
    }

    # add Mail directory
    if ($mail_privs) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            mkdir "$homedir/Mail";
            chown((getpwnam($login_id))[2,3], "$homedir/Mail");
        }
    }

    # add user to domain in cpx config file (init should populate services)
    $co = new VSAP::Server::Modules::vsap::config( username => $login_id );
    $co->domain( $domain );
    if ($xmlobj->child('da')) {
        $co->domain_admin( set => 1 );
        $co->services( fileman => $fileman_privs, podcast => $podcast_privs, webmail => $webmail_privs );
        $co->eu_capabilities( ftp => $capa_ftp,
                              sftp => $capa_sftp,
                              fileman => $capa_fileman,
                              mail => $capa_mail,
                              shell => $capa_shell,
                              zeroquota => $capa_zeroquota);
        $co->eu_prefix( $eu_prefix );
    }
    elsif ($xmlobj->child('eu')) {
        $co->services( fileman => $fileman_privs, webmail => $webmail_privs );
        if ( defined($xmlobj->child('mail_admin')) && $xmlobj->child('mail_admin')->value ) {
            $co->mail_admin( set => 1 );
        }
    }
    $co->comments($comments);
    $co->commit;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:add');
    $root_node->appendTextChild(status => 'ok');
    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::properties;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : '' );
    $domain =~ tr/A-Z/a-z/;

    my $admin  = ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                   ? $xmlobj->child('admin')->value
                   : '' );

    my $user   = ( $xmlobj->child('user') && $xmlobj->child('user')->value
                   ? $xmlobj->child('user')->value
                   : '' );

    my $brief  = ($xmlobj->child('brief') ? 1 : 0 );

    if (!$user) {
      $vsap->error( $_ERR{USER_NAME_MISSING} => "User name missing" );
      return;
    }

    my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});

    ## authorize the caller
    VSAP::Server::Modules::vsap::user::_check_auth($vsap, $co, $admin, $domain, $user) or return;

    ## build properties for user
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:properties');

    my $groups = $co->get_groups($user);
    my $server_admin = $groups->{wheel};

    my $user_node = $dom->createElement('user');

    ## build cheap nodes first
    $user_node->appendTextChild( login_id => $user );
    my ($uid,$home_dir) = (getpwnam($user))[2,7];
    $user_node->appendTextChild( home_dir => ( $home_dir =~ m{[^A-Za-z0-9/]}
                                               ? VSAP::Server::Base::xml_escape( $home_dir )
                                               : $home_dir ) );

    ## calculate quotas
    my ($uu, $uq, $eu, $eq) = (0, 0, 0, 0);
    my $quota_node;
    if ($server_admin) {
        ## server_admin's user quota
        $quota_node = $dom->createElement('user_quota');
        ($uu) = (VSAP::Server::Modules::vsap::user::_quota_node($quota_node, $uid))[1];
        $user_node->appendChild( $quota_node );
        ## total usage for the server account
        $quota_node = $dom->createElement('quota');
        VSAP::Server::Modules::vsap::user::_server_quota_node($quota_node);
        $user_node->appendChild( $quota_node );
    }
    elsif ($co->mail_admin) {
        ## mail admins need parent admin quota information as well
        ## as their "regular" quota information
        # first, append parent admin quota info (need this for adding/editing users)
        my $user_domain = $co->user_domain($vsap->{username});
        my $domains = $co->domains(domain => $user_domain);
        my $parent_admin = $domains->{$user_domain};  ## domain admin for mail admin
        my ($parent_admin_uid) = (getpwnam($parent_admin))[2];
        my $parent_groups = $co->get_groups($parent_admin);
        my $parent_is_server_admin = defined($parent_groups->{wheel}) || ($parent_admin eq $APACHE_ADMIN);
        $quota_node = $dom->createElement('admin_quota');
        if ($parent_is_server_admin) {
            VSAP::Server::Modules::vsap::user::_server_quota_node($quota_node);
        }
        else {
            VSAP::Server::Modules::vsap::user::_quota_node($quota_node, $parent_admin_uid);
        }
        $user_node->appendChild( $quota_node );
        # second, append the mail admin regular quota node
        $quota_node = $dom->createElement('quota');
        ($uq, $uu) = VSAP::Server::Modules::vsap::user::_quota_node($quota_node, $uid);
        $user_node->appendChild( $quota_node );
    }
    else {
        ## domain admins and end users
        $quota_node = $dom->createElement('quota');
        ($uq, $uu) = VSAP::Server::Modules::vsap::user::_quota_node($quota_node, $uid);
        $user_node->appendChild( $quota_node );
    }

  FROM_CONFIG: {

      if ($brief) {
          ## get what services we can: ftp, sftp, and mail
          my $serv_node = $dom->createElement('services');
          for my $serv ( [ mail => [qw(imap pop dovecot mailgrp)] ],
                         [ ftp  => [qw(ftp)] ],
                         [ sftp  => [qw(sftp)] ] ) {
              for my $group ( @{$serv->[1]} ) {
                  if ($groups->{$group} ) {
                      $serv_node->appendChild($dom->createElement($serv->[0]));
                      last;
                  }
              }
          }
          $user_node->appendChild($serv_node);
          last FROM_CONFIG;
      }

      ($eq, $eu) = VSAP::Server::Modules::vsap::user::_config_info($user_node, $dom, $co, $user, $server_admin, $groups);

    } ## FROM_CONFIG

    my $group_quota_node = $dom->createElement('group_quota');
    my $committed = $uu + $eu;
    my $allocated = $uq + $eq;
    $group_quota_node->appendTextChild( usage => $committed );
    $group_quota_node->appendTextChild( limit => $allocated );
    $group_quota_node->appendTextChild( units => 'MB'   );
    $user_node->appendChild( $group_quota_node );

    $root->appendChild($user_node);

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $co->commit;  ## commit any updates via init
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list;

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::user::prefs;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value : '' );
    $domain =~ tr/A-Z/a-z/;

    my $admin  = ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                   ? $xmlobj->child('admin')->value : '' );

    my $user   = ( $xmlobj->child('user') && $xmlobj->child('user')->value
                   ? $xmlobj->child('user')->value : '' );

    my $page = ( $xmlobj->child('page') && $xmlobj->child('page')->value
                 ? $xmlobj->child('page')->value : 1 );

    my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
    my @users = ();

    ## authorize the caller
    @users = VSAP::Server::Modules::vsap::user::_check_auth($vsap, $co, $admin, $domain, $user)
      or return;

    ## remove admin from @users if $admin ne "" (BUG26997)
    @users = grep(!/^$admin$/, @users);

    # these view settings are saved as preferences to preserve state
    my %_usortprefs = ( users_sortby  => 'domain',     ## login_id | domain | usertype | status | limit | used
                        users_order   => 'ascending',  ## descending | ascending
                        users_sortby2 => 'login_id',   ## login_id | domain | usertype | status | limit | used
                        users_order2  => 'ascending',  ## descending | ascending
                      );

    for my $pref (keys %_usortprefs) {
        (my $s_pref = $pref) =~ s/users_//;
        $_usortprefs{$pref} = ( $xmlobj->child($s_pref) && $xmlobj->child($s_pref)->value
                               ? $xmlobj->child($s_pref)->value
                               : VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, $pref) );
    }

    my $users_per_page = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'users_per_page') || 25;

    ## this 'set_values' call must be after the get_value call above
    VSAP::Server::Modules::vsap::user::prefs::set_values( $vsap, $dom, %_usortprefs );

    my $allocated = 0;  ## running quota for sets of users
    my $committed = 0;  ## running usage for sets of users

    ## loop through users and load up pertinent info for sorting:
    ## (login_id, domain, usertype, status, limit, used)
    my %_uinfo = ();
    for my $user (@users) {
        next if ($user eq "nobody");       ## skip system 'nobody'
        next if ($user eq $APACHE_ADMIN);  ## skip system domain admin
        my $uid = $co->user_uid($user);
        next unless ($uid);                ## skip root-ish or non-existent users
        my $groups = $co->get_groups($user);
        my $server_admin = $groups->{wheel};
        # login_id
        $_uinfo{$user}->{'login_id'} = $user;
        # usertype
        my $usertype = $co->user_type($user);
        $_uinfo{$user}->{'usertype'} = $usertype;
        # domain
        $_uinfo{$user}->{'user_domain'} = $co->user_domain($user);
        # status
        my $disabled = $co->user_disabled($user);
        $_uinfo{$user}->{'status'} = ($disabled ? 'disabled' : 'enabled');

        ## user quotas
        my $uq = 0;
        my $uu = 0;
        if ($server_admin) {
          ## this node is for the server's disk limit/usage
          $_uinfo{$user}->{'quota_node'} = $dom->createElement('quota');
          VSAP::Server::Modules::vsap::user::_server_quota_node($_uinfo{$user}->{'quota_node'});
          ## this node is for the server admin's own disk limit/usage
          $_uinfo{$user}->{'user_quota_node'} = $dom->createElement('user_quota');
          ($uq, $uu) = VSAP::Server::Modules::vsap::user::_quota_node($_uinfo{$user}->{'user_quota_node'}, $uid);
        }
        else {
          $_uinfo{$user}->{'quota_node'} = $dom->createElement('quota');
          ($uq, $uu) = VSAP::Server::Modules::vsap::user::_quota_node($_uinfo{$user}->{'quota_node'}, $uid);
        }
        $allocated += $uq;
        $_uinfo{$user}->{'limit'} = $uq;
        $_uinfo{$user}->{'used'} = ($uq ? ($uu / $uq) : 0);
        $committed += $uu if ($uq);  # only count committed disk usage of users with non-zero quota

        ## domains
        my $sort_domain = $_uinfo{$user}->{'user_domain'};  ## default
        if (($usertype eq "sa") || ($usertype eq "da")) {
            my %domains = ();
            if ($usertype eq "sa") {
                %domains = %{$co->domains};
            }
            else {  ## domain admin
                %domains = %{$co->domains(admin => $user)};
            }
            if (keys %domains) {
                $_uinfo{$user}->{'domains_node'} = $dom->createElement('domains');
                my $first = 0;
                for my $domain (sort keys %domains) {
                    if ( !$first && ($domains{$domain} eq $user) ) {
                        $sort_domain = $domain;
                        $first = 1;
                    }
                    my $d_node = $dom->createElement('domain');
                    $d_node->appendTextChild( name  => $domain );
                    $d_node->appendTextChild( admin => $domains{$domain} );
                    $_uinfo{$user}->{'domains_node'}->appendChild($d_node);
                }
            }
        }
        $_uinfo{$user}->{'domain'} = $sort_domain;
    }

    ## build sorted user list
    my @sorted_users = sort {
            if (($_usortprefs{'users_sortby'} eq "limit") || ($_usortprefs{'users_sortby'} eq "used")) {
                # primary sort criteria requires numeric comparison
                if ($_uinfo{$a}->{$_usortprefs{'users_sortby'}} == $_uinfo{$b}->{$_usortprefs{'users_sortby'}}) {
                    # primary sort values identical... fail over to secondary sort criteria
                    if (($_usortprefs{'users_sortby2'} eq "limit") || ($_usortprefs{'users_sortby2'} eq "used")) {
                        # secondary sort criteria requires numeric comparison
                        return ( ($_usortprefs{'users_order2'} eq "ascending") ?
                                 ($_uinfo{$a}->{$_usortprefs{'users_sortby2'}} <=> $_uinfo{$b}->{$_usortprefs{'users_sortby2'}}) :
                                 ($_uinfo{$b}->{$_usortprefs{'users_sortby2'}} <=> $_uinfo{$a}->{$_usortprefs{'users_sortby2'}}) );
                    }
                    # secondary sort criteria requires string comparison
                    return ( ($_usortprefs{'users_order2'} eq "ascending") ?
                             ($_uinfo{$a}->{$_usortprefs{'users_sortby2'}} cmp $_uinfo{$b}->{$_usortprefs{'users_sortby2'}}) :
                             ($_uinfo{$b}->{$_usortprefs{'users_sortby2'}} cmp $_uinfo{$a}->{$_usortprefs{'users_sortby2'}}) );
                }
                return ( ($_usortprefs{'users_order'} eq "ascending") ?
                         ($_uinfo{$a}->{$_usortprefs{'users_sortby'}} <=> $_uinfo{$b}->{$_usortprefs{'users_sortby'}}) :
                         ($_uinfo{$b}->{$_usortprefs{'users_sortby'}} <=> $_uinfo{$a}->{$_usortprefs{'users_sortby'}}) );
            }
            else {
                # primary sort criteria requires string comparison
                if ($_uinfo{$a}->{$_usortprefs{'users_sortby'}} eq $_uinfo{$b}->{$_usortprefs{'users_sortby'}}) {
                    # primary sort values identical... fail over to secondary sort criteria
                    if (($_usortprefs{'users_sortby2'} eq "limit") || ($_usortprefs{'users_sortby2'} eq "used")) {
                        # secondary sort criteria requires numeric comparison
                        return ( ($_usortprefs{'users_order2'} eq "ascending") ?
                                 ($_uinfo{$a}->{$_usortprefs{'users_sortby2'}} <=> $_uinfo{$b}->{$_usortprefs{'users_sortby2'}}) :
                                 ($_uinfo{$b}->{$_usortprefs{'users_sortby2'}} <=> $_uinfo{$a}->{$_usortprefs{'users_sortby2'}}) );
                    }
                    # secondary sort criteria requires string comparison
                    return ( ($_usortprefs{'users_order2'} eq "ascending") ?
                             ($_uinfo{$a}->{$_usortprefs{'users_sortby2'}} cmp $_uinfo{$b}->{$_usortprefs{'users_sortby2'}}) :
                             ($_uinfo{$b}->{$_usortprefs{'users_sortby2'}} cmp $_uinfo{$a}->{$_usortprefs{'users_sortby2'}}) );
                }
                return ( ($_usortprefs{'users_order'} eq "ascending") ?
                         ($_uinfo{$a}->{$_usortprefs{'users_sortby'}} cmp $_uinfo{$b}->{$_usortprefs{'users_sortby'}}) :
                         ($_uinfo{$b}->{$_usortprefs{'users_sortby'}} cmp $_uinfo{$a}->{$_usortprefs{'users_sortby'}}) );
            }
        } (keys(%_uinfo));

    my $num_users = $#sorted_users + 1;
    my $total_pages = ( $users_per_page > 0 && $num_users > 0
                        ? ( $num_users % $users_per_page
                            ? int($num_users / $users_per_page) + 1
                            : int($num_users / $users_per_page) )
                        : 1);

    if ($page > $total_pages) { $page = 1; }
    my $prev_page = ($page == 1) ? '' : $page - 1;
    my $next_page = ($page == $total_pages) ? '' : $page + 1;
    my $first_user = 1 + ($users_per_page * ($page - 1));
    if ($num_users < 1) { $first_user = 0; }
    my $last_user = $first_user + $users_per_page - 1;
    if ($last_user > $num_users) { $last_user = $num_users; }
    if ($last_user < 1) { $last_user = 0; }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:list');
    $root->appendTextChild( num_users     => $num_users );
    $root->appendTextChild( page          => $page );
    $root->appendTextChild( total_pages   => $total_pages );
    $root->appendTextChild( prev_page     => $prev_page );
    $root->appendTextChild( next_page     => $next_page );
    $root->appendTextChild( first_user    => $first_user );
    $root->appendTextChild( last_user     => $last_user );
    $root->appendTextChild( sortby        => $_usortprefs{'users_sortby'} );
    $root->appendTextChild( order         => $_usortprefs{'users_order'} );
    $root->appendTextChild( sortby2       => $_usortprefs{'users_sortby2'} );
    $root->appendTextChild( order2        => $_usortprefs{'users_order2'} );

    if ($#sorted_users > -1) {
        ## loop through "visible" users
        for my $user ( @sorted_users[($first_user-1 .. $last_user-1)] ) {
            # node for this user
            my $user_node = $dom->createElement('user');
            # login id
            $user_node->appendTextChild( login_id => $user );
            # home directory
            my $home_dir = $co->user_home($user);
            $home_dir = ( $home_dir =~ m{[^A-Za-z0-9/]} ? VSAP::Server::Base::xml_escape( $home_dir ) : $home_dir );
            $user_node->appendTextChild( home_dir => $home_dir );

            ## quota information
            $user_node->appendChild( $_uinfo{$user}->{'quota_node'} );
            $user_node->appendChild( $_uinfo{$user}->{'user_quota_node'} ) if ($_uinfo{$user}->{'user_quota_node'});

            # user type
            my $usertype = $_uinfo{$user}->{'usertype'};
            $user_node->appendTextChild( usertype => $usertype );
            # domain name
            $user_node->appendTextChild( domain => $_uinfo{$user}->{'user_domain'} );
            # status
            $user_node->appendTextChild( status => $_uinfo{$user}->{'status'} );
            # services
            my $services = $co->user_services($user);
            my @services = split(/:/, $services);
            my $serv_node = $dom->createElement('services');
            for my $serv (@services) {
                $serv_node->appendChild($dom->createElement($serv));
            }
            $user_node->appendChild($serv_node);
            # domains
            if ((($usertype eq "sa") || ($usertype eq "da")) &&
                ( defined($_uinfo{$user}->{'domains_node'}) )) {
                    $user_node->appendChild($_uinfo{$user}->{'domains_node'});
            }
            # append to root
            $root->appendChild($user_node);
        }
    }

    my $quota_node = $dom->createElement('quota');
    $quota_node->appendTextChild( usage => $committed );
    $quota_node->appendTextChild( allocated => $allocated );
    $quota_node->appendTextChild( units => 'MB'   );
    $root->appendChild( $quota_node );

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list_brief;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
    my @users = ();

    ## authorize the caller
    @users = VSAP::Server::Modules::vsap::user::_check_auth($vsap, $co, '', '', '')
      or return;

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:list_brief');

    for my $user (@users) {
        next if ($user eq "nobody");       ## skip system 'nobody'
        next if ($user eq $APACHE_ADMIN);  ## skip system domain admin
        my $uid = $co->user_uid($user);
        next unless ($uid);                ## skip root-ish or non-existent users

        my $groups = $co->get_groups($user);

        my $user_node = $dom->createElement('user');

        ## build cheap nodes first
        $user_node->appendTextChild( login_id => $user );
        my $home_dir = $co->user_home($user);
        $user_node->appendTextChild( home_dir => ( $home_dir =~ m{[^A-Za-z0-9/]}
                                                   ? VSAP::Server::Base::xml_escape( $home_dir )
                                                   : $home_dir ) );

        ## get what services we can: ftp, sftp, and mail
        my $serv_node = $dom->createElement('services');
        for my $serv ( [ mail => [qw(imap pop dovecot mailgrp)] ],
                       [ ftp  => [qw(ftp)] ],
                       [ sftp  => [qw(sftp)] ] ) {
            for my $group ( @{$serv->[1]} ) {
                if ($groups->{$group}) {
                    $serv_node->appendChild($dom->createElement($serv->[0]));
                    last;
                }
            }
        }
        $user_node->appendChild($serv_node);

        $root->appendChild($user_node);
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list::eu;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $user  = ( $xmlobj->child('user') && $xmlobj->child('user')->value
                  ? $xmlobj->child('user')->value
                  : $vsap->{username} );

    my $userid = getpwnam($user);
    my $co = new VSAP::Server::Modules::vsap::config(uid => $userid);

    my @ulist;
    if (($vsap->{server_admin}) && ($user eq $vsap->{username})) {
        # server admin making call w/ no user specified ... add
        # all non-system users to user list (including self)
        @ulist = keys %{$co->users()};
        # add web administrator
        my $webadmin = ( $vsap->is_linux() ) ? "apache" : "webadmin";
        push(@ulist, $webadmin);
    }
    elsif ($co->domain_admin) {
        # domain admin making call w/ no user specified ... or
        # user specified is a domain admin.  add domain admin's
        # enduser to the list
        @ulist = keys %{$co->users(admin => $user)};
        # add self to list
        push(@ulist, $vsap->{username});
    }
    else {
        # add self (presume enduser)
        push(@ulist, $vsap->{username});
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'user:list:eu');

    my $validuser;
    foreach $validuser (@ulist) {
        $root_node->appendTextChild(user => $validuser);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list::system;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $system_only  = ($xmlobj->child('system_only') ? 1 : 0 );
    my $no_system    = ($xmlobj->child('no_system_users') ? 1 : 0 );

    # only server admin can list all users on system
    unless ($vsap->{server_admin}) {
        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'user:list:system');

    my ($user, $uid);
    my $uidFloor = ($vsap->is_linux()) ? 500 : 1000;
    setpwent();
    while (($user, $uid) = (getpwent())[0,2]) {
        if ($system_only) {
            next unless (($uid < $uidFloor) || ($uid > 65533));
        }
        if ($no_system) {
            next if $uid < $uidFloor;
            next if lc $user eq 'nfsnobody'; # HIC-858 even though nfsnobody is uid 65xxx it's still somehow a system user.
        }
        $root_node->appendTextChild(user => $user);
    }
    endpwent();

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list_eu_capa;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $admin  = ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                   ? $xmlobj->child('admin')->value
                   : '' );

    if (!$admin) {
      $vsap->error( $_ERR{USER_NAME_MISSING} => "Admin name missing" );
      return;
    }
    my $co = new VSAP::Server::Modules::vsap::config( username => $admin);

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:list_eu_capa');

    $co->init( username => $admin );
    if (!$co->is_valid) {
      $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
      return;
    }
    if ($co->domain_admin) {
        my $eu_capa_node = $dom->createElement('eu_capa');
        for my $eu_capa ( keys %{ $co->eu_capabilities } ) {
            $eu_capa_node->appendChild($dom->createElement($eu_capa));
        }
        $root->appendChild($eu_capa_node);
    }
    elsif ($co->mail_admin) {
        my $user_domain = $co->user_domain($vsap->{username});
        my $domains = $co->domains(domain => $user_domain);
        my $parent_admin = $domains->{$user_domain};  ## domain admin for mail admin
        $co->init( username => $parent_admin );
        my $eu_capa_node = $dom->createElement('eu_capa');
        for my $eu_capa ( keys %{ $co->eu_capabilities } ) {
            next if ( $eu_capa ne "mail" );
            $eu_capa_node->appendChild($dom->createElement($eu_capa));
        }
        $root->appendChild($eu_capa_node);
    }
    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list_da_eligible;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{USER_PERMISSION} => "Permission denied");
        return;
    }

    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    # users eligible to be included in list
    my %eligible_users = ();

    # any user associated with primary domain can be included here
    # (e.g. end users of the primary domain can be promoted)
    my @primary_domain_users = keys %{$co->users(domain => $co->primary_domain)};
    foreach my $user (@primary_domain_users) {
        next if ($user eq $APACHE_ADMIN);  ## skip system domain admin
        $eligible_users{$user} = "到!";
    }

    # any current domain administrator is also eligible
    my @domain_administrators = @{$co->domain_admins};
    foreach my $user (@domain_administrators) {
        next if ($user eq $APACHE_ADMIN);  ## skip system domain admin
        $eligible_users{$user} = "到!";
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:list_da_eligible' );
    $root->appendTextChild('admin' => $_) for keys (%eligible_users);

    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::list_da;

use VSAP::Server::Modules::vsap::config;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{USER_PERMISSION} => "Permission denied");
        return;
    }

    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:list_da');

    ## add all domain admins
    foreach my $admin (@{$co->domain_admins}) {
        next if ($admin eq 'oemroot');
        $root_node->appendTextChild('admin' => $admin)
    }

    ## add web server owner
    $root_node->appendTextChild('admin' => $APACHE_ADMIN);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::edit;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::domain;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $user = ( $xmlobj->child('user') && $xmlobj->child('user')->value
                 ? $xmlobj->child('user')->value
                 : '' );

    unless ($user) {
        $vsap->error($_ERR{USER_NAME_MISSING} => "Username missing for edit");
        return;
    }

    ## make sure *this* vsap user has permissions to edit $user
    my $admin_type = "";
    my $parent_admin = "";
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
  CHECK_AUTHZ: {
        if ($vsap->{server_admin}) {
            $admin_type = "sa";
            last CHECK_AUTHZ;
        }
        elsif ($co->domain_admin($user)) {
            if ($user ne $vsap->{username}) {
                $admin_type = "da";
                last CHECK_AUTHZ;
            }
        }
        elsif ($co->mail_admin) {
            $admin_type = "ma";   ## mail admin has limited edit capabilities
            my $user_domain = $co->user_domain($vsap->{username});
            my @authuserlist = keys %{$co->users(domain => $user_domain)};
            my $domains = $co->domains(domain => $user_domain);
            $parent_admin = $domains->{$user_domain};  ## domain admin for mail admin
            if ( (grep(/^$user$/, @authuserlist)) &&
                 (!($co->domain_admin(admin => $user))) &&  ## mail admin cannot edit domain admin
                 (!($co->mail_admin(admin => $user))) ) {   ## mail admin cannot edit another mail admin
                last CHECK_AUTHZ;
            }
        }

        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;
    }

    ## cannot get this later when co->init for eu
    my $eu_capa;
    if ($admin_type eq "ma") {
        $co->init( username => $parent_admin );
        $eu_capa = $co->eu_capabilities;
    }
    else {
        $eu_capa = $co->eu_capabilities;
    }

    ## init as user we are going to edit
    $co->init(username => $user);

    ## setup some values that i need later
    my $domain = "";
    my $domain_admin = "";
    my $old_domain = "";
    my $old_domain_admin = "";
    if ($xmlobj->child('da')) {
        ## editing domain admin
        $domain = ( $xmlobj->child('da')->child('domain') && $xmlobj->child('da')->child('domain')->value
                    ? $xmlobj->child('da')->child('domain')->value : '' );
        $domain =~ tr/A-Z/a-z/;
    }
    elsif ($xmlobj->child('eu')) {
        ## editing end user
        $domain = ( $xmlobj->child('eu')->child('domain') && $xmlobj->child('eu')->child('domain')->value
                    ? $xmlobj->child('eu')->child('domain')->value : '' );
        $domain =~ tr/A-Z/a-z/;
        if ($domain) {
            $domain_admin = (values %{$co->domains(domain=>$domain)})[0];
            $old_domain = $co->user_domain( $user );
            $old_domain_admin = (values %{$co->domains(domain=>$old_domain)})[0];
        }
    }

    ## authentication check
    if ($xmlobj->child('da')) {
        if ($domain) {
            $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
            return;
        }
    }
    elsif ($xmlobj->child('eu')) {
        # cannot add new end user to an unknown domain name
        if ($domain) {
            my %domains = %{ $co->domains };
            unless ( defined($domains{$domain}) ) {
                $vsap->error( $_ERR{USER_ADD__EU_UNKNOWN_DOMAIN} => "unknown domain name: $domain" );
                return;
            }
        }

        ## checking to see if the new domain is zeroquota capable
        my $quota = ( $xmlobj->child('quota') ? $xmlobj->child('quota')->value : undef );
        if (defined($quota) && ($quota == 0)) {
            $co->init( username => $domain_admin );
            unless($co->eu_capabilities()->{'zeroquota'}) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => "service (zeroquota) is denied by config" );
                return;
            }
            $co->init( username => $user );
        }

        if ( $admin_type ne "ma" ) {
            $co->domain( $domain );
            my $mail_admin = ( $xmlobj->child('mail_admin') && $xmlobj->child('mail_admin')->value ) ?
                               $xmlobj->child('mail_admin')->value : 0;
            $co->mail_admin( set => $mail_admin );
        }
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling user:edit for user '$user'");

    # backup affected system file(s)
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/passwd");
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/group");
    if ( $vsap->is_linux() ) {
        VSAP::Server::Modules::vsap::backup::backup_system_file($FTPUSERS);     ## ftp
        VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/fstab");  ## sftp
    }

    # if domain has changed, update mail address
    if ($domain && ($old_domain ne $domain) && ($admin_type ne "ma")) {
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
        VSAP::Server::Modules::vsap::mail::backup_system_file("genericstable");
        VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");
        # edit virtusertable entries
        VSAP::Server::Modules::vsap::mail::change_domain( $user, $old_domain, $domain );
        # edit genericstable entry
        my $dest = VSAP::Server::Modules::vsap::mail::addr_genericstable( $user );
        $dest =~ s/\@.*$/\@$domain/;
        VSAP::Server::Modules::vsap::mail::genericstable( user => $user, dest => $dest );
    }

    ## set services

    #
    # check to see if webmail being added
    #
    # webmail can only be added if:
    #   1. if editing da
    #      a.mail service set
    #
    #   2. if editing eu
    #      a.eu_capa_mail set (da check only)
    #      b.mail service set (sa and da check)
    #

    if ($xmlobj->child('services') && $xmlobj->child('services')->child('webmail') &&
        $xmlobj->child('services')->child('webmail')->value == 1) {
        my $mail_service_pending = ($xmlobj->child('services')->child('mail') ) ?
                                    $xmlobj->child('services')->child('mail')->value : 0;
        my $user_services = $co->services;
        my $mail_service_active = $user_services->{'mail'} ? 1 : 0;
        if (!$mail_service_pending && !$mail_service_active) {
                $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => 'Cannot activate webmail without mail services enabled' );
                return;
        }
        if (!($vsap->{server_admin})) {
                my $mail_eu_capa = $eu_capa->{'mail'} ? 1 : 0;
                if (!$mail_eu_capa) {
                        $vsap->error( $_ERR{USER_ADD__EU_SERVICE_VERBOTEN} => 'Cannot activate webmail without admin mail eu_capa enabled' );
                        return;
                }
        }
    }

    # do the linux-specific ftp/sftp stuff
    if ( $vsap->is_linux() ) {
        # linux uses /etc/ftpusers (or /etc/vsftpd/user_list) for ftp service
        #  add entry to deny; remove entry to grant
        if ($xmlobj->child('services') && $xmlobj->child('services')->child('ftp')) {
            my @lines;
            if (-e "$FTPUSERS") {
                REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    if (open INFILE, "$FTPUSERS") {
                        while (<INFILE>) {
                            push @lines, $_ if ( ! /^$user$/ );
                        }
                        close INFILE;
                    }
                }
            }
            unless( $xmlobj->child('services')->child('ftp')->value == 1) {
                push @lines, "$user\n";
            }
            REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                if (open OUTFILE, ">$FTPUSERS") {
                    print OUTFILE @lines;
                    close OUTFILE;
                }
            }
        }
        # we use /etc/fstab to create "bind" mounts for sftp users
        # FIXME: RUS
    }

    if ($xmlobj->child('services')) {
        my %services = map { lc($_->name) => $_->value } $xmlobj->child('services')->children ;
        if ($co->mail_admin) {
            # can't "unset" mail service for mail admin
            unless ( $xmlobj->child('services')->child('mail') &&
                     $xmlobj->child('services')->child('mail')->value ) {
                $services{'mail'} = 1;
            }
        }
        $co->services( %services );
    }

    ## set capabilities
    if ($xmlobj->child('capabilities')) {
        $co->capabilities( map { lc($_->name) => $_->value } $xmlobj->child('capabilities')->children );
    }

    ## check if zeroquota capability has been granted or revoked
    if ($xmlobj->child('eu_capabilities')) {
        if ($xmlobj->child('eu_capabilities')->child('zeroquota')->value && !$co->eu_capabilities->{'zeroquota'}) {
            # set up a group quota
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                my $dev = Quota::getqcarg('/home');
                my $cur_quota = (Quota::query(Quota::getqcarg('/home'), (getpwnam($user))[2]))[1];
                $cur_quota /= 1024 if ($cur_quota);
                Quota::setqlim($dev, (getgrnam($user))[2], ($cur_quota * 1024), ($cur_quota * 1024), 0, 0, 0, 1);
                Quota::sync($dev);
            }
        }
        elsif (!$xmlobj->child('eu_capabilities')->child('zeroquota')->value && $co->eu_capabilities->{'zeroquota'}) {
            # unset the group quota
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                my $dev = Quota::getqcarg('/home');
                Quota::setqlim($dev, (getgrnam($user))[2], 0, 0, 0, 0, 0, 1);
                Quota::sync($dev);
            }
        }
    }

    ## set eu_capabilities
    if ($xmlobj->child('eu_capabilities')) {
        $co->eu_capabilities( map { lc($_->name) => $_->value } $xmlobj->child('eu_capabilities')->children );
    }

    ## set fullname
    my $fullname = ( $xmlobj->child('fullname') && $xmlobj->child('fullname')->value
                     ? $xmlobj->child('fullname')->value : '' );

    if ($fullname) {
        if ($xmlobj->child('change_gecos')) {
            VSAP::Server::Modules::vsap::user::_change_fullname($vsap, $user, $fullname);
            VSAP::Server::Modules::vsap::logger::log_message("changed fullname for user '$user' to '$fullname'");
        }
    }

    ## set comments
    my $comments = ( $xmlobj->child('comments') && $xmlobj->child('comments')->value
                     ? $xmlobj->child('comments')->value : '' );
    # set special "__REMOVE" flag to remove comments if applicable
    $comments = "__REMOVE" if ($xmlobj->child('comments') && !$xmlobj->child('comments')->value);
    $co->comments($comments);

    if ($admin_type eq "sa") {
        ## set eu_prefix
        my $eu_prefix = ( $xmlobj->child('eu_prefix') && $xmlobj->child('eu_prefix')->value
                          ? $xmlobj->child('eu_prefix')->value : '' );
        if (length($eu_prefix) > 10) {
            $vsap->error( $_ERR{EU_PREFIX_TOO_LONG} => "login prefix must be 10 chars or shorter" );
            return;
        }
        if ($eu_prefix =~ /[^a-z0-9_\.\-]/) {
            $vsap->error( $_ERR{EU_PREFIX_BAD_CHARS} => "login prefix contains invalid characters" );
            return;
        }
        if ($eu_prefix =~ /^[^a-z0-9_]/) {
            $vsap->error( $_ERR{EU_PREFIX_ERR} => "login prefix begins with an invalid character" );
            return;
        }
        # does eu_prefix already exist?
        my $duplicate = 0;
        my @prefix_list = @{$co->eu_prefix_list};
        my $current_eup = $co->eu_prefix();  ## current user prefix
        foreach my $prefix (@prefix_list) {
            next if ($prefix eq $current_eup);
            if ($prefix eq $eu_prefix) {
                $vsap->error( $_ERR{EU_PREFIX_DUPLICATE} => "login prefix already exists" );
                return;
            }
        }
        # set special "__REMOVE" flag to remove eu prefix if applicable
        $eu_prefix = "__REMOVE" if ($xmlobj->child('eu_prefix') && !$xmlobj->child('eu_prefix')->value);
        $co->eu_prefix($eu_prefix);
    }

    ## set quota
    my $quota = ( $xmlobj->child('quota') ? $xmlobj->child('quota')->value : undef );
    if (defined $quota or ($domain_admin ne $old_domain_admin)) {
        unless ($quota =~ /^\d+$/) {
            $vsap->error( $_ERR{USER_ADD__QUOTA_NOT_INTEGER} => "Quota must be an integer" );
            return;
        }

        my $old_quota = 0;  ## get current quota allocation
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $old_quota = (Quota::query(Quota::getqcarg('/home'), (getpwnam($user))[2]))[1];
            $old_quota /= 1024 if ($old_quota);
        }

        my $groups = $co->get_groups($user);
        my $server_admin = $groups->{wheel};
        my $domain_admin = ($domain) ? (values(%{$co->domains(domain=>$domain)}))[0] : "";

        my $max_quota = 0;
        if ($server_admin || ($domain_admin eq $APACHE_ADMIN)) {
            ## editing quota for a server admin, domain_admin, or a system end user
            my $df;
            local $_;
            for (`df -P -m /home`) {
                chomp;
                next unless m!\d+\s+\d+\s+\d+\s+\d+%!;
                $df = $_;
                last;
            }
            $df = "0 0 0 0 0 0" unless $df;
            ($max_quota) = (split(' ', $df))[1];
            ## check quotas
            if ($max_quota && ($quota > $max_quota)) {
                $vsap->error( $_ERR{USER_ADD__QUOTA_OUT_OF_BOUNDS} => "Quota value ($quota) exceeds system limit ($max_quota)" );
                return;
            }
        }
        else {
            ## editing quota an end user of a domain admin
            my $cur_usage = 0;
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                ($cur_usage, $max_quota) = (Quota::query(Quota::getqcarg('/home'), (getpwnam($domain_admin))[2]))[0,1];
                $max_quota /= 1024 if ($max_quota);
                $cur_usage /= 1024 if ($cur_usage);
            }
            if ($max_quota > 0) {
                ## adjust domain admin quota
                if ($domain_admin eq $old_domain_admin) {
                    $max_quota += $old_quota;  ## max_quota == total space available for quota allocation
                }
                ## check quotas
                if ($max_quota && ($quota >= $max_quota)) {  # note the greater-than-equal-to!!!
                    $vsap->error( $_ERR{USER_ADD__QUOTA_OUT_OF_BOUNDS} => "Quota value exceeded domain admin limit" );
                    return;
                }
                elsif ($quota >= ($max_quota - $cur_usage)) {
                    $vsap->error( $_ERR{USER_ADD__QUOTA_ALLOCATION_FAILURE} => "quota exceeds free space available for domain admin" );
                    return;
                }
              REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    ## or $old_quota, in case the form doesn't include a quota, although i don't know if that is even valid
                    my $new_da_quota = $max_quota - $quota;
                    my $dev = Quota::getqcarg('/home');
                    Quota::setqlim($dev, (getpwnam($domain_admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 0);
                    ## group quota too
                    Quota::setqlim($dev, (getgrnam($domain_admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 1);
                    Quota::sync($dev);
                }
            }
        }

        ## if the user was removed from another domain admin, restore that admin's quota
        if (($domain_admin ne $old_domain_admin) && ($old_domain_admin ne $APACHE_ADMIN)) {
            my $cur_usage = 0;
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                ($cur_usage, $max_quota) = (Quota::query(Quota::getqcarg('/home'), (getpwnam($old_domain_admin))[2]))[0,1];
                $max_quota /= 1024 if ($max_quota);
                $cur_usage /= 1024 if ($cur_usage);
                if ($max_quota) {  ## check to see if quota for old domain admin is not unlimited (BUG29019)
                    my $new_da_quota = $max_quota + $old_quota;
                    my $dev = Quota::getqcarg('/home');
                    Quota::setqlim($dev, (getpwnam($old_domain_admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 0);
                    ## group quota too
                    Quota::setqlim($dev, (getgrnam($old_domain_admin))[2], ($new_da_quota * 1024), ($new_da_quota * 1024), 0, 0, 0, 1);
                    Quota::sync($dev);
                }
            }
        }

        # now (finally)... we are ready to set the new quota for the user
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $dev = Quota::getqcarg('/home');
            Quota::setqlim($dev, (getpwnam($user))[2], ($quota * 1024), ($quota * 1024), 0, 0, 0, 0);
            Quota::sync($dev);
        }

        # all DAs will have a group quota that shadows the user quota.
        # this covers us if a zeroquota DA has zeroquota users, and then the
        # zeroquota capability is removed, the existing zeroquota users will
        # still be bound by the group quota.  -michael

        ## set group quota
        if ($xmlobj->child('da')) {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                my $dev = Quota::getqcarg('/home');
                Quota::setqlim($dev, (getgrnam($user))[2], ($quota * 1024), ($quota * 1024), 0, 0, 0, 1);
                Quota::sync($dev);
            }
        }

        unless ($server_admin) {
            ## figure out if the user needs to move to a new group
            my($gid, $home_dir) = (getpwnam($user))[3,7];
            my($group, $new_gid, $remove_user_group);
            $group = (getgrgid($gid))[0];
            $remove_user_group = $new_gid = 0;
            if ($quota == 0) {
                my $admin = (values %{$co->domains(domain=>$domain)})[0];
                $new_gid = (getpwnam($admin))[3];
                if ($gid == $new_gid) {
                    ## nevermind, the user is already in the DA group
                    $new_gid = "";
                }
                else {
                    if ($group eq $user) {
                        ## remove user group: it is no longer needed
                        $remove_user_group = 1;
                    }
                }
            }
            else {
                if ($user ne $group) {
                    ## put the user back into it's own group, named for the user
                    unless($new_gid = (getgrnam($user))[2]) {
                        ## if the new gid doesn't yet exist, make it
                      REWT: {
                            local $> = $) = 0;  ## regain privileges for a moment
                            if ($vsap->is_linux()) {
                                system("/usr/sbin/groupadd $user");
                            }
                            else {
                                system("/usr/sbin/pw groupadd -n $user");
                            }
                        }
                        $new_gid = (getgrnam($user))[2];
                    }
                }
            }

            if ($new_gid) {
                ## the user needs to move to a new group
              REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    if ($vsap->is_linux()) {
                        system("/usr/sbin/usermod -g $new_gid $user");
                        ## chown the user's files into the new group
                        system("/usr/bin/find $home_dir \\( -user $user -or -group $gid \\) -exec chown :$new_gid {} \\;");
                        system("/usr/bin/find /tmp /var/tmp /var/spool/at /var/spool/cron /var/spool/mail -user $user -exec chown :$new_gid {} \\;");
                        ## remove the group
                        if ($remove_user_group) {
                            system("/usr/sbin/groupdel $group");
                        }
                    }
                    else {
                        system("/usr/sbin/pw usermod -n $user -g $new_gid");
                        ## chown the user's files into the new group
                        system("/usr/bin/find $home_dir \\( -user $user -or -group $gid \\) -exec chown :$new_gid {} \\;");
                        system("/usr/bin/find /tmp /var/tmp /var/at/jobs /var/cron/tabs /var/mail -user $user -exec chown :$new_gid {} \\;");
                        ## remove the group
                        if ($remove_user_group) {
                            system("/usr/sbin/pw groupdel -n $group");
                        }
                    }
                }
            }
        }
    }

    ## enable/disable
    my $status   = ( $xmlobj->child('status') && $xmlobj->child('status')->value
                     ? $xmlobj->child('status')->value
                     : '' );

    if ($status) {
        $co->disabled( ($status eq 'disable' ? 1 : 0) );
        if ($co->domain_admin) {
            VSAP::Server::Modules::vsap::backup::backup_system_file($APACHE_CONFIG);
            VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
            VSAP::Server::Modules::vsap::mail::backup_system_file("genericstable");
            VSAP::Server::Modules::vsap::mail::backup_system_file("domains");
            VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");
            for my $domain ( keys %{ $co->domains(admin => $user) } ) {
                if ($status eq 'disable') {
                    VSAP::Server::Modules::vsap::domain::_disable($vsap, $domain);
                }
                else {
                    VSAP::Server::Modules::vsap::domain::_enable($vsap, $domain);
                }
            }
            $co->_parse_passwd();  # updates cache
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:edit');
    $root_node->appendTextChild( 'status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::remove;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my @users   = ( $xmlobj->children('user') )
                ? map { $_->value } $xmlobj->children('user')
                : ();

    # missing user
    unless (@users) {
        $vsap->error($_ERR{USER_NAME_MISSING} => "Username missing for delete");
        return;
    }

    ## root or nonexistent username
    foreach my $user (@users) {
        unless ($user && getpwnam($user)) {
            $vsap->error($_ERR{USER_NAME_BOGUS} => qq{Nonexistent username [$user]});
            return;
        }
    }

    ## can't delete ourselves
    if (scalar grep { $_ eq $vsap->{username} } @users ) {
        $vsap->error($_ERR{USER_DELETE_SELF} => "Cannot delete self");
        return;
    }

    ## make sure *this* vsap user has permissions to remove the user(s)
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
    for (my $index=0; $index<=$#users; $index++) {
        my $user = $users[$index];
        my $authorized = 0;
        if ($vsap->{server_admin}) {
            $authorized = 1;
        }
        elsif ($co->domain_admin($user)) {
            $authorized = 1;
        }
        elsif ($co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            my @authuserlist = keys %{$co->users(domain => $user_domain)};
            if ( (grep(/^$user$/, @authuserlist)) &&
                 (!($co->domain_admin(admin => $user))) &&  ## mail admin cannot remove domain admin
                 (!($co->mail_admin(admin => $user))) ) {   ## mail admin cannot remove another mail admin
                $authorized = 1;
            }
        }
        next if ($authorized);
        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling user:remove");

    # backup affected system file(s)
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/passwd");
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/group");
    if ( $vsap->is_linux() ) {
        VSAP::Server::Modules::vsap::backup::backup_system_file($FTPUSERS);     ## ftp
        VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/fstab");  ## sftp
    }
    VSAP::Server::Modules::vsap::mail::backup_system_file("genericstable");

    my $numusers = $#users + 1;

    # only have resource to delete X number of users before apache times out (BUG21365)
    my $user_threshold = 50; # set X == 50
    if ($numusers > $user_threshold) {
        $vsap->error( $_ERR{USER_REMOVE__THRESHOLD_EXCEEDED} => "remove threshold exceeded" );
        return;
    }

    my $remove_status = 0;   ## 0 = happy ... !0 = !happy
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $failcount = 0;
        my $dev = Quota::getqcarg('/home');
        for (my $index=0; $index<=$#users; $index++) {
            my $user = $users[$index];
            ## adjust domain admin quota
            my $users = $co->users();
            my $domain = $$users{$user};
            my $admin = (values(%{$co->domains(domain=>$domain)}))[0];
            if ($admin ne $APACHE_ADMIN) {
                if ($user ne $admin) {
                    my $uq = (Quota::query(Quota::getqcarg('/home'), (getpwnam($user))[2]))[1];
                    my $aq = (Quota::query(Quota::getqcarg('/home'), (getpwnam($admin))[2]))[1];
                    if ($uq && $aq) {
                        ## add non-zero user quota back to domain admin quota
                        my $nq = $aq + $uq;
                        Quota::setqlim($dev, (getpwnam($admin))[2], $nq, $nq, 0, 0, 0, 0);
                        ## group quota too
                        Quota::setqlim($dev, (getgrnam($admin))[2], $nq, $nq, 0, 0, 0, 1);
                        Quota::sync($dev);
                    }
                }
            }

            ## delete quota info for this user to keep quota table clean (BUG31455)
            my $uq = (Quota::query(Quota::getqcarg('/home'), (getpwnam($user))[2]))[1];
            Quota::setqlim($dev, (getpwnam($user))[2], 0, 0, 0, 0, 0, 0) if ($uq);

            ## if user was a domain admin; clean up any archived logs (BUG31455)
            my $logpath;
            $logpath = (-e "/usr/local/apache/logs/$user") ? "/usr/local/apache/logs/$user" :    # VPSv2
                       (-e "/usr/local/apache2/logs/$user") ? "/usr/local/apache2/logs/$user" :  # VPSv3
                       (-e "/var/log/httpd/$user") ? "/var/log/httpd/$user" : "";                # Linux
            if (-e "$logpath") {
                system('rm', '-rf', '--', $logpath)
                  and do {
                      # failed to remove log directory... do something?
                      my $exit = ($? >> 8);
                  };
            }

            ## remove user
            if ( !VSAP::Server::Modules::vsap::user::_rmuser($vsap, $user) ) {
                $vsap->error( $_ERR{USER_REMOVE_ERR} => qq{Could not execute vrmuser for [$user]: $!});
                VSAP::Server::Modules::vsap::logger::log_error("vrmuser() failed for user '$user': $!");
                $remove_status = 101;
                $failcount++;
            }
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} removed user '$user'");
        }
        Quota::sync($dev);
    }

    return if ( $remove_status != 0 );

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:remove');
    $root_node->appendTextChild( 'status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::home_exists;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $home = ( $xmlobj->child('home_dir') ? $xmlobj->child('home_dir')->value : '' );

    unless ($home) {
        return;
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:home_exists' );
    $root->appendTextChild( exists => ( -e $home ? 1 : 0 ) );
    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::exists;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $login_id = ( $xmlobj->child('login_id') && $xmlobj->child('login_id')->value
                     ? $xmlobj->child('login_id')->value : '' );

    unless ($login_id) {
        $vsap->error($_ERR{USER_NAME_MISSING} => "Username missing for testing existence");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:exists');

    my $userExists = 0;
    setpwent();
    while ((my $tmpName)=getpwent) {
        if (lc $tmpName eq lc $login_id) {
            $userExists = 1;
        }
    }
    endpwent();

    $root_node->appendTextChild( exists => ( $userExists ? 1 : 0 ) );

    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::user - vsap user management

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::user;
  blah blah blah

=head1 DESCRIPTION

VSAP::Server::Modules::vsap::user manages all aspects of user accounts.

=head2 user:add

Adds a new user (domain admin or end user) to the system and to the CPX
configuration file.  The following elements are expected:

    login_id
        The login id (or login name) may be a combination of up to 16
        alphanumeric characters, the underscore (_), the period (.),
        and the dash (-).  However, the login id may only start with
        an alphanumeric character or an underscore (_).  It is
        recommended that only lowercase chacters and/or digits be
        used.  The login id must be unique to the system.

    fullname
        A description of the login id (such as a firstname and
        surname) of up to 100 characters in length.  The colon (:)
        character cannot be used.

    password
        The password must be at least 8 characters in length and must
        contain one non-alpha character.  The password cannot be the
        same as the login id.  Adherence to a sensible password
        selection policy is highly recommended.

    confirm_password
        The confirmed value of the password (must match password).

    email_prefix
        Optional element. Alternate email prefix to be used within
        the sendmail genericstable file.

    quota
        The disk space limit to be imposed on the new user.

    type
        The type of user to be added.  One of the following types
        must be included:

            da
                Domain admin.  The new user will be a domain
                administrator for the domain name specified.  User
                privileges such as ftp, sftp, mail, and shell are
                included as children of this element.  End user
                capability for granting services may also be
                included.

            eu
                End user.  The new user will be an "end user" in the
                realm of the domain name specified.  User privileges
                such as ftp, sftp, mail, and shell are included as
                children of this element.  Only ftp, sftp, mail, and
                shell privileges can be granted if the parent domain
                admin has been given capability to grant the
                respective service.

    domain
        The domain associated with the new domain admin or the new
        end user.

    ftp_privs

    sftp_privs

    fileman_privs

    podcast_privs

    mail_privs

    shell_privs

    shell

    eu_capa_ftp

    eu_capa_sftp

    eu_capa_fileman

    eu_capa_mail

    eu_capa_shell

Example of a valid new domain admin:

  <vsap type="user:add">
    <login_id>quuxfoo</login_id>
    <fullname>Quux Foo</fullname>
    <password>quuxf00bar</password>
    <confirm_password>quuxf00bar</confirm_password>
    <quota>100</quota>
    <da>
      <domain>quuxfoo.com</domain>
      <ftp_privs/>
      <sftp_privs/>
      <fileman_privs/>
      <podcast_privs/>
      <mail_privs/>
      <shell_privs/>
      <shell>/bin/tcsh</shell>
      <eu_capa_ftp/>
      <eu_capa_sftp/>
      <eu_capa_mail/>
      <eu_capa_shell/>
    </da>
  </vsap>

Example of a valid new end user:

  <vsap type="user:add">
    <login_id>quuxfoochild1</login_id>
    <fullname>Quux Foo Child 1</fullname>
    <password>quuxf00childbar1</password>
    <confirm_password>quuxf00childbar1</confirm_password>
    <quota>10</quota>
    <eu>
      <domain>quuxfoo.com</domain>
      <fileman_privs/>
      <mail_privs/>
      <shell_privs/>
      <shell>/bin/tcsh</shell>
    </eu>
  </vsap>

=head2 user:edit

  <vsap type="user:edit">
    <fullname>New Name</fullname>
    <quota>500</quota>
  </vsap>

=head2 user:properties

  <vsap type="user:properties">
    <user>joefooson</user>
  </vsap>

returns:

  <vsap type="user:properties">
    <user>
      <login_id>joefooson</login_id>
      <fullname>Joe Foo's Son</fullname>
      <quota>52</quota>
      <capability>
        <mail/>
      </capability>
      <services>
        <mail/>
      </services>
    </user>
  </vsap>

=head2 user:list

  <vsap type="user:list"/>

returns:

  <vsap type="user:list">
    <user>
      <login_id>joefooson</login_id>
      <fullname>Joe Foo's Son</fullname>
      <quota>52</quota>
      <capability>
        <mail/>
      </capability>
      <services>
        <mail/>
      </services>
    </user>
    <user>
     .
     .
     .
    </user>
    <user>
     .
     .
     .
    </user>
  </vsap>

=head2 user:list_brief

An alternate method to E<lt>user:listE<gt> is E<lt>user:list_briefE<gt>.

  <vsap type="user:list_brief"/>

This call does not include any user propety that would need to be
derived from the F<cpx.conf> file (which is slow to parse).  The
result is that you get a more minimal listing:

  <vsap type="user:list_brief>
    <user>
      <login_id>joefoo</login_id>
      <home_dir>/home/joefoo</home_dir>
      <quota>
        <limit>50</limit>
        <usage>21</usage>
        <units>MB</units>
      </quota>
      <services>
        <mail/>
        <sftp/>
      </services>
    </user>
    <user>
     .
     .
     .
    </user>
    <user>
     .
     .
     .
    </user>
  </vsap>

The only services that can be listed under E<lt>list_briefE<gt> are
I<ftp>, I<sftp>, and I<mail>, since they can be looked up on the
platform.

=head2 user:list:eu

List all endusers for a '<user>' (if no '<user>' is specified, the
authenticated user is presumed).

  <vsap type="user:list:eu">
    <user>quuxfoo</user>
  </vsap>

returns:

  <vsap type="user:list:eu">
    <user>quuxfoo</user>
    <user>quuxfooenduser1</user>
    <user>quuxfooenduser2</user>
    <user>quuxfooenduser3</user>
  </vsap>

A query against a server admin user will return all (non-system) users.

=head2 user:list:system

List all users on the platform (including system users).  This query
can only be made by a system administrator.

  <vsap type="user:list:system"/>

returns:

  <vsap type="user:list:system">
    <user>root</user>
    <user>toor</user>
    <user>daemon</user>
    <user>operator</user>
      .
      .
      .
  </vsap>

An optional E<lt>system_onlyE<gt> node can be included to only list
system users (i.e. users with uids below 1000 or greater than 65533).

=head2 user:list_eu_capa

  <vsap type="user:list_eu_capa">
    <admin>joefooadmin</admin>
  </vsap>

returns:

  Each eu_capability included for the da is included.

  Assuming all eu_capabilities have been added for an admin, the return would be:

  <vsap type="user:list_eu_capa">
    <eu_capa>
      <mail/>
      <ftp/>
      <sftp/>
      <shell/>
    </eu_capa>
  </vsap>

=head2 user:remove

  <vsap type="user:remove">
    <user>joe</user>
    <user>jane</user>
  </vsap>

=head2 user:exists

  <vsap type="user:exists">
    <login_id>joefooson</login_id>
  </vsap>

returns:

  If the user (login_id) already exists:

  <vsap type="user:exists">
    <status>1</status>
  </vsap>

  If the user (login_id) does not exist:

  <vsap type="user:exists">
    <status>0</status>
  </vsap>


=head1 SEE ALSO

vsapd

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
