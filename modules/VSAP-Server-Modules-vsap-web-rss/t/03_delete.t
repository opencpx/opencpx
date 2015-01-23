use Test::More tests => 102;
use strict;

## $SMEId: apps/vsap/modules/VSAP-Server-Modules-vsap-web-rss/t/03_delete.t,v 1.2.2.1 2006/04/28 14:58:07 kwhyte Exp $

BEGIN { use_ok( 'VSAP::Server::Modules::vsap::web::rss' ) };
BEGIN { use_ok( 'VSAP::Server::Test' ); };
BEGIN { use_ok( 'VSAP::Server::Test::Account' ); };

##################################################
## initialization

use POSIX('uname');
our $VPS = ( ( -d '/skel' ) || ( (POSIX::uname())[0] =~ /Linux/ ) ) ? 1 : 0;

our $acct;   # vsap test account object
my $vsap;    # vsap test object
our $client; # vsap test client object
my $resp;    # vsap response
my $node;    # vsap responce node
my @nodes;   # vsap responce nodes
my $ruid;    # rss unique id
my $iuid;    # item unique id

ok( $acct = VSAP::Server::Test::Account->create({type => 'account-owner'}), "create test account" );
ok( $acct->exists, "test account exists" );
if( $VPS ) {
    ok( $vsap = $acct->create_vsap(['vsap::web::rss','vsap::domain']),"started vsapd" );
}
else {
    ok( $vsap = $acct->create_vsap(['vsap::web::rss']),"started vsapd" );
}
ok( $client = $vsap->client({acct => $acct}), "obtained vsap client" );

## set rssfeeds file
our $RSSFEEDS;
if( $VPS ) {
    $RSSFEEDS = $acct->homedir . '/.cpx/rssfeeds.xml';
}
else {
    $RSSFEEDS = $acct->homedir . '/users/' . $acct->username . '/.cpx/rssfeeds.xml';
}

require 't/rssfeed.pl';


## ---------------------------------------------------------------------- 
## create test feeds and items for deletion
## ---------------------------------------------------------------------- 

ok( add_feed({ title => 'Minimal feed',
               directory => 'mypodcasts',
               filename => 'my_min_feed.rss',
               link => 'http://www.mytestco.com',
               description => 'This is a minimal feed entry.' }),
             "adding first feed entry" );

ok( add_feed({ title => 'My Happy Fun Hour',
               directory => 'happyfun/shows',
               filename => 'podcast_feed.rss',
               link => 'http://www.happyfunhour.com/happyfun/',
               description => "Um, not sure really",
               language => 'en',
               copyright => '2006 Happy Fun Hour Inc',
               category => 'Talk Radio' }),
             "adding second feed entry" );

ok( add_feed({ title => 'The Ricky Gervais Show',
               directory => 'podcast',
               filename => 'trgs.xml',
               link => 'http://www.guardian.co.uk/rickygervais',
               description => "Ricky Gervais and Steve Merchant, award winning writers and directors of 'The Office' and 'Extras' explore the shallow depths of the mind of Karl Pilkington",
               language => 'en-us',
               copyright => 'Ricky Gervais 2006',
               pubdate_day => 'Mon',
               pubdate_date => '30',
               pubdate_month => 'Jan',
               pubdate_year => '2006',
               pubdate_hour => '07',
               pubdate_minute => '30',
               pubdate_second => '00',
               pubdate_zone => '-0500',
               category => 'Comedy',
               generator => 'VWH Content System v1.0',
               ttl => '60',
               image_url => 'http://podcast.rickygervais.com/Gervais_onGU_300.jpg',
               image_title => 'The Ricky Gervais Show',
               image_link => 'http://www.guardian.co.uk/rickygervais',
               image_width => '88',
               image_height => '31',
               image_description => 'The Ricky Gervais Show',
               itunes_subtitle => 'Ricky Steve and Karl spend a half-hour chatting about topics of no importance whatsoever',
               itunes_author => 'on Guardian Unlimited',
               itunes_summary => "Ricky Gervais and Steve Merchant, award winning writers and directors of 'The Office' and 'Extras' explore the shallow depths of the mind of Karl Pilkington",
               itunes_category => [ 'Comedy::', 'Talk Radio::', 'Arts &amp; Entertainment::Entertainment'],
               itunes_owner_name => 'Ricky Gervais',
               itunes_owner_email => 'email@rickygervais.com',
               itunes_image => 'http://podcast.rickygervais.com/Gervais_onGU_300.jpg',
               itunes_explicit => 'yes',
               itunes_block => 'no' }),
             "adding third feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@ruid'), "contains an ruid attribute" );
}

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Happy Fun Hour"]');
    skip "unable to obtain node from feed listing", 1
	unless ok( $node,"found feed node" );
    ok( $node->findvalue('@ruid'), "contains an ruid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@ruid'), "contains an ruid attribute" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Minimal item',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode101.mp3',
               description => 'This is a minimal item entry.' }),
             "adding first item entry" );

