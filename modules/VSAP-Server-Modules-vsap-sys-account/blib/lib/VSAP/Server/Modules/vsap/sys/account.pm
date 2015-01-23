package VSAP::Server::Modules::vsap::sys::account;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

##############################################################################

sub restart_service {
    my $vsap = shift;
    my $service = shift;

    local $> = $) = 0;  ## regain privileges for a moment

    # Restart the service only if it's already running
    $service = 'httpd' if $service eq 'apache';
    return unless system("/sbin/service $service status") == 0;

    # Apache is special, since we may be biting the CPX that feeds us
    if ($service eq 'httpd') {
        $vsap->need_apache_restart();
        return;
    }

    # XXX The logical way to do this is with a pipe, but I don't have the foo
    #     to reliably make perl not hang in that situation.
    my $temp = "/var/vsap/service.$$";
    if (system("/sbin/service $service restart >$temp 2>&1") == 0) {
        unlink $temp;
        return;
    }
    open my $tf, '<', $temp;
    my $out = join('', <$tf>);
    $out =~ s/\n/ /g;
    $out =~ s/ *$//;
    close $tf;
    unlink $temp;
    return $out
        ? "$service: $out"
        : "service $service restart: exit code $?";
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::account - VSAP module to do account stuff

=head1 SYNOPSIS

use VSAP::Server::Modules::vsap::sys::account;

=head1 DESCRIPTION

This module is used in lieu of some system calls to manage/configure account
stuff.

=head1 AUTHOR

Jamie Gritton

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
