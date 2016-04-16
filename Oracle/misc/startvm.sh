#!/bin/bash
if [ $# -ne 4 ]; then
	cat<<-EOF
		Usage:	${0##*/} hostname hostip netmask gateway
		where:	hostname is the hostname of the VM to start
		 	hostip is the ip address being assigned to the host
		 	netmask is the netmask being assigned to host
		 	gateway is the default router of the host
	EOF
	exit 1
fi
eval $(ipcalc -b $2 $3)
xl create /xen/VMs/VM.cfg "name='${1}'; extra='ip=${2}:${BROADCAST}:${4}:${3}:${1}:eth0:none elevator=noop'; disk=['phy:/dev/vg_tmpsc1/${1}-os,xvda,w']; vcpus=2; memory=4096"
