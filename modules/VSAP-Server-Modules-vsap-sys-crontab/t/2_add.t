use Test::More tests => 46;
## this hack also found in vsapd; it pushes vendor_perl higher than
## site_perl in Perl's @INC array so we find the right modules and
## versions of those modules. -scottw
BEGIN {
    my @vendor = grep {   m!/vendor_perl! } @INC;
    @INC       = grep { ! m!/vendor_perl! } @INC;
    my $i = 0; for ( @INC ) { last if m!/site_perl!; $i++ }
    splice @INC, $i, 0, @vendor;
    use_ok('VSAP::Server::Modules::vsap::sys::crontab');
};

#########################

use VSAP::Server::Test::Account;

##
## test setup
##
my $ACCT = create VSAP::Server::Test::Account( { type => 'account-owner' } );

##
## set crontab file
##
our $CRONTAB;
our $SIG = 0;
our $VPS = 0;
our $LVPS = 0;
use POSIX qw(uname);
if ( -d '/skel' ) {
    # For FreeBSD VPS2
    $VPS = 1;
    $CRONTAB = '/etc/crontab';
} elsif ( (POSIX::uname())[0] =~ /Linux/ ) {
    # For Linux VPS2
    $LVPS = 1;
    $CRONTAB = '/etc/crontab';
} else {
    # For Signature
    $SIG = 1;
    $CRONTAB = $ACCT->homedir . '/etc/crontab';
}

## set vsap object based on Sig or no
my @modules = qw(vsap::sys::crontab);
push @modules, 'vsap::server::users::prefs' if $SIG;
my $vsap = $ACCT->create_vsap( \@modules );
my $t    = $vsap->client( { acct => $ACCT } );
ok( ref($t), 'got vsap server test object' );
my $de;
my $block_id;

require 't/crontab.pl';

##
## set web user
##
my $WEBUSER;
if ($SIG) {
    # For Signature
    $WEBUSER = $ACCT->userid;
} elsif ($LVPS) {
    # For Linux VPS2
    $WEBUSER = 'apache';
} else {
    # For FreeBSD VPS2
    $WEBUSER = 'www';
}
    
##
## try to break it
##

## test missing/bad schedule
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block>
    <comment>run my stats every day</comment>
    <event>
      <schedule>
        <minute>*/10</minute>
        <hour>3</hour>
        <dom>*</dom>
        <dow>*</dow>
      </schedule>
      <user>daemon</user>
      <command>$HOME/bin/mystats.sh</command>
    </event>
  </block>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"]/code'), 103, "illegal schedule (month missing)" );

## test missing/bad user
SKIP: {
    skip "illegal user", 1 if ($SIG);
    undef $de;
    $de = $t->xml_response(q!<vsap type="sys:crontab:add">
      <block>
        <comment>run my stats every day</comment>
        <event>
          <schedule>
            <minute>*/10</minute>
            <hour>3</hour>
            <dom>*</dom>
            <month>*</month>
            <dow>*</dow>
          </schedule>
          <user>joedoesnotexist</user>
          <command>$HOME/bin/mystats.sh</command>
        </event>
      </block>
    </vsap>!);

    is( $de->findvalue('/vsap/vsap[@type="error"]/code'), 104, "illegal user" );
}

## test missing command
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block>
    <comment>run my stats every day</comment>
    <event>
      <schedule>
        <minute>*/10</minute>
        <hour>3</hour>
        <dom>*</dom>
        <month>*</month>
        <dow>*</dow>
      </schedule>
      <user>daemon</user>
      <command/>
    </event>
  </block>
</vsap>!);

is( $de->findvalue('/vsap/vsap[@type="error"]/code'), 105, "illegal command" );

SKIP: {
    skip "TZ setup for Sig", 0 unless $SIG;

    undef $de;
    $de = $t->xml_response(qq!<vsap type="server:users:prefs:save">
  <timeZoneInfo>Europe/Vatican</timeZoneInfo>
</vsap>!);

}

##
## add new block to empty crontab
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block>
    <comment>run my stats every day</comment>
    <event>
      <schedule>
        <minute>*/10</minute>
        <hour>3</hour>
        <dom>*</dom>
        <month>*</month>
        <dow>*</dow>
      </schedule>
      <user>$WEBUSER</user>
      <command>\$HOME/bin/mystats.sh</command>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));

SKIP: {
    skip "TZ var set for Sig", 1 unless $SIG;

    ## make sure the TZ env is set for this account, based on the user prefs
    is( $nodes[1]->findvalue('env[name="TZ"]/value'), 'Europe/Vatican', 'TZ variable set' );
}

## now the rest of the crontab
is( $nodes[1]->findvalue('comment'), 'run my stats every day', 'comment set' );
is( $nodes[1]->findvalue('event/schedule/hour'), 3, 'hour set' );
if ($SIG) {
    is( $nodes[1]->findvalue('event/user'), '', 'user set' );
} else {
    is( $nodes[1]->findvalue('event/user'), $WEBUSER, 'user set' );
}
is( $nodes[1]->findvalue('event/command'), '$HOME/bin/mystats.sh', 'command set' );

