package VSAP::Server::Modules::vsap::mail::addresses;

use 5.008004;
use strict;
use warnings;

use Email::Valid;
use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::mail;
use VSAP::Server::Modules::vsap::string::encoding;

our $VERSION = '0.01';

our %_ERR =
(
        PERMISSION_DENIED    => 100,
        EMAIL_INVALID        => 101,
        ADDRESS_EXISTS       => 200,
        USER_MISSING         => 201,
        DOMAIN_MISSING       => 202,
);
our $POSTFIX_INSTALLED = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postfix();

sub update_address {
    my $vsap_type = shift;
    my $vsap = shift;
    my $xml = shift;

    my $dom = $vsap->{_result_dom};

    my $sourceaddr = ($xml->child('sourceaddr') && $xml->child('sourceaddr')->value) ?  $xml->child('sourceaddr')->value : '';
    my $sourcedomain = ($xml->child('sourcedomain') && $xml->child('sourcedomain')->value) ?  $xml->child('sourcedomain')->value : '';
    my $source = ($xml->child('source') && $xml->child('source')->value) ? $xml->child('source')->value : '';
    my $dest = ($xml->child('dest') && $xml->child('dest')->value) ? $xml->child('dest')->value : '';
    my $type = ($xml->child('dest') && $xml->child('dest')->attribute('type')) ? $xml->child('dest')->attribute('type') : '';

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling $vsap_type");

    ## make backups as appropriate
    VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
    VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");

    if ($type eq "reject") {
        $dest = $POSTFIX_INSTALLED ? '"|exit 67"' : 'error:nouser User unknown';
    }
    elsif ($type eq "delete") {
        $dest = "dev-null";
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::check_devnull();
    }
    # 'source' allows for an entry as a single string, rather than user in one and
    # domain in another
    $source =~ /^([^@]*)(.+)$/ && do {
        $sourceaddr = $1;
        $sourcedomain = $2;
    };
    my $domain;
    ($domain = $sourcedomain) =~ s/^.*\@(\S+)/$1/;
    # check if user is admin for domain being added
    if ($vsap->{server_admin} || VSAP::Server::Modules::vsap::mail::is_admin($vsap->{username}, $domain)) {
        # check destination e-mail address(es) for validity
        my @addrs = grep { $_ } split(/\s*[\r\n,]+\s*/, $dest);
        foreach my $addr (@addrs) {
            next unless ($addr =~ /\@/);  # skip local delivery
            unless( Email::Valid->address( $addr ) ) {
                my $details = Email::Valid->details();
                $vsap->error($_ERR{EMAIL_INVALID} => $addr);
                return;
            }
        }
        if ($sourceaddr) {
            # check source e-mail address for validity
            unless( Email::Valid->address( $sourceaddr . $sourcedomain ) ) {
                my $details = Email::Valid->details();
                my $addr = $sourceaddr . $sourcedomain;
                $vsap->error($_ERR{EMAIL_INVALID} => $addr);
                return;
            }
        }
        # add/update the e-mail address
        my $rhs   = join(', ', @addrs) || 'dev-null';
        local $> = $) = 0;  ## regain privileges for a moment
        VSAP::Server::Modules::vsap::mail::add_entry($sourceaddr . $sourcedomain, $rhs);
        my $root_node = $dom->createElement('vsap');
        $root_node->setAttribute( type => $vsap_type );
        $root_node->appendTextChild("status","ok");
        $dom->documentElement->appendChild($root_node);
        return;
    }
    else {
        $vsap->error( $_ERR{PERMISSION_DENIED} => "Permission denied" );
        return;
    }
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::list;

