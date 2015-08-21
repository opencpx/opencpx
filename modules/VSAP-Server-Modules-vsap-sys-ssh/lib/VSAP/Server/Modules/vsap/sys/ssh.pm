package VSAP::Server::Modules::vsap::sys::ssh;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::backup;

##############################################################################

our $VERSION = '0.12';

our $SSHD_CONFIG = "/etc/ssh/sshd_config";

##############################################################################

sub _disable_protocol_1
{
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        # read it in
        open(CONFIG, $SSHD_CONFIG);
        my @config = <CONFIG>;
        close(CONFIG);
        # back it up
        VSAP::Server::Modules::vsap::backup::backup_system_file($SSHD_CONFIG);
        # write it out
        open(NEWCFG, ">/tmp/sshd_config.$$") || return;
        for (my $i=0; $i<=$#config; $i++) {
            if ($config[$i] =~ /^(#?)Protocol/) {
                $config[$i] =~ s/^\#(Protocol\s+2\s)/$1/;
                $config[$i] =~ s/^(Protocol\s+2,1\s)/\#$1/;
            }
            print NEWCFG $config[$i] || return;
        }
        close(NEWCFG);
        # rename
        rename("/tmp/sshd_config.$$", $SSHD_CONFIG);
    }
}

# ----------------------------------------------------------------------------

sub _enable_protocol_1
{
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        # read it in
        open(CONFIG, $SSHD_CONFIG);
        my @config = <CONFIG>;
        close(CONFIG);
        # back it up
        VSAP::Server::Modules::vsap::backup::backup_system_file($SSHD_CONFIG);
        # write it out
        open(NEWCFG, ">/tmp/sshd_config.$$") || return;
        for (my $i=0; $i<=$#config; $i++) {
            if ($config[$i] =~ /^(#?)Protocol/) {
                $config[$i] =~ s/^(Protocol\s+2\s)/\#$1/;
                $config[$i] =~ s/^\#(Protocol\s+2,1\s)/$1/;
            }
            print NEWCFG $config[$i] || return;
        }
        close(NEWCFG);
        # rename
        rename("/tmp/sshd_config.$$", $SSHD_CONFIG);
    }
}

# ----------------------------------------------------------------------------

sub _is_enabled_protocol_1
{
    my $enabled = 0;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        # read it in
        open(CONFIG, $SSHD_CONFIG);
        my @config = <CONFIG>;
        close(CONFIG);
        $enabled = grep(/^Protocol.*1/i, @config);
    }
    return($enabled)
}

# ----------------------------------------------------------------------------

sub _num_connections
{
    my $netstat_command;
    if (-e "/bin/netstat") {
        # Linux
        $netstat_command = "/bin/netstat -tnv";
    }
    elsif (-e "/usr/bin/netstat") {
        # FreeBSD
        $netstat_command = "/usr/bin/netstat -p tcp -n";
    }
    else {
        # punt
        return(0);
    }
    my @netstat = `$netstat_command`;
    my @ssh_connections = grep(/\s[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*[:|\.]22\s/, @netstat);
    my $num_connections = $#ssh_connections + 1;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssh::audit;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $status = "ok";

    # disable Protocol version 1 (if no connections found)
    my $nc = VSAP::Server::Modules::vsap::sys::ssh::_num_connections();
    VSAP::Server::Modules::vsap::sys::ssh::_disable_protocol_1 unless ($nc);

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:ssh:audit');
    $root_node->appendTextChild(status => $status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssh::init;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $status = "ok";

    # enable Protocol version 1
    VSAP::Server::Modules::vsap::sys::ssh::_enable_protocol_1();

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:ssh:init');
    $root_node->appendTextChild(status => $status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::ssh::status;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # is SSH Protocol version 1 enabled?
    my $ssh1_status;
    $ssh1_status = VSAP::Server::Modules::vsap::sys::ssh::_is_enabled_protocol_1();
    $ssh1_status = $ssh1_status ? "enabled" : "disabled";

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:ssh:status');
    $root_node->appendTextChild(ssh1_status => $ssh1_status);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::ssh - VSAP module to support CPX embedded
java terminal access (only available using SSH v1 at the moment)

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::ssh;

=head1 DESCRIPTION

This module is used for the benefit of CPX embedded java terminal access.

=head1 SEE ALSO

sshd_config(5)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

