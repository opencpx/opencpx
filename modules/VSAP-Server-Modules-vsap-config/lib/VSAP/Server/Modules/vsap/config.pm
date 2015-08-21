package VSAP::Server::Modules::vsap::config;

use 5.008004;
use strict;
use warnings;

use Carp qw(carp croak);
use Encode qw(encode_utf8);
use Fcntl 'LOCK_EX';
use POSIX qw(uname);
use Socket;
use XML::LibXML;

use VSAP::Server::Modules::vsap::backup qw(backup_system_file);
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail qw(all_genericstable all_virtusertable add_entry delete_entry);
use VSAP::Server::Modules::vsap::string::encoding qw(guess_string_encoding);

##############################################################################

## NOTES: This object is odd because it retains some stateful
## NOTES: information, such as the username it was initialized with
## NOTES: and uses that information for certain queries.
## NOTES: At other times, the object may be used generally to query
## NOTES: the configuration file of certain things. Figuring out which
## NOTES: methods do what is left as an exercise.

##############################################################################

## VERSION: the version of the config file format. bump this when you change
## VERSION: the DOM so that it won't be read by earlier versions
our $VERSION  = '0.12';

##############################################################################

our $AUTOLOAD;  ## Yes, Virginia, there is an AUTOLOAD
our $DEBUG        = 0;
our $TRACE        = 0;
our $TRACE_PAT    = '';
our $TRACE_SUB    = 1;
our $TRACE_PID    = 0;
our $LOGSTYLE     = 'syslog'; ## 'stdout' and 'syslog' also valid
our $RC_CONF      = '/etc/rc.conf';
our $TMPLOCK      = '/tmp/cpx.conf.lock';
our $SEMAPHORE    = undef;

our $CONFIG       = $VSAP::Server::Modules::vsap::globals::CONFIG;
our $CPX_SPF      = $VSAP::Server::Modules::vsap::globals::SITE_PREFS;

# disabling caching will degrade performance (you have been warned)
our $DISABLE_CACHING = 0;

##############################################################################

our %PLATFORM_GRPS = ( mail => [ qw(imap pop) ],
                       sftp => [ qw(sftp)      ],
                       ftp  => [ qw(ftp)      ], );

our %SERVICES     = ( mail    => 1,
                      sftp    => 1,
                      ftp     => 1,
                      shell   => 1,
                      webmail => 1,
                      fileman => 1,  ## 'fileman' is funnier than 'filemgr'
                      podcast => 1,
                      zeroquota => 1,
                    );

our $IS_LINUX = $VSAP::Server::Modules::vsap::globals::IS_LINUX;
if ($IS_LINUX) {
    $PLATFORM_GRPS{'mail'} = [qw(mailgrp)];
}

## build a hash of server administrators
my %server_admins = map { $_ => (getpwnam($_))[0] } split(' ', (getgrgid( ($IS_LINUX ? 10 : 0) ))[3]);

## scottw, Thu Jan 20 18:09:43 GMT 2005: A better way would be to read
## these from the config file; this would allow server admins to
## selectively add or remove services. We'd like to figure out a
## config file syntax that would allow these on a per-domain basis.
##
## 1 indicates the service has an external nv_status procedure we can
## call; 0 indicates that it does not and the service is not get/set-able
## from config.pm.
##
our %EXT_SERVICES = ( 'mail-spamassassin' => 1,
                      'mail-clamav'       => 1,
                      'mail-autoreply'    => 0,
                      'mail-forward'      => 0,
                    );

our %CAPABILITIES = ( %SERVICES,
                      map { $_ => 1 } keys %EXT_SERVICES,
                    );
## optional vinstall platform packages => package marker file
our %PACKAGES;
if ($IS_LINUX) {
    %PACKAGES =     ( 'mail-spamassassin' => 'spamassassin',
                      'mail-clamav'       => 'clamd|clamav-milter',
                    );
}
else {
    %PACKAGES =     ( 'mail-spamassassin' => 'spamd_enable',
                      'mail-clamav'       => 'clamav_clamd_enable',
                    );
}

## optional site preferences => default value (0 or 1)
our %SITEPREFS    = (
                      'custom-topnav'            => '0',
                      'custom-sidenav'           => '0',
                      'disable-clamav'           => '0',
                      'disable-enhanced-webmail' => '0',
                      'disable-help'             => '0',
                      'disable-firewall'         => '0',
                      'disable-mail-admin'       => '0',
                      'disable-shell'            => '0',
                      'disable-podcast'          => '0',
                      'disable-spamassassin'     => '0',
                      'disable-webmail'          => '0',
                      'enable-change-mode'       => '0',
                      'enable-create-csr'        => '0',
                      'enable-debug'             => '0',
                      'enable-install-cert'      => '0',
                      'enable-selfsigned-cert'   => '0',
                      'limited-file-manager'     => '0',
                    );

# the big one... the Cache
our %Cache = ( _groups               => undef,
               _nodes                => undef,
               _times                => undef,
               _services             => undef,
               _capabilities         => undef,
               _packages             => undef,
               _siteprefs            => undef,
               _domains              => undef,  ## for the benefit of user:list
               _domainadminness      => undef,  ## for the benefit of user:list
               _mailadminness        => undef,  ## for the benefit of user:list
               _userservices         => undef,  ## for the benefit of user:list
               _pwentries            => undef,  ## for the benefit of user:list
             );

##############################################################################

## load application modules

for my $service ( grep { $EXT_SERVICES{$_} } keys %EXT_SERVICES ) {
    (my $module = $service ) =~ s/-/::/g;
    $module = "VSAP::Server::Modules::vsap::$module";
    (my $fclass = "$module.pm") =~ s!::!/!g;
    if (exists $INC{$fclass}) {
        print STDERR "$fclass already included\n" if $DEBUG;
        next;
    }
    eval "require $module";
    if ($@) {
        print STDERR "Error including module: $@\n";
        next;
    }
}

##############################################################################

## these are the only legitimate members of the config class
use fields qw( uid
               dom
               username
               maxsites
               bwquota
               is_dirty
               is_valid
               server_name
               server_admin
               auto_refresh
               auto_compat );

##############################################################################

sub add_domain
{
    my $self   = shift;
    my $domain = shift;

    ($Cache{_nodes}->{domains_node}) ||= $self->{dom}->findnodes('/config/domains');

    unless ($Cache{_nodes}->{domains_node}) {
        $Cache{_nodes}->{domains_node} = $self->{dom}->createElement('domains');
        ($Cache{_nodes}->{conf_node}) ||= $self->{dom}->findnodes('/config')
          or return;
        $Cache{_nodes}->{conf_node}->appendChild($Cache{_nodes}->{domains_node});
        VSAP::Server::Modules::vsap::logger::log_message("config: added domains node");
        $self->{is_dirty} = 1;
    }

    ## make sure $domain does not already exist
    return if $self->{dom}->find("/config/domains/domain[name='$domain']");

    $self->_parse_apache(domain => $domain);
}

##############################################################################

sub disabled
{
    my $self = shift;
    return unless $self->{dom};
    my $disable = shift;

    if (defined $disable) {
        local $> = $) = 0;  ## regain privileges for a moment
        if ($IS_LINUX) {
            system('usermod', ( $disable ? '-L' : '-U' ), $self->{username}); ## FIXME: check return value
        }
        else {
            system('pw', ( $disable ? 'lock' : 'unlock' ), $self->{uid}); ## FIXME: check return value
        }
        # append a trace in the message log
        my $action = $disable ? "disabled" : "enabled";
        VSAP::Server::Modules::vsap::logger::log_message("config: $action user '$self->{username}'");
    }

    my $disabled;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $pass = (getpwuid($self->{uid}))[1];
        ## NOTE: if $pass starts with '!' then disabled (on Linux)
        ## NOTE: if $pass starts with '*LOCKED*' then disabled (on FreeBSD)
        ## NOTE: if $pass includes '*DISABLED*' then user domain disabled (by CPX)
        $disabled = (($pass =~ /^\!|\*LOCKED\*/) || ($pass =~ /\*DISABLED\*/));
    }

    return $disabled;
}

##############################################################################

sub capabilities
{
    my $self = shift;
    my %capa = @_;
    unless ($self->{dom}) {
        return {};
    }

    ## find the capa node
    ($Cache{_nodes}->{capa_node}) ||= $Cache{_nodes}->{user_node}->findnodes("capabilities")
      or do {
          ## couldn't find the capa node!
          carp "Couldn't find the capa node for " . $self->{username} . "\n";
          return {};
      };

    $Cache{_capabilities} ||= { map { $_->localname => 1 } $Cache{_nodes}->{capa_node}->childNodes() };

    if (keys %capa) {
        for my $service ( keys %capa ) {
            next unless $CAPABILITIES{$service};  ## skip bogus services
            next if   $capa{$service} &&   $Cache{_capabilities}->{$service};
            next if ! $capa{$service} && ! $Cache{_capabilities}->{$service};

            ## give capability
            if ($capa{$service}) {
                $Cache{_nodes}->{capa_node}->appendChild( $self->{dom}->createElement($service) );
                $Cache{_capabilities}->{$service} = 1;
                VSAP::Server::Modules::vsap::logger::log_message("config: giving capability '$service' to $self->{username}");
            }

            ## remove capability
            else {
                my ($serv_node) = $Cache{_nodes}->{capa_node}->findnodes("$service")
                  or do {
                      carp "Could not find child $service\n";
                      next;
                  };
                $Cache{_nodes}->{capa_node}->removeChild($serv_node);
                delete $Cache{_capabilities}->{$service};
                VSAP::Server::Modules::vsap::logger::log_message("config: removing capability '$service' from $self->{username}");
            }
            $self->{is_dirty} = 1;
        }
    }

    ## update w/ platform overrides
    for my $service ( keys %SERVICES ) {
        next if $Cache{_capabilities}->{$service};

        ## FIXME: working on this chunk

        if ($Cache{_nodes}->{user_node}->find("services/$service")) {
            $Cache{_nodes}->{capa_node}->appendChild($self->{dom}->createElement($service));
            $Cache{_capabilities}->{$service} = 1;
            VSAP::Server::Modules::vsap::logger::log_message("config: giving capability '$service' to $self->{username}");
            $self->{is_dirty} = 1;
        }
    }

    ## populate return hash
    return $Cache{_capabilities};
}

##############################################################################

sub capability
{
    return feature(shift, 'capabilities', @_);
}

##############################################################################

sub commit
{
    return unless $_[0]->{is_dirty};
    return unless $_[0]->{dom};

    VSAP::Server::Modules::vsap::backup::backup_system_file($CONFIG);
    VSAP::Server::Modules::vsap::logger::log_message("config: commiting changes to cpx.conf");

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment

        ## toString does not preserve utf8-goodness. We still get the
        ## atomic rename, which was the original race condition anyway.
        my $tmp = "$CONFIG.$$.tmp";
        if (open my $cpxfh, ">", $tmp) {
            binmode $cpxfh;
            $_[0]->{dom}->toFH($cpxfh, 1);
            close($cpxfh);
            chmod 0600, $tmp;  ## make user-read/writable only
            chown 0, 0, $tmp;  ## make root-owned
            rename $tmp, $CONFIG if (-s "$tmp");
            unlink($tmp) if (-e "$tmp");
        }
        else {
            ## do something with the error ($!) here... perhaps die?
            die("can't commit cpx.conf: open() failed for $tmp ($!)");
        }
    }

    $_[0]->{is_dirty} = 0;
    return 1;
}