ok( add_item({ ruid => $ruid,
               title => 'My Next Show',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode102.mp3',
               description => 'This is the second episode of my nifty podcast.' }),
             "adding second item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Happy Fun Hour"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Show 1001',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1001.mov',
               description => 'Our very first show',
               author => 'John Doe' }),
             "adding first item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Show 1002',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1002.mov',
               description => 'Our second show ever',
               author => 'Jane Doe' }),
             "adding second item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Show 1003',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1003.mov',
               description => 'Our third show, the novelty has worn off',
               author => 'John and Jane Doe' }),
             "adding third item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Episode 101 - Does, Donts and Doughnuts',
               description => 'The complete guide to deal with everything.',
               author => 'Gareth Keenan',
               pubdate_day => 'Sat',
               pubdate_date => '04',
               pubdate_month => 'Mar',
               pubdate_year => '2006',
               pubdate_hour => '06',
               pubdate_minute => '00',
               pubdate_second => '01',
               pubdate_zone => '+0000',
               guid => 'http://www.mytestco.com/mypodcasts/episode101.mp3',
               itunes_subtitle => 'Episode 101',
               itunes_author => 'Gareth Keenan',
               itunes_summary => 'The complete guide to deal with everything.',
               itunes_duration_hour => '00',
               itunes_duration_minute => '43',
               itunes_duration_second => '19',
               itunes_keywords => 'does, donts, doughnuts, guide',
               itunes_explicit => 'yes',
               itunes_category => [ 'Comedy::', 'Music::', 'Technology::Podcasting'],
               itunes_block => 'no',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode101.mp3' }),
             "adding complete item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Episode 102 - Happy Hour',
               description => 'The crews heads out to happy hour, what could go wrong?',
               author => 'Tim Canterbury',
               pubdate_day => 'Sun',
               pubdate_date => '02',
               pubdate_month => 'Apr',
               pubdate_year => '2006',
               pubdate_hour => '15',
               pubdate_minute => '30',
               pubdate_second => '01',
               pubdate_zone => '+0200',
               guid => 'http://www.mytestco.com/mypodcasts/episode102.mp3',
               itunes_subtitle => 'Episode 102',
               itunes_author => 'Tim Canterbury',
               itunes_summary => 'The crews heads out to happy hour, what could go wrong?',
               itunes_duration_hour => '01',
               itunes_duration_minute => '04',
               itunes_duration_second => '54',
               itunes_keywords => 'happy, hour, crew, wrong',
               itunes_explicit => 'yes',
               itunes_category => [ 'Comedy::', 'Food::', 'International::Canadian'],
               itunes_block => 'no',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode102.mp3' }),
             "adding complete item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Minimal item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Next Show"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1001"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1002"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1003"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 101 - Does, Donts and Doughnuts"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 102 - Happy Hour"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}


## ---------------------------------------------------------------------- 
## test web:rss:delete:item - delete item; single
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Minimal item"]/@iuid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./iuid'), $iuid, "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Next Show"]/@iuid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./iuid'), $iuid, "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1001"]/@iuid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./iuid'), $iuid, "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1002"]/@iuid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./iuid'), $iuid, "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1003"]/@iuid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./iuid'), $iuid, "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$iuid</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}


## ---------------------------------------------------------------------- 
## test web:rss:delete:item - delete item; full
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef @nodes;
foreach ( $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/item') ) {
    push @nodes, $_->findvalue('@iuid');
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:item"><iuid>$nodes[0]</iuid><iuid>$nodes[1]</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]/iuid[1]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('.'), $nodes[0], "iuid attribute is correct" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:item"]/iuid[2]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('.'), $nodes[1], "iuid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$nodes[0]</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:item"><iuid>$nodes[1]</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '105', "entry not found as expected" );
}


## ----------------------------------------------------------------------
## test web:rss:delete:item - delete item; exceptions
## ----------------------------------------------------------------------

## test web:rss:delete:item: error, iuid not found 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:delete:item"><iuid>0123456789</iuid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:delete:item"]');
    skip "unable to obtain node from item listing", 1
        unless ok( $node,"found item node" );
    is( $node->findvalue('./code'), '100', "iuid not found as expected" );
}


