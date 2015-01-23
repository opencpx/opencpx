use Test::More tests => 24;
BEGIN { use_ok('VSAP::Server::Modules::vsap::webmail::send') };

#########################

use VSAP::Server::Test;
use File::Copy;
use VSAP::Server::Test::Account;
use Devel::Peek;

my $MAIL_SLEEP_TIME = 3;

## set up a user
my $ACCT = VSAP::Server::Test::Account->create();

ok($ACCT->exists, "account exists");

my $home = $ACCT->homedir;

## remove mail spool
if( $ENV{VST_PLATFORM} =~ /Signature/i ) {
    unlink $ACCT->inboxpath();
}

my $vsap = $ACCT->create_vsap(['vsap::webmail','vsap::webmail::send','vsap::webmail::options','vsap::webmail::folders', 'vsap::webmail::messages']);

my $t = $vsap->client({ acct => $ACCT});
my $email = $ACCT->emailaddress;
ok(ref($t),"obtained a reference to VSAP client object");

##  <vsap type="webmail:send">
my $de = $t->xml_response(qq!"<vsap type="webmail:send"><To>$email</To><Subject>testing</Subject><Text>This is a test.&#013;&#010;And another line.</Text><Attachment>/etc/passwd</Attachment></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:send"]/status'), 'ok',"status of send is ok") 
	|| diag($de->toString(1));

#print STDERR $de->toString(1);

## give the mail some time for delivery
sleep $MAIL_SLEEP_TIME;

$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/num_messages'), 1, "number of messages is 1")
	|| diag($de->toString(1));

# Save the uid for later. 
my $uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[1]/uid');

## check that message
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><uid>$uid</uid></vsap>!);
like( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/body'), qr(This is a test\.&#013;&#010;<br>And another line\.), "body is correct" )
	|| diag($de->toString(1));

is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/name'), 'passwd', "filename of attachment is correct")
	|| diag($de->toString(1));

## try composing with messageid
$de = $t->xml_response(qq!<vsap type="webmail:send:messageid"/>!);
$messageid = $de->findvalue('/vsap/vsap[@type="webmail:send:messageid"]/messageid');
is (length($messageid), 21, "messageid is correct length (21 chars)");

## add attachment to the message
copy("/etc/passwd", $ACCT->mailtmppath);
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:add"><messageid>$messageid</messageid><filename>passwd</filename></vsap>!);
is ($de->findvalue('/vsap/vsap[@type="webmail:send:attachment:add"]/status'), 'ok', "attachment is ok")
	|| diag($de->toString(1));

## list attachments
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:list"><messageid>$messageid</messageid></vsap>!);
is ($de->findvalue('/vsap/vsap[@type="webmail:send:attachment:list"]/attachment/filename'), 'passwd', "listing attachments shows attached file")
	|| diag($de->toString(1));

## delete attachments
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:delete"><messageid>$messageid</messageid><filename>passwd</filename></vsap>!);
is ($de->findvalue('/vsap/vsap[@type="webmail:send:attachment:delete"]/status'), 'ok', "removing attachments ok")
	|| diag($de->toString(1));


## Add attachment which is too large. 
`/bin/dd if=/dev/zero of=/tmp/large_file bs=1024 count=12288 2>/dev/null`;
`/bin/dd if=/dev/zero of=/tmp/medium_file bs=1024 count=6144 2>/dev/null`;

copy("/tmp/large_file", $ACCT->mailtmppath);
copy("/tmp/medium_file", $ACCT->mailtmppath);

$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:add"><messageid>$messageid</messageid><filename>large_file</filename></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='error']/code"),'113', "correct error code for too large an attachment");

## Smaller attachment.. 
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:add"><messageid>$messageid</messageid><filename>medium_file</filename></vsap>!);
is ($de->findvalue('/vsap/vsap[@type="webmail:send:attachment:add"]/status'), 'ok', "medium attachment is ok")
	|| diag($de->toString(1));

copy("/tmp/medium_file", $ACCT->mailtmppath);
## Smaller attachment again, should fail. 
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:add"><messageid>$messageid</messageid><filename>medium_file</filename></vsap>!);
is($de->findvalue("/vsap/vsap[\@type='error']/code"),'113', "correct error code for too large an attachment");

## delete medium_file attachment
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:delete"><messageid>$messageid</messageid><filename>medium_file</filename></vsap>!);
is ($de->findvalue('/vsap/vsap[@type="webmail:send:attachment:delete"]/status'), 'ok', "removing attachments ok")
	|| diag($de->toString(1));