##############################################################################

sub compat
{
    my $self = shift;
    my $c_version;

    return unless $self->{dom};

    if (! $Cache{_nodes}->{meta_node}) {
        unless (($Cache{_nodes}->{meta_node}) = $self->{dom}->findnodes('/config/meta')) {
            return;
        }
    }
    my ($v_node) = $Cache{_nodes}->{meta_node}->findnodes('version');

    ## no version node? Put in the oldest version we know about
    unless ($v_node) {
        $v_node = $self->{dom}->createElement('version');
        $v_node->appendTextNode("0.12");
        $Cache{_nodes}->{meta_node}->appendChild($v_node);
        VSAP::Server::Modules::vsap::logger::log_message("config: creating version node");
        $self->{is_dirty} = 1;
    }

    return unless $c_version = $v_node->textContent();

    ## insert compat version checks here (as req'd)
}

##############################################################################

sub debug
{
    my($subr) = (caller(1))[3] || '';
    $subr =~ s/^.*:://;

    if ($TRACE_PAT) {
        return unless $subr;
        return unless $subr =~ $TRACE_PAT;
    }

    my $msg   = shift;
    my $level = shift || 1;

    if ($TRACE > 1) {
        return unless $level >= $TRACE;
    }

    $msg =~ s/[\r\n]$//g;  ## strip newlines
    $msg =    "[$$] " . $msg if $TRACE_PID;
    $msg = "($subr) " . $msg if $TRACE_SUB;

    if ($LOGSTYLE eq 'syslog') {
        system('/usr/bin/logger', '-p', 'daemon.notice', $msg);
    }

    elsif ($LOGSTYLE eq 'stdout') {
        print $msg, "\n";
    }

    else {
        print STDERR "[$$]: $msg\n";
    }
}

##############################################################################

## domain_admin( 'joe' ) ## am I domain admin for joe?
## domain_admin( user => 'joe' )  ## same as above
## domain_admin( domain => 'foo.com' )
## domain_admin( set => 1 );  ## make me a domain admin
## domain_admin( admin => 'joe' ) ## is joe a domain admin?
## domain_admin( admin => 'joe', set => 1) ## make joe a domain admin

sub domain_admin
{
    my $self = shift;
    return unless $self->{dom};
    my $user = $self->{username};
    my %parms = ( scalar @_ % 2 ? (user => @_) : @_ );

    ## am I the domain admin for this domain?
    if ($parms{domain}) {
        # debug("checking for domain admin of " . $parms{domain});
        my $dom = $parms{domain};
        return
          ( $self->{dom}->findvalue("/config/domains/domain[name = '$dom']/admin[1]")
            eq $user );
    }

    ## am I the domain admin for this user (who is not myself)?
    elsif ($parms{user} && ($parms{user} ne $user)) {
        # debug("checking for domain admin for the user");
        my $eu = $parms{user};
        my $eu_domain = $self->{dom}->findvalue("/config/users/user[\@name='$eu']/domain");
        my $eu_domain_admin = $self->{dom}->findvalue("/config/domains/domain[name ='$eu_domain']/admin[1]");
        return ($eu_domain_admin eq $user );
    }

    ## is this user a domain admin?
    elsif ($parms{admin}) {
        # debug("checking domain admin for " . $parms{admin});
        return $self->_set_domain_admin($parms{admin}, $parms{set});
    }

    ## grant or revoke my domain_admin privs
    elsif(defined $parms{set}) {
        $self->_set_domain_admin($user, $parms{set});
    }

    ## am I (self) a domain admin (generally)?
    else {
        return $self->{dom}->find("/config/users/user[\@name='$user']/domain_admin");
    }
}

##############################################################################

## return list of domain admins

sub domain_admins
{
    my $self = shift;
    return [] unless $self->{dom};

    ## we use a hash for two reasons: 1) prevent duplicates in a
    ## broken cpx.conf file and 2) it allows us to manipulate it
    ## before we return its contents. Mostly a "what-if" decision
    my %admins = ();
    $admins{$_}++ for map { $_->getAttribute('name') } $self->{dom}->findnodes('/config/users/user[domain_admin]');
    return [ keys %admins ];
}

##############################################################################

## returns a hashref of domain => admin pairs

sub domains
{
    my $self = shift;
    return {} unless $self->{dom};
    my %parms = ( scalar @_ % 2 ? (admin => @_) : @_ );
    my $xpath = '';  ## /config/domains/domain';

    ## select all domains for this admin
    if ($parms{admin}) {
        $xpath = "domain[admin='$parms{admin}']";
    }

    ## select this one domain
    elsif ($parms{domain}) {
        $xpath = "domain[name='$parms{domain}']";
    }

    my @nodes = ( $xpath
                  ? $Cache{_nodes}->{domains_node}->findnodes($xpath)
                  : $Cache{_nodes}->{domains_node}->childNodes() );

    return { map { $_->findvalue('name[1]') => $_->findvalue('admin[1]') } @nodes };
}

##############################################################################

## I am a domain admin; these are the capabilities of my end users

sub eu_capabilities
{
    my $self = shift;
    my %capa = @_;
    my $username = $self->{username};
    return unless $self->{dom};

    ## special case: username is a server admin
    if ( $server_admins{$username} ) {
        my %EU_CAPABILITIES = %CAPABILITIES;
        $EU_CAPABILITIES{'zeroquota'} = 0;
        return { %EU_CAPABILITIES } ;
    }


    ## make sure we're a domain admin
    unless ($self->domain_admin) {
        return;
    }

    ## special case: username is the system level domain admin
    if ($username eq $VSAP::Server::Modules::vsap::globals::APACHE_RUN_USER) {
        my %EU_CAPABILITIES = %CAPABILITIES;
        $EU_CAPABILITIES{'zeroquota'} = 0;
        return { %EU_CAPABILITIES } ;
    }

    ## find user node
    ($Cache{_nodes}->{user_node}) ||= $self->{dom}->findnodes("/config/users/user[\@name='$username'][1]")
      or do {
          carp "Couldn't find user node for $username\n";
          return;
      };

    ## find the eu_capa node
    if (! $Cache{_nodes}->{eu_capa_node}) {
        unless(($Cache{_nodes}->{eu_capa_node}) = $Cache{_nodes}->{user_node}->findnodes('eu_capabilities[1]')) {
            $Cache{_nodes}->{eu_capa_node} = $self->{dom}->createElement('eu_capabilities');
            $Cache{_nodes}->{user_node}->appendChild($Cache{_nodes}->{eu_capa_node});
        }
    }

    my %eu_capa_nodes = map { $_->localname => 1 } $Cache{_nodes}->{eu_capa_node}->childNodes();

    if (keys %capa) {
        for my $service ( keys %capa ) {
            next unless $CAPABILITIES{$service};  ## skip bogus services
            next if   $capa{$service} &&   $eu_capa_nodes{$service};
            next if ! $capa{$service} && ! $eu_capa_nodes{$service};

            ## give capability
            if ($capa{$service}) {
                $Cache{_nodes}->{eu_capa_node}->appendChild( $self->{dom}->createElement($service) );
                VSAP::Server::Modules::vsap::logger::log_message("config: giving capability '$service' to $username");
            }

            ## remove capability
            else {
                my($serv_node) = $Cache{_nodes}->{eu_capa_node}->findnodes("$service")
                  or do {
                      carp "Could not find child $service\n";
                      next;
                  };
                $Cache{_nodes}->{eu_capa_node}->removeChild($serv_node);
                VSAP::Server::Modules::vsap::logger::log_message("config: removing capability '$service' from $username");
            }
            $self->{is_dirty} = 1;
        }
    }

    ## populate return hash
    return { map { $_->nodeName => 1 } grep { $CAPABILITIES{$_->nodeName} }
             $Cache{_nodes}->{eu_capa_node}->childNodes() };
}

##############################################################################

## return list of eu_prefixes

sub eu_prefix_list
{
    my $self = shift;
    return [] unless $self->{dom};

    my %eu_prefixes = ();
    $eu_prefixes{$_}++ for map { $_->findvalue('eu_prefix') } $self->{dom}->findnodes('/config/users/user[domain_admin]');
    foreach my $eup (keys %eu_prefixes) {
         delete($eu_prefixes{$eup}) if ($eup eq "");
    }
    return [ keys %eu_prefixes ];
}

##############################################################################

sub feature
{
    my $self = shift;
    return unless $self->{dom};
    my $class = shift;
    my $service = shift;
    my $user = $self->{username};

    ## necessary to detect installations of %EXT_SERVICES
    $self->refresh
      if $self->{auto_refresh};

    my $rval;
    my %stuff = %{$Cache{"_$class"}} if $Cache{"_$class"};  ## have to do this or tests in 05_cache.t break
    return ( exists $stuff{$service}
             ? $Cache{"_$class"}->{$service}
             : ( $self->{dom}->find("/config/users/user[\@name='$user']/$class/$service")
                 ? 1 : 0 ) );
}

##############################################################################

sub get_groups
{
    my $self = shift;
    my $user = shift || $self->{username};
    return _get_groups($user);
}

##############################################################################

