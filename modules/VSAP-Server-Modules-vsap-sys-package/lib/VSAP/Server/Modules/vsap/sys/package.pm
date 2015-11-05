package VSAP::Server::Modules::vsap::sys::package;

use 5.008004;
use strict;
use warnings;

use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

our %_ERR = (
              NOT_AUTHORIZED         => 100,
              PACKAGE_REQUIRED       => 101,
              PLATFORM_ERROR         => 500,
            );

##############################################################################

sub _default_range
{
    my $npkg = @_;

    return($npkg) if ($npkg < 10);
    return(10) if ($npkg < 80);
    return(25) if ($npkg < 200);
    return(50) if ($npkg < 400);
    return(100);
}

# ----------------------------------------------------------------------------

sub _get
{
    my %options = @_;

    my %pkginfo;

    if ($VSAP::Server::Modules::vsap::globals::PLATFORM_DISTRO eq 'rhel') {
        # use rpm/yum
        %pkginfo = _get_rhel_pkg_info(%options);
    }
    elsif ($VSAP::Server::Modules::vsap::globals::PLATFORM_DISTRO eq 'debian') {
        # use dpkg/apt-get
        %pkginfo = _get_debian_pkg_info(%options);
    }
    else {
        # FreeBSD
        %pkginfo = _get_freebsd_pkg_info(%options);
    }

    return(%pkginfo);
}

# ----------------------------------------------------------------------------

sub _get_debian_pkg_info
{
    my %options = @_;

    # options{package}   = specific single package
    # options{installed} = is installed
    # options{pattern}   = regex search pattern

    ## FIXME: insert get pkg info code here
    my %pkginfo = ();
    return(%pkginfo);
}

# ----------------------------------------------------------------------------

sub _get_freebsd_pkg_info
{
    my %options = @_;

    # options{package}   = specific single package
    # options{installed} = is installed
    # options{pattern}   = regex search pattern

    ## FIXME: insert get pkg info code here
    my %pkginfo = ();
    return(%pkginfo);
}

# ----------------------------------------------------------------------------

