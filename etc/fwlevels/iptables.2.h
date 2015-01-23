# iptables.2.h
#
# This custom chain logs, then DROPs packets.
#
-N LnD

-A LnD -p tcp -m limit --limit 1/s -j LOG --log-prefix "[TCP drop] " --log-level=info
-A LnD -p udp -m limit --limit 1/s -j LOG --log-prefix "[UDP drop] " --log-level=info
-A LnD -p icmp -m limit --limit 1/s -j LOG --log-prefix "[ICMP drop] " --log-level=info
-A LnD -f -m limit --limit 1/s -j LOG --log-prefix "[FRAG drop] " --log-level=info
-A LnD -j DROP

#
# This custom chain logs, then REJECTs packets.
#
-N LnR

-A LnR -p tcp -m limit --limit 1/s -j LOG --log-prefix "[TCP reject] " --log-level=info
-A LnR -p udp -m limit --limit 1/s -j LOG --log-prefix "[UDP reject] " --log-level=info
-A LnR -p icmp -m limit --limit 1/s -j LOG --log-prefix "[ICMP reject] " --log-level=info
-A LnR -f -m limit --limit 1/s -j LOG --log-prefix "[FRAG reject] " --log-level=info
-A LnR -j REJECT

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

# End iptables.2.h

