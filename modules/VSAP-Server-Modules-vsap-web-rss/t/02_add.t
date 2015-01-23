use Test::More tests => 209;
use strict;

## $SMEId: apps/vsap/modules/VSAP-Server-Modules-vsap-web-rss/t/02_add.t,v 1.2.2.1 2006/04/28 14:58:07 kwhyte Exp $

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
## test web:rss:add:feed - add feed; minimal
## ---------------------------------------------------------------------- 

ok( add_feed({ title => 'Minimal feed',
               directory => 'mypodcasts',
               filename => 'my_min_feed.rss',
               link => 'http://www.mytestco.com',
               description => 'This is a minimal feed entry.' }),
             "adding minimal feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]');
    skip "unable to obtain node from feed listing", 7
	unless ok( $node,"found feed node" );
    ok( $node->findvalue('@ruid'), "contains an ruid attribute" );
    is( $node->findvalue('./directory'), 'mypodcasts', "directory is correct" );
    is( $node->findvalue('./filename'), 'my_min_feed.rss', "filename is correct" );
    is( $node->findvalue('./link'), 'http://www.mytestco.com', "link is correct" );
    is( $node->findvalue('./description'), 'This is a minimal feed entry.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:feed - add feed; edit minimal
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="Minimal feed"]/@ruid');

ok( add_feed({ ruid => $ruid,
               edit => 1,
               title => 'My Minimal feed',
               directory => 'minpodcasts',
               filename => 'min_feed.rss',
               link => 'http://www.mintestco.com',
               description => 'This is a minimal feed.' }),
             "editing minimal feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Minimal feed"]');
    skip "unable to obtain node from feed listing", 7
	unless ok( $node,"found feed node" );
    is( $node->findvalue('@ruid'), $ruid, "ruid attribute is correct" );
    is( $node->findvalue('./directory'), 'minpodcasts', "directory is correct" );
    is( $node->findvalue('./filename'), 'min_feed.rss', "filename is correct" );
    is( $node->findvalue('./link'), 'http://www.mintestco.com', "link is correct" );
    is( $node->findvalue('./description'), 'This is a minimal feed.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:feed - add feed; complete
## ---------------------------------------------------------------------- 

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
             "adding complete feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]');
    skip "unable to obtain node from feed listing", 37
	unless ok( $node,"found feed node" );
    ok( $node->findvalue('@ruid'), "contains an ruid attribute" );
    is( $node->findvalue('./directory'), 'podcast', "directory is correct" );
    is( $node->findvalue('./filename'), 'trgs.xml', "filename is correct" );
    is( $node->findvalue('./link'), 'http://www.guardian.co.uk/rickygervais', "link is correct" );
    is( $node->findvalue('./description'), "Ricky Gervais and Steve Merchant, award winning writers and directors of 'The Office' and 'Extras' explore the shallow depths of the mind of Karl Pilkington", "description is correct" );
    is( $node->findvalue('./language'), 'en-us', "language is correct" );
    is( $node->findvalue('./copyright'), 'Ricky Gervais 2006', "copyright is correct" );
    is( $node->findvalue('./pubdate_day'), 'Mon', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '30', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_month'), 'Jan', "pubdate_month is correct" );
    is( $node->findvalue('./pubdate_year'), '2006', "pubdate_year is correct" );
    is( $node->findvalue('./pubdate_hour'), '07', "pubdate_hour is correct" );
    is( $node->findvalue('./pubdate_minute'), '30', "pubdate_minute is correct" );
    is( $node->findvalue('./pubdate_second'), '00', "pubdate_second is correct" );
    is( $node->findvalue('./pubdate_zone'), '-0500', "pubdate_zone is correct" );
    is( $node->findvalue('./category'), 'Comedy', "category is correct" );
    is( $node->findvalue('./generator'), 'VWH Content System v1.0', "generator is correct" );
    is( $node->findvalue('./ttl'), '60', "ttl is correct" );
    is( $node->findvalue('./image_url'), 'http://podcast.rickygervais.com/Gervais_onGU_300.jpg', "image_url is correct" );
    is( $node->findvalue('./image_title'), 'The Ricky Gervais Show', "image_title is correct" );
    is( $node->findvalue('./image_link'), 'http://www.guardian.co.uk/rickygervais', "image_link is correct" );
    is( $node->findvalue('./image_width'), '88', "image_width is correct" );
    is( $node->findvalue('./image_height'), '31', "image_height is correct" );
    is( $node->findvalue('./image_description'), 'The Ricky Gervais Show', "image_description is correct" );
    is( $node->findvalue('./itunes_subtitle'), 'Ricky Steve and Karl spend a half-hour chatting about topics of no importance whatsoever', "itunes_subtitle is correct" );
    is( $node->findvalue('./itunes_author'), 'on Guardian Unlimited', "itunes_author is correct" );
    is( $node->findvalue('./itunes_summary'), "Ricky Gervais and Steve Merchant, award winning writers and directors of 'The Office' and 'Extras' explore the shallow depths of the mind of Karl Pilkington", "itunes_summary is correct" );
    is( $node->findvalue('./itunes_category[1]'), 'Comedy::', "itunes_category[1] is correct" );
    is( $node->findvalue('./itunes_category[2]'), 'Talk Radio::', "itunes_category[2] is correct" );
    is( $node->findvalue('./itunes_category[3]'), 'Arts & Entertainment::Entertainment', "itunes_category[3] is correct" );
    is( $node->findvalue('./itunes_owner_name'), 'Ricky Gervais', "itunes_owner_name is correct" );
    is( $node->findvalue('./itunes_owner_email'), 'email@rickygervais.com', "itunes_owner_email is correct" );
    is( $node->findvalue('./itunes_image'), 'http://podcast.rickygervais.com/Gervais_onGU_300.jpg', "itunes_image is correct" );
    is( $node->findvalue('./itunes_explicit'), 'yes', "itunes_explicit is correct" );
    is( $node->findvalue('./itunes_block'), 'no', "itunes_block is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:feed - add feed; edit complete
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/@ruid');

ok( add_feed({ ruid => $ruid,
               edit => 1,
               directory => 'podcast/ricky',
               filename => 'trgs_podcast.xml',
               pubdate_day => 'Fri',
               pubdate_date => '10',
               pubdate_month => 'Feb',
               itunes_owner_email => 'podcast@rickygervais.com',
               itunes_explicit => 'clean' }),
             "editing complete feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]');
    skip "unable to obtain node from feed listing", 9
	unless ok( $node,"found feed node" );
    is( $node->findvalue('@ruid'), $ruid, "ruid attribute is correct" );
    is( $node->findvalue('./directory'), 'podcast/ricky', "directory is correct" );
    is( $node->findvalue('./filename'), 'trgs_podcast.xml', "filename is correct" );
    is( $node->findvalue('./pubdate_day'), 'Fri', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '10', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_month'), 'Feb', "pubdate_month is correct" );
    is( $node->findvalue('./itunes_owner_email'), 'podcast@rickygervais.com', "itunes_owner_email is correct" );
    is( $node->findvalue('./itunes_image'), 'http://podcast.rickygervais.com/Gervais_onGU_300.jpg', "itunes_image is correct" );
    is( $node->findvalue('./itunes_explicit'), 'clean', "itunes_explicit is correct" );
}

ok( add_feed({ ruid => $ruid,
               edit => 1,
               pubdate_day => 'Wed',
               pubdate_date => '01',
               pubdate_month => 'Mar' }),
             "editing complete feed entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]');
    skip "unable to obtain node from feed listing", 4
	unless ok( $node,"found feed node" );
    is( $node->findvalue('@ruid'), $ruid, "ruid attribute is correct" );
    is( $node->findvalue('./pubdate_day'), 'Wed', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '01', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_month'), 'Mar', "pubdate_month is correct" );
}


## ----------------------------------------------------------------------
## test web:rss:add:feed - add feed; exceptions
## ----------------------------------------------------------------------

## test web:rss:add:feed: error, ruid required for edit

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:add:feed"><edit>1</edit></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '102', "ruid required as expected" );
}

## test web:rss:add:feed: error, ruid not found for edit

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:add:feed"><ruid>0123456789</ruid><edit>1</edit></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:feed"]');
    skip "unable to obtain node from feed listing", 1
        unless ok( $node,"found feed node" );
    is( $node->findvalue('./code'), '104', "ruid not found as expected" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:item - add item; minimal
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Minimal feed"]/@ruid');

ok( add_item({ ruid => $ruid,
               title => 'Minimal item',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode101.mp3',
               description => 'This is a minimal item entry.' }),
             "adding minimal item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Minimal item"]');
    skip "unable to obtain node from item listing", 4 
	unless ok( $node,"found item node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/mypodcasts/episode101.mp3', "fileurl is correct" );
    is( $node->findvalue('./description'), 'This is a minimal item entry.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}

ok( add_item({ ruid => $ruid,
               title => 'My Next Show',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode102.mp3',
               description => 'This is the second episode of my nifty podcast.' }),
             "adding second item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Next Show"]');
    skip "unable to obtain node from item listing", 4 
	unless ok( $node,"found item node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/mypodcasts/episode102.mp3', "fileurl is correct" );
    is( $node->findvalue('./description'), 'This is the second episode of my nifty podcast.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:item - add item; edit minimal
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Minimal feed"]/@ruid');
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Minimal item"]/@iuid');

ok( add_item({ ruid => $ruid,
               iuid => $iuid,
               edit => 1,
               title => 'My Minimal item',
               fileurl => 'http://www.mytestco.com/minpodcasts/episode101.mp3',
               description => 'This is a minimal item entry.' }),
             "editing minimal item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Minimal item"]');
    skip "unable to obtain node from item listing", 7
	unless ok( $node,"found item node" );
    is( $node->findvalue('@iuid'), $iuid, "iuid attribute is correct" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/minpodcasts/episode101.mp3', "fileurl is correct" );
    is( $node->findvalue('./description'), 'This is a minimal item entry.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Minimal feed"]/@ruid');
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="My Next Show"]/@iuid');

ok( add_item({ ruid => $ruid,
               iuid => $iuid,
               edit => 1,
               title => 'Show 2',
               fileurl => 'http://www.mytestco.com/minpodcasts/show2.mp3',
               description => 'This is the second episode.' }),
             "editing second item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Show 2"]');
    skip "unable to obtain node from item listing", 7
	unless ok( $node,"found item node" );
    is( $node->findvalue('@iuid'), $iuid, "iuid attribute is correct" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/minpodcasts/show2.mp3', "fileurl is correct" );
    is( $node->findvalue('./description'), 'This is the second episode.', "description is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:item - add item; complete
## ---------------------------------------------------------------------- 

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

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 101 - Does, Donts and Doughnuts"]');
    skip "unable to obtain node from item listing", 27 
	unless ok( $node,"found item node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
    is( $node->findvalue('./description'), 'The complete guide to deal with everything.', "description is correct" );
    is( $node->findvalue('./author'), 'Gareth Keenan', "author is correct" );
    is( $node->findvalue('./pubdate_day'), 'Sat', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '04', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_month'), 'Mar', "pubdate_month is correct" );
    is( $node->findvalue('./pubdate_year'), '2006', "pubdate_year is correct" );
    is( $node->findvalue('./pubdate_hour'), '06', "pubdate_hour is correct" );
    is( $node->findvalue('./pubdate_minute'), '00', "pubdate_minute is correct" );
    is( $node->findvalue('./pubdate_second'), '01', "pubdate_second is correct" );
    is( $node->findvalue('./pubdate_zone'), '+0000', "pubdate_zone is correct" );
    is( $node->findvalue('./guid'), 'http://www.mytestco.com/mypodcasts/episode101.mp3', "guid is correct" );
    is( $node->findvalue('./itunes_subtitle'), 'Episode 101', "itunes_subtitle is correct" );
    is( $node->findvalue('./itunes_author'), 'Gareth Keenan', "itunes_author is correct" );
    is( $node->findvalue('./itunes_summary'), 'The complete guide to deal with everything.', "itunes_summary is correct" );
    is( $node->findvalue('./itunes_duration_hour'), '00', "itunes_duration_hour is correct" );
    is( $node->findvalue('./itunes_duration_minute'), '43', "itunes_duration_minute is correct" );
    is( $node->findvalue('./itunes_duration_second'), '19', "itunes_duration_second is correct" );
    is( $node->findvalue('./itunes_keywords'), 'does, donts, doughnuts, guide', "itunes_keywords is correct" );
    is( $node->findvalue('./itunes_explicit'), 'yes', "itunes_explicit is correct" );
    is( $node->findvalue('./itunes_category[1]'), 'Comedy::', "itunes_category[1] is correct" );
    is( $node->findvalue('./itunes_category[2]'), 'Music::', "itunes_category[2] is correct" );
    is( $node->findvalue('./itunes_category[3]'), 'Technology::Podcasting', "itunes_category[3] is correct" );
    is( $node->findvalue('./itunes_block'), 'no', "itunes_block is correct" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/mypodcasts/episode101.mp3', "fileurl is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}

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
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 102 - Happy Hour"]');
    skip "unable to obtain node from item listing", 27 
	unless ok( $node,"found item node" );
    ok( $node->findvalue('@iuid'), "contains an iuid attribute" );
    is( $node->findvalue('./description'), 'The crews heads out to happy hour, what could go wrong?', "description is correct" );
    is( $node->findvalue('./author'), 'Tim Canterbury', "author is correct" );
    is( $node->findvalue('./pubdate_day'), 'Sun', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '02', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_month'), 'Apr', "pubdate_month is correct" );
    is( $node->findvalue('./pubdate_year'), '2006', "pubdate_year is correct" );
    is( $node->findvalue('./pubdate_hour'), '15', "pubdate_hour is correct" );
    is( $node->findvalue('./pubdate_minute'), '30', "pubdate_minute is correct" );
    is( $node->findvalue('./pubdate_second'), '01', "pubdate_second is correct" );
    is( $node->findvalue('./pubdate_zone'), '+0200', "pubdate_zone is correct" );
    is( $node->findvalue('./guid'), 'http://www.mytestco.com/mypodcasts/episode102.mp3', "guid is correct" );
    is( $node->findvalue('./itunes_subtitle'), 'Episode 102', "itunes_subtitle is correct" );
    is( $node->findvalue('./itunes_author'), 'Tim Canterbury', "itunes_author is correct" );
    is( $node->findvalue('./itunes_summary'), 'The crews heads out to happy hour, what could go wrong?', "itunes_summary is correct" );
    is( $node->findvalue('./itunes_duration_hour'), '01', "itunes_duration_hour is correct" );
    is( $node->findvalue('./itunes_duration_minute'), '04', "itunes_duration_minute is correct" );
    is( $node->findvalue('./itunes_duration_second'), '54', "itunes_duration_second is correct" );
    is( $node->findvalue('./itunes_keywords'), 'happy, hour, crew, wrong', "itunes_keywords is correct" );
    is( $node->findvalue('./itunes_explicit'), 'yes', "itunes_explicit is correct" );
    is( $node->findvalue('./itunes_category[1]'), 'Comedy::', "itunes_category[1] is correct" );
    is( $node->findvalue('./itunes_category[2]'), 'Food::', "itunes_category[2] is correct" );
    is( $node->findvalue('./itunes_category[3]'), 'International::Canadian', "itunes_category[3] is correct" );
    is( $node->findvalue('./itunes_block'), 'no', "itunes_block is correct" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/mypodcasts/episode102.mp3', "fileurl is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ---------------------------------------------------------------------- 
## test web:rss:add:item - add item; edit complete
## ---------------------------------------------------------------------- 

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/@ruid');
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 101 - Does, Donts and Doughnuts"]/@iuid');

ok( add_item({ ruid => $ruid,
               iuid => $iuid,
               edit => 1,
               title => 'Episode 101',
               description => 'Does, Donts and Doughnuts, the complete guide to deal with everything',
               itunes_summary => 'Does, Donts and Doughnuts, the complete guide to deal with everything',
               itunes_duration_second => '30' }),
             "editing minimal item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 101"]');
    skip "unable to obtain node from item listing", 7
	unless ok( $node,"found item node" );
    is( $node->findvalue('@iuid'), $iuid, "iuid attribute is correct" );
    is( $node->findvalue('./title'), 'Episode 101', "title is correct" );
    is( $node->findvalue('./description'), 'Does, Donts and Doughnuts, the complete guide to deal with everything', "description is correct" );
    is( $node->findvalue('./itunes_summary'), 'Does, Donts and Doughnuts, the complete guide to deal with everything', "itunes_summary is correct" );
    is( $node->findvalue('./itunes_duration_second'), '30', "itunes_duration_second is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="The Ricky Gervais Show"]/@ruid');
undef $iuid;
$iuid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 102 - Happy Hour"]/@iuid');

ok( add_item({ ruid => $ruid,
               iuid => $iuid,
               edit => 1,
               title => 'Episode 102',
               description => 'Happy Hour, crews heads out to happy hour, what could go wrong?',
               author => 'Sir David of Brent',
               pubdate_day => 'Mon',
               pubdate_date => '03',
               pubdate_hour => '08',
               pubdate_minute => '00',
               pubdate_second => '00',
               pubdate_zone => '+0000',
               guid => 'http://www.mytestco.com/mypodcasts/episode_102.mp3',
               itunes_author => 'Sir David of Brent',
               itunes_summary => 'Happy Hour, crews heads out to happy hour, what could go wrong?',
               itunes_duration_hour => '00',
               itunes_duration_minute => '59',
               itunes_duration_second => '58',
               fileurl => 'http://www.mytestco.com/mypodcasts/episode_102.mp3' }),
             "editing second item entry" );

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);

SKIP: { 
    ($node) = $resp->findnodes('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss/item[title="Episode 102"]');
    skip "unable to obtain node from item listing", 19
	unless ok( $node,"found item node" );
    is( $node->findvalue('@iuid'), $iuid, "iuid attribute is correct" );
    is( $node->findvalue('./title'), 'Episode 102', "title is correct" );
    is( $node->findvalue('./description'), 'Happy Hour, crews heads out to happy hour, what could go wrong?', "description is correct" );
    is( $node->findvalue('./author'), 'Sir David of Brent', "author is correct" );
    is( $node->findvalue('./pubdate_day'), 'Mon', "pubdate_day is correct" );
    is( $node->findvalue('./pubdate_date'), '03', "pubdate_date is correct" );
    is( $node->findvalue('./pubdate_hour'), '08', "pubdate_hour is correct" );
    is( $node->findvalue('./pubdate_minute'), '00', "pubdate_minute is correct" );
    is( $node->findvalue('./pubdate_second'), '00', "pubdate_second is correct" );
    is( $node->findvalue('./pubdate_zone'), '+0000', "pubdate_zone is correct" );
    is( $node->findvalue('./guid'), 'http://www.mytestco.com/mypodcasts/episode_102.mp3', "guid is correct" );
    is( $node->findvalue('./itunes_author'), 'Sir David of Brent', "itunes_author is correct" );
    is( $node->findvalue('./itunes_summary'), 'Happy Hour, crews heads out to happy hour, what could go wrong?', "itunes_summary is correct" );
    is( $node->findvalue('./itunes_duration_hour'), '00', "itunes_duration_hour is correct" );
    is( $node->findvalue('./itunes_duration_minute'), '59', "itunes_duration_minute is correct" );
    is( $node->findvalue('./itunes_duration_second'), '58', "itunes_duration_second is correct" );
    is( $node->findvalue('./fileurl'), 'http://www.mytestco.com/mypodcasts/episode_102.mp3', "fileurl is correct" );
    ok( $node->findvalue('./epoch_create'), "contains an epoch_create" );
    ok( $node->findvalue('./epoch_modify'), "contains an epoch_modify" );
}


## ----------------------------------------------------------------------
## test web:rss:add:item - add item; exceptions
## ----------------------------------------------------------------------

## test web:rss:add:item: error, ruid required

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:add:item"/>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:item"]');
    skip "unable to obtain node from item listing", 1
        unless ok( $node,"found item node" );
    is( $node->findvalue('./code'), '102', "ruid required as expected" );
}

## test web:rss:add:item: error, ruid not found

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:add:item"><ruid>0123456789</ruid></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:item"]');
    skip "unable to obtain node from item listing", 1
        unless ok( $node,"found item node" );
    is( $node->findvalue('./code'), '100', "ruid not found as expected" );
}

## test web:rss:add:item: error, iuid required for edit

undef $resp;
$resp = $client->xml_response(q!<vsap type="web:rss:load:feed"/>!);
undef $ruid;
$ruid = $resp->findvalue('/vsap/vsap[@type="web:rss:load:feed"]/rssSet/rss[title="My Minimal feed"]/@ruid');

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:add:item"><ruid>$ruid</ruid><edit>1</edit></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:item"]');
    skip "unable to obtain node from item listing", 1
        unless ok( $node,"found item node" );
    is( $node->findvalue('./code'), '103', "iuid required as expected" );
}

## test web:rss:add:item: error, iuid not found for edit

undef $resp;
$resp = $client->xml_response(qq!<vsap type="web:rss:add:item"><ruid>$ruid</ruid><iuid>0123456789</iuid><edit>1</edit></vsap>!);

SKIP: {
    ($node) = $resp->findnodes('/vsap/vsap[@caller="web:rss:add:item"]');
    skip "unable to obtain node from item listing", 1
        unless ok( $node,"found item node" );
    is( $node->findvalue('./code'), '105', "iuid not found as expected" );
}

END { }

