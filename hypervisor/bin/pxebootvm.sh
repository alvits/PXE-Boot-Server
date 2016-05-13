#!/bin/bash

. /usr/local/etc/functions

if [ -z "${OSVERSION}" ]; then
	echo OS Version is required.
	usage
fi

ks="ks=http://10.132.64.40/os/kickstart/${HOST}/ks.cfg"
disk="['phy:/dev/vg_tmpsc1/${HOST}-os,xvda,w']"
repo="method=http://10.132.64.40/os/${OSVERSION}/x86_64/"
bootloader_args="['--location','http://10.132.64.40/os/${OSVERSION}/x86_64','--kernel','images/pxeboot/vmlinuz','--ramdisk','images/pxeboot/initrd.img']"

if [ ${OSVERSION%%/*} == "ovs" ]; then
	dom0_mem=max:128G
	dom0_max_vcpus=20
else
	version=${OSVERSION##*/}
	if [ ${version%.*} -gt 6 ]; then
		ks="inst.ks=http://10.132.64.40/os/kickstart/${HOST}/ks.cfg"
		repo="inst.stage2=http://10.132.64.40/os/${OSVERSION}/x86_64/ inst.repo=http://10.132.64.40/os/${OSVERSION}/x86_64/"
	fi
fi

xl create /xen/VMs/PXE-Boot-Install.cfg "name='${HOST}'; extra='nomodeset text ramdisk_size=8192${dom0_mem:+ dom0_mem}${dom0_mem:+=}${dom0_mem}${dom0_max_vcpus:+ dom0_max_vcpus}${dom0_max_vcpus:+=}${dom0_max_vcpus} $ks $repo ksdevice=eth0 ip=${IPADDR} netmask=${NETMASK} gateway=${GATEWAY} dns=10.209.76.198 hostname=${HOST} sshd=1 elevator=noop'; disk=$disk; vcpus=2; memory=4096; bootloader_args=$bootloader_args"
