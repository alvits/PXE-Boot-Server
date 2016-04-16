#!/bin/bash

if [ $# -ne 5 ]; then
	cat<<-EOF
		Usage:	${0##*/} hostname osversion hostip netmask gateway
		where:	hostname is the hostname to image
		 	osversion is one of oel/6.6 ovs/3.3 oel/7.1
		 	hostip is the ip address being assigned to the host
		 	netmask is the netmask being assigned to host
		 	gateway is the default router of the host
	EOF
	exit 1
fi

ks="ks=http://10.132.64.40/os/kickstart/$1/ks.cfg"
disk="['phy:/dev/vg_tmpsc1/$1-os,xvda,w']"
repo="method=http://10.132.64.40/os/$2/x86_64/"
bootloader_args="['--location','http://10.132.64.40/os/$2/x86_64','--kernel','images/pxeboot/vmlinuz','--ramdisk','images/pxeboot/initrd.img']"

if [ ${2%%/*} == "ovs" ]; then
	dom0_mem=max:128G
	dom0_max_vcpus=20
else
	version=${2##*/}
	if [ ${version%.*} -gt 6 ]; then
		ks="inst.ks=http://10.132.64.40/os/kickstart/$1/ks.cfg"
		repo="inst.stage2=http://10.132.64.40/os/$2/x86_64/ inst.repo=http://10.132.64.40/os/$2/x86_64/"
	fi
fi

xl create /xen/VMs/PXE-Boot-Install.cfg "name='$1'; extra='nomodeset text ramdisk_size=8192${dom0_mem:+ dom0_mem}${dom0_mem:+=}${dom0_mem}${dom0_max_vcpus:+ dom0_max_vcpus}${dom0_max_vcpus:+=}${dom0_max_vcpus} $ks $repo ksdevice=eth0 ip=$3 netmask=$4 gateway=$5 dns=10.209.76.198 hostname=$1 sshd=1 elevator=noop'; disk=$disk; vcpus=2; memory=4096; bootloader_args=$bootloader_args"
