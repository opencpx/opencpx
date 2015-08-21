package VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd;

use strict;
use warnings;

use Carp;

use base qw(VSAP::Server::Sys::Config::Inetd);

use VSAP::Server::Modules::vsap::sys::monitor;

##############################################################################

our $VERSION = '0.12';

our %SEARCH_MAP = (
        'ftp'   => ((-e "/usr/sbin/proftpd") ? 'proftpd' : 'vsftpd'),
	'ssh'   => 'ssh',
        'pop3s' => 'popa3ds',
        'pop3'  => 'popa3d',
        'imap'  => 'imap',
        'imaps' => 'imaps',
    );

##############################################################################

sub _parse_status
{
    my $self = shift;

    my @output = `/sbin/chkconfig --list`;

    my $flag;
    foreach my $line (@output) {
	if ($line =~ /^xinetd based services/) {
            $flag = 1;
            next;
        }
        next unless ($flag);
        my ($service,$status) = ($line =~ (/\s*(.*):\s*(.*)$/));
        $self->{services}->{$service} = $status;
    }

    # prune services that aren't running through xinetd
    foreach my $service_name (keys(%SEARCH_MAP)) {
        my $xinetd_service = $SEARCH_MAP{$service_name};
        unless (defined($self->{services}->{$xinetd_service})) {
            delete $self->{_services}->{$service_name};
        }
    }
}

##############################################################################

sub new
{
    my $class = shift;
    my %args = (@_);

    my $self = bless \%args, $class;
    $self->{_services} = \%SEARCH_MAP;
    $self->_parse_status;

    return $self;
}

##############################################################################

sub is_disabled
{
    my $self = shift;
    my $service = shift;

    $service = exists $self->{_services}->{$service} ? $self->{_services}->{$service}  : $service;

    return ($self->{services}->{$service} eq 'off') ? 1 : 0;
}

##############################################################################

sub is_enabled
{
    my $self = shift;
    my $service = shift;

    $service = exists $self->{_services}->{$service} ? $self->{_services}->{$service}  : $service;

    return ($self->{services}->{$service} eq 'on') ? 1 : 0;
}

##############################################################################

sub disable
{
    my $self = shift;
    my $service = shift;

    $service = exists $self->{_services}->{$service} ? $self->{_services}->{$service}  : $service;

    my $rc = system('/sbin/chkconfig', $service, 'off');

    $self->_parse_status;

    return 0 if (($rc >> 8) != 0);

    return 1;
}

##############################################################################

sub enable
{
    my $self = shift;
    my $service = shift;

    $service = exists $self->{_services}->{$service} ? $self->{_services}->{$service}  : $service;

    my $rc = system('/sbin/chkconfig', $service, 'on');

    $self->_parse_status;

    return 0 if (($rc >> 8) != 0);

    return 1;
}

##############################################################################

sub version
{
    my $self = shift;
    my $service = shift;

    my $version = "0.0.0.0";

    if ($service eq "ftp") {
        if (-e "/usr/sbin/proftpd") {
            my $status = `/usr/sbin/proftpd -v`;
            if ($status =~ m#Version (.*?)$#i) {
                $version = $1;
            }
        }
        elsif (-e "/usr/sbin/vsftpd") {
            my $status = `/usr/sbin/vsftpd -v 0>&1`;
            if ($status =~ m#version (.*?)$#i) {
                $version = $1;
            }
        }
        else {
            $version = "";
        }
    }
    elsif ($service eq "ssh") {
        my $status = `/usr/sbin/sshd -v 2>&1`;
        if ($status =~ m#OpenSSH_(.*?)[,\-\s]#i) {
            $version = $1;
        }
    }
    elsif (($service eq "pop3") || ($service eq "pop3s") ||
           ($service eq "imap") || ($service eq "imaps")) {
        $version = `/usr/sbin/dovecot --version`;
        chomp($version);
    }

    return $version;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd - Module used to control inetd on the linux vps platform.

=head1 SYNOPSIS

 use VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd;

 $inetd = new VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd();

 if ($inetd->is_enabled('ftp') {
    print "ftp is enabled.";
 }

 # Disable the ftp service
 $inetd->disable('ftp');

 # Enable the ftp service
 $inetd->enable('ftp');

=head1 DESCRIPTION

Module used /sbin/chkconfig to control xinetd based services.

=head1 METHODS

=head2 new

Constructor

 $inetd = VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd->new();

=head2 is_enabled

The is_enabled method returns undef if no entry was found, 0 if the entry was found but is
disabled (commented out).

The I<is_enabled>, I<is_disabled>, I<enable> and I<disable> methods require the name of a service.
The %SUPER::SEARCH_MAP defines a translation from the provided service name to the service name which xinetd
understands. This is useful since different platforms may call the services by different names.

=head2 is_disabled

Method returns 1 if the specified entry is disabled, 0 if the specified entry is not disabled (ie: enabled)
and undef if the specified entry cannot be found.

=head2 enable

Method enables a service specified by the search criteria. Returns 1 on success, undef if the specified
entry cannot be found. If the entry was already enabled, nothing is done and 1 is returned.

=head2 disable

Method disables a service specified by the search criteria. Returns 1 on success, undef if the specified
entry cannot be found. If the entry was already disabled, nothing is done and 1 is returned.

=head2 EXPORT

None by default.

=head1 SEE ALSO

xinetd.conf, chkconfig

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