sub init
{
    my $self = shift;
    my %args = @_;

    debug("object recently blessed; about to commit existing object") if $TRACE;
    $self->commit;  ## in case we're reusing this object

    undef $Cache{_nodes};
    undef $Cache{_services};
    undef $Cache{_capabilities};
    undef $Cache{_packages};
    undef $Cache{_siteprefs};
    undef $self->{uid};
    undef $self->{dom};
    undef $self->{username};
    undef $self->{maxsites};
    undef $self->{is_dirty};
    undef $self->{server_name};
    undef $self->{server_admin};
    undef $self->{auto_refresh};
    undef $self->{auto_compat};
    undef $self->{is_valid};

    if ($args{username}) {
        $self->{username} = $args{username};
    }

    if ($args{maxsites}) {
        $self->{maxsites} = $args{maxsites};
    }

    if ($args{uid} || $self->{username}) {
        $self->{uid} = ( $args{uid} ? $args{uid} : (getpwnam($self->{username}))[2] );
        $self->{username} = getpwuid($self->{uid})
          unless $self->{username};
    }

    ## default: 1
    $self->{auto_refresh} = ( defined $self->{auto_refresh}
                              ? $self->{auto_refresh}
                              : ( exists $args{auto_refresh} ? $args{auto_refresh} : 1 ) );
    $self->{auto_compat}  = ( defined $self->{auto_compat}
                              ? $self->{auto_compat}
                              : ( exists $args{auto_compat}  ? $args{auto_compat}  : 1 ) );
    debug("self reset. Checking uid") if $TRACE;

    ## only read for extant, non-root uids
    unless ($self->{uid}) {
        $self->{dom} = undef;
        return;
    }

    my $username = $self->{username};

    debug("About to create dom object") if $TRACE;

    if (! $self->{dom}) {
        ## don't bother if file doesn't exist (BUG12728, BUG12785)
        if (-e $CONFIG) {
            debug("Reading dom from file") if $TRACE;
            # make several attempts to read file if failure occurs (BUG27007)
            my $attempt = 1;
            my $numtries = 10;
            while ($attempt <= $numtries) {
                eval {
                    my $parser = new XML::LibXML;
                    local $> = $) = 0;  ## regain privileges for a moment
                    $parser->keep_blanks(0); ## Don't care about blanks
                    $self->{dom} = $parser->parse_file( $CONFIG )
                      or die;  ## this is trapped by eval and put in $@, if you need it
                };
                if ($@) {
                    debug("Error reading '$CONFIG': $@ (attempt \#$attempt)");
                    # if parse_file() fails, sleep and try again (BUG27007)
                    sleep(1);
                    $attempt++;
                }
                else {
                    last;
                }
            }
        }
        undef $Cache{_domains};
        undef $Cache{_domainadminness};
        undef $Cache{_mailadminness};
        undef $Cache{_userservices};
    }

    if ($@) {
        debug("Error reading '$CONFIG': giving up");
        $self->{dom} = undef;
        return;
    }

    debug("Created dom object") if $TRACE;

    unless ($self->{dom}) {
        debug("No dom found, creating new dom") if $TRACE;
        $self->{dom} = XML::LibXML::Document->new('1.0', 'UTF-8');
        $self->{dom}->createInternalSubset( "cpx_config", undef, 'cpx_config.dtd' );
        my $m_node = $self->{dom}->createElement('meta');
        $m_node->appendTextChild( version => $VERSION );
        $m_node->appendTextChild( warning => "Do not edit this file directly" );
        $m_node->appendTextChild( rootbeer => "Americana" );
        $m_node->appendTextChild( fruit_pie => "Strawberry Rhubarb" );
        $m_node->appendTextChild( ginger_ale => "Buderim Ginger Brew" );
        $m_node->appendTextChild( pepper_sauce => "Tabasco, McIlhenny Co., Avery Island, La." );
        $m_node->appendTextChild( indian_proverb => "Call on God, but row away from the rocks." );
        $m_node->appendTextChild( potshot => "Micros~1: For when quality, reliability, and security just aren't that important!" );
        $Cache{_nodes}->{conf_node} = $self->{dom}->createElement('config');
        $self->{dom}->setDocumentElement($Cache{_nodes}->{conf_node});
        $Cache{_nodes}->{conf_node}->appendChild($m_node);
        VSAP::Server::Modules::vsap::logger::log_message("config: created default meta node");
        $self->{is_dirty} = 1;
    }

    if (! $Cache{_nodes}->{conf_node}) {
        unless (($Cache{_nodes}->{conf_node}) = $self->{dom}->findnodes('/config[1]')) {
            debug("About to create config node") if $TRACE;
            $Cache{_nodes}->{conf_node} = $self->{dom}->createElement('config');
            $self->{dom}->setDocumentElement($Cache{_nodes}->{conf_node});
            VSAP::Server::Modules::vsap::logger::log_message("config: created config node");
            $self->{is_dirty} = 1;
        }
    }

    if (! $Cache{_nodes}->{maxsites_node}) {
        unless (($Cache{_nodes}->{maxsites_node}) = $Cache{_nodes}->{conf_node}->findnodes('maxsites[1]')) {
            if ($self->{maxsites})
            {
                debug("About to create maxsites node") if $TRACE;
                $Cache{_nodes}->{maxsites_node} = $self->{dom}->createElement('maxsites');
                $Cache{_nodes}->{maxsites_node}->setAttribute( count => $self->{maxsites} );
                $Cache{_nodes}->{conf_node}->appendChild($Cache{_nodes}->{maxsites_node});
            }
        }
    }

    if ($self->{maxsites})
    {
        $Cache{_nodes}->{maxsites_node}->setAttribute( count => $self->{maxsites});
        $self->{is_dirty} = 1;
    }

    if (! $Cache{_nodes}->{domains_node}) {
        unless (($Cache{_nodes}->{domains_node}) = $Cache{_nodes}->{conf_node}->findnodes('domains[1]')) {
            debug("About to create domains node") if $TRACE;
            $Cache{_nodes}->{domains_node} = $self->{dom}->createElement('domains');
            $self->_parse_apache();  ## update w/ list of domains on the box
            $Cache{_nodes}->{conf_node}->appendChild($Cache{_nodes}->{domains_node});
        }
    }

    ## NOTE: set defaults if <domains> node already exists; if you add
    ## NOTE: additional side-effects to $self in _parse_apache, make
    ## NOTE: sure they receive defaults here also for times when
    ## NOTE: _parse_apache is not called
    $self->{server_name}  ||= $Cache{_nodes}->{domains_node}->findvalue('domain[@type="server"]/name');
    $self->{server_admin} ||= $Cache{_nodes}->{domains_node}->findvalue('domain[@type="server"]/admin');

    if (! $Cache{_nodes}->{users_node}) {
        unless (($Cache{_nodes}->{users_node}) = $Cache{_nodes}->{conf_node}->findnodes('users[1]')) {
            debug("About to create users node") if $TRACE;
            $Cache{_nodes}->{users_node} = $self->{dom}->createElement('users');
            $self->_parse_passwd();
            $Cache{_nodes}->{conf_node}->appendChild($Cache{_nodes}->{users_node});
        }
    }

    ## populate user -> domain hash for the benefit of user:list
    ## populate user -> domainadminess hash for the benefit of user:list
    ## populate user -> mailadminess hash for the benefit of user:list
    ## these hashes eliminate the need for the expensive "switch_user"
    ## business (which was only used in the old user:list anyway)
    if (! $Cache{_domains}) {   ## implies "adminness" hashes are undef'd as well
        foreach my $node ( $Cache{_nodes}->{users_node}->childNodes() ) {
            my $user = $node->getAttribute('name');
            $Cache{_domainadminness}->{$user} = 0;
            foreach my $subnode ( $node->childNodes() ) {
                my $nodename = $subnode->nodeName();
                if ($nodename eq "domain") {
                    my $value = $subnode->textContent();
                    $Cache{_domains}->{$user} = $value;
                }
                elsif ($nodename eq "domain_admin") {
                    $Cache{_domainadminness}->{$user} = 1;
                }
                elsif ($nodename eq "mail_admin") {
                    $Cache{_mailadminness}->{$user} = 1;
                }
                elsif ($nodename eq "services") {
                    $Cache{_userservices}->{$user} = "";
                    foreach my $capanode ( $subnode->childNodes() ) {
                        my $capanodename = $capanode->nodeName();
                        $Cache{_userservices}->{$user} .= $capanodename . ":";
                    }
                    chop($Cache{_userservices}->{$user}) if ($Cache{_userservices}->{$user} ne "");
                }
            }
        }
    }

    ##
    ## create a user node for *this* user
    ##
    if (! $Cache{_nodes}->{user_node}) {
        unless (($Cache{_nodes}->{user_node}) = $Cache{_nodes}->{users_node}->findnodes("user[\@name='$username'][1]")) {
            debug("About to create user node for '$username'") if $TRACE;
            $Cache{_nodes}->{user_node} = $self->{dom}->createElement('user');
            $Cache{_nodes}->{user_node}->setAttribute( name => $username );
            $Cache{_nodes}->{users_node}->appendChild($Cache{_nodes}->{user_node});
        }
    }

    ## set domain node for *this* user
    unless ($Cache{_nodes}->{user_node}->findnodes('domain[1]')) {
        debug("Setting domain nodes for '$username'") if $TRACE;
        $self->_set_domain_node(); ## made dirty internally
    }

    ## set capabilities node for *this* user
    if (! $Cache{_nodes}->{capa_node}) {
        unless (($Cache{_nodes}->{capa_node}) = $Cache{_nodes}->{user_node}->findnodes("capabilities[1]")) {
            debug("Setting capa nodes for '$username'") if $TRACE;
            $Cache{_nodes}->{capa_node} = $self->{dom}->createElement('capabilities');
            $Cache{_nodes}->{user_node}->appendChild($Cache{_nodes}->{capa_node});
        }
    }

    ## set services node for *this* user
    if (! $Cache{_nodes}->{serv_node}) {
        unless (($Cache{_nodes}->{serv_node}) = $Cache{_nodes}->{user_node}->findnodes("services[1]")) {
            debug("Setting serv nodes for '$username'") if $TRACE;
            $Cache{_nodes}->{serv_node} = $self->{dom}->createElement('services');
            $Cache{_nodes}->{user_node}->appendChild($Cache{_nodes}->{serv_node});
        }
    }

    ## do compat check
    debug("Doing compat check") if $TRACE;
    $self->compat if $self->{auto_compat};

    ## update platform
    debug("Doing platform_refresh") if $TRACE;
    $self->platform_refresh if $self->{auto_refresh};

    ## refresh user attributes
    debug("Doing refresh") if $TRACE;
    $self->refresh if $self->{auto_refresh};

    $self->{is_valid} = 1;

    return 1;
}

##############################################################################

sub is_valid
{
    my $self = shift;
    return $self->{is_valid};
}

##############################################################################

## mail_admin( set => 1 );  ## make me a mail admin
## mail_admin( set => 0 );  ## remove me as a mail admin
## mail_admin( admin => 'joe' ) ## is joe a mail admin?
## mail_admin( admin => 'joe', set => 1) ## make joe a mail admin

sub mail_admin
{
    my $self = shift;
    return unless $self->{dom};
    my $user = $self->{username};
    my %parms = @_;

    ## is this user a mail admin?
    if ($parms{admin}) {
        # debug("checking mail admin for " . $parms{admin});
        return $self->_set_mail_admin($parms{admin}, $parms{set});
    }

    ## grant or revoke my mail_admin privs
    elsif (defined $parms{set}) {
        $self->_set_mail_admin($user, $parms{set});
    }

    ## am I (self) a mail admin (generally)?
    else {
        return $self->{dom}->find("/config/users/user[\@name='$user']/mail_admin");
    }
}

##############################################################################

sub new
{
    debug("acquiring lock...") if $TRACE;
    my $tries = 0;
  GET_LOCK: {
        $tries++;
        ## check for reused FH. This is for reused objects which don't
        ## go out of scope (calling DESTROY()) until new() returns.
        ## FIXME: find the test case for this one and mark it
        if (defined $SEMAPHORE) {
            if ($TRACE) {
                debug("wiping out stale semaphore");
                my ($pkg, undef, $ln) = caller;
                debug("caller $pkg line $ln");
            }
            close $SEMAPHORE;
            undef $SEMAPHORE;
        }

        ## this overwrites the semaphore immediately, so we don't
        ## store anything important in there.
        unless (open $SEMAPHORE, "> $TMPLOCK") {
            debug("[$$] Error getting semaphore: ($!). You may need to restart vsapd");
            if ($tries > 5) {
                die "Couldn't open semaphore after 5 tries.";
            }
            sleep 1;
            redo GET_LOCK;
        }

        ## allow non-privileged process to access the semaphore
        chmod 0777, $TMPLOCK;

        ## get exclusive lock on semaphore
        $tries = 0;
        while( ! flock $SEMAPHORE, LOCK_EX ) {
            if ($tries > 5) {
                die "Couldn't lock semaphore $SEMAPHORE after 5 tries.";
            }
            sleep(1); $tries++;
        }

        ## have a lock now. Proceed.
        last GET_LOCK;
    }

    debug("lock acquired. Beginning init") if $TRACE;
    my VSAP::Server::Modules::vsap::config $self = shift; ## comment out this line and
    $self = fields::new($self) unless ref($self);         ## this line to avoid 'fields'
    $self->init(@_);
    return $self;
}

##############################################################################

sub packages
{
    my $self = shift;
    unless ($self->{dom}) {
        return {};
    }
    return $Cache{_packages};
}

##############################################################################

## only update from platform on-demand to avoid lots of overhead

