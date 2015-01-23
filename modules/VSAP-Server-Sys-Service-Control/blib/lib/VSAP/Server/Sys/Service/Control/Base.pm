package VSAP::Server::Sys::Service::Control::Base;

our $VERSION = '0.01';

sub new { 
    my $class = shift;
    my %args = @_;

    bless \%args, $class;
}

sub restart { 
    my $self = shift;
    $self->stop;
    return $self->start;
}

sub get_pid { 
    my $self = shift;
    my $pidfile = shift;

    return undef
	unless (-f $pidfile);

    open FH, "<$pidfile";
    my $line = (<FH>);
    close FH;

    my ($pid) = ($line =~ (/(\d+)/));

    return $pid;
}


1;
__END__

=head1 NAME

VSAP::Server::Sys::Service::Control::Base  - Base class for service specific module.

=head1 SYNOPSIS

  package VSAP::Server::Sys::Service::Control::SomeService; 

  use base VSAP::Server::Sys::Service::Control::Base;

  sub stop { .. } 
  sub start { .. } 
    ... 

=head1 DESCRIPTION

This is the base object for all service specific objects used by the VSAP::Server::Sys::Service::Control
module. This module defines the C<new> constructor for the object. Any common functionality which is needed 
by all services can be added to this class. This class should be considered abstract and never actually 
instantiated on its own. 

=head1 METHODS

=head2 new

Constructor for the base class. Simply blesses an empty hashref. 

=head2 restart

Method simple calls the stop and then start methods on the object. The return
is the result of the start. 

=head2 get_pid

Method returns the pid contained in a pidfile. Returns undef if file does not exist. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
