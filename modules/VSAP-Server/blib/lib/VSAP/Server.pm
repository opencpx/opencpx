package VSAP::Server;

use 5.008001;  ## for Encode
use strict;
use vars qw($CVS_VERSION $VERSION $RELEASE $LOGFILE $AUTHSCHEME @ISA @EXPORT @EXPORT_OK $AUTHEXPIRE);
use IO::Socket;
use Sys::Hostname;
use Sys::Syslog;
use Carp;
use Encode;
use XML::LibXML;

use VSAP::Server::Modules;
use VSAP::Server::Modules::vsap::apache;
use VSAP::Server::Util;

BEGIN {
    eval { require VSAP::Server::LDAP };
    use POSIX('uname');
    # Handle VPS and Signature.
    if (-d '/usr/local/vwh') {
        # Signature product
        eval 'exec qq(/usr/local/bin/perl5.8.4 -w $0 @ARGV)'
            unless $^V ge v5.8.4;
        $RELEASE = '2.0';  ## made this up.  --rus.
    } 
    else {
        # VPS product
        eval 'exec qq(/usr/bin/perl -w $0 @ARGV)'
            unless $^V ge v5.8.4;
        my @vendor = grep {   m!/vendor_perl! } @INC;
        @INC       = grep { ! m!/vendor_perl! } @INC;
        my $i = 0; for ( @INC ) { last if m!/site_perl!; $i++ }
        splice @INC, $i, 0, @vendor;
        ($RELEASE = `cat /usr/local/cp/RELEASE`) =~ s/\s+$//;
    }
}

use VSAP::XMLObj;
use Data::Dumper;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
$VERSION = '0.5';
$AUTHSCHEME = 'plaintext';
$AUTHEXPIRE = 7200;

=pod 

=head1 NAME

VSAP::Server - Perl module comprising the server end of VSAP communications.

=head1 SYNOPSIS

  use VSAP::Server;

  my $server     = new VSAP::Server;

  $vsap_request = ... somehow read some XML data which represents an vsap request ... 

  $vsap_response = $server->process_request($vsap_request);

=head1 DESCRIPTION

This is a server library to process VSAP requests. The main module, VSAP::Server, parses, 
validates, and processes them, and returns data. The server code itself (as well as any 
thread or forking implementations) is external to this module.

The submodules VSAP::Server::XML and VSAP::Server::Modules::vsap::auth perform parsing and 
authentication, respectively. Other modules under the VSAP::Server::Modules namespace 
contain the actual functions called by VSAP::Server, preferably organized by 
the VSAP XML namespace definitions. Standards for these modules are described 
in the VSAP::Server::Proto dummy module, which outlines a framework for 
easily implementing extensions to the VSAP server.

=head1 AUTHOR

Dan Brian E<lt>dbrian@improvist.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.
  
=cut

#----------------------------------------------------------------------------------------------------

=head2 new()

    * VSAP::Server->new();
    * Param: none
    * Returns: a blessed VSAP::Server object.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->{_xml_parser} = XML::LibXML->new();
    $self->{logintime} = 0;

    my $os = (POSIX::uname())[0];
    if ($os =~ /Linux/i) {
        # Linux platform
        $self->{_linux} = 1; 
        # determine product
        if (-d '/usr/local/vwh') {
            # Signature product
            $self->{_signature} = 1;
        }
        else {
            $self->{_vps} = 1;
            if (-d '/var/vsap') {
                $self->{_cloud} = 1;
            }
        }
    }
    else {
        # FreeBSD platform
        my $version = (POSIX::uname())[2];
        if ($version =~ /^6/) {
            if (-d '/skel/usr/local/apache2') {
                $self->{_freebsd6} = 1;
            }
            else {
                $self->{_freebsd4} = 1;
            }
        }
        else {
            $self->{_freebsd4} = 1;
        }
        if (-d '/usr/local/vwh') {
            # Signature product
            $self->{_signature} = 1;
        }
        else {
            $self->{_vps} = 1;
        }
    }

    return $self;
}

=head2 greet()

    * $vsap->greet()
    * Param: none. 
    * Return: A string containing the initial vsap response sent to a connecting client. 

=cut

