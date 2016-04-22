#!/bin/bash
# ensure script is ran not sourced
return > /dev/null 2>&1
# parameters:
# -d <device> storage device (default: sda)
# -v <distro/ver> OS version (default: oel/6.6)
# -a <arch> architecture (default: x86_64)
# -s <source> (default: http://${INETADDR}/os)
# -I <iface> boot interface (default: eth0)
# -S <swapsize>
# -h help
# -e ether (mac) address
# -i ip
# -n hostname
# -g gateway
# -q quiet. don't ask for private net
# -m netmask
# -b bonded
# -x xen (mutually exclusive with openstack)
# -k kernel devel
# -c redhat cluster suite
# -u unbound interface
# -o openstack install (mutually exclusive with xen)
# -p ip/prefix private ip address with prefix
# -P root password

usage() {
${CAT}<<-EOF
	usage: ${0##*/} [-d <target disk>] [-v <distro/ver>] [-a <arch>] [-s <install source>] [-I <ks boot interface>] [-S <swapsize in MB>] [-e mac] [-i <ip address>] [ -n <hostname>] [-g <gateway>] [-m {<netmask>|<prefix>}] [-p <private IP/prefix> ] [{-b|-u}] [{-x|-o}] [-q] [-h] [-P <root password>]
	where:	-d target disk - is host's internal storage device. (default sda)
	 	-v distro/ver - is OS distribution and version (default oel/6.6)
	 	-a arch - is hardware or virtual architecture (default x86_64)
	 	-s install source - is the url of the repository where installation media is located
	 	-h - prints this message and exit
	 	-e mac address - is the ether address of the bare metal or virtual host
	 	-i ip address - is the IP assigned to host
	 	-n hostname - is the assigned hostname
	 	-g gateway - is the default route of the host
	 	-q - quiet. don't ask for private network
	 	-m netmask - is the assigned netmask
	 	-b - the network interface is bonded. mutually exclusive with -u
	 	-x - install xen. mutually exclusive with -o
	 	-k - install kernel-uek-devel package
	 	-u - unbound interface. mutually exclusive with -b
	 	-o - install and configure openstack node. mutually exclusive with -x
	 	-p ip/prefix - private ip address in prefix notation
	 	-P root password - root password. If password is in cleartext, script will encrypt
EOF
exit
}

. ${0%/*}/kickstart-functions
. ${0%/*}/OpenStack

DISK=sda
OSVERSION=oel/6.6
ARCH=x86_64
INTFACE=eth0

while getopts ":d:v:a:s:I:S:e:i:n:g:xqm:p:P:kbuho" OPT
do
	case ${OPT} in
	d)
		DISK=${OPTARG}
		;;
	v)
		if [ ${OPTARG##*/} == ${OPTARG} ]; then
			OSVERSION=oel/${OPTARG}
		else
			OSVERSION=${OPTARG}
		fi
		;;
	a)
		ARCH=${OPTARG}
		;;
	s)
		SOURCE=${OPTARG}
		;;
	I)
		INTFACE=${OPTARG}
		;;
	S)
		SWAP=${OPTARG}
		;;
	e)
		MAC=${OPTARG//:/-}
		MAC=${MAC,,}
		;;
	i)
		IPADDR=${OPTARG}
		;;
	n)
		HOST=${OPTARG}
		;;
	g)
		GATEWAY=${OPTARG}
		;;
	q)
		QUIET=1
		;;
	m)
		NETMASK=${OPTARG##/}
		SLASH=${OPTARG:0:1}
		if [ "$SLASH}" == "${NETMASK:0:1}" ]; then
			SLASH=' '
		fi
		;;
	b)
		if [ ${OPSTACK:-0} -eq 1 ]; then
			BONDED=1
		else
			BONDED=0
		fi
		;;
	u)
		BONDED=1
		;;
	x)
		XEN=1
		unset OPSTACK
		;;
	k)
		KDEV=1
		;;
	o)
		OPSTACK=1
		unset XEN
		BONDED=1
		;;
	p)
		privateIP=${OPTARG%%/*}
		privatePREFIX=${OPTARG##*/}
		[ -n "$privateIP" ] && [ -n "privatePREFIX" ] || usage
		;;
	P)
		if [ "${OPTARG:0:3}" = '$1$' ]; then
			ROOTPW=${OPTARG}
		else
			ROOTPW=$(openssl passwd -1 "$OPTARG")
		fi
		;;
	*)
		usage
		;;
	esac
