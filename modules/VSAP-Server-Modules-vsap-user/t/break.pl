use Test::More tests => 3;
BEGIN { use_ok('VSAP::Server::Modules::vsap::user') }

## NOTE: this use to break cpx.conf, by tickling a race condition in
## NOTE: the libxml toFile() method. The condition has been
## NOTE: eliminated. This file should be made into a legitimate test
## NOTE: file sometime.

use VSAP::Server::Test;
use VSAP::Server::Modules::vsap::config;

if( getpwnam('joefoosa') || getpwnam('joefooda') ) {
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}

my $opid = "_orig.$$";

SETUP: {
    system('cp', '-p', "/usr/local/etc/cpx.conf", "/usr/local/etc/cpx.conf.$opid")
      if -e "/usr/local/etc/cpx.conf";
    system('logger', '-p', 'daemon.notice', "Couldn't write cpx.conf.$opid: $@")
      if $@;
    system('cp', '-p', '/www/conf/httpd.conf', "/www/conf/httpd.conf.$opid");
}

my $vsapd_config = "_config.$$.vsapd";

## write a simple config file
open VSAPD, ">$vsapd_config"
    or die "Couldn't open '$vsapd_config': $!\n";
print VSAPD <<_CONFIG_;
LoadModule    vsap::auth
LoadModule    vsap::user
LoadModule    vsap::domain
LoadModule    vsap::user::mail
LoadModule    vsap::mail::addresses
_CONFIG_
close VSAPD;

my $vsap = new VSAP::Server::Test( { vsapd_config => $vsapd_config } );

## set up a user
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    system( 'vadduser --quiet --login=joefoosa --password=joefoobar --home=/home/joefoosa --fullname="Joe Foo SA" --services=mail --quota=10' )
        and die "Could not create user 'joefoosa'\n";

    system('pw', 'groupmod', '-n', 'wheel', '-m', 'joefoosa');  ## make us an administrator

    system( 'vadduser --quiet --login=joefooda --password=joefoobar --home=/home/joefooda --fullname="Joe Foo DA" --services=mail --quota=5' )
	and die "Could not create user 'joefooda'\n";

    ## add entry in httpd.conf so we become domain admin
    system('vaddhost', '--quiet', '--hostname=somesampledomain.tld', '--user=joefooda', '--defaults');
}
ok( getpwnam('joefoosa') && getpwnam('joefooda') );


###############################################################################
###############################################################################
##
##
## here we create a domain admin w/ privs, and an end user for that admin
##
##
###############################################################################
###############################################################################

## create vsap client
my $t = $vsap->client({ username => 'joefoosa', password => 'joefoobar'});
ok(ref($t));

$de = $t->xml_response(qq!
<vsap type="domain:add">
  <domain>somesampledomain.tld</domain>
  <edit>1</edit>
  <end_users>5</end_users>
</vsap>
!);
#print STDERR $de->toString(1);

#$VSAP::Server::Modules::vsap::config::TRACE     = 1;
#$VSAP::Server::Modules::vsap::config::TRACE_SUB = 1;
#$VSAP::Server::Modules::vsap::config::TRACE_PAT = qr(^(?:users|domains|services|capabilities|refresh|_parse.*|new|init)$);

my $co = new VSAP::Server::Modules::vsap::config( username => 'joefooda' );
$co->services( mail => 1, webmail => 1 );
$co->capabilities( mail => 1, webmail => 1 );
$co->eu_capabilities( mail => 1, webmail => 1 );
undef $co;

## do some things, create a user, etc.
$de = $t->xml_response(qq!
<vsap type="user:add">
  <login_id>joefooeu</login_id>
  <fullname>Domain End User</fullname>
  <password>asdlkfja kfj </password>
  <confirm_password>asdlkfja kfj </confirm_password>
  <quota>2</quota>
  <eu>
    <domain>somesampledomain.tld</domain>
    <mail_privs/>
    <webmail_privs/>
  </eu>
</vsap>!);

## let eu do fun things
$co = new VSAP::Server::Modules::vsap::config( username => 'joefooeu' );
$co->services( mail => 1, webmail => 1 );
$co->capabilities( mail => 1, webmail => 1 );
undef $co;

unless( -d '/home/joefooeu' ) {
    print STDERR $de->toString(1);
}

undef $t;

#system('less', '/usr/local/etc/cpx.conf');


###############################################################################
###############################################################################
##
##
## here we fork and do various operations, trying to whack cpx.conf somehow
##
##
###############################################################################
###############################################################################

my $Pid = $$;     ## with a capital 'P' that rhymes with 'T'
my $pid = fork();
die "Cannot fork: $!\n" unless defined $pid;
my $forked = 1;
my $de = '';

