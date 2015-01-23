use Test::More tests => 10;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::messages') };

#########################

use VSAP::Server::Test;
use VSAP::Server::Test::Account;

my $MAIL_PAUSE_TIME = 3; 

## set up a user
$ACCT = VSAP::Server::Test::Account->create();

ok( $ACCT->exists);

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::messages','vsap::webmail::options']);
my $t = $vsap->client({ acct => $ACCT });

ok(ref($t));

ok($ACCT->send_email("test-emails/01-01.txt"));

sleep $MAIL_PAUSE_TIME;

## list message
my $de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
my %nodes = map { $_ => 1 } map { $_->string_value } 
  $de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message/flags/*');
cmp_ok( keys %nodes, ">=", 1 );
ok( $nodes{'\Valid'} );

#print STDERR $de->toString(1);

## set a flag
$de = $t->xml_response(q!<vsap type="webmail:messages:flag">
  <folder>INBOX</folder>
  <uid>1</uid>
  <flag>\Deleted</flag>
</vsap>!);

ok( $de->findnodes('/vsap/vsap[@type="webmail:messages:flag"]') );

## check flags again
$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
%nodes = map { $_ => 1 } map { $_->string_value } 
  $de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message/flags/*');
like( keys %nodes, qr/[23]/ );  ## sometimes \Seen is set
ok( $nodes{'\Deleted'} );
ok( $nodes{'\Valid'} );

END { }

#print STDERR $de->toString(1);
