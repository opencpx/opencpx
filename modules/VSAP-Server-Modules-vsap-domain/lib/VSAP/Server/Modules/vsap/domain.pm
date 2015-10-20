package VSAP::Server::Modules::vsap::domain;

use 5.008004;
use strict;
use warnings;

use Config::Crontab;
use Config::Savelogs;
use Email::Valid;
use Fcntl 'LOCK_EX';
use POSIX;
use Quota;

use VSAP::Server::Modules::vsap::apache;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;
use VSAP::Server::Modules::vsap::user::prefs;

##############################################################################

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( get_docroot_all list_server_ips );

##############################################################################

our $VERSION = '0.12';

our %_ERR    = ( DOMAIN_ADMIN_MISSING          => 100,
                 DOMAIN_PERMISSION             => 101,
                 DOMAIN_ADD_MISSING_ADMIN      => 102,
                 DOMAIN_ADD_MISSING_DOMAIN     => 103,
                 DOMAIN_ADD_MISSING_CONTACT    => 104,
                 DOMAIN_ADD_EXISTS             => 105,
                 DOMAIN_ADMIN_BAD              => 106,
                 DOMAIN_LOG_ROTATE_BAD         => 107,
                 DOMAIN_CONFIG_FILE            => 108,
                 DOMAIN_HAS_USERS              => 109,
                 DOMAIN_ETC_PASSWD             => 110,
                 DOMAIN_CONTACT_BAD            => 111,
                 DOMAIN_EMAIL_ADDRS_BAD        => 112,
                 DOMAIN_PRIMARY_NA             => 113,
                 DOMAIN_END_USERS_BAD          => 114,
                 VADDHOST_FAILED               => 115,
               );

our %Cache = ();

use constant IN_VHOST  => 1;
use constant IN_DIRLOC => 2;

our $APACHE_CONF = $VSAP::Server::Modules::vsap::globals::APACHE_CONF;
our $ALIASES = $VSAP::Server::Modules::vsap::globals::MAIL_ALIASES;
our $GENERICS = $VSAP::Server::Modules::vsap::globals::MAIL_GENERICS;
our $LOCALHOSTNAMES = $VSAP::Server::Modules::vsap::globals::MAIL_VIRTUAL_DOMAINS;
our $VIRTUSERTABLE = $VSAP::Server::Modules::vsap::globals::MAIL_VIRTUAL_USERS;

our $IS_LINUX = $VSAP::Server::Modules::vsap::globals::IS_LINUX;
our $SHADOW = $IS_LINUX ? '/etc/shadow' : '/etc/master.passwd';
our $CHPASS = $IS_LINUX ? 'usermod' : 'chpass';

our $SAVELOGS_CONFIG_PATH = '/usr/local/etc';

our @CERT_FILES = qw(SSLCertificateChainFile SSLCertificateFile SSLCertificateKeyFile);

our %APACHE_CERT_FILES = (
        SSLCertificateFile      => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_FILE,
        SSLCertificateChainFile => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_CHAIN,
        SSLCertificateKeyFile   => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_KEY,
      );

##############################################################################

sub build_list
{
    my $type   = shift;
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift;
    my $admin  = shift;
    my $domain = shift;
    my $properties = shift;
    my $diskspace  = shift;
    my $page   = shift;

    if ($admin && ! getpwnam($admin)) {
        $vsap->error($_ERR{DOMAIN_ADMIN_MISSING} => "Domain admin missing");
        return;
    }

    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
    my $domains = {};

  AUTHZ: {
        ## we're a server admin
        if ($vsap->{server_admin}) {
            $domains = ( $admin
                         ? $co->domains($admin)    ## ...asking for all domains of $admin
                         : ( $domain
                             ? $co->domains(domain => $domain)  ## asking for a particular domain
                             : $co->domains ) );                ## ...asking for all domains

            last AUTHZ;
        }

        ## we're a domain admin asking about ourselves
        if ($admin && $co->domain_admin && ($vsap->{username} eq $admin)) {
            $domains = $co->domains($admin);
            last AUTHZ;
        }

        ## we're a mail admin asking about ourselves
        if ($admin && $co->mail_admin && ($vsap->{username} eq $admin)) {
            my $user_domain = $co->user_domain($vsap->{username});
            $domains = $co->domains(domain => $user_domain);
            $admin = $domains->{$user_domain};
            last AUTHZ;
        }

        ## we're a domain admin asking for one of our domains
        if ($domain && $co->domain_admin(domain => $domain)) {
            $domains = $co->domains(domain => $domain);
            last AUTHZ;
        }

        ## we're a mail admin asking about our domain
        if ($domain && $co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            if ($user_domain eq $domain) {
                $domains = $co->domains(domain => $user_domain);
                $admin = $domains->{$user_domain};
                last AUTHZ;
            }
        }

        ## we are domain admin of this domain: list domains of this admin
        if (!$domain && $co->domain_admin) {
            $domains = $co->domains($vsap->{username});
            last AUTHZ;
        }

        ## we are mail admin : list domain of this admin
        if (!$domain && $co->mail_admin) {
            my $user_domain = $co->user_domain($vsap->{username});
            $domains = $co->domains(domain => $user_domain);
            $admin = $domains->{$user_domain};
            last AUTHZ;
        }

        $vsap->error( $_ERR{USER_PERMISSION} => "Not authorized" );
        return;
    }

    $admin ||= $vsap->{username};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => $type);
    $root->appendTextChild( admin   => $admin );

    $co->init( username => $admin );

    ## read virtusertable and aliastable before our loop
    my $vut;
    my $alt;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $vut = VSAP::Server::Modules::vsap::mail::all_virtusertable();
        $alt = VSAP::Server::Modules::vsap::mail::all_aliastable();
    }

    my %vm_usages    = ();
    my %admins_found = ();
    my %catchalls    = ();

    for my $lhs ( keys %$vut ) {
        ## skip system addrs, catchalls, and the admin's default email addr
        next     if $lhs =~ /^(?:postmaster|root|www|apache)\@/;
        next unless $lhs =~ /\@(.+)$/;
        my $vdomain = $1;
        if ($lhs =~ /^\@/) {
            $catchalls{$vdomain} = $alt->{$vut->{$lhs}} || $vut->{$lhs};
            next;
        }
        $vm_usages{$vdomain}++;
    }

    ## do sorting/paging stuff if necessary, e.g. (page != -1)
    my @sorted_domains = ();
    my $first_domain = 1;
    my $last_domain = -1;
    my %_dinfo = ();
    if ($page > 0) {
        # these view settings are saved as preferences to preserve state
        my %_dsortprefs = ( domains_sortby  => 'admin',      ## name | admin | status
                            domains_order   => 'ascending',  ## descending | ascending
                            domains_sortby2 => 'name',       ## name | admin | status
                            domains_order2  => 'ascending',  ## descending | ascending
                          );

        for my $pref ( keys %_dsortprefs ) {
            (my $s_pref = $pref) =~ s/domains_//;
            $_dsortprefs{$pref} = ( $xmlobj->child($s_pref) && $xmlobj->child($s_pref)->value
                                   ? $xmlobj->child($s_pref)->value
                                   : VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, $pref) );
        }

        my $domains_per_page = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'domains_per_page') || 25;

        ## this 'set_values' call must be after the get_value call above
        VSAP::Server::Modules::vsap::user::prefs::set_values( $vsap, $dom, %_dsortprefs );

        ## loop through users and load up pertinent info for sorting:
        ## (name, admin, status)
        for my $domain ( keys %$domains ) {
            $_dinfo{$domain}->{'name'} = $domain;
            $_dinfo{$domain}->{'admin'} = $domains->{$domain};
            my %_dvhosts = VSAP::Server::Modules::vsap::domain::get_vhost($domain);
            $_dinfo{$domain}->{'status'} = ( $_dvhosts{nossl} =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio
                                             ? "disabled" : "enabled" );
            if ($diskspace) {
                my $users = $co->users(domain => $domain);
                my ($usage, $limit, $units) = VSAP::Server::Modules::vsap::domain::get_diskspace_usage($vsap, $co, $dom, $domain, $users);
                $_dinfo{$domain}->{'usage'} = $usage;
                $_dinfo{$domain}->{'limit'} = $limit;
                $_dinfo{$domain}->{'units'} = $units;
            }
        }

        ## build sorted domain list
        @sorted_domains = sort {
                if ($_dsortprefs{'domains_sortby'} eq "usage") {
                    # primary sort criteria requires numeric comparison
                    if ($_dinfo{$a}->{$_dsortprefs{'domains_sortby'}} == $_dinfo{$b}->{$_dsortprefs{'domains_sortby'}} ) {
                        # primary sort values identical... fail over to secondary sort criteria
                        if ($_dsortprefs{'domains_sortby2'} eq "usage") {
                            # secondary sort criteria requires numeric comparison
                            return ( ($_dsortprefs{'domains_order2'} eq "ascending") ?
                                     ($_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}} <=> $_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}}) :
                                     ($_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}} <=> $_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}}) );
                        }
                        # secondary sort criteria requires string comparison
                        return ( ($_dsortprefs{'domains_order2'} eq "ascending") ?
                                 ($_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}} cmp $_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}}) :
                                 ($_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}} cmp $_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}}) );
                    }
                    return ( ($_dsortprefs{'domains_order'} eq "ascending") ?
                             ($_dinfo{$a}->{$_dsortprefs{'domains_sortby'}} <=> $_dinfo{$b}->{$_dsortprefs{'domains_sortby'}}) :
                             ($_dinfo{$b}->{$_dsortprefs{'domains_sortby'}} <=> $_dinfo{$a}->{$_dsortprefs{'domains_sortby'}}) );
                }
                else {
                    # primary sort criteria requires string comparison
                    if ($_dinfo{$a}->{$_dsortprefs{'domains_sortby'}} eq $_dinfo{$b}->{$_dsortprefs{'domains_sortby'}} ) {
                        # primary sort values identical... fail over to secondary sort criteria
                        if ($_dsortprefs{'domains_sortby2'} eq "usage") {
                            # secondary sort criteria requires numeric comparison
                            return ( ($_dsortprefs{'domains_order2'} eq "ascending") ?
                                     ($_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}} <=> $_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}}) :
                                     ($_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}} <=> $_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}}) );
                        }
                        # secondary sort criteria requires string comparison
                        return ( ($_dsortprefs{'domains_order2'} eq "ascending") ?
                                 ($_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}} cmp $_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}}) :
                                 ($_dinfo{$b}->{$_dsortprefs{'domains_sortby2'}} cmp $_dinfo{$a}->{$_dsortprefs{'domains_sortby2'}}) );
                    }
                    return ( ($_dsortprefs{'domains_order'} eq "ascending") ?
                             ($_dinfo{$a}->{$_dsortprefs{'domains_sortby'}} cmp $_dinfo{$b}->{$_dsortprefs{'domains_sortby'}}) :
                             ($_dinfo{$b}->{$_dsortprefs{'domains_sortby'}} cmp $_dinfo{$a}->{$_dsortprefs{'domains_sortby'}}) );
                }
            } (keys(%_dinfo));

        my $num_domains = $#sorted_domains + 1;
        my $total_pages = ( $domains_per_page > 0 && $num_domains > 0
                            ? ( $num_domains % $domains_per_page
                                ? int($num_domains / $domains_per_page) + 1
                                : int($num_domains / $domains_per_page) )
                            : 1);

        if ($page > $total_pages) { $page = 1; }
        my $prev_page = ($page == 1) ? '' : $page - 1;
        my $next_page = ($page == $total_pages) ? '' : $page + 1;
        $first_domain = 1 + ($domains_per_page * ($page - 1));
        if ($num_domains < 1) { $first_domain = 0; }
        $last_domain = $first_domain + $domains_per_page - 1;
        if ($last_domain > $num_domains) { $last_domain = $num_domains; }
        if ($last_domain < 1) { $last_domain = 0; }

        $root->appendTextChild( num_domains   => $num_domains );
        $root->appendTextChild( page          => $page );
        $root->appendTextChild( total_pages   => $total_pages );
        $root->appendTextChild( prev_page     => $prev_page );
        $root->appendTextChild( next_page     => $next_page );
        $root->appendTextChild( first_domain  => $first_domain );
        $root->appendTextChild( last_domain   => $last_domain );
        $root->appendTextChild( sortby        => $_dsortprefs{'domains_sortby'} );
        $root->appendTextChild( order         => $_dsortprefs{'domains_order'} );
        $root->appendTextChild( sortby2       => $_dsortprefs{'domains_sortby2'} );
        $root->appendTextChild( order2        => $_dsortprefs{'domains_order2'} );
    }
    else {
        @sorted_domains = (keys %$domains);
        $last_domain = $#sorted_domains + 1;
    }

    if ($#sorted_domains >= 0) {
        for my $domain ( @sorted_domains[($first_domain-1 .. $last_domain-1)] ) {
            next unless $domain =~ /^[\w\.\-]+$/;  ## skip unsafe or bogus domains

            my $users = $co->users(domain => $domain);

            my $domain_node = $dom->createElement('domain');
            $domain_node->setAttribute( type => 'server' ) if $domain eq $co->primary_domain;
            $domain_node->appendTextChild( name  => $domain );
            $domain_node->appendTextChild( admin => $domains->{$domain} );

            ## add users node
            my $users_node = $dom->createElement('users');
            $users_node->appendTextChild( usage => scalar grep { ! /^(?:$domains->{$domain})$/ } keys %$users );
            $users_node->appendTextChild( limit => ($domain eq $co->primary_domain
                                                    ? 'unlimited'
                                                    : $co->user_limit($domain)) );
            $domain_node->appendChild( $users_node );

            ## add aliases node
            my $aliases_node = $dom->createElement('mail_aliases');
            $aliases_node->appendTextChild( usage => $vm_usages{$domain} || 0 );
            $aliases_node->appendTextChild( limit => ($domain eq $co->primary_domain
                                                      ? 'unlimited'
                                                      : $co->alias_limit($domain)) );
            $domain_node->appendChild($aliases_node);

            ## add diskspace node
            if ($diskspace) {
                my ($usage, $limit, $units);
                if ($page > 0) {
                    # cached from above
                    $usage = $_dinfo{$domain}->{'usage'};
                    $limit = $_dinfo{$domain}->{'limit'};
                    $units = $_dinfo{$domain}->{'units'};
                }
                else {
                    my ($usage, $limit, $units) = VSAP::Server::Modules::vsap::domain::get_diskspace_usage($vsap, $co, $dom, $domain, $users);
                }
                my $ds_node = $dom->createElement('diskspace');
                $ds_node->appendTextChild( usage => $usage );
                $ds_node->appendTextChild( limit => $limit );
                $ds_node->appendTextChild( units => $units );
                $domain_node->appendChild($ds_node);
            }

            my %vhosts = VSAP::Server::Modules::vsap::domain::get_vhost($domain);

            ## determine module status (enabled/disabled)
            $domain_node->appendTextChild( disabled =>
                                           ( $vhosts{nossl} =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio
                                             ? 1 : 0 ) );

            ## special properties for individual domain listing
            if ($properties) {

                ## has ip address
                my $ip = VSAP::Server::Modules::vsap::domain::get_ip($domain);
                if ($ip) {
                    $domain_node->appendTextChild(ip => $ip);
                }

                ##
                ## has www alias
                ##
                $domain_node->appendTextChild(www_alias => ($vhosts{nossl} =~ qr(^\s*ServerAlias.*\bwww\.\Q$domain\E\b)mi ? 1 : 0 ));

                ##
                ## other domain aliases
                ##
                my %other_aliases = ();
                while( $vhosts{nossl} =~ /^\s*ServerAlias\s+(.+)$/mig ) {
                    my @other_aliases = split( ' ', $1 );
                    @other_aliases{@other_aliases} = (1) x @other_aliases;
                }
                delete $other_aliases{"www.$domain"};

                sub domain_sort {
                    my @d1 = reverse split(/\./, $a);
                    my @d2 = reverse split(/\./, $b);

                    my $size = ( $#d1 > $#d2
                                 ? ($#d2+1)
                                 : ( $#d1 == $#d2
                                     ? $#d1
                                     : ($#d1+1) ) );

                    $d1[$size] ||= ''; $d2[$size] ||= '';
                    for my $i ( 0 .. $size ) {
                        next if $d1[$i] eq $d2[$i];
                        return $d1[$i] cmp $d2[$i];
                    }

                    return 0;
                }

                if (scalar keys %other_aliases) {
                    $domain_node->appendTextChild( other_aliases => join(', ', sort domain_sort keys %other_aliases) );
                    my $alias_node = $dom->createElement('other_alias_list');
                    for my $alias ( keys %other_aliases ) {
                        next if ($alias =~ /^www\./);
                        $alias_node->appendTextChild( alias => $alias );
                    }
                    $domain_node->appendChild($alias_node);
                }

                ##
                ## document root
                ##
                my $doc_root;
                $doc_root = VSAP::Server::Modules::vsap::domain::get_docroot($domain) || 
                            VSAP::Server::Modules::vsap::domain::get_server_docroot();
                $domain_node->appendTextChild( doc_root => $doc_root);

                ##
                ## logging
                ##
                my $log;
                if ( $vhosts{nossl} =~ qr(^\s*(?:Transfer|Custom)Log\s+(.+))mio ) {
                    $log = $1;
                    if ( $log =~ qr(/dev/null)o ) {
                        $domain_node->appendTextChild( www_logs => 'none' );
                    }

                    else {
                        ## log relative to server root
                        if ( $log =~ m!^[^/]! ) {
                            $domain_node->appendTextChild( www_logs => 'relative');
                        }
                        else {
                            $log =~ s!^(/.+)/[^/]+!$1!;
                            $domain_node->appendTextChild( www_logs => $log );
                        }
                    }
                }

                ## using server logs
                else {
                    $domain_node->appendTextChild( www_logs => 'server');
                }

                ##
                ## error logging
                ##
                if ( $vhosts{nossl} =~ qr(^\s*ErrorLog\s+(.+))mio ) {
                    $log = $1;
                    if ( $log =~ qr(/dev/null)o ) {
                        $domain_node->appendTextChild( www_elogs => 'none' );
                    }

                    else {
                        ## log relative to server root
                        if ( $log =~ m!^[^/]! ) {
                            $domain_node->appendTextChild( www_elogs => 'relative');
                        }
                        else {
                            $log =~ s!^(/.+)/[^/]+!$1!;
                            $domain_node->appendTextChild( www_elogs => $log );
                        }
                    }
                }

                ## using server error logs
                else {
                    $domain_node->appendTextChild( www_elogs => 'server');
                }

                ##
                ## log rotation & periodicity
                ##
                GET_DATA_FROM_SAVELOGS: {
                  local $> = $) = 0;  ## regain privileges for a moment
                  my $strFreq;
                  my $group;
                  FREQ: for my $freq qw(daily weekly monthly) {  ## find the right conf file
                    next unless -f "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                    my $conf = "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                    my $sc = new Config::Savelogs($conf)
                      or do {
                        warn "Could not open '$conf': $!\n";
                        next FREQ;
                      };
                    $strFreq = $freq;
                    $group = $sc->find_group( match => { ApacheHost => $domain } )
                      and last FREQ;
                  }

                  if ($group && ref($group) ) {
                    $domain_node->appendTextChild( log_rotation => $strFreq );
                    my $period = $group->{period};
                    my $strPeriod = ($period && $period =~ /^\d+/)?$period:'all';
                    $domain_node->appendTextChild( log_period => $strPeriod );
                  }
                  else {
                    $domain_node->appendTextChild( log_rotation => 'none' );
                  }
                } # end GET_DATA_FROM_SAVELOGS:

                ##
                ## add web services selected (cgi, ssl)
                ##
                my $services_node = $dom->createElement('services');

                ## check for cgi
                $services_node->appendTextChild(cgi => ($vhosts{nossl} =~ qr(^\s*ScriptAlias\s+/cgi\-bin/\s+.+)mio ? 1 : 0 ));
                $domain_node->appendChild($services_node);

                ## check for ssl
                $services_node->appendTextChild(ssl => ($vhosts{ssl} and ($vhosts{ssl} !~ /RewriteEngine on\s+RewriteRule\s+\^\/ - \[F,L\]/mi) ? 1 : 0));

                ##
                ## add domain contact
                ##
                if ( $vhosts{nossl} =~ m!^\s*ServerAdmin\s+(.+)$!m ) {
                    $domain_node->appendTextChild(domain_contact => $1);
                }

                ##
                ## show mail catchall info
                ##
                my $catchall = $catchalls{$domain};
                if ( ! $catchall ) {
                    $domain_node->appendTextChild(catchall => 'none');
                }

                elsif( $catchall =~ /nouser/ ) {
                    $domain_node->appendTextChild(catchall => "reject");
                }

                elsif( $catchall =~ /dev\-?null/ ) {
                    $domain_node->appendTextChild(catchall => "delete");
                }

                elsif( $catchall eq $domains->{$domain} ) {
                    $domain_node->appendTextChild(catchall => "admin");
                }

                else {
                    $domain_node->appendTextChild(catchall => $catchall);
                }
            }

            $root->appendChild($domain_node);
        }
    }

    $dom->documentElement->appendChild($root);
}

##############################################################################

## this is ugly; it was put in for profiling purposes. feel free to improve it.

sub get_diskspace_usage
{
    my $vsap = shift;
    my $co   = shift;
    my $dom  = shift;
    my $domain = shift;
    my $users  = shift;

    my $usage;
    my $disk_usage = 0;
    for my $user ( keys %$users ) {
        next if $vsap->{server_admin} && $co->domain_admin( admin => $user );
        $usage = 0;
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            ($usage) = (Quota::query(Quota::getqcarg('/home'), (getpwnam($user))[2]))[0];
        }
        $usage /= 1024;
        $disk_usage += $usage;
    }

    ## calculate disk space taken under the docroot for this domain
  USAGE: {
        my $docroot;
        if ( $domain eq $co->primary_domain ) {
            $docroot = VSAP::Server::Modules::vsap::domain::get_server_docroot();
        }
        else {
            $docroot = VSAP::Server::Modules::vsap::domain::get_docroot($domain);
        }
        last USAGE unless $docroot;
        $usage = 0;
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            last REWT unless -d $docroot;  ## is this necessary?  i moved it down from above, because it couldn't "-d" as non-root...
            $usage = `du -sk "$docroot"`;
        }
        if ( $usage ) {
            chomp $usage;
            $usage =~ s/^\s*(\d+).*/$1/;
            $usage /= 1024;
            $disk_usage += $usage;
        }
    }
    $usage = sprintf("%.0f", $disk_usage);  ## does normal arithmetic round
    my $limit = $co->disk_limit($domain);
    return($usage, $limit, 'MB');
}

