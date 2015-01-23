use Test::More tests => 13;
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

## enable mailboxlist-based view
undef $de;
$de = $t->xml_response(qq!<vsap type='webmail:options:save'>
<webmail_options>
  <use_mailboxlist>yes</use_mailboxlist>
</webmail_options>
</vsap>!);

## test initial list of subscribed folders
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:list"/>! );
@nodes = $de->findnodes('/vsap/vsap[@type="webmail:folders:list"]/folder');
if ($ENV{VST_PLATFORM} eq "Signature") {
        is( @nodes, 6 ) || diag $de->toString(1);
} else {
        is( @nodes, 4 ) || diag $de->toString(1);
}

## subscribe to non-existent folder
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:subscribe"><folder>QuuxFoo</folder></vsap>! );
my $value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 117, "error check: subscribe to non-existent folder fails");

## unsubscribe from non-existent folder
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:unsubscribe"><folder>QuuxFoo</folder></vsap>! );
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
SKIP: {
    skip "Linux: dovecot doesn't consider it an error to unsubscribe from a non-existant folder.", 1
      if $ENV{VST_PLATFORM} eq 'LVPS2' ;

        is($value, 112, "error check: unsubscribe from non-existent folder fails");
}

## subscribe to valid folder
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:create"><folder>QuuxFoo</folder></vsap>! );
my $folder = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is($folder->string_value, 'QuuxFoo', "folder created: QuuxFoo" ) || diag $de->toString(1);
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:subscribe"><folder>QuuxFoo</folder></vsap>! );
$folder = $de->find("/vsap/vsap[\@type='webmail:folders:subscribe']/folder");
is($folder->string_value, 'QuuxFoo', "folder subscribed: QuuxFoo" ) || diag $de->toString(1);

## subscribe to folder with subdirectory
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:create"><folder>Quux/Foo</folder></vsap>! );
$folder = $de->find("/vsap/vsap[\@type='webmail:folders:create']/folder");
is($folder->string_value, 'Quux/Foo', "folder created: Quux/Foo" ) || diag $de->toString(1);
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:subscribe"><folder>Quux/Foo</folder></vsap>! );
$folder = $de->find("/vsap/vsap[\@type='webmail:folders:subscribe']/folder");
is($folder->string_value, 'Quux/Foo', "folder subscribed: Quux/Foo" ) || diag $de->toString(1);

## unsubscribe from valid folder
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:unsubscribe"><folder>QuuxFoo</folder></vsap>! );
$folder = $de->find("/vsap/vsap[\@type='webmail:folders:unsubscribe']/folder");
is($folder->string_value, 'QuuxFoo', "folder unsubscribed: QuuxFoo" ) || diag $de->toString(1);

## unsubscribe from INBOX
undef $de;
$de = $t->xml_response( qq!<vsap type="webmail:folders:unsubscribe"><folder>INBOX</folder></vsap>! );
$value = $de->findvalue("/vsap/vsap[\@type='error']/code");
is($value, 113, "error check: unsubscribe from INBOX fails");

