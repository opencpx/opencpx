use Test;
BEGIN { $|=1; plan(tests => 8); chdir 't' if -d 't'; }

use blib;

use VSAP::Server::Base qw();
ok(1);

##################################################
## xmlescape tests
##################################################
my $str  = 'joe & bob';
my $nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, 'joe &amp; bob' );

## test to make sure the original string is untouched
ok( $str ne $nstr );

$str  = '10 < 100<';
$nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, '10 &lt; 100&lt;' );

$str  = '100 > 10>';
$nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, '100 &gt; 10&gt;' );

$str  = "new\rline\r";
$nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, 'new&#013;line&#013;' );

$str  = "new\nline\n";
$nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, 'new&#010;line&#010;' );

$str  = "null\x00bytes\x00";
$nstr = VSAP::Server::Base::xml_escape($str);
ok( $nstr, 'nullbytes');


exit;