##############################################################################

sub list_server_ips
{
    my $ifconfig = `ifconfig -a`;

    ## get IPv4 addresses
    my @ip4 = ($ifconfig =~ /inet addr:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g);
    @ip4 = grep { $_ ne "127.0.0.1" } @ip4;

    # exclude any elements starting with '10.' (BUG22627)
    @ip4 = grep { $_ !~ /^10\./ } @ip4;

    ## get IPv6 addresses
    my @ip6 = ($ifconfig =~ /inet6\s*(\S+)\s*prefixlen/g);
    @ip6 = grep { $_ ne "::1" } @ip6;

    ## merge and return
    my @ips = (@ip4, @ip6);

    return @ips;
}

##############################################################################

sub parse_conf
{
    ## NOTICE: only one-second granularity. Updates made within a second will fail

    ## main apache config
    my @config_files = ( $APACHE_CONF );
    my $lastmodtime = (lstat($APACHE_CONF))[9];

    ## add available sites (if applicable)
    my $lastmodsite = 0;
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    if (opendir(SITESAVAIL, $sites_dir)) {
        while (defined (my $sfile = readdir(SITESAVAIL))) {
            my $spath = $sites_dir . '/' . $sfile;
            next unless (-f $spath);
            my $slm = (stat(_))[9];
            $lastmodsite = $slm if ($slm > $lastmodsite);
            push(@config_files, $spath);
        }
        closedir(SITESAVAIL);
    }
    $lastmodtime = $lastmodsite if ($lastmodsite > $lastmodtime);

    if ( ! $Cache{_conf} || ($lastmodtime > $Cache{_conf}) ) {
        undef $Cache{vhosts};
        undef $Cache{server};
        $Cache{_conf} = $lastmodtime || 0;
    }

    return if $Cache{vhosts} && $Cache{server};
    undef $Cache{vhosts};
    undef $Cache{server};

    foreach my $config_file (@config_files) {

        # is config file readable?  check first (BUG19032)
        unless (-r $config_file) {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                chmod(0644, $config_file);
            }
        }

        open my $conf_fp, $config_file
          or next;

        local $_;
        my %vhost  = ();
        my @vhost  = ();
        my @state  = ();
        while (<$conf_fp>) {
            chomp;
            next if /^\s*#/ || /^\s*$/;

            if ( m!^\s*<(?:Directory|Location)\b!io ) {
                push @state, IN_DIRLOC;
                next;
            }

            if ( $state[$#state] && IN_DIRLOC == $state[$#state] && m!\s*</(?:Directory|Location)>!io ) {
                pop @state;
                next;
            }

            if ( $state[$#state] && IN_DIRLOC == $state[$#state] ) {
                next;  ## skip directory/location directives
            }

            if ( ( m!^\s*<VirtualHost\s+([\d.\*]+):(\d+)!io ) ||
                 ( m!^\s*<VirtualHost\s+\[([\w:\*]+)\]:(\d+)!io ) ) {
                push @state, IN_VHOST;
                $vhost{ip}   = $1;
                $vhost{port} = $2;
                push @vhost, $_ . "\n";
                next;
            }

            if ( $state[$#state] && IN_VHOST == $state[$#state] && m!\s*</VirtualHost>!io ) {
                pop @state;
                push @vhost, $_ . "\n";
                $vhost{text} = join('', @vhost);

                ## save a deep copy of %vhost
                if ( $vhost{sslenable} || $vhost{port} == 443 ) {
                    $Cache{vhosts}->{ssl}->{$vhost{servername}}   = { %vhost } if $vhost{servername};
                }
                else {
                    $Cache{vhosts}->{nossl}->{$vhost{servername}} = { %vhost } if $vhost{servername};
                }
                %vhost = @vhost = ();
                next;
            }

            if ( $state[$#state] && IN_VHOST == $state[$#state] ) {
                if ( /^\s*ServerName\s+([^\s]+)\s*$/io ) {
                    $vhost{servername} = $1;
                }
                elsif( /^\s*User\s+([^\s]+)\s*$/io ) {
                    $vhost{user} = $1;
                }
                elsif( /^\s*SuexecUserGroup\s+([^\s]+)\s+([^\s]+)\s*$/io ) {
                    $vhost{user} = $1;
                }
                elsif( /^\s*DocumentRoot\s+"?([^\s\"]+)/io ) {
                    $vhost{documentroot} = $1;
                }
                elsif( /^\s*SSLEnable/io ) {
                    $vhost{sslenable} = 1;
                }
                elsif( /^\s*SSLEngine\s+on/io ) {
                    $vhost{sslenable} = 1;
                }
                elsif( /^\s*SSLEngine\s+off/io ) {
                    $vhost{ssldisable} = 1;
                }
                elsif( /^\s*SSLDisable/io ) {
                    $vhost{ssldisable} = 1;
                }
                push @vhost, $_ . "\n";
                next;
            }

            next if $state[$#state];

            ## server directives
            if (/^\s*DocumentRoot\s+"?([^"]+)/io) {
                $Cache{server}->{documentroot} = $1;
            }
            elsif (/^\s*ServerAdmin\s+(.+)\s*$/io) {
                $Cache{server}->{servername} = $1;
            }
            elsif (/^\s*ServerName\s+(.+)\s*$/io) {
                $Cache{server}->{servername} = $1;
            }
            elsif (/^\s*SSLEnable/io) {
                $Cache{server}->{sslenable} = 1;
            }
            elsif (/^\s*SSLEngine\s+on/io) {
                $Cache{server}->{sslenable} = 1;
            }
            elsif (/^\s*SSLEngine\s+off/io) {
                $Cache{server}->{ssldisable} = 1;
            }
            elsif (/^\s*SSLDisable/io) {
                $Cache{server}->{ssldisable} = 1;
            }

            $Cache{server}->{found} = 1;  ## don't bust cache when no main documentroot is found
        }
        close($conf_fp);
    }
}

# ---------------------------------------------------------------------------

sub get_admin
{
    parse_conf();
    my $domain = shift;
    return $Cache{vhosts}->{nossl}->{$domain}->{user};
}

# ---------------------------------------------------------------------------

sub get_docroot
{
    parse_conf();
    my $domain = shift;
    return $Cache{vhosts}->{nossl}->{$domain}->{documentroot};
}

# ---------------------------------------------------------------------------

sub get_docroot_all
{
    my %paths = ();
    parse_conf();
    foreach my $domain (keys(%{$Cache{vhosts}->{nossl}})) {
        $paths{$domain} = $Cache{vhosts}->{nossl}->{$domain}->{documentroot};
    }
    $paths{$Cache{server}->{servername}} = $Cache{server}->{documentroot};
    return %paths;
}

# ---------------------------------------------------------------------------

sub get_server_docroot
{
    parse_conf();
    return $Cache{server}->{documentroot};
}

# ---------------------------------------------------------------------------

sub get_ip
{
    parse_conf();
    my $domain = shift;
    return $Cache{vhosts}->{nossl}->{$domain}->{ip};
}

# ---------------------------------------------------------------------------

sub get_vhost
{
    my $domain = shift
      or return;

    my %vhosts = ();

    parse_conf();
    $vhosts{ssl}   = $Cache{vhosts}->{ssl}->{$domain}->{text} || '';
    $vhosts{nossl} = $Cache{vhosts}->{nossl}->{$domain}->{text} || '';
    return %vhosts;
}

# ---------------------------------------------------------------------------

sub edit_vhost
{
    my $callback = shift;
    my $domain   = shift
      or do {
          warn "Didn't get a domain\n";
          return;
      };
    my %args     = @_;

    my $config_path = $APACHE_CONF;
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    my $domain_config = $sites_dir . "/" . $domain . ".conf";
    $config_path = $domain_config if (-e "$domain_config");

    ## got REWT?
    local $> = $) = 0;  ## regain privileges for a moment

    open CONF, "+< $config_path"
      or do {
           warn "Could not open $config_path (edit_vhost): $!\n";
          return;
      };
    flock CONF, LOCK_EX
      or do {
          close CONF;
          warn "Could not lock $config_path: $!\n";
          return;
      };
    seek CONF, 0, 0;

    local $_;
    my $state = 0;
    my @conf  = ();
    my @vhost = ();
    my $found = 0;

    while( <CONF> ) {
        if ( m!^\s*<VirtualHost!io ) {
            $state = 1;
            push @vhost, $_;
            next;
        }

        if ( $state && m!^\s*</VirtualHost>!io ) {
            $state = 0;
            push @vhost, $_;

            ## is this our vhost?
            if ( $found ) {
                ## NOTE: cache invalidation: this is brutal, but this
                ## NOTE: is the heuristic we use in parse_conf() to
                ## NOTE: determine sanity. Someday, it would be nice
                ## NOTE: to do per-vhost invalidation.
                delete $Cache{_conf};
                eval { @vhost = &$callback($domain, \%args, @vhost); };
                if ( $@ ) {
                    close CONF;
                    warn "Got error from callback: $@\n";
                    return;
                }
            }

            ## add this vhost to the pile
            push @conf, @vhost;

            ## reset state
            @vhost = ();
            $found = 0;

            next;
        }

        ## in a virtualhost block
        if ( $state ) {
            if ( /^\s*ServerName\s+\Q$domain\E\s*$/i ) {
                $found = 1;
            }
            push @vhost, $_;
            next;
        }

        push @conf, $_;
    }

    ## write out new config file
    seek CONF, 0, 0;
    print CONF @conf;
    truncate CONF, tell CONF;
    close CONF;

    # make sure we have read perms (BUG19032)
    chmod(0644, $config_path);

    1;
}

# ---------------------------------------------------------------------------

sub _disable
{
    my $vsap   = shift;
    my $domain = shift;

    ##
    ## disable Apache virtual host
    ##

    # enable the mod_rewrite module
    my $rewrite_module = "modules/mod_rewrite.so";
    VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
                                                     module => $rewrite_module,
                                                     action => 'enable' );

  DISABLE_VHOST: {

        ## disable the virtual host
        VSAP::Server::Modules::vsap::logger::log_message("disabling VirtualHost for domain '$domain'");
        VSAP::Server::Modules::vsap::domain::edit_vhost
            (sub {
                 my $domain = shift;
                 my $args   = shift;
                 my @vhost  = @_;

                 return @vhost if join('', @vhost) =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio;

                 ## if you change the start/end markers, be sure you
                 ## fix them in 'enable' and in the domain:list
                 ## handler which groks that string to determine
                 ## whether a domain is enabled or not
                 splice @vhost, 1, 0, (qq!    ## start VirtualHost disabled\n!,
                                       qq!    ## No user-servicable parts inside.\n!,
                                       qq!    ## use CPX to re-enable, and you will have peace\n!,
                                       qq!    ## If the seal is broken, the warranty is voided\n!,
                                       qq!    RewriteEngine on\n!,
                                       qq!    RewriteRule   ^/ - [F,L]\n!,
                                       qq!    ## end VirtualHost disabled\n!,);
                 return @vhost;
             }, $domain );

        ## restart apache (gracefully)
        $vsap->need_apache_restart();
    }

    ## LoadModule    rewrite_module libexec/mod_rewrite.so
    ## RewriteEngine on
    ## RewriteRule   ^/ - [F,L]

  DISABLE_LOCALHOSTNAME: {
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::localhostname(domain => $domain,
                                                         action => 'disable');
        ## reload/restart mail service
        VSAP::Server::Modules::vsap::mail::restart();
    }

    ##
    ## disable savelogs
    ##
  DISABLE_SAVELOGS: {
        local $> = $) = 0;  ## regain privileges for a moment
      FREQ: for my $freq qw(daily weekly monthly) {  ## disable in all conf files
            next unless -f "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
            my $conf = "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
            my $sc = new Config::Savelogs($conf)
              or do {
                  warn "Could not open '$conf': $!\n";
                  next FREQ;
              };

            my $group = $sc->find_group( match => { ApacheHost => $domain } )
              or next FREQ;
            $group->{disabled} = 1;
            $sc->write;
        }
    }

    ##
    ## disable users
    ##
  DISABLE_USERS: {
        my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{server_admin});
        my $users = $co->users(domain => $domain);

        ## got REWT?
        local $> = $) = 0;  ## regain privileges for a moment

        # do not disable server administrators (BUG31873)
        my $gid = $vsap->is_linux() ? 10 : 0;
        my %admins = map { $_ => (getpwnam($_))[0] } split(' ', (getgrgid($gid))[3]);

        open(PWD, $SHADOW) || return(0);
        local $_;
        my %pwd = ();
        while( <PWD> ) {
            my($user,$pass,undef) = split(':', $_, 3);
            next unless $users->{$user};
            next if $admins{$user};  # skip server admin (BUG31873)
            ## NOTE: we disable with *DISABLED* here, which is different
            ## NOTE: than how an individual user is disabled. This is so
            ## NOTE: that when a server admin re-enables the domain, any
            ## NOTE: end users that were previously disabled by the domain
            ## NOTE: admin will remain disabled.
            if ($pass !~ /\*DISABLED\*/) {
                if ($pass =~ /^(\!|\*LOCKED\*)(.*)/) {
                    ## this user was previously disabled
                    $pass = $1 . '*DISABLED*' . $2;
                }
                else {
                    $pass = '*DISABLED*' . $pass;
                }
            }
            $pwd{$user} = $pass;
        }
        close PWD;

        for my $user ( keys %$users ) {
            next if $admins{$user};  # skip server admin (BUG31873)
            VSAP::Server::Modules::vsap::logger::log_message("disabling user '$user'");
            system($CHPASS, '-p', $pwd{$user}, $user);  ## FIXME: not optimized for many users
        }
    }

    return(1);
}

