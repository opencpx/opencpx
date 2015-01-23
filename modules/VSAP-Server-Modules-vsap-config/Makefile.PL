use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::config',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/config.pm', # finds $VERSION
    PREREQ_PM         => { VSAP::Server::Modules::vsap::mail::clamav => 0.02, 
			   VSAP::Server::Modules::vsap::mail::spamassassin => 0.02 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/config.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
