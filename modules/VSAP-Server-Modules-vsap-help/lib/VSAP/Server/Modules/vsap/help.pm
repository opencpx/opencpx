package VSAP::Server::Modules::vsap::help;

use 5.008004;
use strict;
use warnings;

use Pod::Find;
use Pod::Text;
use XML::LibXML;

use VSAP::Server::Modules::vsap::globals;

##############################################################################

our $VERSION = '0.12';

our $SCORE_THRESHOLD    = 0;
our $MIN_WORD_SIZE      = 2;

our %_ERR = (
              HELP_SHORT_QUERY            => 100,
              HELP_INVALID_LANGUAGE       => 101,
              HELP_NO_SEARCH_RESULTS      => 102,
              HELP_INVALID_CATEGORY       => 103,
              HELP_INVALID_TOC_FILE       => 104,
              HELP_INVALID_TOC_XML        => 105,
              HELP_INVALID_GOT_FILE       => 106,
              HELP_INVALID_GOT_XML        => 107,
              HELP_INVALID_FAQ_FILE       => 108,
              HELP_INVALID_FAQ_XML        => 109,
              HELP_INVALID_TOPIC_FILE     => 110,
              HELP_INVALID_TOPIC_XML      => 111,
              HELP_INVALID_LANGUAGE       => 112,
              HELP_INVALID_DTD            => 113,
              HELP_NO_MODULE              => 114,
            );

##############################################################################

