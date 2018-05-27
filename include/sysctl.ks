cat<<-EOF > /etc/sysctl.d/99-misc.conf
##############################################################################
# File system
##############################################################################
fs.file-max = 6815744
fs.aio-max-nr = 3145728
fs.suid_dumpable = 0

##############################################################################
# Virtual memory
##############################################################################
# Use swap only if really needed
vm.swappiness = 10

# Tune OOM killer
vm.min_free_kbytes = 51200

# Hugepages/bigpages values are strongly tied to SGA size.
# If SGA size changes, then these values need to be adjusted accordingly.
#vm.nr_hugepages = ((1+3%)*SGA_SIZE)/2MB

# Miscellaneous
kernel.sysrq = 1
kernel.core_uses_pid = 1
EOF

cat<<-EOF > /etc/sysctl.d/99-network.conf
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
EOF

cat<<-EOF > /etc/sysctl.d/99-msgbuff.conf
##############################################################################
# Kernel
##############################################################################
# Messages
kernel.msgmni = 2878
kernel.msgmax = 65536
kernel.msgmnb = 65536
EOF

cat<<-EOF > /etc/sysctl.d/99-sharedmem.conf
# Semaphores
kernel.sem = 250 32000 100 142

# Shared memory
kernel.shmmni = 4096
kernel.shmall = 4294967296
kernel.shmmax = 4398046511104
EOF
