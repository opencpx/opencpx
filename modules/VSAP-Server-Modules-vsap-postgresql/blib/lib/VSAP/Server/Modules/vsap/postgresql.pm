package VSAP::Server::Modules::vsap::postgresql;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::monitor;

our %_ERR =
(
    ERROR_PASSWORD_MISSING        => 100,
    ERROR_PASSWORD_MISMATCH       => 101,
    ERROR_PASSWORD_CHANGE_FAILED  => 102,
    ERROR_PERMISSION_DENIED       => 500,
);


##############################################################################

sub set_root_password {
    my $root_passwd = shift;

    local $> = $) = 0;  ## got rewt?

    my $is_installed = VSAP::Server::Modules::vsap::sys::monitor::_is_installed_postgresql();
    return(1) unless ($is_installed);

    ## stop postgresql
    if (-e "/sbin/service") {
        system("/sbin/service postgresql stop > /dev/null 2>&1");
    }
    else {
        system("/usr/local/etc/rc.d/postgresql stop > /dev/null 2>&1");
    }

    ## where does the conf file live?
    my $conf = (-e "/usr/local/pgsql/data/pg_hba.conf") ? 
                   "/usr/local/pgsql/data/pg_hba.conf" :   ## FreeBSD
                   "/var/lib/pgsql/data/pg_hba.conf";      ## Linux
    my $conf_backup = $conf . ".bak";

    ## backup the conf file
    open CNF, "<$conf";
    my @cnf = <CNF>;
    close CNF;
    rename($conf, $conf_backup);

    ## build new config to allow login without password
    my @newcnf;
    foreach my $line (@cnf) {

        if ($line =~ /^local\s+all\s+all\s+(reject|md5|password|gss|sspi|krb5|ident|pam|ldap|cert)/) {
            $line =~ s/reject|md5|password|gss|sspi|krb5|ident|pam|ldap|cert/trust/;
        }
        push @newcnf, $line;
    }

    ## write the changes
    open CNF, ">$conf";
    print CNF @newcnf;
    close CNF;

    ## start postgresql
    if (-e "/sbin/service") {
        system("/sbin/service postgresql start > /dev/null 2>&1");
    }
    else {
        system("/usr/local/etc/rc.d/postgresql start > /dev/null 2>&1");
    }

    # Be patient...(Part of what was causing HIC-914)
    sleep(3);
    
    ## create tmp file with command to change password
    my $tmpfile = "/tmp/pgsql-$$.tmp";
    open MYTMP, ">$tmpfile" or return($!);
    print MYTMP "ALTER USER Postgres WITH PASSWORD '$root_passwd'\n";
    close MYTMP;

    ## change the password
    my @command = ();
    push(@command, '/usr/bin/psql');
    push(@command, '-U');
    push(@command, 'postgres');
    push(@command, '-f');
    push(@command, "$tmpfile");
    system(@command) 
      and do {
          # fail!
          my $exit = ($? >> 8);
          VSAP::Server::Modules::vsap::logger::log_error("psql password change request failed (exitcode=$exit)");

          # Always restore config file...even on failure (HIC-914).
          rename($conf_backup, $conf);
          unlink($tmpfile);

          return($exit);
      };

    ## take a nap
    sleep(3);

    ## restore config file
    rename($conf_backup, $conf);
    unlink($tmpfile);

    ## restart
    if (-e "/sbin/service") {
        system("/sbin/service postgresql restart > /dev/null 2>&1");
    }
    else {
        system("/usr/local/etc/rc.d/postgresql restart > /dev/null 2>&1");
    }

    return(0);
}

##############################################################################

package VSAP::Server::Modules::vsap::postgresql::config;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    # check for server admin
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{ERROR_PERMISSION_DENIED} => "Not authorized");
        return;
    }

    # get the password
    my $passwd = ( $xmlobj->child('new_password') &&
                             $xmlobj->child('new_password')->value
                             ? $xmlobj->child('new_password')->value : '' );

    # get the password confirmation
    my $confirm_passwd = ( $xmlobj->child('confirm_password') &&
                             $xmlobj->child('confirm_password')->value
                             ? $xmlobj->child('confirm_password')->value : '' );

    # check for password
    unless ($passwd) {
        $vsap->error($_ERR{ERROR_PASSWORD_MISSING} => "Password missing");
        return;
    }

    # do the passwords match?
    my $passwords_match = ($passwd == $confirm_passwd);
    unless ($passwords_match) {
        $vsap->error($_ERR{ERROR_PASSWORD_MISMATCH} => "Password mismatch");
        return;
    }

    # set the postgresql root password
    my $fail = VSAP::Server::Modules::vsap::postgresql::set_root_password($passwd);
    if ($fail) {
        $vsap->error($_ERR{PASSWORD_CHANGE_FAILED} => "Change password failed: exitcode=$fail");
        return;
    }

    # build return dom
    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'postgresql:config');
    $root_node->appendTextChild(status => 'ok');
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VSAP::Server::Modules::vsap::postgresql -  VSAP helper module for managing postgreSQL

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::postgresql;

=head1 DESCRIPTION

=head2 set_root_password

Use to set the root password for the postgreSQL database.

=head1 AUTHOR

Rus Berrett

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
