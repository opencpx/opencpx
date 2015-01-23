# iptables.3.c
#
# DNS client (53)
# 
-A INPUT -p udp --sport 53 --dport 1024: -m state --state ESTABLISHED,RELATED -j ACCEPT

# TCP client-to-server requests are allowed by the protocol
# if UDP requests fail. This is rarely seen. Usually, clients
# use TCP as a secondary name server for zone transfers from
# their primary name servers, and as hackers.
-A INPUT -p tcp -m state --state ESTABLISHED,RELATED --sport 53 --dport 1024: -j ACCEPT

#
# ntp client
#
-A INPUT -s 0.0.0.0/0 -p udp -m udp --sport 123 -j ACCEPT

#
# Outbound SMTP / e-mail
# ssh client (22)
#
-A INPUT -p tcp -m multiport --sports smtp,22 -m state --state ESTABLISHED -j ACCEPT

#
# ssh server
#
-A INPUT -p tcp -m tcp --dport 22 -m state --state INVALID,NEW -j LOG --log-prefix "iptables(ssh connection): "
-A INPUT -s 0.0.0.0/0 -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

#
# Urchin
#

-A INPUT -s 0.0.0.0/0 -p tcp -m tcp --dport 9878 -m state --state NEW,ESTABLISHED -j ACCEPT

#
# webmin
#

-A INPUT -s 0.0.0.0/0 -p tcp -m tcp --dport 10000 -m state --state NEW,ESTABLISHED -j ACCEPT

# End iptables.3.c