##############################################################################

sub _enable
{
    my $vsap   = shift;
    my $domain = shift;

    ##
    ## remove rewrite directives
    ##
  ENABLE_VHOST: {
        VSAP::Server::Modules::vsap::logger::log_message("enabling VirtualHost for domain '$domain'");
        VSAP::Server::Modules::vsap::domain::edit_vhost
            (sub {
                 my $domain = shift;
                 my $args   = shift;
                 my @vhost  = @_;

                 my @tmp    = ();
                 my $state  = 0;
                 for my $line ( @vhost ) {
                     if ( $line =~ /^\s*\#\# start VirtualHost disabled/io ) {
                         $state = 1;
                         next;
                     }

                     elsif( $line =~ /^\s*\#\# end VirtualHost disabled/io ) {
                         $state = 0;
                         next;
                     }

                     next if $state;
                     push @tmp, $line;
                 }

                 return @tmp;
             }, $domain );

        ## restart apache (gracefully)
        $vsap->need_apache_restart();
    }

    ##
    ## uncomment out entry in /etc/mail/local-host-names
    ##
  ENABLE_LOCALHOSTNAME: {
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::localhostname(domain => $domain,
                                                         action => 'enable');
        ## reload/restart mail service
        VSAP::Server::Modules::vsap::mail::restart();
    }

    ##
    ## enable savelogs
    ##
  ENABLE_SAVELOGS: {
        local $> = $) = 0;  ## regain privileges for a moment
      FREQ: for my $freq qw(daily weekly monthly) {  ## enable in all conf files?
            next unless -f "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
            my $conf = "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
            my $sc = new Config::Savelogs($conf)
              or do {
                  warn "Could not open '$conf': $!\n";
                  next FREQ;
              };

            my $group = $sc->find_group( match => { ApacheHost => $domain } )
              or next FREQ;
            delete $group->{disabled};
            $sc->write;

            ## freshen up the crontab too; it's easier to remove and
            ## add an entry than make sure it's all right
            my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 ); $ct->read;
            $ct->remove( $ct->select( -type       => 'event',
                                      -user       => 'root',
                                      -special    => '@' . $freq,
                                      -command_re => qr(savelogs\s+--config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf) ) );
            my $block = new Config::Crontab::Block;
            $block->last( new Config::Crontab::Event( -special => '@' . $freq,
                                                      -user    => 'root',
                                                      -command => qq!savelogs --config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf! ) );
            $ct->last($block);
            $ct->write;
        }
    }

    ##
    ## enable users
    ##
  ENABLE_USERS: {
        my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{server_admin});
        my $users = $co->users(domain => $domain);
        my $domains = $co->domains(domain => $domain);
        my $domain_admin = $domains->{$domain};

        ## got REWT?
        local $> = $) = 0;  ## regain privileges for a moment

        open (PWD, $SHADOW) || return(0);
        local $_;
        my %pwd = ();
        while( <PWD> ) {
            my($user,$pass,undef) = split(':', $_, 3);
            next unless $users->{$user};
            $pass =~ s/\*DISABLED\*//;
            $pwd{$user} = $pass;
        }
        close PWD;

        ## NOTE: we enable by removing the *DISABLED* here.  This is so
        ## NOTE: that when a server admin re-enables the domain, any
        ## NOTE: end users that were previously disabled by the domain
        ## NOTE: admin will remain disabled.
        for my $user ( keys %$users ) {
            VSAP::Server::Modules::vsap::logger::log_message("enabling user '$user'");
            system($CHPASS, '-p', $pwd{$user}, $user);  ## FIXME: not optimized for many users
        }

        # make sure the domain admin is enabled (ENH25432)
        $co->init( username => $domain_admin );
        $co->disabled(0);
    }

    return(1);
}

