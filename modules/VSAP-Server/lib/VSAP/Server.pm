package VSAP::Server;

=head1 NAME

VSAP::Server - Perl module comprising the server end of VSAP communications.

=head1 SYNOPSIS

  use VSAP::Server;

  my $server     = new VSAP::Server;

  $vsap_request  = "<some XML data></some XML data>";

  $vsap_response = $server->process_request($vsap_request);

=head1 DESCRIPTION

This is a server library to process VSAP requests. The main module,
VSAP::Server, parses, validates, and processes them, and returns data. The
server code itself (as well as any thread or forking implementations) is
external to this module.

The submodules VSAP::Server::XML and VSAP::Server::Modules::vsap::auth
perform parsing and authentication, respectively. Other modules under the
VSAP::Server::Modules namespace contain the actual functions called by
VSAP::Server, preferably organized by the VSAP XML namespace definitions.

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

##############################################################################

use 5.008001;
use strict;
use warnings;

require Exporter;
require AutoLoader;
our @ISA = qw(Exporter AutoLoader);

our $VERSION = '0.12';
our $RELEASE;

use Carp;
use Encode;
use IO::Socket;
use POSIX;
use Sys::Syslog;
use XML::LibXML;

use VSAP::Server::Modules;
use VSAP::Server::Modules::vsap::apache;
use VSAP::Server::XMLObj;

BEGIN {
    ($RELEASE = `cat /usr/local/cp/RELEASE`) =~ s/\s+$//;
}

##############################################################################

=head2 new()

    * VSAP::Server->new();
    * Param: none
    * Returns: a blessed VSAP::Server object.

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;

    $self->{_xml_parser} = XML::LibXML->new();
    $self->{logintime} = 0;

    my ($os, $osv) = (POSIX::uname())[0,2];
    $self->{_platform} = $os;
    $self->{_product} = $osv;
    if ($os =~ /Linux/i) {
        # Linux platform
        $self->{_linux} = 1;
    }
    elsif ($os =~ /FreeBSD/i) {
        # FreeBSD platform
        $self->{_freebsd} = 1;
    }
    else {
        # meh
    }

    $self->{_VERSION} = $VSAP::Server::VERSION;
    $self->{_RELEASE} = $VSAP::Server::RELEASE;

    return $self;
}

##############################################################################

=head2 authenticated()

    * $vsap->authenticated
    * Usage: $self->authenticated;
    * Return: true if this connection is authenticated, false otherwise.

=cut

sub authenticated
{
    my $self = shift;
    $self->{authenticated} || 0;
}

##############################################################################

=head2 disconnect()

    * $vsap->disconnect()
    * Param: none
    * Return: true if the server should disconnect.

=cut

sub disconnect
{
    my $self = shift;
    return $self->{disconnect};
}

##############################################################################

=head2 dom()

    * $vsap->dom
    * Param: none
    * Returns: The XML::LibXML::Document element being used in this request.

=cut

sub dom
{
    my $self = shift;

    $self->{_result_dom};
}

##############################################################################

=head2 error()

    * $vsap->error($code, "Message", "Extra info");
    * Param: error code <IN>, error message <IN>, extra information <IN>
    * Return: Nothing.
    * Notes: Places an vsap error response into the _result_dom.

=cut

sub error
{
    my $self = shift;
    my $errorcode = shift;
    my $errormsg = shift || "";
    my $extradata = shift || "";
    my $package;

    my $type = '';
    my $i = 0;
    while (($package) = caller($i)) {
        if ($package eq "VSAP::Server") {
            ($package) = (caller($i - 1));
            last unless $package;
            $package =~ /^VSAP::Server::Modules::vsap::(.*)$/;
            ($type = $1) =~ s/::/:/g;
            last;
        }
        $i++;
    }

    my $error_node = $self->{_result_dom}->createElement('vsap');
    $error_node->setAttribute('type' => 'error');
    $error_node->setAttribute('caller' => $type);
    $error_node->appendTextChild(code => $errorcode);
    $error_node->appendTextChild(message => $errormsg);
    $error_node->appendTextChild(info => $extradata) if ($extradata);
    $self->{_result_dom}->documentElement->appendChild($error_node);
}

##############################################################################

=head2 greet()

    * $vsap->greet()
    * Param: none.
    * Return: A string containing the initial vsap response sent to a connecting client.

=cut

sub greet
{
    my $self = shift;

    my $hostname = `/bin/hostname -f 2>/dev/null` || (POSIX::uname())[1];
    $hostname =~ tr/\0\r\n//d;
    return "<vsap>\n" .
           "  <server>VSAP</server>\n" .
           "  <status>OK</status>\n" .
           "  <hostname>$hostname</hostname>\n" .
           "  <authscheme>plaintext</authscheme>\n" .
           "  <version>$VSAP::Server::VERSION</version>\n" .
           "  <release>$VSAP::Server::RELEASE</release>\n" .
           "</vsap>\n";
}

##############################################################################

=head2 is_linux()

    * Returns true if the OS is Linux (any distro)

=cut

sub is_linux
{
    exists($_[0]->{_linux});
}

##############################################################################

=head2 is_freebsd()

    * Returns true if the OS is FreeBSD (any version)

=cut

sub is_freebsd
{
    exists($_[0]->{_freebsd});
}

##############################################################################

