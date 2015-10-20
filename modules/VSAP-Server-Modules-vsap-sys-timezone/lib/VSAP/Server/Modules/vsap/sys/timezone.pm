package VSAP::Server::Modules::vsap::sys::timezone;

use 5.008004;
use strict;
use warnings;

use Digest::MD5;

##############################################################################

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_timezone );

##############################################################################

our $VERSION = '0.12';

our %_ERR = ( 
              ERR_INVALID_TIMEZONE => 100,
              ERR_TIMEZONE_REQUIRED => 101,
              ERR_SET => 102,
              ERR_GET => 103,
              ERR_NOTAUTHORIZED => 104
            );

our $ZONEINFO_PATH = '/usr/share/zoneinfo';
our $ETC_LOCALTIME = '/etc/localtime';

# We list our timezones here so that we don't include any timezones which are
# not in our strings files.  List zoneinfo files in the $ZONEINFO_PATH first,
# followed by directories; list continents by order of preference (BUG27685)
our @TIMEZONES = (
                   'CET',
                   'CST6CDT',
                   'EET',
                   'EST',
                   'EST5EDT',
                   'GMT',
                   'HST',
                   'MET',
                   'MST',
                   'MST7MDT',
                   'PST8PDT',
                   'WET',
                   'UTC',
                   'America',
                   'Asia',
                   'Europe',
                   'Indian',
                   'Australia',
                   'Atlantic',
                   'Pacific',
                   'Africa',
                   'Antarctica',
                   'Arctic',
                 );

##############################################################################

sub _get_md5
{
    my $path = shift;

    open FH, "<$path" || die "$!";
    my $ctx = Digest::MD5->new;
    $ctx->addfile(*FH);
    my $filemd5 = $ctx->hexdigest;
    close FH;

    return $filemd5;
}

# ----------------------------------------------------------------------------

sub _find_timezone
{
    my $md5 = shift;
    my $path = shift;
    my @files;

    # handle the case when the path isn't a directory, for the EST, EET, ones in the root. 
    if (-d $path) { 
        opendir DIR, $path;
        @files = sort readdir DIR;
        closedir DIR;
    }
    else { 
        return $path if (_get_md5($path) eq $md5);
    }

    foreach my $file (@files) {
        next if ($file =~ /^\./);
        my $path = $path.'/'.$file;
        # If we created @files by just pointing to a path above, this will always be false. 
        if (-d $path) {
            my $ret = _find_timezone($md5,$path);
            return $ret if defined($ret);
        }
        else {
            return $path if (_get_md5($path) eq $md5);
        }
    }
    return undef;
}

# ----------------------------------------------------------------------------

sub _get_timezone_fullpath
{
    return "$ZONEINFO_PATH/GMT" unless (-e $ETC_LOCALTIME);

    my $ctx = Digest::MD5->new;
    open FH, "<$ETC_LOCALTIME";
    $ctx->addfile(*FH);
    my $md5 = $ctx->hexdigest;
    close FH;

    my $timezone = undef;  

    foreach my $zone (@TIMEZONES) { 
        my $path = $ZONEINFO_PATH . '/' . $zone;
        $timezone = _find_timezone($md5, $path);
        last if ($timezone);
    }
    return($timezone);
}

##############################################################################