sub platform_refresh
{
    my $self = shift;

    return unless $Cache{_nodes}->{conf_node};

    ($Cache{_nodes}->{domains_node}) ||= $Cache{_nodes}->{conf_node}->findnodes('domains[1]')
        or return;

    ($Cache{_nodes}->{meta_node}) ||= $self->{dom}->findnodes('/config/meta')
        or return;

    if (! $Cache{_nodes}->{cache_node}) {
        unless (($Cache{_nodes}->{cache_node}) = $Cache{_nodes}->{meta_node}->findnodes('cache')) {
            $Cache{_nodes}->{cache_node} = $self->{dom}->createElement('cache');
            $Cache{_nodes}->{meta_node}->appendChild($Cache{_nodes}->{cache_node});
        }
    }

    ## do Apache httpd.conf cache check
    if (! $DISABLE_CACHING && $Cache{_nodes}->{cache_node}) {
        my $ap_conf;
        ($ap_conf) = $Cache{_nodes}->{cache_node}->findnodes('apache_conf[1]')
          or do {
              $ap_conf = $self->{dom}->createElement('apache_conf');
              $ap_conf->appendTextNode(0);
              $Cache{_nodes}->{cache_node}->appendChild($ap_conf);
              VSAP::Server::Modules::vsap::logger::log_message("config: created apache_conf cache node");
              $self->{is_dirty} = 1;
          };

        my $last_apache_mod_time = $ap_conf->textContent() || 0;
        my $curr_apache_mod_time = _get_apache_config_modtime();
        if ($last_apache_mod_time < $curr_apache_mod_time) {
            ## we're out of date
            $self->_parse_apache(modtime => $curr_apache_mod_time);
            my $new_ap_conf = $self->{dom}->createElement('apache_conf');
            $new_ap_conf->appendTextNode($curr_apache_mod_time);
            $ap_conf->replaceNode($new_ap_conf);
            VSAP::Server::Modules::vsap::logger::log_message("config: updated timestamp for apache_conf cache node");
            $self->{is_dirty} = 1;
        }
        else {
            debug("Apache cache hit! You just saved a bundle.") if $TRACE;
        }
    }
    else {
        $self->_parse_apache();
    }

    ##
    ##
    ($Cache{_nodes}->{users_node}) ||= $Cache{_nodes}->{conf_node}->findnodes('users')
        or return;
    ##
    ##

    ## do /etc/passwd cache check
    if (! $DISABLE_CACHING && $Cache{_nodes}->{cache_node}) {
        my $etc_pwd;
        ($etc_pwd) = $Cache{_nodes}->{cache_node}->findnodes('etc_passwd')
          or do {
              $etc_pwd = $self->{dom}->createElement('etc_passwd');
              $etc_pwd->appendTextNode(0);
              $Cache{_nodes}->{cache_node}->appendChild($etc_pwd);
              VSAP::Server::Modules::vsap::logger::log_message("config: created etc_passwd cache node");
              $self->{is_dirty} = 1;
          };

        my $etc_pwd_cache = $etc_pwd->textContent() || 0;
        my $ts_etc_pwd = (lstat('/etc/passwd'))[9] || 0;
        if ($etc_pwd_cache < $ts_etc_pwd) {
            ## we're out of date
            $self->_parse_passwd();
            my $new_etc_pwd = $self->{dom}->createElement('etc_passwd');
            $new_etc_pwd->appendTextNode($ts_etc_pwd);
            $etc_pwd->replaceNode($new_etc_pwd);
            VSAP::Server::Modules::vsap::logger::log_message("config: updated timestamp for etc_passwd cache node");
            $self->{is_dirty} = 1;
        }
        else {
            debug("passwd cache hit! You just saved a bundle.") if $TRACE;
        }
    }

    else {
        $self->_parse_passwd();
    }

    ## do package checks
    my $parse_required = 0;
    if ($IS_LINUX) {
        ## no caching possible for Linux (booooo!)
        $parse_required = 1;
    }
    else {
        ## do package cache check
        if (! $DISABLE_CACHING && $Cache{_nodes}->{cache_node}) {
            my $rc_conf;
            ($rc_conf) = $Cache{_nodes}->{cache_node}->findnodes('rc_conf')
              or do {
                  $rc_conf = $self->{dom}->createElement('rc_conf');
                  $rc_conf->appendTextNode(0);
                  $Cache{_nodes}->{cache_node}->appendChild($rc_conf);
                  VSAP::Server::Modules::vsap::logger::log_message("config: created rc_conf cache node");
                  $self->{is_dirty} = 1;
              };

            my $rc_conf_cache = $rc_conf->textContent() || 0;
            my $ts_rc_conf = (lstat($RC_CONF))[9] || 0;
            if ($rc_conf_cache < $ts_rc_conf) {
                ## we're out of date
                $parse_required = 1;
                my $new_rc_conf = $self->{dom}->createElement('rc_conf');
                $new_rc_conf->appendTextNode($ts_rc_conf);
                $rc_conf->replaceNode($new_rc_conf);
                VSAP::Server::Modules::vsap::logger::log_message("config: updated timestamp for rc_conf cache node");
                $self->{is_dirty} = 1;
            }
            $parse_required = 1 if (! $Cache{_packages});
        }
        else {
            $parse_required = 1;
        }
    }
    if ($parse_required) {
        $self->_parse_packages();
    }
    else {
        debug("package cache hit! You just saved a smidgen.") if $TRACE;
    }

    ## do cpx site prefs file cache check
    $parse_required = 0;
    if (! $DISABLE_CACHING && $Cache{_nodes}->{cache_node}) {
        my $cpx_siteprefs;
        ($cpx_siteprefs) = $Cache{_nodes}->{cache_node}->findnodes('cpx_siteprefs')
          or do {
              $cpx_siteprefs = $self->{dom}->createElement('cpx_siteprefs');
              $cpx_siteprefs->appendTextNode(0);
              $Cache{_nodes}->{cache_node}->appendChild($cpx_siteprefs);
              VSAP::Server::Modules::vsap::logger::log_message("config: created cpx_siteprefs cache node");
              $self->{is_dirty} = 1;
          };

        my $cpx_siteprefs_cache = $cpx_siteprefs->textContent() || 0;
        my $ts_cpx_siteprefs = (lstat($CPX_SPF))[9] || 0;
        if ($cpx_siteprefs_cache < $ts_cpx_siteprefs) {
            ## we're out of date
            $parse_required = 1;
            my $new_cpx_siteprefs = $self->{dom}->createElement('cpx_siteprefs');
            $new_cpx_siteprefs->appendTextNode($ts_cpx_siteprefs);
            $cpx_siteprefs->replaceNode($new_cpx_siteprefs);
            VSAP::Server::Modules::vsap::logger::log_message("config: updated timestamp for cpx_siteprefs cache node");
            $self->{is_dirty} = 1;
        }
        $parse_required = 1 if (! $Cache{_siteprefs});
    }
    else {
        $parse_required = 1;
    }
    if ($parse_required) {
        $self->_parse_siteprefs();
    }
    else {
        debug("siteprefs cache hit! You just saved a smidgen.") if $TRACE;
    }

    ## do hostname cache check
    if (! $DISABLE_CACHING && $Cache{_nodes}->{cache_node}) {
        my $hn_node;
        my $hostname = $self->_get_hostname();
        ($hn_node) = $Cache{_nodes}->{cache_node}->findnodes('hostname')
          or do {
              $hn_node = $self->{dom}->createElement('hostname');
              $hn_node->appendTextNode($hostname);
              $Cache{_nodes}->{cache_node}->appendChild($hn_node);
              VSAP::Server::Modules::vsap::logger::log_message("config: created hostname cache node; set value to '$hostname'");
              $self->{is_dirty} = 1;
          };

        my $cached_hostname = $hn_node->textContent() || "foo.bar.com.tw";
        if ($cached_hostname ne $hostname ) {
            ## we're out of sync
            $self->_propagate_hostname($hostname, $cached_hostname);
            my $new_hn_node = $self->{dom}->createElement('hostname');
            $new_hn_node->appendTextNode($hostname);
            $hn_node->replaceNode($new_hn_node);
            VSAP::Server::Modules::vsap::logger::log_message("config: updated hostname cache node value from '$cached_hostname' to '$hostname'");
            $self->{is_dirty} = 1;
        }
        else {
            debug("hostname cache hit! You just saved a smidgeon.") if $TRACE;
        }
    }
    else {
        ## hostname check requires caching
    }
}

##############################################################################

## return primary domain name

sub primary_domain
{
    my $self = shift;

    unless ($self->{server_name}) {
        debug("Setting the primary domain name from _get_hostname") if $TRACE;
        my $hostname = $self->_get_hostname();
        $self->{server_name} = $hostname;
        debug("Primary hostname set now from _get_hostname") if $TRACE;
        chomp $self->{server_name};
    }

    return $self->{server_name};
}

##############################################################################

sub refresh
{
    my $self = shift;
    my $username = $self->{username};

    return unless $self->{dom};

    ($Cache{_nodes}->{user_node}) ||= $self->{dom}->findnodes("/config/users/user[\@name='$username'][1]")
      or do {
          carp "Couldn't find user node\n";
          return;
      };

    my %user_attrs = map { $_->localname => 1 } $Cache{_nodes}->{user_node}->childNodes();

    ## check status of user
    if ($self->disabled) {
        unless ($user_attrs{disabled}) {
            $Cache{_nodes}->{user_node}->appendChild( $self->{dom}->createElement('disabled') );
        }
    }
    else {
        if (my ($d_node) = $Cache{_nodes}->{user_node}->findnodes('disabled')) {
            $Cache{_nodes}->{user_node}->removeChild($d_node);
            delete $user_attrs{disabled};
        }
    }

    ## find services node
    ($Cache{_nodes}->{serv_node}) ||= $Cache{_nodes}->{user_node}->findnodes("services")
      or do {
          carp "Couldn't find services node\n";
          return;
      };

    ($Cache{_nodes}->{capa_node}) ||= $Cache{_nodes}->{user_node}->findnodes("capabilities")
      or do {
          carp "Couldn't find capabilities node\n";
          return;
      };

    my %s_updates = ();
    my %c_updates = ();

    ## core services are set here for each user
    my $groups = _get_groups($username);
    $Cache{_services}     ||= { map { $_->localname => 1 } $Cache{_nodes}->{serv_node}->childNodes() };
    $Cache{_capabilities} ||= { map { $_->localname => 1 } $Cache{_nodes}->{capa_node}->childNodes() };

    for my $service ( keys %SERVICES ) {
        ## check ftp
        if ($service eq 'ftp') {
            if ($groups->{$service}) {
                next if $Cache{_services}->{$service} && $Cache{_capabilities}->{$service};
                $s_updates{$service} = 1;
                $c_updates{$service} = 1;
            }

            else {
                next unless $Cache{_services}->{$service};
                $s_updates{$service} = 0;
            }
        }

        ## check sftp
        elsif ($service eq 'sftp') {
            if ($groups->{$service}) {
                next if $Cache{_services}->{$service} && $Cache{_capabilities}->{$service};
                $s_updates{$service} = 1;
                $c_updates{$service} = 1;
            }
            else {
                next unless $Cache{_services}->{$service};
                $s_updates{$service} = 0;
            }
        }

        ## check mail
        elsif ($service eq 'mail') {
            ## assign the correct mail group depending on platform
            my $mailGroup = ( $IS_LINUX ) ? "mailgrp" : "imap";
            if ($groups->{$mailGroup}) {
                next if $Cache{_services}->{$service} && $Cache{_capabilities}->{$service};
                $s_updates{$service} = 1;
                $c_updates{$service} = 1;
            }
            else {
                next unless $Cache{_services}->{$service};
                $s_updates{$service} = 0;
            }
        }

        ## check shell
        elsif ($service eq 'shell') {
            if ((getpwnam($username))[8] &&
                ((getpwnam($username))[8] !~ /(?:nologin|nonexistent|noshell|false|true)/)) {
                next if $Cache{_services}->{$service} && $Cache{_capabilities}->{$service};
                $s_updates{$service} = 1;
                $c_updates{$service} = 1;
            }
            else {
                next unless $Cache{_services}->{$service};
                $s_updates{$service} = 0;
            }
        }
    }

    ## 3rd party applications are set here. Select only EXT_SERVICES
    ## that have an external API we can call via nv_* functions
    for my $service ( grep { $EXT_SERVICES{$_} } keys %EXT_SERVICES ) {

        if ($TRACE) {
            debug("nodes: ($service): " . ($Cache{_services}->{$service} ? $Cache{_services}->{$service} : '') );
            debug("nodes: ($service): " . ($Cache{_capabilities}->{$service} ? $Cache{_capabilities}->{$service} : '') );
        }

        ## see if we have the service set already
        my $status;
        NO_STRICT: {
              (my $status_function = $service) =~ s/-/::/g;
              $status_function = 'VSAP::Server::Modules::vsap::' . $status_function . '::nv_status';

              local $> = getpwnam($username);           ## drop privs; this also sets $> so the
              no strict 'refs';                         ## nv_* functions will behave like VSAP
              $status = &$status_function($username);   ## (which is always setuid to the user)
          }

        debug("status of $service: $status") if $TRACE;

        if ($status eq 'on') {
            next if $Cache{_services}->{$service} && $Cache{_capabilities}->{$service};
            $s_updates{$service} = 1;
            $c_updates{$service} = 1;
        }

        else {
            next unless $Cache{_services}->{$service};
            $s_updates{$service} = 0;
        }
    }

    if (keys %s_updates) {
        debug("doing 'services'") if $TRACE;
        $self->services(%s_updates);
    }

    if (keys %c_updates) {
        debug("doing 'capabilities'") if $TRACE;
        $self->capabilities(%c_updates);
    }

    debug("exiting refresh") if $TRACE;
}

