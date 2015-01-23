# iptables.2.w
#
# http client
#
-A INPUT -p tcp -m multiport --sports http,https,webcache -m tcp --dport 1024: -m state --state ESTABLISHED -j ACCEPT

#
# http server
#
-A INPUT -p tcp -m tcp --sport 1024: -m multiport --dports http,https,webcache -m state --state NEW,ESTABLISHED -j ACCEPT

# End iptables.2.w

