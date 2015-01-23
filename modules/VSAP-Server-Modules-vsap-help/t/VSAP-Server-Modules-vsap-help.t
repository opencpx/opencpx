use Test::More tests => 12;

# TEST 1
BEGIN { use_ok('VSAP::Server::Modules::vsap::help') };

################################

use VSAP::Server::Test;
use VSAP::Server::Modules::vsap::config;
use Data::Dumper;


my $vsapd_config = "_config.$$.vsapd";

## make sure our user doesn't exist
if( getpwnam('joefoo') ) 
{
    die "User 'joefoo' already exists. Remove the user (rmuser -y joefoo) and try again.\n";
}


## set up users
{
    local $ENV{PERL5LIB} = '';  ## Test::Harness::runtests sets PERL5LIB
                                ## to the executing Perl's @INC array,
                                ## which screws up the env for vadduser
    system( 'vadduser --quiet --login=joefoo --password=joefoobar --home=/home/joefoo --fullname="Joe Foo" --services=ftp,mail --quota=50' )
        and die "Could not create user 'joefoo'\n";

    system('pw', 'groupmod', '-n', 'wheel', '-m', 'joefoo');  ## make us an administrator

}

# TEST 2
ok( getpwnam('joefoo') );



## write a simple config file
open VSAPD, ">$vsapd_config" or die "Couldn't open '$vsapd_config': $!\n";

print VSAPD <<_CONFIG_;
LoadModule    vsap::auth
LoadModule    vsap::help
_CONFIG_
close VSAPD;

my $vsap    = new VSAP::Server::Test( { vsapd_config => $vsapd_config } );
my $t       = $vsap->client({ username => 'joefoo', password => 'joefoobar' }) ;



## MODULE TESTS
#----------------------------------------------------------------------------
# TEST 3
# the series of test topics that this test script uses all
# have the keyword herring in them.
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>herring</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    my @nodes = $de->findnodes('/vsap/vsap[@type="help:search"]/topic');

    ok(  scalar(@nodes) == 4, qq{Search for specific topics in a specified category.} );

    #print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 4
# Singular topic search. make sure were not always getting all topics back
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>test1</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    my @nodes = $de->findnodes('/vsap/vsap[@type="help:search"]/topic');

    ok(  scalar(@nodes) == 1, qq{Search for a singular topic in a specified category.} );

    # print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 5
# Invalid or not supplied Language param.
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>test1</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 112]') , qq{Test Missing Language param.} );

    #print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 6
# Invalid or not supplied category param.
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>test1</query>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 103]') , qq{Test Missing category param.} );

    #print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 7
# Debug checking Invalid category directory
{
    $de = $t->xml_response(qq!<vsap type="help:debug">
        <debug>1</debug>
        <topic>topic666</topic>
        <category>test-ugh</category>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 103]') , qq{invalid category directory, does not exist.} );

    #print qq{DEBUG:}, $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 8
# Query too short 
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>t</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 100]') , qq{Query string too short.} );

    # print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 9
# No topics found in search.
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>Goblin</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 102]') , qq{No topics found in search.} );

    #print $de->toString;
}
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# TEST 10
# Case Sensitive Search
{
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>CASE</query>
        <category>test</category>
        <case_sensitive>1</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    my @upper_case_nodes = $de->findnodes('/vsap/vsap[@type="help:search"]/topic');
    #print qq{UPPER:}, $de->toString;

    undef $de;
    $de = $t->xml_response(qq!<vsap type="help:search">
        <query>CASE</query>
        <category>test</category>
        <case_sensitive>0</case_sensitive>
        <language>en_US</language>
    </vsap>!);

    my @mixed_case_nodes = $de->findnodes('/vsap/vsap[@type="help:search"]/topic');
    #print qq{MIXED:}, $de->toString;

    ok(  scalar(@mixed_case_nodes) > scalar(@upper_case_nodes), qq{Test Case sensitive Search option.} );
}
#----------------------------------------------------------------------------


#----------------------------------------------------------------------------
# TEST 11
# Debug checking Invalid topic file. Does not exist.
{
    $de = $t->xml_response(qq!<vsap type="help:debug">
        <debug>1</debug>
        <topic>topic666</topic>
        <category>test</category>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 110]') , qq{Invalid topic file, does not exist.} );

    #print qq{DEBUG:}, $de->toString;
}
#----------------------------------------------------------------------------



#----------------------------------------------------------------------------
# TEST 12
# Debug checking Invalid topic file. Invalid XML
{
    $de = $t->xml_response(qq!<vsap type="help:debug">
        <debug>1</debug>
        <topic>topic-bad</topic>
        <category>test</category>
        <language>en_US</language>
    </vsap>!);

    ok( $de->find('/vsap/vsap[@type="error"]/code[. = 111]') , qq{Invalid topic file, invalid XML.} );

    #print qq{DEBUG:}, $de->toString;
}
#----------------------------------------------------------------------------



# CLEANUP
END {
    getpwnam('joefoo')    && system q(vrmuser -y joefoo 2>/dev/null);

    unlink $vsapd_config;
}