## make sure Config::Crontab always prefers 'special' over everything else
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block>
    <comment>clean my shorts every day</comment>
    <event>
      <schedule>
        <minute>*/10</minute>
        <hour>3</hour>
        <dom>*</dom>
        <month>*</month>
        <dow>*</dow>
        <special>@daily</special>
      </schedule>
      <user>daemon</user>
      <command>/bin/mystats.sh</command>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[2]->findvalue('comment'), 'clean my shorts every day', "comment set" );
is( $nodes[2]->findvalue('event/schedule/special'), '@daily', 'special set' );
is( $nodes[2]->findvalue('event/schedule/hour'), '', 'hour not set' );
is( $nodes[2]->findvalue('event/schedule/dow'), '', 'dow not set' );

## make sure root user is ok
undef $de;
$de = $t->xml_response(q!<vsap type="sys:crontab:add">
  <block>
    <comment>run my stats every day</comment>
    <event>
      <schedule>
        <minute>13</minute>
        <hour>7</hour>
        <dom>*</dom>
        <month>1-12</month>
        <dow>*</dow>
      </schedule>
      <user>root</user>
      <command>/bin/stats.sh</command>
    </event>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
if ($SIG) {
    is( $nodes[3]->findvalue('event/user'), '', 'root user ok' );
} else {
    is( $nodes[3]->findvalue('event/user'), 'root', 'root user ok' );
}
is( $nodes[3]->findvalue('event/command'), '/bin/stats.sh', 'command set' );

## add event to non-existent block
undef $de;
$de = $t->xml_response(qq#<vsap type="sys:crontab:add">
  <block id="10">
    <comment>blah blah blah</comment>
    <event>
      <schedule>
        <minute>10</minute>
        <hour>22</hour>
        <dom>*</dom>
        <month>1-7,9-12</month>
        <dow>1-5</dow>
      </schedule>
      <user>daemon</user>
      <command>echo "Time for bed!" | mail -s "bedtime!" sleepyclub</command>
    </event>
  </block>
</vsap>#);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
if ($SIG) {
    is( $nodes[4]->findvalue('event[1]/user'), '', 'new event user' );
} else {
    is( $nodes[4]->findvalue('event[1]/user'), 'daemon', 'new event user' );
}
like( $nodes[4]->findvalue('event[1]/command'), qr(^echo.*sleepyclub$), 'new command set' );
is( $nodes[4]->findvalue('comment'), 'blah blah blah', 'comment set' );

#undef $de;
#$de = $t->xml_response(qq!<vsap type="sys:crontab:list"/>!);
#print STDERR $de->toString(1);

##
## write out a fresh default crontab file
##
if ($SIG) {
    write_usr_cron(0);
} else {
    write_sys_cron(0);
}

##
## add new block w/o comment
##
undef $de;
$de = $t->xml_response(qq#<vsap type="sys:crontab:add">
  <block>
  <comment/>
  <event>
    <schedule>
      <minute>10</minute>
      <hour>12</hour>
      <dom>*</dom>
      <month>1-7,9-12</month>
      <dow>1-5</dow>
    </schedule>
    <user>$WEBUSER</user>
    <command>echo "Time for lunch!" | mail -s "lunchtime!" lunchclub</command>
  </event>
  </block>
</vsap>#);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[7]->findvalue('comment'), '', 'comment empty' );
is( $nodes[7]->findvalue('event/schedule/month'), '1-7,9-12', 'month set' );

##
## multi-line comment
##
undef $de;
$de = $t->xml_response(qq#<vsap type="sys:crontab:add">
  <block>
    <comment>run my stats every day</comment>
    <comment>don't mess with Texas!</comment>
    <event>
      <schedule>
        <minute>*/10</minute>
        <hour>3</hour>
        <dom>*</dom>
        <month>*</month>
        <dow>*</dow>
      </schedule>
      <user>$WEBUSER</user>
      <command>\$HOME/bin/mystats.sh</command>
    </event>
  </block>
</vsap>#);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[8]->findvalue('comment[1]'), 'run my stats every day', 'comment line 1' );
is( $nodes[8]->findvalue('comment[2]'), "don't mess with Texas!", 'comment line 2' );
is( $nodes[8]->findvalue('event/schedule/minute'), '*/10', 'minute set' );

##
## add new entry to existing block
##
undef $de;
$de = $t->xml_response(qq#<vsap type="sys:crontab:add">
  <block id="7">
    <event>
      <schedule>
        <minute>10</minute>
        <hour>22</hour>
        <dom>*</dom>
        <month>1-7,9-12</month>
        <dow>1-5</dow>
      </schedule>
      <user>bin</user>
      <command>echo "Time for bed!" | mail -s "bedtime!" sleepyclub</command>
    </event>
  </block>
</vsap>#);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
if ($SIG) {
    is( $nodes[7]->findvalue('event[1]/user'), '', 'existing event user' );
} else {
    is( $nodes[7]->findvalue('event[1]/user'), $WEBUSER, 'existing event user' );
}
like( $nodes[7]->findvalue('event[1]/command'), qr(^echo.*lunchclub$), 'existing event command' );
if ($SIG) {
    is( $nodes[7]->findvalue('event[2]/user'), '', 'new event user' );
} else {
    is( $nodes[7]->findvalue('event[2]/user'), 'bin', 'new event user' );
}
like( $nodes[7]->findvalue('event[2]/command'), qr(^echo.*sleepyclub$), 'new command set' );
is( $nodes[7]->findvalue('comment'), '', 'existing comment empty' );

##
## add comment to existing block w/ no comment
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block id="7">
    <comment>send out reminders</comment>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[7]->findvalue('comment'), 'send out reminders', 'new comment set' );

## manually adjust the crontab file and add a private comment between
## our comments about stats and Texas
unless ($SIG) {
    system('perl', '-0777', '-pi', '-e', 's{(run my stats every day)}{$1\n#this is a private comment}', $CRONTAB);
}

##
## replace multi-line comment in existing block w/ comment
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block id="8">
    <comment>just run my stats every day in Texas</comment>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[8]->findvalue('comment[1]'), 'just run my stats every day in Texas', 'new comment replacement' );
if ($SIG) {
    is( $nodes[8]->findvalue('comment[2]'), '', 'private comment retained' );
} else {
    is( $nodes[8]->findvalue('comment[2]'), 'this is a private comment', 'private comment retained' );
}
is( $nodes[8]->findvalue('comment[3]'), '', 'old comment replaced' );

##
## replace comment in existing block w/ multi-line comment
##
undef $de;
$de = $t->xml_response(qq!<vsap type="sys:crontab:add">
  <block id="8">
    <comment>just run my stats every day in Texas</comment>
    <comment>and I'll have that with a glass of OJ</comment>
  </block>
</vsap>!);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[8]->findvalue('comment[1]'), 'just run my stats every day in Texas', 'new comment replacement' );
is( $nodes[8]->findvalue('comment[2]'), "and I'll have that with a glass of OJ", 'new comment replacement' );
if ($SIG) {
    is( $nodes[8]->findvalue('comment[3]'), '', 'private comment retained' );
} else {
    is( $nodes[8]->findvalue('comment[3]'), 'this is a private comment', 'private comment retained' );
}

##
## multi-line comment embedded in a single <comment/> element
##
undef $de;
$de = $t->xml_response(qq~<vsap type="sys:crontab:add">
  <block id="8">
    <comment>What? Not again!&#010;darn these socks!&#013;&#010;they're full of holes&#010;&#013;and stink all the time.</comment>
    <comment>and if that's not enough,&#010;my lunch money was stolen&#013;by our good friend Moe.</comment>
  </block>
</vsap>~);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
is( $nodes[8]->findvalue('comment[1]'), 'What? Not again!', 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[2]'), 'darn these socks!', 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[3]'), "they're full of holes", 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[4]'), "and stink all the time.", 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[5]'), "and if that's not enough,", 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[6]'), "my lunch money was stolen", 'multi-line comment replacement' );
is( $nodes[8]->findvalue('comment[7]'), "by our good friend Moe.", 'multi-line comment replacement' );
if ($SIG) {
    is( $nodes[8]->findvalue('comment[8]'), '', 'private comment retained' );
} else {
    is( $nodes[8]->findvalue('comment[8]'), 'this is a private comment', 'private comment retained' );
}

##
## i18n comment (utf-8 req'd)
##
undef $de;
$de = $t->xml_response(qq~<vsap type="sys:crontab:add">
  <block id="8">
    <comment>This comment contains UTF-8 encoded Unicode chars:</comment>
    <comment>Γνωθι Σεαυτον</comment>
  </block>
</vsap>~);

@nodes = get_nodes($t->xml_response(qq!<vsap type="sys:crontab:list"/>!));
like( $nodes[8]->findvalue('comment[1]'), qr(This comment contains UTF-8), 'i18n comment' );
is( $nodes[8]->findvalue('comment[2]'), "\x{0393}\x{03bd}\x{03c9}\x{03b8}\x{03b9} \x{03a3}\x{03b5}\x{03b1}\x{03c5}\x{03c4}\x{03bf}\x{03bd}", 'i18n comment' );

exit;

######################################################################
sub get_nodes {
    my $de = shift;
    my @nodes = $de->findnodes('/vsap/vsap[@type="sys:crontab:list"]/*');
    unshift @nodes, undef;
    return @nodes;
}
