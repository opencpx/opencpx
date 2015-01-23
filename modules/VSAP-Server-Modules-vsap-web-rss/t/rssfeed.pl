##
## $SMEId: apps/vsap/modules/VSAP-Server-Modules-vsap-web-rss/t/rssfeed.pl,v 1.1 2006/03/02 16:20:25 kwhyte Exp $

## common stuff

use warnings;

BEGIN {
    rename( $RSSFEEDS, "$RSSFEEDS.$$" ) if -e $RSSFEEDS;
    if( $VPS ) {
        my $xml = qq!<vsap type="domain:add">\n!;
        $xml .= qq!<admin>! . $acct->userid . qq!</admin>\n!;
        $xml .= qq!<domain>example.com</domain>\n!;
        $xml .= qq!<www_alias>1</www_alias>\n!;
        $xml .= qq!<other_aliases/>\n!;
        $xml .= qq!<cgi>0</cgi>\n!;
        $xml .= qq!<ssl>0</ssl>\n!;
        $xml .= qq!<end_users>0</end_users>\n!;
        $xml .= qq!<email_addrs>0</email_addrs>\n!;
        $xml .= qq!<website_logs>no</website_logs>\n!;
        $xml .= qq!<domain_contact>root\@example.com</domain_contact>\n!;
        $xml .= qq!<mail_catchall>reject</mail_catchall>\n!;
        $xml .= qq!</vsap>\n!;
        $client->xml_response($xml);
    }
}

END {
    rename( "$RSSFEEDS.$$", $RSSFEEDS ) if -e "$RSSFEEDS.$$";
    if( $VPS ) {
        my $xml = qq!<vsap type="domain:delete">\n!;
        $xml .= qq!<domain>example.com</domain>\n!;
        $xml .= qq!</vsap>\n!;
        $client->xml_response($xml);
    }
}

sub add_feed { 
    my $data   = shift;

    my $xml = qq!<vsap type="web:rss:add:feed">\n!;
    $xml .= qq!<ruid>$data->{ruid}</ruid>\n! if (defined $data->{ruid});
    $xml .= qq!<edit>$data->{edit}</edit>\n! if (defined $data->{edit});
    $xml .= qq!<title>$data->{title}</title>\n! if (exists $data->{title});
    $xml .= qq!<directory>$data->{directory}</directory>\n! if (exists $data->{directory});
    $xml .= qq!<filename>$data->{filename}</filename>\n! if (exists $data->{filename});
    $xml .= qq!<domain>example.com</domain>\n! if ($VPS);
    $xml .= qq!<link>$data->{link}</link>\n! if (exists $data->{link});
    $xml .= qq!<description>$data->{description}</description>\n! if (exists $data->{description});
    $xml .= qq!<language>$data->{language}</language>\n! if (exists $data->{language});
    $xml .= qq!<copyright>$data->{copyright}</copyright>\n! if (exists $data->{copyright});
    $xml .= qq!<pubdate_day>$data->{pubdate_day}</pubdate_day>\n! if (exists $data->{pubdate_day});
    $xml .= qq!<pubdate_date>$data->{pubdate_date}</pubdate_date>\n! if (exists $data->{pubdate_date});
    $xml .= qq!<pubdate_month>$data->{pubdate_month}</pubdate_month>\n! if (exists $data->{pubdate_month});
    $xml .= qq!<pubdate_year>$data->{pubdate_year}</pubdate_year>\n! if (exists $data->{pubdate_year});
    $xml .= qq!<pubdate_hour>$data->{pubdate_hour}</pubdate_hour>\n! if (exists $data->{pubdate_hour});
    $xml .= qq!<pubdate_minute>$data->{pubdate_minute}</pubdate_minute>\n! if (exists $data->{pubdate_minute});
    $xml .= qq!<pubdate_second>$data->{pubdate_second}</pubdate_second>\n! if (exists $data->{pubdate_second});
    $xml .= qq!<pubdate_zone>$data->{pubdate_zone}</pubdate_zone>\n! if (exists $data->{pubdate_zone});
    $xml .= qq!<category>$data->{category}</category>\n! if (exists $data->{category});
    $xml .= qq!<generator>$data->{generator}</generator>\n! if (exists $data->{generator});
    $xml .= qq!<ttl>$data->{ttl}</ttl>\n! if (exists $data->{ttl});
    $xml .= qq!<image_url>$data->{image_url}</image_url>\n! if (exists $data->{image_url});
    $xml .= qq!<image_title>$data->{image_title}</image_title>\n! if (exists $data->{image_title});
    $xml .= qq!<image_link>$data->{image_link}</image_link>\n! if (exists $data->{image_link});
    $xml .= qq!<image_width>$data->{image_width}</image_width>\n! if (exists $data->{image_width});
    $xml .= qq!<image_height>$data->{image_height}</image_height>\n! if (exists $data->{image_height});
    $xml .= qq!<image_description>$data->{image_description}</image_description>\n! if (exists $data->{image_description});
    $xml .= qq!<itunes_subtitle>$data->{itunes_subtitle}</itunes_subtitle>\n! if (exists $data->{itunes_subtitle});
    $xml .= qq!<itunes_author>$data->{itunes_author}</itunes_author>\n! if (exists $data->{itunes_author});
    $xml .= qq!<itunes_summary>$data->{itunes_summary}</itunes_summary>\n! if (exists $data->{itunes_summary});
    if (exists $data->{itunes_category}) {
        foreach my $category (@{$$data{itunes_category}}) {
            $xml .= qq!<itunes_category>$category</itunes_category>\n!;
        }
    }
    $xml .= qq!<itunes_owner_name>$data->{itunes_owner_name}</itunes_owner_name>\n! if (exists $data->{itunes_owner_name});
    $xml .= qq!<itunes_owner_email>$data->{itunes_owner_email}</itunes_owner_email>\n! if (exists $data->{itunes_owner_email});
    $xml .= qq!<itunes_image>$data->{itunes_image}</itunes_image>\n! if (exists $data->{itunes_image});
    $xml .= qq!<itunes_explicit>$data->{itunes_explicit}</itunes_explicit>\n! if (exists $data->{itunes_explicit});
    $xml .= qq!<itunes_block>$data->{itunes_block}</itunes_block>\n! if (exists $data->{itunes_block});
    $xml .= qq!</vsap>\n!;

    my $resp = $client->xml_response($xml);

    if (defined $data->{ruid}) {
        return $resp->findvalue(qq!/vsap/vsap[\@type="web:rss:add:feed"]/rssSet/rss[\@ruid="$data->{ruid}"]!);
    } else {
        return $resp->findvalue(qq!/vsap/vsap[\@type="web:rss:add:feed"]/rssSet/rss[title="$data->{title}"]!);
    }
}