##############################################################################

sub _do_addhost
{
    my($vsap, $user, $hostname, $aliases, $admin, $cgi, $ip, $logs) = @_;

    local $> = $) = 0;  ## regain privileges for a moment

    my($pw_uid, $pw_gid, $pw_dir) = (getpwnam $user)[2, 3, 7];
    return unless $pw_uid;
    $pw_dir =~ s/\/+$//;
    my $pw_group = getgrgid($pw_gid) || $user;
    my $apache_gid = getgrnam($VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP);

    ## Make the DocumentRoot
    my $wwwdir = "$pw_dir/www";
    mkdir $wwwdir, 0750
        and chown $pw_uid, $apache_gid, $wwwdir;
    my $docroot = "$pw_dir/www/$hostname";
    mkdir $docroot, 0755
        and chown $pw_uid, $apache_gid, $docroot;

    ## Set up the log files
    my @log;
    if (!$logs) {
        @log = ("TransferLog    /dev/null",
                "ErrorLog       /dev/null");
    }
    else {
        my $logdir = "/var/log/httpd/$user";
        my $tfile = "$logdir/$hostname-access_log";
        my $efile = "$logdir/$hostname-error_log";
        @log = ("CustomLog      $tfile combined",
                "ErrorLog       $efile");
        mkdir $logdir, 0750
            and chown 0, $pw_gid, $logdir;
        if (!-e $tfile) {
            open my $lf, '>', $tfile;
            close $lf;
            chown 0, $pw_gid, $tfile;
            chmod 0640, $tfile;
        }
        if (!-e $efile) {
            open my $lf, '>', $efile;
            close $lf;
            chown 0, $pw_gid, $efile;
            chmod 0640, $efile;
        }
        if (!-e "$wwwdir/logs")
        {
            local $) = $apache_gid;
            local $> = $pw_uid;
            symlink $logdir, "$wwwdir/logs";
        }
    }

    ## Set up the CGI bin
    my @cgi;
    if (!$cgi) {
        @cgi = ('Alias          /cgi-bin /dev/null',
                'Options        -ExecCGI');
    }
    else {
        my $cgidir = "$wwwdir/cgi-bin";
        mkdir $cgidir, 0755
            and chown $pw_uid, $pw_gid, $cgidir;
        @cgi = ("ScriptAlias    /cgi-bin/ $cgidir/",
                "<Directory $cgidir>",
                '    AllowOverride None',
                '    Options    ExecCGI',
                '    Order      allow,deny',
                '    Allow      from all',
                '</Directory>');
    }

    ## non-ssl block
    my @out =
        ( "\n",
          "## vaddhost: ($hostname) at $ip:80\n",
          "<VirtualHost $ip:80>\n",
          "    SuexecUserGroup $user $pw_group\n",
          "    ServerName     $hostname\n",
          (@$aliases ? "    ServerAlias    @$aliases\n" : ()),
          "    ServerAdmin    $admin\n",
          "    DocumentRoot   $docroot\n",
          map("    $_\n", @cgi),
          "    <IfModule mod_rewrite.c>\n",
          "        RewriteEngine On\n",
          "        RewriteOptions Inherit\n",
          "    </IfModule>\n",
          map("    $_\n", @log),
          "</VirtualHost>\n");

    ## ssl block
    push @out,
        ( "\n",
          "## vaddhost: ($hostname) at $ip:443\n",
          "<VirtualHost $ip:443>\n",
          "    SSLEngine      on\n",
          "    SuexecUserGroup $user $pw_group\n",
          "    ServerName     $hostname\n",
          (@$aliases ? "    ServerAlias    @$aliases\n" : ()),
          "    ServerAdmin    $admin\n",
          "    DocumentRoot   $docroot\n",
          map("    $_\n", @cgi),
          "    <IfModule mod_rewrite.c>\n",
          "        RewriteEngine On\n",
          "        RewriteOptions Inherit\n",
          "    </IfModule>\n",
          map("    $_\n", @log),
          "</VirtualHost>\n");

    my $config_path = "";
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    if (-d "$sites_dir") {
        $config_path = $sites_dir . "/" . $hostname . ".conf";
    }
    else {
        $config_path = $APACHE_CONF;
    }

    ## write virtual host entry to config
    if (-e "$config_path") {
        open( CONF, '+<', $config_path )
            or do {
                my $errmsg = "Could not open $config_path: $!";
                VSAP::Server::Modules::vsap::logger::log_error($errmsg);
                warn "$errmsg\n";
                return 0;
            };
    }
    else {
        # create new config file (e.g. in sites-available)
        open( CONF, '>', $config_path )
            or do {
                my $errmsg = "Could not create $config_path: $!";
                VSAP::Server::Modules::vsap::logger::log_error($errmsg);
                warn "$errmsg\n";
                return 0;
            };
    }
    flock CONF, LOCK_EX
        or do {
            close CONF;
            my $errmsg = "Could not lock $config_path: $!";
            VSAP::Server::Modules::vsap::logger::log_error($errmsg);
            warn "$errmsg\n";
            return 0;
        };

    seek CONF, 0, 2;      ## seek to eof
    my $last = tell CONF; ## last VirtualHost entry found (default = EOF)
    my @eof  = ();        ## the rest of the file after last VirtualHost entry

    seek CONF, 0, 0;      ## rewind disk
    local $_;
    while( <CONF> ) {
        $last = tell CONF
            if m!^#*\s*</VirtualHost>!io;
    }
    seek CONF, $last, 0;  ## go back to the last </VirtualHost> line (or eof)
    @eof = <CONF>;        ## save the rest (if any)

    seek CONF, $last, 0;  ## go back to end of vhost section
    print CONF @out;      ## add new virtual host block
    print CONF @eof;      ## put the rest of the file back

    truncate CONF, tell CONF;
    close CONF;

    return 1;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::list_ips;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'domain:list_ips');

    for my $ip (VSAP::Server::Modules::vsap::domain::list_server_ips()) {
        $root->appendTextChild(ip => $ip);
    }
    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::list;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $admin  = ( $vsap->{server_admin}
                   ? ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                       ? $xmlobj->child('admin')->value
                       : '' )
                   : $vsap->{username} );
    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : '' );

    my $properties = ( $xmlobj->child('properties') ? 1 : 0 );
    my $diskspace = ( $xmlobj->child('diskspace') ? 1 : 0 );

    my $page = -1;  ## value of -1 == do not page/sort

    VSAP::Server::Modules::vsap::domain::build_list('domain:list', $vsap, $xmlobj, $dom, $admin, $domain, $properties, $diskspace, $page);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::admin_list;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $admin  = $vsap->{username};
    my $domain = '';

    my $properties = 0;
    my $diskspace = 0;

    my $page = -1;  ## value of -1 == do not page/sort

    VSAP::Server::Modules::vsap::domain::build_list('domain:admin_list', $vsap, $xmlobj, $dom, $admin, $domain, $properties, $diskspace, $page);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::paged_list;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $admin  = ( $vsap->{server_admin}
                   ? ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                       ? $xmlobj->child('admin')->value
                       : '' )
                   : $vsap->{username} );
    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : '' );

    my $properties = ( $xmlobj->child('properties') ? 1 : 0 );
    my $diskspace = ( $xmlobj->child('diskspace') ? 1 : 0 );

    my $page = ($xmlobj->child('page') && $xmlobj->child('page')->value
                   ? $xmlobj->child('page')->value
                   : 1 );

    VSAP::Server::Modules::vsap::domain::build_list('domain:paged_list', $vsap, $xmlobj, $dom, $admin, $domain, $properties, $diskspace, $page);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::add;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $admin          = ( $xmlobj->child('admin') && $xmlobj->child('admin')->value
                           ? $xmlobj->child('admin')->value
                           : undef );
    my $domain         = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                           ? lc($xmlobj->child('domain')->value)
                           : do { $vsap->error($_ERR{DOMAIN_ADD_MISSING_DOMAIN} => "Missing domain");
                                  return } );

    my $www_alias      = ( $xmlobj->child('www_alias') && defined $xmlobj->child('www_alias')->value
                           ? $xmlobj->child('www_alias')->value
                           : undef );
    my $have_other_aliases = ( $xmlobj->child('other_aliases') ? 1 : 0 );
    my $other_aliases  = ( $have_other_aliases && $xmlobj->child('other_aliases')->value
                           ? $xmlobj->child('other_aliases')->value
                           : '' );
    my @delete_aliases = ( $xmlobj->child('delete_alias')
                           ? map { lc($_->value) } $xmlobj->children('delete_alias')
                           : undef );
    my $add_alias      = ( $xmlobj->child('add_alias')
                           ? lc($xmlobj->child('add_alias')->value)
                           : undef );

    my $cgi            = ( $xmlobj->child('cgi') && defined $xmlobj->child('cgi')->value
                           ? $xmlobj->child('cgi')->value
                           : undef );
    my $ssl            = ( $xmlobj->child('ssl') && defined $xmlobj->child('ssl')->value
                           ? $xmlobj->child('ssl')->value
                           : undef );
    my $ip             = ( $xmlobj->child('ip') && defined $xmlobj->child('ip')->value
                           ? $xmlobj->child('ip')->value
                           : undef );

    my $end_users      = ( $xmlobj->child('end_users') && defined $xmlobj->child('end_users')->value
                           ? $xmlobj->child('end_users')->value
                           : undef );
    my $email_addr     = ( $xmlobj->child('email_addrs') && defined $xmlobj->child('email_addrs')->value
                           ? $xmlobj->child('email_addrs')->value
                           : undef );
    my $website_logs   = ( $xmlobj->child('website_logs') && $xmlobj->child('website_logs')->value
                           ? $xmlobj->child('website_logs')->value
                           : undef );
    my $log_rotate     = ( $xmlobj->child('log_rotate') && $xmlobj->child('log_rotate')->value
                           ? $xmlobj->child('log_rotate')->value
                           : undef );
    my $log_save       = ( $xmlobj->child('log_save') && $xmlobj->child('log_save')->value
                           ? $xmlobj->child('log_save')->value
                           : ($log_rotate ? 7 : undef) );
    my $domain_contact = ( $xmlobj->child('domain_contact') && $xmlobj->child('domain_contact')->value
                           ? $xmlobj->child('domain_contact')->value
                           : undef );
    my $mail_catchall  = ( $xmlobj->child('mail_catchall') && $xmlobj->child('mail_catchall')->value
                           ? $xmlobj->child('mail_catchall')->value
                           : undef );
    my $is_edit        = ( $xmlobj->child('edit') && $xmlobj->child('edit')->value
                           ? $xmlobj->child('edit')->value
                           : undef );

    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    ## if domain admin editing, verify they administer the domain being edited
    if (! defined($vsap->{server_admin}) ) {
       if (!$domain || !$admin) {
        $vsap->error( $_ERR{DOMAIN_PERMISSION} => "Not authorized" );
        return;
       }
      my $domains = $co->domains(domain => $domain);
      if (defined ($domains->{$domain}) && $domains->{$domain} ne $admin) {
        $vsap->error( $_ERR{DOMAIN_PERMISSION} => "Not authorized" );
        return;
      }
   }

    ## if domain admin doing the editing, enforce limitations
    if (!defined($vsap->{server_admin})) {
        if (!$is_edit) {
            $vsap->error($_ERR{DOMAIN_PERMISSION} => 'Permission denied - domain admin can only edit, not add');
            return;
        }

        if ($www_alias || $other_aliases || $cgi || $ssl || $end_users ||
           $email_addr || $website_logs || $log_rotate || $log_save) {
            $vsap->error($_ERR{DOMAIN_PERMISSION} => 'Permission denied - domain admin can only edit domain contact and mail catchall');
            return;
        }
    }

    ## admin sanity checks
    my $admin_is_being_promoted = 0;  ## flag set if promoting an end user to admin
    if ( $is_edit ) {
        $admin ||= VSAP::Server::Modules::vsap::domain::get_admin($domain);
    }
    else {
        ## domain admin is required
        unless ($admin) {
            $vsap->error($_ERR{DOMAIN_ADD_MISSING_ADMIN} => "Missing domain admin");
            return;
        }
        ## domain contact is required
        unless ($domain_contact) {
            $vsap->error($_ERR{DOMAIN_ADD_MISSING_CONTACT} => "Missing contact");
            return;
        }
        ## make sure the user exists (and is non-root!)
        unless (getpwnam($admin)) {
            $vsap->error($_ERR{DOMAIN_ADMIN_BAD} => "Domain admin does not exist (or is root)");
            return;
        }
        ## make sure our domain isn't already listed (in apache config or in sites-available)
        my $escaped_domain = $domain;
        $escaped_domain =~ s#\.#\\\.#;
        unless( system('egrep', '-qi', "^[[:space:]]*ServerName[[:space:]]+$escaped_domain\$", $APACHE_CONF) ) {
            $vsap->error($_ERR{DOMAIN_ADD_EXISTS} => "Domain already exists in $APACHE_CONF");
            return;
        }
        my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
        if (-d "$sites_dir") {
            my $domain_config = $sites_dir . "/" . $domain . ".conf";
            if (-e "$domain_config") {
                $vsap->error($_ERR{DOMAIN_ADD_EXISTS} => "Domain already exists in sites-available");
                return;
            }
        }
        ## is this a promotion (from eu to da)?
        $admin_is_being_promoted = ! $co->domain_admin( admin => $admin );
    }

    ## add domain node

    ## can't do anything w/ the primary domain
    if ( $domain eq $co->primary_domain ) {
        $vsap->error($_ERR{DOMAIN_PRIMARY_NA} => "Primary domain not available for editing");
        return;
    }

    ## make sure doesn't exist
    unless ($is_edit) {
        if ($co->domain_admin(domain => $domain)) {
            $vsap->error( $_ERR{DOMAIN_ADD_EXISTS} => "Domain already exists in cpx.conf");
            return;
        }
    }

    ##
    ## some normalization
    ##

    $www_alias = 1 if ($domain =~ s/^www\.//i && $vsap->{server_admin});

    my @other_aliases = map { s/^\s*//; s/\s*$//; lc } split(/[, ]/, $other_aliases);

    if ( $domain_contact ) {
        unless( Email::Valid->address( $domain_contact ) && $domain_contact =~ qr(^\S+$) ) {
            $vsap->error($_ERR{DOMAIN_CONTACT_BAD} => "Bad domain contact found");
            return;
        }
    }

    if ( defined $email_addr && $email_addr ne 'unlimited') {
        unless( $email_addr =~ qr(^\d+$) ) {
            $vsap->error($_ERR{DOMAIN_EMAIL_ADDRS_BAD} => "Bad number for email addresses limit");
            return;
        }
    }

    if ( defined $end_users && $end_users ne 'unlimited') {
        unless( $end_users =~ qr(^\d+$) ) {
            $vsap->error($_ERR{DOMAIN_END_USERS_BAD} => "Bad number for end users limit");
            return;
        }
    }

    ## add a trace to the message log
    if ( $is_edit ) {
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling domain:add (in edit mode) for domain '$domain'");
    }
    else {
        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling domain:add for domain '$domain'");
    }

    ## load up old vhost information (for change comparison purposes)
    my %vhosts = ();
    if ( $is_edit ) {
        %vhosts = VSAP::Server::Modules::vsap::domain::get_vhost($domain);
    }

    ##
    ## make backups as required
    ##

    VSAP::Server::Modules::vsap::backup::backup_system_file($APACHE_CONF);
    VSAP::Server::Modules::vsap::backup::backup_system_file($ALIASES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($GENERICS);
    VSAP::Server::Modules::vsap::backup::backup_system_file($LOCALHOSTNAMES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($VIRTUSERTABLE);
    for my $freq qw(daily weekly monthly) {
        VSAP::Server::Modules::vsap::backup::backup_system_file("$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf");
    }

    ##
    ## setup VirtualHost block
    ##

    my $lhn_changed;

    # begin main edit domain block
    if ( $is_edit ) {

      my $changed;

      IP_ADDRESS: {
            last IP_ADDRESS unless defined $ip;
            if ($ip) {
                set_IP($domain, $ip);
                VSAP::Server::Modules::vsap::logger::log_message("IP address for domain '$domain' set to '$ip'");
                $changed = 1;
            }
      }

      WWW_ALIAS: {
            last WWW_ALIAS unless defined $www_alias;

            ## make sure exists
            if ( $www_alias ) {
                add_ServerAlias($domain, "www.$domain")
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("www alias for domain '$domain' added");
                $changed = 1;
            }

            ## make sure doesn't exist
            else {
                remove_ServerAlias($domain, "www.$domain")
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("www alias for domain '$domain' removed");
                $changed = 1;
            }
        }

      ADD_ALIAS: {
            last ADD_ALIAS unless defined $add_alias;
            add_ServerAlias($domain, $add_alias)
              or do {
                  $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error adding additional aliases: $!");
                  return;
              };
            VSAP::Server::Modules::vsap::logger::log_message("server alias '$add_alias' for domain '$domain' added");
            add_ServerAlias($domain, "www.$add_alias")
              or do {
                  $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error adding additional aliases: $!");
                  return;
              };
            VSAP::Server::Modules::vsap::logger::log_message("server alias 'www.$add_alias' for domain '$domain' added");
            $changed = 1;

        }

      DELETE_ALIASES: {
            for my $alias ( @delete_aliases ) {
              next unless $alias;
              remove_ServerAlias($domain, $alias)
                or do {
                    $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error removing additional aliases: $!");
                    return;
                };
              VSAP::Server::Modules::vsap::logger::log_message("server alias '$alias' for domain '$domain' removed");
              remove_ServerAlias($domain, "www.$alias")
                or do {
                    $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error removing additional aliases: $!");
                    return;
                };
              VSAP::Server::Modules::vsap::logger::log_message("server alias 'www.$alias' for domain '$domain' removed");
            }
            $changed = 1;
        }

      OTHER_ALIASES: {
            last OTHER_ALIASES unless $have_other_aliases;
            ## get the existing aliases in httpd.conf, compare w/ @other_aliases

            my %original_aliases = ();
            while( $vhosts{nossl} =~ /^\s*ServerAlias\s+(.+)$/mig ) {
                my @other_aliases = split(' ', $1 );
                @original_aliases{@other_aliases} = (1) x @other_aliases;
            }
            my $has_www_alias = delete $original_aliases{"www.$domain"};

            ## compare w/ @other_aliases
            last OTHER_ALIASES if join(' ', sort @other_aliases) eq join(' ', sort keys %original_aliases );

            my %other_aliases = ();
            @other_aliases{@other_aliases} = (1) x @other_aliases;

            ## delete missing aliases
            for my $alias ( keys %original_aliases ) {
                next if $other_aliases{$alias};  ## skip existing aliases
                {
                        local $> = $) = 0;  ## regain privileges for a moment
                        VSAP::Server::Modules::vsap::mail::localhostname( domain => $alias, action => 'delete' );
                        $lhn_changed = 1;
                }
                remove_ServerAlias($domain, $alias)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error removing additional aliases: $!");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("server alias '$alias' for domain '$domain' removed");
                $changed = 1;
            }

            ## add new aliases
            for my $alias ( @other_aliases ) {
                {
                    local $> = $) = 0;  ## regain privileges for a moment
                    VSAP::Server::Modules::vsap::mail::localhostname( domain => $alias, action => 'add' );
                    $lhn_changed = 1;
                }
                add_ServerAlias($domain, $alias)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error adding additional aliases: $!");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("server alias '$alias' for domain '$domain' added");
                $changed = 1;
            }
        }

      DOMAIN_CONTACT: {
            last DOMAIN_CONTACT unless defined $domain_contact;

            if ( $domain_contact ) {
                set_Contact($domain, $domain_contact);
                VSAP::Server::Modules::vsap::logger::log_message("contact for domain '$domain' set to '$domain_contact'");
                $changed = 1;
            }
        }

      CGI_BIN: {
            last CGI_BIN unless defined $cgi;

            if ( $cgi ) {
                add_CgiBin($domain)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("cgi-bin for domain '$domain' added");
                $changed = 1;
            }

            ## remove cgi-bin
            else {
                remove_CgiBin($domain);
                VSAP::Server::Modules::vsap::logger::log_message("cgi-bin for domain '$domain' removed");
                $changed = 1;
            }
        }

      SSL: {
            last SSL unless defined $ssl;

            if ( $ssl ) {
                add_SSL($domain)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!\n");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("ssl for domain '$domain' added");
                $changed = 1;
            }

            ## remove ssl
            else {
                remove_SSL($domain, $vsap)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!\n");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("ssl for domain '$domain' removed");
                $changed = 1;
            }
        }

      LOGS: {
            last LOGS unless defined $website_logs;

            ## enable logging
            if ( $website_logs !~ /^[Nn]/ ) {
                add_Weblogs($domain, $admin)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!\n");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("logging for domain '$domain' enabled");
                $changed = 1;
            }

            ## disable logging
            else {
                remove_Weblogs($domain)
                  or do {
                      $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Error editing config file: $!\n");
                      return;
                  };
                VSAP::Server::Modules::vsap::logger::log_message("logging for domain '$domain' disabled");
                $changed = 1;
            }
        }

      USERS: {
            last USERS unless defined $end_users;
            $co->user_limit($domain, $end_users);
        }

      EMAIL_ADDRS: {
            last EMAIL_ADDRS unless defined $email_addr;
            $co->alias_limit($domain, $email_addr);
        }

        if ( $changed ) {
            ## restart apache (gracefully)
            $vsap->need_apache_restart();
        }
    }
    # end main edit domain block

    # begin main add domain block
    else {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            # make sure www_path for admin has correct ownership and perms (BUG26851)
            my $www_path = (getpwnam($admin))[7] . "/www";
            my $group = $VSAP::Server::Modules::vsap::globals::APACHE_RUN_GROUP;
            chown scalar(getpwnam($admin)), scalar(getgrnam($group)), "$www_path";
        }

        ## add the new host block to Apache config file
        if (!VSAP::Server::Modules::vsap::domain::_do_addhost(
                 $vsap,
                 $admin,
                 $domain,
                 [($www_alias ? "www.$domain" : ()), @other_aliases],
                 $domain_contact,
                 $cgi,
                 $ip,
                 $website_logs && $website_logs !~ /^[Nn]/ )) {
            # trap on _do_addhost() failure (BUG26851)
            $vsap->error($_ERR{VADDHOST_FAILED} => "Error adding vhost");
            VSAP::Server::Modules::vsap::logger::log_error("_do_addhost() for '$domain' failed: $!");
            return;
        }
        VSAP::Server::Modules::vsap::logger::log_message("_do_addhost() for '$domain' successful");

        unless ( $ssl ) {
            ## if SSL box is not checked, disable SSL (see BUG23160)
            remove_SSL($domain, $vsap);
        }
        else {
            ## SSL box checked, add a self-signed cert
            require VSAP::Server::Modules::vsap::sys::ssl;
            VSAP::Server::Modules::vsap::sys::ssl::install_cert($vsap, $domain, {apache => 1}, undef, undef, undef, 1, 1);
        }

        ## update local-host-names w/ aliases
        for my $alias ( @other_aliases ) {
                local $> = $) = 0;  ## regain privileges for a moment
                VSAP::Server::Modules::vsap::mail::localhostname( domain => $alias, action => 'add' );
                $lhn_changed = 1;
        }

        ## update config file
        $co->add_domain($domain);      ## this re-reads httpd.conf, so this must execute after _do_addhost
        $co->user_limit( $domain, ( defined $end_users  ? $end_users  : 0)); ## depends on domain
        $co->alias_limit($domain, ( defined $email_addr ? $email_addr : 0)); ## ...node existence

        ## if end user is being promoted to a domain admin, then do some stuff
        if ( $admin_is_being_promoted ) {
            $co->init( username => $admin );             ## init as new domain admin
            $co->domain( $domain );

            ## give the newly promoted admin some capabilities to pass on to end users
            my $user_services = $co->services;
            $co->eu_capabilities(
              mail => ($user_services->{'mail'} ? 1 : 0),
              fileman => ($user_services->{'fileman'} ? 1 : 0),
              ftp => ($user_services->{'ftp'} ? 1 : 0),
              shell => ($user_services->{'shell'} ? 1 : 0)
            );

            $co->init( username => $vsap->{username} );  ## revert to authenticated user
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                my $dest = $admin . '@'. $domain;
                VSAP::Server::Modules::vsap::mail::genericstable( user => $admin, dest => $dest );
                ## set up promoted admin's group quota
                my $dev = Quota::getqcarg('/home');
                my $uq = (Quota::query(Quota::getqcarg('/home'), (getpwnam($admin))[2]))[1];
                Quota::setqlim($dev, (getgrnam($admin))[2], $uq, $uq, 0, 0, 0, 1);
                Quota::sync($dev);
            }
        }

        # restart apache (gracefully)
        $vsap->need_apache_restart();
    }
    # end main add domain block

    ##
    ## setup(/remove) log rotation
    ##

    ## did the logs go from an enabled state to a disabled state?
    my $logs_enabled_in_config;
    if ( $is_edit ) {
        $logs_enabled_in_config = 1;
        if ( $vhosts{nossl} =~ qr(^\s*(?:Transfer|Custom)Log\s+(.+))mio ) {
            my $log = $1;
            if ( $log =~ qr(/dev/null)o ) {
                $logs_enabled_in_config = 0;
            }
        }
    }

    ## placeholder to preserve disabled-ness (BUG25443)
    my $rotation_disabled_in_config = 0;

  LOG_ROTATION: {
        last LOG_ROTATION
          if ! $is_edit or ! $vsap->{server_admin};

        ## delete the crontab, unless we have $log_rotate set UNLESS $website_logs is "none"
        last LOG_ROTATION
          unless defined $website_logs && ($website_logs !~ /^[Nn]/ || $logs_enabled_in_config);

        ## make sure the old rotation scheme is removed
        ## remove the savelogs conf entry, if any
      REMOVE_DOMAIN_FROM_SAVELOGS: {
            local $> = $) = 0;  ## regain privileges for a moment
          FREQ: for my $freq qw(daily weekly monthly) {  ## remove from all possible conf files
                next unless -f "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                my $conf = "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                my $sc = new Config::Savelogs($conf)
                  or do {
                      warn "Could not open '$conf': $!\n";
                      next FREQ;
                  };
                my $group = $sc->find_group( match => { ApacheHost => $domain } );
                $rotation_disabled_in_config = $group->{disabled} if ( $group );
                $sc->remove_from_group( match => { ApacheHost => $domain }, apachehost => $domain );
                VSAP::Server::Modules::vsap::logger::log_message("removing domain '$domain' from $freq savelogs config");

                if ( ! exists $sc->data->{groups} or
                    ! scalar(@{$sc->data->{groups}}) ) {
                    unlink $conf;

                    ## remove crontab entry too
                    my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 ); $ct->read;
                    $ct->remove( $ct->select( -type       => 'event',
                                              -user       => 'root',
                                              -special    => '@' . $freq,
                                              -command_re => qr(savelogs\s+--config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf) ) );
                    $ct->write;
                }
                else {
                    $sc->write if $sc->is_dirty;
                }
            }
        }
    }

    ## log rotation: daily, weekly, monthly
    if ( $log_rotate && defined $website_logs && $website_logs !~ /^[Nn]/ ) {
        my $freq = lc($log_rotate);
        unless( $freq =~ /^(daily|weekly|monthly)$/ ) {
            $vsap->error($_ERR{DOMAIN_LOG_ROTATE_BAD} => "Illegal rotation period");
            return;
        }

        VSAP::Server::Modules::vsap::logger::log_message("adding domain '$domain' to $freq savelogs config");

      ## now configure a savelogs rotation in the appropriate .conf file
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            my $conf = $SAVELOGS_CONFIG_PATH . '/savelogs-cpx.' . $freq . '.conf';
            my $sc = new Config::Savelogs($conf)
              or do {
                warn "Could not open '$conf': $!\n";
                $vsap->error($_ERR{DOMAIN_PERMISSION} => "Could not open '$conf': $!");
                last REWT;
              };

            # where is the domain <VirtualHost> defined?
            my $config_path = $APACHE_CONF;
            my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
            if (-d "$sites_dir") {
                $config_path = $sites_dir . "/" . $domain . ".conf";
            }

            $sc->set(ApacheConf   => $config_path,
                     PostMoveHook => '/usr/local/sbin/restart_apache');

            my %group = ( ApacheHost => $domain, Chown => $admin );
            if ($log_save ne 'all') { $group{Period} = $log_save; }
            ## check if previous state was disabled, if so then preserve (BUG25443)
            if ($rotation_disabled_in_config) { $group{Disabled} = 1; }
            if ( $is_edit ) {
                ## check if domain is disabled, if so then disable log rotation as well (BUG31501)
                if ($vhosts{nossl} =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio) { $group{Disabled} = 1; }
            }
            $sc->add_group(%group);
            $sc->write;

            ## create a crontab entry if needed;
            ## this remove() call just keeps new events from accumulating
            my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 ); $ct->read;
            $ct->remove( $ct->select( -type       => 'event',
                                      -user       => 'root',
                                      -special    => '@' . $freq,
                                      -command_re => qr(savelogs\s+--config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf) ) );
            my $block = new Config::Crontab::Block;
            $block->last( new Config::Crontab::Event( -special => '@' . $freq,
                                                      -user    => 'root',
                                                      -command => qq!savelogs --config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf! ) );
            $ct->last($block);
            $ct->write;
        }
    }

    ##
    ## set mail catchall
    ##

  MAIL_CATCHALL: {
        my $delivery = 'error:nouser User unknown';
        if ( $is_edit ) {
            $mail_catchall ||= 'reject' if ( defined($mail_catchall) && ! $mail_catchall );
        }
        else {
            $mail_catchall ||= 'reject';
        }

        if ( defined $mail_catchall ) {
            if ( $mail_catchall eq 'delete' ) {
                $delivery = 'dev-null';
                local $> = $) = 0;  ## regain privileges for a moment
                VSAP::Server::Modules::vsap::mail::check_devnull();
            }
            elsif( $mail_catchall eq 'reject' ) { $delivery = 'error:nouser User unknown' }
            elsif( $mail_catchall eq 'admin'  ) { $delivery = $admin }
            else { $delivery = $mail_catchall }
            local $> = $) = 0;  ## regain privileges for a moment
            VSAP::Server::Modules::vsap::mail::domain_catchall($domain, $delivery);
        }

        unless( $is_edit ) {
            ## setup postmaster, root, www, apache
            local $> = $) = 0;  ## regain privileges for a moment
            my $www_user = $VSAP::Server::Modules::vsap::globals::APACHE_RUN_USER;
            VSAP::Server::Modules::vsap::mail::add_entry('root@' . $domain, $domain_contact);
            VSAP::Server::Modules::vsap::mail::add_entry('postmaster@' . $domain, $domain_contact);
            VSAP::Server::Modules::vsap::mail::add_entry($www_user . '@' . $domain, $domain_contact);
            VSAP::Server::Modules::vsap::mail::add_entry($admin . '@' . $domain, $admin);
        }

        if ( ( defined $mail_catchall ) || ( !$is_edit ) ) {
            ## reload/restart mail service
            VSAP::Server::Modules::vsap::mail::restart();
        }
    }

    ##
    ## set local-host-names
    ##

    LOCAL_HOST_NAMES: {
        last LOCAL_HOST_NAMES if $is_edit;
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::localhostname( domain => $domain,
                                                          action => 'add' );
        $lhn_changed = 1;
    }

    if ( $lhn_changed ) {
        ## reload/restart mail service
        VSAP::Server::Modules::vsap::mail::restart();
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'domain:add');
    $root_node->appendTextChild('status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

# ---------------------------------------------------------------------------- 
#
# add/remove vhost ServerAlias
#
# ---------------------------------------------------------------------------- 

sub add_ServerAlias
{
    my $domain = shift;
    my $alias  = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;
             my @vhost  = @_;
             my $alias  = $args->{alias};

             my $have_alias_line = 0;
           VHOST: for my $line ( @vhost ) {
                 next unless $line =~ /\s*ServerAlias/io;
                 $have_alias_line = 1;

                 ## do we already have the alias?
                 last VHOST if $line =~ /\s\Q$alias\E\b/is;

                 ## add the new alias
                 $line =~ s/[\r\n]//g;
                 $line .= " $alias\n";
                 last VHOST;
             }

             ## add the ServerAlias line if it doesn't exist already
             unless( $have_alias_line ) {
               VHOST: for my $i ( 0 .. $#vhost ) {
                     next unless $vhost[$i] =~ /\s*ServerName/io;
                     splice @vhost, $i+1, 0, "    ServerAlias    $alias\n";
                     last VHOST;
                 }
             }

             return @vhost;
         }, $domain, alias => $alias );

}

