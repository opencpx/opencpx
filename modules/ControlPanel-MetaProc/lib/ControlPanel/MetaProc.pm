package ControlPanel::MetaProc;

use 5.006;
use strict;
use Carp;
use XML::LibXML;
use XML::LibXSLT;
use VSAP::Client;

our $VERSION = '0.02';
our $vsapport = $ENV{VSAP_Port} || 551;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    # we should have been passed the DOM along, we'll store that in ourself for later use.
    my %args = @_;
    $self->{DOM} = $args{DOM};
    $self->{CP} = $args{CP};

    return $self;
}

sub dom {
    my $self = shift;
    my $newdom = shift;
  
    $self->{DOM} = $newdom if ($newdom);
    return $self->{DOM};
}

sub external_redirect { 
    my $self = shift;
    my $value = shift; 

    $self->{_EXTERN_REDIRECT} = $value 
	if ($value);

    return $self->{_EXTERN_REDIRECT};
}

sub process {
    my $self = shift;
    my $filename = shift;  # these are optionally sent in the function call
    my $base_path = shift;
 
    my $dom = $self->{DOM};
    my $cp = $self->{CP};

    ## find which file we're supposed to be processing
    $base_path ||= $dom->documentElement->findvalue('/cp/request/base_path');
    $filename ||= $dom->documentElement->findvalue('/cp/request/filename');

    if (!$base_path) {
        croak "no base_path specified (in /request/base_path or as parameter to MetaProc->process)";
    }
    if (!$filename) {
        croak "no filename specified (in /request/filename or as parameter to MetaProc->process)";
    }

    ## first lets create a VSAP client we can use throughout this whole process (so 
    ## authentication only has to happen once) If there's already a VSAP object in $cp, use it instead
    if (!defined($cp->{VSAP})) {
      my $vsap_port = $ENV{VSAP_Port};
      $cp && $cp->debug(10, "Starting a VSAP Client on localhost");
      $self->{VSAP} = new VSAP::Client(Hostname => "localhost", Debug => 0, PeerPort => $vsap_port) or croak ($@);
      $cp->{VSAP} = $self->{VSAP};
    } else {
      $cp && $cp->debug(10, "Using VSAP Client already there");
      $self->{VSAP} = $cp->{VSAP};
    }
    
    ## as long as process_file keeps returning to redirect, we keep going
    my $proc_filename = $filename;
    my $proc_result = 1;
    ## $runs will be used as a sanity checker - 20 page redirects seems a little excessive
    my $runs = 0;

    while ($proc_result && ($runs < 20)) {
        $proc_result = process_file($self, $base_path, $proc_filename);

	# If we have an external redirect set by any meta file, we stop processing and just get out
	# and we also remove any final_xsl value, since we won't be transforming anything. 
	return 0 if ($self->external_redirect);

	## we need to put the final filename somewhere, so the control panel knows 
	## which .xsl file to transform against (Since we may have redirected)
        $cp && $cp->debug(1, "Within proc loop, result is $proc_result");
	$proc_filename = $proc_result if ($proc_result);
        $runs++;
    }

    if ($runs == 20) {
        die "Looping redirects found!";
    }
    
    ## let's remove the /cp/completed nodes to not confuse anyone later (will probably only
    ## be used in the .meta files anyway
    #foreach my $cnode ($dom->documentElement->findnodes('/cp/completed')) {
    #  $cp && $cp->debug(1, "Removing completed node ...");
    #  $cnode->unbindNode(); # this is causing our segfaults, but not until 
    #                        # $cnode passes out of scope (gets destroyed).
    #  $cp && $cp->debug(1, "Removed.");
    #}
    #$cp && $cp->debug(1, "Finished removing complete nodes.");

    $cp && $cp->debug(1, "Final DOM being returned from MetaProc:\n" . $dom->toString(1));

    return $proc_filename;
}

## internally used subroutines follow

