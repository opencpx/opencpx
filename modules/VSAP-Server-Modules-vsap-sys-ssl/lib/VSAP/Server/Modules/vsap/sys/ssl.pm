package VSAP::Server::Modules::vsap::sys::ssl;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::domain;
use VSAP::Server::Modules::vsap::globals;

########################################################################

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( install_cert );

########################################################################

our $VERSION = '0.12';

our %_ERR = ( 
              ERR_PERMISSION_DENIED =>  100,
              ERR_DOMAIN_MISSING =>     101,
              ERR_OPENSSL_FAILED =>     102,
              ERR_CSR_FILE =>           103,
              ERR_CERT_FILE =>          104,
              ERR_DOCROOT_MISSING =>    105,
              ERR_VALIDATION_URL =>     106,
              ERR_KEY_FILE =>           107,
              ERR_CACERT_FILE =>        108,
              ERR_CERT_MISMATCH =>      109,
              ERR_RESTART_SERVICE =>    110,
              ERR_UNINSTALL_INUSE =>    111,
            );

our $APACHE_CONF     = $VSAP::Server::Modules::vsap::globals::APACHE_CONF;
our $APACHE_SSL_CONF = $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CONF;

our $VSFTPD_CONF     = '/etc/vsftpd/vsftpd.conf';

our $SSL_CERT_DIR    = '/etc/pki/tls/certs';
our $SSL_KEY_DIR     = '/etc/pki/tls/private';

our $OPENSSL         = '/usr/bin/openssl';

##############################################################################

our %SSL_APPS = (
        apache =>  { 
            cert   => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_FILE,
            cacert => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_CHAIN,
            key    => $VSAP::Server::Modules::vsap::globals::APACHE_SSL_CERT_KEY
          },
        dovecot => {
            cert   => '/etc/dovecot/certs/dovecot.pem',
            key    => '/etc/dovecot/private/dovecot.pem',
            combineca => 1
          },
        postfix => {
            cert   => '/etc/postfix/certs/postfix.pem',
            key    => '/etc/postfix/private/postfix.pem',
            needself => 1
          },
        vsftpd =>  {
            cert   => '/etc/vsftpd/certs/vsftpd.pem',
            cacert => '/etc/vsftpd/certs/vsftpd-chain.pem',
            key    => '/etc/vsftpd/private/vsftpd.pem'
          }
      );

##############################################################################

sub _run_openssl
{
    my $pid = open my $pipe, "-|";
    return (undef, $!)
        unless defined $pid;

    my($out, $e);
    if ($pid) {
        local $_;
        $out = join(' ', <$pipe>);
        $out =~ s/\n//g;
        close $pipe;
        $e = $out || $? if $?;
    }
    else {
        close STDERR;
        open STDERR, '>& STDOUT';
        local $> = $) = 0;  ## regain privileges for a moment
        exec {$OPENSSL} 'openssl', @_;
        exit 1;
    }

    return ($out, $e);
}

##############################################################################

