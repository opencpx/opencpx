# iptables.3.m
#
# smtp server
#

-A INPUT -p tcp -m tcp --dport smtp -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --sport auth -m state --state ESTABLISHED -j ACCEPT

#
# POP3S (995) - Hosting a secure POP3 server for remote clients
# IMAPS (993) - Hosting a Secure IMAP server for remote clients
#
-A INPUT -p tcp --sport 1024: -m multiport --dports 995,993 -j ACCEPT

#
# IMAP (143) - Retrieving Mail as an IMAP client
# IMAPS (993) - Retrieving Mail as an Secure IMAP client
# POP3S (995) - Retrieving Mail as a POP3S client
# IMAPS (1194) - Another port for retrieving mail as secure IMAP client
#
-A INPUT -p tcp -m state --state ESTABLISHED,RELATED -m multiport --sports 143,993,995,1194 -m tcp --dport 1024: -j ACCEPT

# End iptables.3.m

