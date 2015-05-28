package VSAP::Client;

=head1 NAME

VSAP::Client - VSAP client object

=head1 SYNOPSIS

  use VSAP::Client;

  # INET mode.
  $client = VSAP::Client->new( mode => 'tcp', Hostname => 'somehost', PeerPort => 551);

  # Unix domain socket mode.
  $client = VSAP::Client->new( mode => 'unix', Socket => '/var/run/vsapd.sock');

  # Mode/Options determined by VSAP::Client::Config
  $client = VSAP::Client->new();

  # Convert to an SSL connection.
  $client->starttls()
        or die "TLS negotiation failed.";

  my $sessionkey = $client->authenticate('user','password','hostname');

  unless ($sessionkey)
        die "Unable to authenticate: ". $client->response->toString;

  $response = $client->send("<vsap> <vsap type='some:vsap:module'> <some_vsap_xml/> </vsap> </vsap>");

  unless ($response)
        die "Unable to send request. ";
 
  if ($response->toString =~ (/some valid response/)) {
        # We got a valid response;
  }
  else {
        # We got some invalid response.
  }

  # Let us shut it down now.
  $client->quit;

=head1 DESCRIPTION

Provides client acccess to the vsap server.  The default configuration options will
come from the VSAP::Client::Config module.

=head1 SEE ALSO

VSAP(1), VSAP::Server(3), VSAP::Client::Config(3)

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

##############################################################################

use 5.006001;
use strict;
use warnings;

our @ISA = ();

our $VERSION = '0.12';

use utf8;
use Carp;
use IO::Socket;
use Net::SSLeay;
use Text::Iconv;
use XML::LibXML;

use VSAP::Client::Config qw($VSAP_CLIENT_MODE $VSAP_CLIENT_SSL);

my %debug = ();

our $SSL_CERT_FILE = ".cpx/client.crt";
our $SSL_KEY_FILE  = ".cpx/client.key";

##############################################################################

=head1 Methods

=head2 new()

    * VSAP::Client->new( mode => 'tcp', option2 => 'value', option3 => 'value');)
    * Param: key value pairs which are dependant on the value of mode.
    * Return: A blessed object either VSAP::Client::UNIX, VSAP::Client::INET

=cut

sub new
{
    my $pkg = shift;
    my %arg = @_;
    my $client;

    my $mode = (defined($arg{mode}) ? $arg{mode} : $VSAP_CLIENT_MODE);

    if ($mode eq "tcp") {
        use VSAP::Client::INET;
        $client = VSAP::Client::INET->new(@_);
    } 
    elsif ($mode eq "unix") {
        use VSAP::Client::UNIX;
        $client = VSAP::Client::UNIX->new(@_);
    }

    $client->autoflush(1);
    $client->debug(exists $arg{Debug} ? $arg{Debug} : undef);

    if (defined $arg{ssl} ? $arg{ssl} : $VSAP_CLIENT_SSL) {
        &negotiate_tls($client)
            or return;
    }

    $client->parse_response;

    # Rather than put this through an XML parser to strip the elements we
    # manually strip them and encapsulate their values.
    $client->_strip_response;

    return $client;
}

##############################################################################

=head2 _strip_response

    * $client->_strip_response;
    * Param: none
    * Return: none.

    Method used to parse and strip the response contained in this object. Extracts certain
    information from the response and places it in various class variables. Parses either
    the greeting and/or authentication response.

=cut