##############################################################################

## we don't automatically demote from domain admin to end user since
## "domain admin" is a property of _potential_ admin-ness, not
## necessarily actual admin-ness. Removing the domain_admin element
## from a user node is an application-level decision (i.e., in the
## VSAP for vsap:domain).

sub remove_domain
{
    my $self   = shift;
    my $domain = shift;

    ( $Cache{_nodes}->{domains_node} ) ||= $self->{dom}->findnodes('/config/domains')
      or return;

    for my $node ( $Cache{_nodes}->{domains_node}->findnodes("domain[name='$domain']") ) {
        $Cache{_nodes}->{domains_node}->removeChild($node);
        VSAP::Server::Modules::vsap::logger::log_message("config: removing domain node for '$domain'");
        $self->{is_dirty} = 1;
    }
}

##############################################################################

## returns a hashref of user => domain pairs

sub users
{
    my $self   = shift;
    return {} unless $self->{dom};
    my %args   = @_;
    my $xpath  = '';

    if ($args{domain}) {
        $xpath = "user[domain = '$args{domain}']";
    }

    elsif ($args{admin}) {
        $xpath = "user[domain = /config/domains/domain[admin = '$args{admin}']/name]";
    }

    my @nodes = ();
    if ($xpath) {
        @nodes = $Cache{_nodes}->{users_node}->findnodes($xpath);
    }
    else {
        ## an admin
        unless ($Cache{_nodes}->{user_nodes}) {
            $Cache{_nodes}->{user_nodes} = { map { $_->getAttribute('name') => $_ }
                                             $Cache{_nodes}->{users_node}->childNodes() };
        }
        @nodes = values %{$Cache{_nodes}->{user_nodes}};
    }

    _get_pwentries();  ## populates $Cache{_pwentries}

    my %users = ();
    for my $node ( @nodes ) {
        my $user = $node->getAttribute('name');

        ## verify this user exists; delete defunct child when needed
        unless (defined($Cache{_pwentries}->{$user})) {
            $node->parentNode->removeChild($node);
            delete $Cache{_nodes}->{user_nodes}->{$user};
            VSAP::Server::Modules::vsap::logger::log_message("config: removing user node for defunct user '$user'");
            $self->{is_dirty} = 1;

            ($Cache{_nodes}->{domains_node}) ||= $self->{dom}->findnodes('/config/domains');
            for my $domain ( $self->{dom}->findnodes("/config/domains/domain[admin='$user']") ) {
                $self->_parse_apache(domain => $domain->findvalue('name'));
            }
            next;
        }

        ## skip users w/ system uids
        my $uid = $Cache{_pwentries}->{$user}->{'uid'};
        my $lowUID = ( $IS_LINUX ) ? 500 : 1000;
        next if ($uid < $lowUID);
        next if ($uid > 65530);

        next if ($args{admin} && ($user eq $args{admin}));  ## exclude admin from list of end users
        $users{$user} = $node->findvalue("domain[1]");
    }

    return \%users;
}

##############################################################################

sub service
{
    return feature(shift, 'services', @_);
}

##############################################################################

sub services
{
    my $self = shift;
    my %serv = @_;
    my $username  = $self->{username};
    return unless $self->{dom};

    my $groups    = _get_groups($username);
    my %n_groups  = %$groups;

    ## find the services node
    ($Cache{_nodes}->{serv_node}) ||= $Cache{_nodes}->{user_node}->findnodes("services")
      or do {
          carp "Couldn't find the service node\n";
          return {};
      };

    ## FIXME: we should do a ||= on these nodes for the %Cache hash
    my %service_nodes = ();
    for my $node ( $Cache{_nodes}->{serv_node}->childNodes() ) {
        my $name = $node->localname;
        $service_nodes{$name} = $node;
        $Cache{_services}->{$name} = 1;
    }

    ## have some settings to change, praps
    if (keys %serv) {
        for my $service ( keys %serv ) {
            next unless $SERVICES{$service} || $EXT_SERVICES{$service};    ## skip bogus services
            next if   $serv{$service} &&   $Cache{_services}->{$service};
            next if ! $serv{$service} && ! $Cache{_services}->{$service};

            ## enable this service
            if ($serv{$service}) {
                if ($PLATFORM_GRPS{$service}) {
                    @n_groups{@{$PLATFORM_GRPS{$service}}} = (1) x @{$PLATFORM_GRPS{$service}};
                }
                $Cache{_nodes}->{serv_node}->appendChild( $self->{dom}->createElement($service) );
                $Cache{_services}->{$service} = 1;
                VSAP::Server::Modules::vsap::logger::log_message("config: enable capability '$service' for $username");

                debug("Just created a $service service node") if $TRACE;

                ## call nv_enable routine
                if ($EXT_SERVICES{$service}) {
                    NO_STRICT: {
                          (my $status_function = $service) =~ s/-/::/g;
                          $status_function = 'VSAP::Server::Modules::vsap::'
                            . $status_function
                              . '::nv_enable';

                          local $> = getpwnam($username);  ## drop privs; this also sets $> so the
                          no strict 'refs';                ## nv_* functions will behave like VSAP
                          &$status_function($username);    ## (which is always setuid to the user)
                      }
                }
            }

            ## disable this service
            else {
                unless (exists $service_nodes{$service}) {
                    carp "Could not find child $service\n";
                    next;
                }
                my $s_node = $service_nodes{$service};

                if ($PLATFORM_GRPS{$service}) {
                    delete @n_groups{@{$PLATFORM_GRPS{$service}}};
                }
                $Cache{_nodes}->{serv_node}->removeChild($s_node);
                delete $Cache{_services}->{$service};
                VSAP::Server::Modules::vsap::logger::log_message("config: disable capability '$service' for $username");

                ## call nv_enable routine
                if ($EXT_SERVICES{$service}) {
                    NO_STRICT: {
                          (my $status_function = $service) =~ s/-/::/g;
                          $status_function = 'VSAP::Server::Modules::vsap::'
                            . $status_function
                              . '::nv_disable';

                          local $> = getpwnam($username);  ## drop privs; this also sets $> so the
                          no strict 'refs';                ## nv_* functions will behave like VSAP
                          &$status_function($username);    ## (which is always setuid to the user)
                      }
                }
            }

            $self->{is_dirty} = 1;
        }

      UPDATE_GROUP: {
            if ($self->{is_dirty}) {
                ## an optimization
              CHECK_GROUP: {
                    last CHECK_GROUP unless scalar(keys %$groups) == scalar(keys %n_groups);
                    for ( my($key,$val) = each %$groups ) {
                        next unless $key;
                        last CHECK_GROUP unless exists $n_groups{$key};
                        last CHECK_GROUP if $n_groups{$key} ne $val;
                    }
                    last UPDATE_GROUP; ## arrays are equal
                }

                debug("Unsetting groups: " . join(' ', keys %n_groups)) if $TRACE;
                $Cache{_groups}->{$username} = \%n_groups;
                local $> = $) = 0;  ## regain privileges for a moment
                ## Setting groups
                if ( $IS_LINUX ) {
                        system('usermod', '-G', join(',', grep { !/^\Q$username\E$/ } keys %n_groups), $username)
                          and do {
                      carp "Could not execute 'pw': $!\n";
                  };
                }
                else {
                        system('/usr/sbin/pw', 'usermod', $username,
                       '-G', join(',', grep { !/^\Q$username\E$/ } keys %n_groups))
                          and do {
                      carp "Could not execute 'pw': $!\n";
                  };
                }

                debug("Groups now unset") if $TRACE;
            }
        }
    }

    if ($TRACE) {
        debug("Current services for $username:");
        for my $service ( $Cache{_nodes}->{serv_node}->childNodes() ) {
            debug($service->nodeName);
        }
    }

    ## populate return hash
    return($Cache{_services});
}

##############################################################################

sub siteprefs
{
    my $self = shift;
    unless ($self->{dom}) {
        return {};
    }
    return $Cache{_siteprefs};
}

##############################################################################

sub user_disabled
{
    my $self = shift;
    my $user = shift;

    my $pwentry = _get_pwentries($user);

    my $pass = $pwentry->{'passwd'};
    ## NOTE: if $pass starts with '!' then disabled (on Linux)
    ## NOTE: if $pass starts with '*LOCKED*' then disabled (on FreeBSD)
    ## NOTE: if $pass includes '*DISABLED*' then user domain disabled (by CPX)
    my $disabled = (($pass =~ /^\!|\*LOCKED\*/) || ($pass =~ /\*DISABLED\*/));

    return $disabled;
}

##############################################################################

sub user_domain
{
    my $self = shift;
    my $user = shift;

    return ( $Cache{_domains}->{$user} || $self->{server_name} );
}

##############################################################################

sub user_gecos
{
    my $self = shift;
    my $user = shift;

    my $pwentry = _get_pwentries($user);

    return ( $pwentry->{'gecos'} || (getpwnam($user))[6] );
}

##############################################################################

sub user_home
{
    my $self = shift;
    my $user = shift;

    my $pwentry = _get_pwentries($user);

    return ( $pwentry->{'home'} || (getpwnam($user))[7] );
}

##############################################################################

