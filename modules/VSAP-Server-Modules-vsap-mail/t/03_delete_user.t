use Test::More tests => 23;
BEGIN { use_ok('VSAP::Server::Modules::vsap::mail') };

#########################
use POSIX('uname');
my $is_linux = ((POSIX::uname())[0] =~ /Linux/) ? 1 : 0;

my $pwd = `pwd`; chomp $pwd;

## move old things out of the way
my $aliasesDir;
if ($is_linux)
{
    $aliasesDir = "/etc";
} else {
    $aliasesDir = "/etc/mail";
}

unless( -e "${aliasesDir}/aliases" ) {
  system "touch ${aliasesDir}/aliases";
}
system "/bin/cp -p ${aliasesDir}/aliases ${aliasesDir}/aliases.$$";

if( -e '/etc/mail/virtusertable' ) {
    rename '/etc/mail/virtusertable', "/etc/mail/virtusertable-backup.$$"
      or die "Could not rename virtusertable: $!\n";
}

select undef, undef, undef, 1.3;  ## needed for 'make' to detect a change in virtusertable

##
## delete simple wilbur from virtusertable
##

my $str_virtusertable;
my $str_aliases;

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
pfw1@mailblock.net                      alias_blarney
geo9@mailblock.net                      wilbur
fooster@mailblock.net                   alias_fooster
scott@mailblock.net                     scott
@mailblock.net                          nouser
_VUT_

clobber_files($str_virtusertable, undef);

my $wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'geo9\@mailblock\.net' /etc/mail/virtusertable`;
unlike( $ca, qr(geo9\@mailblock\.net\s+wilbur), 'user deleted from virtusertable' );
my $wcv2 = `wc -l /etc/mail/virtusertable`; chomp $wcv2; $wcv2 =~ s/^\s*(\S+).*/$1/;
is(($wcv-1), $wcv2, 'virtusertable line count');

##
## delete 2 wilburs
##

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
pfw1@mailblock.net                      alias_blarney
geo9@mailblock.net                      wilbur
fooster@mailblock.net                   alias_fooster
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
@mailblock.net                          nouser
_VUT_

clobber_files($str_virtusertable, undef);

$wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'geo9\@mailblock\.net' /etc/mail/virtusertable`;
unlike( $ca, qr(geo9\@mailblock\.net\s+wilbur), 'virtusertable entry gone' );
$ca = `egrep -C2 'vilbuhr8\@mailblock\.net' /etc/mail/virtusertable`;
unlike( $ca, qr(vilbuhr8\@mailblock\.net\s+wilbur), 'virtusertable entry gone' );
$ca = `egrep -C2 'wilbur' /etc/mail/virtusertable`;
unlike( $ca, qr(wilbur), 'user gone from virtusertable' );
$wcv2 = `wc -l /etc/mail/virtusertable`;
chomp $wcv2;
$wcv2 =~ s/^\s*(\S+).*/$1/;
is(($wcv-2), $wcv2, 'virtusertable line count');


##
## delete alias and virtusertable entries
##
$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
geo9@mailblock.net                      wilbur
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
@mailblock.net                          nouser
_VUT_

$str_aliases = <<'_ALIASES_';
MAILER-DAEMON: postmaster
postmaster: root
alias_blarney: wilbur
alias_fooster: fooster, foosterson, wilbur
alias_blarney2: pfw1@mailblock.net
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

clobber_files($str_virtusertable, $str_aliases);
$wcv    = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
my $wca = `wc -l ${aliasesDir}/aliases`;       chomp $wca; $wca =~ s/^\s*(\S+).*/$1/;

VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'geo9\@mailblock\.net' /etc/mail/virtusertable`;
unlike( $ca, qr(geo9\@mailblock\.net\s+wilbur), 'user gone from virtusertable' );
$ca = `egrep -C2 'vilbuhr8\@mailblock\.net' /etc/mail/virtusertable`;
unlike( $ca, qr(vilbuhr8\@mailblock\.net\s+wilbur), 'user gone from virtusertable' );
$ca = `egrep -C2 'wilbur' /etc/mail/virtusertable`;
unlike( $ca, qr(wilbur), 'user gone from virtusertable' );
$wcv2 = `wc -l /etc/mail/virtusertable`; chomp $wcv2; $wcv2 =~ s/^\s*(\S+).*/$1/;
is(($wcv-2), $wcv2, 'virtusertable line count');

$ca = `egrep -C2 'alias_blarney:' ${aliasesDir}/aliases`;
unlike( $ca, qr(alias_blarney:), 'alias gone from aliases' );
$ca = `egrep -C2 'alias_fooster:' ${aliasesDir}/aliases`;
like( $ca, qr(^alias_fooster:\s*fooster, foosterson\n)m, "aliases removed" );

##
## delete more complex entries
##

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
horsemistress@mailblock.net		alias_blarney
geo9@mailblock.net                      wilbur
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
@mailblock.net                          nouser
_VUT_

$str_aliases = <<'_ALIASES_';
MAILER-DAEMON: postmaster
postmaster: root
alias_blarney: wilbur
alias_fooster: fooster, foosterson, wilbur
alias_blarney2: pfw1@mailblock.net
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

clobber_files($str_virtusertable, $str_aliases);
$wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
$wca = `wc -l ${aliasesDir}/aliases`;       chomp $wca; $wca =~ s/^\s*(\S+).*/$1/;

VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'alias_blarney' /etc/mail/virtusertable`;
unlike( $ca, qr(alias_blarney\b), "aliases to user in virtusertable removed" );

##
## delete very long chains
##

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
horsemistress@mailblock.net		alias_blarney
geo9@mailblock.net                      wilbur
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
@mailblock.net                          nouser
_VUT_

