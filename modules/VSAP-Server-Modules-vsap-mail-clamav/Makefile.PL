use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::mail::clamav',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/mail/clamav.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/mail/clamav.pm', # retrieve abstract from module
       AUTHOR         => 'Rus Berrett <rus@surfutah.com>') : ()),
);
