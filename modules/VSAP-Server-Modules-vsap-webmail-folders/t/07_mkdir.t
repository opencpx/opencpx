use Test::More tests => 9;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::folders') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT);

ok($ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail::folders']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));

## try and make a subdirectory without specifying a name
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:mkdir"/>! );
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 114, "error check: mkdir without specifying name fails");

## try and make a subdirectory with bad chars
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:mkdir"><subdirectory>Quux*Foo</subdirectory></vsap>! );
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 100, "error check: mkdir with invalid name with fails (bad chars)");

## try and make a subdirectory over the top of an existing folder
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:create"><folder>QuuxFoo</folder></vsap>! );
my $folder = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is($folder->string_value, 'QuuxFoo', "folder created: QuuxFoo" ) || diag $de->toString(1);
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:mkdir"><subdirectory>QuuxFoo</subdirectory></vsap>! );
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 115, "error check: mkdir fails when file exists");

## make a valid subdirectory
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:mkdir"><subdirectory>QuuxDir</subdirectory></vsap>! );
$folder = $de->find("/vsap/vsap[\@type='webmail:folders:mkdir']/subdirectory");
is($folder->string_value, 'QuuxDir', "subdirectory created: QuuxDir" ) || diag $de->toString(1);

