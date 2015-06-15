package ControlPanel::Transform;

use 5.006;
use strict;

use Carp;
use XML::LibXML;
use XML::LibXSLT;

# set max recursive depth to something higher than the default (ENH27705)
XML::LibXSLT->max_depth(2500);

our $VERSION = '0.12';

##############################################################################

sub new
{
    my $class = shift;
    my $self = bless {}, $class;

    # place the args in ourself
    my %args = @_;
    $self->{DOM} = $args{DOM};
    $self->{base_path} = $args{base_path};
    $self->{filename} = $args{filename};

    return $self;
}

##############################################################################

sub process
{
    my $self = shift;

    my $parser = XML::LibXML->new;
    my $xslt = XML::LibXSLT->new;

    my $xsl = $parser->parse_file($self->{base_path} . '/' . $self->{filename});
    my $stylesheet = $xslt->parse_stylesheet($xsl);
    $self->{result_dom} = $stylesheet->transform($self->{DOM});
    $self->{output_string} = $stylesheet->output_string($self->{result_dom});
}

##############################################################################

sub result_dom
{
    my $self = shift;

    return $self->{result_dom};
}

##############################################################################

sub cp_unescape
{
    my $html = shift;
    my $string_name = shift;
    
    $html =~ s/\&lt\;/</g;
    $html =~ s/\&gt\;/>/g;
    $html =~ s/\&amp\;/\&/g;
    $html =~ s/\&quot\;/\"/g;

    if ($string_name) {
        return "<$string_name>$html</$string_name>";
    }
    return $html; 
}

##############################################################################

sub result_html
{
    my $self = shift;

    my $html = $self->{output_string};

    # HACK: look for any elements with the cdata="yes" attribute set. These
    # are strings that must have entities unescaped.
    # this is because we can't disable-output-escaping in CDATA elements
    # since they're part of parameters passed to other templates
    if ($html =~ /cdata=['"]yes['"]/) {
        $html =~ s{<(\S+)\s+cdata.*?>(.*?)</\s*\1\s*>}{cp_unescape($2, $1)}egs;
    }
    if ($html =~ /cp-unescape/) {
        $html =~ s{[<\[]cp-unescape[>\]](.*?)[<\[]/cp-unescape[>\]]}{cp_unescape($1)}egs;
    }

    return $html;
}

##############################################################################

1;
__END__

=head1 NAME

ControlPanel::Transform - transform a DOM into an HTML document

=head1 SYNOPSIS

  use ControlPanel::MetaProc;
  use ControlPanel::Transform;

  my $metaproc = ControlPanel::MetaProc->new(DOM => $dom);
  $filename = $metaproc->process();

  my $transform = ControlPanel::Transform->new(DOM => $dom,
                                               base_path => $xsl_template_dir
                                               filename => $filename);
  $transform->process;

  print $transform->result_html;

=head1 DESCRIPTION

This module provides the ability to transform a DOM against an html-generating
template into a final HTML document.  It takes the DOM to be used, a path name 
containing the template directory, and the filename return from the meta 
processing engine.

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