sub _delete_ssl_files
{
    my $domain = shift;
    my $backtime = shift;
    my $delete_key = shift;
    my $delete_csr = shift;
    my $delete_cert = shift;
    my $delete_cacert = shift;
    my $delete_self = shift;

    if (!$backtime) {
        my @lt = localtime;
        my $backtime = sprintf("%04d%02d%02d-%02d%02d",
                               $lt[5] +1900, $lt[4] + 1, @lt[3, 2, 1]);
    }

    my $keyfile = "$SSL_KEY_DIR/$domain.pem";
    my $csrfile = "$SSL_KEY_DIR/$domain.csr";
    my $certfile = "$SSL_CERT_DIR/$domain.pem";
    my $cacertfile = "$SSL_CERT_DIR/$domain-chain.pem";
    my $wcacertfile = "$SSL_CERT_DIR/$domain-chained.pem";
    my $selfkeyfile = "$SSL_KEY_DIR/$domain-self.pem";
    my $selfcertfile = "$SSL_CERT_DIR/$domain-self.pem";

    local $> = $) = 0;  ## regain privileges for a moment

    if ($delete_csr && -e $csrfile) {
        my($e, $csr, $docroot, $url) =
            VSAP::Server::Modules::vsap::sys::ssl::_read_csr($domain);
        unlink "$docroot/$url"
            if $docroot && $url && -e "$docroot/$url";
        rename $csrfile, "$csrfile.$backtime.bak"
            if -e $csrfile;
    }

    rename $certfile, "$certfile.$backtime.bak"
        if $delete_cert && -e $certfile;
    rename $cacertfile, "$cacertfile.$backtime.bak"
        if $delete_cacert && -e $cacertfile;
    rename $wcacertfile, "$wcacertfile.$backtime.bak"
        if $delete_cacert && -e $wcacertfile;
    rename $keyfile, "$keyfile.$backtime.bak"
        if $delete_key && !-e $csrfile && !-e $certfile && -e $keyfile;
    rename $selfcertfile, "$selfcertfile.$backtime.bak"
        if $delete_self && -e $selfcertfile;
    rename $selfkeyfile, "$selfkeyfile.$backtime.bak"
        if $delete_self && -e $selfkeyfile;
}

##############################################################################

sub _restore_ssl_files
{
    my $domain = shift;
    my $backtime = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    my $keyfile = "$SSL_KEY_DIR/$domain.pem";
    my $csrfile = "$SSL_KEY_DIR/$domain.csr";
    my $certfile = "$SSL_CERT_DIR/$domain.pem";
    my $cacertfile = "$SSL_CERT_DIR/$domain-chain.pem";
    my $wcacertfile = "$SSL_CERT_DIR/$domain-chained.pem";
    my $selfkeyfile = "$SSL_KEY_DIR/$domain-self.pem";
    my $selfcertfile = "$SSL_CERT_DIR/$domain-self.pem";

    rename "$csrfile.$backtime.bak", $csrfile
        if -e "$csrfile.$backtime.bak";
    rename "$certfile.$backtime.bak", $certfile
        if -e "$certfile.$backtime.bak";
    rename "$cacertfile.$backtime.bak", $cacertfile
        if -e "$cacertfile.$backtime.bak";
    rename "$wcacertfile.$backtime.bak", $wcacertfile
        if -e "$wcacertfile.$backtime.bak";
    rename "$keyfile.$backtime.bak", $keyfile
        if -e "$keyfile.$backtime.bak";
    rename "$selfcertfile.$backtime.bak", $selfcertfile
        if -e "$selfcertfile.$backtime.bak";
    rename "$selfkeyfile.$backtime.bak", $selfkeyfile
        if -e "$selfkeyfile.$backtime.bak";
}

##############################################################################

sub _read_csr
{
    my $domain = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    # Read the CSR file
    my $csrfile = "$SSL_KEY_DIR/$domain.csr";
    my $csr;
    open my $csrfh, '<', $csrfile
        or return ([$_ERR{ERR_CSR_FILE},
                    "$csrfile: $!"]);
    $csr = join('', <$csrfh>);
    $csr =~ s/\n$//;
    close $csrfh;
    $csr
        or return ([$_ERR{ERR_CSR_FILE},
                    "$csrfile empty"]);

    # Generate the validation URL
    my $docroot = VSAP::Server::Modules::vsap::domain::get_docroot($domain)
        || VSAP::Server::Modules::vsap::domain::get_server_docroot()
        or return ([$_ERR{ERR_DOCROOT_MISSING},
                    "Could not determine DocumentRoot"],
                   $csr);
    $csr =~ /(.{10})\n[^\n]*$/;
    my $url = $1;
    $url =~ s/[^a-zA-Z0-9]/_/g;
    $url = "$1.html";

    return (undef, $csr, $docroot, $url);
}