sub _strip_response
{
    my $client = shift;

    my $response = $client->response->toString;

    if ($response =~ m|^<vsap>\s*<server>([^<]+)</server>\s*
                           <status>([^<]+)</status>\s*
                           <hostname>([^<]+)</hostname>\s*
                           <authscheme>([^<]+)</authscheme>\s*
                           <version>([^<]+)</version>\s*
                           <release>([^<]+)</release>\s*</vsap>\s*|sx) {
        # Server greeting
        ${*$client}{'vsap_server'}     = $1;
        ${*$client}{'vsap_status'}     = $2;
        ${*$client}{'vsap_hostname'}   = $3;
        ${*$client}{'vsap_authscheme'} = $4;
        ${*$client}{'vsap_version'}    = $5;
        ${*$client}{'vsap_release'}    = $6;
    }
    elsif ($response =~ m|\s*<vsap\s+type="auth">\s*
                           <username>([^<]+)</username>\s*
                           <sessionkey>([^<]+)</sessionkey>\s*
                           <platform>([^<]+)</platform>\s*
                           <product>([^<]+)</product>\s*
                           .*?
                           </vsap>\s*|sx) {
        # Authentication info
        ${*$client}{'username'}        = $1;
        ${*$client}{'sessionkey'}      = $2;
        ${*$client}{'authenticated'}   = 1;
        ${*$client}{'platform'}        = $3;
        ${*$client}{'product'}         = $4;
   }
   else {
       # Errors(?)
   }
}

##############################################################################

=head2 authenticate()

    * $client->authenticate()
    * Param: username, password, hostname all scalars.
    * Return: The session key from the authentication response.

    Method used to send an 'auth' request to vsap. A session key is returned.

=cut

sub authenticate
{
    my($client,$user,$pass,$hostname) = @_;

    my $vsapcmd;
    $vsapcmd =  "<vsap><vsap type='auth'>\n";
    $vsapcmd .= "  <username>$user</username>\n";
    $vsapcmd .= "  <password>$pass</password>\n" if $pass;
    $vsapcmd .= "  <hostname>$hostname</hostname>\n" if ($hostname);
    $vsapcmd .= "</vsap></vsap>\n";

    ${*$client}{'auth_data'} = $vsapcmd;
    $client->command($vsapcmd);
    $client->parse_response;
    # strip out what we want some key variables
    $client->_strip_response;
    return $client->sessionkey;
}

##############################################################################

=head2 authenticated()

    * $client->authenticated()
    * Param: none
    * Return: True if the connection is authenticated.

    Method to return true/false depending on whether or not this client connection
    is authenticated.

=cut

sub authenticated
{
    my $client = shift;
    ${*$client}{'authenticated'} || 0;
}

##############################################################################

=head2 authscheme()

    * $client-authscheme
    * Param: none
    * Return: The authscheme returned by the VSAP greeting.

    Obtain the value of authscheme as obtained by the VSAP greeting.

=cut

sub authscheme
{
    my $client = shift;
    ${*$client}{'vsap_authscheme'};
}

##############################################################################

=head2 command()

    * $client->command("<vsap>...</vsap>");
    * Params: The vsap request which is sent to the server.
    * Return: true if the command was successfully sent, false otherwise.

    This method simply writes the data to the connection after doing some newline processing. If unable
    to write the fully request, the connection will be closed and undef will be returned. If the connection
    is not currently opened, undef will be returned. If a SIGPIPE is received undef will be returned. If undef
    is returned, it is safe to assume that the connection is in an inconsistent state and a new connection should
    be made.

    Don't use this method, use C<send()> instead as it automatically processes and returns the response.

=cut

sub command
{
    my $client = shift;

    return undef
        unless ($client->opened);

    binmode $client, ":utf8";
    #binmode $client, ":encoding(utf8)";

    if (scalar(@_)) {
        local $SIG{PIPE} = sub { die "sigpipe"; };
        my $str =  join(" ", map { /\n/ ? do { my $n = $_; $n =~ tr/\n/ /; $n } : $_; } @_) . "\015\012";
        my $len = length $str;
        my $bytes_written = 0;

        eval {
            while ($bytes_written < $len) {

                my $wrote = ${*$client}{ssl}
                    ? Net::SSLeay::ssl_write_all(${*$client}{ssl}, $str)
                    : syswrite($client,$str,$len,$bytes_written);
                if (!defined($wrote)) {
                    $client->close;
                    return undef;
                }

                $bytes_written += $wrote;
            }
        };

        if ($@) {
            # Must of gotten a SIG{PIPE}
            $client->close;
            return undef;
        }

        $client->debug_print(1,$str)
          if($client->debug);
    }

    return 1;
}

##############################################################################