sub greet {
    my $self = shift;
    undef $Sys::Hostname::host;
    my $hostname = Sys::Hostname::hostname;
    return "<vsap>\n" .
            "  <server>VSAP</server>\n" .
            "  <status>OK</status>\n" .
            "  <hostname>$hostname</hostname>\n" . 
            "  <authscheme>plaintext</authscheme>\n" .
            "  <version>$VSAP::Server::VERSION</version>\n" .
            "  <release>$VSAP::Server::RELEASE</release>\n" .
           "</vsap>\n";
}

=head2 xml()

    * $vsap->xml
    * Param: none
    * Returns: The XML::LibXML object contained within this VSAP::Server object. 

=cut

sub xml {
    my $self = shift;
    $self->{_xml_parser};
}

=head2 dom()

    * $vsap->dom
    * Param: none
    * Returns: The XML::LibXML::Document element being used in this request. 

=cut

sub dom { 
    my $self = shift;

    $self->{_result_dom};
}

=head2 prefs()

    * $vsap->prefs('name');
    * Param: none
    * Return: The value of the preference given by 'name'.

=cut

sub prefs {
    my $self = shift;
    my $prefname = shift;
    unless (defined $self->{prefs}) {
        VSAP::Server::Modules::vsap::server::users::prefs::getPrefs($self);
    }
    return ${$self->{prefs}}{$prefname};
}

=head2 tmp_prefs()

    * $vsap->tmp_prefs('name');
    * Param: none
    * Return: The value of the temporary preference given by 'name'.

=cut

sub tmp_prefs {
    my $self = shift;
    my $prefname = shift;
    return VSAP::Server::Modules::vsap::server::users::prefs::getTmpPrefs($self,$prefname);
}

=head2 ldap()

    * $vsap->ldap
    * Param: none
    * Return: Return the VSAP::Server::LDAP::ldap object contained in this VSAP::Server object.

=cut

sub ldap {
    my $self = shift;
    $self->{ldap} || ( $INC{'VSAP/Server/LDAP.pm'} ? VSAP::Server::LDAP::ldap($self) : undef );
}

=pod

    Method: authenticate
    Usage: $self->authenticate; 
    Purpose: To authenticate the given connection. 
    Returns: the value of authenticated or the return of the auth::authenticate method. 

=cut

=head2 authenticate()

    * $vsap->authenticate
    * Param: none
    * Return: Authenticate the current connection. 

=cut

sub authenticate {
    my $self = shift;
    $self->{authenticated} || VSAP::Server::Modules::vsap::auth::authenticate($self);
}

=head2 authenticated()

    * $vsap->authenticated
    * Usage: $self->authenticated; 
    * Return: true if this connection is authenticated, false otherwise. 

=cut

sub authenticated {
    my $self = shift;
    $self->{authenticated} || 0;
}


=head2 process_request_internal()
    * $vsap->process_request_internal($vsap_obj);
    * Param: the VSAP::XMLObj object which represents a <vsap type='..'> call.
    *      : the result dom used to return results from vsap handlers.  
    * Returns: nothing. 

    This method is used to process a specific vsap request. 
=cut