sub handler {
    my $vsap = shift;
    my $xml = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'mail:addresses:list' );

    my $domain = ($xml->child('domain') && $xml->child('domain')->value) ?
         $xml->child('domain')->value : '';
    my $rhs = ($xml->child('rhs') && $xml->child('rhs')->value) ?
         $xml->child('rhs')->value : '';

    my $virtusertable = {};

  GET_DOMAINS: {
        local $> = $) = 0;  ## regain privileges for a moment

        # if domain was passed, use it
        if ($domain) {
            # if user is admin for that domain, allow it
            if ($vsap->{server_admin} ||
                VSAP::Server::Modules::vsap::mail::is_admin($vsap->{username}, $domain)) {
                $virtusertable = VSAP::Server::Modules::vsap::mail::domain_virtusertable($domain);
            }
        }
        elsif ($rhs) {
            # add genericstable entry
            my $uid = getpwnam($rhs);
            if (defined($uid)) {  # only do genericstable query if rhs is a valid username
                my $dest = VSAP::Server::Modules::vsap::mail::addr_genericstable( $rhs );
                $virtusertable->{$dest} = $rhs if ($dest);
            }
            # add virtusertable entries that point to user
            foreach my $address (@{VSAP::Server::Modules::vsap::mail::addr_virtusertable($rhs)}) {
                $virtusertable->{$address} = $rhs;
            }
            # add virtusertable entries that reference user
            my $reftable = VSAP::Server::Modules::vsap::mail::ref_virtusertable($rhs);
            foreach my $address (keys(%{$reftable})) {
                $virtusertable->{$address} = $reftable->{$address};
            }
        }
        else {
            if ($vsap->{server_admin}) {
                $virtusertable = VSAP::Server::Modules::vsap::mail::all_virtusertable();
            }
            else {
                # list for all domains for which user is an admin
                foreach my $ldomain (VSAP::Server::Modules::vsap::mail::list_domains($vsap->{username})) {
                    my $tmpusertable = VSAP::Server::Modules::vsap::mail::domain_virtusertable($ldomain);
                    %{$virtusertable} = (%{$virtusertable}, %{$tmpusertable});
                }
            }
        }
    }

    my $aliases;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $aliases = VSAP::Server::Modules::vsap::mail::all_aliastable();
    }

    my ($sourceval, $destval);
    while (($sourceval, $destval) = each %$virtusertable ) {
        my $alias = VSAP::Server::Modules::vsap::mail::make_alias($sourceval);
        if ($destval eq $alias) {
            $destval = $aliases->{$alias};
        }

        next unless (defined($destval) && $destval ne "");

        my $dest = $dom->createElement('dest');

        # if dest is dev-null ...
        if ($destval eq "dev-null") {
            $dest->setAttribute( type => 'delete' );
        }
        elsif ($destval =~ qr(^error:nouser\b)io) {
            # if dest is reject (nouser) ...
            $dest->setAttribute( type => 'reject' );
        }
        elsif ($destval =~ qr(^"\|exit 67"\b)io) {
            $dest->setAttribute( type => 'reject' );
        }
        elsif ($destval !~ /\@/) {
            # is this a local user, and not an alias?
            if ( (getpwnam($destval))[0] && ! $aliases->{$destval} ) {
                # the "local" dest type is used by the templates to make
                # local mailbox delivery more intuitive ...
                $dest->setAttribute( type => 'local' );
            }
            $dest->appendText( VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($destval) );
        }
        else {
            $dest->appendText( VSAP::Server::Modules::vsap::string::encoding::guess_string_encoding($destval) );
        }

        my $url_source = $sourceval;
        $url_source =~ s/([\\\|\#\%\&<>"' ])/uc sprintf("%%%02x",ord($1))/eg;

        my $address = new XML::LibXML::Element ("address");
        $address->appendTextChild( source => $sourceval );
        $address->appendTextChild( url_source => $url_source );
        $address->appendTextChild( source_mailbox => substr( $sourceval, 0, index($sourceval,'@') ) );
        $address->appendTextChild( source_domain  => substr( $sourceval, index($sourceval,'@')+1 ) );
        $address->appendChild($dest);
        $address->appendChild($dom->createElement('system')) ## append <system> element for system addrs
            if $sourceval =~ /^(?:postmaster|root|www|apache)?\@/;
        $root_node->appendChild($address);
    }

    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::add;

sub handler {
    return VSAP::Server::Modules::vsap::mail::addresses::update_address('mail:addresses:add', @_);
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::delete;

sub handler {
    my $vsap = shift;
    my $xml = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'mail:addresses:delete' );

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling mail:addresses:delete");

    ## make backups as appropriate
    VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
    VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");

    my @sources = $xml->children('source');
    foreach my $sourcenode (@sources)  {
        my $source = $sourcenode->value;

        my $sourceaddr;
        my $sourcedomain;
        $source =~ /^([^@]*)(.+)$/ && do {
            $sourceaddr = $1;
            $sourcedomain = $2;
        };
        my $domain;
        ($domain = $sourcedomain) =~ s/^.*\@(\S+)/$1/;
        # check if user is admin for domain being added
        if ($vsap->{server_admin} || VSAP::Server::Modules::vsap::mail::is_admin($vsap->{username}, $domain)) {
            local $> = $) = 0;  ## regain privileges for a moment
            VSAP::Server::Modules::vsap::mail::delete_entry($source);
            $root_node->appendTextChild("status","ok");
            $dom->documentElement->appendChild($root_node);
        }
        else {
            $root_node->appendTextChild("status","not ok");
            $dom->documentElement->appendChild($root_node);
        }
    }
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::update;

sub handler {
    return VSAP::Server::Modules::vsap::mail::addresses::update_address('mail:addresses:update', @_);
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::delete_user;

use VSAP::Server::Modules::vsap::config;

sub handler {
    my $vsap = shift;
    my $xml = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'mail:addresses:delete_user' );


    my $admin = ($xml->child('admin') && $xml->child('admin')->value) ?
         $xml->child('admin')->value : '';

    my @users   = ( $xml->children('user') )
                ? map { $_->value } $xml->children('user')
                : ();  

    unless ( $admin || @users ) {
        # need one of the other
        $vsap->error( $_ERR{USER_MISSING} => "User name required" );
        return;
    }

    ## make sure *this* vsap user has permissions to remove the address(es)
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );
    if ( @users ) {
        # removing addresses for a list of one or more users
        foreach my $user ( @users ) {
            unless ( defined(getpwnam($user)) ) {
                $vsap->error( $_ERR{USER_MISSING} => "User name does not exist!" );
                return;
            }
            my $authorized = 0;
            if ( $vsap->{server_admin} ) {
                $authorized = 1;
            }
            elsif ( $co->domain_admin($user) ) {
                $authorized = 1;
            }
            elsif ( $co->mail_admin ) {
                my $user_domain = $co->user_domain($vsap->{username});
                my @authuserlist = keys %{$co->users(domain => $user_domain)};
                if ( (grep(/^$user$/, @authuserlist)) &&
                     (!($co->domain_admin(admin => $user))) &&  ## mail admin cannot remove domain admin addresses
                     (!($co->mail_admin(admin => $user))) ) {   ## mail admin cannot remove another mail admin addresses
                    $authorized = 1;
                }
            }
            unless ($authorized) {
                # you're doing it wrong
                $vsap->error( $_ERR{PERMISSION_DENIED} => "Not authorized" );
                return;
            }
        }
    }
    else {
        # removing addresses for a domain admin; must be a server admin
        unless ( $vsap->{server_admin} ) {
            $vsap->error( $_ERR{PERMISSION_DENIED} => "Not authorized" );
            return;
        }
    }

    ## add a trace to the message log
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} calling mail:addresses:delete_user");

    ## make backups as appropriate
    VSAP::Server::Modules::vsap::mail::backup_system_file("aliases");
    VSAP::Server::Modules::vsap::mail::backup_system_file("virtusertable");

    ## FIXME: sometimes something here is undef and makes a boo-boo in the log
    if ( @users ) {
        foreach my $user ( @users ) {
            $co->init( username => $user);
            my $domain = $co->domain;
            local $> = $) = 0;  ## regain privileges for a moment
            VSAP::Server::Modules::vsap::mail::delete_user_domain($user, $domain);
        }
    }
    elsif ($admin) {
        foreach my $domain (keys %{$co->domains(admin => $admin)}) {
            local $> = $) = 0;  ## regain privileges for a moment
            VSAP::Server::Modules::vsap::mail::delete_user_domain($admin, $domain);
        }
    }

    $root_node->appendTextChild("status","ok");
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::mail::addresses::exists;

sub handler {
    my $vsap = shift;
    my $xml = shift;
    my $dom = shift || $vsap->{_result_dom};

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute( type => 'mail:addresses:exists' );

    my $source = ($xml->child('source') && $xml->child('source')->value) ?
         $xml->child('source')->value : '';
    my $domain = ($xml->child('domain') && $xml->child('domain')->value) ?
         $xml->child('domain')->value : '';

    if (!$domain) {
        $vsap->error( $_ERR{DOMAIN_MISSING} => "Domain name required" );
        return;
    }

    my $addr;
    $addr = $source . '@' . $domain if ($source);
    $addr = '@' . $domain if (!$source);

    my $chktable = {};
    my $exists = 0;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $chktable = VSAP::Server::Modules::vsap::mail::domain_virtusertable($domain);
    }
    foreach my $key (sort keys %$chktable) {
        if ($key =~ /^\Q$addr\E$/i) {
            $exists = 1;
            last;
        }
    }
    $root_node->appendTextChild('exists' => $exists);
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VSAP::Server::Modules::vsap::mail::addresses - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail::addresses;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for VSAP::Server::Modules::vsap::mail::addresses, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

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