##
## here is the child process
##
unless( $pid ) {
    undef $Pid;  ## mark us as child
    my $t2 = $vsap->client({ username => 'joefooda', password => 'joefoobar' });

    ## loop and add/remove a user

    for ( 1..3 ) {
        undef $de;
        print STDERR "                                        CHILD: Adding new user\n";
        system('logger', '-p', 'daemon.notice', "CHILD [$$]: adding new user");
        $de = $t2->xml_response(qq!
<vsap type="user:add">
  <fullname>Joe Eu Two</fullname>
  <login_id>joefooeu2</login_id>
  <password>foofoo123</password>
  <confirm_password>foofoo123</confirm_password>
  <quota>2</quota>
  <eu>
    <domain>somesampledomain.tld</domain>
    <mail_privs/>
  </eu>
</vsap>
!);

        unless( -d '/home/joefooeu2' ) {
            warn "Could not create user\n";
        }

        print STDERR "                                        CHILD: Removing new user\n";
        system('logger', '-p', 'daemon.notice', "CHILD [$$]: removing user");
        $de = $t2->xml_response(qq!<vsap type="user:remove"><user>joefooeu2</user></vsap>!);

        if( -d '/home/joefooeu2' ) {
            warn "Could not delete user\n";
        }

    }

    ## clean exit: don't do any object destruction, etc.
    syscall( 1, 0 );  # syscall( &SYS_exit, 0 );  ## don't kill our vsap test object
}

##
## here is the parent process
##
my $t1 = $vsap->client({ username => 'joefoosa', password => 'joefoobar'});

sleep 1;

## raise and drop email quota limits for somesampledomain.tld

my $killeth = 0;

for my $loop ( 1..5 ) {
    my $elim = ( $loop%2 ? 1 : 0 );

    print STDERR "PARENT: setting email limits to $elim\n";
    system('logger', '-p', 'daemon.notice', "PARENT [$$]: setting email limits to $elim");
    $de = $t1->xml_response(qq!
<vsap type="domain:add">
  <edit>1</edit>
  <admin>joefooda</admin>
  <domain>somesampledomain.tld</domain>
  <www_alias>0</www_alias>
  <other_aliases></other_aliases>
  <cgi>0</cgi>
  <ssl>0</ssl>
  <end_users>1</end_users>
  <email_addrs>$elim</email_addrs>
  <website_logs>yes</website_logs>
  <log_rotate>daily</log_rotate>
  <log_save>30</log_save>
  <domain_contact>webmaster\@somesampledomain.tld</domain_contact>
  <mail_catchall>reject</mail_catchall>
</vsap>!);

    ## check cpx.conf
    my $conf = `egrep -C13 '<user name="joefooeu">' /usr/local/etc/cpx.conf | tail -n 15 | head -n 13`;
#    my $conf = `egrep 'webmail' /usr/local/etc/cpx.conf`;
    if( $conf =~ /webmail/ ) {
        warn "CPX.CONF: Webmail ok\n";
    }
    else {
        system('logger', '-p', 'daemon.notice', "cpx.conf crashed");
        warn "\n\nCPX.CONF: Webmail missing from joefooeu!    *****************  \n\n";
        warn "Entry: $conf\n";
        warn "Killing child\n";
        kill 15 => $pid;
        $killeth = 1;
        last;
    }
}

waitpid($pid, 0);
exit $killeth;

###############################################################################
###############################################################################

END {
    if( $forked ) {
	unless( $Pid ) {
	    print STDERR "Child in END block. Skipping\n";
	    return;
	}
    }

    system('logger', '-p', 'daemon.notice', "Cleaning up...");

    getpwnam('joefoosa')  && system q(vrmuser -y joefoosa  2>/dev/null);
    getpwnam('joefooda')  && system q(vrmuser -y joefooda  2>/dev/null);
    getpwnam('joefooeu')  && system q(vrmuser -y joefooeu  2>/dev/null);
    getpwnam('joefooeu2') && system q(vrmuser -y joefooeu2 2>/dev/null);
    unlink $vsapd_config;

    system('logger', '-p', 'daemon.notice', "  restoring cpx.conf...");
    unlink "/usr/local/etc/cpx.conf";
    rename("/usr/local/etc/cpx.conf.$opid", "/usr/local/etc/cpx.conf")
      if -e "/usr/local/etc/cpx.conf.$opid";

    system('logger', '-p', 'daemon.notice', "  restoring httpd.conf...");
    rename("/www/conf/httpd.conf.$opid", '/www/conf/httpd.conf')
      if -e "/www/conf/httpd.conf.$opid";

    system('logger', '-p', 'daemon.notice', "cleanup finished.");
}

=pod

    <user name="joefooeu">
      <domain>somesampledomain.tld</domain>
      <capabilities>
        <mail/>
        <webmail/>
      </capabilities>
      <services>
        <mail/>
        <webmail/>
      </services>
      <fullname>Domain End User</fullname>
    </user>

=cut

