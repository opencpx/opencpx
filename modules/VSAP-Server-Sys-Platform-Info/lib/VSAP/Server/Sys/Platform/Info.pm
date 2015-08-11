package VSAP::Server::Sys::Platform::Info;

use 5.008004;
use strict;
use warnings;

use XML::LibXML;

use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::sys::hostname;

##############################################################################

our $VERSION = '0.12';

##############################################################################

sub new
{
    my $class = shift;
    my $self = bless {}, $class;

    my @fields = qw(

      bwlimit bwstat cpushare disklimit diskquota diskstat diskusage hostname initpid ipaddr ipaddr6 iquota ldavg nofile nofilebarrier
      nofilelimit noproc noprocbarrier noproclimit pmem server sflags stype type vid vmem vusers

    );

    @{ $self->{ map } }{ @fields } = @fields;

    $self->{ system } = $^O;
    $self->{ vk }     = '';
    $self->{ get }    = \&_get;

    $self->{ field }{ hostname } = VSAP::Server::Modules::vsap::sys::hostname::get_hostname();

    my ( %map, @na );

    if ( $self->{ system } eq 'freebsd' ) {

        eval 'use Vkern';
        die $@ if $@;

      $self->{ system } = 'vkern';
      $self->{ vk }     = Vkern->new;
      $self->{ get }    = $self->{ vk }->can( 'vkern' );

      # map fields
      %map = (

        ipaddr      => 'ip',
        login       => 'name',
        noproclimit => 'nproclimit',
        noproc      => 'nproc',
        type        => 'stype',

      );
    }
    elsif ( $self->{ system } eq 'linux' && -d '/proc/user_beancounters' ) {

        eval 'use OpenVZ';
        die $@ if $@;

        $self->{ system } = 'openvz';
        $self->{ vk }     = OpenVZ->new;
        $self->{ get }    = $self->{ vk }->can( 'get' );

        # map fields
        %map = (

          ipaddr        => 'ip',
          login         => 'login',
          nofilebarrier => 'nofilebarrier',
          nofilelimit   => 'numfilelimit',
          nofile        => 'numfile',
          noprocbarrier => 'noprocbarrier',
          noproclimit   => 'numproclimit',
          noproc        => 'numproc',
          server        => 'server',

        );
    }
    elsif ( $self->{ system } eq 'linux' ) {

        %map = (

          ipaddr => 'public-ipv4',
          vid    => 'vm-id',

        );

        push @na, qw(

          bwlimit bwstat cpushare disklimit diskstat ipaddr6 server stype vusers

        );

        $self->_get_info;

    }

    $self->{ map }{ $_ } = $map{ $_ } for keys %map;

    for my $na ( @na ) {
        delete $self->{ map }{ $na };
        delete $self->{ field }{ $na };
    }

    return $self;

}

##############################################################################

sub fields { return keys %{ $_[0]->{ map } } }

##############################################################################

sub get
{
    my ( $self, $field ) = @_;

    my $arg = $self->{ map }{ $field };

    return $self->{ get }->( $self, $arg );

}

##############################################################################

sub _get
{

  my ( $self, $arg ) = @_;

  return exists $self->{ field }{ $arg }
       ? $self->{ field }{ $arg }
       : sprintf '%s unknown or unimplemented', ( $arg || 'empty arg' );

}

##############################################################################