=head2 debug()

    * $client->debug($newlevel);
    * Param: $newlevel (IN)
    * Return: The old debug level.

    Method used to set the debug level of the client. Will also cause
    the @ISA heirarchy to be printed.

=cut

sub debug
{
    @_ == 1 or @_ == 2 or croak 'usage: $obj->debug([LEVEL])';

    my($client,$level) = @_;
    my $pkg = ref($client) || $client;
    my $oldval = 0;

    if(ref($client)) {
        $oldval = ${*$client}{'net_cmd_debug'} || 0;
    }
    else {
        $oldval = $debug{$pkg} || 0;
    }

    return $oldval
      unless @_ == 2;

    $level = $debug{$pkg} || 0
      unless defined $level;

    _print_isa($pkg)
      if($level && !exists $debug{$pkg});

    if(ref($client)) {
        ${*$client}{'net_cmd_debug'} = $level;
    }
    else {
        $debug{$pkg} = $level;
    }

    $oldval;
}

##############################################################################

=head2 _print_isa

    * $client->_print_isa()
    * Param: none
    * Return: none

    Method used to print out all memebers of the @ISA, and all their members of @ISA. Just
    to get the full inheritance tree of this object.

=cut

sub _print_isa
{
    no strict qw(refs);

    my $pkg = shift;
    my $cmd = $pkg;

    $debug{$pkg} ||= 0;

    my %done = ();
    my @do   = ($pkg);
    my %spc = ( $pkg , "");

    print STDERR "\n";
    while ($pkg = shift @do) {
        next if defined $done{$pkg};

        $done{$pkg} = 1;

        my $v = ( defined ${"${pkg}::VERSION"}
                  ? "(" . ${"${pkg}::VERSION"} . ")"
                  : "" );

        my $spc = $spc{$pkg};
        print STDERR "$cmd: ${spc}${pkg}${v}\n";

        if(@{"${pkg}::ISA"}) {
            @spc{@{"${pkg}::ISA"}} = ("  " . $spc{$pkg}) x @{"${pkg}::ISA"};
            unshift(@do, @{"${pkg}::ISA"});
        }
    }

    print STDERR "\n";
}

##############################################################################

=head2 debug_print()

    * $client->debug_print(1,"Some message");
    * Param: $output (IN), $message (IN).
    * Return: Nothing.

    This method is used to print the communication between this client and the server.
    If the first parameter is true (1), the value printed will be indicated to be output
    (from client to server), otherwise it will be considered input.

=cut

sub debug_print
{
    my($client,$out,$text) = @_;
    binmode STDERR, ":encoding(utf8)";
    print STDERR $client,($out ? '>>> ' : '<<< '), $text;
}

##############################################################################

=head2 get_response()

    * $client->get_response;
    * Param: none
    * Return: The response read from the last call to parse_response.

=cut

sub get_response
{
    my $client = shift;
    return ${*$client}{'response'};
}

##############################################################################

=head2 hostname()

    * $client->hostname
    * Param: none
    * Return: The value of the hostname

    Obtain the value of hostname as reported by the VSAP greeting.

=cut

sub hostname
{
    my $client = shift;
    ${*$client}{'vsap_hostname'};
}

##############################################################################

sub negotiate_tls
{
    my $client = shift;

    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
    my $ctx = Net::SSLeay::CTX_tlsv1_new();
    if (!$ctx) {
        $client->close;
        return;
    }
    if ($ENV{HOME}) {
        my $certfile = "$ENV{HOME}/$SSL_CERT_FILE";
        my $keyfile = "$ENV{HOME}/$SSL_KEY_FILE";
        Net::SSLeay::set_cert_and_key($ctx, $certfile, $keyfile)
            if -f $certfile;
    }
    my $ssl = Net::SSLeay::new($ctx);
    if (!$ssl) {
        Net::SSLeay::CTX_free($ctx);
        $client->close;
        return;
    }
    Net::SSLeay::set_fd($ssl, $client->fileno);
    if (Net::SSLeay::connect($ssl) <= 0) {
        Net::SSLeay::CTX_free($ctx);
        $client->close;
        return;
    }
    ${*$client}{ctx} = $ctx;
    ${*$client}{ssl} = $ssl;
    return 1;
}