# ---------------------------------------------------------------------------- 

sub remove_ServerAlias
{
    my $domain = shift;
    my $alias  = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;
             my @vhost  = @_;
             my $alias  = $args->{alias};

             for my $i ( 0 .. $#vhost ) {
                 next unless $vhost[$i] =~ /\s*ServerAlias/io;
                 next unless $vhost[$i] =~ /\b\Q$alias\E\b/i;

                 ## see if it's alone
                 if ( $vhost[$i] =~ /\s*ServerAlias\s+\Q$alias\E\s*$/mi ) {
                     splice @vhost, $i, 1;
                 }

                 ## just clean up that line
                 else {
                     $vhost[$i] =~ s{(\s+)\Q$alias\E\s*}{$1}i;
                     $vhost[$i] .= "\n" unless $vhost[$i] =~ /\n$/;
                 }
                 last;
             }

             return @vhost;
         }, $domain, alias => $alias );
}

# ---------------------------------------------------------------------------- 
#
# set vhost IP address
#
# ---------------------------------------------------------------------------- 

sub set_IP
{
    my $domain = shift;
    my $ip     = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain  = shift;
             my $args    = shift;
             my @vhost   = @_;
             my $ip = $args->{ip};

             for my $line (@vhost) {
                 next unless $line =~ /VirtualHost/;
                 $line =~ s/VirtualHost\s+[\d\.]+/VirtualHost $ip/;
                 last;
             }

             return @vhost;

         }, $domain, ip => $ip );
}

