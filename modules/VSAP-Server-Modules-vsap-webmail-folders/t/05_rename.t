use Test::More tests => 28;
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
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>David</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "David" );
ok( -f $ACCT->mailboxpath.'/David' );

## create some new folders
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>David2</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "David2" );
ok( -f $ACCT->mailboxpath.'/David2' );

## Test a target which already exists. 

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David</folder><new_folder>David2</new_folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="error" and @caller="webmail:folders:rename"]/code'), '109' );

## put it back

## rename it
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David</folder><new_folder>Copperfield</new_folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:folders:rename"]/folder'), 'David' );
is( $de->findvalue('/vsap/vsap[@type="webmail:folders:rename"]/new_folder'), 'Copperfield' );
ok( ! -f $ACCT->mailboxpath.'/David' );
ok(   -f $ACCT->mailboxpath.'/Copperfield' );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>Copperfield</folder><new_folder>Davy</new_folder></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:folders:rename"]/folder'), 'Copperfield' ) || diag $de->toString(1);
is( $de->findvalue('/vsap/vsap[@type="webmail:folders:rename"]/new_folder'), 'Davy' ) || diag $de->toString(1);
ok( ! -f $ACCT->mailboxpath.'/Copperfield' );
ok(   -f $ACCT->mailboxpath.'/Davy' );

## rename with folder that needs utf-7
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:create"><folder>David&amp;Polly</folder></vsap>!);
is( $de->findvalue("/vsap/vsap[\@type='webmail:folders:create']/folder"), "David&Polly" ) || diag $de->toString(1);
ok( -f $ACCT->mailboxpath.'/David&-Polly' );
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:folders:rename"><folder>David&amp;Polly</folder><new_folder>Polly&amp;Copperfield</new_folder></vsap>!);
ok(! -f $ACCT->mailboxpath.'/David&-Polly' );
ok( -f $ACCT->mailboxpath.'/Polly&-Copperfield' );

## try renaming to/from INBOX
undef $de;
$de = $t->xml_response(q!<vsap type="webmail:folders:rename"><folder>INBOX</folder><new_folder>Copperfield</new_folder></vsap>!);
#like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/System folders may not be/i );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David</folder><new_folder>INBOX</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/System folders may not be/i );

## Try renaming with invalid characters. 
undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David2</folder><new_folder>%</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/Illegal character/i );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David2</folder><new_folder>*</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/Illegal character/i );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David2</folder><new_folder>]</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/Illegal character/i );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David2</folder><new_folder>)</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/Illegal character/i );

undef $de;
$de = $t->xml_response(qq!<vsap type="webmail:folders:rename"><folder>David2</folder><new_folder>(</new_folder></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="error"]/message'), qr/Illegal character/i );
