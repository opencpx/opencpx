package VSAP::Server::Modules::vsap::sys::account;

use 5.008004;
use strict;
use warnings;

use POSIX qw(setsid);
use XML::LibXML;

use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::sys::hostname;

##############################################################################

our $VERSION = '0.12';

our $DEFAULTS = '/var/vsap/account.default';
our $HOSTS = '/etc/hosts';
our $INITTAB = '/etc/inittab';
our $LOCAL_HOST_NAMES = '/etc/postfix/domains';
our $MYSQL_CONF = '/etc/my.cnf';
our $PGSQL_HBA = '/var/lib/pgsql/data/pg_hba.conf';
our $POSTFIX_MAIN_CF = '/etc/postfix/main.cf';
our $POSTFIX_MASTER_CF = '/etc/postfix/master.cf';

##############################################################################

our %_ERR = (
              ERR_PERMISSION_DENIED =>                  100,
              ERR_READ_CONF_FAILED =>                   101,
              ERR_WRITE_CONF_FAILED =>                  102,
              ERR_HOSTNAME_MISSING =>                   110,
              ERR_IP_MISSING =>                         111,
              ERR_DOMAIN_MISSING =>                     112,
              ERR_WRITE_POSTFIX_CF_FAILED =>            120,
              ERR_SWITCH_ADMIN_PASSWORD_BLANK =>        200,
              ERR_SWITCH_NEW_PASSWORD_REQ =>            201,
              ERR_SWITCH_NEW_PASSWORD_FORMAT =>         202,
              ERR_SWITCH_CONFIRM_PASSWORD_MISMATCH =>   203,
              ERR_SWITCH_ADMIN_PASSWORD_INVALID =>      204,
            );

##############################################################################

sub _read_account_conf
{
    my $vsap = shift;

    my $conf;
    if (-e $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF) {
        eval {
            local $> = $) = 0;  ## regain privileges for a moment
            open my $acfh, "$VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF";
            binmode $acfh;
            local $/;
            my $acdata = <$acfh>;
            close $acfh;
            $conf = XML::LibXML->load_xml(string => $acdata, no_blanks => 1)
                or die;
        };
        if ($@) {
            $vsap->error($_ERR{ERR_READ_CONF_FAILED} =>
                         "Error reading $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF: $@")
                if $vsap;
            return;
        }
    }
    else {
        $conf = XML::LibXML::Document->new('1.0', 'UTF-8');
        $conf->createInternalSubset('cpx_account_config', undef,
                                    'cpx_account_config.dtd');
        $conf->setDocumentElement($conf->createElement('account'));
    }
    return $conf;
}

##############################################################################

sub _write_account_conf
{
    my $vsap = shift;
    my $conf = shift;

    VSAP::Server::Modules::vsap::backup::backup_system_file($VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF);
    VSAP::Server::Modules::vsap::logger::log_message("sys:account: writing $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF");
    {
        local $> = $) = 0;  ## regain privileges for a moment

        my $tmp = $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF . "-" . $$ . ".tmp";
        my $acfh;
        if (open $acfh, '>', $tmp) {
            binmode $acfh;
            $conf->toFH($acfh, 1);
        }
        if (!$acfh || !close($acfh)) {
            $vsap->error($_ERR{ERR_WRITE_CONF_FAILED} =>
                         "Error writing $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF: $!");
            unlink $tmp;
            return;
        }
        chmod 0644, $tmp;  ## make root writable, world readable
        chown 0, 10, $tmp;
        rename $tmp, $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF if -s $tmp;
        unlink $tmp if -e $tmp;
    }
    return 1;
}

##############################################################################

