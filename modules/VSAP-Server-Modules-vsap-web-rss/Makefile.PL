use 5.008004;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::web::rss',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/web/rss.pm', # finds $VERSION
    PREREQ_PM         => { 'Data::UUID' => 0,
			   'File::Path' => 0,
			   'MIME::Types' => 0,
			   'URI::URL' => 0,
			   'XML::LibXML' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/web/rss.pm', # retrieve abstract from module
       AUTHOR         => 'Charlie & <root@freebsd.org>') : ()),
);
