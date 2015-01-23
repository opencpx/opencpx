use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::webmail::messages',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/webmail/messages.pm', # finds $VERSION
    PREREQ_PM         => { HTML::Scrubber::StripScripts => 0.02 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/webmail/messages.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