sub user_services
{
    my $self = shift;
    my $user = shift;

    # this returns a string like this "service|service|service|service"
   return ( $Cache{_userservices}->{$user} );
}

##############################################################################

sub user_type
{
    my $self = shift;
    my $user = shift;

    my $groups = _get_groups($user);
    return "sa" if ($groups->{wheel});
    return "da" if ($Cache{_domainadminness}->{$user});
    return "ma" if ($Cache{_mailadminness}->{$user});
    return "eu";
}

##############################################################################

sub user_uid
{
    my $self = shift;
    my $user = shift;

    # use user_uid() in lieu of getpwnam() inside of large for() loops;
    # getpwnam() is slow on VPSv3

    my $pwentry = _get_pwentries($user);

    return ( $pwentry->{'uid'} || getpwnam($user) );
}

##############################################################################

sub version_cpx
{
    my $self = shift;

    return($VERSION);
}

##############################################################################

sub _get_apache_config_modtime
{
    my $lastmodtime = 0;

    ## check main apache config file
    my $conf_path = $VSAP::Server::Modules::vsap::globals::APACHE_CONF; 
    $lastmodtime = (lstat($conf_path))[9]; 

    ## check domains in sites-available (if applicable)
    my $lastmodsite = 0;
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    if (opendir(SITESAVAIL, $sites_dir)) {
        while (defined (my $sfile = readdir(SITESAVAIL))) {
            my $spath = $sites_dir . '/' . $sfile;
            next unless (-f $spath);
            my $slm = (stat(_))[9];
            $lastmodsite = $slm if ($slm > $lastmodsite);
        }
        closedir(SITESAVAIL);
    }
    $lastmodtime = $lastmodsite if ($lastmodsite > $lastmodtime);

    return($lastmodtime);
}

##############################################################################

sub _get_groups
{
    my $user = shift;

    ## check for invalid cache
    if (! $Cache{_groups} ||
        ! $Cache{_times}->{groups} ||
        ($Cache{_times}->{groups} < (lstat('/etc/group'))[9])) {

        ## cache is stale
        undef $Cache{_groups} if ( $Cache{_groups} );
        $Cache{_times}->{groups} = (lstat('/etc/group'))[9];
    }

    return $Cache{_groups}->{$user} if exists $Cache{_groups}->{$user};
    undef $Cache{_groups};

    ## NOTE:
    ## NOTE: While ugly and longer, doing this loop by hand is about
    ## NOTE: 3x faster (runs in 1/3 the time) of the corresponding
    ## NOTE: setgrent/getgrent/endgrent loop:
    ## NOTE:
    ## NOTE:      setgrent();
    ## NOTE:      while( my($group,$members) = (getgrent)[0,3] ) {
    ## NOTE:          $Cache{_groups}->{$_}->{$group} = 1 for split(' ', $members);
    ## NOTE:      }
    ## NOTE:      endgrent();
    ## NOTE:
    ## NOTE: It's called often enough to make a significant speedup
    ## NOTE: (I've profiled and benchmarked this area carefully).
    ## NOTE: -scottw
    ## NOTE:

    my $tries = 0;
    while (!open(GROUPFH, '/etc/group')) {
        sleep(1);
        $tries++;
        die "Can't open /etc/group: $!\n" if ($tries == 5);
    }
    local $_;
    while( <GROUPFH> ) {
        next if /:$/o;
        next if /^#/;
        chomp;
        my($group, $members) = (split(':'))[0,3];
        next unless $members;
        $Cache{_groups}->{$_}->{$group} = 1 for split(',', $members);
    }
    close GROUPFH;

    return $Cache{_groups}->{$user} || {};
}

##############################################################################

## get hostname

sub _get_hostname
{
    require VSAP::Server::Modules::vsap::sys::hostname;
    my $hostname = VSAP::Server::Modules::vsap::sys::hostname::get_hostname();

    return lc $hostname;
}

##############################################################################

sub _get_pwentries_freebsd
{
    my $user = shift;

    ## check for invalid cache
    if (! $Cache{_pwentries} ||
        ! $Cache{_times}->{pwentries} ||
        ($Cache{_times}->{pwentries} < (lstat('/etc/passwd'))[9])) {

        ## cache is stale
        undef $Cache{_pwentries} if ( $Cache{_pwentries} );
        $Cache{_times}->{pwentries} = (lstat('/etc/passwd'))[9];

      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $tries = 0;
            while (!open(PASSWDFH, '/etc/master.passwd')) {
                sleep(1);
                $tries++;
                die "Can't open /etc/master.passwd: $!\n" if ($tries == 5);
            }
            local $_;
            while( <PASSWDFH> ) {
                next if /^#/;
                chomp;
                # user:passwd:uid:gid:undef:undef:undef:gecos:home:shell
                my($user,$passwd,$uid,$gid,undef,undef,$gecos,$home,$shell) = split(':');
                $Cache{_pwentries}->{$user}->{'passwd'} = $passwd;
                $Cache{_pwentries}->{$user}->{'uid'} = $uid;
                $Cache{_pwentries}->{$user}->{'home'} = $home;
                $Cache{_pwentries}->{$user}->{'gecos'} = $gecos;
            }
            close PASSWDFH;
        }
    }

    return( $user ? $Cache{_pwentries}->{$user} || {} : {} );
}

##############################################################################

sub _get_pwentries_linux
{
    my $user = shift;

    ## check for invalid cache
    if (! $Cache{_pwentries} ||
        ! $Cache{_times}->{pwentries} ||
        ($Cache{_times}->{pwentries} < (lstat('/etc/passwd'))[9])) {

        ## cache is stale
        undef $Cache{_pwentries} if ( $Cache{_pwentries} );
        $Cache{_times}->{pwentries} = (lstat('/etc/passwd'))[9];

        # get uid and home directory from passwd file
        my $tries = 0;
        while (!open(PASSWDFH, '/etc/passwd')) {
            sleep(1);
            $tries++;
            die "Can't open /etc/passwd: $!\n" if ($tries == 5);
        }
        local $_;
        while( <PASSWDFH> ) {
            next if /^#/;
            chomp;
            # user:undef:uid:gid:gecos:home:shell
            my($user,undef,$uid,$gid,$gecos,$home,$shell) = split(':');
            $Cache{_pwentries}->{$user}->{'uid'} = $uid;
            $Cache{_pwentries}->{$user}->{'home'} = $home;
            $Cache{_pwentries}->{$user}->{'gecos'} = $gecos;
        }
        close PASSWDFH;

      REWT: {
            # get password out of shadowed password file
            local $> = $) = 0;  ## regain privileges for a moment
            my $tries = 0;
            while (!open(SHADOWFH, '/etc/shadow')) {
                sleep(1);
                $tries++;
                die "Can't open /etc/shadow: $!\n" if ($tries == 5);
            }
            local $_;
            while( <SHADOWFH> ) {
                next if /^#/;
                chomp;
                my($user,$passwd) = (split(':'))[0,1];
                $Cache{_pwentries}->{$user}->{'passwd'} = $passwd;
            }
            close SHADOWFH;
        }
    }

    return( $user ? $Cache{_pwentries}->{$user} || {} : {} );
}

##############################################################################

sub _get_pwentries
{
    my $user = shift || "";

    return ( $IS_LINUX ? _get_pwentries_linux($user) : _get_pwentries_freebsd($user) );
}

##############################################################################

sub _parse_apache
{
    my $self = shift;
    my %args = @_;

    my $find_domain = $args{'domain'} || '';
    my $last_modtime = $args{'modtime'} || '';

    # debug("_parse_apache for $find_domain");
    VSAP::Server::Modules::vsap::logger::log_message("config: parsing apache config file (changes detected)");

    ## delete existing domain (refreshing an existing domain)
    if ($find_domain) {
        # debug("calling remove_domain");
        $self->remove_domain($find_domain);
    }

    my $domain_root = $Cache{_nodes}->{domains_node};

    ## build list of config files to parse
    my @conf_files = ();
    my $conf_file = $VSAP::Server::Modules::vsap::globals::APACHE_CONF;
    push(@conf_files, $conf_file);

    ## add sites-available (if applicable)
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    if (opendir(SITESAVAIL, $sites_dir)) {
        while (defined (my $sfile = readdir(SITESAVAIL))) {
            my $spath = $sites_dir . '/' . $sfile;
            next unless (-f $spath);
            my $slm = (stat(_))[9] if ($last_modtime);
            # only parse if modified more recent than last_modtime
            push(@conf_files, $spath) if (! $last_modtime || ($slm > $last_modtime));
        }
        closedir(SITESAVAIL);
    }

    my $server_name = '';
    my $server_admin = '';

    ## parse each config file
    foreach $conf_file (@conf_files) {
        debug("Looking for $conf_file") if $TRACE;

        ## is conf_file readable?  check first (BUG19032)
        unless (-r "$conf_file") {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                chmod(0644, $conf_file);
            }
        }

        local $_;
        open(CONF, $conf_file) or next;
        my $state   = 0;
        my $user    = '';
        my $domain  = '';

        ## NOTE: VirtualHost blocks w/o User/Group directives will inherit
        ## NOTE: server context User/Group directives

        debug("Parsing $conf_file") if $TRACE;
        while (<CONF>) {
            s/\r?\n$//;  ## safer than chomp

            ## find servername in server context
            if (! $find_domain && ! $state && ! $server_name && m!^\s*ServerName\s*"?(.+)"?!io) {
                $server_name = (split(/:/, $1))[0];
                $server_name =~ s/^\s+//g;  ## eliminate any leading white space
                $server_name =~ s/\s+$//g;  ## eliminate any trailing white space
                $self->{server_name} = $server_name;
                next;
            }

            ## find username in server context
            if (! $find_domain && ! $state && ! $server_admin && ( m!^\s*User\s*"?(.+)"?!io || m!^\s*suexecusergroup\s*(.+)\s+(.+)!io )) {
                $server_admin = $1;
                $server_admin =~ s/^\s+//g;  ## eliminate any leading white space
                $server_admin =~ s/\s+$//g;  ## eliminate any trailing white space
                $self->{server_admin} = $server_admin;
                next;
            }

            ## server context
            if (! $state) {
                next unless m!^\s*<VirtualHost!io;
                $state = 1;  ## virtual host context
                debug("Found a VirtualHost block") if $TRACE;
                next;
            }

            ## end of VirtualHost block
            if ($state && m!^\s*</VirtualHost>!io) {
                ## maybe didn't find a user
                $user ||= $server_admin;
                $user =~ s/^\s+//g;  ## eliminate any leading white space
                $user =~ s/\s+$//g;  ## eliminate any trailing white space

              CREATE_NODE: {
                    if ($domain && $user) {
                        last CREATE_NODE if $find_domain and $domain ne $find_domain;
                        my ($domain_node) = $domain_root->findnodes("domain[name = '$domain']");
                        ## if domain exists in config, check to see if admin has changed
                        if ( $domain_node ) {
                            my $admin = $self->{dom}->findvalue("/config/domains/domain[name = '$domain']/admin[1]");
                            if ( $admin ne $user ) {
                                # admin has changed... demote previous admin if last domain name
                                my $domains = $self->domains( $admin );
                                my $numdomains = scalar keys %$domains;
                                if ( $numdomains == 1 ) {
                                    # last domain name for this admin (*sniff*)
                                    $self->domain_admin( admin => $admin, set => 0 );
                                }
                                # change the admin in domain node
                                my ($old_node) = $domain_node->findnodes('admin');
                                my $new_node = $self->{dom}->createElement('admin');
                                $new_node->appendTextNode($user);
                                $domain_node->replaceChild( $new_node, $old_node );
                                VSAP::Server::Modules::vsap::logger::log_message("config: changing admin for $domain from $admin to '$user'");
                                $self->{is_dirty} = 1;
                            }
                        }

                        ## now make sure this user is a DA
                        if ( my ($user_node) = $self->{dom}->findnodes("/config/users/user[\@name='$user'][1]") ) {
                            unless ($self->domain_admin( user => $user )) {
                                debug("making '$user' a domain admin") if $TRACE;
                                $self->domain_admin( admin => $user, set => 1 );
                            }
                            # debug("setting domain node ...");
                            $self->_set_domain_node($user_node, $domain_root);
                        }

                        ## skip this domain if we've already processed it
                        # debug("done finding nodes, etc.");
                        last CREATE_NODE if ( $domain_node );

                        my $d_node = $self->{dom}->createElement('domain');
                        $d_node->appendTextChild( name  => $domain );
                        $d_node->appendTextChild( admin => $user );
                        $domain_root->appendChild( $d_node );
                        VSAP::Server::Modules::vsap::logger::log_message("config: created domain node for $domain (admin => $user)");
                        $self->{is_dirty} = 1;

                        debug("Leaving VirtualHost block ($domain)") if $TRACE;

                        undef $domain;
                        undef $user;
                        last;
                    }
                }

                undef $user;
                undef $domain;
                undef $state;  ## back to server context
                next;
            }

            ## in a <VirtualHost> block... looking for domain name and domain admin

            if ( ! $domain && m!^\s*ServerName\s+"?(.+)"?!io ) {
                ## found servername
                $domain = lc((split(/:/, $1))[0]);
                $domain =~ s/^\s+//g;  ## eliminate any leading white space
                $domain =~ s/\s+$//g;  ## eliminate any trailing white space
                ## skip this domain unless it's the one we're after
                if ($find_domain) {
                    unless ($domain eq $find_domain) {
                        undef $user;
                        undef $domain;
                        undef $state;
                        next;
                    }
                }
            }
            if ( ! $user && (m!^\s*User\s*"?(.+)"?\s*!io) ) {
                ## found user
                $user = $1;
            }
            if ( ! $user && (m!^\s*suexecusergroup\s*(.+)\s+(.+)!io) ) {
                ## found user
                $user = $1;
            }
        }
        close(CONF);
    }

  SET_SERVER_DOMAIN: {
        unless ($find_domain) {
            ## get default for server_admin if not set
            $self->{server_admin} ||= $VSAP::Server::Modules::vsap::globals::APACHE_RUN_USER;
            last SET_SERVER_DOMAIN if $domain_root->findnodes('domain[@type = "server"]');
            ## set one last host: servername
            my $d_node = $self->{dom}->createElement('domain');
            my $domain = $self->primary_domain;
            my $admin = $self->{server_admin};
            $d_node->setAttribute( type => 'server' );
            $d_node->appendTextChild( name  => $self->primary_domain );
            $d_node->appendTextChild( admin => $self->{server_admin} );
            $domain_root->appendChild( $d_node );
            VSAP::Server::Modules::vsap::logger::log_message("config: created primary domain node (type => server) for hostname '$domain' (admin => $admin)");
            $self->{is_dirty} = 1;
        }
    }

    1;
}