$str_aliases = <<'_ALIASES_';
MAILER-DAEMON: postmaster
postmaster: root
alias_blarney: wilbur
alias_fooster: fooster, foosterson, wilbur
alias_blarney2: pfw1@mailblock.net
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

clobber_files($str_virtusertable, $str_aliases);
$wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
$wca = `wc -l ${aliasesDir}/aliases`;       chomp $wca; $wca =~ s/^\s*(\S+).*/$1/;

VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'alias_blarney' /etc/mail/virtusertable`;
unlike( $ca, qr(alias_blarney\b), "aliases to user in virtusertable removed" );
like( $ca, qr(alias_blarney2), "ok aliases to user in virtusertable kept" );
$ca = `egrep -C2 'wilbur' ${aliasesDir}/aliases`;
unlike( $ca, qr(wilbur), "user deleted from aliases file" );

##
## complex chain, circling back into virtusertable
##

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
horsemistress@mailblock.net		alias_blarney
geo9@mailblock.net                      wilbur
wilburfoo@mailblock.net			alias_wilburfoo
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
@mailblock.net                          nouser
_VUT_

$str_aliases = <<'_ALIASES_';
MAILER-DAEMON: postmaster
postmaster: root
alias_blarney: wilburfoo@mailblock.net
alias_fooster: fooster, foosterson, wilbur
alias_blarney2: pfw1@mailblock.net
alias_wilburfoo: wilbur
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

clobber_files($str_virtusertable, $str_aliases);
$wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
$wca = `wc -l ${aliasesDir}/aliases`;       chomp $wca; $wca =~ s/^\s*(\S+).*/$1/;

VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `egrep -C2 'alias_blarney' /etc/mail/virtusertable`;
unlike( $ca, qr(alias_blarney\b), "aliases to alias in virtusertable removed" );
$ca = `egrep -C2 'alias_wilburfoo' /etc/mail/virtusertable`;
unlike( $ca, qr(alias_wilburfoo), "aliases to alias in virtusertable removed" );

$ca = `egrep -C2 'alias_blarney' ${aliasesDir}/aliases`;
unlike( $ca, qr(alias_blarney\b), "alias deleted from aliases file" );
$ca = `egrep -C2 'alias_wilburfoo' ${aliasesDir}/aliases`;
unlike( $ca, qr(alias_wilburfoo), "alias deleted from aliases file" );

##
## delete very long, circurlar, complex chains
##

$str_virtusertable = <<'_VUT_';
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
horsemistress@mailblock.net		alias_blarney
geo9@mailblock.net                      wilbur
wilburfoo@mailblock.net			alias_wilburfoo
scott@mailblock.net                     scott
vilbuhr8@mailblock.net                  wilbur
fooster@mailblock.net			horsemistress@mailblock.net
@mailblock.net                          nouser
_VUT_

$str_aliases = <<'_ALIASES_';
MAILER-DAEMON: postmaster
postmaster: root
alias_blarney: wilburfoo@mailblock.net
alias_fooster: fooster@mailblock.net, foosterson, wilbur
alias_blarney2: pfw1@mailblock.net
alias_wilburfoo: wilbur
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

clobber_files($str_virtusertable, $str_aliases);
$wcv = `wc -l /etc/mail/virtusertable`; chomp $wcv; $wcv =~ s/^\s*(\S+).*/$1/;
$wca = `wc -l ${aliasesDir}/aliases`;       chomp $wca; $wca =~ s/^\s*(\S+).*/$1/;

#$VSAP::Server::Modules::vsap::mail::DEBUG = 1;
VSAP::Server::Modules::vsap::mail::delete_user('wilbur');
$ca = `cat /etc/mail/virtusertable`;
is( $ca, <<'_VUT_', "virtusertable ok");
##
## swedishbork.com
##
scott@swedishbork.com                   scott

##
## mailblock.net
##
mwalters21@mailblock.net                alias_blarney2
scott@mailblock.net                     scott
@mailblock.net                          nouser
_VUT_

$ca = `cat ${aliasesDir}/aliases`;
is( $ca, <<'_ALIASES_', "aliases ok");
MAILER-DAEMON: postmaster
postmaster: root
alias_fooster: foosterson
alias_blarney2: pfw1@mailblock.net
alias_blarney3: pfw1@mailblock.net, fooster
_ALIASES_

##
## FIXME: support for :include: files
##

exit;

END {
    unlink "${aliasesDir}/aliases" if -e "${aliasesDir}/aliases";
    if( -e ${aliasesDir}."/aliases.$$" ) {  
        rename "${aliasesDir}/aliases.$$", "${aliasesDir}/aliases";
    }

    unlink "/etc/mail/virtusertable" if -e "/etc/mail/virtusertable";
    if( -e "/etc/mail/virtusertable-backup.$$" ) {
	rename "/etc/mail/virtusertable-backup.$$", '/etc/mail/virtusertable';
        unlink "/etc/mail/virtusertable-backup.$$";
	chdir('/etc/mail');
	system('make maps >/dev/null 2>&1');
    }
}

sub clobber_files {
    my $virtusertable = shift;
    my $aliases = shift;

    ## overwrite virtusertable
    if( $str_virtusertable ) {
	open VUT, ">/etc/mail/virtusertable"
	  or die "Could not open virtusertable: $!\n";
	print VUT $virtusertable;
	close VUT;
    }

    if( $str_aliases ) {
	open ALIASES, ">${aliasesDir}/aliases"
	  or die "Could not open aliases: $!\n";
	print ALIASES $aliases;
	close ALIASES;
    }

    chdir('/etc/mail');
    system('make maps >/dev/null 2>&1');
    system('newaliases >/dev/null 2>&1');
    chdir($pwd);
}