=head2 log()

     * $vsap->log($priority, $message)
     * Param: $priority <IN> A syslog priority, info, debug, error, etc. See syslog(3)
     * Param: $message <IN>
     * Notes: Will log a message to syslog at the appropriate priority.
     *        Is backwards compatiable with the $vsap->log($message) usage.

=cut

sub log
{
    my $self = shift;
    my $priority = shift;
    my $message = shift;

    # in the absence of a priority, assume 'notice'
    unless ($priority =~ /^(?:emerg|alert|crit|err|warning|notice|info|debug)$/) {
        $message = $priority;
        $priority = 'notice';
    }
    syslog($priority, '%s', Encode::encode_utf8($message));
}

##############################################################################

=head2 need_apache_restart()

    * Marks the need to restart Apache after the request is finished,
      either by the client (if local) or the server itself.

=cut

sub need_apache_restart
{
    $_[0]->{_need_apache_restart} = 1;
}

##############################################################################

=head2 platform()

    * $vsap->platform
    * Param: none
    * Returns: the OS platform

=cut

sub platform
{
    my $self = shift;

    $self->{_platform};
}

##############################################################################

=head2 process_request()

    * $vsap->process_request("<vsap>...</vsap>")
    * Param:  The vsap content to be parsed.
    * Return: The response from the vsap server or undef on error.
    * Notes:  This calls the vsap handles which are referenced by the incomming XML data. This
    *         will setup the _result_dom and the value of that result_dom is returned as a string.

=cut

sub process_request
{
    my $self = shift;
    my $content = shift;

    my $parser = $self->{_xml_parser};

    delete $self->{_result_dom};

    # instantiate a DOM to carry the result in
    $self->{_result_dom} = XML::LibXML::Document->createDocument('1.0', 'UTF-8');
    $self->{_result_dom}->setDocumentElement($self->{_result_dom}->createElement('vsap'));

    my $xmlobj;
    if (ref($content) =~ /^XML\:\:LibXML/) {
        my $dom = XML::LibXML::Document->new("1.0", "UTF-8");
        $dom->setDocumentElement($content);
        $xmlobj = new VSAP::Server::XMLObj($dom);
    }
    else {
        $xmlobj = new VSAP::Server::XMLObj(XML => $content);
    }

    my @vsap_calls = $xmlobj->child("vsap")->children;

    # each child <vsap/>
    foreach my $vsap (@vsap_calls) {
        $self->log('debug', "calling process_request_internal: " . $vsap->attribute('type') || 'unknown type');
        $self->process_request_internal($vsap, $self->{_result_dom});
        $self->log('debug', "finished process_request_internal: " . $vsap->attribute('type') || 'unknown type');
        # does apache need to be restarted as a results of the request?
        if ($self->{_need_apache_restart}) {
            my $lc = $self->{_result_dom}->getLastChild;
            if ($lc) {
                $lc = $lc->getLastChild;
                $lc->appendTextChild(need_apache_restart => 1) if ($lc);
            }
        }
    }

    if (ref($content) =~ /^XML\:\:LibXML/) {
        return $self->{_result_dom};
    }
    else {
        return $self->{_result_dom}->toString(1);
    }
}

##############################################################################

=head2 process_request_internal()

    * $vsap->process_request_internal($vsap_obj);
    * Param: the VSAP::Server::XMLObj object which represents a <vsap type='..'> call.
    * Param: the result dom used to return results from vsap handlers.
    * Returns: nothing.

    This method is used to process a specific vsap request.

=cut

sub process_request_internal
{
    my $self = shift;
    my $vsap_element = shift;
    my $dom = shift;

    my $evalns = "vsap";
    my $type = $vsap_element->attribute("type") || '';

    # We explicitly disallow anything but [a-zA-Z0-9:_] in the namespace
    unless (($evalns =~ /^[a-zA-Z0-9:_]+$/) && ($type =~ /^[a-zA-Z0-9:_]+$/)) {
        $self->{disconnect} = 1;
        return undef;
    }

    $evalns    =~ s/\:/\:\:/g;
    $type      =~ s/\:/\:\:/g;

    # call the subroutine in the namespace indicated
    my $code_path = "VSAP::Server::Modules::" . $evalns . "::" . $type . "::handler";
    no strict "refs";
    my $ref = *{$code_path}{CODE};
    &{$ref}($self, $vsap_element, $dom);
}

##############################################################################

=head2 product()

    * $vsap->product
    * Param: none
    * Returns: the "product" identifier of the platform

=cut

sub product
{
    my $self = shift;

    $self->{_product};
}

##############################################################################

=head2 release()

    * $vsap->release
    * Param: none
    * Returns: release tag of the opencpx software

=cut

sub release
{
    my $self = shift;

    $self->{_RELEASE};
}

##############################################################################

=head2 version()

    * $vsap->version
    * Param: none
    * Returns: version of the vsapd server

=cut

sub version
{
    my $self = shift;

    $self->{_VERSION};
}

##############################################################################

=head2 xml()

    * $vsap->xml
    * Param: none
    * Returns: The XML::LibXML object contained within this VSAP::Server object.

=cut

sub xml
{
    my $self = shift;

    $self->{_xml_parser};
}

##############################################################################

=head2 DESTROY()

    * $vsap->DESTROY
    * Param: none
    * Return: nothing.

=cut

sub DESTROY {
    my $self = shift;

    undef $self;
}

##############################################################################

1;
__END__