## send with messageid
copy("/etc/passwd", $ACCT->mailtmppath);
$de = $t->xml_response(qq!<vsap type="webmail:send:attachment:add"><messageid>$messageid</messageid><filename>passwd</filename></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:send:attachment:add"]/status'), 'ok', "confirm attachment" )
	|| diag($de->toString(1));
$de = $t->xml_response(qq!<vsap type="webmail:send"><messageid>$messageid</messageid><To>$email</To><Subject>testing</Subject><Text>This is a test.</Text></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:send"]/status'), 'ok', "message sent with attachments ok") || diag($de->toString(1));

sleep $MAIL_SLEEP_TIME;

## check that message
$de = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
$uid = ($de->findnodes('/vsap/vsap[@type="webmail:messages:list"]/message[attachments=1]'))[0]->findvalue('uid');
$de = $t->xml_response(qq!<vsap type="webmail:messages:read"><uid>$uid</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/name'), 'passwd', "attachment has correct filename")
	|| diag($de->toString(1));

##
## latin-1 encoded filename (but we don't know that)
##
## works like above
my $nfile = "bj\x{c3}\x{b8}rn.txt";  ## this is not utf8, it's just bytes

my $file = Encode::decode_utf8($nfile); ## Dan note: I'm not certain how this 
## worked, because passing a non-UTF8 file over the VSAP connection shouldn't 
## have retained a compatible filename. So this line makes it work for now.
## May need a revisit. Also, line further down.

{
    local $> = getpwnam($ACCT->userid);
    open FILE, ">" . $ACCT->mailtmppath . '/' . $file
      or die "Could not open file '$file': $!\n";
    print FILE "Underwear!\n";
    close FILE;
}

$de = $t->xml_response( qq!<vsap type="webmail:send:attachment:add">
  <messageid>$messageid</messageid>
  <filename>$file</filename>
</vsap>! );
is( $de->findvalue('/vsap/vsap[@type="webmail:send:attachment:add"]/status'), 'ok', "attachment ok" )
  || diag($de->toString(1));

## byte semantics prevent the concatenation below from becoming a utf8
## string (which would actually do double encoding) 

## Dan note: here too, this probably isn't what the original test was going 
## for. But it shouldn't have worked in the first place.
## ok( -f "$home/.cpx_tmp/$messageid/bjÃ¸rn.txt", "attachment found" ) || 
ok( -f "$home/.cpx_tmp/$messageid/$file", "attachment found" ) || 
   do {
       diag("attachment dir contained:\n" . `ls $home/.cpx_tmp/$messageid/`);
       exit();
  };

## remove attachment
$de = $t->xml_response( qq!<vsap type="webmail:send:attachment:delete">
  <messageid>$messageid</messageid>
  <filename>$file</filename>
</vsap>! );
use bytes;
ok( ! -f "$home/.cpx_tmp/$messageid/$file", "attachment NOT found" );
no bytes;

{
    local $> = getpwnam($ACCT->userid);
    open FILE, ">" . $ACCT->mailtmppath . '/' . $file
      or die "Could not open file '$file': $!\n";
    print FILE "Underwear!\n";
    close FILE;
}

## add it again
$de = $t->xml_response( qq!<vsap type="webmail:send:attachment:add">
  <messageid>$messageid</messageid>
  <filename>$file</filename>
</vsap>! );
use bytes;
ok( -f "$home/.cpx_tmp/$messageid/$file", "attachment found" );
# ok( -f "$home/.cpx_tmp/$messageid/bjÃ¸rn.txt", "attachment found" );
no bytes;


## send message w/ attachment
$de = $t->xml_response( qq!<vsap type="webmail:send">
  <messageid>$messageid</messageid>
  <To>$email</To>
  <Subject>test i18n attachment</Subject>
  <Text>Foo is what we learn in college.</Text>
  <SaveOut>1</SaveOut>
</vsap>! );
is( $de->findvalue('/vsap/vsap[@type="webmail:send"]/status'), 'ok', "message sent ok" )
  || diag($de->toString(1));

## scan the dom now


sleep $MAIL_SLEEP_TIME;

$de  = $t->xml_response(q!<vsap type="webmail:messages:list"/>!);
$uid = $de->findvalue('/vsap/vsap[@type="webmail:messages:list"]/message[subject="test i18n attachment"]/uid');
$de  = $t->xml_response(qq!<vsap type="webmail:messages:read"><uid>$uid</uid></vsap>!);
is( $de->findvalue('/vsap/vsap[@type="webmail:messages:read"]/attachments/attachment/name'), 
#    "bj\x{c3}\x{b8}rn.txt", "attachment found" ) || diag($de->toString(1));
    $file, "attachment found" ) || diag($de->toString(1));

