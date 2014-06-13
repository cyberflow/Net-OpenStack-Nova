use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::OpenStack::Nova',
    LICENSE 		  => 'GPL2',
    VERSION_FROM      => 'lib/Net/OpenStack/Nova.pm', 
    PREREQ_PM         => {
    	"Moose" => 0,
        "HTTP::Request" => 0,
        "JSON" => 0,
        "LWP" => 0,
        "Net::OpenStack::Neutron" => 0,
        # "Test::Class" => 0,
        # "Test::Most" => 0,
        # "Test::MockModule" => 0,
        # "Test::MockObject" => 0,
        # "Test::MockObject::Extends" => 0,
        # "Devel::StackTrace" => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/OpenStack/Nova.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry <cyberflow@>') : ()),
);