sub _get_rhel_pkg_info
{
    my %options = @_;

    # options{package}   = specific single package
    # options{installed} = is installed
    # options{pattern}   = regex search pattern
    # options{group}     = rpm group

    my %pkginfo;

    # fields for an individual package info request
    my @infoqf = ( 'Version', 'Release', 'Summary', 'Size', 'Installtime',
                   'Buildtime', 'Vendor', 'License', 'Group', 'Url', 'Arch',
                   'Description');

    # the corresponding rpm query format string
    my $infoqfmt = '"<Package name=\"%{NAME}\">\n';
    foreach my $field (@infoqf) {
        my $capfield = $field;
        $capfield =~ tr/a-z/A-Z/;
        $infoqfmt .= " <$field>" . '%{' . $capfield . '}' . "</$field>" . '\n';
    }
    $infoqfmt .= '</Package>\n"';

    # fields for an package list request
    my @listqf = ( 'Version', 'Release', 'Summary', 'Size', 'Installtime', 'Group');

    # the corresponding rpm query format string
    my $listqfmt = '"<Package name=\"%{NAME}\">\n';
    foreach my $field (@listqf) {
        my $capfield = $field;
        $capfield =~ tr/a-z/A-Z/;
        $listqfmt .= " <$field>" . '%{' . $capfield . '}' . "</$field>" . '\n';
    }
    $listqfmt .= '</Package>\n"';

    # unit conversion help
    my %units = ( 'u' => 1,
                  'k' => 1024,
                  'M' => 1048576,
                  'G' => 1073741824 );

    local $> = $) = 0;  ## regain privileges for a moment

    if ($options{'package'}) {
        # package specified; is package already installed?
        my @command = ('/bin/rpm', '-q');
        push(@command, '--queryformat', $infoqfmt);
        push(@command, $options{'package'});
        my $info = `@command`;
        if ($info =~ /is not installed/) {
            # not installed... get info from yum repo
            @command = ('/usr/bin/yum', 'info', $options{'package'}, '2>&1');
            my @results = `@command`;
            my ($pkgname, $lastkey);
            $pkgname = $lastkey = "";
            foreach my $line (@results) {
               if ($line =~ /(.*?):(.*)/) {
                    my $key = $1;
                    my $value = $2;
                    $key =~ tr/A-Z/a-z/;
                    $key =~ s/^\s+//g;
                    $key =~ s/\s+$//g;
                    $value =~ s/^\s+//g;
                    $value =~ s/\s+$//g;
                    $key = $lastkey unless($key);
                    if ($key eq 'name') {
                        last if ($pkgname ne "");
                        $pkgname = $key;
                    }
                    next unless ($pkgname);
                    if ($key eq "size") {
                        my $size = $value;
                        my $unit = $value;
                        $size =~ s/[^0-9]//g;
                        $unit =~ s/[^A-Za-z]//g;
                        $unit = 'u' unless($unit);
                        $value = $size * $units{$unit};
                    }
                    unless (defined($pkginfo{$options{'package'}}->{$key})) {
                       $pkginfo{$options{'package'}}->{$key} = $value;
                    }
                    elsif (ref($pkginfo{$options{'package'}}->{$key}) eq 'ARRAY') {
                       push(@{$pkginfo{$options{'package'}}->{$key}}, $value);
                    }
                    else {
                      my $scalar = $pkginfo{$options{'package'}}->{$key};
                      delete($pkginfo{$options{'package'}}->{$key});
                      push(@{$pkginfo{$options{'package'}}->{$key}}, $scalar);
                      push(@{$pkginfo{$options{'package'}}->{$key}}, $value);
                    }
                    $lastkey = $key;
                }
            }
        }
        else {
            # already installed... get info returned from rpm
            my $pkgname = $options{'package'};
            $pkginfo{$pkgname}->{'name'} = $pkgname;
            foreach my $field (@infoqf) {
                if ($info =~ m#<Package name=\"\Q$pkgname\E\">.*?<$field>(.*?)</$field>#s) {
                    my $value = $1;
                    my $key = $field;
                    $key =~ tr/A-Z/a-z/;
                    my @values = split(/\n/, $value);
                    if ($#values) {
                        @{$pkginfo{$pkgname}->{$key}} = @values;
                    }
                    else {
                        $pkginfo{$pkgname}->{$key} = $value;
                    }
                }
            }
            # what requires package?
            @command = ('/bin/rpm', '-q', '--whatrequires', $options{'package'});
            my @results = `@command`;
            foreach my $line (@results) {
                if ($line =~ /(.*?)\-.*/) {
                    push(@{$pkginfo{$options{'package'}}->{'required_by'}}, $1);
                }
            }
            # get available updates
            my @updates = ();
            @command = ('/usr/bin/yum', 'list', 'updates', $options{'package'}, '2>&1');
            @results = `@command`;
            my $available = 0;
            foreach my $line (@results) {
                $available = 1 if ($line =~ /Updated Packages/);
                next unless ($available);
                if ($line =~ /^$options{'package'}\S+\s+(\S+)\s+/) {
                    my $vr = $1;
                    $vr =~ /(.*)\-(.*)/;
                    my $version = $1;
                    my $rp = $2;
                    if ($rp =~ /(.*?)\..*/) {
                        my $release = $1;
                        $version .= "-" . $release
                    }
                    push(@updates, $version);
                }
            }
            @{$pkginfo{$options{'package'}}->{'update_available'}} = @updates;
        }
        # get dependencies for specified package
        my %dependencies = ();
        @command = ('/usr/bin/yum', '-C', 'deplist', $options{'package'}, '2>&1');
        my @results = `@command`;
        my ($pkgname, $lastkey);
        $pkgname = $lastkey = "";
        foreach my $line (@results) {
            if ($line =~ /(.*?):(.*)/) {
                my $key = $1;
                my $value = $2;
                $key =~ tr/A-Z/a-z/;
                $key =~ s/^\s+//g;
                $key =~ s/\s+$//g;
                $value =~ s/^\s+//g;
                $value =~ s/\s+$//g;
                $key = $lastkey unless($key);
                if ($key eq 'package') {
                    last if ($pkgname ne "");
                    $pkgname = $key;
                }
                next unless ($pkgname);
                if ($key eq "provider") {
                    if ($value =~ /(.*?)\.(.*)/) {
                        $dependencies{$1} = '到';
                    }
                }
                $lastkey = $key;
            }
        }
        @{$pkginfo{$options{'package'}}->{'dependencies'}} = sort(keys(%dependencies));
    }
    elsif ($options{'group'} || $options{'installed'}) {
        # get installed packages that match specified group and/or pattern
        my @command = ('/bin/rpm', '-q');
        push(@command, '-a') unless ($options{'group'});
        push(@command, '--queryformat', '"%{NAME} "');
        push(@command, '--group', "\"$options{'group'}\"") if ($options{'group'});
        my $results = `@command`;
        $results =~ s/\s+$//g;
        my @packages = split(/ /, $results);
        @command = ('/bin/rpm', '-q');
        push(@command, '--queryformat', $listqfmt);
        push(@command, @packages);
        my $info = `@command`;
        foreach my $pkgname (@packages) {
            $pkginfo{$pkgname}->{'name'} = $pkgname;
            foreach my $field (@listqf) {
                if ($info =~ m#<Package name=\"\Q$pkgname\E\">.*?<$field>(.*?)</$field>#s) {
                    my $value = $1;
                    my $key = $field;
                    $key =~ tr/A-Z/a-z/;
                    my @values = split(/\n/, $value);
                    if ($#values) {
                        @{$pkginfo{$pkgname}->{$key}} = @values;
                    }
                    else {
                        $pkginfo{$pkgname}->{$key} = $value;
                    }
                }
            }
        }
        # delete packages that do not match search pattern
        if (defined($options{'pattern'}) && ($options{'pattern'} ne "")) {
            my @mismatches = ();
            foreach my $package (keys(%pkginfo)) {
                next if ($package =~ /$options{'pattern'}/i);
                if (defined($pkginfo{$package}->{'summary'})) {
                    my $summary = (ref($pkginfo{$package}->{'summary'}) eq "ARRAY") ?
                                   join(' ', @{$pkginfo{$package}->{'summary'}}) :
                                   $pkginfo{$package}->{'summary'};
                    next if ($summary =~ /$options{'pattern'}/i);
                }
                push(@mismatches, $package);
            }
            foreach my $mismatch (@mismatches) {
                delete($pkginfo{$mismatch});
            }
        }
    }
    else {
        # search repo for packages that match search criteria
        $options{'pattern'} = '.*' unless defined ($options{'pattern'});
        my @command = ('/usr/bin/yum', 'search', $options{'pattern'}, '2>&1');
        my @results = `@command`;
        unless (grep(/No Matches found/, @results)) {
            foreach my $result (@results) {
                if ($result =~ /(.*)\.(.*?) : (.*)/) {
                    my $pkgname = $1;
                    $pkginfo{$pkgname}->{'name'} = $pkgname;
                    $pkginfo{$pkgname}->{'arch'} = $2;
                    $pkginfo{$pkgname}->{'summary'} = $3;
                }
            }
        }
        # yum search returns very little information (name, arch, summary);
        # also need to get the version to show with the results
        @command = ('/usr/bin/yum', '-C', 'list', keys(%pkginfo), '2>&1');
        @results = `@command`;
        my $installed = 0;
        my $available = 0;
        foreach my $result (@results) {
            $installed = 1 if ($result =~ /Installed Packages/);
            $available = 1 if ($result =~ /Available Packages/);
            if (($installed || $available) && ($result =~ /^(\S+)\s+(\S+)\s+\S+/)) {
                my $na = $1;
                my $vr = $2;
                next unless ($na =~ /(.*)\..*/);
                my $pkgname = $1;
                if ($available && defined($pkginfo{$pkgname})) {
                    $vr =~ /(.*)\-(.*)/;
                    #my $version = $1;
                    #my $rp = $2;
                    #if ($rp =~ /(.*?)\..*/) {
                    #    my $release = $1;
                    #    $version .= "-" . $release
                    #}
                    #$pkginfo{$pkgname}->{'version'} = $version;
                    $pkginfo{$pkgname}->{'version'} = $1;
                    $pkginfo{$pkgname}->{'release'} = $2;
                }
                elsif ($installed && defined($pkginfo{$pkgname})) {
                    delete($pkginfo{$pkgname});
                }
            }
        }
    }

    # consolidate version and release
    foreach my $pkgname (keys(%pkginfo)) {
        next unless (defined($pkginfo{$pkgname}->{'version'}));
        my $version = $pkginfo{$pkgname}->{'version'};
        my $rp = $pkginfo{$pkgname}->{'release'};
        if ($rp =~ /(.*?)\..*/) {
            my $release = $1;
            $version .= "-" . $release
        }
        $pkginfo{$pkgname}->{'version'} = $version;
        delete($pkginfo{$pkgname}->{'release'});
    }

    return(%pkginfo);
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::package::info;

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    # check authorization
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized");
        return;
    }

    my $package = ( $xmlobj->child('package') &&
            defined($xmlobj->child('package')->value)
                  ? $xmlobj->child('package')->value : '' );

    unless ($package) {
        $vsap->error($_ERR{'PACKAGE_REQUIRED'} => "package not specified");
        return;
    }

    # get package info
    my %pkginfo = VSAP::Server::Modules::vsap::sys::package::_get( package => $package );

    # need local time zone for build date and install date
    my $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') ||
                   VSAP::Server::Modules::vsap::sys::timezone::get_timezone();

    # build dom
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:package:info');

    # package name
    $root->appendTextChild( name => $package );

    foreach my $field (keys(%{$pkginfo{$package}})) {
        if (ref($pkginfo{$package}->{$field}) eq "ARRAY") {
            if (($field eq "dependencies") || ($field eq "required_by")) {
                my $fnode = $root->appendChild($dom->createElement($field));
                foreach my $item (@{$pkginfo{$package}->{$field}}) {
                    $fnode->appendTextChild( package => $item );
                }
            }
            elsif ($field eq "description") {
                my $value = join("\n", @{$pkginfo{$package}->{$field}});
                $root->appendTextChild( $field => $value );
            }
            else {
                my $value = join(' ', @{$pkginfo{$package}->{$field}});
                $root->appendTextChild( $field => $value );
            }
        }
        else {
            my $value = $pkginfo{$package}->{$field};
            $root->appendTextChild( $field => $value );
        }
        if (($field eq "buildtime") || ($field eq "installtime")) {
            my $datefield = $field;
            $datefield =~ s/time/date/;
            my $time = $pkginfo{$package}->{$field};
            my $d = new VSAP::Server::G11N::Date( epoch => $time, tz => $timezone );
            if ($d) {
                my $date_node = $root->appendChild($dom->createElement($datefield));
                $date_node->appendTextChild( year   => $d->local->year    );
                $date_node->appendTextChild( month  => $d->local->month   );
                $date_node->appendTextChild( day    => $d->local->day     );
                $date_node->appendTextChild( hour   => $d->local->hour    );
                $date_node->appendTextChild( hour12 => $d->local->hour_12 );
                $date_node->appendTextChild( minute => $d->local->minute  );
                $date_node->appendTextChild( second => $d->local->second  );

                $date_node->appendTextChild( o_year   => $d->original->year    );
                $date_node->appendTextChild( o_month  => $d->original->month   );
                $date_node->appendTextChild( o_day    => $d->original->day     );
                $date_node->appendTextChild( o_hour   => $d->original->hour    );
                $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
                $date_node->appendTextChild( o_minute => $d->original->minute  );
                $date_node->appendTextChild( o_second => $d->original->second  );
                $date_node->appendTextChild( o_offset => $d->original->offset  );
            }
        }
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::package::list;

use VSAP::Server::G11N::Date;
use VSAP::Server::Modules::vsap::sys::timezone;
use VSAP::Server::Modules::vsap::user::prefs;

sub handler
{
    my $vsap = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    # check authorization
    unless ($vsap->{server_admin}) {
        $vsap->error($_ERR{'NOT_AUTHORIZED'} => "not authorized");
        return;
    }

    my $page = ( $xmlobj->child('page') &&
         defined($xmlobj->child('page')->value)
               ? $xmlobj->child('page')->value : 1 );

    # narrow list to a specifc group?
    my $group = ( $xmlobj->child('group') &&
          defined($xmlobj->child('group')->value)
                ? $xmlobj->child('group')->value : '' );

    # narrow list to those that match a regex search pattern?
    my $pattern = ( $xmlobj->child('pattern') &&
            defined($xmlobj->child('pattern')->value)
                  ? $xmlobj->child('pattern')->value : '' );

    # narrow list to only show installed packages?
    # (<installed/> and <installed>1</installed> ok)
    my $installed = ( $xmlobj->child('installed')
          ? ( defined($xmlobj->child('installed')->value)
                   ?  $xmlobj->child('installed')->value : 1 ) : 0 );

    # get packages
    my %packages = VSAP::Server::Modules::vsap::sys::package::_get( installed => $installed,
                                                                    group     => $group,
                                                                    pattern   => $pattern );

    # these view settings are saved as preferences to preserve state
    my %_psortprefs;
    if ($installed || $group) {
        # can sort by [ name | installtime | size ]
        # in ascending or descending order
        %_psortprefs = ( packages_list_sortby  => 'name',
                         packages_list_order   => 'ascending',
                         packages_list_sortby2 => 'installtime',
                         packages_list_order2  => 'ascending' );
    }
    else {
        # only thing to sort on is package name, so just need order
        %_psortprefs = ( packages_search_order  => 'ascending' );
    }

    for my $pref (keys %_psortprefs) {
        (my $p_pref = $pref) =~ s/packages_(list|search)_//;
        $_psortprefs{$pref} = ( $xmlobj->child($p_pref) && $xmlobj->child($p_pref)->value
                               ? $xmlobj->child($p_pref)->value
                               : VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, $pref) );
    }

    # how many packages shown per page?
    my $packages_per_page = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'packages_per_page') ||
                            VSAP::Server::Modules::vsap::sys::package::_default_range(keys(%packages));

    # this 'set_values' call must be after the get_value call above
    VSAP::Server::Modules::vsap::user::prefs::set_values( $vsap, $dom, %_psortprefs );

    # show installation times as dates in user's preferred timezone
    my $timezone;
    if ($installed || $group) {
        $timezone = VSAP::Server::Modules::vsap::user::prefs::get_value($vsap, 'time_zone') ||
                    VSAP::Server::Modules::vsap::sys::timezone::get_timezone();
    }

    # build sorted package list
    my @sorted_packages;
    if ($installed || $group) {
        @sorted_packages = sort {
                if (($_psortprefs{'packages_list_sortby'} eq "installtime") || ($_psortprefs{'packages_list_sortby'} eq "size")) {
                    # primary sort criteria requires numeric comparison
                    if ($packages{$a}->{$_psortprefs{'packages_list_sortby'}} == $packages{$b}->{$_psortprefs{'packages_list_sortby'}}) {
                        # primary sort values identical... fail over to secondary sort criteria
                        if (($_psortprefs{'packages_list_sortby2'} eq "installtime") || ($_psortprefs{'packages_list_sortby2'} eq "size")) {
                            # secondary sort criteria requires numeric comparison
                            return ( ($_psortprefs{'packages_list_order2'} eq "ascending") ?
                                     ($packages{$a}->{$_psortprefs{'packages_list_sortby2'}} <=> $packages{$b}->{$_psortprefs{'packages_list_sortby2'}}) :
                                     ($packages{$b}->{$_psortprefs{'packages_list_sortby2'}} <=> $packages{$a}->{$_psortprefs{'packages_list_sortby2'}}) );
                        }
                        # secondary sort criteria requires string comparison
                        return ( ($_psortprefs{'packages_list_order2'} eq "ascending") ?
                                 ($packages{$a}->{$_psortprefs{'packages_list_sortby2'}} cmp $packages{$b}->{$_psortprefs{'packages_list_sortby2'}}) :
                                 ($packages{$b}->{$_psortprefs{'packages_list_sortby2'}} cmp $packages{$a}->{$_psortprefs{'packages_list_sortby2'}}) );
                    }
                    return ( ($_psortprefs{'packages_list_order'} eq "ascending") ?
                             ($packages{$a}->{$_psortprefs{'packages_list_sortby'}} <=> $packages{$b}->{$_psortprefs{'packages_list_sortby'}}) :
                             ($packages{$b}->{$_psortprefs{'packages_list_sortby'}} <=> $packages{$a}->{$_psortprefs{'packages_list_sortby'}}) );
                }
                else {
                    # primary sort criteria requires string comparison
                    if ($packages{$a}->{$_psortprefs{'packages_list_sortby'}} eq $packages{$b}->{$_psortprefs{'packages_list_sortby'}}) {
                        # primary sort values identical... fail over to secondary sort criteria
                        if (($_psortprefs{'packages_list_sortby2'} eq "installtime") || ($_psortprefs{'packages_list_sortby2'} eq "size")) {
                            # secondary sort criteria requires numeric comparison
                            return ( ($_psortprefs{'packages_list_order2'} eq "ascending") ?
                                     ($packages{$a}->{$_psortprefs{'packages_list_sortby2'}} <=> $packages{$b}->{$_psortprefs{'packages_list_sortby2'}}) :
                                     ($packages{$b}->{$_psortprefs{'packages_list_sortby2'}} <=> $packages{$a}->{$_psortprefs{'packages_list_sortby2'}}) );
                        }
                        # secondary sort criteria requires string comparison
                        return ( ($_psortprefs{'packages_list_order2'} eq "ascending") ?
                                 ($packages{$a}->{$_psortprefs{'packages_list_sortby2'}} cmp $packages{$b}->{$_psortprefs{'packages_list_sortby2'}}) :
                                 ($packages{$b}->{$_psortprefs{'packages_list_sortby2'}} cmp $packages{$a}->{$_psortprefs{'packages_list_sortby2'}}) );
                    }
                    return ( ($_psortprefs{'packages_list_order'} eq "ascending") ?
                             ($packages{$a}->{$_psortprefs{'packages_list_sortby'}} cmp $packages{$b}->{$_psortprefs{'packages_list_sortby'}}) :
                             ($packages{$b}->{$_psortprefs{'packages_list_sortby'}} cmp $packages{$a}->{$_psortprefs{'packages_list_sortby'}}) );
                }
            } (keys(%packages));
    }
    else {
        # only thing to sort on is package name
        @sorted_packages = sort {
                return ( ($_psortprefs{'package_search_order'} eq "ascending") ? ($a cmp $b) : ($b cmp $a) );
            } (keys(%packages));
    }

    my $num_packages = $#sorted_packages + 1;
    my $total_pages = ( $packages_per_page > 0 && $num_packages > 0
                        ? ( $num_packages % $packages_per_page
                            ? int($num_packages / $packages_per_page) + 1
                            : int($num_packages / $packages_per_page) )
                        : 1);

    if ($page > $total_pages) { $page = 1; }
    my $prev_page = ($page == 1) ? '' : $page - 1;
    my $next_page = ($page == $total_pages) ? '' : $page + 1;
    my $first_package = 1 + ($packages_per_page * ($page - 1));
    if ($num_packages < 1) { $first_package = 0; }
    my $last_package = $first_package + $packages_per_page - 1;
    if ($last_package > $num_packages) { $last_package = $num_packages; }
    if ($last_package < 1) { $last_package = 0; }

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:package:list');
    $root->appendTextChild( installed     => $installed );
    $root->appendTextChild( group         => $group ) if ($group);
    $root->appendTextChild( pattern       => $pattern ) if ($pattern);
    $root->appendTextChild( num_packages  => $num_packages );
    $root->appendTextChild( packages_per_page  => $packages_per_page );
    $root->appendTextChild( page          => $page );
    $root->appendTextChild( total_pages   => $total_pages );
    $root->appendTextChild( prev_page     => $prev_page );
    $root->appendTextChild( next_page     => $next_page );
    $root->appendTextChild( first_package => $first_package );
    $root->appendTextChild( last_package  => $last_package );
    if ($installed) {
        $root->appendTextChild( sortby    => $_psortprefs{'packages_list_sortby'} );
        $root->appendTextChild( order     => $_psortprefs{'packages_list_order'} );
        $root->appendTextChild( sortby2   => $_psortprefs{'packages_list_sortby2'} );
        $root->appendTextChild( order2    => $_psortprefs{'packages_list_order2'} );
    }
    else {
        $root->appendTextChild( order     => $_psortprefs{'packages_search_order'} );
    }

    if ($#sorted_packages > -1) {
        # loop through "visible" packages
        for my $package ( @sorted_packages[($first_package-1 .. $last_package-1)] ) {
            # node for this package
            my $package_node = $dom->createElement('package');
            # package name
            $package_node->appendTextChild( name => $package );
            # package version
            $package_node->appendTextChild( version => $packages{$package}->{'version'} );
            # package summary
            $package_node->appendTextChild( summary => $packages{$package}->{'summary'} );
            if ($installed || $group) {
                # package group
                $package_node->appendTextChild( group => $packages{$package}->{'group'} );
                # package size
                $package_node->appendTextChild( size => $packages{$package}->{'size'} );
                # install time
                my $itime = $packages{$package}->{'installtime'};
                $package_node->appendTextChild( installtime => $itime );
                my $d = new VSAP::Server::G11N::Date( epoch => $itime, tz => $timezone );
                if ($d) {
                    my $date_node = $package_node->appendChild($dom->createElement('installdate'));
                    $date_node->appendTextChild( year   => $d->local->year    );
                    $date_node->appendTextChild( month  => $d->local->month   );
                    $date_node->appendTextChild( day    => $d->local->day     );
                    $date_node->appendTextChild( hour   => $d->local->hour    );
                    $date_node->appendTextChild( hour12 => $d->local->hour_12 );
                    $date_node->appendTextChild( minute => $d->local->minute  );
                    $date_node->appendTextChild( second => $d->local->second  );

                    $date_node->appendTextChild( o_year   => $d->original->year    );
                    $date_node->appendTextChild( o_month  => $d->original->month   );
                    $date_node->appendTextChild( o_day    => $d->original->day     );
                    $date_node->appendTextChild( o_hour   => $d->original->hour    );
                    $date_node->appendTextChild( o_hour12 => $d->original->hour_12 );
                    $date_node->appendTextChild( o_minute => $d->original->minute  );
                    $date_node->appendTextChild( o_second => $d->original->second  );
                    $date_node->appendTextChild( o_offset => $d->original->offset  );
                }
            }
            # append to root
            $root->appendChild($package_node);
        }
    }

    if ($VSAP::Server::Modules::vsap::globals::PLATFORM_DISTRO eq 'rhel') {
        if ($installed || $group) {
            # add a summary of groups represented by the query
            my %groups = ();
            foreach my $package (keys(%packages)) {
                my $pgroup = ( defined($packages{$package}->{'group'}) ?
                                       $packages{$package}->{'group'} : 'NONE' );
                if (defined($groups{$pgroup})) {
                    $groups{$pgroup}++;
                }
                else {
                    $groups{$pgroup} = 1;
                }
            }
            my $groups_node = $dom->createElement('groups');
            foreach my $group (sort { $a cmp $b } (keys(%groups))) {
                my $group_node = $dom->createElement('group');
                $group_node->appendTextChild( name => $group );
                $group_node->appendTextChild( number => $groups{$group} );
                $groups_node->appendChild($group_node);
            }
            $root->appendChild($groups_node);
        }
    }

    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::packages - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::packages;


