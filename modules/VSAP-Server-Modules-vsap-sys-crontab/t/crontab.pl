## Scott Wiersdorf
## Created: Fri Apr 29 21:56:46 GMT 2005
## $SMEId: apps/vsap/modules/VSAP-Server-Modules-vsap-sys-crontab/t/crontab.pl,v 1.8 2005/10/20 20:46:35 kwhyte Exp $

## common stuff

use warnings;
use vars qw( @Sys_cron  @Usr_cron);

BEGIN {
    rename( $CRONTAB, "$CRONTAB.$$" ) if -e $CRONTAB;
    system('crontab', '/dev/null') if ($SIG);
}

END {
    rename( "$CRONTAB.$$", $CRONTAB ) if -e "$CRONTAB.$$";
    system('crontab', '/dev/null') if ($SIG);
}

sub write_sys_cron {
    my $idx = shift;
    open CT, ">$CRONTAB"
      or die "Could not write system crontab: $!\n";
    print CT $Sys_cron[$idx];
    close CT;
}

sub write_usr_cron {
    my $idx = shift;
    open CT, ">$CRONTAB"
      or die "Could not write user crontab: $!\n";
    print CT $Usr_cron[$idx];
    close CT;
    system('crontab', $CRONTAB);
}

##
## system crontabs
##

## entry 0
push @Sys_cron, <<'_CRON_';
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
HOME=/var/log

#minute	hour	mday	month	wday	who	command

*/5 * * * * root	/usr/libexec/atrun

# rotate log files every hour, if necessary
0 * * * * root	newsyslog

# do daily/weekly/monthly maintenance
1 3 * * * root	periodic daily
15 4 * * 6 root	periodic weekly
30 5 1 * * root	periodic monthly

@daily root savelogs --apacheconf=/www/conf/httpd.conf --apachehost=farley.com --postmovehook=/usr/local/apache/bin/apachectl graceful --period=30 --chown=farley:

_CRON_

## entry 1
push @Sys_cron, $Sys_cron[0];
$Sys_cron[1] .= <<'_CRON_';
## onlineutah.com log file and search engine processing
10 0 * * * root    savelogs --config=/usr/local/etc/savelogs-onlineutah.com.conf
15 0 * * * bin    analog -G +g/usr/local/share/analog/onlineutah.com-report.cfg
30 0 * * * bin    savelogs --config=/.savelogs-onlineutah.com-cache.conf
5 3 * * 1-5 bin    /usr/local/htdig/bin/rundig -c /usr/local/etc/htdig/onlineutah.com.conf

## perlcode.org mail archiving and search engine processing
15 3 * * * www   /usr/local/bin/mhonarc -rcfile /www/perlcode.org/lists/vps-mail/.vps-mail.rc -add -outdir /www/perlcode.org/lists/vps-mail /usr/local/majordomo/lists/perlcode.org/archive/vps-mail.archive.*
30 3 * * * www   /usr/local/htdig/bin/rundig -c /usr/local/etc/htdig/perlcode.org-vps-mail.conf

_CRON_

## entry 2
push @Sys_cron,  $Sys_cron[1];
$Sys_cron[2] .= <<'_CRON_';
## mail processing
FOOPROG=/bar/blech
@daily root     savelogs --config=/usr/local/etc/savelogs-spam.conf
#@daily root     savelogs --config=/usr/local/etc/savelogs-clamav.conf

_CRON_

## entry 3
push @Sys_cron,  $Sys_cron[2];
$Sys_cron[3] .= <<'_CRON_';
1  5 * * *   bin    echo 1
2  5 * * *   bin    echo 2
3  5 * * *   bin    echo 3
4  5 * * *   bin    echo 4
5  5 * * *   bin    echo 5
6  5 * * *   bin    echo 6
7  5 * * *   bin    echo 7
8  5 * * *   bin    echo 8
9  5 * * *   bin    echo 9
10 5 * * *   bin    echo 10
11 5 * * *   bin    echo 11
12 5 * * *   bin    echo 12
13 5 * * *   bin    echo 13
14 5 * * *   bin    echo 14
15 5 * * *   bin    echo 15
16 5 * * *   bin    echo 16
17 5 * * *   bin    echo 17
_CRON_


##
## user crontabs
##

## entry 0
push @Usr_cron, <<'_CRON_';
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
HOME=/var/log

#minute	hour	mday	month	wday	who	command

*/5 * * * *	/usr/libexec/atrun

# rotate log files every hour, if necessary
0 * * * *	newsyslog

# do daily/weekly/monthly maintenance
1 3 * * *	periodic daily
15 4 * * 6	periodic weekly
30 5 1 * *	periodic monthly

@daily savelogs --apacheconf=/www/conf/httpd.conf --apachehost=farley.com --postmovehook=/usr/local/apache/bin/apachectl graceful --period=30 --chown=farley:

_CRON_

## entry 1
push @Usr_cron, $Usr_cron[0];
$Usr_cron[1] .= <<'_CRON_';
## onlineutah.com log file and search engine processing
10 0 * * *	savelogs --config=/usr/local/etc/savelogs-onlineutah.com.conf
15 0 * * *	analog -G +g/usr/local/share/analog/onlineutah.com-report.cfg
30 0 * * *	savelogs --config=/.savelogs-onlineutah.com-cache.conf
5 3 * * 1-5	/usr/local/htdig/bin/rundig -c /usr/local/etc/htdig/onlineutah.com.conf

## perlcode.org mail archiving and search engine processing
15 3 * * *	/usr/local/bin/mhonarc -rcfile /www/perlcode.org/lists/vps-mail/.vps-mail.rc -add -outdir /www/perlcode.org/lists/vps-mail /usr/local/majordomo/lists/perlcode.org/archive/vps-mail.archive.*
30 3 * * *	/usr/local/htdig/bin/rundig -c /usr/local/etc/htdig/perlcode.org-vps-mail.conf

_CRON_

## entry 2
push @Usr_cron,  $Usr_cron[1];
$Usr_cron[2] .= <<'_CRON_';
## mail processing
FOOPROG=/bar/blech
@daily	savelogs --config=/usr/local/etc/savelogs-spam.conf
#@daily	savelogs --config=/usr/local/etc/savelogs-clamav.conf

_CRON_


## entry 3
push @Usr_cron,  $Usr_cron[2];
$Usr_cron[3] .= <<'_CRON_';
1  5 * * *   echo 1
2  5 * * *   echo 2
3  5 * * *   echo 3
4  5 * * *   echo 4
5  5 * * *   echo 5
6  5 * * *   echo 6
7  5 * * *   echo 7
8  5 * * *   echo 8
9  5 * * *   echo 9
10 5 * * *   echo 10
11 5 * * *   echo 11
12 5 * * *   echo 12
13 5 * * *   echo 13
14 5 * * *   echo 14
15 5 * * *   echo 15
16 5 * * *   echo 16
17 5 * * *   echo 17
_CRON_