sub process_request_internal {
    my $self = shift;
    my $vsap_element = shift; 
    my $dom = shift;

    my $evalns = "vsap";
    my $type = $vsap_element->attribute("type") || '';
    
    # We explicitly disallow anything but [a-zA-Z0-9:_] in the namespace
    unless( $evalns =~ /^[a-zA-Z0-9:_]+$/ && $type =~ /^[a-zA-Z0-9:_]+$/ ) {
        $self->{disconnect} = 1;
        return undef;
    }

    $evalns    =~ s/\:/\:\:/g;
    $type      =~ s/\:/\:\:/g;

    # This block calls the subroutine in the namespace indicated 
    # by any XML elements in the command that do not have parents 
    # (top-level elements).

    # We enforce authentication here, in order to prevent mishaps in 
    # custom modules. To disable the authentication check for a 
    # custom module (don't), the scalar $NO_AUTH must be set to true 
    # within that module.

    my $evaling = 0;
    my $evaled;
    
    if ($evaling == 0) {

        my $code_path = "VSAP::Server::Modules::" . $evalns . "::" . $type . "::handler";
        no strict "refs";
        my $ref = *{$code_path}{CODE};
        $evaled = &{$ref}($self, $vsap_element, $dom);

    } 
    else {

      my $evaling = qq{
        if (\*VSAP\:\:Server\:\:Modules\:\:$evalns\:\:$type\:\:handler{CODE}) {
          if (\$VSAP\:\:Server\:\:Modules\:\:$evalns\:\:$type\:\:NO_AUTH) {
            VSAP\:\:Server\:\:Modules\:\:$evalns\:\:$type\:\:handler(\$self,\$vsap_element,\$dom);
          } else {
            if (\$self->{authenticated}) {
              VSAP\:\:Server\:\:Modules\:\:$evalns\:\:$type\:\:handler(\$self,\$vsap_element,\$dom);
            } else {
              \$self->error('401','UNAUTHORIZED');
              return 0;
            }
          }
        } 
        elsif (\*VSAP\:\:Server\:\:Modules\:\:$evalns\:\:handler{CODE}) {
          if (\$VSAP\:\:Server\:\:Modules\:\:$evalns\:\:NO_AUTH) {
            VSAP\:\:Server\:\:Modules\:\:$evalns\:\:handler(\$self,\$vsap_element,\$dom);
          } else {
            if (\$self->authenticated) {
              VSAP\:\:Server\:\:Modules\:\:$evalns\:\:handler(\$self,\$vsap_element,\$dom);
            } else {
              \$self->error('401','UNAUTHORIZED');
              return 0;
            }
          } 
        } 
        else {
          \$self->error('403','No such module $evalns\:\:$type');
          return 0;
        }
      };

    # If the handler() in the given namespace doesn't exist, we 
    # return an unauthorized error rather than a "doesn't exist"
    # to conceal as much as possible about the namespace structure.

    # This is a secure 'eval' for the following reasons:
    #  1) it gets $evalns, the only user variable in the eval code, 
    #    from a top-level XML namespace which is parsed AS XML 
    #  2) $evalns is allowed only after a test of inclusion, rather than
    #    exclusion, of the values [a-zA-Z0-9:_]
    #  3) it tests to find a module of namespace $evalns within this 
    #     program before executing the code
    #  4) the subroutine named 'handler' is not executed unless the 
    #     client has authorized previously
    #  5) if no subroutine named 'handler' exists in the namespace, an
    #     error is returned with no further executed code

      $evaled = eval $evaling;
    # if a string is returned, attempt to parse it and add it to _result_dom
    # This is to handle legacy modules which doesn't update _result_dom themselves.

    }

    if ($evaled) {
        $self->log('warning',"module $evalns::$type returned xml which needed to be parsed, please convert this to use the dom.");
        my $evaled_chunk;
        my $parser = $self->{_xml_parser};
        eval { $evaled_chunk = $parser->parse_balanced_chunk($evaled); };
        if ($@) {
            $self->error('101', 'Parse Error');
            return;
        }
        $self->{_result_dom}->documentElement->appendChild($evaled_chunk);
    }
    die $@ if ($@);
}

=head2 process_request()

    * $vsap-process_request("<vsap>...</vsap>")
    * Param: The vsap content to be parsed. 
    * Return: The response from the vsap server or undef on error. 
    * Notes: This calls the vsap handles which are referenced by the incomming XML data. This 
            will setup the _result_dom and the value of that result_dom is returned as a string.

=cut

sub process_request {
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
        $xmlobj = new VSAP::XMLObj ($dom);
    } 
    else {
        $xmlobj = new VSAP::XMLObj (XML => $content);
    }

    my @vsap_calls = $xmlobj->child("vsap")->children;

    # each child <vsap/>
    foreach my $vsap (@vsap_calls) { 
        $self->log('debug',"calling process_request_internal: ".$vsap->attribute('type') || 'unknown type');
        $self->process_request_internal($vsap,$self->{_result_dom});
        $self->log('debug',"finished process_request_internal: ".$vsap->attribute('type') || 'unknown type');
        if ($self->{_need_apache_restart} && $self->is_cloud) {
            my $lc = $self->{_result_dom}->lastChild;
            if ($lc) {
                $lc = $lc->lastChild;
                $lc->appendTextChild(need_apache_restart =>
                                     delete $self->{_need_apache_restart})
                    if $lc;
            }
        }
    }
    if ($self->{_need_apache_restart}) {
        VSAP::Server::Modules::vsap::apache::restart('graceful');
        delete $self->{_need_apache_restart};
    }

    if (ref($content) =~ /^XML\:\:LibXML/) {
        return $self->{_result_dom};
    } 
    else {
        return $self->{_result_dom}->toString(1);
    }
}

