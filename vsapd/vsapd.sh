#!/bin/sh
#
# PROVIDE: vsapd
# REQUIRE: LOGIN
# BEFORE:  securelevel
# KEYWORD: FreeBSD shutdown

prefix=/usr/local/cp

#
# Add the following lines to /etc/rc.conf to enable vsapd:
#
#vsapd_enable="YES"
#

. /usr/local/etc/rc.subr

name="vsapd"
rcvar=`set_rcvar`

command="${prefix}/sbin/vsapd"
sysname=`uname`
## !! IMPORTANT !! ## 
## In order for this script to work correctly, the command interpreter 
## in this script and the actual vsapd must be the same. This will 
## need to be adjusted on each platform. With out them being the same
## the script will say that it's not running every time. 
if [ -d '/skel' -o $sysname = "GNU/Linux" ]; then 
    # For VPS2
    command_interpreter=/usr/local/bin/perl
else
    # For Signature.
    command_interpreter=${prefix}/bin/perl5.8.4
fi

pidfile=/var/run/vsapd.pid

# set defaults

vsapd_enable=${vsapd_enable:-"NO"}
vsapd_pidfile=${vsapd_pidfile:-${pidfile}}
vsapd_program=${vsapd_program:-${command}}

load_rc_config $name
run_rc_command "$1"
