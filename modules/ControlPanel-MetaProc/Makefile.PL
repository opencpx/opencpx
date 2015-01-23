use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ControlPanel::MetaProc',
    VERSION_FROM      => 'lib/ControlPanel/MetaProc.pm', # finds $VERSION
    PREREQ_PM         => { VSAP::Client => 0.03,
			   XML::LibXML  => 1.57,
			   XML::LibXSLT => 1.57, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ControlPanel/MetaProc.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
