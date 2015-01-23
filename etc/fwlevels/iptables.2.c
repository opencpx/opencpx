# iptables.2.c
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
#
-A INPUT -p tcp -m tcp --sport smtp -m state --state ESTABLISHED -j ACCEPT

#
# FTP (20, 21) - Allowing outgoing client access to remote FTP servers
#                               Active & Passive
#
-A INPUT -p tcp -m tcp --sport ftp -m state --state ESTABLISHED -j ACCEPT

-A INPUT -p tcp -m tcp --sport ftp-data -m state --state ESTABLISHED,RELATED -j ACCEPT

-A INPUT -p tcp -m tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED -j ACCEPT

#
# FTPS (989, 990) - Allowing incoming access to your local FTP+SSL server
#
# Incoming request
#
-A INPUT -p tcp -m tcp --sport 1024: --dport 990 -m state --state NEW,ESTABLISHED -j ACCEPT

#
# Normal Port mode FTP+SSL data channel responses
#
-A INPUT -p tcp -m tcp --sport 1024: --dport 989 -m state --state ESTABLISHED,RELATED -j ACCEPT

#
# Passive mode FTP data channel responses
#
-A INPUT -p tcp -m tcp --sport 1024: --dport 1024: -m state --state NEW,ESTABLISHED -j ACCEPT

#
# TELNET & TELNETS(23,992) - Allowing outgoing client access to remote sites
#

-A INPUT -p tcp -m multiport --sports 23,992 -m tcp --dport 1024: -m state --state ESTABLISHED,RELATED -j ACCEPT

#
# TELNETS (992) - Allowing incoming access to your local server
#

-A INPUT -p tcp --sport 1024: --dport 992 -j ACCEPT

#
# ssh client
#
-A INPUT -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

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

# End iptables.2.c

