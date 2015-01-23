#!/usr/bin/perl -w
use strict;

use blib;
use VSAP::Server::Modules::vsap::webmail::folders ();
use XML::LibXML;
use VSAP::Server::Base;

#######################################################
#######################################################
##                                                   ##
## This is an extreme hack for profiling this module ##
##                                                   ##
#######################################################
#######################################################

## set up a user
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    print STDERR "Creating user...\n";
    system( 'vadduser --quiet --login=joefoo --password=joefoobar --home=/home/joefoo --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joefoo'\n";

    print STDERR "Promoting user to SA...\n";
    system('pw', 'groupmod', '-n', 'wheel', '-m', 'joefoo');  ## make us an administrator
}

package Foo;
sub new   { return bless { }; }
sub child {
    my $self = shift;
    my $arg  = shift;
    if( $arg eq 'domain' ) {
        return '';
    }
    return;
}

sub children {
    my $self = shift;
    my $arg  = shift;

    return;
}

package main;
my $dom = XML::LibXML->createDocument('1.0' => 'UTF-8');
$dom->setDocumentElement($dom->createElement('vsap'));

print STDERR "Running loop...";
for (1..50) {
    VSAP::Server::Modules::vsap::webmail::folders::list::handler( { username => 'thursday',
                                                                    password => 'thurs123',
                                                                    server_admin => 1,
                                                                    _result_dom  => $dom },
                                                                  new Foo,
                                                                  $dom, );
}
print STDERR "done.\n";

exit;

END {
    print STDERR "Cleaning up...\n";
    getpwnam('joefoo')      && system q(vrmuser -y joefoo 2>/dev/null);
}
