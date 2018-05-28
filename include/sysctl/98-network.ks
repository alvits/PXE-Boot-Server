##############################################################################
# Network
##############################################################################
# bug 5582032
net.ipv4.icmp_echo_ignore_broadcasts = 1

# bug 5582039
net.ipv4.tcp_syncookies = 1
# If you see SYN flood warnings in your logs, but investigation shows that
# they occur because of overload with legal connections, you should tune
# another parameters until this warning disappear.
# See: tcp_max_syn_backlog, tcp_synack_retries, tcp_abort_on_overflow.

# bug 8422792
# Uncomment the following lines if there the system has bridges
#net.bridge.bridge-nf-call-arptables = 0
#net.bridge.bridge-nf-call-ip6tables = 0
#net.bridge.bridge-nf-call-iptables  = 0

# Required by almost all DB installations, it doesnt affect other things.
net.ipv4.ip_local_port_range = 9000 65535

# Network perfomance
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.tcp_keepalive_time = 1000
sunrpc.udp_slot_table_entries = 128
sunrpc.tcp_slot_table_entries = 128
sunrpc.tcp_max_slot_table_entries = 128

# Network security
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0

net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.route.flush = 1