=head2 log()

     * $vsap->log($priority, $message)
     * Param: $priority <IN> A syslog priority, info, debug, error, etc. See syslog(3)
     * Param: $message <IN>
     * Notes: Will log a message to syslog at the appropriate priority.
     *        Is backwards compatiable with the $vsap->log($message) usage.

=cut

sub log {
    my $self = shift;
    my $priority = shift;
    my $message = shift;

    # Handle the old case where you just log a message.
    unless ($priority =~ /^(?:emerg|alert|crit|err|warning|notice|info|debug)$/) {
        $message = $priority;
        $priority = 'notice';
    }
    syslog($priority,'%s',Encode::encode_utf8($message));
}


=head2 error()

    * $vsap->error($code,"Message","Extra info");
    * Param: error code <IN>, error message <IN>, extra information <IN> 
    * Return: Nothing. 
    * Notes: Places an vsap error response into the _result_dom. 

=cut

sub error {
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
    $error_node->appendTextChild(base => ( $INC{'Digest/Elf.pm'} ? Digest::Elf::elf($type) : 0 ));
    $self->{_result_dom}->documentElement->appendChild($error_node);
}

=head2 disconnect()

    * $vsap->disconnect()
    * Param: none
    * Return: true if the server should disconnect. 

=cut

sub disconnect {
    my $self = shift;
    return $self->{disconnect};
}

=head2 need_apache_restart()

    * Marks the need to restart Apache after the request is finished,
      either by the client (if local and cloud) or the server.

=cut

sub need_apache_restart {
    $_[0]->{_need_apache_restart} = 1;
}

=head2 is_linux()

    * Returns true if the OS is Linux.

=cut

sub is_linux {
    exists($_[0]->{_linux});
}

=head2 is_freebsd6()

    * Returns true if the OS is FreeBSD 6.x.

=cut

sub is_freebsd6 {
    exists($_[0]->{_freebsd6});
}

=head2 is_freebsd4() 

    * Returns true if the OS is FreeBSD 4.x.

=cut 

sub is_freebsd4 {
    exists($_[0]->{_freebsd4});
}

=head2 is_freebsd() 

    * Returns true if the OS is FreeBSD (any version)

=cut 

sub is_freebsd {
    exists($_[0]->{_freebsd4}) || exists($_[0]->{_freebsd6});
}

=head2 is_signature()

    * Returns true if the platform is Signature. This is determined using the 
      presence of a /usr/local/vwh directory. If this criteria changes, then
      the test should be updated accordingly.  See the constructor.

=cut

sub is_signature {
    exists($_[0]->{_signature});
}

=head2 is_vps()

    Returns true if the platform is VPS (VPSv2, VPSv3, or VPS-Linux). This is
    determined using the absence of the /usr/local/vwh directory (which will
    only be present on a signature box); if this criteria changes, so should
    the test. See the constructor for VSAP::Server for that code.

=cut 

sub is_vps {
    exists($_[0]->{_vps});
}

=head2 is_cloud()

    Returns true if the platform is Cloud(n). This is determined using the 
    presense of the /var/vsap directory (which will only be present on a 
    cloud account); if this criteria changes, so should the test. See the 
    constructor for VSAP::Server for that code.

=cut 

sub is_cloud {
    exists($_[0]->{_cloud});
}

=head2 DESTROY()

    * $vsap->DESTROY
    * Param: none
    * Return: nothing. 

=cut

sub DESTROY {
    my $self = shift;
    # FIXME What is "m"? 
    if ($self->{m}) { $self->{m}->close; }
    if ($self->{ldap}) { $self->{ldap}->unbind; }
    delete $self->{m};
    delete $self->{ldap};
    undef $self;
}

1;
__END__