sub get_timezone
{
    my $timezone = _get_timezone_fullpath();

    if ($timezone) {
        $timezone =~ s/$ZONEINFO_PATH\///
    }
    else {
        warn("$ETC_LOCALTIME does not match a zone in our TIMEZONES!");
    }

    return($timezone);
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::timezone::set;

use File::Copy qw(copy);

use VSAP::Server::Modules::vsap::logger;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    my $timezone = $xmlobj->child('timezone') ? $xmlobj->child('timezone')->value : undef;

    unless (defined($timezone)) {
        $vsap->error($_ERR{ERR_TIMEZONE_REQUIRED} => "timezone element is required.");
        return;
    }

    unless ($timezone =~ (/^[\w\/\+\-]+$/)) {
        $vsap->error($_ERR{ERR_INVALID_TIMEZONE} => "invalid characters in timezone.");
        return;
    }

    unless (-e "$ZONEINFO_PATH/$timezone" && -f "$ZONEINFO_PATH/$timezone") {
        $vsap->error($_ERR{ERR_INVALID_TIMEZONE} => "non-existant timezone.");
        return;
    }

    unless ($vsap->{server_admin}) { 
        $vsap->error($_ERR{ERR_NOTAUTHORIZED} => "not authorized to set timezone");
        return;
    }

    if (-l $ETC_LOCALTIME) {
        # First we must unlink the existing /etc/localtime so that
        # we can link up the new one.  We need to do this as root.
        ROOT: {
            local $> = $) = 0;  ## regain privileges for a moment

            if (-f $ETC_LOCALTIME && !unlink $ETC_LOCALTIME) {
                $vsap->error($_ERR{ERR_SET}, "Unable to unlink $ETC_LOCALTIME: $!");
                return;
            }

            unless (symlink "$ZONEINFO_PATH/$timezone", $ETC_LOCALTIME) {
                $vsap->error($_ERR{ERR_SET}, "Unable to create symlink to $ETC_LOCALTIME: $!");
                return;
            }
        }
    }
    else {
        ROOT: { 
            local $> = $) = 0;  ## regain privileges for a moment

            unless (copy("$ZONEINFO_PATH/$timezone", $ETC_LOCALTIME)) { 
                $vsap->error($_ERR{ERR_SET}, "unable to copy $timezone to $ETC_LOCALTIME: $!");
                return;
            }
        }
    }

    # paper trail
    VSAP::Server::Modules::vsap::logger::log_message("$vsap->{username} set server timezone to '$timezone'");

    # generate the response
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:timezone:set');
    $root->appendTextChild( timezone => $timezone );
    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::sys::timezone::get;

sub handler
{
    my $vsap   = shift;
    my $xmlobj = shift;
    my $dom = $vsap->{_result_dom};

    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:timezone:get');
  
    # If file doesn't exist, assume GMT.
    unless (-f $ETC_LOCALTIME) { 
        $root->appendTextChild( timezone => 'GMT');
        $dom->documentElement->appendChild($root);
        return;
    }
    
    unless (-r _ ) { 
        $vsap->error($_ERR{ERR_GET}, "$ETC_LOCALTIME not readable.");
        return;
    }

    my $timezone = _get_timezone_fullpath();
    unless ($timezone =~ (/^$ZONEINFO_PATH/)) { 
        $vsap->error($_ERR{ERR_GET}, "$ETC_LOCALTIME does not point to a file in $ZONEINFO_PATH");
        return;
    }

    # Trim the leading path from the value. 
    $timezone =~ (s/$ZONEINFO_PATH\///g);

    $root->appendTextChild( timezone => $timezone);
    $dom->documentElement->appendChild($root);

    return;
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::timezone - VSAP module to setting and getting of the the timezone. 

=head1 SYNOPSIS

    <vsap type='sys:timezone:set'>
        <timezone>America/New_York</timezone>
    </vsap>

    <vsap type='sys:timezone:get'/>

=head2 sys:timezone:set

Request that the time zone be set to New_York, this corresponds
to EST and EDT time. 

<vsap type='sys:timezone:set'>
    <timezone>America/New_York</timezone>
</vsap>

The server would respond back with the below response: 

<vsap type='sys:timezone:set'>
    <timezone>America/New_York</timezone>
</vsap>

=head2 sys:timezone:get

Request the current time zone. 

<vsap type='sys:timezone:get'/>

The server would respond back with the below response: 

<vsap type='sys:timezone:get'>
    <timezone>America/New_York</timezone>
</vsap>

=head1 ERRORS

The following errors are returned by this module. 

=head2 sys:timezone:set
        100 - Unknown timezone specified. 
        101 - timezone element is required. 
        102 - Unable to set timezone. 
        104 - Not authorized. Must be a server admin.

=head2 sys:timezone:get
        103 - Unable to get timezone.

=head1 DESCRIPTION

This module sets and gets the timezone for the VPS2 account. This
is done by controlling where the /etc/localtime file points to. 
This file must point to a zoneinfo file which describes the specific
rules of that timezone. These files are stored in /usr/share/zoneinfo.
A symbolic link is used so that we can simply use readlink to determine
the current timezone. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

tzsetup(8), zic(8), /usr/share/zoneinfo, /usr/src/share/zoneinfo

=head1 AUTHOR

James Russo

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
