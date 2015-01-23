package VSAP::Server::Sys::Config::Inetd;

use strict;
use POSIX;
our $VERSION = '1.1';
our $OS = (POSIX::uname())[0];
our %UNAME_OBJ_MAP = ( 'Linux' => 'VSAP::Server::Sys::Config::Inetd::Impl::Linux::Inetd', 
		       'FreeBSD' => 'VSAP::Server::Sys::Config::Inetd::Impl::FreeBSD::Inetd');

our %SEARCH_MAP = ();

use Carp;

sub new { 
    my $class = shift;
    my %args = (@_);

    my $location = $UNAME_OBJ_MAP{$OS};
    $class = $UNAME_OBJ_MAP{$OS};
    $location =~ s/::/\//g;
    $location =~ s/$/.pm/g;

    require $location;
    return $class->new(@_);
} 

sub services { 
    my $self = shift;
    return keys %{$self->{_services}};
}

1;

__END__

=head1 NAME

VSAP::Server::Sys::Config::Inetd - An module which enables control and reporting of services in inetd.conf 

=head1 SYNOPSIS

 use VSAP::Server::Sys::Config::Inetd;

 $inetd = Config::Inetd->new( searchorder => 'forward', conf => '/etc/inetd.conf', readonly => 0);

 if ($inetd->is_enabled( servicename => 'ftp', protocol => 'tcp')) { 
    print "ftp is enabled.";
 }

 # Disable the ftp service using tcp and has a program name containing proftpd. 
 $inetd->disable( servicename => 'ftp', protocol => 'tcp', prog => qr/proftpd/);

 # Enable the ftp service using tcp and has a program name containing proftpd. 
 $inetd->enable( servicename => 'ftp', protocol => 'tcp', prog => qr/proftpd/);

 # Enable someservice which has 'nowait' option and tcp protocol. 
 $inetd->enable( servicename => 'someservice', wait => 'nowait', protocol => 'tcp');

 $inetd->searchorder('topdown');
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

The I<is_enabled>, I<is_disabled>, I<enable> and I<disable> methods on the object requires key 
value pairs which are used to search for a specified entry to act on in the inetd.conf file. The keys 
can be any of the following: I<servicename>, I<socketype>, I<protocol>, I<wait>, I<user>, I<prog>, 
I<progargs>. These keys directly map in the same order as the fields in the inetd.conf file. The 
search takes place line by line in the order defined by the search order parameter, either begining
at the top or bottom of the file. The first line which matches the B<ALL> search criteria is used
for that operation. The value used can be either a simple scalar which is compared using the 'eq' 
operator, or can be a reference to a regex (ex: qr/somestring/). This makes it a powerful interface 
to act upon the ftp service which uses a certain ftp application. 

=head2 is_disabled

Method returns 1 if the specified entry is disabled, 0 if the specified entry is not disabled (ie: enabled)
and undef if the specified entry cannot be found. 

=head2 enable  

Method enables a service specified by the search criteria. Returns 1 on success, undef if the specified
entry cannot be found. If the entry was already enabled, nothing is done and 1 is returned. 

=head2 disable 

Method disables a service specified by the search criteria. Returns 1 on success, undef if the specified 
entry cannot be found. If the entry was already disabled, nothing is done and 1 is returned. 

=head2 disabled 

Method returns a array reference of hashes representing all the services which are disabled. The individual
hashs have the the same keys as used when searching for an element in addition to an I<enabled> element which
will always be 0 on any entries returned by this method. There will also be a I<line> element which is the
entire line from the inetd.conf file. This line is actually tied to the file, so doing any editing on this
scalar B<will> actually edit the inetd.conf file. 

=head2 disabled 

Method returns an array reference of hashes representing all the services which are disabled. The individual
hashs have the the same keys as used when searching for an element in addition to an I<enabled> element which
will always be 0 on any entries returned by this method. There will also be a I<line> element which is the
entire line from the inetd.conf file. This line is actually tied to the file, so doing any editing on this
scalar B<will> actually edit the inetd.conf file. 

=head2 enabled 

Method returns an array reference of hashes representing all the services which are enabled. The individual
hashs have the the same keys as used when searching for an element in addition to an I<enabled> element which
will always be 1 on any entries returned by this method. There will also be a I<line> element which is the
entire line from the inetd.conf file. This line is actually tied to the file, so doing any editing on this
scalar B<will> actually edit the inetd.conf file. 

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