##############################################################################

## this will determine which package(s) are available

sub _parse_packages
{
    my $self = shift;

    ## process each vinstall package
    if ( $IS_LINUX ) {
        my $config = `/sbin/chkconfig --list`;
        for my $package ( keys %PACKAGES ) {
            ## RULE: if package is 'on' for run level 3,
            ## RULE: then presume the package is available
            my $running = 0;
            my @services = split(/\|/, $PACKAGES{$package});
            foreach my $service (@services) {
              if ($config =~ /^$service.*?3:on.*?6:off$/im) {
                $running = 1;
                last;
              }
            }
            if ( $running ) {
                $Cache{_packages}->{$package} = 1;
            }
            else {
                delete $Cache{_packages}->{$package};
            }
        }
    }
    else {
        ## not Linux (FreeBSD)
        my %rc_info = ();
        if (open(RCFH, $RC_CONF)) {
            while (<RCFH>) {
                next unless /^[a-zA-Z]/;
                tr/A-Z/a-z/;
                s/[^0-9a-z_\-=]//g;
                my($name, $value) = (split('='));
                $value =~ s/^(yes|y)$/1/g;
                $value =~ s/^(no|n)$/0/g;
                $rc_info{$name} = $value;
            }
            close(RCFH);
        }
        for my $package ( keys %PACKAGES ) {
            ## RULE: if daemon is enabled, then presume package is installed
            if ( defined($rc_info{$PACKAGES{$package}}) && $rc_info{$PACKAGES{$package}} ) {
                $Cache{_packages}->{$package} = 1;
            }
            else {
                delete $Cache{_packages}->{$package};
            }
        }
    }

    1;
}

##############################################################################

## this will parse the passwd file for new users and add them to cpx.conf

sub _parse_passwd
{
    my $self = shift;

    undef $Cache{_pwentries};

    ## NOTICE: what happens if we try to do this when there is no
    ## NOTICE: password database? Would the users() sub remove all the
    ## NOTICE: users then put them back?

    ## cache these
    $Cache{_nodes}->{user_nodes} ||= { map { $_->getAttribute('name') => $_ }
                                       $Cache{_nodes}->{users_node}->childNodes() };

    debug("opening password file") if $TRACE;
    my $tries = 0;
    while (!open(PASSWDFH, '/etc/passwd')) {
        sleep(1);
        $tries++;
        die "Can't open /etc/passwd: $!\n" if ($tries == 5);
    }
    local $_;
    while( <PASSWDFH> ) {
        next if /^#/;
        chomp;
        # user:undef:uid:gid:gecos:home:shell
        my($user,undef,$uid,$gid,$fullname,$home,$shell) = split(':');

        ## skip users w/ system uids
        my $lowUID = ( $IS_LINUX ) ? 500 : 1000;
        next if ($uid < $lowUID);
        next if ($uid > 65530);

        ## skip users already in conf file
        my $user_node = $Cache{_nodes}->{user_nodes}->{$user};

        if ($user_node) {
            $self->_set_domain_node($user_node, $Cache{_nodes}->{domains_node});
            next;
        }

        ## create new node
        $user_node = $self->{dom}->createElement('user');
        $user_node->setAttribute( name => $user );
        VSAP::Server::Modules::vsap::logger::log_message("config: created user node for '$user'");

        ## set domain and domain_admin elements
        $self->_set_domain_node($user_node, $Cache{_nodes}->{domains_node});

        $Cache{_nodes}->{users_node}->appendChild($user_node);
        $Cache{_nodes}->{user_nodes}->{$user} = $user_node;
        $self->{is_dirty} = 1;
    }
    close PASSWDFH;
    debug("resetting password file. passwd parse complete") if $TRACE;
}

##############################################################################

## this will parse site prefs file

sub _parse_siteprefs
{
    my $self = shift;

    my %siteprefs = %SITEPREFS;
    if (open(SPFH, $CPX_SPF)) {
        while (<SPFH>) {
            next unless /^[a-zA-Z]/;
            tr/A-Z/a-z/;
            s/[^0-9a-z_\-=]//g;
            my($name, $value) = (split('='));
            $name =~ s/_/-/g;
            $value =~ s/^(yes|y)$/1/g;
            $value =~ s/^(no|n)$/0/g;
            next unless (defined($siteprefs{$name}));
            $siteprefs{$name} = $value;
        }
        close(SPFH);
    }

    for my $sitepref ( keys %siteprefs ) {
        ## only include preferences that have a value of 1
        if ( $siteprefs{$sitepref} ) {
            $Cache{_siteprefs}->{$sitepref} = 1;
        }
        else {
            ## skip site pref if not in conf file
            delete $Cache{_siteprefs}->{$sitepref};
        }
    }

    1;
}

##############################################################################

sub _propagate_hostname
{
    my $self = shift;
    my $newhostname = shift;
    my $oldhostname = shift;

    # change "server" attribute for old and new hostnames
    my $found = 0;
    ($Cache{_nodes}->{domains_node}) ||= $Cache{_nodes}->{conf_node}->findnodes('domains[1]');
    my @nodes = $Cache{_nodes}->{domains_node}->childNodes();
    for my $domain_node ( @nodes ) {
        my $type = $domain_node->getAttribute('type');
        my $domain = $domain_node->findvalue("./name");
        if ($type && ($type eq "server") && ($domain eq $oldhostname)) {
            $domain_node->removeAttribute('type');
            VSAP::Server::Modules::vsap::logger::log_message("config: removing domain node server type attribute for new hostname '$domain'");
            # remove the old host name if it no longer resolves to this server
            my @ips = VSAP::Server::Modules::vsap::domain::list_server_ips();
            my $inaddr = inet_aton($oldhostname);
            my $straddr = ($inaddr) ? inet_ntoa($inaddr) : "_INVALID";
            my $match = 0;
            foreach my $ip (@ips) {
                $match = 1 if ($ip eq $straddr);
                last if ($match);
            }
            unless ($match) {
                # old hostname doesn't resolve to this account... remove
                $Cache{_nodes}->{domains_node}->removeChild($domain_node);
                VSAP::Server::Modules::vsap::logger::log_message("config: removing domain node for '$domain'");
                # do anything else?  like remove e-mail address mappings etc?
            }
        }
        elsif ($domain eq $newhostname) {
            $found = 1;
            $domain_node->setAttribute( type => 'server' );
            VSAP::Server::Modules::vsap::logger::log_message("config: setting domain node server type attribute for new hostname '$domain'");
        }
    }

    if ( !$found ) {
        # new hostname is also a new domain name
        $self->_parse_apache();
    }
    $self->{is_dirty} = 1;
}

##############################################################################

sub _set_domain_admin
{
    my $self   = shift;
    my $user   = shift;
    my $status = shift;

    my $user_node;
    unless ( ($user_node) = $self->{dom}->findnodes("/config/users/user[\@name='$user'][1]") ) {
        carp "No user entry for '$user'\n";
        return;
    }

    unless (defined($status)) {
        return $self->{dom}->find("/config/users/user[\@name='$user']/domain_admin");
    }

    ## make me a domain admin
    if ($status) {
        unless ($user_node->find('domain_admin')) {
            $user_node->appendChild( $self->{dom}->createElement('domain_admin') );
            VSAP::Server::Modules::vsap::logger::log_message("config: add domain admin-ness to $user");
            $self->{is_dirty} = 1;
        }
    }

    ## remove my domain admin-ness
    else {
        if ( my($da_node) = $user_node->findnodes('domain_admin') ) {
            $user_node->removeChild($da_node);
            VSAP::Server::Modules::vsap::logger::log_message("config: remove domain admin-ness from $user");
            $self->{is_dirty} = 1;
        }
    }

    return $status;
}

##############################################################################

