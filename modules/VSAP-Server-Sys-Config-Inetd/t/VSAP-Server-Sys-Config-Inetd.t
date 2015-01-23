use Test::More tests => 49;
use warnings;

BEGIN { 
	use_ok('VSAP::Server::Sys::Config::Inetd');
	use_ok('IO::Socket::INET');
};

$inetd = new VSAP::Server::Sys::Config::Inetd;

ok(grep(/ftp/,$inetd->services), "returned some services");
ok($inetd->disable('ftp'),"disabled ftp");
is($inetd->is_disabled('ftp'),1,"ftp shows as disabled");
is($inetd->is_enabled('ftp'),0,"ftp shows as not enabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'ftp', Proto => 'tcp');
ok(!$sock, "unable to connect to ftp");
ok($inetd->enable('ftp'),"enabled ftp");
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'ftp', Proto => 'tcp');
ok($sock, "able to connect to ftp");
undef $sock; 

ok($inetd->disable('pop3'),"disabled pop3");
is($inetd->is_disabled('pop3'),1,"pop3 shows as disabled");
is($inetd->is_enabled('pop3'),0,"pop3 shows as not enabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'pop3', Proto => 'tcp');
ok(!$sock, "unable to connect to pop3");
ok($inetd->enable('pop3'),"disabled pop3");
is($inetd->is_enabled('pop3'),1,"pop3 shows as enabled");
is($inetd->is_disabled('pop3'),0,"pop3 shows as not disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'pop3', Proto => 'tcp');
ok($sock, "able to connect to pop3");

ok($inetd->disable('pop3s'),"disabled pop3s");
is($inetd->is_disabled('pop3s'),1,"pop3s shows as disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'pop3s', Proto => 'tcp');
ok(!$sock, "unable to connect to pop3s");
is($inetd->is_enabled('pop3s'),0,"pop3s shows as not enabled");
ok($inetd->enable('pop3s'),"disabled pop3s");
is($inetd->is_enabled('pop3s'),1,"pop3s shows as enabled");
is($inetd->is_disabled('pop3s'),0,"pop3s shows as not disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'pop3s', Proto => 'tcp');
ok($sock, "able to connect to pop3s");

ok($inetd->disable('imap'),"disabled imap");
is($inetd->is_disabled('imap'),1,"imap shows as disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'imap', Proto => 'tcp');
ok(!$sock, "unable to connect to imap");
is($inetd->is_enabled('imap'),0,"imap shows as not enabled");
ok($inetd->enable('imap'),"disabled imap");
is($inetd->is_enabled('imap'),1,"imap shows as enabled");
is($inetd->is_disabled('imap'),0,"imap shows as not disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'imap', Proto => 'tcp');
ok($sock, "able to connect to imap");

ok($inetd->disable('imaps'),"disabled imaps");
is($inetd->is_disabled('imaps'),1,"imaps shows as disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'imaps', Proto => 'tcp');
ok(!$sock, "unable to connect to imaps");
is($inetd->is_enabled('imaps'),0,"imaps shows as not enabled");
ok($inetd->enable('imaps'),"disabled imaps");
is($inetd->is_enabled('imaps'),1,"imaps shows as enabled");
is($inetd->is_disabled('imaps'),0,"imaps shows as not disabled");
sleep 3; # Wait for restart to settle..
$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'imaps', Proto => 'tcp');
ok($sock, "able to connect to imaps");

SKIP: { 
	skip 'telnet not in inetd on on linux', 8 unless
		(ref($inetd) eq 'VSAP::Server::Sys::Config::Inetd::Impl::FreeBSD::Inetd');

	ok($inetd->disable('telnet'),"disabled telnet");
	is($inetd->is_disabled('telnet'),1,"telnet shows as disabled");
	sleep 3; # Wait for restart to settle..
	$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'telnet', Proto => 'tcp');
	ok(!$sock, "unable to connect to telnet");
	is($inetd->is_enabled('telnet'),0,"telnet shows as not enabled");
	ok($inetd->enable('telnet'),"disabled telnet");
	is($inetd->is_enabled('telnet'),1,"telnet shows as enabled");
	is($inetd->is_disabled('telnet'),0,"telnet shows as not disabled");
	sleep 3; # Wait for restart to settle..
	$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => 'telnet', Proto => 'tcp');
	ok($sock, "able to connect to telnet");
}
