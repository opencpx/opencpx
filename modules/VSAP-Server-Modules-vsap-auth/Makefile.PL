use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VSAP::Server::Modules::vsap::auth',
    VERSION_FROM      => 'lib/VSAP/Server/Modules/vsap/auth.pm', # finds $VERSION
    PREREQ_PM         => { Authen::PAM => 0.14,
                           Crypt::Rijndael => 0.04,  ## req'd before Crypt::CBC
			   Crypt::CBC  => 2.08, },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VSAP/Server/Modules/vsap/auth.pm', # retrieve abstract from module
       AUTHOR         => 'System Administrator <root@dmz.orem.verio.net>') : ()),
);