done

OSVER=${OSVERSION%.*}
if [ ${OSVER##*/} -gt 5 ]; then
	Cluster=${SOURCE}/${OSVER}Server/${ARCH}/HighAvailability
else
	Cluster=${SOURCE}/${OSVER}Server/${ARCH}/Cluster
fi

if (ping -q -c 2 uln-internal.oracle.com > /dev/null 2>&1); then
	if [ ${OPSTACK:-0} -eq 1 ]; then
		latestkernelUEKR3="ol6_UEKR3=http://$(gethostip -d uln-internal.oracle.com)/uln/OracleLinux/OL6/UEKR3/latest/${ARCH}/"
		latestRepositories="ol6_latest=http://$(gethostip -d uln-internal.oracle.com)/uln/OracleLinux/OL6/latest/${ARCH}/ ASV_base=${SOURCE}/asv/6/base/ $latestkernelUEKR3"
	else
		case ${OSVER##*/} in
			7)
				UEK="UEKR3"
				;;
			6)
				UEK="UEKR3/latest"
				;;
			*)
				UEK="UEK/latest"
				;;
		esac
		latestRepositories="ol${OSVER#*/}_${UEK}=http://$(gethostip -d uln-internal.oracle.com)/uln/OracleLinux/OL${OSVER#*/}/${UEK}/${ARCH}/ ol${OSVER#*/}_latest=http://$(gethostip -d uln-internal.oracle.com)/uln/OracleLinux/OL${OSVER#*/}/latest/${ARCH}/ ASV_latest=${SOURCE}/asv/${OSVER#*/}/latest/"
	fi
fi

if [ "${DISK:0:2}" != "sd" ]; then
	unset XEN
	unset OPSTACK
fi

if [ ${OPSTACK:-0} -eq 1 ]; then
	Repositories="ol7_openstack20=http://$(gethostip -d uln-internal.oracle.com)/uln/OracleLinux/OL${OSVER#*/}/openstack20/${ARCH}/ $latestRepositories"
