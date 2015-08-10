package VSAP::Server::Modules::vsap::sys::hostname;

use 5.008004;
use strict;
use warnings;
use POSIX;

#use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::sys::account;
use VSAP::Server::Modules::vsap::sys::ssl;

our $VERSION = '0.01';
our %_ERR = ( ERR_NOTAUTHORIZED =>          100,
              ERR_SET_HOSTNAME_FAILED =>    101,
              ERR_WRITE_SYSCONFIG_FAILED => 102,
              ERR_INSTALL_CERT =>           103,
              ERR_RESTART_SERVICE =>        104,
              ERR_UNKNOWN =>                200,
);

our $APACHE_CONF =    '/etc/httpd/conf/httpd.conf';
our $CPX_CONF =       '/usr/local/etc/cpx.conf';
our $HOSTS =          '/etc/hosts';
our $SYSCONFIG =      '/etc/sysconfig/network';
our $SYSCONFIG_ETH0 = '/etc/sysconfig/network-scripts/ifcfg-eth0';

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
        s/$search/$replace/;
        print $fo $_;
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

sub get_hostname
{
   my $host;

   $host = `/bin/hostname -f 2>/dev/null` || (POSIX::uname())[1];
   $host =~ tr/\0\r\n//d;
   $host;
}

##############################################################################

sub set_hostname
{
    my $vsap = shift;
    my $hostname = shift;

    my $oldhostname = &get_hostname();

    if ($hostname ne $oldhostname) {
        local $> = $) = 0;  ## regain privileges for a moment

        # set the current hostname
        if (system("/bin/hostname $hostname") != 0) {
            my $exit = ($? >> 8);
            $vsap->error($_ERR{ERR_SET_HOSTNAME_FAILED},
                         "/bin/hostname failed (exitcode $exit)");
            return;
        };

        &_replace($HOSTS, "\\s\\K(?:HOSTNAME|$oldhostname)", $hostname);

        # set the hostname on startup
        my $e = &_replace($SYSCONFIG, "=(?:HOSTNAME|$oldhostname)",
                          "=$hostname");
        if ($e) {
            $vsap->error($_ERR{ERR_WRITE_SYSCONFIG_FAILED} =>
                         "Error writing $SYSCONFIG: $e");
            return;
        }

        $e = &_replace($SYSCONFIG_ETH0, "=\"(?:HOSTNAME|$oldhostname)\"",
                       "=\"$hostname\"");
        if ($e) {
            $vsap->error($_ERR{ERR_WRITE_SYSCONFIG_FAILED} =>
                         "Error writing $SYSCONFIG_ETH0: $e");
            return;
        }

        # Replace the main ServerName in httpd.conf, but not any of
        # the virtual host ServerNames.  It's not the end of the world
        # if this fails, so don't bother with errors here.
        &_replace($APACHE_CONF, "^\\s*\\KServerName (?:HOSTNAME|$oldhostname)",
                  "ServerName $hostname");

        # Generate a default self-signed certificate for this hostname,
        # and apply it to the services that need it.
        $e = &VSAP::Server::Modules::vsap::sys::ssl::install_cert(
            $vsap, $hostname, undef, undef, undef, undef, 1);
        if ($e) {
            $vsap->error($_ERR{ERR_INSTALL_CERT} => $$e[1]);
            return;
        }


        # Reset Postfix files that contain the hostname
        system "/usr/bin/newaliases";
        grep system('/usr/sbin/postmap', "/etc/postfix/$_"),
            qw(virtusertable genericstable domains);

        # Restart services that care about the hostname changing
        # (aside from what install_cert does).
        foreach my $service (qw(rsyslog mysqld)) {
            $e = &VSAP::Server::Modules::vsap::sys::account::restart_service($vsap, $service);
            if ($e) {
                $vsap->error($_ERR{ERR_RESTART_SERVICE} => $e);
                return;
            }
        }

        # update cpx config
        my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
        $co->{is_dirty} = 1;
        if ($oldhostname eq 'HOSTNAME') {
            # Clean up the bogus placeholder hostname(s)
            $co->remove_domain('hostname');
            $co->remove_domain('HOSTNAME');
        }
        $co->commit();
        my $oldlc = lc $oldhostname;
        my $search = $oldhostname eq $oldlc
            ? $oldhostname
            : "(?:$oldhostname|$oldlc)";
        &_replace($CPX_CONF, "<domain>$search</domain>", "<domain>\L$hostname</domain>");
    }

    return 1;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::hostname::get;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $hostname = &VSAP::Server::Modules::vsap::sys::hostname::get_hostname();

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:hostname:get');
    $root_node->appendTextChild('hostname' => $hostname);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::hostname::set;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # check for authorization
    unless ( $vsap->{server_admin} ) {
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "permission denied");
        return;
    }

    my $hostname = $xmlobj->child('hostname')
                      ? $xmlobj->child('hostname')->value : '';

    # if hostname is not specified, then get one
    if ($hostname eq '') {
        $hostname = &VSAP::Server::Modules::vsap::sys::hostname::get_hostname();
    }

    &VSAP::Server::Modules::vsap::sys::hostname::set_hostname($vsap, $hostname)
        or return;

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'sys:hostname:set');
    $root_node->appendTextChild('hostname' => $hostname);
    $root_node->appendTextChild('status' => "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__
=head1 NAME

VSAP::Server::Modules::vsap::sys::hostname - VSAP module to get/set hostname

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::hostname;

=head1 DESCRIPTION

The VSAP hostname module can be used to get the current hostname
of the system or, alternatively, a server admin can set the current
hostname of the system.


Get the hostname by calling:

    <vsap type='sys:hostname:get'/>


Set the hostname by calling:

    <vsap type='sys:hostname:set'>
      <hostname>HOSTNAME</hostname>
    </vsap>

If the hostname is left blank, then the module will attempt to
determine the hostname by various methods.


=head1 AUTHOR

Rus Berrett

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