##############################################################################

sub _replace
{
    my $filename = shift;
    my $search = shift;
    my $replace = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    open my $fi, '<', $filename
        or return $!;
    my $tmp = "$filename.$$.tmp";
    open my $fo, '>', $tmp
        or return $!;
    local $_;
    while (<$fi>) {
        print $fo $_
            if !s/$search/$replace/g || m/./;
    }
    close $fi;
    unless (close $fo) {
        my $e = $!;
        unlink $tmp;
        return $e;
    }
    my($mode, $uid, $gid) = (stat $filename)[2, 4, 5];
    chmod $mode & 0777, $tmp;
    chown $uid, $gid, $tmp;
    unless (rename $tmp, $filename) {
        my $e = $!;
        unlink $tmp;
        return $e;
    }
    return 0;
}

##############################################################################

sub install_cert
{
    my ($vsap, $domain, $apply, $cert, $cacert, $key, $selfsign, $norestart) = @_;

    # In the absence of specific instructions (e.g. from hostname:set),
    # apply this cert to all apps
    $apply = {map(($_, 1), keys %SSL_APPS)}
        if !ref $apply;
    # Some apps always want a self-signed cert (we think).
    $selfsign ||= grep($SSL_APPS{$_}{needself}, keys %$apply);

    local $> = $) = 0;  ## regain privileges for a moment

    my $keyfile = "$SSL_KEY_DIR/$domain.pem";
    my $certfile = "$SSL_CERT_DIR/$domain.pem";
    my $cacertfile = "$SSL_CERT_DIR/$domain-chain.pem";
    my $wcacertfile = "$SSL_CERT_DIR/$domain-chained.pem";
    my $selfkeyfile = "$SSL_KEY_DIR/$domain-self.pem";
    my $selfcertfile = "$SSL_CERT_DIR/$domain-self.pem";

    my @lt = localtime;
    my $backtime = sprintf("%04d%02d%02d-%02d%02d",
                           $lt[5] +1900, $lt[4] + 1, @lt[3, 2, 1]);

    # Check for a valid combination of key and certs:
    # A key may be passed in alone, whether or not a cert exists.
    # A cert must go with a key (either pre-existing or passed in).
    # A CA cert must go with a cert (either pre-existing or passed in).
    if ($cert && !$key && !-f $keyfile) {
        return [$_ERR{ERR_KEY_FILE} =>
                'missing private key'];
    }
    if ($cacert && !$cert && !-f $certfile) {
        return [$_ERR{ERR_CERT_FILE} =>
                'missing certificate'];
    }

    # Write cert files that were passed in
    my $ocert;
    if ($cacert && !$cert) {
        open my $cfh, "$certfile";
        local $/;
        $ocert = <$cfh>;
        close $cfh;
        return [$_ERR{ERR_CERT_FILE} =>
                'cannot read certificate']
            unless $ocert;
    }
    VSAP::Server::Modules::vsap::sys::ssl::_delete_ssl_files(
        $domain, $backtime, $key, 0, $cert, $cacert, $selfsign);
    grep $_ && !/\n$/ && ($_ .= "\n"), $cert, $key, $cacert;
    foreach my $cc ([$cert, $certfile], [$key, $keyfile, 1], [$cacert, $cacertfile],
                    ($cacert
                     ? ([($cert || $ocert) . $cacert, $wcacertfile])
                     : ())) {
        my($c, $cf, $ck) = @$cc;
        next unless $c;
        my $cfh;
        unless (open($cfh, '>', $cf)
                && print($cfh $c)
                && close($cfh)) {
            my $e = [$ck ? $_ERR{ERR_KEY_FILE} : $_ERR{ERR_CERT_FILE},
                     "$cf: $!"];
            VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
                $domain, $backtime);
            return $e;
        }
        chmod 0400, $cf
            if $ck;
    }

    # Check cert file contents
    my($cm, $km);
    if (($cert || $key) && -f $certfile) {
        my $e;
        ($cm, $e) = VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
            qw(x509 -noout -modulus -in), $certfile);
        if ($e) {
            VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
                $domain, $backtime);
            return [$_ERR{ERR_CERT_FILE} =>
                    'certificate format error'];
        }
    }
    if (($cert || $key) && -f $keyfile) {
        my $e;
        ($km, $e) = VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
            qw(rsa -noout -modulus -in), $keyfile);
        ($km, $e) = VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
            qw(dsa -noout -modulus -in), $keyfile)
            if $e;
        if ($e) {
            VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
                $domain, $backtime);
            return [$_ERR{ERR_KEY_FILE} =>
                    'key format error'];
        }
    }
    if ($cacert) {
        if (VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
                qw(x509 -noout -modulus -in), $cacertfile)) {
            VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
                $domain, $backtime);
            return [$_ERR{ERR_CACERT_FILE} =>
                    'intermediate certificate format error']
        }
    }
    if ($cm && $km && $cm ne $km) {
        VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
            $domain, $backtime);
        return [$_ERR{ERR_CERT_MISMATCH} =>
                'certificate does not match key'];
    }

    # If this was just setting the key, don't change any config files now
    # but wait for the associated cert (regardless of what $apply says).
    return if !$cert && !$cacert && !$selfsign;

    # Create a self-signed cert if needed
    if ($selfsign) {
        my $ke = -e $selfkeyfile;
        my $e = VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
            qw(req -batch -new -x509 -days 3650 -subj),
            '/CN=' . substr($domain, 0, 64), '-out', $selfcertfile,
            ($ke
             ? ('-key', $selfkeyfile)
             : (qw(-newkey rsa:2048 -nodes -keyout), $selfkeyfile)));
        if ($e) {
            VSAP::Server::Modules::vsap::sys::ssl::_restore_ssl_files(
                $domain, $backtime);
            return [$_ERR{ERR_OPENSSL_FAILED} =>
                    "openssl error: $e"];
        }
        chmod 0400, $selfkeyfile
            unless $ke;
    }

    $cert ||= $ocert;
    my %to_restart;

    # Update the Apache config for virtual hosts.
    if ($$apply{apache}) {
        my $invh1;
        open my $ac, "$APACHE_CONF";
        local $_;
        while (<$ac>) {
            $invh1 = 0 if /^\s*<VirtualHost/i;
            $invh1 = 1 if /^\s*ServerName\s+\Q$domain\E/i;
            last if /^\s*<\/VirtualHost/i;
        }
        close $ac;
        VSAP::Server::Modules::vsap::domain::add::add_SSL($domain)
            unless $invh1;
        my $found;
        VSAP::Server::Modules::vsap::domain::edit_vhost(
            sub {
                my($domain, $args, @vhost) = @_;

                return @vhost unless $vhost[0] =~ /\s*<VirtualHost .*:443>/i;
                @vhost = grep !/^\s*SSLCertificateChainFile\s/, @vhost
                    if !$cacert;
                my $el = grep($_ eq $vhost[0] .. /SSLEngine|SSLEnable/i, @vhost);
                grep(s/^\s*SSLCertificateChainFile\s+\K.*/"$cacertfile"/i, @vhost)
                    or splice(@vhost, $el, 0,
                              "    SSLCertificateChainFile \"$cacertfile\"\n")
                    if $cacert;
                my $acertfile = $cert ? $certfile : $selfcertfile;
                grep(s/^\s*SSLCertificateFile\s+\K.*/"$acertfile"/i, @vhost)
                    or splice(@vhost, $el, 0,
                              "    SSLCertificateFile \"$acertfile\"\n")
                    if $cert || $selfsign;
                my $akeyfile = $cert ? $keyfile : $selfkeyfile;
                grep(s/^\s*SSLCertificateKeyFile\s+\K.*/"$akeyfile"/i, @vhost)
                    or splice(@vhost, $el, 0,
                              "    SSLCertificateKeyFile \"$akeyfile\"\n")
                    if $cert || $selfsign;
                $found = 1;
                return @vhost;
            },
            $domain)
            unless $invh1;
        $to_restart{apache} = delete $$apply{apache}
            if $found;
    }

    # Update the config files for CA cert.
    if ($$apply{apache}) {
        open my $ac, '<', $APACHE_SSL_CONF;
        my $foundca = grep /^\s*SSLCACertificateFile\s/, <$ac>;
        close $ac;
        if ($cacert && !$foundca) {
            &_replace($APACHE_SSL_CONF,
                      '#\s*SSLCACertificateFile\s.*',
                      "SSLCACertificateFile $SSL_APPS{apache}{cacert}");
        } elsif (!$cacert && $foundca) {
            &_replace($APACHE_SSL_CONF,
                      '^\s*SSLCACertificateFile\s',
                      "    #SSLCACertificateFile ");
        }
    }
    if ($$apply{vsftpd}) {
        open my $vc, '<', $VSFTPD_CONF;
        my $foundca = grep /^\s*ca_certs_file\s*=/, <$vc>;
        close $vc;
        if ($cacert && !$foundca) {
            open $vc, '>>', $VSFTPD_CONF;
            print $vc "ca_certs_file=$SSL_APPS{vsftpd}{cacert}\n";
            close $vc;
        } elsif (!$cacert && $foundca) {
            &_replace($VSFTPD_CONF,
                      '^\s*ca_certs_file\s*=.*',
                      '');
        }
    }

    # Link to the key/cert files from various application-specific filenames.
    foreach my $a (grep $$apply{$_}, sort keys %$apply) {
        if ($cert || $selfsign) {
            unlink $SSL_APPS{$a}{key}
                if -l $SSL_APPS{$a}{key};
            symlink $cert && !$SSL_APPS{$a}{needself}
                ? $keyfile
                : $selfkeyfile,
                $SSL_APPS{$a}{key}
                if !-e $SSL_APPS{$a}{key};
            unlink $SSL_APPS{$a}{cert}
                if -l $SSL_APPS{$a}{cert};
            symlink $cacert && $SSL_APPS{$a}{combineca}
                ? $wcacertfile
                : $cert && !$SSL_APPS{$a}{needself}
                  ? $certfile
                  : $selfcertfile,
                $SSL_APPS{$a}{cert}
                if !-e $SSL_APPS{$a}{cert};
        }
        if ($cacert && $SSL_APPS{$a}{cacert}) {
            unlink $SSL_APPS{$a}{cacert}
                if -l $SSL_APPS{$a}{cacert};
            symlink $cacertfile, $SSL_APPS{$a}{cacert}
                if !-e $SSL_APPS{$a}{cacert};
        }
        $to_restart{$a} = 1;
    }

    # Restart services that need to recognize the new cert.
    require VSAP::Server::Modules::vsap::sys::account;
    foreach my $s ($norestart ? () : reverse sort keys %to_restart) {
        my $e = VSAP::Server::Modules::vsap::sys::account::restart_service($vsap, $s);
        return [$_ERR{ERR_RESTART_SERVICE} => $e]
            if $e;
    }

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssl::csr_create;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }

    my $subject = $xmlobj->child('subject');
    $subject = $subject ? $subject->value : '';
    $subject .= "/CN=$domain"
        if $subject !~ /\/CN=/;

    VSAP::Server::Modules::vsap::sys::ssl::_delete_ssl_files(
        $domain, undef, 0, 1, 0, 0, 0);

    # Create the key and CSR
    my $keyfile = "$SSL_KEY_DIR/$domain.pem";
    my $csrfile = "$SSL_KEY_DIR/$domain.csr";
    my $e = VSAP::Server::Modules::vsap::sys::ssl::_run_openssl(
        qw(req -batch -new -subj), $subject, '-out', $csrfile,
        (-e $keyfile
         ? ('-key', $keyfile)
         : (qw(-newkey rsa:2048 -nodes -keyout), $keyfile)));
    if ($e) {
        $vsap->error($_ERR{ERR_OPENSSL_FAILED} =>
                     "openssl error: $e");
        return;
    }

    # Read the CSR file
    my($csr, $docroot, $url);
    ($e, $csr, $docroot, $url) =
        VSAP::Server::Modules::vsap::sys::ssl::_read_csr($domain);
    if ($e) {
        $vsap->error(@$e);
        return;
    }

    # Create the validation URL file
  ROOT_URL: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $urlfh;
        unless (open($urlfh, '>', "$docroot/$url") && print($urlfh $csr) &&
                close($urlfh)) {
            $vsap->error($_ERR{ERR_VALIDATION_URL},
                         "$docroot/url: $!");
            return;
        }
    }
    $url = "http://$domain/$url";

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:ssl:csr_create');
    $root_node->appendTextChild('csr' => $csr);
    $root_node->appendTextChild('url' => $url);
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssl::csr_delete;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }

    VSAP::Server::Modules::vsap::sys::ssl::_delete_ssl_files(
        $domain, undef, 1, 1, 0, 0, 0);

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:ssl:csr_delete');
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssl::cert_install;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }
    my $cert = $xmlobj->child('cert');
    $cert &&= $cert->value;
    my $selfsign = $xmlobj->child('self');
    $selfsign &&= $selfsign->value;
    my $cacert = $xmlobj->child('cacert');
    $cacert &&= $cacert->value;
    my $key = $xmlobj->child('key');
    $key &&= $key->value;

    my %apply;
    foreach my $a (keys %SSL_APPS) {
        my $aa = $xmlobj->child("applyto_$a");
        $apply{$a} = 1
            if $aa && $aa->value;
    }
    # In the absence of specific instructions, apply this cert
    # either to all apps (if domain is hostname) or just to Apache (otherwise).
    require VSAP::Server::Modules::vsap::sys::hostname;
    my $hostname = VSAP::Server::Modules::vsap::sys::hostname::get_hostname();
    %apply = map(($_, 1),
        $domain eq $hostname ? (keys %SSL_APPS) : qw(apache))
        if !%apply;

    my $e = VSAP::Server::Modules::vsap::sys::ssl::install_cert(
        $vsap, $domain, \%apply, $cert, $cacert, $key, $selfsign);
    if ($e) {
        $vsap->error(@$e);
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:ssl:cert_install');
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssl::cert_uninstall;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }

    # Ensure that the cert isn't currently depended upon
    foreach my $a (sort keys %SSL_APPS) {
        if (readlink($SSL_APPS{$a}{cert}) =~ /$SSL_CERT_DIR\/$domain(?:-\w+)\.pem/ ||
            readlink($SSL_APPS{$a}{key}) =~ /$SSL_KEY_DIR\/$domain(?:-\w+)\.pem/) {
            $vsap->error($_ERR{ERR_UNINSTALL_INUSE},
                         "Certificate for $domain is currently in use by $a");
            return;
        }
    }

    # See that the cert isn't used in an Apache VirtualHost block
    my %vhost = VSAP::Server::Modules::vsap::domain::get_vhost($domain);
    if ($vhost{ssl} =~ /^\s*SSLCertificate(?:Chain|Key)?File/mi) {
        VSAP::Server::Modules::vsap::domain::add::remove_SSL($domain, $vsap);
        VSAP::Server::Modules::vsap::domain::edit_vhost(
            sub {
                my($domain, $args, @vhost) = @_;
                return grep !/^\s*SSLCertificate(?:Chain|Key)?File/, @vhost;
            },
            $domain);
        require VSAP::Server::Modules::vsap::sys::account;
        VSAP::Server::Modules::vsap::sys::account::restart_service($vsap, 'apache');
    }

    # Remove all cert-related files for this domain
    VSAP::Server::Modules::vsap::sys::ssl::_delete_ssl_files(
        $domain, undef, 1, 1, 1, 1, 1);
    
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:ssl:cert_uninstall');
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::ssl - VSAP module to for SSL utilities 

