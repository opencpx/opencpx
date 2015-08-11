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

if [ -e /usr/local/etc/rc.subr ]; then
  . /usr/local/etc/rc.subr
else
  . /etc/rc.subr
fi

name="vsapd"
rcvar=`set_rcvar`

command="${prefix}/sbin/vsapd"
command_interpreter=/usr/local/bin/perl
pidfile=/var/run/vsapd.pid

# set defaults

vsapd_enable=${vsapd_enable:-"NO"}
vsapd_pidfile=${vsapd_pidfile:-${pidfile}}
vsapd_program=${vsapd_program:-${command}}

load_rc_config $name
run_rc_command "$1"
