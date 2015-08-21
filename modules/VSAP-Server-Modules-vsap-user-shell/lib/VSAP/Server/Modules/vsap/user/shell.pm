package VSAP::Server::Modules::vsap::user::shell;

use 5.008004;
use strict;
use warnings;

use Cwd qw( abs_path );

use VSAP::Server::Base;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR = (
              SHELL_INVALID       => 200,
              SHELL_CHANGE_ERR    => 201,
              SHELL_USER_NULL     => 203,
              SHELL_PERMISSION_DENIED => 501,
            );

##############################################################################

sub get_list
{
    unless( open( FH, '<', '/etc/shells' ) ) {
        return wantarray ? ( undef, qq{Unable to open /etc/shells: $!\n}) : undef;
    }

    my @shells = map { /^(\S+)$/ } grep { ! /^(?:#.*|\s*)$/ } <FH>;

    close FH;

    return \@shells;
}

# ----------------------------------------------------------------------------

sub get_shell
{
    return (getpwnam(shift))[8];
}

##############################################################################

package VSAP::Server::Modules::vsap::user::shell::change;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = shift || $vsap->{_result_dom};

    # first check to see if domain/server admin is making a request;
    # and if so, check for authorization
    my $username = $xmlobj->child('user') ? $xmlobj->child('user')->value : '';

    if ($username eq "") {
        # presume this is the enduser changing his or her own password
        $username = $vsap->{username};
    }
    else {
        # check for authorization
        my $authorized = 0;
        if ($vsap->{server_admin}) {
            $authorized = 1;
        }
        else {
            require VSAP::Server::Modules::vsap::config;
            my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );
            $authorized = 1 if ($co->domain_admin(user => $username));
        }
        unless ( $authorized ) {
            $vsap->error($_ERR{SHELL_PERMISSION_DENIED} => "permission denied by config");
            return;
        }
    }

    my $new_shell = $xmlobj->child('shell') ? $xmlobj->child('shell')->value : '';

    $new_shell = VSAP::Server::Base::xml_unescape( $new_shell );

    my $shells = VSAP::Server::Modules::vsap::user::shell::get_list();

    # Make sure new shell is valid
    unless( scalar grep { $_ eq $new_shell } @$shells ) {
        $vsap->error( $_ERR{SHELL_INVALID} => qq{Invalid shell [$new_shell].} );
        return;
    }

  CHANGE_SHELL: {
        local $> = $) = 0;  ## regain privileges for a moment

        if ($vsap->is_linux()) {
            system('usermod','-s', $new_shell, $username);
        }
        else {
            unless( open( SH, "| chpass -s $new_shell $username" ) ) {
                $vsap->error( $_ERR{SHELL_CHANGE_ERR} => qq{Could not execute shell change: $!});
                return;
            }
            print SH $new_shell, "\n";
            close SH;
        }
    }

    # append a trace to the log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} changed shell for user '$username' to '$new_shell'");

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:shell:change');
    $root_node->appendTextChild( 'status' => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::shell::list;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;

    my $shells = VSAP::Server::Modules::vsap::user::shell::get_list();

    # first check to see if domain/server admin is making a request;
    # and if so, check for authorization
    my $username = $xmlobj->child('user') ? $xmlobj->child('user')->value : '';

    if ($username eq "") {
        # presume this is the enduser changing his or her own password
        $username = $vsap->{username};
    }
    else {
        # check for authorization
        my $authorized = 0;
        if ($vsap->{server_admin}) {
            $authorized = 1;
        }
        else {
            require VSAP::Server::Modules::vsap::config;
            my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );
            $authorized = 1 if ($co->domain_admin(user => $username));
        }
        unless ( $authorized ) {
            $vsap->error($_ERR{SHELL_PERMISSION_DENIED} => "permission denied by config");
            return;
        }
    }

    my $current_shell = VSAP::Server::Modules::vsap::user::shell::get_shell( $username );

    my $rdom = $vsap->{_result_dom};
    my $root_node = $rdom->createElement('vsap');
    $root_node->setAttribute( type => 'user:shell:list' );

    foreach my $shell ( @$shells ) {
        my $shell_node = $rdom->createElement('shell');
        if ($shell eq $current_shell) {
            $shell_node->setAttribute( current => 1 );
        }
        $shell_node->appendTextChild( path => VSAP::Server::Base::url_encode( $shell ) );
        $root_node->appendChild($shell_node);
    }

    $rdom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::shell::disable;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom    = shift || $vsap->{_result_dom};

    # build the dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'user:shell:disable' );

    # first check to see if domain/server admin is making a request;
    # and if so, check for authorization
    my $username = $xmlobj->child('user') ? $xmlobj->child('user')->value : '';

    if ($username eq "") {
        $vsap->error($_ERR{SHELL_USER_NULL} => "No username given");
        return;
    }
    else {
        # check for authorization
        my $authorized = 0;
        if ($vsap->{server_admin}) {
            $authorized = 1;
        }
        else {
            require VSAP::Server::Modules::vsap::config;
            my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );
            $authorized = 1 if ($co->domain_admin(user => $username));
        }
        unless ( $authorized ) {
            $vsap->error($_ERR{SHELL_PERMISSION_DENIED} => "permission denied by config");
            return;
        }
    }

    CHANGE_SHELL: {
        local $> = $) = 0;  ## regain privileges for a moment

        if ($vsap->is_linux()) {
            system('usermod', '-s', '/sbin/nologin', $username);
        }
        else {
            system('chpass', '-s', '/sbin/nologin', $username);  ## FIXME: not optimized for many users
        }
    }

    # append a trace to the log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} disabled shell access for user '$username'");

    $root->appendTextChild('status', 'ok');
    $dom->documentElement->appendChild($root);
    return;
}

##############################################################################
1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::user::shell - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::user::shell;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for VSAP::Server::Modules::vsap::user::shell, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 user:shell:disable

Disable shell access by setting login shell to /sbin/nologin

  <vsap type="user:shell:disable">
    <user>joefoo</user>
  </vsap>

B<user:shell:disable> returns:

  <vsap type="user:shell:disable">
    <status>ok</status>
  </vsap>


=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