sub add_item { 
    my $data   = shift;

    my $xml = qq!<vsap type="web:rss:add:item">\n!;
    $xml .= qq!<iuid>$data->{iuid}</iuid>\n! if (defined $data->{iuid});
    $xml .= qq!<edit>$data->{edit}</edit>\n! if (defined $data->{edit});
    $xml .= qq!<ruid>$data->{ruid}</ruid>\n! if (defined $data->{ruid});
    $xml .= qq!<title>$data->{title}</title>\n! if (exists $data->{title});
    $xml .= qq!<fileurl>$data->{fileurl}</fileurl>\n! if (exists $data->{fileurl});
    $xml .= qq!<description>$data->{description}</description>\n! if (exists $data->{description});
    $xml .= qq!<author>$data->{author}</author>\n! if (exists $data->{author});
    $xml .= qq!<pubdate_day>$data->{pubdate_day}</pubdate_day>\n! if (exists $data->{pubdate_day});
    $xml .= qq!<pubdate_date>$data->{pubdate_date}</pubdate_date>\n! if (exists $data->{pubdate_date});
    $xml .= qq!<pubdate_month>$data->{pubdate_month}</pubdate_month>\n! if (exists $data->{pubdate_month});
    $xml .= qq!<pubdate_year>$data->{pubdate_year}</pubdate_year>\n! if (exists $data->{pubdate_year});
    $xml .= qq!<pubdate_hour>$data->{pubdate_hour}</pubdate_hour>\n! if (exists $data->{pubdate_hour});
    $xml .= qq!<pubdate_minute>$data->{pubdate_minute}</pubdate_minute>\n! if (exists $data->{pubdate_minute});
    $xml .= qq!<pubdate_second>$data->{pubdate_second}</pubdate_second>\n! if (exists $data->{pubdate_second});
    $xml .= qq!<pubdate_zone>$data->{pubdate_zone}</pubdate_zone>\n! if (exists $data->{pubdate_zone});
    $xml .= qq!<guid>$data->{guid}</guid>\n! if (exists $data->{guid});
    $xml .= qq!<itunes_subtitle>$data->{itunes_subtitle}</itunes_subtitle>\n! if (exists $data->{itunes_subtitle});
    $xml .= qq!<itunes_author>$data->{itunes_author}</itunes_author>\n! if (exists $data->{itunes_author});
    $xml .= qq!<itunes_summary>$data->{itunes_summary}</itunes_summary>\n! if (exists $data->{itunes_summary});
    if (exists $data->{itunes_category}) {
        foreach my $category (@{$data->{itunes_category}}) {
            $xml .= qq!<itunes_category>$category</itunes_category>\n!;
        }
    }
    $xml .= qq!<itunes_duration_hour>$data->{itunes_duration_hour}</itunes_duration_hour>\n! if (exists $data->{itunes_duration_hour});
    $xml .= qq!<itunes_duration_minute>$data->{itunes_duration_minute}</itunes_duration_minute>\n! if (exists $data->{itunes_duration_minute});
    $xml .= qq!<itunes_duration_second>$data->{itunes_duration_second}</itunes_duration_second>\n! if (exists $data->{itunes_duration_second});
    $xml .= qq!<itunes_keywords>$data->{itunes_keywords}</itunes_keywords>\n! if (exists $data->{itunes_keywords});
    $xml .= qq!<itunes_explicit>$data->{itunes_explicit}</itunes_explicit>\n! if (exists $data->{itunes_explicit});
    $xml .= qq!<itunes_block>$data->{itunes_block}</itunes_block>\n! if (exists $data->{itunes_block});
    $xml .= qq!</vsap>\n!;

    my $resp = $client->xml_response($xml);

    if (defined $data->{iuid}) {
        return $resp->findvalue(qq!/vsap/vsap[\@type="web:rss:add:item"]/rssSet/rss/item[\@iuid="$data->{iuid}"]!);
    } else {
        return $resp->findvalue(qq!/vsap/vsap[\@type="web:rss:add:item"]/rssSet/rss/item[title="$data->{title}"]!);
    }
}

1;