=head1 SYNOPSIS

use VSAP::Server::Modules::vsap::sys::ssl;

=head2 csr_create

call:
 <vsap type="sys:ssl:csr_create">
  <domain>foo.com</domain>
  <subject>/O=Foo Inc/CN=foo.com...</subject>
 </vsap>

response
 <vsap type="sys:ssl:csr_create">
  <csr>-----BEGIN CERTIFICATE REQUEST-----
WHOLE_LOTTA_BASE64_ENCODED_CSR_BYTES
-----END CERTIFICATE REQUEST-----</csr>
  <url>http://foo.com/vhCZ4DkuiV.html</url>
  <status>ok</status>
 </vsap>

=head2 csr_delete

call:
 <vsap type="sys:ssl:csr_delete">
  <domain>foo.com</domain>
 </vsap>

response
 <vsap type="sys:ssl:csr_delete">
  <status>ok</status>
 </vsap>

=head2 cert_install

call:
 <vsap type="sys:ssl:cert_install">
  <domain>foo.com</domain>
  <cert>-----BEGIN CERTIFICATE-----
WHOLE_LOTTA_BASE64_ENCODED_CERT_BYTES
-----END CERTIFICATE-----</cert>
  <key>-----BEGIN PRIVATE KEY-----
WHOLE_LOTTA_BASE64_ENCODED_KEY_BYTES
-----END PRIVATE KEY-----</key>
  <self>yes</self>
  <cacert>-----BEGIN CERTIFICATE-----