=head1 DESCRIPTION

The VSAP packages module allows system administrators to view, install,
uninstall, and update packages.

=head2 sys:package:info

Get information about a specific package:

    <vsap type="sys:package:info">
        <package>package name</package>
    </vsap>

For example:

    <vsap type="sys:package:info">
        <package>curl</package>
    </vsap>

If the package is found, then VSAP will return the detailed information
about the package:

    <vsap type="sys:package:info">
        <package>package name</package>
        <version>version number</version>
        <summary>description found in package file</summary>
        <size>size of installation (in bytes)</size>
        <dependencies>
            <package>package name</package>
            <package>package name</package>
              .
              .
              .
        </dependencies>
        <required_by>
            <package>package name</package>
            <package>package name</package>
              .
              .
              .
        </required_by>
    </vsap>

=head2 sys:package:install

Installs a specific package:

    <vsap type="sys:package:install">
        <package>package name</package>
    </vsap>

For example:

    <vsap type="sys:package:install">
        <package>curl</package>
    </vsap>

If the package is found, it will be installed or an error will be returned.
A successful installation will be indicated by the return status:

    <vsap type="sys:package:install">
        <package>package name</package>
        <status>ok</status>
    </vsap>

=head2 sys:package:list

Get a list of packages.  By default, a list of installed packages is
returned.  However, if a search pattern or group is given then a
list of packages that match the search criteria will be returned.

    <vsap type="sys:package:list"/>

