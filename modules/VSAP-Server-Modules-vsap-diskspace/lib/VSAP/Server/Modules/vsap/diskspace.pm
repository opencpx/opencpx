package VSAP::Server::Modules::vsap::diskspace;

use 5.008004;
use strict;
use warnings;

use Fcntl 'LOCK_EX';
use Quota;

use VSAP::Server::Modules::vsap::backup;

##############################################################################

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( quota_enable user_over_quota );

##############################################################################

our $VERSION = '0.12';

our %_ERR = ( ERR_PERMISSION_DENIED => 100 );

##############################################################################

sub _quota_check
{
    my $quotacheck = `/sbin/quotacheck / 2>&1`;
    return($quotacheck =~ /is enabled/);
}

##############################################################################

sub quota_enable
{
    ## FIXME: this is Linux-specific, need FreeBSD version also
    my $mountpoint = "/";
    my $quotaoptions = ",usrquota,grpquota";

    ## add usrquota,grpquota options to /etc/fstab unless already enabled
    return if (_quota_check());

    ## backup /etc/fstab file
    VSAP::Server::Modules::vsap::backup::backup_system_file("/etc/fstab");

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        ## enable quotas in /etc/fstab file
        my @fstab = ();
        open FSTAB, "+< /etc/fstab"
          or do {
              warn "Could not open /etc/fstab (quota_enable): $!\n";
              return;
          };
        flock FSTAB, LOCK_EX
          or do {
              close FSTAB;
              warn "Could not lock /etc/fstab (quota_enable): $!\n";
              return;
          };
        seek FSTAB, 0, 0;
        my $rewrite = 0;
        while (<FSTAB>) {
            my $curline = $_;
            # add quota options to '/'
            if (/^(\S+\s+$mountpoint\s+\S+\s+)(\S+)(\s+.*)/) {
                my $options = $2;
                unless ($options =~ /usrquota/) {
                    $curline = "$1$2$quotaoptions$3\n";
                    $rewrite = 1;
                }
            }
            push(@fstab, $curline);
        }
        if ($rewrite) {
            seek FSTAB, 0, 0;
            print FSTAB @fstab;
            truncate FSTAB, tell FSTAB;
        }
        close FSTAB;

        ## FIXME: add enable_quotas to rc.conf (FreeBSD)

        if ($rewrite) {
            ## remount file system
            system('/bin/mount -o remount $mountpoint');  
            ## create the quota database files
            system('/sbin/quotacheck -cugm $mountpoint');
        }
    }
}

##############################################################################

sub user_over_quota
{
    my $user = shift;

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        my $dev = Quota::getqcarg('/home');
        my($uid, $gid) = (getpwnam($user))[2,3];
        # check user quota
        my $usage = 0;
        my $quota = 0;
        ($usage, $quota) = (Quota::query($dev, $uid))[0,1];
        if (($quota > 0) && ($usage > $quota)) {
            return 0;
        }
        # check group quota
        my $grp_usage = 0;
        my $grp_quota = 0;
        ($grp_usage, $grp_quota) = (Quota::query($dev, $gid, 1))[0,1];
        if (($grp_quota > 0) && ($grp_usage > $grp_quota)) {
            return 0;
        }
    }

    return 1;
}

##############################################################################

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift;

    ## commit any outstanding soft updates
    system('sync');  

    ## enable quota on filesystem
    VSAP::Server::Modules::vsap::diskspace::quota_enable();

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