WHOLE_LOTTA_BASE64_ENCODED_CERT_BYTES
-----END CERTIFICATE-----</cacert>
  <applyto_apache>yes</applyto_apache>
  <applyto_dovecot>yes</applyto_dovecot>
  <applyto_postfix>yes</applyto_postfix>
  <applyto_vsftpd>yes</applyto_vsftpd>
 </vsap>

response
 <vsap type="sys:ssl:cert_install">
  <status>ok</status>
 </vsap>

=head2 cert_uninstall

call:
 <vsap type="sys:ssl:cert_uninstall">
  <domain>foo.com</domain>
 </vsap>

response
 <vsap type="sys:ssl:cert_uninstall">
  <status>ok</status>
 </vsap>

=head1 DESCRIPTION

The VSAP ssl module is used to manage SSL certificates.

CSRs (certificate signing requests) are created with ssl:csr_create, and when
no longer needed may be removed with ssl:csr_remove.

The optional "subject" is a string to pass as openssl's "-subj", and if not
supplied will default to "/CN=<domain>".  csr_create will pass back the
created CSR and the location of a validation URL (which also contains the
CSR).


Actual certificates are installed with ssl:cert_install, and removed with
ssl_cert_uninstall.

The certificate may be passed in, or the <self> parameter may be passed
(non-empty) to indicate that a self-signed cert should be generated.  An
intermediate certificate may also be passed in <cacert>.  If a private key
wasn't already generated via the ssl:csr_create call, it should be passed in
along with the cert; this isn't necessary for self-signed certs, as a key
will be generated.

If the domain is the same as the hostname, the certificate will be installed
for all services by default.  Otherwise, only Apache will use the certificate,
and then only in the VirtualHost section corresponding to the domain (assuming
such a section exists).

The certificate can also be explicitly applied only to certain services, by
including the various <applyto_*> parameters.

=head1 AUTHOR

Jamie Gritton

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
