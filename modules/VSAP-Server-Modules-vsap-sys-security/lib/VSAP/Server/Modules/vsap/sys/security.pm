package VSAP::Server::Modules::vsap::sys::security;

use 5.008004;
use strict;
use warnings;
use Carp;

use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.01';

our %_ERR = (
    ERR_NOTAUTHORIZED => 100,
);

use constant LOCK_EX => 2;

##############################################################################

our $force_ssl_block = <<'_REWRITE_BLOCK_';
## <===CPX: force ssl redirect start===>
    <IfModule mod_rewrite.c>
        RewriteCond %{REQUEST_URI} ^/ControlPanel/
        RewriteCond %{SERVER_PORT} !^443$
        RewriteRule ^.*$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R]
    </IfModule>
## <===CPX: force ssl redirect end===>
_REWRITE_BLOCK_

# ----------------------------------------------------------------------------

sub _controlpanel_ssl_redirect_modify {

    my($modify_request) = @_;

    my $config_file = (-e "/www/conf.d/cpx.conf") ? 
                          "/www/conf.d/cpx.conf" : "/www/conf/httpd/conf";

    open CONF, "+< $config_file"
      or do {
          carp "Could not open $config_file: $!\n";
          return(0);
      };

    flock CONF, LOCK_EX
      or do {
          carp "Could not lock $config_file: $!\n";
          return(0);
      };

    seek CONF, 0, 0;  ## rewind

    my @conf = ();

    if ( $modify_request eq "disable" ) {
        my $skip = 0;
        local $_;
        while( <CONF> ) {
            if ( /CPX: force ssl redirect start/i ) {
                $skip = 1;
            }
            elsif ( /CPX: force ssl redirect end/i ) {
                $skip = 0;
                next;
            }
            next if ($skip);
            push @conf, $_;
        }
    }

    elsif ( $modify_request eq "enable" ) {
        my $scan_for_location = 0;
        local $_;
        while( <CONF> ) {
            push @conf, $_;
            if ( /require ControlPanel/i ) {
                $scan_for_location = 1;
            }
            elsif ( $scan_for_location && /<\/Location>/) {
                push(@conf, $force_ssl_block);
            }
        }
    }

    else {  # unknown request
        close CONF;
        return(0);
    }

    seek CONF, 0, 0;  ## rewind
    print CONF @conf;
    truncate CONF, tell CONF;
    close CONF;
    return(1);
}

# ----------------------------------------------------------------------------

sub _controlpanel_ssl_redirect_status {

    my $config_file = (-e "/www/conf.d/cpx.conf") ? 
                          "/www/conf.d/cpx.conf" : "/www/conf/httpd/conf";

    open CONF, "$config_file"
      or do {
          carp "Could not open $config_file: $!\n";
          return(-1);
      };

    seek CONF, 0, 0;  ## rewind

    my @conf = ();
    while( <CONF> ) {
        push @conf, $_;
    }
    close CONF;

    my $status = grep(/CPX: force ssl redirect start/i, @conf);
    return($status);
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::security::controlpanel;

sub handler {
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $sslr = $xmlobj->child('ssl_redirect') ? $xmlobj->child('ssl_redirect')->value : '';

    # are we changing stuff?
    my $is_edit = ($sslr ne '');
    if ($is_edit) {
        ## check for server admin
        unless ($vsap->{server_admin}) {
            $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "Not authorized to set security preferences");
            return;
        }
    }

    # handle ssl redirect change request (if made)
    my $ssl_redirect_status;
    my $ssls = VSAP::Server::Modules::vsap::sys::security::_controlpanel_ssl_redirect_status();
    if ( (($sslr eq "disable") && ($ssls)) ||
         (($sslr eq "enable") && (!$ssls)) ) {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            VSAP::Server::Modules::vsap::sys::security::_controlpanel_ssl_redirect_modify($sslr);
            $ssls = $ssls ? 0 : 1;  # invert status
            $ssl_redirect_status = $ssls ? "enabled" : "disabled";
            # add a trace to the message log
            VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} $ssl_redirect_status ssl_redirect");
            # restart apache
            $vsap->need_apache_restart();
        }
    }
    else {
        $ssl_redirect_status = $ssls ? "enabled" : "disabled";
    }

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'sys:security:controlpanel');
    $root_node->appendTextChild(ssl_redirect => $ssl_redirect_status);
    $dom->documentElement->appendChild($root_node);
    return;
}   

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::security - VSAP module for managing Control Panel security policies

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::security;
  blah blah blah

=head1 DESCRIPTION

=head2 EXPORT

None by default.


=head1 SEE ALSO


=head1 AUTHOR

Rus Berrett, E<lt>rus@berrett.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