##############################################################################

=head2 parse_response()

    * $client->parse_response;
    * Param: none
    * Return: A response from the server or undef on failure.

    This method reads a complete response from the server and returns this value also
    saving this value for use by the C<response()> method.

    The read request is validated by looking for <vsap/> or </vsap> followed by \r\n
    followed by the end of the string.

=cut

sub parse_response
{
    my $client = shift;

    local ($/) = "\r\n";

    # grab any leftover from the previous.
    delete ${*$client}{'response'};

    while (1) {
        ## Here lies the elusive "readline() on closed filehandle GENx
        ## at ... IO/Handle.pm" error. After sending a <vsap
        ## type="logout"/>, the server shuts down the connection, and
        ## we're left with a dead filehandle. This checks that case.
        return undef
          unless( $client->opened );

        # The line we get here is guaranteed to end with \r\n. This may
        # or may not be the end of the response, since \r\n could
        # occur in the middle of the xml response. We get this
        # and add it to our response. If the response is validated with the
        # below regex, it is considered valid.
        my $str = ${*$client}{ssl}
            ? Net::SSLeay::ssl_read_CRLF(${*$client}{ssl})
            : $client->getline();

        # Some error occurred in reading.
        if (!defined($str) || $str eq '') {
                return undef;
        }

        # Add this to the existing response.
        ${*$client}{'response'} .= $str;

        $client->debug_print(0,$str)
          if ($client->debug);

        if (${*$client}{'response'} =~ (/(\<\/vsap\>|\<vsap\/\>|<\/starttls>)\s*\r\n$/)) {
                return ${*$client}{'response'};
        }
    }
    return undef;
}

##############################################################################

=head2 platform()

    * $client->platform
    * Param: none
    * Return: The platform returned by the auth response.

    Obtain the value of platform as obtained by the VSAP auth response.

=cut

sub platform
{
    my $client = shift;
    ${*$client}{'platform'};
}

##############################################################################

=head2 product()

    * $client-product
    * Param: none
    * Return: The product returned by the auth response.

    Obtain the value of domain name as obtained by the VSAP auth response.

=cut

sub product
{
    my $client = shift;
    ${*$client}{'product'};
}

##############################################################################

=head2 quit()

    * $client->quit();
    * Param: none.
    * Return: nothing.

    Method used to send a request to the vsap server, obtain and return the response. Returns
    the response as a scalar on success, or undef on failure.

=cut

sub quit
{
    my $client = shift;

    $client->send("<vsap><vsap type='logout'\/></vsap>") || return undef;
    if (${*$client}{ssl}) {
        Net::SSLeay::free(${*$client}{ssl});
        Net::SSLeay::CTX_free(${*$client}{ctx});
    }
    $client->close;
}

##############################################################################

=head2 response()

    * $client->response
    * Param: none
    * Return: The DOM value of the last response.

    Method to obtain the last response from the server.

=cut

sub response {
    my $cmd = shift;
    my $vsapdom;
    my $response = ${*$cmd}{'response'};
    unless ($response) {
        $vsapdom = XML::LibXML::Document->new();
        my $vsapnode = $vsapdom->createElement("vsap");
        $vsapnode->appendTextChild("vsap" => "VSAP did not return response; connection likely failed");
        $vsapdom->setDocumentElement($vsapnode);
        return $vsapdom;   
    }
    $response =~ s/\&#013\;/\r/g;
    $response =~ s/\&#010\;/\n/g;
    my $parser = new XML::LibXML;
    $response =~ s/\s+$//;
    $response =~ s/^\s+//;
    eval {
        $vsapdom = $parser->parse_string($response);
    };
    if ($@) {
        $vsapdom = XML::LibXML::Document->new();
        my $vsapnode = $vsapdom->createElement("vsap");
        $vsapnode->appendTextChild("vsap" => "Could not parse the VSAP response: $@");
        $vsapdom->setDocumentElement($vsapnode);
    }
    else {
        return $vsapdom;
    }
}

##############################################################################