The query can also include optional page, sort options, and pattern
criteria.

        page
                An integer value {1..npage} which indicates what
                page of packages should be shown.  The value of 1
                is presumed if not otherwise specified.

        sortby
                An enumerated value which declares how the list
                of packages should be sorted.  Currently, the
                only possible values are:

                        installtime
                        name
                        size

                When listing packages that are not installed, then
                the only valid value for sorting is using 'name'.

        order
                Define how the the sorting should be ordered, which
                can be either:

                        ascending
                        descending

        installed
                If defined, only show installed packages.

        group
                If defined, the group will be used to narrow
                the list of returned packages to those of the
                named group.  The match is CASE-sensitive.
                Available only on platforms that use rpm.

        pattern
                If defined, the pattern will be used to narrow
                the list of returned packages to those whose
                names (or descriptions) match the pattern specified.
                If not defined, a default pattern (.*) is used.

Some examples that utilize the optional input paramaters:

    <vsap type="sys:package:list">
        <range>25</range>
        <start>76</start>
        <sortby>name</sortby>
        <order>descending</order>
    </vsap>

    <vsap type="sys:package:list">
        <search_pattern>php</search_pattern>
        <range>10</range>
    </vsap>

    <vsap type="sys:package:list">
        <group>Development/Languages</group>
        <range>100</range>
    </vsap>

