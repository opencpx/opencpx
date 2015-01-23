use Test::More tests => 23;
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
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:list']/folder[name='INBOX']/size"), 0 );

## create some new folders
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>David</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "David" );

$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Barkis</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "Barkis" );

$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Old Junk</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "Old Junk" );

$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Em'lee</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "Em'lee" );

ok( -f $ACCT->mailboxpath."/Em'lee" );
$de = $t->xml_response(qq!<vsap type="webmail:folders:delete"><folder>Em'lee</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:delete']/folder"), "Em'lee" );
ok( ! -f $ACCT->mailboxpath."/Em'lee" );

## test multiple folders, including system folders (Sent Items, Trash, etc.)
$de = $t->xml_response(qq!<vsap type="webmail:folders:delete">
  <folder>David</folder>
  <folder>Trash</folder>
  <folder>Old Junk</folder>
  <folder>Sent Items</folder>
</vsap>!);

#print STDERR $de->toString(1);

my @nodes = $de->findnodes('/vsap/vsap[@type="webmail:folders:delete"]/*');
is( scalar(@nodes), 4 );
ok( ! -e $ACCT->mailboxpath.'/David' );
ok( ! -e $ACCT->mailboxpath.'/Old Junk' );
ok(   -f $ACCT->mailboxpath.'/Sent Items' );
ok(   -f $ACCT->mailboxpath.'/Trash' );

## try INBOX (should error)
$de = $t->xml_response(qq!<vsap type="webmail:folders:delete"><folder>INBOX</folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error"]/message'), 'Cannot delete INBOX' );

## test folders that need modified utf-7 encoding
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Em&amp;lee</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "Em&lee" );
ok( -f $ACCT->mailboxpath."/Em&-lee" );
$de = $t->xml_response(qq!<vsap type="webmail:folders:delete"><folder>Em&amp;lee</folder></vsap>!);
ok( ! -f $ACCT->mailboxpath."/Em&-lee" );

$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>Trashy Files</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "Trashy Files", "create 'Trashy Files' folder to test prefix of system folder." );

$de = $t->xml_response(qq!<vsap type="webmail:folders:delete"><folder>Trashy Files</folder></vsap>!);
ok( ! -f $ACCT->mailboxpath."/Trashy Files", "check that folder doesn't exist.");
