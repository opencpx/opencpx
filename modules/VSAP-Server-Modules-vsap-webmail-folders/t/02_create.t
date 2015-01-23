use Test::More tests => 16;
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

## list the folders
my $de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
my $nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Bunkus']");
is( $nl->string_value, '' );

## create a new mailbox
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Bunkus</folder></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is( $nl->string_value, "Bunkus" ) || diag $de->toString(1);

# Subscribe to newly created folder so it shows up in the listing.
$de = $t->xml_response( qq!<vsap type="webmail:folders:subscribe"><folder>Bunkus</folder></vsap>! );

## list the folders again
$de = $t->xml_response(qq!<vsap type="webmail:folders:list"/>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:list']/folder[name='Bunkus']/size");
cmp_ok( $nl->string_value,'==', -s $ACCT->mailboxpath.'/Bunkus') || $de->toString(1);

## try creating a bogus folder
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num%num</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Illegal character) );

## try creating a bogus folder
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num*num</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Illegal character) );

## try creating a bogus folder
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num]num</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Illegal character) );

## try creating a bogus folder
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num)num</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Illegal character) );

## try creating a bogus folder
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num(num</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr(Illegal character) );

## try creating a folder with a subdirectory specification
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>Num/num</folder></vsap>!);
ok( -s $ACCT->mailboxpath.'/Num/num', "created folder with subdirectory");

## try creating with ampersand
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>amphere&amp;go</folder></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is( $nl->string_value, "amphere&go" );

use encoding 'utf8';
## try creating a folder with full width katakana
$de = $t->xml_response(q!<vsap type="webmail:folders:create"><folder>２００７メール</folder></vsap>!);
$nl = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is( $nl->string_value, "２００７メール", "Creating folder with full width katakana." );
no encoding;

## create an existing folder (should have an error)
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Bunkus</folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/[already|File] exists/ );
