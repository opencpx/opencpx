package VSAP::Server::Sys::Config::Inetd::Impl::FreeBSD::Inetd;

use strict;
use warnings;

use Carp;
use Fcntl qw(O_RDWR LOCK_SH LOCK_EX LOCK_UN O_RDONLY);
use Tie::File;

use base qw(VSAP::Server::Sys::Config::Inetd);

##############################################################################

our $VERSION = '0.12';

our $INETD_CONF     = "/etc/inetd.conf";
our $INETD_PIDFILE  = '/var/run/inetd.pid';

our @INETD_MAP = (
                   'servicename',
                   'socketype',
                   'protocol',
                   'wait',
                   'user',
                   'prog',
                   'progargs'
                 );

our $TIED_CONF; 

##############################################################################
#
# This provides a mapping of the service names passed to the methods and how
# they are search in the inetd.conf file.  The available search fields are 
# specified in the @INETD_MAP variable above. 
#

my $isInstalledDovecot = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_dovecot();

our %SEARCH_MAP;
our %SERVICE_MAP;
if ($isInstalledDovecot) {
    %SERVICE_MAP = (
        'ftp'    => 'ftp',
        'ssh'    => 'ssh',
        'telnet' => 'telnet',
       );

    %SEARCH_MAP = ( 
        'ftp'    => { servicename => 'ftp',    protocol => qr/^tcp/, prog => qr/proftpd/ },
        'ssh'    => { servicename => 'ssh',    protocol => qr/^tcp/, prog => qr/sshd/ },
        'telnet' => { servicename => 'telnet', protocol => qr/^tcp/ }
      );
}
else {
    %SERVICE_MAP = (
        'pop3s'  => 'pop3s',
        'pop3'   => 'pop3',
        'imap'   => 'imap',
        'imaps'  => 'imaps',
        'ftp'    => 'ftp',
        'ssh'    => 'ssh',
        'telnet' => 'telnet',
     );

    %SEARCH_MAP = (
        'pop3'   => { servicename => 'pop3',   protocol => qr/^tcp/ },
        'pop3s'  => { servicename => 'pop3s',  protocol => qr/^tcp/ },
        'imap'   => { servicename => 'imap',   protocol => qr/^tcp/ },
        'imaps'  => { servicename => 'imaps',  protocol => qr/^tcp/ },
        'ftp'    => { servicename => 'ftp',    protocol => qr/^tcp/, prog => qr/proftpd/ },
        'ssh'    => { servicename => 'ssh',    protocol => qr/^tcp/, prog => qr/sshd/ },
        'telnet' => { servicename => 'telnet', protocol => qr/^tcp/ }
      );
}

##############################################################################

sub _extract_lines
{ 
    my $self = shift;

    foreach my $line (@{$self->{CONF}}) { 
        next unless ($line =~ (/(?:stream|dgram|raw|rdm|seqpacket)/));
        # We need a reference to the lines, so when we edit them
        # the changes will flow back into the TIE'd file. 
        push @{$self->{LINES}}, \$line;
    }
}

# ----------------------------------------------------------------------------