sub process_file {
    my ($self, $base_path, $filename) = @_;

    my $dom = $self->{DOM};
    my $vsapc = $self->{VSAP};
    my $cp = $self->{CP};

    $cp && $cp->debug(10,"Starting file process on $filename");

    ## start up our parsers and transformers, and parse the xsl doc
    my $parser = XML::LibXML->new();
    my $xslt = XML::LibXSLT->new();

    ## add the .meta to the filename 
    my $metafilename = $filename;
    $metafilename =~ s/^(.*)(\.xsl)$/$1.meta$2/;

    ## if the .meta file doesn't exist, simply return
    if (!-e $base_path . '/' . $metafilename) {
        return 0;
    }
    
    my $style_doc = $parser->parse_file($base_path . '/' . $metafilename);
    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    ## now transform that DOM against the XSL stylesheet until we get to a '<showpage>'
    ## or '<redirect>'
    my $runs = 0;  ## this is strictly a sanity check. 
    my $abort = 0; ## This is an emergency abort 
    while (($runs < 50) && !$abort) {
        $runs++;

        my $newdom = $stylesheet->transform($dom);
        my $cmdnode = $newdom->documentElement->firstChild();

        $cp && $cp->debug(10, ".meta.xsl returned:\n" . $newdom->toString(1));
        $cp && $cp->debug(10, "first child is:\n" . $cmdnode->nodeName);

        if ($cmdnode->nodeName eq 'vsap') {
            ## if the vsap call is to logout, we need to close our VSAP client and start a new one
            if (my ($logoutnode) = $cmdnode->findnodes('vsap[@type="logout"]')) {
                $vsapc->quit;
                $self->{VSAP} = new VSAP::Client(Hostname => "localhost", Debug => 0) or croak ($@);
                $vsapc = $self->{VSAP};
    
                # remove this node from the tree (so vsap doesn't try calling it)
                $logoutnode->unbindNode();
            }

            ## do vsap call here
            my $vsapcmd = $cmdnode->toString();
            $cp && $cp->debug(8,"Running vsap:\n$vsapcmd");
            $vsapcmd =~ s/\n/\&#010;/g;
            $vsapcmd =~ s/\r/\&#013;/g;
            $vsapc->send($vsapcmd);
            ## FIXME: above is an unneeded serialization if we can do without 
            ## the substitution; change our transmission end to \0
 
            ## take the result, add to our DOM
            my $vsapresult = $vsapc->response();

            ## VSAP::Client is doing this for us
            if (ref($vsapresult) =~ /XML::LibXML/) {
                my $importnode = $dom->importNode($vsapresult->documentElement);
                $dom->documentElement->appendChild($importnode);
            } else {
                $cp && $cp->debug(8,"VSAP Response:\n$vsapresult");
                $vsapresult = unescape_newlines($vsapresult);
                my $vsapdom;
                eval {
                    $vsapdom = $parser->parse_string($vsapresult);
                };

                if ($@) {
                    $cp && $cp->debug(1, "Error parsing VSAP response: $@");
                    $dom->documentElement->appendTextChild('vsap_parse_error', "Could not parse the VSAP Response: $@");
                    return "error.xsl";
                } else {
                    ## now append the vsap element to our dom
                    my $importnode = $dom->importNode($vsapdom->documentElement);
                    $dom->documentElement->appendChild($importnode);
                }
            }
            
            ## add the call to the /cp/completed section, so we can see it's been done
            my $completednode = XML::LibXML::Element->new('completed');
#            $completednode->appendChild($cmdnode);
            my $fragment = $parser->parse_balanced_chunk( $vsapcmd );
            $completednode->appendChild($fragment);
            my $dimport = $dom->importNode($completednode);
            $dom->documentElement->appendChild($dimport);
        }

        ## if the root element is <cp>, it's something we just need to add to
        ## the dom
        elsif ($cmdnode->nodeName eq 'cp') {
            ## take the children, and append them to our real dom
            foreach my $schild_node ($cmdnode->childNodes) {
                my $importnode = $dom->importNode($schild_node);
                $dom->documentElement->appendChild($importnode);
            }
        }

        ## if we received a redirection, we need to redirect    
        elsif ($cmdnode->nodeName eq 'redirect') {
            ## return from call with dom, or path?
            $cp && $cp->debug(10, "returning from .meta.xsl redirecting to " . $cmdnode->findvalue('path'));
            return $cmdnode->findvalue('path');
        }

	elsif ($cmdnode->nodeName eq 'external-redirect') {
	    my $url = $cmdnode->findvalue('url');
            $cp && $cp->debug(10, "external-redirect to $url");
	    $self->external_redirect($url);
	    return 0;
	}

        ## if we receive a showpage, continue on showing the page
        elsif ($cmdnode->nodeName eq 'showpage') {
            ## we're done modifying the dom, we can leave the module
            return 0;
        }

        ## if we receive forbidden, send an error back to the caller
        elsif ($cmdnode->nodeName eq 'forbidden') {
            croak "forbidden";
        }

        ## none of the above? uh oh
        else {
            croak "transforming the XSL file $base_path/$filename against dom didn't return <vsap>, <redirect>, <cp>, or <showpage>";
        }
    }
}

sub unescape_newlines {
    my $xml = shift;

    # un-escape \r, \n from returned xml
    $xml =~ s/\&#013\;/\r/g;   
    $xml =~ s/\&#010\;/\n/g;

    return $xml;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

ControlPanel::MetaProc - Metadata processor for the control panel

=head1 SYNOPSIS

  use ControlPanel::MetaProc;

  my $metaproc = ControlPanel::MetaProc->new(DOM => $dom);
  $filename = $metaproc->process();
  
=head1 DESCRIPTION

This module provides all .meta.xsl processing to build up the DOM before it can
be transformed against the html-generating template. It takes as a constructor 
argument the DOM to be used, which contains all the information the processor 
will need.

=head1 AUTHOR

Zach Wily

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