# ---------------------------------------------------------------------------- 
#
# set vhost IP address
#
# ---------------------------------------------------------------------------- 

sub set_Contact
{
    my $domain  = shift;
    my $contact = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain  = shift;
             my $args    = shift;
              my @vhost   = @_;
             my $contact = $args->{contact};

             for my $line ( @vhost ) {
                 next unless $line =~ /\s*ServerAdmin/io;
                 $line =~ s/^(\s*ServerAdmin\s*).*/${1}${contact}/i;
                 last;
             }

             return @vhost;
         }, $domain, contact => $contact );
}

# ---------------------------------------------------------------------------- 
#
# add/remove vhost cgi-bin
#
# ---------------------------------------------------------------------------- 

sub add_CgiBin
{
    my $domain = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;  ## not used
             my @vhost  = @_;

             ## find admin's home directory
             my $home = '';  ## defaults to server's cgi-bin
             my $user = '';
             my $cgibin_path = '';

           HOMEDIR: {
                 for my $line ( @vhost ) {
                     if ($line =~ m!^\s*User\s+(.+)\s*$!i) {
                        # matches the user directive
                        $user = $1;
                     }
                     elsif ($line =~ m!^\s*SuexecUserGroup\s+(.+)\s+(.+)\s*$!i) {
                        # matches the suexecusergroup
                        $user = $1;
                     }
                     else {
                       next;
                     }
                     system('/usr/bin/logger', '-p', 'daemon.notice', "user is '$user'");
                     chomp $user;
                     last unless getpwnam($user);  ## no root users
                     $home = (getpwnam($user))[7];
                     last;
                 }
             }

             if ($user) {
                 $cgibin_path = "$home/www/cgi-bin/";
             }
             else {
                 $cgibin_path = $VSAP::Server::Modules::vsap::globals::APACHE_CGIBIN;
             }

             ## remove any legacy "Options -ExecCGI" that previous version created
           OPTIONS: {
                 for my $i ( 0 .. $#vhost ) {
                     next unless $vhost[$i] =~ /^\s*Options\s+-ExecCGI$/;
                     splice @vhost, $i, 1;
                     last;
                 }
             }

             ## fix scriptalias line
           SCRIPTALIAS: {
                 my $found_scriptalias = 0;
                 for my $line ( @vhost ) {
                     next unless $line =~ m!^(\s*(?:Script)?Alias.*)/cgi-bin\b!io;
                     $found_scriptalias = 1;
                     $line = qq!    ScriptAlias    /cgi-bin/ "$cgibin_path"\n!;
                 }

                 ## add ScriptAlias line
                 unless( $found_scriptalias ) {
                     for my $i ( 0 .. $#vhost ) {
                         next unless $vhost[$i] =~ m!^\s*DocumentRoot\b!io;
                         $found_scriptalias = 1;
                         splice @vhost, $i+1, 0, qq!    ScriptAlias    /cgi-bin/ "$cgibin_path"\n!;
                     }
                 }

                 die "Can't find a place for ScriptAlias directive\n"
                   unless $found_scriptalias;
             }

           CGIBIN: {
                 my $found_cgibin = 0;
                 for my $line ( @vhost ) {
                     next unless $line =~ m!\s*<Directory.*/cgi-bin/?>!io;
                     $found_cgibin = 1;
                 }

                 unless( $found_cgibin ) {
                     my @directory = ("    <Directory $cgibin_path>\n",
                                      "        AllowOverride None\n",
                                      "        Options +ExecCGI\n",
                                      "        Order allow,deny\n",
                                      "        Allow from all\n",
                                      "    </Directory>\n" );

                     for my $i ( 0 .. $#vhost ) {
                         next unless $vhost[$i] =~ m!\s*ScriptAlias!io;
                         splice @vhost, $i+1, 0, @directory;
                     }
                 }
             }

             ## need to create the cgi-bin directory & chown it
             unless( -e "$cgibin_path" ) {
                 local $> = $) = 0;  ## regain privileges for a moment
                 system('mkdir', '-p', $cgibin_path);
                 chown scalar(getpwnam($user)), scalar(getgrnam($user)), "$cgibin_path";
             }

             return @vhost;
         }, $domain );
}

# ---------------------------------------------------------------------------- 

