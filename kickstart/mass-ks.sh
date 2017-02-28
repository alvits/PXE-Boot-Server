#!/bin/bash
# ensure script is ran not sourced
return > /dev/null 2>&1
zonecount=0
params="$@"
while read line; do
	if [ ${line:0:1} != "#" ]; then
		if [ "$line" != "${line/=/}" ]; then
			export ${line%%=*}="${line#*=}"
			if [ -n "${HOSTSFILE}" ]; then
				HOSTSFILE=${HOSTSFILE##*/}
				> /usr/local/Downloads/include/hosts/${HOSTSFILE##*/}
			fi
			if [ -n "${SWIFTCONF}" ]; then
				cat<<-EOF > /usr/local/Downloads/include/swift/${SWIFTCONF##*/}
					[swift-hash]
					# random unique string that can never change (DO NOT LOSE)
					swift_hash_path_prefix = $(tr -dc [:alnum:] < /dev/urandom | head -c 15)
					swift_hash_path_suffix = $(tr -dc [:alnum:] < /dev/urandom | head -c 15)
				EOF
			fi
			if [ -n "${RINGBUILDER}" ]; then
				> /usr/local/Downloads/include/swift/${RINGBUILDER##*/}
			fi
		else
			set $(tr ',' ' ' <<< $line)
			host=$1
			shift
			ipaddr=$1
			shift
			disk=$1
			shift
			if [[ "${1}" =~ ([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2} ]]; then
				mac=$1
				shift
			fi
			if [ -n "${HOSTSFILE}" ]; then
				echo -e "$ipaddr\t$host" >> /usr/local/Downloads/include/hosts/${HOSTSFILE##*/}
				privIP="${@}"
				privIP=${privIP//* -p }
				echo -e "${privIP//\/*}\t${host}-internal" >> /usr/local/Downloads/include/hosts/${HOSTSFILE##*/}
			fi
			config-kickstart.sh -n $host -g ${GATEWAY%%/*} -i $ipaddr -m /${GATEWAY##*/} -d ${disk:-sda} ${mac:+"-e"} ${mac} -q -b $params $@ ${COMMAND:+-r} "${COMMAND}"
			if [ -n "${RINGBUILDER##*/}" ]; then
				(( zonecount++ ))
				cat<<-EOF >> /usr/local/Downloads/include/swift/${RINGBUILDER##*/}
					swift-ring-builder account.builder add z${zonecount}-${ipaddr}:6002R${privIP//\/*}:6005/sdb 100
					swift-ring-builder container.builder add z${zonecount}-${ipaddr}:6001R${privIP//\/*}:6004/sdb 100
					swift-ring-builder object.builder add z${zonecount}-${ipaddr}:6000R${privIP//\/*}:6003/sdb 100
				EOF
			fi
		fi
	fi
done
if [ -n "$NOVA_KEY" ]; then
	rm -f /usr/local/Downloads/include/ssh-keys/${NOVA_KEY##*/} /usr/local/Downloads/include/ssh-keys/${NOVA_KEY##*/}.pub
	ssh-keygen -b 2048 -f /usr/local/Downloads/include/ssh-keys/${NOVA_KEY##*/} -N '' -n nova
	chown apache:apache /usr/local/Downloads/include/ssh-keys/${NOVA_KEY##*/} /usr/local/Downloads/include/ssh-keys/${NOVA_KEY##*/}.pub
fi
