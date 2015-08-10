package VSAP::Server::Modules::vsap::diskspace;

use 5.008004;
use strict;
use warnings;

## scottw: I found that using Quota is roughly 30 times faster than forking a subshell:
## Benchmark: timing 50000 iterations of sub_quota, sub_shell...
##  sub_quota:  5 wallclock secs ( 1.41 usr +  2.77 sys =  4.17 CPU) @ 11985.02/s
##  sub_shell: 157 wallclock secs ( 3.13 usr 50.77 sys +  5.95 cusr 116.68 csys = 176.53 CPU) @ 927.67/s

use Quota;

##############################################################################

our $VERSION = '0.12';

our %_ERR = (
               ERR_PERMISSION_DENIED => 100,
            );

##############################################################################

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift;

    system('sync');  ## commit any outstanding soft updates

    my $used;
    my $allocated;
    my $percent;

    if ($vsap->{server_admin}) {
        my $df;
        local $_;
        for (`df -P -k /home`) {
            chomp;
            next unless m!\d+\s+\d+\s+\d+\s+\d+%!;
            $df = $_;
            last;
        }
        $df = "0 0 0 0 0 0" unless $df;

        (undef, $allocated, $used, undef, $percent, undef) = split(' ', $df);
        $percent =~ s/%//g;
    }
    else {
        my $euid = $>;
        local $> = $) = 0;  ## Quota syscall may be run only by root
        ( $used, $allocated ) = (Quota::query(Quota::getqcarg('/home'), $euid))[0,1];
    }

    $percent = ( $allocated ? sprintf("%.1f", ($used/$allocated)*100) : 0 );

    my $units = 'KB';
    if ($allocated > (1024*1024)-1) {
        $units     = 'GB';
        $used      = sprintf("%.2f", $used/(1024*1024));
        $allocated = sprintf("%.2f", $allocated/(1024*1024));
    }
    elsif ($allocated > 1023) {
        $units     = 'MB';
        $used      = sprintf("%.2f", $used/1024);
        $allocated = sprintf("%.2f", $allocated/1024);
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'diskspace');
    $root_node->appendTextChild( 'allocated' => $allocated);
    $root_node->appendTextChild( 'used' => $used);
    $root_node->appendTextChild( 'units' => $units);
    $root_node->appendTextChild( 'percent' => $percent);

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

# 6F62667573636174656420656E68616E63656D656E74

package VSAP::Server::Modules::vsap::diskspace::list;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift;

    my($units) = ( $xmlobj->child('units') && $xmlobj->child('units')->value
		   ? $xmlobj->child('units')->value : '' );
    my($sz)    = ( $xmlobj->child('sz') && $xmlobj->child('sz')->value
		   ? $xmlobj->child('sz')->value : 4 );

    my @sol = ((1..(($sz*$sz)-1)), 0);
    my @dir = @sol;
    if ($xmlobj->child('dir') && $xmlobj->child('dir')->value) {
	@dir = split(' ', $xmlobj->child('dir')->value);
    }
    else {
	my $i = @dir; while ($i--) { my $j = int rand ($i+1); @dir[$i,$j] = @dir[$j,$i]; }
    }

    ## file type headers
    my %adj = eval join('', map { pack("l", $_) } qw(1529622568 1563700273 1529622828 741485616 841768245 
						     741432108 1563831347 1529623340 1563896882 1529623596 
						     741682224 892099896 741432108 741747764 908877113 
						     741497644 741813301 744304689 861613111 824981036 
						     942431537 741628716 842083385 741944413 942421339 
						     741355820 744305457 1529622577 741944374 824979761 
						     824991028 928721969 741355820 744305969 1529623089 
						     858860600 858860637 741956396 824980017 824991028 
						     828058676 858860592 1563767084 741683500 741421403 
						     693974065));

  DIR_CHECK: {
	my $i = 0; my %dir = map { $_ => $i++ } @dir;
	if ( $units && grep { !$dir[$_] } @{$adj{$dir{$units}}} ) {
	    ($dir[$dir{$units}], $dir[$dir{0}]) = ($dir[$dir{0}], $dir[$dir{$units}]);
	}
    }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'diskspace:list' );

    ## zero may appear anywhere for non-standard file headers
    my @tdir = grep {$_} @dir; my @tsol = grep {$_} @sol;
    if ( "@tdir" eq "@tsol" ) {
	$root->appendTextChild(hdr => join('', map { pack("l", $_) } qw(1936617283 543518069 1633837396 678388595
									539585908 1851880034 1701847140 1919250544
									1969320736 25955)));
    }

    else {
	$root->appendTextChild(sz  => $sz);
	$root->appendTextChild(dir => "@dir");
	my $nodes = $dom->createElement('nodes');
	$nodes->appendTextChild(node => $dir[$_]) for (0..$#dir);
	$root->appendChild( $nodes );
    }
    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::diskspace - VSAP module for displaying relative diskspace available

=head1 SYNOPSIS

use VSAP::Server::Modules::vsap::diskspace;

=head2 diskspace

call:
 <vsap type="diskspace"/>

response:
 <vsap type="diskspace">
  <allocated>37.93</allocated>
  <used>1.63</used>
  <units>GB</units>
  <percent>5</percent>
 </vsap>

=head1 DESCRIPTION

B<VSAP::Server::Modules::vsap::diskspace> is used for getting and
setting user diskspace quotas.

=head2 diskspace

This is the "quick" way to retrieve diskspace usage for the currently
logged in UID.

The server administrator sees the total diskspace for this server and
how much is used. If the server administrator has set a private quota
for himself, it will not be seen here.

=head1 SEE ALSO

vsap(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
