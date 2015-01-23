# iptables.2.m
#
# smtp server
#
-A INPUT -p tcp -m tcp --dport smtp -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --sport auth -m state --state ESTABLISHED -j ACCEPT

#
# POP3 (110) - Retrieving Mail as a POP3 client
# POP3S (995) - Retrieving Mail as a POP3S client
# IMAP (143) - Retrieving Mail as an IMAP client
# IMAPS (993) - Retrieving Mail as an Secure IMAP client
# IMAPS (1194) - Another port for retrieving mail as a secure IMAP client
#
-A INPUT -p tcp -m state --state ESTABLISHED,RELATED -m multiport --sports 110,995,143,993,1194 -m tcp --dport 1024: -j ACCEPT

#
# POP3 (110) - Hosting a POP3 server for remote clients
# POP3S (995) - Hosting a secure POP3 server for remote clients
# IMAP (143) - Hosting an IMAP server for remote clients
# IMAPS (993) - Hosting a Secure IMAP server for remote clients
#
-A INPUT -p tcp --sport 1024: -m multiport --dports 110,995,143,993 -j ACCEPT

# End iptables.2.m