sub _set_domain_node
{
    my $self = shift;
    my $user_node    = shift || $Cache{_nodes}->{user_node};
    my $domains_node = shift || $Cache{_nodes}->{domains_node};

    my $user = $user_node->getAttribute('name');
    ## server admin; we choose the primary hostname Apache responds to
    my $groups = _get_groups($user);
    if ($groups->{wheel}) {
        my($domain) = $self->primary_domain;
        unless ($user_node->findnodes("domain[1]")) {
            $user_node->appendTextChild( domain => $domain );
            VSAP::Server::Modules::vsap::logger::log_message("config: setting domain for $user to '$domain'");
            $self->{is_dirty} = 1;
        }
        unless ($user_node->findnodes("domain_admin[1]")) {
            $user_node->appendChild( $self->{dom}->createElement('domain_admin') );
            $self->{is_dirty} = 1;
        }
    }

    ## domain admin; we set it to the primary domain
    elsif ( my ($d_node) = $domains_node->findnodes("domain[admin='$user'][1]") ) {
        my($domain) = $d_node->findvalue("name");
        unless ($user_node->findnodes("domain")) {
            $user_node->appendTextChild( domain => $domain );
            VSAP::Server::Modules::vsap::logger::log_message("config: setting domain for $user to '$domain'");
            $self->{is_dirty} = 1;
        }
        unless ($user_node->findnodes("domain_admin")) {
            $user_node->appendChild( $self->{dom}->createElement('domain_admin') );
            VSAP::Server::Modules::vsap::logger::log_message("config: setting $user as domain_admin for '$domain'");
            $self->{is_dirty} = 1;
        }
    }

    ## end user; we will be safe with server_name here.
    ## The server admin will sort things out later.
    else {
        my($domain) = $self->primary_domain;
        unless ($user_node->findnodes("domain[1]")) {
            $user_node->appendTextChild( domain => $domain );
            VSAP::Server::Modules::vsap::logger::log_message("config: setting domain for $user to '$domain'");
            $self->{is_dirty} = 1;
        }
    }

    1;
}

##############################################################################

sub _set_mail_admin
{
    my $self   = shift;
    my $user   = shift;
    my $status = shift;

    my $user_node;
    unless ( ($user_node) = $self->{dom}->findnodes("/config/users/user[\@name='$user'][1]") ) {
        carp "No user entry for '$user'\n";
        return;
    }

    unless (defined($status)) {
        return $self->{dom}->find("/config/users/user[\@name='$user']/mail_admin");
    }

    ## make me a mail admin
    if ($status) {
        unless ($user_node->find('mail_admin')) {
            $user_node->appendChild( $self->{dom}->createElement('mail_admin') );
            VSAP::Server::Modules::vsap::logger::log_message("config: add mail admin-ness to $user");
            $self->{is_dirty} = 1;
        }
    }

    ## remove my mail admin-ness
    else {
        if ( my($ma_node) = $user_node->findnodes('mail_admin') ) {
            $user_node->removeChild($ma_node);
            VSAP::Server::Modules::vsap::logger::log_message("config: remove mail admin-ness to $user");
            $self->{is_dirty} = 1;
        }
    }

    return $status;
}

##############################################################################

sub AUTOLOAD
{
    my $self = shift or return;

    my $sub = $AUTOLOAD;
    $sub =~ s/^.*:://;
    return if $sub eq 'DESTROY';

    my $sub_ref;

    ## getters/setters for top-level user node data
    if ($sub =~ /^(?:domain|comments|eu_prefix)$/) {
        $sub_ref = sub {
            my $self = shift;
            my $parm = $self->{username};
            return unless $self->{dom};
            my $set_data = shift;  ## setter

            my ($new_node) = $self->{dom}->findnodes("/config/users/user[\@name='$parm'][1]")
              or do {
                  carp "Could not find node\n";
                  return;
              };

          SET_DATA: {
                last SET_DATA unless $set_data;

                if ( my ($node) = $new_node->findnodes("$sub") ) {
                    if ($set_data eq "__REMOVE") {
                        $new_node->removeChild( $node );
                        VSAP::Server::Modules::vsap::logger::log_message("config: removing '$sub' data for $parm");
                    }
                    else {
                        my $new = $self->{dom}->createElement($sub);
                        $new->appendTextNode($set_data);
                        $new_node->replaceChild( $new, $node );
                        VSAP::Server::Modules::vsap::logger::log_message("config: setting '$sub' for $parm to $set_data");
                    }
                }
                else {
                    if ($set_data ne "__REMOVE") {
                        $new_node->appendTextChild( $sub => $set_data );
                        VSAP::Server::Modules::vsap::logger::log_message("config: setting '$sub' for $parm to $set_data");
                    }
                }
                $self->{is_dirty} = 1;
            }

            return $new_node->findvalue("$sub") || '';
        };
    }

    ## getters/setters for domain-level node data
    elsif ($sub =~ /^(?:disk_limit|alias_limit|user_limit)$/) {
        $sub_ref = sub {
            my $self = shift;
            my $parm = shift;
            return unless $self->{dom} && $parm;
            my $set_data = shift;  ## setter

            my ($new_node) = $self->{dom}->findnodes("/config/domains/domain[name='$parm']")
              or do {
                  carp "Could not find node\n";
                  return;
              };

          SET_DATA: {
                last SET_DATA unless defined $set_data && $set_data =~ /^(?:\d+|unlimited)$/;

                if ( my ($node) = $new_node->findnodes("$sub") ) {
                    my $new = $self->{dom}->createElement($sub);
                    $new->appendTextNode($set_data);
                    $new_node->replaceChild( $new, $node );
                }
                else {
                    $new_node->appendTextChild( $sub => $set_data );
                }
                VSAP::Server::Modules::vsap::logger::log_message("config: setting '$sub' for $parm to $set_data");
                $self->{is_dirty} = 1;
            }

            return $new_node->findvalue("$sub") || "unlimited";
        };
    }

    else {
        croak "Undefined subroutine '$sub'";
    }

  ADD_TO_SYMBOL_TABLE: {
        no strict 'refs';
        *$AUTOLOAD = $sub_ref;
    }
    unshift @_, $self;  ## put me back on call stack
    goto &$AUTOLOAD;    ## jump to me
}

##############################################################################

sub DESTROY
{
    $_[0]->commit;
    undef $_[0]->{dom};
    debug("releasing lock") if $TRACE;
    close $SEMAPHORE;  ## implicit (and atomic) unlock
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::config - CPX configuration data

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::config;

=head1 DESCRIPTION

vsap::config manages the CPX configuration file
(F</usr/local/etc/cpx.conf>). The file is an XML dom and is parsed by
this module.

NOTE: This object should not be long-lived because of possible
race-conditions with other processes. Particularly, if two domain
admins are making changes, a significant risk exists that one will
overwrite changes made by the other.

=head2 new(%args)

Creates a new config object. Possible parameters are B<username> and
B<uid>. B<uid> has precedence over B<username>.

  my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );

Arguments:

=over 4

=item auto_refresh

Enabled by default. When set to a false value, disables invoking the
B<refresh> method.

=item auto_compat

Enabled by default. When set to a false value, disables invoking the
B<compat> method.

=back

=head2 init(%args)

Initializes an object; arguments are the same as B<new>.

  $old_co->init( username => 'joe' );

=head2 refresh

Polls system services and updates the object accordingly. This is
implicitly called during B<init>. Normally, you would not call
B<refresh> unless you suspected the platform services have changed
underneath the object (i.e., after the object was initialized).

  $co->refresh;

Affected elements in the config file include:

=over 4

=item disabled

checks whether the user is disabled or not.

=item services

see capabilities

=item capabilities

checks the status of each service in %SERVICES and %EXT_SERVICES and
updates the corresponding elements.

=back

=head2 commit

Writes the contents of the object to an XML file.

=head2 capability('service')

Returns whether the specified capability is available for this user.

  print "Have ftp\n" if $co->capability('ftp');

=head2 capabilities( [%args] )

Returns a hash reference of capabilities for this user. If %args is
set, services will first be set accordingly.

  my %capa = %{ $co->capabilities( ftp => 0, mail => 1, webmail => 1 ) };

Note that if the platform service (e.g., ftp, mail, shell) has not
been disabled prior to the (set) capabilities call, the capability
will be overridden and will not be disabled; you can't remove
capability for a service that is already in place. This functionality
may not be desireable.

=head2 service

Analogous to B<capability>.

=head2 services( [%args] )

Analogous to B<capabilities>. If %args is set, services will be
enabled or disabled for this user.

  ## turn off ftp
  $co->services( ftp => 0 );

=head2 packages()

Returns a hash reference of optional vinstall platform packages
that are currently installed for this cpx.

=head2 siteprefs()

Returns a hash reference of cpx site preferences.

=head2 users( [domain => "foo.com"] | [admin => 'joeuser'] )

Returns a hashref of user => domain pairs.

When given a domain, all end users for that domain are returned. When
given an admin, all end users provisioned under that admin are
returned.

=head2 domain

Sets/gets the domain name for the uid of this object.

=head1 CAPABILITIES vs SERVICES vs EU_CAPABILITIES

Each user has two property sets: capabilities and services.

The current capabilities of a user are shell, email, ftp, webmail, and
fileman. Services is a proper subset of capabilities. Services
indicates what the settings of the user's capabilities are. For
example, if a user has the following capabilities:

  shell   => 0
  mail    => 1
  sftp    => 0
  ftp     => 1
  webmail => 0

The services will look like:

  mail    => 1
  ftp     => 1

The capabilities settings determine, in the UI, which checkboxes to
display, which features to surface for a user generally, while the
services setting determines the status of those checkboxes or other
features (though it could also affect display of webmail, for
example).

If a user has shell capability, a shell line will appear when they
view their properties under "My Profile" (for example). If the shell
is set to /sbin/nologin, the shell setting will read "no shell". If
the user has no shell capability, no shell line will appear at all
when they view their properties. The idea was that if DAs or SAs don't
want their end users to know that a feature exists or is available,
they just remove the capability and no UI element will surface at all
for that.

Eu_capabilities refers to the kinds of capabilities a domain admin may
give to his end users. The E<lt>eu_capabilitiesE<gt> node will only
be found under a domain admin's E<lt>userE<gt> node.

=head2 compat

Updates a config file to the latest version. Automatically called in
the constructor.

=head2 Philosophy

We want to have config.pm be a reliable way to receive the status of
a particular service, with the assumption that CPX will be the only
supported method of changing the status of a service. We'll do our
best to allow platform changes independent of CPX, but the sheer
number of possibilities make it impossible for CPX to guarantee
sanity.

Each service that has its own module (e.g., mail:spamassassin,
mail:clamav, etc.) should have a small set of procedures named:

  nv_status()
  nv_enable()
  nv_disable()

These methods should be exported by the VSAP module for config.pm
(this file) to import. This will allow us a programmatic way to
enable, disable, and query the status of each of these services.
Platform sanity checks should go in the individual service modules.

New services should be put in the %EXT_SERVICES hash at the top of
config.pm, indicating whether the service implements and exports the
nv_*() procedures.

The config 'capabilities' node is still authoritative in all
cases. The capabilities node for a particular service may be initially
determined by platform tests (i.e., if SA were already installed, the
capabilities node for spamassassin would be set).

=head1 NOTES

=over 4

=item FIXME

We don't have any locking mechanism in this module (but we should!).
Exercise as much care as you can for now to avoid corruption. This
must be fixed before production.

=item *

What to do when a new domain is added not via cpx? Tell the user to
delete the entire E<lt>domains/E<gt> node. It will rebuild on its own.

=item *

Authorization is not handled in this module; it should be handled at
the application layer (i.e., in the VSAP) to make sure that average
users don't go horking the configuration file.

=item *

Once this module has been in wide-use, version bumps (incompatible API
changes) will require some kind of transformation on the configuration
file.

=back

=head1 SEE ALSO

vsap(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