elif [ ${OSVERSION%%/*} == "ovs" ]; then
	unset Repositories
else
	UEKdir=$(find ${TFTPBOOTDIR%/*}/os/${OSVERSION}/${ARCH} -maxdepth 1 -name UEK\* -type d 2>/dev/null)
	[ -n "${UEKdir}" ] && UEK="UEK=${SOURCE}/${OSVERSION}/${ARCH}/${UEKdir##*/}/" || UEK=""
	ASV_base="ASV_base=${SOURCE}/asv/${OSVER#*/}/base/"
	Repositories="$latestRepositories $ASV_base ${UEK}"
fi

unset latestRepositories

initialize ${DISK} "${SWAP}" ${SOURCE} ${OSVERSION} ${ARCH} '' '' "${ROOTPW:-\$1\$/D0WZ/Qx\$hiV59A2D7YIq/Th3OqZM/1}" '' '' "${Repositories}" > ${KS}

${PRINTF} "This script will generate a kickstart configuration file named ks.cfg\n\n"

while [ -z "$HOST" ]; do
	${PRINTF} "What is the target hostname? "
	read HOST
done

if [ -z "$BONDED" ]; then
	$(yesno "Is this machine using bonded interfaces?")
	BONDED=$?
fi

while [ ${STATUS} -ne 0 ]; do
	if [ -z "${IPADDR}${SLASH}${NETMASK}" ]; then
		SLASH=" "
		set $(get_IP "What is the public IP Address?" "Invalid IP Address")
		IPADDR=${1}
		NETMASK=${2}
	fi
	if [ -z "${NETMASK}" ]; then
		NETMASK=${IPADDR##*/}
		IPADDR=${IPADDR%%/*}
		[ "${IPADDR}" != "${NETMASK}" ] || NETMASK=""
		if [ -n "${NETMASK}" ]; then
			SLASH=/
		else
			set $(get_IP "What is the netmask?" "Invalid netmask")
			NETMASK=${1}
		fi
	fi
	${IPCALC} -c -s -m -n -b ${IPADDR}${SLASH}${NETMASK}
	STATUS=$?
done

if [ -z "$GATEWAY" ]; then
	set $(get_IP "What is the default gateway?" "Invalid gateway")
	GATEWAY=${1%%/*}
fi

network ${HOST} ${GATEWAY} >> ${KS}

if [ ${XEN:-0} -eq 1 ]; then
	ifcfg_interface xenbr0 ${IPADDR} "${SLASH}" ${NETMASK} Bridge >> ${KS}
	if [ ${BONDED} -eq 0 ]; then
		bonding 0 >> ${KS}
		bridgeAddInterface bond0 xenbr0 >> ${KS}
		ifenslave_interface ${INTFACE:-eth0} bond0 >> ${KS}
		ifenslave_interface ${INTFACE:0:${#INTFACE}-1}$((${INTFACE:${#INTFACE}-1}+1)) bond0 >> ${KS}
	else
		bridgeAddInterface ${INTFACE:-eth0} xenbr0 >> ${KS}
	fi
elif [ ${OPSTACK:-0} -eq 1 ]; then
	ifcfg_interface ${INTFACE:-eth0} ${IPADDR} "${SLASH}" ${NETMASK} >> ${KS}
elif [ ${OSVERSION%%/*} == "ovs" ]; then
	ifcfg_interface br0 ${IPADDR} "${SLASH}" ${NETMASK} Bridge >> ${KS}
	if [ ${BONDED} -eq 0 ]; then
		bonding 0 >> ${KS}
		bridgeAddInterface bond0 br0 >> ${KS}
		ifenslave_interface ${INTFACE:-eth0} bond0 >> ${KS}
		ifenslave_interface ${INTFACE:0:${#INTFACE}-1}$((${INTFACE:${#INTFACE}-1}+1)) bond0 >> ${KS}
		ifenslave_interface ${INTFACE:0:${#INTFACE}-1}$((${INTFACE:${#INTFACE}-1}+2)) bond0 >> ${KS}
		ifenslave_interface ${INTFACE:0:${#INTFACE}-1}$((${INTFACE:${#INTFACE}-1}+3)) bond0 >> ${KS}
	else
		bridgeAddInterface ${INTFACE:-eth0} br0 >> ${KS}
	fi
else
	if [ ${BONDED} -eq 0 ]; then
		bonding 0 >> ${KS}
		ifcfg_interface bond0 ${IPADDR} "${SLASH}" ${NETMASK} >> ${KS}
		ifenslave_interface ${INTFACE:-eth0} bond0 >> ${KS}
		ifenslave_interface ${INTFACE:0:${#INTFACE}-1}$((${INTFACE:${#INTFACE}-1}+1)) bond0 >> ${KS}
	else
		ifcfg_interface ${INTFACE:-eth0} ${IPADDR} "${SLASH}" ${NETMASK} >> ${KS}
	fi
fi

pxeMASK=$(${IPCALC} -s -m ${IPADDR}${SLASH}${NETMASK}|${SED} 's/NETMASK=//g')
if [ ${OSVER##*/} -gt 6 ]; then
	MODE="nomodeset text"
fi
if [ -n "$MAC" ]; then
	${ECHO} "default ${HOST}" > ${TFTPBOOTDIR}/01-${MAC}
	pxeBoot ${HOST} ${OSVERSION} ${ARCH} ${SOURCE}/kickstart/${HOST}/ks.cfg ${SOURCE}/${OSVERSION}/${ARCH}/ ${INTFACE:-eth0} "${IPADDR}" "${pxeMASK}" "${GATEWAY}" "${MODE}" 10.209.76.198 >> ${TFTPBOOTDIR}/01-${MAC}
	#efiBoot ${HOST} ${OSVERSION} ${ARCH} ${SOURCE}/kickstart/${HOST}/ks.cfg ${SOURCE}/${OSVERSION}/${ARCH}/ ${INTFACE:-eth0} "${IPADDR}" "${pxeMASK}" "${GATEWAY}" "${MODE}" 10.209.76.198 >> ${TFTPBOOTDIR}/../01-${MAC}
fi
pxeBootCleanup ${HOST} > /dev/null 2>&1
pxeBoot ${HOST} ${OSVERSION} ${ARCH} ${SOURCE}/kickstart/${HOST}/ks.cfg ${SOURCE}/${OSVERSION}/${ARCH}/ ${INTFACE:-eth0} "${IPADDR}" "${pxeMASK}" "${GATEWAY}" "${MODE}" 10.209.76.198 >> ${TFTPBOOTDIR}/default

if [ -n "$privateIP" -a -n "$privatePREFIX" -o -z "$QUIET" ]; then
	if [ -z "$QUIET" ]; then
		if yesno "Does this machine have private network?"; then
			STATUS=1
		else
			STATUS=0
		fi
	else
		STATUS=1
	fi
	while [ ${STATUS} -ne 0 ]; do
		if [ -z "$QUIET" ]; then
			SLASH=" "
			set $(get_IP "What is the private IP Address?" "Invalid IP Address")
			IPADDR=${1}
			NETMASK=${2}
			if [ -z "${NETMASK}" ]; then
				NETMASK=${IPADDR##*/}
				IPADDR=${IPADDR%%/*}
				[ "${IPADDR}" != "${NETMASK}" ] || NETMASK=""
				if [ -n "${NETMASK}" ]; then
					SLASH=/
				else
					set $(get_IP "What is the netmask?" "Invalid netmask")
					NETMASK=${1}
				fi
			fi
		else
			IPADDR=$privateIP
			NETMASK=$privatePREFIX
			SLASH="/"
		fi
		${IPCALC} -c -s -m -n -b ${IPADDR}${SLASH}${NETMASK}
		STATUS=$?
	done

	if [ ${BONDED} -eq 0 ]; then
		bonding 1 >> ${KS}
		ifcfg_interface bond1 ${IPADDR} "${SLASH}" ${NETMASK} >> ${KS}
		ifenslave_interface eth1 bond1 >> ${KS}
		ifenslave_interface eth3 bond1 >> ${KS}
	else
		ifcfg_interface ${privateETH:-eth2} ${IPADDR} "${SLASH}" ${NETMASK} >> ${KS}
	fi
fi

updateSysctl >> ${KS}
updateNtp 10.132.10.137 10.132.9.97 ${GATEWAY} >> ${KS}
updateResolv us.oracle.com us.oracle.com 10.209.76.198 10.209.76.197 192.135.82.132 >> ${KS}
if [ ${OSVERSION%%/*} != "ovs" ]; then
	limits >> ${KS}
	#createUser hadooproot 5500 users 100 >> ${KS}
	createUser oracle 1000 dba 1000 >> ${KS}
	#sudoer hadooproot >> ${KS}
	sudoer oracle >> ${KS}
	addAUTHkeys ${SSHKEYS} oracle >> ${KS}
	#addAUTHkeys ${SSHKEYS} hadooproot >> ${KS}
	addSSSD >> ${KS}
	addXENkparams >> ${KS}
fi
addAUTHkeys ${SSHKEYS} root >> ${KS}
if [ ${OPSTACK:-0} -eq 1 ]; then
	customizeOpenStack >> ${KS}
fi
autoextendTHINpool >> ${KS}
${MKDIR} ${KICKSTART}/${HOST} 2> /dev/null
echo "%end" >> ${KS}
${MV} --backup=numbered ${KS} ${KICKSTART}/${HOST}/ks.cfg
${PRINTF} "\nYour new kickstart configuration is stored in ${KICKSTART}/${HOST} subdirectory.\n"