sub remove_CgiBin
{
    my $domain = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;  ## not used
             my @vhost  = @_;

             ## fix scriptalias line
           SCRIPTALIAS: {
                 my $state = 0;
                 for my $line ( @vhost ) {
                     if ( $line =~ m!^(\s*)Script(Alias\s*)"?/cgi-bin\b.*!i ) {
                         $line = "${1}${2}      /cgi-bin /dev/null\n";
                     }
                 }
             }

             ## remove cgi-bin <Directory> block
           DIRECTORY: {
                 my $state = 0;
                 my $begin = 0;
                 my $count = 0;
                 for my $i ( 0 .. $#vhost ) {
                     if ( $state ) {
                         $count++;
                         $state = 0 if ( $vhost[$i] =~ m!</Directory>!io );
                     }
                     elsif ( !$count ) {
                         if ( $vhost[$i] =~ m!\s*<Directory.*/cgi-bin/?>!io ) {
                            $state = $count = 1;
                            $begin = $i;
                         }
                     }
                 }
                 splice(@vhost, $begin, $count) if ($count);
             }

             return @vhost;
         }, $domain );
}

# ---------------------------------------------------------------------------- 
#
# add/remove vhost SSL
#
# ---------------------------------------------------------------------------- 

sub add_SSL
{
    my $domain = shift;

    my $state         = 0;
    my $servername    = '';
    local $_;

    ## CASES:
    ## 1. ssl vhost exists and ssl enabled
    ## 2. ssl vhost exists and ssl disabled
    ## 3. ssl vhost does not exist

    my $config_path = "";
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    if (-d "$sites_dir") {
        $config_path = $sites_dir . "/" . $domain . ".conf";
    }
    else {
        $config_path = $APACHE_CONF;
    }

    # is config file readable?  check first (BUG19032)
    unless (-r $config_path) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            chmod(0644, $config_path);
        }
    }

    ##
    ## scan through and try to find the ssl vhost
    ##
    open CONF, $config_path
      or return;

    while (<CONF>) {
        if ( m!\s*<VirtualHost .*:443>!io ) {
            $state      = 1;
            $servername = '';
            next;
        }

        if ( $state && m!\s*</VirtualHost>!io ) {
            $state = 0;
        }

        ## in a VirtualHost block
        if ( $state ) {
            if ( m!\s*ServerName\s+(.+)\s*!i ) {
                $servername = $1; chomp $servername;
                last if $servername eq $domain;
            }
        }
    }
    close(CONF);

    ##
    ## found our SSL domain (cases 1 and 2)
    ##
    if ( $domain eq $servername ) {
        VSAP::Server::Modules::vsap::domain::edit_vhost
          (sub {
               my $domain = shift;
               my $args   = shift;  ## not used
               my @vhost  = @_;
               return @vhost unless $vhost[0] =~ m!\s*<VirtualHost .*:443>!io;

               my $changed = 0;
               my %cfe;

               for my $line ( @vhost ) {
                   ## change SSLDisable => SSLEnable
                   if ( $line =~ m!\s*SSLDisable\b!i ) {
                       $line = "    SSLEnable\n";
                   }

                   ## change SSLEngine off => SSLEngine on
                   if ( $line =~ m!\s*SSLEngine\s+off\b!i ) {
                       $line = "    SSLEngine on\n";
                   }

                   ## if we have SSLEngine on, we're ok
                   if ( $line =~ m!\s*SSLEngine\s+on\b!i ) {
                       $changed = 1;
                       next;
                   }

                   ## if we have SSLEnable, we're ok
                   if ( $line =~ m!\s*SSLEnable\b!i ) {
                       $changed = 1;
                       next;
                   }

                   ## note cert files, and comment out any that don't exist
                   foreach my $cf (@CERT_FILES) {
                       next unless $line =~ m!^\s*$cf\s+(.+)!i;
                       my $cfn = $1;
                       $cfn =~ s/^"|"\s*$//g
                           or $cfn =~ s/[#\s].*//;
                       if (-e $cfn) {
                           $cfe{$cf} = 1;
                       }
                        else {
                           $line =~ s/SSL/#SSL/;
                       }
                   }
               }

               unless ($changed) {
                   ## couldn't find any SSL line; add one here
                   splice @vhost, 1, 0, "    SSLEngine on\n";
               }

               ## add default cert files if needed
               my $el = grep($_ eq $vhost[0] .. /SSLEngine|SSLEnable/i, @vhost);
               foreach my $cf (@CERT_FILES) {
                   splice @vhost, $el, 0, "    $cf \"$APACHE_CERT_FILES{$cf}\"\n"
                       if !$cfe{$cf} && -e $APACHE_CERT_FILES{$cf};
               }

               return @vhost;
           }, $domain);

        ## remove any disabling rewrite rules
        ## FIXME: this could be consolidated with the above loop someday
        VSAP::Server::Modules::vsap::domain::edit_vhost
            (sub {
                 my $domain = shift;
                 my $args   = shift;  ## not used
                 my @vhost  = @_;

                 return @vhost unless $vhost[0] =~ /:443>/;
                 return @vhost unless join('', @vhost) =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio;

                 my @tmp    = ();
                 my $state  = 0;
                 for my $line ( @vhost ) {
                     if ( $line =~ /^\s*\#\# start VirtualHost disabled/io ) {
                         $state = 1;
                         next;
                     }

                     elsif( $line =~ /^\s*\#\# end VirtualHost disabled/io ) {
                         $state = 0;
                         next;
                     }

                     next if $state;
                     push @tmp, $line;
                 }

                 return @tmp;
             }, $domain );

        return 1;
    }

    ##
    ## ssl vhost does not exist (case 3)
    ## make a copy of the non-ssl vhost and adjust it to be ssl-enabled
    ##

    my @vhost_nossl   = ();
    my $previous_line = '';
    my $vaddhost_line = '';
    $state            = 0;

    open CONF, $config_path
      or return;

    ## find non-ssl vhost and copy it
    seek CONF, 0, 0;
    while( <CONF> ) {
        if ( m!\s*<VirtualHost .*:80>!i ) {
            $state      = 1;
            $servername = '';
            @vhost_nossl = ();
            if ( $previous_line =~ m!\#\# vaddhost! ) {
                $vaddhost_line = $previous_line;
                $vaddhost_line =~ s!:80!:443!;
            }
            push @vhost_nossl, $_;
            next;
        }

        if ( $state && m!\s*</VirtualHost>!i ) {
            $state = 0;
            next unless $servername;
            push @vhost_nossl, $_;
            last;
        }

        ## in a VirtualHost block
        if ( $state ) {
            push @vhost_nossl, $_;
            if ( m!\s*ServerName\s+(.+)\s*! ) {
                $servername = $1; chomp $servername;
                $state = 0 unless $servername eq $domain;
            }
        }

        $previous_line = $_;
        next;
    }
    close CONF;

    ## @vhost_nossl will always have something, but only if $servername eq
    ## $domain will it be complete
    return unless $servername eq $domain;

    ##
    ## change port, ssldisable -> sslenable
    ##
    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;  ## not used
             my @vhost  = @_;

             my $changed = 0;
             my %cfe;

             for my $line ( @vhost ) {
                 if ( $line =~ m!\s*<VirtualHost .*:80>!io ) {
                     $line =~ s!:80>!:443>!;
                     next;
                 }

                 if ( $line =~ m!\s*SSLDisable! ) {
                     $line = "    SSLEnable\n";
                     $changed = 1;
                     next;
                 }

                 if ( $line =~ m!\s*SSLEngine\s+off!i ) {
                     $line = "    SSLEngine on\n";
                     $changed = 1;
                     next;
                 }

                 foreach my $cf (@CERT_FILES) {
                       next unless $line =~ m!^\s*$cf\s+(.+)!i;
                       my $cfn = $1;
                       $cfn =~ s/^"|"\s*$//g
                           or $cfn =~ s/[#\s].*//;
                       if (-e $cfn) {
                           $cfe{$cf} = 1;
                       }
                       else {
                           $line =~ s/SSL/#SSL/;
                       }
                   }
             }

             unless($changed) {
                 ## couldn't find any SSL line; add one here
                 splice @vhost, 1, 0, "    SSLEngine on\n";
             }

             ## add default cert files if needed
             my $el = grep($_ eq $vhost[0] .. /SSLEngine|SSLEnable/i, @vhost);
             foreach my $cf (@CERT_FILES) {
                 splice @vhost, $el, 0, "    $cf \"$APACHE_CERT_FILES{$cf}\"\n"
                     if !$cfe{$cf} && -e $APACHE_CERT_FILES{$cf};
             }

             return (@vhost_nossl, "\n", ($vaddhost_line ? $vaddhost_line : () ), @vhost);
         }, $domain );
}

# ---------------------------------------------------------------------------- 

sub remove_SSL
{
    my $domain = shift;
    my $vsap = shift;

    # enable the mod_rewrite module
    my $rewrite_module = "modules/mod_rewrite.so";
    VSAP::Server::Modules::vsap::apache::loadmodule( name   => 'rewrite_module',
                                                     module => $rewrite_module,
                                                     action => 'enable' );

    # disable the SSL version of the vhost definition
  DISABLE_VHOST: {
    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;  ## not used
             my @vhost  = @_;

             return @vhost unless $vhost[0] =~ /:443>/;
             return @vhost if join('', @vhost) =~ qr(^\s*RewriteRule\s+\^/\s+\-\s+\[F,L\])mio;

             ## make sure we are SSLDisable'd
             for my $line ( @vhost ) {
                 if ($line =~ /^\s*SSLEnable/i) {
                     $line = "    SSLDisable\n";
                     last;
                 } elsif ($line =~ /^\s*SSLEngine\s+on/i) {
                     $line = "    SSLEngine off\n";
                     last;
                 }
             }

             ## if you change the start/end markers, be sure you
             ## fix them in 'enable' and in the domain:list
             ## handler which groks that string to determine
             ## whether a domain is enabled or not
             splice @vhost, 1, 0, (qq!    ## start VirtualHost disabled\n!,
                                   qq!    ## No user-servicable parts inside.\n!,
                                   qq!    ## use CPX to re-enable, and you will have peace\n!,
                                   qq!    ## If the seal is broken, the warranty is voided\n!,
                                   qq!    RewriteEngine on\n!,
                                   qq!    RewriteRule   ^/ - [F,L]\n!,
                                   qq!    ## end VirtualHost disabled\n!,);

             return @vhost;
         }, $domain );
    }
}

# ---------------------------------------------------------------------------- 
#
# add/remove vhost logging
#
# ---------------------------------------------------------------------------- 

sub add_Weblogs
{
    my $domain = shift;
    my $admin  = shift;

    my $log_dir = $VSAP::Server::Modules::vsap::globals::APACHE_LOGS;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;
             my @vhost  = @_;
             my $mkdir  = 0;  ## need to create the logs dir

             for my $line ( @vhost ) {
                 next unless $line =~ qr(\s*(Transfer|Custom|Error)Log\s+(.+))io;
                 my $type = $1;
                 my $log  = $2;

                 ## disabled
                 if ( $log eq '/dev/null' ) {
                     if ( lc($type) eq 'error' ) {
                         $line =~ s{/dev/null}{$log_dir/$admin/$domain-error_log};
                         $mkdir = 1;
                     }

                     elsif( $type =~ qr((?:transfer|custom))io ) {
                         $line = "    CustomLog      $log_dir/$admin/$domain-access_log combined\n";
                         $mkdir = 1;
                     }
                 }
             }

             ## need to create the log directory & chown it
             if ( $mkdir && ! -e "$log_dir/$admin" ) {
                 local $> = $) = 0;  ## regain privileges for a moment
                 system('mkdir', '-p', "$log_dir/$admin");
                 chown 0, scalar(getgrnam($admin)), "$log_dir/$admin";
             }

             return @vhost;
         }, $domain );
}

# ---------------------------------------------------------------------------- 