Based on the input criteria, a list of packages will be returned.
Some basic information about each package is included:

    <vsap type="sys:package:list">
        <num_packages>number of matching packages</num_packages>
        <range>number of packages listed</range>
        <start>starting row</start>
        <end>ending row</end>
        <package>
            <name>package name</name>
            <summary>comment found in package file</summary>
            <version>version number</version>
              .
              .
              .
        </package>
        <package>
          .
          .
          .
        </package>
    </vsap>

=head2 sys:package:reinstall

Reinstalls a specific package, overwriting the current installation
data:

    <vsap type="sys:package:reinstall">
        <package>package name</package>
    </vsap>

For example:

    <vsap type="sys:package:reinstall">
        <package>curl</package>
    </vsap>

If the package is found, it will be reinstalled or an error will be
returned.

A successful reinstallation will be indicated by the return status:

    <vsap type="sys:package:reinstall">
        <package>package name</package>
        <status>ok</status>
    </vsap>

=head2 sys:package:uninstall

Uninstalls a specific package:

    <vsap type="sys:package:uninstall">
        <package>package name</package>
    </vsap>

For example:

    <vsap type="sys:package:uninstall">
        <package>curl</package>
    </vsap>

If the package is found, it will be uninstalled or an error will be
returned.

A successful uninstallation will be indicated by the return status:

    <vsap type="sys:package:uninstall">
        <package>package name</package>
        <status>ok</status>
    </vsap>

=head2 sys:package:update

Updates a specific package to latest available version:

    <vsap type="sys:package:update">
        <package>package name</package>
    </vsap>

For example:

    <vsap type="sys:package:update">
        <package>curl</package>
    </vsap>

If the package is found, it will be updated or an error will be
returned.

A successful update will be indicated by the return status:

    <vsap type="sys:package:update">
        <package>package name</package>
        <status>ok</status>
    </vsap>


=head1 SEE ALSO

rpm(8)

=head1 AUTHOR

Rus Berrett, E<lt>rus@surfutah.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
