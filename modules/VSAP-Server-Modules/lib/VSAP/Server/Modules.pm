package VSAP::Server::Modules;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01';

## keep working ...
our $CONFIG  = $ENV{VSAPD_CONFIG} || -e '/usr/local/vwh/cp/etc/vsapd.conf' ? 
                                        '/usr/local/vwh/cp/etc/vsapd.conf' : 
                                     -e '/usr/local/cp/etc/vsapd.conf' ?
                                        '/usr/local/cp/etc/vsapd.conf' : 
                                        '/usr/local/etc/vsapd.conf';

our $BASE    = 'VSAP::Server::Modules::';
our $DEBUG   = $ENV{VSAPD_DEBUG}  || 0;

unless( -f $CONFIG ) {
    print STDERR "No configuration file found ($CONFIG)\n" if $DEBUG;
    return 1;
}

our $MODULES = {};
my $cnt = 0;

open CONF, $CONFIG
  or die "Could not open '$CONFIG': $!\n";
local $_;
while( <CONF> ) {
    next if /^\s*$/o;   ## skip whitespace
    next if /^\s*\#/o;  ## skip comments

    chomp;

    if( /^\s*LoadModule\s+(\S+)\s*$/io ) {
	my $loadmodule = $1;
	unless( $loadmodule =~ /^$BASE/ ) {
	    $loadmodule = $BASE . $loadmodule;
	}
	$MODULES->{'modules'}->{$loadmodule} = $cnt++;
    }

    elsif( /^\s*UnloadModule\s+(\S+)\s*$/io ) {
	my $loadmodule = $1;
	unless( $loadmodule =~ /^$BASE/ ) {
	    $loadmodule = $BASE . $loadmodule;
	}
	delete $MODULES->{'modules'}->{$loadmodule};
    }
}
close CONF;

## process modules
for my $module ( sort { $MODULES->{'modules'}->{$a} <=> $MODULES->{'modules'}->{$b} } 
		 keys %{$MODULES->{'modules'}} ) {
    my $fclass = "$module.pm"; $fclass =~ s!::!/!g;
    if( exists $INC{$fclass} ) {
	print STDERR "'$module' already loaded. Skipping\n" if $DEBUG;
	next;
    }

    eval "require $module";
    if( $@ ) {
	print STDERR "Error loading '$module': $@\n";
	undef $module;
	next;
    }

    print STDERR "'$module' successfully loaded ($INC{$fclass})\n" if $DEBUG;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules - VSAP control panel modules

=head1 SYNOPSIS

  use VSAP::Server::Modules;

=head1 DESCRIPTION

VSAP::Server::Modules loads all necessary control panel modules via
F</usr/local/etc/vsapd.conf> (by default).

Modules listed in F<vsapd.conf> may be listed relative to
VSAP::Server::Modules for brevity's sake. Here is a sample
F<vsapd.conf>:

    ## authentication
    LoadModule    vsap::auth

    ## modules common to all user types
    LoadModule    vsap::server::password
    ...

=head1 SEE ALSO

L<VSAP::Server(1)>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Scott Wiersdorf

=cut