sub _validate_password
{
    my $password = shift;
    my $username = shift;

    return 'cannot be less than 8 characters'
        if length($password) < 8;
    return 'must contain a capital letter'
        if $password !~ /[A-Z]/;
    return 'must contain a lowercase letter'
        if $password !~ /[a-z]/;
    return 'must contain a number or symbol'
        if $password !~ /[0-9~!@#\$%^&*()_+=-]/;
    return "contains illegal character '$1'"
        if $password =~ /([^A-Za-z0-9~!@#\$%^&*()_+=-])/;
    return 'cannot contain the username'
        if $username && $password =~ /$username/i;
    return;
}

##############################################################################

sub _set_password
{
    my $password = shift;
    my $username = shift;

    local $> = $) = 0;  ## regain privileges for a moment
    my @saltChars = ('a'..'z','A'..'Z',1..9,'.','/');
    system('usermod', '-p',
           crypt($password, join('', '$1$', map $saltChars[rand @saltChars], 0 .. 7)),
           $username);
}

##############################################################################

sub _sql_password
{
    my $password = shift;
    my $hostname = shift;
    $password =~ s/(['"\\%_])/\\$1/g;
    $password =~ s/\0/\\0/g; $password =~ s/\x08/\\b/g; $password =~ s/\n/\\n/g;
    $password =~ s/\r/\\r/g; $password =~ s/\t/\\t/g; $password =~ s/\x1a/\\Z/g;
    $hostname =~ s/(['"\\%_])/\\$1/g;
    $hostname =~ s/\0/\\0/g; $hostname =~ s/\x08/\\b/g; $hostname =~ s/\n/\\n/g;
    $hostname =~ s/\r/\\r/g; $hostname =~ s/\t/\\t/g; $hostname =~ s/\x1a/\\Z/g;

    local $> = $) = 0;  ## regain privileges for a moment

    # Set the MySQL password by temporarily including a command file in my.cnf
    my $ifn = "/tmp/my.init.$$";
    my $cfbak = "$MYSQL_CONF.bak.$$";
    open my $ifh, ">$ifn";
    print $ifh "SET PASSWORD FOR 'root'\@'localhost' = PASSWORD('$password');\n";
    print $ifh "SET PASSWORD FOR 'root'\@'$hostname' = PASSWORD('$password');\n"
        if $hostname;
    print $ifh "DROP USER ''\@'localhost';\n";
    print $ifh "DROP USER ''\@'$hostname';\n"
        if $hostname;
    close $ifh;

    rename $MYSQL_CONF, $cfbak;

    open my $cfh, "<$cfbak";
    my @mycnf = <$cfh>;
    close $cfh;

    my @newcnf;
    foreach my $line (@mycnf) {
        push @newcnf, $line;
        push @newcnf, "init_file=$ifn\n"
            if $line =~ /\[mysqld\]/;
    }

    open CNF, ">$MYSQL_CONF";
    print CNF @newcnf;
    close CNF;

    if (system(qw(/sbin/service mysqld status)) == 0) {
        system qw(/sbin/service mysqld restart);
        sleep 5;
    } else {
        system qw(/sbin/service mysqld start);
        sleep 5;
        system qw(/sbin/service mysqld stop);
    }

    unlink $ifn;
    rename $cfbak, $MYSQL_CONF;

    # Set the pgsql password by temporarily suspending authentication
    # and running a command file
    my $pfn = "/tmp/pgsql.$$";
    open my $pfh, ">$pfn";
    print $pfh "ALTER USER postgres WITH PASSWORD '$password';\n";
    close $pfh;
    open my $phh, ">$PGSQL_HBA.$$";
    print $phh
        "local all all trust\n",
        "host all all 127.0.0.1/32 trust\n",
        "host all all ::1/128 trust\n";
    close $phh;

    my $status = system(qw(/sbin/service postgresql status));
    system "/sbin/service postgresql stop"
        if $status == 0;
    rename $PGSQL_HBA, "$PGSQL_HBA.bak.$$";
    rename "$PGSQL_HBA.$$", $PGSQL_HBA;
    system "/sbin/service postgresql start";
    sleep 2;
    system(qw(su -l postgres -c), "/usr/bin/psql postgres -f $pfn");
    system "/sbin/service postgresql stop";
    unlink $PGSQL_HBA;
    rename "$PGSQL_HBA.bak.$$", $PGSQL_HBA;
    system "/sbin/service postgresql start"
        if $status == 0;

    unlink $pfn;
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

sub _daemon
{
    my($vsap, $errcode, $errverb, $command, $function, @args) = @_;

    my $pid = fork;
    if (!defined $pid) {
        $vsap->error($_ERR{$errcode} =>
                     "Cannot fork to $errverb")
            if $vsap && $errcode;
        return;
    }
    return 1 if $pid;

    local $> = $) = 0;  ## regain privileges
    foreach my $fd (0 .. 1023) {
        open my $fh, "<&=$fd";
        close $fd;
    }
    setsid;
    if ($function) {
        &$function(@args);
    } else {
        system $command;
    }
    exit 0;
}

##############################################################################

sub get_account_param
{
    my $name = shift;

    my $conf = $_[0] ||= &_read_account_conf();
    return unless $conf;

    # account.conf shouldn't have more than one node with a pariticular name.
    my $node = ($conf->documentElement->getChildrenByTagName($name))[0];
    return unless $node;

    # Don't mess with the identities of sub-nodes; just look for any text.
    # This was done for ip_address, so anything other complex parameters
    # should behave in a similar way.
    my $value = '';
    foreach my $ochild ($node->nonBlankChildNodes()) {
        $value .= ' ' . ($ochild->nodeName eq '#text'
                         ? $ochild->nodeValue
                         : $ochild->textContent);
    }
    $value =~ s/^ //;
    return $value;
}

##############################################################################

sub restart_service
{
    my $vsap = shift;
    my $service = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    # Restart the service only if it's already running
    $service = 'httpd' if $service eq 'apache';
    return unless system("/sbin/service $service status") == 0;

    # Apache is special, since we may be biting the CPX that feeds us
    if ($service eq 'httpd') {
        $vsap->need_apache_restart();
        return;
    }

    # XXX The logical way to do this is with a pipe, but I don't have the foo
    #     to reliably make perl not hang in that situation.
    my $temp = "/var/vsap/service.$$";
    if (system("/sbin/service $service restart >$temp 2>&1") == 0) {
        unlink $temp;
        return;
    }
    open my $tf, '<', $temp;
    my $out = join('', <$tf>);
    $out =~ s/\n/ /g;
    $out =~ s/ *$//;
    close $tf;
    unlink $temp;
    return $out
        ? "$service: $out"
        : "service $service restart: exit code $?";
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::get;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Read in the current config
    my $conf = &VSAP::Server::Modules::vsap::sys::account::_read_account_conf($vsap)
        or return;
    my $cde = $conf->documentElement;

    # If parameters were passed, pass only those ones back
    if (my @xchildren = $xmlobj->children) {
        my $tde = $dom->createElement('account');
        foreach my $xchild (@xchildren) {
            if (my @cchildren = $cde->getChildrenByTagName($xchild->name)) {
                $tde->appendChild($cchildren[0]->cloneNode(1));
            }
            else {
                $tde->appendChild($dom->createElement($xchild->name));
            }
        }
        $cde = $tde;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:account:get');
    $root_node->appendChild($cde);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::set;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Read in the current config
    my $conf = &VSAP::Server::Modules::vsap::sys::account::_read_account_conf($vsap)
        or return;
    my $cde = $conf->documentElement;

    # Read in any default parameters
    if (-f $DEFAULTS) {
        my $env = $xmlobj->child('environment');
        $env = $env ? $env->value : '';
        local $> = $) = 0;  ## regain privileges for a moment
        my @def;
        my $dfh;
        if (open $dfh, $DEFAULTS) {
            @def = <$dfh>;
            chomp @def;
            close $dfh;
        }
        # Look for a section tagged with the environment.
        if (grep /^\s*\[$env\]/, @def) {
            shift @def while $def[0] !~ /^\s*\[$env\]/;
            shift @def;
        }
        # If that fails, fall back to the first section.
        else {
            shift @def while @def && $def[0] !~ /^\s*\[|\S\s/;
            shift @def if @def && $def[0] =~ /^\s*\[/;
        }
        while (grep /^\s*\[/, @def) {
            pop @def while $def[-1] !~ /^\s*\[/;
            pop @def;
        }
        my $xdom = $xmlobj->{_DOM};
        foreach my $def (@def) {
            next unless $def =~ /^(\S+)\s+([^\n]+)/;
            my($n, $v) = ($1, $2);
            next if $xmlobj->child($n);
            $xdom->appendTextChild($n, $v);
        }
    }

    # Check for required parameters, either passed now or already
    # in the config file.

    # hostname
    my $hostname = $xmlobj->child('hostname');
    $hostname &&= $hostname->value;
    if (!$hostname && !$cde->getChildrenByTagName('hostname')) {
        $vsap->error($_ERR{ERR_HOSTNAME_MISSING},
                     "Missing required parameter: hostname");
        return;
    }

    # ip_address
    my @old_ip_address = $cde->getChildrenByTagName('ip_address');
    my $ip_address = $xmlobj->child('ip_address');
    if ($ip_address) {
        if (my @ips = $ip_address->children) {
            $ip_address = join(' ', map $_->value, @ips);
        }
        else {
            $ip_address = $ip_address->value;
        }
    }
    if (defined $ip_address ? $ip_address !~ /\S/ : !@old_ip_address) {
        $vsap->error($_ERR{ERR_IP_MISSING},
                     "Missing required parameter: ip_address");
        return;
    }

    # Handle special parameters...

    # ip_address
    my $old_ip_address = '';
    if (@old_ip_address) {
        foreach my $ochild ($old_ip_address[0]->nonBlankChildNodes()) {
            $old_ip_address .= ' ' . ($ochild->nodeName eq '#text'
                                    ? $ochild->nodeValue
                                    : $ochild->textContent);
        }
        $old_ip_address =~ s/^ //;
    }
    if ($ip_address && $ip_address ne $old_ip_address) {
        my $search = 'IP_ADDRESS' . ($old_ip_address && "|$old_ip_address");
        $search =~ s/[.]/[.]/g;
        my $e = &VSAP::Server::Modules::vsap::sys::account::_replace($POSTFIX_MASTER_CF, $search, $ip_address);
        if ($e) {
            $vsap->error($_ERR{ERR_WRITE_POSTFIX_CF_FAILED} =>
                         "Error writing $POSTFIX_MASTER_CF: $e");
            return;
        }
        $e = &VSAP::Server::Modules::vsap::sys::account::_replace($POSTFIX_MAIN_CF, $search, $ip_address);
        if ($e) {
            $vsap->error($_ERR{ERR_WRITE_POSTFIX_CF_FAILED} =>
                         "Error writing $POSTFIX_MAIN_CF: $e");
            return;
        }
        &VSAP::Server::Modules::vsap::sys::account::_replace($HOSTS, $search, $ip_address);
        &VSAP::Server::Modules::vsap::sys::account::restart_service($vsap, 'postfix');
    }


    # hostname
    if ($hostname) {
        &VSAP::Server::Modules::vsap::sys::hostname::set_hostname($vsap, $hostname)
            or return;

        # FIXME: add the actual hostname ("primary domain name") to the localhostnames
        # due to the current postfix configuration of the virtusertable?
    }

    # admin_password
    my $admin_password = $xmlobj->child('admin_password');
    $admin_password &&= $admin_password->value;
    if ($admin_password) {
        &VSAP::Server::Modules::vsap::sys::account::_set_password($admin_password, 'admin');
        &VSAP::Server::Modules::vsap::sys::account::_sql_password($admin_password, $hostname);
        # Set up default mailman mail list. Don't fail on this...not important enough. Just "fire and forget".
        VSAP::Server::Modules::vsap::app::mailman::config_mailman($vsap, $admin_password);
    }

    # Replace all passed parameters (special or not) in the configuration file
    # and write it back out.
    foreach my $xchild ($xmlobj->{_DOM}->childNodes()) {
        next if $xchild->nodeName =~ /_password$/;
        foreach my $xgrandchild ($xchild->childNodes) {
            $xchild->removeChild($xgrandchild)
                if $xgrandchild->nodeName eq '#text'
                    && $xgrandchild->nodeValue =~ /^\s+$/;
        }
        my @cchildren = $cde->getChildrenByTagName($xchild->nodeName);
        $cde->removeChild(pop @cchildren)
            while @cchildren > 1;
        if (!$xchild->hasChildNodes()) {
            $cde->removeChild($cchildren[0])
                if @cchildren;
        }
        elsif (@cchildren) {
            $cchildren[0]->replaceNode($xchild->cloneNode(1));
        }
        else {
            $cde->appendChild($xchild->cloneNode(1));
        }
    }
    &VSAP::Server::Modules::vsap::sys::account::_write_account_conf($vsap, $conf)
        or return;

    # Pass back what was changed
    my $tde = $dom->createElement('account');
    foreach my $xchild ($xmlobj->children) {
        if (my @cchildren = $cde->getChildrenByTagName($xchild->name)) {
            $tde->appendChild($cchildren[0]->cloneNode(1));
        }
        else {
            $tde->appendChild($dom->createElement($xchild->name));
        }
    }

    # Remove the defaults (if they still exist) now that they have been set
    {
        local $> = $) = 0;  ## regain privileges for a moment
        unlink $DEFAULTS;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:account:set');
    $root_node->appendChild($tde);
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::disable;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Set the run level to 2, both now and on reboot
  ROOT_INIT: {
        local $> = $) = 0;  ## regain privileges for a moment
        system("telinit 2");
        &VSAP::Server::Modules::vsap::sys::account::_replace(
            $INITTAB, "^id:[^:]:initdefault:", "id:2:initdefault:");
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:account:disable');
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::enable;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Set the run level to 3, both now and on reboot
  ROOT_INIT: {
        local $> = $) = 0;  ## regain privileges for a moment
        system("telinit 3");
        &VSAP::Server::Modules::vsap::sys::account::_replace(
            $INITTAB, "^id:[^:]:initdefault:", "id:3:initdefault:");
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:account:enable');
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::addcw;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Add the specified domain
    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }
  ROOT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $found;
        open my $lhn, '<', $LOCAL_HOST_NAMES;
        local $_;
        while (<$lhn>) {
            s/[\r\n]+//;
            $found = 1
                if $_ eq $domain;
        }
        close $lhn;
        if (!$found) {
            my $lhn;
            unless (open($lhn, '>>', $LOCAL_HOST_NAMES)
                    && print($lhn "$domain    $domain\n")
                    && close($lhn)) {
                $vsap->error($_ERR{ERR_WRITE_POSTFIX_CF_FAILED} =>
                             "Error writing $LOCAL_HOST_NAMES: $!");
                return;
            }
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:account:addcw');
    $root_node->appendTextChild('domain' => $domain);
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::account::rmcw;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # Check for authorization
    if (!$vsap->{server_admin}) {
        $vsap->error($_ERR{ERR_PERMISSION_DENIED}, "Permission denied");
        return;
    }

    # Remove the specified domain
    my $domain = $xmlobj->child('domain');
    $domain &&= $domain->value;
    if (!defined $domain || $domain eq '') {
        $vsap->error($_ERR{ERR_DOMAIN_MISSING},
                     "Missing required parameter: domain");
        return;
    }
    my $e = &VSAP::Server::Modules::vsap::sys::account::_replace(
            $LOCAL_HOST_NAMES, "^$domain", '');
    if ($e) {
        $vsap->error($_ERR{ERR_WRITE_POSTFIX_CF_FAILED} =>
                     "Error writing $LOCAL_HOST_NAMES: $e");
        return;
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:account:rmcw');
    $root_node->appendTextChild('domain' => $domain);
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::account - VSAP module to configure system on the account level

=head1 SYNOPSIS

use VSAP::Server::Modules::vsap::sys::account;

=head2 sys:account:get

call:
 <vsap type="sys:account:get"/>

response:
 <vsap type="sys:account:get">
  <account>
   <hostname>foo.com</hostname>
   <ip_address>
    <ip>1.2.3.4</ip>
    <ip>5.6.7.8</ip>
   </ip_address>
  </account>
 </vsap>

=head2 sys:account:set

call:
 <vsap type="sys:account:set">
  <hostname>foo.com</hostname>
  <ip_address>
   <ip>1.2.3.4</ip>
   <ip>5.6.7.8</ip>
  </ip_address>
  <some_random_parameter>FOO</some_random_parameter>
  <some_parameter_i_want_to_delete/>
 </vsap>

response:
 <vsap type="sys:account:set">
  <account>
   <hostname>foo.com</hostname>
   <ip_address>
    <ip>1.2.3.4</ip>
    <ip>5.6.7.8</ip>
   </ip_address>
   <some_random_parameter>FOO</some_random_parameter>
  </account>
  <status>ok</status>
 </vsap>

=head2 sys:account:enable

call:
 <vsap type="sys:account:enable"/>

response:
 <vsap type="sys:account:enable">
  <status>ok</status>
 </vsap>

=head2 sys:account:disable

call:
 <vsap type="sys:account:disable"/>

response:
 <vsap type="sys:account:disable">
  <status>ok</status>
 </vsap>

=head2 sys:account:addcw

call:
 <vsap type="sys:account:addcw">
  <domain>foo.com</domain>
 </vsap>

response:
 <vsap type="sys:account:addcw">
  <domain>foo.com</domain>
  <status>ok</status>
 </vsap>

=head2 sys:account:rmcw

call:
 <vsap type="sys:account:rmcw">
  <domain>foo.com</domain>
 </vsap>

response:
 <vsap type="sys:account:rmcw">
  <domain>foo.com</domain>
  <status>ok</status>
 </vsap>

=head1 DESCRIPTION

This module is used in lieu of vutil to configure system settings on the
account level.  Account configuration is stored in /var/vsap/account.conf,
in XML format.

Some account parameters are "special", and can alter actual
system configuration.  These are:

    hostname:       The system hostname, same as set via sys:hostname, except
                    that setting it here will also write it to account.conf.
    ip_address:     The IP address of the account. A single address is of the form
                      <ip_address>1.2.3.4</ip_address>,
                    and multiple addresses use multiple <ip> nodes, e.g.
                      <ip_address><ip>1.2.3.4</ip><ip>5.6.7.8</ip></ip_address>
    admin_password: The plaintext password of "admin", the CPX admin account.
                    For security reasons, this is not stored in account.conf.
    environment:    Control the set of default account parameters.

Some of these special parameters are required.  They must be supplied the first
time the account is set, and cannot be cleared later.  The required parameters
are:

    hostname
    ip_address

When sys:account:set is first called, some default parameters may be set,
along with those that have been passed in.  The file /var/vsap/account.default
contains a list of parameters that will be set in the account.  If they have
the same name as any passed parameters, the explicitly passed parameters take
precedence.  The "environment" parameter can be passed to specify a section
of this file to be used.


Get the account info with sys:account:get.  By default, this will return all
of the account's parameters.  You may also get only certain parameters by
a call of the form:

    <vsap type='sys:account:get'>
     <hostname/>
     <account_ip/>
    </vsap>

Set account info with sys:account:set.  Aside from the reserved parameters
listed above, any parameter may be passed along to sys:account:set;
though they will not do anything on the system, they'll be stored for later
retrieval.


The system run level determines whether an account is enabled.  End-user
services such as httpd and postfix run in level 3 but not in level 2.
vsapd needs to run in level 2, or a disabled account won't be able to
start up again!

The sys:account:enable and sys:account:disable calls set the run level,
both currently via telinit and at startup by changing /etc/inittab.
A new system starts disabled, and sys:account:enable should be called
after the account is fully set up.


The first calls to sys:account:set and sys:account:enable serve the purpose
of inital account setup, the analog of an account "create" call.


Add and remove a domain that Postfix will take mail for by calling
sys:account:addcw or sys:account:rmcw.  Unlike the parameters passed to
sys:account:set, the domain name will not be included in the account
configuration file.  These calls also are unrelated to the CPX-level domain
calls, which have to do with Apache and users.

=head1 AUTHOR

Jamie Gritton

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
