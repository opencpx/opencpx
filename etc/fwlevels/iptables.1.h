# iptables.1.h
#
# This chain logs, then DROPs "Xmas" and Null packets which might 
# indicate a port-scan attempt
#
-N ScanD

-A ScanD -p tcp -m limit --limit 1/s -j LOG --log-prefix "[TCP Scan?] "
-A ScanD -p udp -m limit --limit 1/s -j LOG --log-prefix "[UDP Scan?] "
-A ScanD -p icmp -m limit --limit 1/s -j LOG --log-prefix "[ICMP Scan?] "
-A ScanD -f -m limit --limit 1/s -j LOG --log-prefix "[FRAG Scan?] "
-A ScanD -j DROP

#
# This chain limits the number of new incoming connections to
#  prevent DDoS attacks
#
-N DDoS

-A DDoS -m limit --limit 100/s --limit-burst 500 -j RETURN
-A DDoS -j LOG --log-prefix "[DOS Attack/SYN Scan?] "
-A DDoS -j DROP

# End iptables.1.h