sub search_topic
{
    my ($topic_rec, $query, $case_sensitive) = @_;

    # Dont look at stuff that isnt there.
    return $topic_rec unless (-f $topic_rec->{path});

    my $parser      = XML::LibXML->new();
    my $tree        = $parser->parse_file($topic_rec->{path});
    my $root        = $tree->getDocumentElement;

    my $keywords    = $root->find(q{/topic/keywords})->to_literal;
    my $title       = $root->find(q{/topic/title})->to_literal;
    my $text        = $root->find(q{/topic//text()})->to_literal;

    my %seen;
    my @query_words =   grep { ! $seen{$_}++  }             # duplicates
                        grep { length >= $MIN_WORD_SIZE }   # length check
                        grep { /[[:alnum:]\+\/\_-]/ }       # puctuation filter
                        split( /[^[:alnum:]\+\/\_-]+/, $query );

    my @file_words =    grep { length >= $MIN_WORD_SIZE }   # length check
                        grep { /[[:alnum:]\+\/\_-]/ }       # puctuation filter
                        split( /[^[:alnum:]\+\/\_-]+/, qq{$keywords $title $text});

    # Rank the topic rec based on how many word hits it gets.
    # Duplicate keywords inside topic files will increase ranking.
    foreach my $word (@query_words) {
        if ($case_sensitive) {
            $topic_rec->{score} += scalar grep { /$word/ } @file_words;
        }
        else {
            $topic_rec->{score} += scalar grep { /$word/i } @file_words;
        }
    }

    return $topic_rec;
}

# ----------------------------------------------------------------------------

sub get_topics
{
    my ($vsap, $categories, $language, $query, $case_sensitive) = @_;

    my @records;            # Used to hold return records
    my $user_access_level;  # XPath user access level test string
    my $user_attrib_level;  # XPath user capabilities test string
    my $platform_type;      # XPath platform type test string

    my $base_help_dir       = qq{/usr/local/cp/help/$language};
    my $help_toc_file       = qq{$base_help_dir/help_toc.xml};
    my $all_cat             = (scalar grep { /^all$/i } @$categories ) ? 1 : 0;

    my $co                  = VSAP::Server::Modules::vsap::config->new( uid => $> );
    my $parser              = XML::LibXML->new();
    my $tree                = $parser->parse_file( $help_toc_file );

    unless ($tree) {
        $vsap->error( $_ERR{HELP_INVALID_TOC} => qq{Invalid Help TOC file [$help_toc_file].} );
        return;
    }

    my $root = $tree->getDocumentElement;


    # Create a string of all user access level rights.
    if ($vsap->{server_admin}) {
        $user_access_level = q{SA,DA,MA,EU};
        $user_attrib_level = join( ',', keys %{$co->capabilities} );
    }
    elsif ($co->domain_admin) {
        $user_access_level = q{DA,MA,EU};
        $user_attrib_level = join( ',', keys %{$co->services} );
    }
    elsif ($co->mail_admin) {
        $user_access_level = q{MA,EU};
        $user_attrib_level = join( ',', keys %{$co->services} );
    }
    else {
        $user_access_level = q{EU};
        $user_attrib_level = join( ',', keys %{$co->services} );
    }

    my $packages  = join( ',', keys %{$co->packages} );
    $user_attrib_level =~ s/mail-clamav// unless ($packages =~ /mail-clamav/);
    $user_attrib_level =~ s/mail-spamassassin// unless ($packages =~ /mail-spamassassin/);

    my $siteprefs  = join( ',', keys %{$co->siteprefs} );
    $user_attrib_level =~ s/mail-clamav// if ($siteprefs =~ /disable-clamav/);
    $user_attrib_level =~ s/mail-spamassassin// if ($siteprefs =~ /disable-spamassassin/);

    # limit results to those appropriate for platform (if necessary)
    $platform_type = $VSAP::Server::Modules::vsap::globals::PLATFORM_TYPE;

    # Get list of all topics that user can access.
    my $xpath = q{/toc/*/category[contains( '} .
                $platform_type .
                q{', @platform_type ) and contains( '} .
                $user_access_level .
                q{', @user_access_level ) and contains( '} .
                $user_attrib_level .
                q{', @user_attrib_level )]/topic[not(@hidden) and contains( '} .
                $platform_type .
                q{', @platform_type ) and contains( '} .
                $user_access_level .
                q{', @user_access_level ) and contains( '} .
                $user_attrib_level .
                q{', @user_attrib_level )]};

  NODE: foreach my $node ( $root->findnodes( $xpath ) )
    {
        my $category = $node->parentNode->getAttributeNode( 'id' )->getValue;

        # Prune out the categories we dont want.
        next NODE unless ( $all_cat || (scalar grep { $category eq $_ } @$categories) );

        my $topic = $node->getAttributeNode( 'id' )->getValue;
        my $topic_path = $base_help_dir .'/'. $category .'/'. $topic . q{.xml};

        my %rec =
        (
            id          => $topic,
            category    => $category,
            path        => $topic_path,
            score       => 0,
        );

        if ($query) {
            VSAP::Server::Modules::vsap::help::search_topic(
                \%rec,
                $query,
                $case_sensitive
            );
        }

        push(@records, \%rec);
    }

    return wantarray ? @records : \@records;
}

##############################################################################

package VSAP::Server::Modules::vsap::help::debug;

sub handler
{
    my ($vsap, $xml)  = @_;

    my $topic;
    my $category;
    my $language;
    my $query;
    my $case;

    $topic     = $xml->child('topic')->value           if ( $xml->child('topic') );
    $category  = $xml->child('category')->value        if ( $xml->child('category') );
    $language  = $xml->child('language')->value        if ( $xml->child('language') );
    $query     = $xml->child('query')->value           if ( $xml->child('query') );
    $case      = $xml->child('case_sensitive')->value  if ( $xml->child('case_sensitive') );

    my $base_help_dir = qq{/usr/local/cp/help/$language};

    unless ($language && (-d $base_help_dir)) {
        $vsap->error( $_ERR{HELP_INVALID_LANGUAGE} => qq{Invalid language directory [$base_help_dir].} );
        return;
    }

    my $tree;
    my $help_dtd_file   = qq{/usr/local/cp/help/help.dtd};
    my $help_toc_file   = qq{$base_help_dir/help_toc.xml};
    my $help_got_file   = qq{$base_help_dir/help_got.xml};
    my $help_faq_file   = qq{$base_help_dir/help_faq.xml};

    my $parser          = XML::LibXML->new();
    my $dtd             = XML::LibXML::Dtd->new("SOME // Public / ID / 1.0", $help_dtd_file);

    unless ($dtd) {
        $vsap->error( $_ERR{HELP_INVALID_DTD} => qq{Invalid DTD file [$help_dtd_file].} );
        return;
    }

    #------------------------------------------
    # topic file checking
    #------------------------------------------
    if ($topic) {
        my $help_topic_file = qq{$base_help_dir/$category/$topic.xml};
        my $category_dir = qq{$base_help_dir/$category};

        # Check to make sure the category directory exists
        unless (-d $category_dir) {
            $vsap->error($_ERR{HELP_INVALID_CATEGORY} => qq{Invalid Category directory [$category_dir].});
            return;
        }

        unless (-e $help_topic_file) {
            $vsap->error($_ERR{HELP_INVALID_TOPIC_FILE} => qq{Topic file is invalid [$help_topic_file].});
            return;
        }

        eval { $tree = $parser->parse_file($help_topic_file) };
        if ($@) {
            $vsap->error($_ERR{HELP_INVALID_TOPIC_XML} => qq{Topic file XML is invalid [$help_topic_file][$@].});
            return;
        }

        # Verify structure
        eval { $tree->validate($dtd) };
        if ($@) {
            $vsap->error( $_ERR{HELP_INVALID_TOPIC_XML} => qq{Invalid topic file XML [$help_topic_file][$@].} );
            return;
        }
    }

    #------------------------------------------
    # test the validity of the TOC file
    #------------------------------------------
    unless (-e $help_toc_file) {
        $vsap->error($_ERR{HELP_INVALID_TOC_FILE} => qq{TOC file does not exist [$help_toc_file].});
        return;
    }

    eval { $tree  = $parser->parse_file($help_toc_file) };
    if ($@) {
        $vsap->error($_ERR{HELP_INVALID_TOC_XML} => qq{TOC file XML is invalid [$help_toc_file][$@].});
        return;
    }

    # verify structure
    eval { $tree->validate($dtd) };
    if ($@) {
        $vsap->error($_ERR{HELP_INVALID_TOC_XML} => qq{Invalid TOC file XML [$help_toc_file][$@][$!].});
        return;
    }

    #------------------------------------------
    # test the validity of the GOT file
    #------------------------------------------
    unless(-e $help_got_file) {
        $vsap->error($_ERR{HELP_INVALID_GOT_FILE} => qq{GOT file does not exist [$help_got_file].});
        return;
    }

    eval { $tree = $parser->parse_file($help_got_file) };
    if ($@) {
        $vsap->error($_ERR{HELP_INVALID_GOT_XML} => qq{GOT file XML is invalid [$help_got_file][$@].});
        return;
    }

    # verify structure
    eval { $tree->validate($dtd) };
    if ($@) {
        $vsap->error($_ERR{HELP_INVALID_GOT_XML} => qq{Invalid GOT file XML [$help_got_file][$@].});
        return;
    }

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::help::search;

sub handler
{
    my ($vsap, $xml)  = @_;

    my $query;
    my $category;
    my $language;
    my $case_sensitive;

    unless ($xml->child('query') && ($query = $xml->child('query')->value) && (length($query) >= $MIN_WORD_SIZE)) {
        $vsap->error( $_ERR{HELP_SHORT_QUERY} => qq{Search query string too short[$query].} );
        return;
    }

    unless($xml->child('category') && ($category = $xml->child('category')->value)) {
        $vsap->error( $_ERR{HELP_INVALID_CATEGORY} => qq{Invalid category specified [$category].} );
        return;
    }

    unless( $xml->child('language') && ($language = $xml->child('language')->value)) {
        $vsap->error( $_ERR{HELP_INVALID_LANGUAGE} => qq{Invalid Search Language[$language].} );
        return;
    }

    if ($xml->child('case_sensitive')) {
        $case_sensitive  = $xml->child('case_sensitive')->value;
    }

    my $dom = $vsap->{_result_dom};

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute(type => 'help:search');

    my @topics = VSAP::Server::Modules::vsap::help::get_topics($vsap, [$category], $language, $query, $case_sensitive);

    # See if we have found any that are worth reporting.
    unless ( scalar grep { $_->{score} > $SCORE_THRESHOLD } @topics ) {
        $vsap->error($_ERR{HELP_NO_SEARCH_RESULTS} => qq{No Search results.});
        return undef;
    }

    foreach my $topic ( sort { $b->{score} <=> $a->{score} } @topics ) {
        next unless ( $topic->{score} > $SCORE_THRESHOLD );
        my $topic_node = $dom->createElement('topic');
        $topic_node->setAttribute( category => $topic->{category} );
        $topic_node->setAttribute( score    => $topic->{score} );
        $topic_node->setAttribute( new      => $topic->{new} );
        $topic_node->setAttribute( id       => $topic->{id} );
        $root_node->appendChild($topic_node);
    }

    $dom->documentElement->appendChild($root_node);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::help::vsap;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->dom;

    my $module = $xmlobj->child('module') ? $xmlobj->child('module')->value : '';

    my $help;
    my @mod;

    # Return the POD documentation corresponsing to a module,
    # or perhaps its parent.
    if ($module) {
        my $pm = "VSAP:Server:Modules:vsap:$module";
        $pm =~ s/:/::/g;
        for (;;) {
            if (my $f = &Pod::Find::pod_where({-inc => 1}, $pm)) {
                my $parser = Pod::Text->new;
                $parser->output_string(\$help);
                $parser->parse_file($f);
                last;
            }
            unless ($pm =~ s/VSAP::Server::Modules::vsap::.*\K::[^:]*$//) {
                $vsap->error($_ERR{HELP_NO_MODULE} => "No such module: $module");
                return;
            }
        }
    }
    else {
        # In the absense of a module, return a list of all available modules.
        my @pkg = ('VSAP::Server::Modules::vsap::');
        for (my $pi = 0; $pi < @pkg; $pi++) {
            no strict 'refs';
            my $p = $pkg[$pi];
            if (exists &{"${p}handler"}) {
                $p =~ /VSAP::Server::Modules::vsap::(.*)::/;
                my $m = $1;
                $m =~ s/::/:/g;
                push @mod, $m;
            }
            push @pkg, map "$p$_", grep /::$/, keys %$p;
        }
    }

    my $root_node = $dom->createElement('vsap');
    $root_node->setAttribute('type' => 'help:vsap');
    $root_node->appendTextChild('help' => $help) if $help;
    grep $root_node->appendTextChild('module' => $_), sort @mod;
    $dom->documentElement->appendChild($root_node);
    return;
}

##############################################################################
1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::help - VSAP module for handling search help topic search queries

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::help;

=head1 DESCRIPTION

VSAP module for handling search help topic search queries

There are three commands:

    <vsap type="help:debug">
      <query>...</query>
      <topic>...</topic>
      <category>...</category>
      <language>...</language>
      <case_sensitive>...</case_sensitive>
    </vsap>

This provides some sort of help, I'm sure.

    <vsap type="help:search">
      <query>...</query>
      <category>...</category>
      <language>...</language>
      <case_sensitive>...</case_sensitive>
    </vsap>

This will return a set of <topic> nodes corresponding to the query.

    <vsap type="help:vsap">
      <module>...</module>
    </vsap>

By default, this will return a set of <module> nodes, corresponding to all
VSAP modules (requests, calls, commands, whatever).  If a module is passed
in, it will return the POD documentation for that module, or perhaps for its
parent.  For example, you can wee what you're reading right now with
<module>help:vsap</module>, though it's really the same as
<module>help</module>.

The quality of the POD documentation for various modules is, at best,
inconsistent.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

System Administrator, E<lt>root@securesites.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut

