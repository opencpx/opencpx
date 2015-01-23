use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::webmail::addressbook',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/webmail/addressbook.pm', # finds $VERSION
    PREREQ_PM         => { 'Data::UUID' => 0,
			   'XML::LibXML' => 0 ,
			   'VSAP::Server::Modules::vsap::webmail::distlist' => 0.02,
			   'VSAP::Server::Modules::vsap::webmail::options' => 0.02 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/webmail/addressbook.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