sub _parse_line
{
    my $line = shift; 

    my %linehash;
    my @arr = split(/\s+/, $$line, $#INETD_MAP+1);
    for (my $pos=0; $pos<=$#INETD_MAP; $pos++) { 
        $linehash{$INETD_MAP[$pos]} = $arr[$pos];
    }

    $linehash{enabled} = ($linehash{servicename} =~ (/^\#/)) ? 0 : 1;
    $linehash{servicename} =~ (s/^\#//g);
    $linehash{line} = $line; 
    return \%linehash;
}

# ----------------------------------------------------------------------------

sub _restart_inetd
{

    return undef unless (-e $INETD_PIDFILE and -f $INETD_PIDFILE);

    open FH, "<$INETD_PIDFILE";
    my $pid = (<FH>);
    close FH;

    return undef unless ($pid && $pid =~ (/\d+/));

    return undef unless (kill 1, $pid);

    return 1;
}

# ----------------------------------------------------------------------------

sub _search
{ 
    my $self = shift; 
    my %args = @_;
    my @lines = @{$self->{LINES}};

    # Setup an array of references to lines in the file. 
    @lines = reverse @lines if ($self->searchorder eq 'bottomup');
    
    foreach my $field (keys %args) { 
        croak("invalid search field: $field") unless grep /$field/, @INETD_MAP;
    }

    my @results = ();
    foreach my $line (@lines) { 
      ENTRY: { 
            my $linehash = _parse_line($line);
            next unless $linehash;
            foreach my $key (keys %args) { 
                if (ref($args{$key}) eq "Regexp") { 
                    next ENTRY unless ($linehash->{$key} =~ $args{$key});
                }
                else { 
                    next ENTRY unless ($linehash->{$key} eq $args{$key});
                }
            }
            push(@results, $linehash);
        }
    }
    return(@results);
}

# ----------------------------------------------------------------------------

sub _tie_conf
{ 
    my $self = shift;
    my $file = $self->{conf};

    $TIED_CONF = tie @{$self->{CONF}}, 'Tie::File', $file, mode => ($self->{readonly} ? O_RDONLY : O_RDWR)
        or die "Could't tie $file: $!";
    $self->{readonly} ? $TIED_CONF->flock(LOCK_SH) : $TIED_CONF->flock(LOCK_EX);
}

##############################################################################

sub new
{ 
    my $class = shift;
    my %args = (@_);

    $args{searchorder} ||= 'topdown';
    $args{conf} ||= $INETD_CONF;
    $args{readdonly} ||= 0;
    
    my $self = bless \%args, $class;
    $self->{_services} = \%SERVICE_MAP;
    $self->_tie_conf;
    $self->_extract_lines; 
    return $self;
} 

##############################################################################

sub disable
{ 
    my $self = shift;
    my $service = shift;
    my %args = %{$SEARCH_MAP{$service}};

    my @results = $self->_search(%args);

    return undef unless ($#results >= 0);

    foreach my $linehash (@results) {
        my $line = $linehash->{line};
        unless ($$line =~ (/^\#/)) {
            $$line = '#'.$$line;
        }
    }

    return 0 unless $self->_restart_inetd; 

    return 1; 
}

##############################################################################

sub enable
{ 
    my $self = shift;
    my $service = shift;
    my %args = %{$SEARCH_MAP{$service}};

    my @results = $self->_search(%args);

    return undef unless ($#results >= 0);

    foreach my $linehash (@results) {
        my $line = $linehash->{line};
        if ($$line =~ (/^\#/)) {
            $$line = substr($$line, 1, length($$line));
        }
    }

    return 0 unless $self->_restart_inetd; 

    return 1; 
}

##############################################################################

sub is_disabled
{ 
    my $self = shift;
    my $service = shift;

    my $results = $self->is_enabled($service);

    return undef unless defined($results);

    return $results ? 0 : 1;
}

##############################################################################

sub is_enabled
{ 
    my $self = shift;
    my $service = shift;

    my %args = %{$SEARCH_MAP{$service}};

    my @results = $self->_search(%args);
    my $linehash = $results[0];

    return undef unless ($linehash);

    return ($linehash->{enabled}) ? 1 : 0;
}

##############################################################################

sub searchorder
{ 
    my $self = shift;
    my $neworder = shift;

    $self->{searchorder} = $neworder if ($neworder);

    return $self->{searchorder}
}

##############################################################################

sub version
{
    my $self = shift;
    my $service = shift;

    my $version = "0.0.0.0";

    if ($service eq "ftp") {
        my $status = `/usr/local/sbin/proftpd -v`;
        if ($status =~ m#Version (.*?)$#i) {
            $version = $1;
        }
    }
    elsif ($service eq "ssh") {
        my $status = `/usr/sbin/sshd -v 2>&1`;
        if ($status =~ m#OpenSSH_(.*?)[,\-\s]#i) {
            $version = $1;
        }
    }
    elsif (($service eq "pop3") || ($service eq "pop3s")) {
        my $inode = (stat("/usr/local/libexec/ipop3d"))[1];
        my @files = `/bin/ls /usr/local/libexec/ipop3d-*`;
        foreach my $file (@files) {
            chomp($file);
            my $fnode = (stat($file))[1];
            if ($fnode == $inode) {
                ($version) = (split("-", $file))[1];
                last;
            }
        }
    }
    elsif (($service eq "imap") || ($service eq "imaps")) {
        my $inode = (stat("/usr/local/libexec/imapd"))[1];
        my @files = `/bin/ls /usr/local/libexec/imapd-*`;
        foreach my $file (@files) {
            chomp($file);
            my $fnode = (stat($file))[1];
            if ($fnode == $inode) {
                ($version) = (split("-", $file))[1];
                last;
            }
        }
    }

    return $version;
}

##############################################################################

sub DESTROY
{ 
    my $self = shift;

    $TIED_CONF->flock(LOCK_UN) if defined($TIED_CONF);

    undef $TIED_CONF;

    untie @{$self->{CONF}};
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Sys::Config::Inetd - An module which enables control and reporting of services in inetd.conf

=head1 SYNOPSIS

 use VSAP::Server::Sys::Config::Inetd::Impl::FreeBSD::Inetd;

 $inetd = Config::Inetd->new( searchorder => 'forward', conf => '/etc/inetd.conf', readonly => 0);

 if ($inetd->is_enabled( servicename => 'ftp', protocol => qr/^tcp/)) {
    print "ftp is enabled.";
 }

 # Disable the ftp
 $inetd->disable('ftp');

 # Enable the ftp
 $inetd->enable('ftp');

 $inetd->searchorder('topdown');
# or
 $inetd->searchorder('bottomup');

=head1 DESCRIPTION

Config::Inetd is an interface to inetd's configuration file F<inetd.conf>.
It simplifies enabling, disabling and checking on the current state of services.
It consistently handles the case where there are multiple entries in the inetd.conf
for the same service and protocol. The module always acts upon the first entry it
finds given the search criteria. The search criteria can be any field in the inetd.conf
file, and the search can take place from topdown or bottomup in the file. This enables
you to always enable the last (or first) entry in the file for a given service.

=head1 METHODS

=head2 new

Constructor

 $inetd = VSAP::Server::Sys::Config::Inetd->new( conf => '/etc/inetd.conf', searchorder => 'forwards' );

The I<conf> element defines where the inetd.conf file is located. If not included, the
default value of F</etc/inetd.conf> is used. The searchorder element defines in which
order the inetd.conf file is searched. The valid values are I<bottomup> and I<topdown>
with the default being I<bottomup>. The readonly flag, if true opens the file in readonly
mode and performs a shared lock rather then exclusive lock on the file.

=head2 is_enabled

The is_enabled method returns undef if no entry was found, 0 if the entry was found but is
disabled (commented out).

The I<is_enabled>, I<is_disabled>, I<enable> and I<disable> methods on the object requires a service
name. The mapping of service names to specific entires in the inetd.conf file is done by the %SERVICE_MAP
variable. In the %SERVICE_MAP file you can specify any of the following: I<servicename>, I<socketype>,
I<protocol>, I<wait>, I<user>, I<prog>, I<progargs>. These keys directly map in the same order as the
fields in the inetd.conf file. The search takes place line by line in the order defined by the search
order parameter, either begining at the top or bottom of the file. The first line which matches the
B<ALL> search criteria is used for that operation. The value used can be either a simple scalar which
is compared using the 'eq' operator, or can be a reference to a regex (ex: qr/somestring/). This makes
it a powerful interface to act upon the ftp service which uses a certain ftp application.

=head2 is_disabled

Method returns 1 if the specified entry is disabled, 0 if the specified entry is not disabled (ie: enabled)
and undef if the specified entry cannot be found.

=head2 enable

Method enables a service specified by the search criteria. Returns 1 on success, undef if the specified
entry cannot be found. If the entry was already enabled, nothing is done and 1 is returned. Inetd is
restarted after this call.

=head2 disable

Method disables a service specified by the search criteria. Returns 1 on success, undef if the specified
entry cannot be found. If the entry was already disabled, nothing is done and 1 is returned. Inetd is
restarted after this call.

=head2 searchorder

Method used to get/set the search order used for the I<is_disabled>, I<disable>, I<is_enabled> and I<enabled>
methods. Method accepts optional argument 'bottomup' or 'topdown' defining the search order through the inetd.conf file.
The first entry matched in a search is used, so this is why the search order is important. Method returns
the current searchorder string.

=head2 EXPORT
None by default.

=head1 SEE ALSO

L<Tie::File>, inetd(8), inetd.conf(5)

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

