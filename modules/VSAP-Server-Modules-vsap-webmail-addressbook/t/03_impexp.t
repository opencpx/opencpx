use Test::More tests => 59;
use strict;

BEGIN { use_ok( 'VSAP::Server::Modules::vsap::webmail::addressbook' ); };
BEGIN { use_ok( 'VSAP::Server::Test' ); };
BEGIN { use_ok( 'VSAP::Server::Test::Account' ); };

##################################################
## initialization

my $acct;    # vsap test account object
my $vsap;    # vsap test object
my $client;  # vsap test client object
my $resp;    # vsap response
my $node;    # vsap responce node
my $tmpdir;  # test account tmpdir value

ok( $acct = VSAP::Server::Test::Account->create({type => 'end-user'}), 'create test account' );
ok( $acct->exists, 'test account exists' );
ok( $vsap = $acct->create_vsap(['vsap::webmail::addressbook']), 'started vsapd' );
ok( $client = $vsap->client({acct => $acct}), 'obtained vsap client' );

ok( $tmpdir = $acct->tmpdir, 'obtained tmpdir' );


## ---------------------------------------------------------------------- 
## test address book import: vcf v2.1
## ---------------------------------------------------------------------- 

## test address book import: blank

is( system('cp', '-fp', 'test-files/21-Blank.vcf', $tmpdir), '0', 'cp 21-Blank.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-Blank.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '0', 'records imported is 0' );

## test address book import: single

is( system('cp', '-fp', 'test-files/21-Single.vcf', $tmpdir), '0', 'cp 21-Single.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-Single.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '1', 'records imported is 1' );

## test address book import: multiple

is( system('cp', '-fp', 'test-files/21-Multiple.vcf', $tmpdir), '0', 'cp 21-Multiple.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-Multiple.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '5', 'records processed is 5' );
is( $resp->findvalue('/vsap/vsap/imported'), '5', 'records imported is 5' );

## test address book import: invalid format; missing name

is( system('cp', '-fp', 'test-files/21-NoName.vcf', $tmpdir), '0', 'cp 21-NoName.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-NoName.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '0', 'records imported is 0' );


## ---------------------------------------------------------------------- 
## test address book import: vcf v3.0
## ---------------------------------------------------------------------- 

## test address book import: blank

is( system('cp', '-fp', 'test-files/30-Blank.vcf', $tmpdir), '0', 'cp 30-Blank.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>30-Blank.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '0', 'records imported is 0' );

## test address book import: single

is( system('cp', '-fp', 'test-files/30-Single.vcf', $tmpdir), '0', 'cp 03-Single.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>30-Single.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '1', 'records imported is 1' );

## test address book import: multiple

is( system('cp', '-fp', 'test-files/30-Multiple.vcf', $tmpdir), '0', 'cp 03-Multiple.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>30-Multiple.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '3', 'records processed is 3' );
is( $resp->findvalue('/vsap/vsap/imported'), '3', 'records imported is 3' );

## test address book import: invalid format; missing name

is( system('cp', '-fp', 'test-files/30-NoName.vcf', $tmpdir), '0', 'cp 30-NoName.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>30-NoName.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '1', 'records processed is 1' );
is( $resp->findvalue('/vsap/vsap/imported'), '0', 'records imported is 0' );


## ---------------------------------------------------------------------- 
## test address book import: csv Outlook Express
## ---------------------------------------------------------------------- 

## test address book import: multiple

is( system('cp', '-fp', 'test-files/Express-Multiple.csv', $tmpdir), '0', 'cp Express-Multiple.csv test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>Express-Multiple.csv</file_name>
  <file_type>csv</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '3', 'records processed is 3' );
is( $resp->findvalue('/vsap/vsap/imported'), '3', 'records imported is 3' );


## ---------------------------------------------------------------------- 
## test address book import: csv Outlook
## ---------------------------------------------------------------------- 

## test address book import: multiple

is( system('cp', '-fp', 'test-files/Outlook-Multiple.csv', $tmpdir), '0', 'cp Outlook-Multiple.csv test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>Outlook-Multiple.csv</file_name>
  <file_type>csv</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/processed'), '3', 'records processed is 3' );
is( $resp->findvalue('/vsap/vsap/imported'), '3', 'records imported is 3' );


## ---------------------------------------------------------------------- 
## test address book import: exceptions
## ---------------------------------------------------------------------- 

## test address book import: error, invalid file name

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>Bad.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/code'), '105', 'code is 105' );
is( $resp->findvalue('/vsap/vsap/message'), 'Invalid file name: Bad.vcf', 'message is Invalid file name' );

## test address book import: error, invalid file format

is( system('cp', '-fp', 'test-files/Empty.vcf', $tmpdir), '0', 'cp Empty.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>Empty.vcf</file_name>
  <file_type>vcf</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/code'), '106', 'code is 106' );
is( $resp->findvalue('/vsap/vsap/message'), 'Invalid file format: Empty.vcf', 'message is Invalid file format' );

## test address book import: error, empty file type

is( system('cp', '-fp', 'test-files/21-Blank.vcf', $tmpdir), '0', 'cp 21-Blank.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-Blank.vcf</file_name>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/code'), '107', 'code is 107' );
is( $resp->findvalue('/vsap/vsap/message'), 'Empty or missing file type', 'message is Empty or missing file type' );

## test address book import: error, invalid file type

is( system('cp', '-fp', 'test-files/21-Blank.vcf', $tmpdir), '0', 'cp 21-Blank.vcf test file' );

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:import">
  <file_name>21-Blank.vcf</file_name>
  <file_type>exe</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/code'), '108', 'code is 108' );
is( $resp->findvalue('/vsap/vsap/message'), 'Invalid file type: exe', 'message is Invalid file type' );


## ---------------------------------------------------------------------- 
## test address book export: vcf
## ---------------------------------------------------------------------- 

## test address book export: full

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:export">
  <file_type>vcf</file_type>
</vsap>!);

ok( -s $resp->findvalue('/vsap/vsap/path'), 'vcf export file exists');
is( $resp->findvalue('/vsap/vsap/processed'), '16', 'records processed is 16' );
is( $resp->findvalue('/vsap/vsap/exported'), '16', 'records exported is 16' );


## ---------------------------------------------------------------------- 
## test address book export: csv
## ---------------------------------------------------------------------- 

## test address book export: full

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:export">
  <file_type>csv</file_type>
</vsap>!);

ok( -s $resp->findvalue('/vsap/vsap/path'), 'csv export file exists');
is( $resp->findvalue('/vsap/vsap/processed'), '16', 'records processed is 16' );
is( $resp->findvalue('/vsap/vsap/exported'), '16', 'records exported is 16' );


## ---------------------------------------------------------------------- 
## test address book export: exceptions
## ---------------------------------------------------------------------- 

## test address book export: error, empty file type

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:export" />!);

is( $resp->findvalue('/vsap/vsap/code'), '107', 'code is 107' );
is( $resp->findvalue('/vsap/vsap/message'), 'Empty or missing file type', 'message is Empty or missing file type' );

## test address book import: error, invalid file type

undef $resp;
$resp = $client->xml_response(q!<vsap type="webmail:addressbook:export">
  <file_type>exe</file_type>
</vsap>!);

is( $resp->findvalue('/vsap/vsap/code'), '108', 'code is 108' );
is( $resp->findvalue('/vsap/vsap/message'), 'Invalid file type: exe', 'message is Invalid file type' );


END { }

