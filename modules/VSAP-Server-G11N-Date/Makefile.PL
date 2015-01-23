require 5.008001;
use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

## lots of good ideas from Digest::MD5 Makefile.PL
## see also 'configure' on dev2.h2ay.net

my @extra  = ();
my @define = ();
@extra = (DEFINE => "@define") if @define = defines();

WriteMakefile(
    'NAME'		=> 'VSAP::Server::G11N::Date',
    'VERSION_FROM'	=> 'lib/VSAP/Server/G11N/Date.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Time::Zone' => 2.20 }, # e.g., Module::Name => 1.1
    @extra,
    'dist'              => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ($] >= 5.005 
	? (ABSTRACT_FROM  => 'lib/VSAP/Server/G11N/Date.pm',
	   AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>')
	: () ),
);

sub defines {
    my %tests = ();
    my @results = ();

    $|=1;

    ## *******************************************
    ## find where tm struct lives
    open TEST, ">t.c" or die "$!";
    print TEST <<_CODE_; close TEST;
#include <sys/types.h>
#include <time.h>
int main() { struct tm *tp; tp->tm_sec; ; return 0; }
_CODE_

    my $time_h = ( compile_run() ? 'time.h' : 'sys/time.h' );
    push @results, ( $time_h eq 'sys/time.h' ? '-DD_USE_SYS_TIME' : '' );

    my $test_no = 1;

    ## *******************************************
    $tests{'tm_zone'} = { order   => $test_no++,
			  code    => <<_CODE_,
#include <sys/types.h>
#include <$time_h>
int main() { struct tm tm; tm.tm_zone; return 0; }
_CODE_
			  result => '-DD_HAS_TM_ZONE'};

    ## *******************************************
    $tests{'tm_gmtoff'} = { order   => $test_no++,
			    code    => <<_CODE_,
#include <sys/types.h>
#include <$time_h>
int main() { struct tm tm; tm.tm_gmtoff; return 0; }
_CODE_
			  result => '-DD_HAS_TM_GMTOFF'};

    ## *******************************************
    $tests{'tzname'} = { order  => $test_no++,
			 code   => <<'_CODE_',
int main() { extern short tzname[]; printf("%hd", tzname[0]); return 0; }
_CODE_
			  result => '-DD_HAS_TZNAME'};

    ## *******************************************
    $tests{'timezone'} = { order  => $test_no++,
			  code   => <<_CODE_,
#include <sys/types.h>
#include <$time_h>
int main() { long i; tzset(); i = -timezone + daylight ? 3600 : 0; return 0; }
_CODE_
			  result => '-DD_HAS_TIMEZONE'};

    ## *******************************************
    $tests{'altzone'} = { order  => $test_no++,
			  code   => <<_CODE_,
#include <sys/types.h>
#include <$time_h>
int main() { long i = -altzone; return 0; }
_CODE_
			  result => '-DD_HAS_ALTZONE'};

    ## *******************************************
    ## run tests
    for my $t ( sort { $tests{$a}->{'order'} <=> $tests{$b}->{'order'} } keys %tests ) {
	my $code = $tests{$t}->{'code'};
	print "Testing for $t... ";
	open TEST, ">t.c" or die "$!";
	print TEST <<EOT; close TEST;
$code
EOT

        ## save results
        push @results, ( compile_run() ? $tests{$t}->{'result'} : '' );
	if( $results[$#results] ) {
	    print "ok\n";
	} 
	else {
	    print "nope\n";
	}
    }

    return @results;
}

sub compile_run {
    my $cc_cmd = "$Config{cc} $Config{ccflags} -I$Config{archlibexp}/CORE";
    my $exe    = "_t_phony$Config{_exe}";

    if ($^O eq 'MSWin32') {
        $cc_cmd .= ' -DWIN32IO_IS_STDIO';
    } else {
        $cc_cmd .= " -o $exe";
    }

    my $rc = system("$cc_cmd $Config{ldflags} t.c $Config{libs} > /dev/null 2>&1");
    if ($rc) {
        unlink("t.c", $exe, "t$Config{_o}");
        return;
    }

    $rc = system("./$exe 2>&1 > /dev/null");
    unlink("t.c", $exe, "t$Config{_o}");

    return ( $rc ? 0 : 1 );
}
