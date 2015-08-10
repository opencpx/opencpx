package VSAP::Server::Modules::vsap::apache;

use 5.008004;
use strict;
use warnings;

use Carp;
use Fcntl qw( :flock :DEFAULT );

use VSAP::Server::Modules::vsap::config;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR       = ( ERROR_PERMISSION_DENIED => 100 );

our $APACHECTL  = -e '/usr/sbin/apachectl' ? '/usr/sbin/apachectl' :
                                             '/usr/local/sbin/apachectl';

our $A2DISMOD   = '/usr/sbin/a2dismod';
our $A2ENMOD    = '/usr/sbin/a2enmod';

##############################################################################

sub loadmodule_debian
{
    my %args = @_;

    return unless $args{name};
    return unless $args{action};
    return unless ($args{action} =~ /^(?:enable|disable|add|delete)$/);

    if ($args{action} =~ /^(?:enable|add)$/) {
        return unless $args{module};
    }

    if ($args{action} =~ /^(?:delete|disable)/) {
        my @a2dismodcmd = ();
        push(@a2dismodcmd, $VSAP::Server::Modules::vsap::apache::A2DISMOD);
        push(@a2dismodcmd, $args{name});
        push(@a2dismodcmd, '> /dev/null 2>&1');
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            system(@a2dismodcmd);
        }
    }
    elsif ($args{action} =~ /^(?:add|enable)/) {
        my @a2enmodcmd = ();
        push(@a2enmodcmd, $VSAP::Server::Modules::vsap::apache::A2ENMOD);
        push(@a2enmodcmd, $args{name});
        push(@a2enmodcmd, '> /dev/null 2>&1');
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            system(@a2enmodcmd);
        }
    }
    else {
        ## unknown/invalid action
        return;
    }

    return(1);
}

# ----------------------------------------------------------------------------

sub loadmodule_default
{
    my %args = @_;

    return unless $args{name};
    return unless $args{action};
    return unless ($args{action} =~ /^(?:enable|disable|add|delete)$/);

    if ($args{action} =~ /^(?:enable|add)$/) {
        return unless $args{module};
    }

    open CONF, "+< $VSAP::Server::Modules::vsap::globals::APACHE_CONF"
      or do {
          carp "Could not open httpd.conf: $!\n";
          return;
      };

    flock CONF, LOCK_EX
      or do {
          carp "Could not lock httpd.conf: $!\n";
          return;
      };

    seek CONF, 0, 0;  ## rewind

    my @conf = ();

    if ($args{action} =~ /^(?:delete|disable)/) {
        local $_;
        while (<CONF>) {
            if (/loadmodule\s+$args{name}/i) {
                next if $args{action} eq 'delete';
                s/^(\s*LoadModule)/#$1/;
            }
            push @conf, $_;
        }
    }
    elsif ($args{action} =~ /^(?:add|enable)/) {
        my $last_lm  = 0;
        my $last_mod = 0;
        my $found    = 0;
        local $_;
        while (<CONF>) {
            push @conf, $_;
            next if $found;
            if ( /^\s*LoadModule\s+\Q$args{name}\E\s+\Q$args{module}\E/i) {
                $found = 1;
                next;
            }
            if ( /^\#*\s*LoadModule\s+\Q$args{name}\E\s+\Q$args{module}\E/i) {
                $last_mod = $#conf;
            }
            if ( /^\#*\s*LoadModule\s+/io) {
                $last_lm = $#conf;
            }
        }

        unless ($found) {
            if ($last_mod) {
                $conf[$last_mod] =~ s!\#*!!;
            }
            else {
                splice @conf, ($last_lm ? $last_lm+1 : 0), 0,
                  sprintf("LoadModule %-19s%s\n", $args{name}, $args{module});
            }
        }
    }
    else {
        ## unknown/invalid action
        close CONF;
        return;
    }

    seek CONF, 0, 0;  ## rewind
    print CONF @conf;
    truncate CONF, tell CONF;
    close CONF;
    return(1);
}

# ----------------------------------------------------------------------------

sub loadmodule
{
    my %args = @_;

    if ($VSAP::Server::Modules::vsap::globals::PLATFORM_DISTRO eq "debian") {
       return(loadmodule_debian(%args));
    }
    else {
       return(loadmodule_default(%args));
    }
}

##############################################################################

sub restart
{
    my $type = shift;

    return unless (($type eq "restart") || ($type eq "graceful"));
    VSAP::Server::Modules::vsap::logger::log_message("restarting apache ($type)");

    my @apachectlcmd = ();
    push(@apachectlcmd, $VSAP::Server::Modules::vsap::apache::APACHECTL);
    push(@apachectlcmd, $type);
    push(@apachectlcmd, '> /dev/null 2>&1');

  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        system(@apachectlcmd);
    }
}

##############################################################################

package VSAP::Server::Modules::vsap::apache::restart;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # need config for user
    my $co = new VSAP::Server::Modules::vsap::config( username => $vsap->{username} );

    # check permission
    if ($vsap->{server_admin} || $co->domain_admin) {
        # happy
        VSAP::Server::Modules::vsap::logger::log_message("apache restart required/requested (user='$vsap->{username}')");
    }
    else {
        # not happy
        $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
        return;
    }

    # do restart
    VSAP::Server::Modules::vsap::apache::restart('graceful');

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'apache:restart');
    $root_node->appendTextChild(status => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::apache - VSAP helper module for managing Apache config files

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::apache;
  blah blah blah

=head1 DESCRIPTION

=head2 loadmodule

Used to enable/disable/add/delete LoadModule lines in httpd.conf.

Example:

  loadmodule( name   => 'rewrite_module',
              module => 'libexec/mod_rewrite.so',
              action => 'enable' );  ## will add if necessary

  loadmodule( name   => 'rewrite_module',
              module => 'libexec/mod_rewrite.so',
              action => 'disable' );

  loadmodule( name   => 'rewrite_module',
              module => 'libexec/mod_rewrite.so',
              action => 'add' );

=head2 EXPORT

None by default.


=head1 SEE ALSO


=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
