if [ ${ARCH} == x86_64 ]; then
	SHMMAX=68719476736
	SHMALL=4294967296
else
	SHMMAX=4294967295
	SHMALL=268435456
fi
if [ -d /etc/sysctl.d ]; then
	sysctlconf=/etc/sysctl.d/98-custom.conf
else
	sysctlconf=/etc/sysctl.conf
fi
if grep -q net.ipv4.tcp_syncookies ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(net.ipv4.tcp_syncookies\).*$/\1 = 1/g' ${sysctlconf%/*}*sysctl.conf
else
	echo -e "\n# Controls the use of TCP syncookies" >> ${sysctlconf}
	echo net.ipv4.tcp_syncookies = 1 >> ${sysctlconf}
fi
if grep -q kernel.msgmnb ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(kernel.msgmnb\).*$/\1 = 65536/g' ${sysctlconf%/*}*sysctl.conf
else
	echo -e "\n# Controls the maximum size of a message, in bytes" >> ${sysctlconf}
	echo kernel.msgmnb = 65536 >> ${sysctlconf}
fi
if grep -q kernel.msgmax ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(kernel.msgmax\).*$/\1 = 65536/g' ${sysctlconf%/*}*sysctl.conf
else
	echo -e "\n# Controls the default maxmimum size of a mesage queue" >> ${sysctlconf}
	echo kernel.msgmax = 65536 >> ${sysctlconf}
fi
if grep -q kernel.shmmax ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(kernel.shmmax\).*$/\1 = '${SHMMAX}'/g' ${sysctlconf%/*}*sysctl.conf
else
	echo -e "\n# Controls the maximum shared segment size, in bytes" >> ${sysctlconf}
	echo kernel.shmmax = ${SHMMAX} >> ${sysctlconf}
fi
if grep -q kernel.shmall ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(kernel.shmall\).*$/\1 = '${SHMALL}'/g' ${sysctlconf%/*}*sysctl.conf
else
	echo -e "\n# Controls the maximum number of shared memory segments, in pages" >> ${sysctlconf}
	echo kernel.shmall = ${SHMALL} >> ${sysctlconf}
fi
if grep -q net.ipv4.conf.default.rp_filter ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(net.ipv4.conf.default.rp_filter\).*$/\1 = 0/g' ${sysctlconf%/*}*sysctl.conf
else
	echo net.ipv4.conf.default.rp_filter = 0 >> ${sysctlconf}
fi
if grep -q net.ipv4.conf.all.rp_filter ${sysctlconf%/*}*sysctl.conf; then
	sed -i 's/^[#[:blank:]]*\(net.ipv4.conf.all.rp_filter\).*$/\1 = 0/g' ${sysctlconf%/*}*sysctl.conf
else
	echo net.ipv4.conf.all.rp_filter = 0 >> ${sysctlconf}
fi
cat<<-SYSCTLEOF >> ${sysctlconf}
##
##
# For server-side
net.ipv4.tcp_tw_recycle = 1
# For client-side
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.optmem_max = 40960
##
net.core.rmem_max = 16777216
net.core.rmem_default = 16777216
net.core.wmem_max = 16777216
net.core.wmem_default = 16777216
net.core.netdev_max_backlog = 10240
##
SYSCTLEOF
