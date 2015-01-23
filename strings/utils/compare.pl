use strict;

use XML::LibXML;
use Getopt::Long;

our ($help, $content_same, $content_diff, $presence_diff, $nonempty);
my $result = GetOptions ("h" => \$help,
                         "contentsame" => \$content_same,
                         "contentdiff" => \$content_diff,
                         "presence" => \$presence_diff,
                         "nonempty" => \$nonempty
);

if ($help) {
    print <<EOF;
Compare the content of two CPX strings files. Not a diff utility.

USAGE: compare.pl [-h -contentsame -contentdiff -presence] \ 
       file1.xml file2.xml

  -contentsame     Compare the string content, outputting where content 
                   is identical.
  -contentdiff     Compare the string content, outputting where content
                   is different.
  -presence        Output where elements in file1 are missing in file2.
  -nonempty        Ignore empty elements.
  -h               See this message.

To find all nodes in file2.xml that are missing elements in file1.xml, 
or have identical string content to file1.xml:

  % perl utils/compare.pl -presence -contentsame -nonempty \
    en_US/mail.xml ja_JP/mail.xml

EOF
exit;
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

unless ($file1 && $file2) {
    print "Please supply two file names.\n";
    exit;
}

unless (-T $file1 && -T $file2) {
    print "Both files must exist and be readable.\n";
    exit;
}

my $parser = XML::LibXML->new();

my $xml1 = $parser->parse_file($file1);
my $xml2 = $parser->parse_file($file2);

foreach my $child ($xml1->documentElement->childNodes) {
    # print $child->nodePath() . "  " . ref($child) . "\n";
    recurse_nodes($child);
}

sub recurse_nodes {
    my $node1 = shift;
    return unless (ref($node1) eq "XML::LibXML::Element");
    my ($node2) = $xml2->findnodes($node1->nodePath);
    if (!$node2 && $presence_diff) {
        print "Missing from 2nd file: " . $node1->toString . "\n";
    }
    if ($content_same && $node1->toString eq $node2->toString) {
        if (!$nonempty || $node1->findvalue('text()') ne "") {
            print "Content is the same: " . $node1->toString . "\n";
        }
    }
    if ($content_diff && $node1->toString ne $node2->toString) {
       print "Content is different: " . $node1->toString . "\n";
    }
    foreach my $child ($node1->childNodes) {
        recurse_nodes($child);
    }
}



