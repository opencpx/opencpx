package VSAP::Server::Modules::vsap::user::password;

use 5.006001;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::auth;
use VSAP::Server::Modules::vsap::logger;

our $VERSION = '0.01';
our %_ERR = 
(
    PW_NEW_MISSING      => 100,
    PW_NEW_NOT_MATCH    => 101,
    PW_CHANGE_ERR       => 102,
    PW_OLD_MISSING      => 103,
    PW_OLD_NOT_MATCH    => 104,
    PW_USER_NOT_FOUND   => 105,
    PW_PERMISSION_DENIED => 501,
);

##############################################################################

package VSAP::Server::Modules::vsap::user::password::get;

use VSAP::Server::Base;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # This is touchy security, so only let server admins peek at even the encrypted password.
    unless ( $vsap->{server_admin} ) {
        $vsap->error($_ERR{PW_PERMISSION_DENIED} => "permission denied by config");
        return; 
    }

    my $username = $xmlobj->child('user')
                              ? $xmlobj->child('user')->value
                              : '';


    if ( $username eq "" ) {
        $username = $vsap->{username};
    }

    my $crypt_password;
  GET_PASSWORD: {
        local $> = $) = 0;  ## regain privileges for a moment

	local $_;
	open SHADOW, $vsap->is_linux() ? '/etc/shadow' : '/etc/master.passwd';
	while (<SHADOW>)
	{
	    $crypt_password = $1
		if /^$username:([^:]*)/;
	}
	close SHADOW;
    }

    if ( !defined $crypt_password ) {
        $vsap->error($_ERR{PW_USER_NOT_FOUND} => "user \"$username\" not found");
        return; 
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'user:password:get');
    $root_node->appendTextChild( 'crypt_password' => $crypt_password);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::password::change;

use VSAP::Server::Base;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # first check to see if domain/server admin is making a request; 
    # and if so, check for authorization
    my $username = $xmlobj->child('user')
                                  ? $xmlobj->child('user')->value
                                  : '';

    my $old_password_required = 0;
    if ( $username eq "") {
        # changing own password
        $username = $vsap->{username} unless ($username);
        $old_password_required = 1;
    }
    else {
        # check for authorization
        my $authorized = 0;
        if ( $username eq $vsap->{username} ) {
            # changing own password
            $authorized = 1;
            $old_password_required = 1;
        }
        elsif ( $vsap->{server_admin} ) {
            $authorized = 1;
        }
        else {
            ## mail admin or domain admin
            require VSAP::Server::Modules::vsap::config;
            my $co = new VSAP::Server::Modules::vsap::config( uid => $vsap->{uid} );
            if ( $co->domain_admin ) {
                $authorized = 1 if ( $co->domain_admin(user => $username) );
            }
            elsif ( $co->mail_admin ) {
                my $user_domain = $co->user_domain($vsap->{username});
                my @authuserlist = keys %{$co->users(domain => $user_domain)};
                my $domains = $co->domains(domain => $user_domain);
                my $da = $domains->{$user_domain};
                if ( (grep(/^$username$/, @authuserlist)) &&
                     (!($co->domain_admin(admin => $username))) &&  ## cannot change password of domain admin
                     (!($co->mail_admin(admin => $username))) ) {   ## cannot change password of another mail admin
                    $authorized = 1;
                }
            }
        }
        unless ( $authorized ) {
            $vsap->error($_ERR{PW_PERMISSION_DENIED} => "permission denied by config");
            return; 
        }
    }

    ## note: admin needs old password only to change own password
    if ( $old_password_required ) {
        ## check old password
        my $old_password = $xmlobj->child('old_password')
                         ? $xmlobj->child('old_password')->value
                         : '';

        # Make sure old password was passed in 
        unless( $old_password ) { 
            $vsap->error( $_ERR{PW_OLD_MISSING} => q{Old password not entered} );  
            return;
        }

        # Make sure the 'old password' submitted is correct
        unless( $old_password eq $vsap->{password} ) { 
            $vsap->error( $_ERR{PW_OLD_NOT_MATCH} => q{Incorrect old password submitted} );  
            return;
        }
    }

    my $new_password = $xmlobj->child('new_password')
                     ? $xmlobj->child('new_password')->value
                     : '';
    my $crypt_password = $xmlobj->child('crypt_password')
                     ? $xmlobj->child('crypt_password')->value
                     : '';

    if ( $crypt_password && $vsap->{server_admin} ) {
        # Server admin can supply a pre-encrypted password
        $new_password = '';
        $crypt_password = VSAP::Server::Base::xml_unescape( $crypt_password );
    }
    else {
        # Make sure new password was passed in 
        unless( $new_password ) {
            $vsap->error( $_ERR{PW_NEW_MISSING} => q{New password not entered} );  
            return;
        }

        my $new_password2 = $xmlobj->child('new_password2')
                          ? $xmlobj->child('new_password2')->value
                          : '';

        # make sure new password was confirmed
        unless( $new_password eq $new_password2 ) {
            $vsap->error( $_ERR{PW_NEW_NOT_MATCH} => q{New passwords do not match}); 
            return;
        }

        $new_password = VSAP::Server::Base::xml_unescape( $new_password );
        $crypt_password = '';
    }

    my $sess_key = "";
  CHANGE_PASSWORD: {
        local $> = $) = 0;  ## regain privileges for a moment

        if ($vsap->is_linux()) {
            if (!$crypt_password) {
                my @saltChars = ('a'..'z','A'..'Z',1..9,'.','/');
                my $len = int rand 9;
                my $salt = '$1$';
                while ($len--) {
                    my $idx = int rand @saltChars;
                    $salt .= $saltChars[$idx];
                }
                $crypt_password = crypt($new_password, $salt);
            }
            system('usermod', '-p', $crypt_password, $username);
        } 
        else {
            my $hflag = $crypt_password ? 'H' : 'h';
            unless(open(PW, "| pw user mod -n $username -$hflag 0") ) {
                $vsap->error( $_ERR{PW_CHANGE_ERR} => qq{Could not execute pw: $!}); 
                VSAP::Server::Modules::vsap::logger::log_error("Could not execute pw: $!");
                return;
            }
            print PW $crypt_password || $new_password, "\n";
            close PW;
        }

        VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} changed password for user '$username'");

        # on success, need to reset the session key
        if ( $new_password ) {
            $vsap->{password} = $new_password;
            $sess_key = $username . ':' . VSAP::Server::Modules::vsap::auth::encrypt_key($vsap);
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'user:password:change');
    $root_node->appendTextChild(status => "ok");
    $root_node->appendTextChild('sessionkey' => $sess_key) if ($sess_key);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::user::password - VSAP extension for changing password

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::user::password;

=head1 DESCRIPTION

Blah blah blah.

=head1 SEE ALSO

L<Authen::PAM(3)>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