sub remove_Weblogs
{
    my $domain = shift;

    VSAP::Server::Modules::vsap::domain::edit_vhost
        (sub {
             my $domain = shift;
             my $args   = shift;
             my @vhost  = @_;

             my %found = ();
             for my $line (@vhost) {
                 next unless $line =~ qr(\s*(Transfer|Custom|Error)Log\s+(.+))io;
                 my $type = $1;
                 my $log  = $2;
                 $found{lc($type)}++;

                 ## enabled
                 if ($log ne '/dev/null') {
                     $line =~ s{Custom}{Transfer}io;
                     $line =~ s{(Log\s+).+}{$1/dev/null};
                 }
             }

             my $last = $#vhost;
             $last-- while $last && $vhost[$last] !~ m!^\s*</VirtualHost>!io;

             ## add a disabling entry for system logging
             unless( $found{transfer} || $found{custom} ) {
                 splice @vhost, $last, 0, "    TransferLog    /dev/null\n" if $last;
             }

             unless( $found{error} ) {
                 splice @vhost, $last, 0, "    ErrorLog       /dev/null\n" if $last;
             }

             ## FIXME: disable rotation here

             return @vhost;
         }, $domain );
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::delete;

use Fcntl 'LOCK_EX';

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my @domains = ( $xmlobj->child('domain')
                    ? map { lc($_->value) } $xmlobj->children('domain')
                    : () );

    ## must be server admin to delete a domain
    unless( $vsap->{server_admin} ) {
        $vsap->error($_ERR{DOMAIN_PERMISSION} => 'Permission denied');
        return;
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling domain:delete");

    ## make backups as required
    VSAP::Server::Modules::vsap::backup::backup_system_file($APACHE_CONF);
    VSAP::Server::Modules::vsap::backup::backup_system_file($ALIASES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($GENERICS);
    VSAP::Server::Modules::vsap::backup::backup_system_file($LOCALHOSTNAMES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($VIRTUSERTABLE);
    for my $freq qw(daily weekly monthly) {
        VSAP::Server::Modules::vsap::backup::backup_system_file("$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf");
    }

    ## iterate over multiple domains
    my $co = new VSAP::Server::Modules::vsap::config(username => $vsap->{username});
    for my $domain ( @domains ) {
        next unless $domain;

        ## can't delete a domain w/ sub users
        my $users = $co->users( domain => $domain );    ## get list of users for this domain
        my $das   = $co->domains( domain => $domain );  ## get list of domain admins for this domain (1)
        ## delete the admin user
        if (defined($das->{$domain})) {
            delete $users->{$das->{$domain}} if (defined($users->{$das->{$domain}}));
        }
        if (keys %$users) {
            $vsap->error($_ERR{DOMAIN_HAS_USERS} => "You may not delete a domain with subusers");
            return;
        }

      REMOVE_VHOST: {
            ## got REWT?
            local $> = $) = 0;  ## regain privileges for a moment

            VSAP::Server::Modules::vsap::logger::log_message("removing domain '$domain' from server");

          REMOVE_DOMAIN_FROM_SAVELOGS: {
              FREQ: for my $freq qw(daily weekly monthly) {  ## remove from all conf files
                    next unless -f "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                    my $conf = "$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf";
                    my $sc = new Config::Savelogs($conf)
                      or do {
                          warn "Could not open '$conf': $!\n";
                          next FREQ;
                      };
                    $sc->remove_from_group( match => { ApacheHost => $domain }, apachehost => $domain );
                    VSAP::Server::Modules::vsap::logger::log_message("removing domain '$domain' from $freq savelogs config");

                    if ( ! exists $sc->data->{groups} ||
                         ! scalar(@{$sc->data->{groups}}) ) {
                        unlink $conf;

                        ## remove crontab entry too
                        my $ct = new Config::Crontab( -file => '/etc/crontab', -system => 1 ); $ct->read;
                        $ct->remove( $ct->select( -type       => 'event',
                                                  -user       => 'root',
                                                  -special    => '@' . $freq,
                                                  -command_re => qr(savelogs\s+--config=$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf) ) );
                        $ct->write;
                    }
                    else {
                        $sc->write if $sc->is_dirty;
                    }
                }
            }

            ## remove email addresses in virtmaps and aliases
            VSAP::Server::Modules::vsap::mail::delete_domain($domain);
            VSAP::Server::Modules::vsap::mail::localhostname( domain => $domain, action => 'delete' );

            ## remove domain aliases from local-host-names
            my %vhosts = VSAP::Server::Modules::vsap::domain::get_vhost($domain);
            my %other_aliases = ();
            while( $vhosts{nossl} =~ /^\s*ServerAlias\s+(.+)$/mig ) {
                my @other_aliases = split( ' ', $1 );
                @other_aliases{@other_aliases} = (1) x @other_aliases;
            }
            delete $other_aliases{"www.$domain"};
            for my $alias ( keys %other_aliases ) {
                VSAP::Server::Modules::vsap::mail::localhostname( domain => $alias, action => 'delete' );
            }

            ## remove entry in cpx.conf
            $co->remove_domain($domain);

            ## remove domain_admin property if last domain
            my $domains = $co->domains($das->{$domain});
            unless (scalar keys %$domains) {
                $co->domain_admin( admin => $das->{$domain}, set => 0 );

                ## change domain name to hostname and change e-mail to user@primary_hostname
                ## ( perhaps this step is somewhat moot as the domain admin may likely be )
                ## (   subsequently removed by the server admin after the domain removal. )
                my $server_hostname = $co->primary_domain();
                $co->init( username => $das->{$domain} );   ## init as domain admin
                $co->domain( $server_hostname );
                $co->init (username => $vsap->{username});  ## revert to authenticated user
              REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    my $dest = $das->{$domain} . '@'. $server_hostname;
                    VSAP::Server::Modules::vsap::mail::add_entry($dest, $das->{$domain});
                    VSAP::Server::Modules::vsap::mail::genericstable( user => $das->{$domain}, dest => $dest );
                    ## zero-out the domain admin's group quota
                    my $dev = Quota::getqcarg('/home');
                    Quota::setqlim($dev, (getgrnam($das->{$domain}))[2], 0, 0, 0, 0, 0, 1);
                    Quota::sync($dev);
                }
            }
        }
    }

  REWT: {
        ## got root?
        local $> = $) = 0;  ## regain privileges for a moment

        $co->commit;

        my $delete_count = 0;
        my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
        if (-d "$sites_dir") {
            for my $domain ( @domains ) {
                next unless $domain;
                my $domain_config = $domain . ".conf";
                my $config_path = $sites_dir . "/" . $domain_config;
                if (-e "$config_path") {
                    # remove from sites-enabled (if necessary)
                    system('/usr/sbin/a2dissite', $domain_config);
                    # remove from sites-aailable
                    unlink($config_path);
                    $delete_count++;
                }
            }
        }

        unless ($delete_count == ($#domains+1)) {
            open CONF, "+< $APACHE_CONF"
              or do {
                  $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Could not open $APACHE_CONF: $!");
                  return;
              };
            flock CONF, LOCK_EX
              or do {
                  close CONF;
                  $vsap->error($_ERR{DOMAIN_CONFIG_FILE} => "Could not lock $APACHE_CONF: $!");
                  return;
              };
            seek CONF, 0, 0;  ## rewind

            local $_;
            my $state = 0;
            my @conf  = ();
            my @vhost = ();
            my $found = 0;
            my $skip_space = 0;

            while (<CONF>) {
                if ($skip_space == 1) { ## we just deleted a virt host; skip its trailing newlines
                    next if (/^\s+$/s);
                    $skip_space = 0;
                }

                if ( $state == 2 ) {  ## means we're done
                    push @conf, $_;
                    next;
                }

                if ( m!^\s*<VirtualHost!io ) {
                    $state = 1;
                    push @vhost, $_;
                    next;
                }

                if ( m!^\s*</VirtualHost>!io ) {
                    $state = 0;
                    push @vhost, $_;

                    ## is this our vhost?
                    if ($found) {
                        @vhost = ();  ## wipe it out
                        $skip_space = 1;
                    }

                    ## add this vhost to the pile
                    push @conf, @vhost;

                    ## reset state
                    $state = 0;
                    @vhost = ();
                    $found = 0;

                    next;
                }

                ## in a virtualhost block
                if ($state) {
                    if (/^\s*ServerName\s+(\S*)\s*$/i) {
                        my $domain = $1;
                        if (grep(/^$domain$/, @domains)) {
                            $found = 1;
                            VSAP::Server::Modules::vsap::logger::log_message("removing domain '$domain' from httpd.conf");
                        }
                    }
                    push @vhost, $_;
                    next;
                }

                if (/^\#\# vaddhost:\s*\((.*)\)/i ) {
                    ## remove the vaddhost comment?
                    my $domain = $1;
                    next if (grep(/^$domain$/, @domains));
                }
                push @conf, $_;
            }

            ## write out new config file
            seek CONF, 0, 0;
            print CONF @conf;
            truncate CONF, tell CONF;
            close CONF;

            # make sure we have read perms (BUG19032)
            chmod(0644, $APACHE_CONF);

        }
    }

    ## restart apache (gracefully)
    $vsap->need_apache_restart();

    ## reload/restart mail service
    VSAP::Server::Modules::vsap::mail::restart();

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'domain:delete');
    $root_node->appendTextChild('status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::disable;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::logger;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : do { $vsap->error($_ERR{DOMAIN_ADD_MISSING_DOMAIN} => "Missing domain");
                          return } );

    ## check perms
    unless( $vsap->{server_admin} ) {
        $vsap->error($_ERR{DOMAIN_PERMISSION} => 'Permission denied');
        return;
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling domain:disable for domain '$domain'");

    ## make backups as required
    VSAP::Server::Modules::vsap::backup::backup_system_file($APACHE_CONF);
    VSAP::Server::Modules::vsap::backup::backup_system_file($ALIASES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($GENERICS);
    VSAP::Server::Modules::vsap::backup::backup_system_file($LOCALHOSTNAMES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($VIRTUSERTABLE);
    for my $freq qw(daily weekly monthly) {
        VSAP::Server::Modules::vsap::backup::backup_system_file("$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf");
    }

    ## disable the domain
    VSAP::Server::Modules::vsap::logger::log_message("disabling domain '$domain'");
    unless ( VSAP::Server::Modules::vsap::domain::_disable($vsap, $domain) ) {
        ## only possible failure: could not open passwd file
        $vsap->error($_ERR{DOMAIN_ETC_PASSWD} => "Could not open $SHADOW: $!");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'domain:disable');
    $root_node->appendTextChild('status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::enable;

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::logger;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : do { $vsap->error($_ERR{DOMAIN_ADD_MISSING_DOMAIN} => "Missing domain");
                          return } );

    ## check perms
    unless( $vsap->{server_admin} ) {
        $vsap->error($_ERR{DOMAIN_PERMISSION} => 'Permission denied');
        return;
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling domain:enable for domain '$domain'");

    ## make backups as required
    VSAP::Server::Modules::vsap::backup::backup_system_file($APACHE_CONF);
    VSAP::Server::Modules::vsap::backup::backup_system_file($ALIASES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($GENERICS);
    VSAP::Server::Modules::vsap::backup::backup_system_file($LOCALHOSTNAMES);
    VSAP::Server::Modules::vsap::backup::backup_system_file($VIRTUSERTABLE);
    for my $freq qw(daily weekly monthly) {
        VSAP::Server::Modules::vsap::backup::backup_system_file("$SAVELOGS_CONFIG_PATH/savelogs-cpx.$freq.conf");
    }

    # enable the domain
    VSAP::Server::Modules::vsap::logger::log_message("enabling domain '$domain'");
    unless (VSAP::Server::Modules::vsap::domain::_enable($vsap, $domain)) {
        ## only possible failure: could not open passwd file
        $vsap->error($_ERR{DOMAIN_ETC_PASSWD} => "Could not open $SHADOW: $!");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'domain:enable');
    $root_node->appendTextChild('status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::domain::exists;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : do { $vsap->error($_ERR{DOMAIN_ADD_MISSING_DOMAIN} => "Missing domain");
                          return } );

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'domain:exists');

    ## is httpd.conf world readable?  check first (BUG19032)
    unless (-r $APACHE_CONF) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            chmod(0644, $APACHE_CONF);
        }
    }

    ## check if domain exists in sites-available
    my $exists = 0;
    my $sites_dir = $VSAP::Server::Modules::vsap::globals::APACHE_SERVER_ROOT . "/sites-available";
    my $domain_config = $sites_dir . "/" . $domain . ".conf";
    $exists = (-e "$domain_config");

    ## check if domain exists in main apache config
    unless ($exists) {
        $exists = ! system('egrep', '-qi', "^[[:space:]]*ServerName[[:space:]]+$domain\$", $APACHE_CONF);
    }

    $root_node->appendTextChild( 'exists' => $exists );

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::domain - CPX domain management

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::domain;
  blah blah blah

=head1 DESCRIPTION

=head2 domain:list

Standard:

Server admin may request all domains:

  <vsap type="domain:list"/>

Domain admins making the same call:

  <vsap type="domain:list"/>

will receive only their own domains.

Server admins may also request the domains for a particular domain
admin:

  <vsap type="domain:list">
    <admin>jeff</admin>
  </vsap>

B<domain:list> returns:

  <vsap type="domain:list">
    <domain>
      <name>foo.com</name>
      <admin>jeff</admin>
      <disabled/>
      <users>
        <usage>5</usage>
        <limit>10</limit>
      </users>
      <aliases>
        <usage>10</usage>
        <limit>unlimited</limit>
      </aliases>
    </domain>
    <domain>
      ...
    </domain>
  </vsap>

Optional:

Server and Domain admins may request to include diskspace node:

  <vsap type="domain:list">
    <diskspace />
  </vsap>

B<domain:list> returns:

  <vsap type="domain:list">
    <domain>
      <name>foo.com</name>
      <admin>jeff</admin>
      <disabled/>
      <users>
        <usage>5</usage>
        <limit>10</limit>
      </users>
      <aliases>
        <usage>10</usage>
        <limit>unlimited</limit>
      </aliases>
      <diskspace>
        <usage>70</usage>
        <limit>500</limit>
        <units>MB</units>
      </diskspace>
    </domain>
    <domain>
      ...
    </domain>
  </vsap>

=head2 domain:exists

Request to determine whether domain exists.

  <vsap type="domain:exists">
    <domain>foo.com</domain>
  </vsap>

B<domain:exists> returns:

  If the user (domain) already exists:

  <vsap type="domain:exists">
    <status>1</status>
  </vsap>

  If the domain does not exist:

  <vsap type="domain:exists">
    <status>0</status>
  </vsap>

=head1 SEE ALSO

vsap(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