=head2 send()

    * $client->send("<vsap> <vsap type='some:module'>...</vsap></vsap>");
    * Param: The data to be sent to the vsap server.
    * Return: The response DOM from the vsap server.

    Method used to send a request to the vsap server, obtain and return the response. Returns the response as a scalar (DOM) on success, or undef on failure.

=cut

sub send
{
    my $client = shift;

    if (ref($_[0]) =~ /XML::LibXML/) {
        my $node   = shift;
        my $vsapcmd = $node->toString();
        #$vsapcmd =~ s/\s+$//;
        #$vsapcmd =~ s/\n/\&#010;/g;
        #$vsapcmd =~ s/\r/\&#013;/g;
        $client->command($vsapcmd) || return undef;
        return $client->parse_response;
    }
    else {
        my $vsapcmd = join '', @_;
        #$vsapcmd =~ s/\s+$//;
        #$vsapcmd =~ s/\n/\&#010;/g;
        #$vsapcmd =~ s/\r/\&#013;/g;
        $client->command($vsapcmd) || return undef;
        return $client->parse_response;
    }
}

##############################################################################

=head2 sessionkey()

    * $client->sessionkey
    * Param: none
    * Return: The sessionkey returned by the auth response.

    Obtain the value of sessionkey as obtained by the VSAP auth response.

=cut

sub sessionkey
{
    my $client = shift;
    ${*$client}{'sessionkey'};
}

##############################################################################

=head2 starttls()

    * $client->starttls()
    * Param: none
    * Return: true on success.

    Start an SSL session on the connection (negotiate TLS).
    This must be done before the connection is authenticated.
    Failure to start an SSL session is a fatal error, closing the connection.

=cut

sub starttls {
    my $client = shift;

    # Send the starttls request to the server,
    # if we have any business doing so.
    if (${*$client}{'authenticated'} || ${*$client}{ssl}) {
        $client->close;
        return;
    }
    $client->command('<starttls/>');
    $client->parse_response;
    my $response = $client->get_response;
    if (!$response || $response !~ m|<status>ok</status>|) {
        $client->close;
        return;
    }
    &negotiate_tls($client)
        or return;

    # We're in SSL mode now, so collect the new "hello" header.
    $client->parse_response;
    $client->_strip_response;
    return 1;
}

##############################################################################

=head2 status()

    * $client->status
    * Param: none
    * Return: The value of the vsap_status

    Obtain the value of vsap_status as reported by the VSAP greeting.

=cut

sub status
{
    my $client = shift;
    ${*$client}{'vsap_status'};
}

##############################################################################

=head2 username()

    * $client->username
    * Param: none
    * Return: The username returned by the auth response.

    Obtain the value of username as obtained by the VSAP auth response.

=cut

sub username
{
    my $client = shift;
    ${*$client}{'username'};
}

##############################################################################

=head2 valid_utf8()

    * $client->valid_utf8($string);
    * Param: string
    * Return: sanitized string

    This method takes a string as input, checks string for valid utf8-ness, and will
    sanitize the string if the string is not valid utf-8.

=cut

sub valid_utf8
{
    my $client = shift;
    my $string = shift;

    if ($string =~ m![^\011\012\015\040-\176]!) {
        my $converter = Text::Iconv->new("UTF-8", "UTF-8");   
        my $converted = $converter->convert($string);
        utf8::decode($converted);
        return($string) if ($string eq $converted);
        $client->debug_print(0, $string) if ($client->debug);
        $client->debug_print(0, $converted) if ($client->debug);
        $string =~ s![^\011\012\015\040-\176]!?!go;
    }
    return($string);
}

##############################################################################

=head2 version()

    * $client->version
    * Param: none
    * Return: The version of the vsap server.

    Obtain the version of the VSAP::Server object as reported during the VSAP greeting.

=cut

sub version
{
    my $client = shift;
    ${*$client}{'vsap_version'};
}

##############################################################################

=head2 DESTROY

    * Param: none.
    * Return: nothing.

    Perl DESTROY method, simply calls quit on the object.

=cut

sub DESTROY
{
    my $client = shift;
    $client->quit;
}

##############################################################################

1;
__END__

