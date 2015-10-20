package VSAP::Server::Modules::vsap::user::mail;

use 5.008004;
use strict;
use warnings;

##############################################################################
 
our $VERSION = '0.12';

our %_ERR    = ( 
                 PERMISSION_DENIED    => 100,
                 USER_MISSING         => 200,
                 USER_UNKNOWN         => 201,
                 DOMAIN_MISSING       => 202,
                 DOMAIN_UNKNOWN       => 203,
                 EMAIL_PREFIX_INVALID => 204,
               );

##############################################################################
   
package VSAP::Server::Modules::vsap::user::mail::setup;

use Email::Valid;

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;
use VSAP::Server::Modules::vsap::mail::clamav;
use VSAP::Server::Modules::vsap::mail::spamassassin;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;
 
    # load up the config for the user
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    # get the domain (required for authentication check)
    my $domain = ( $xmlobj->child('domain') && $xmlobj->child('domain')->value
                   ? $xmlobj->child('domain')->value
                   : '' );

    # check to see if the domain exists on the system
    my %domains = ();
    if ( $vsap->{server_admin} ) {
        %domains = %{ $co->domains };
    }
    elsif ( $co->domain_admin && $domain ) {
        %domains = %{ $co->domains( $vsap->{username} ) };
    }
    elsif ( $co->mail_admin && $domain ) {
        my $user_domain = $co->user_domain( $vsap->{username} );
        %domains = %{ $co->domains( domain => $user_domain ) };
    }
    if ( $domain && keys(%domains) ) {  # avoid giveaway to non-privileged user
      unless ( defined($domains{$domain}) ) {
        $vsap->error( $_ERR{DOMAIN_UNKNOWN} => "unknown domain name" );
        return;
      }
    }

    # make sure *this* vsap user has permissions
    CHECK_AUTHZ: {
        last CHECK_AUTHZ if $vsap->{server_admin};
        if ( ($co->domain_admin || $co->mail_admin) && $domain ) {
            last CHECK_AUTHZ if ( defined($domains{$domain}) );
        }
        $vsap->error( $_ERR{PERMISSION_DENIED} => "Not authorized" );
        return;
    }

    # user checks
    my $user = ( $xmlobj->child('user') && $xmlobj->child('user')->value
                 ? $xmlobj->child('user')->value
                 : '' );
    if ( $user eq "" ) {
        $vsap->error( $_ERR{USER_MISSING} => "username is required" );
        return;
    }
    unless ( getpwnam($user) ) {
        $vsap->error( $_ERR{USER_UNKNOWN} => "username is unknown" );
        return;
    }

    # domain checks
    if ( $domain eq "" ) {
        $vsap->error( $_ERR{DOMAIN_MISSING} => "domain name is required" );
        return;
    }

    # email checks
    my $lhs = ( $xmlobj->child('email_prefix') && 
                $xmlobj->child('email_prefix')->value
                ? $xmlobj->child('email_prefix')->value
                : '' );
    if ( $lhs =~ /\@/ ) {
        $vsap->error( $_ERR{EMAIL_PREFIX_INVALID} => "email prefix is invalid" );
        return;
    }
    my $dest = $lhs . '@' . $domain;
    unless( Email::Valid->address( $dest ) ) {
        $vsap->error($_ERR{EMAIL_PREFIX_INVALID} => "email prefix is badly formed");
        return;
    }

    # add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling user:mail:setup for user '$user'");

    ## make backups as appropriate
    VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
    VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");

    # good to go.... setup email address 
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::add_entry($dest, $user);
    }

    # now setup selected capabilities (if any)
    my %capa = ();
    $co = new VSAP::Server::Modules::vsap::config( username => $user );
    my $capa_webmail = $xmlobj->child('capa_webmail') ? 1 : 0;
    $capa{'webmail'} = 1 if ($capa_webmail);
    my $capa_sa = $xmlobj->child('capa_spamassassin') ? 1 : 0;
    if ($capa_sa) {
        unless ( VSAP::Server::Modules::vsap::mail::spamassassin::_is_installed_globally() ) {
            VSAP::Server::Modules::vsap::mail::spamassassin::nv_enable($user);
        }
        $co->services(spamassassin => 1);
        $capa{'mail-spamassassin'} = 1;
    }
    my $capa_clamav = $xmlobj->child('capa_clamav') ? 1 : 0;
    if ($capa_clamav) {
        unless ( VSAP::Server::Modules::vsap::mail::clamav::_is_installed_milter() ) {
            VSAP::Server::Modules::vsap::mail::clamav::_init($user);
            VSAP::Server::Modules::vsap::mail::clamav::nv_enable($user);
        }
        $co->services(clamav => 1);
        $capa{'mail-clamav'} = 1;
    }
    $co->capabilities(%capa);
    $co->commit();

    # return success
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type', 'user:mail:setup');
    $root_node->appendTextChild('status', "ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::user::mail - VSAP module for user mail setup

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::user::mail;

=head1 DESCRIPTION

Blah blah blah.

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