## ---------------------------------------------------------------------- 
## recreate test items for deletion
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Minimal item',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode101.mp3',
               description => 'This is a minimal item entry.' }),
             "adding first item entry" );

ok( add_item({ ruid => $ruid,
               title => 'My Next Show',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode102.mp3',
               description => 'This is the second episode of my nifty podcast.' }),
             "adding second item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Happy Fun Hour"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Show 1001',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1001.mov',
               description => 'Our very first show',
               author => 'John Doe' }),
             "adding first item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Show 1002',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1002.mov',
               description => 'Our second show ever',
               author => 'Jane Doe' }),
             "adding second item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Show 1003',
               fileurl => 'http://www.happyfunhour.com/happyfun/shows/show_1003.mov',
               description => 'Our third show, the novelty has worn off',
               author => 'John and Jane Doe' }),
             "adding third item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Episode 101 - Does, Donts and Doughnuts',
               description => 'The complete guide to deal with everything.',
               author => 'Gareth Keenan',
               pubdate_day => 'Sat',
               pubdate_date => '04',
               pubdate_month => 'Mar',
               pubdate_year => '2006',
               pubdate_hour => '06',
               pubdate_minute => '00',
               pubdate_second => '01',
               pubdate_zone => '+0000',
               guid => 'http://www.mytestco.com/mypodcasts/episode101.mp3',
               itunes_subtitle => 'Episode 101',
               itunes_author => 'Gareth Keenan',
               itunes_summary => 'The complete guide to deal with everything.',
               itunes_duration_hour => '00',
               itunes_duration_minute => '43',
               itunes_duration_second => '19',
               itunes_keywords => 'does, donts, doughnuts, guide',
               itunes_explicit => 'yes',
               itunes_category => [ 'Comedy::', 'Music::', 'Technology::Podcasting'],
               itunes_block => 'no',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode101.mp3' }),
             "adding complete item entry" );

ok( add_item({ ruid => $ruid,
               title => 'Episode 102 - Happy Hour',
               description => 'The crews heads out to happy hour, what could go wrong?',
               author => 'Tim Canterbury',
               pubdate_day => 'Sun',
               pubdate_date => '02',
               pubdate_month => 'Apr',
               pubdate_year => '2006',
               pubdate_hour => '15',
               pubdate_minute => '30',
               pubdate_second => '01',
               pubdate_zone => '+0200',
               guid => 'http://www.mytestco.com/mypodcasts/episode102.mp3',
               itunes_subtitle => 'Episode 102',
               itunes_author => 'Tim Canterbury',
               itunes_summary => 'The crews heads out to happy hour, what could go wrong?',
               itunes_duration_hour => '01',
               itunes_duration_minute => '04',
               itunes_duration_second => '54',
               itunes_keywords => 'happy, hour, crew, wrong',
               itunes_explicit => 'yes',
               itunes_category => [ 'Comedy::', 'Food::', 'International::Canadian'],
               itunes_block => 'no',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode102.mp3' }),
             "adding complete item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Minimal item"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Next Show"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1001"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1002"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 1003"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 101 - Does, Donts and Doughnuts"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 102 - Happy Hour"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
}


## ---------------------------------------------------------------------- 
## test web:rss:delete:feed - delete feed; single
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]/@ruid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:feed"><ruid>$ruid</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./ruid'), $ruid, "ruid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:feed"><ruid>$ruid</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '104', "entry not found as expected" );
}


## ---------------------------------------------------------------------- 
## test web:rss:delete:feed - delete feed; full
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef @nodes;
foreach ( $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss') ) {
    push @nodes, $_->findvalue('@ruid');
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:delete:feed"><ruid>$nodes[0]</ruid><ruid>$nodes[1]</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:feed"]/ruid[1]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('.'), $nodes[0], "ruid attribute is correct" );
}

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:delete:feed"]/ruid[2]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('.'), $nodes[1], "ruid attribute is correct" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:feed"><ruid>$nodes[0]</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '104', "entry not found as expected" );
}

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:load:feed"><ruid>$nodes[1]</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:load:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '104', "entry not found as expected" );
}


## ----------------------------------------------------------------------
## test web:rss:delete:feed - delete feed; exceptions
## ----------------------------------------------------------------------

## test web:rss:delete:feed: error, ruid not found 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:delete:feed"><ruid>0123456789</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:delete:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '100', "ruid not found as expected" );
}

END { }

