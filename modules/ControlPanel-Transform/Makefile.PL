use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ControlPanel::Transform',
    VERSION_FROM      => 'lib/ControlPanel/Transform.pm', # finds $VERSION
    PREREQ_PM         => { XML::LibXML  => 1.57,
			   XML::LibXSLT => 1.57, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ControlPanel/Transform.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
