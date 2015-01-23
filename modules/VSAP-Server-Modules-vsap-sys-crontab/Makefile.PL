use 5.008004;
use ExtUtils::MakeMaker;

## this hack also found in vsapd; it pushes vendor_perl higher than
## site_perl in Perl's @INC array so we find the right modules and
## versions of those modules. -scottw
BEGIN {
    my @vendor = grep {   m!/vendor_perl! } @INC;
    @INC       = grep { ! m!/vendor_perl! } @INC;
    my $i = 0; for ( @INC ) { last if m!/site_perl!; $i++ }
    splice @INC, $i, 0, @vendor;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::sys::crontab',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/sys/crontab.pm', # finds $VERSION
    PREREQ_PM         => { Config::Crontab => 1.05 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/sys/crontab.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);