sub _get_info
{
    my $self = shift;

    eval 'use LWP::Simple ()';
    die $@ if $@;

    my ( $gateway_ip ) = do {
        # While it is possible to have multiple default gateways, it is generally
        # not advisable and we will most likely not be doing that.
        open my $FH, '<', '/proc/net/route'
          or die "Unable to open /proc/net/route: $!\n";
        my ( $row ) = grep { $_->[1] eq '00000000' && $_->[2] ne '00000000' }
                        map { [ split /\t/ ] } <$FH>;
        join '.', map { hex $_ } reverse unpack 'A2 A2 A2 A2', $row->[2];
    };

    my $url = "http://$gateway_ip/latest/meta-data/";

    my $meta_data = LWP::Simple::get( $url );

    for my $d ( split /\n/, $meta_data ) {
      $self->{ map }{ $d } = $d;
      $self->{ field }{ $d } = scalar LWP::Simple::get( "$url$d" );
    }

    $self->{ field }{ initpid } = 1;

    do {

      open my $FH, '<', '/proc/1/limits'
        or die "Unable to open /proc/1/limits: $!";

      local $/;
      my $l = <$FH>;

      # cat /proc/1/limits
      #Limit                     Soft Limit           Hard Limit           Units
      #Max cpu time              unlimited            unlimited            seconds
      #Max file size             unlimited            unlimited            bytes
      #Max data size             unlimited            unlimited            bytes
      #Max stack size            8388608              unlimited            bytes
      #Max core file size        0                    unlimited            bytes
      #Max resident set          unlimited            unlimited            bytes
      #Max processes             3718                 3718                 processes
      #Max open files            1024                 4096                 files
      #Max locked memory         65536                65536                bytes
      #Max address space         unlimited            unlimited            bytes
      #Max file locks            unlimited            unlimited            locks
      #Max pending signals       3718                 3718                 signals
      #Max msgqueue size         819200               819200               bytes
      #Max nice priority         0                    0
      #Max realtime priority     0                    0
      #Max realtime timeout      unlimited            unlimited            us

      ( $self->{ field }{ noproclimit } ) = $l =~ /Max processes\s+\d+\s+(\d+)/;

    };

    do {

      open my $FH, '<', '/proc/loadavg'
        or die "Unable to open /proc/loadavg: $!";

      local $/;
      my $l = <$FH>;
      my $field = $self->{ field };
      ( $field->{ ldavg }, $field->{ noproc } ) = $l =~ m!^(\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+)\s+\d+/(\d+)!;

    };

    do {

      open my $FH, '<', '/proc/sys/fs/file-nr'
        or die "Unable to open /proc/sys/fs/file-nr: $!";

      local $/;
      my $l = <$FH>;
      my $field = $self->{ field };
      ( $field->{ nofile }, undef, $field->{ nofilelimit } ) = split /\s+/, $l;

    };

    do {

      require Quota
        or die "Unable to require Quota module: $!";

      my $dev = Quota::getqcarg( '/home' );

      # returns
      # 0 bc current blocks being used
      # 1 bs soft limit for blocks
      # 2 bh hard limit for blocks
      # 3 bt time limit
      # 4 ic current inodes being used
      # 5 is soft limit for inodes
      # 6 ih hard limit for inodes
      # 7 it time limit

      my $result = 'good';

      my @data = Quota::query( $dev )
        or $result = Quota::strerr();

      my $field = $self->{ field };

      if ( $result eq 'good' ) {

        $field->{ diskusage }  = $data[0] / 1024; # blocks are 1kb
        $field->{ diskquota }  = $data[2] / 1024;
        $field->{ inodeusage } = $data[4];
        $field->{ iquota }     = $data[6];

      }
      elsif ( $result eq 'No quota for this user' ) {

        $field->{ diskusage }  = $result;
        $field->{ diskquota }  = $result;
        $field->{ inodeusage } = $result;
        $field->{ iquota }     = $result;

      }
      else {

        die "Unable to query quota: $result";

      }

    };

    # Because what we are getting from the virtual router is unreliable, we're
    # just going to go with what we have in the account.conf file. This code is
    # ripped from VSAP/Server/Modules/vsap/sys/account.pm:_read_account_conf

    # account.conf
    #
    # <?xml version="1.0" encoding="UTF-8"?>
    # <!DOCTYPE cpx_account_config SYSTEM "cpx_account_config.dtd">
    # <account>
    #   <hostname>HOSTNAME</hostname>
    #   <ext_ip>209.238.188.198</ext_ip>
    #   <int_ip>10.1.99.72</int_ip>
    #   <vmid>4824</vmid>
    # </account>

    my $field = $self->{ field };

    $field->{ 'public-ipv4' } = '0.0.0.0';
    $field->{ 'vm-id' } = 0;

    if (-e $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF) {

      my $conf;

      eval {
        local $> = $) = 0;  ## regain privileges for a moment

        open my $FH, '<', $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF
          or die "Unable to open $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF: $!";

        binmode $FH;

        local $/;
        my $data = <$FH>;

        $conf = XML::LibXML->load_xml(string => $data, no_blanks => 1)
          or die;
      };

      if ( $@ ) {

        $field->{ ERR } = [ 101, "Error reading $VSAP::Server::Modules::vsap::globals::ACCOUNT_CONF: $@" ]
          if $@;

      }
      else {
          # Can't find an equivalent to exists for an xml node, so we just ignore $@.
          my $i = '0.0.0.0';
          eval "\$i = \$conf->getElementsByTagName( 'ext_ip' )->[0]->string_value";
          my $v = '0';
          eval "\$v = \$conf->getElementsByTagName( 'vmid' )->[0]->string_value";
          $field->{ 'public-ipv4' } = $i;
          $field->{ 'vm-id' } = $v;

      }
    }
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Sys::Platform::Info - Obtain platform information on Linux.

=head1 SYNOPSIS

  use VSAP::Server::Sys::Platform::Info;

  $info = new VSAP::Server::Sys::Platform::Info();

  $info->get('vid');

=head1 DESCRIPTION

This module uses the OpenVZ module to obtain platform information.  The following fields are supported
by this module. Other fields may be supported by more specific platform modules.

  login       The login for the virtual server
  hostname    The hostname for the virtual server
  ipaddr      The ip of the virtual server
  vid         The virtual id for the server
  type        The type of the virtual server
  nofile      The number of files currently opened on the virtual server
  nofilelimit The soft limit of files permitted to be open on the virtual server
  noproc      The number of processes currently in use on the virtual server
  noproclimit The soft limit of processes permitted.
  diskusage   The current disk usage on the virtual server.

=head2 EXPORT

None by default.

=head1 AUTHOR

Alan  Young <alan.young@contractor.verio.net>
  based on code written by James A. Russo <jrusso@verio.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by NTT/Verio
