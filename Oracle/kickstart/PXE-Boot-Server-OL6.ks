%include ../../PXE-Boot-Server/PXE-Boot-Server.ks

%packages --excludedocs --nobase --ignoremissing
device-mapper
%end

%post
cd /usr/local/Downloads
find kickstart -type f -o -type l | xargs -n 1 -I {} ln ../Downloads/{} /usr/local/bin
cat<<-DHCPDPOOL>/usr/local/sbin/dhcpdpool
#!/bin/bash
. /etc/sysconfig/kickstart
DEV=\${DEV:-eth0}
GREP=/bin/grep
IPCALC=/bin/ipcalc
IP=/sbin/ip
AWK=/usr/bin/awk
ECHO=/bin/echo
CAT=/bin/cat
SED=/usr/bin/sed
RPM=/bin/rpm
DHCPDCONF=\${DHCPDCONF:-\$(\${RPM} -ql dhcp| \${GREP} -E 'dhcpd.conf$')}
INETADDR=\$(\${IP} -o -f inet addr show dev \${DEV}|\${AWK} '{print \$4}')
NEXTSERVER=\${NEXTSERVER:-\${INETADDR%%/*}}
. <(\${IPCALC} -n -m -b \${INETADDR})
START=\$(\${ECHO} \${NETWORK}|\${AWK} -F. '{printf("%d.%d.%d.%d",\$1,\$2,\$3,\$4+2)}')
END=\$(\${ECHO} \${BROADCAST}|\${AWK} -F. '{printf("%d.%d.%d.%d",\$1,\$2,\$3,\$4-2)}')
ROUTERS=\$(\${IP} route list scope global|\${AWK} '{print \$3}')
if (\${GREP} -q ^subnet \${DHCPDCONF}); then
${TAB}	\${SED} -i 's/^\(\s*next-server\).*$/\1 '\${NEXTSERVER}';/g' \${DHCPDCONF}
${TAB}	\${SED} -i 's/^\(\s*option subnet-mask\).*$/\1 '\${NETMASK}';/g' \${DHCPDCONF}
${TAB}	\${SED} -i 's/^\(\s*option routers\).*$/\1 '\${ROUTERS}';/g' \${DHCPDCONF}
${TAB}	\${SED} -i 's/^\(\s*range\).*$/\1 '\${START}' '\${END}';/g' \${DHCPDCONF}
${TAB}	\${SED} -i 's/^\(\s*subnet\).*\(netmask\).*$/\1 '\${NETWORK}' \2 '\${NETMASK}' {/g' \${DHCPDCONF}
else
${TAB}	\${CAT}<<-EOF>>\${DHCPDCONF}

${TAB}	option space PXE;
${TAB}	option PXE.mtftp-ip    code 1 = ip-address;
${TAB}	option PXE.mtftp-cport code 2 = unsigned integer 16;
${TAB}	option PXE.mtftp-sport code 3 = unsigned integer 16;
${TAB}	option PXE.mtftp-tmout code 4 = unsigned integer 8;
${TAB}	option PXE.mtftp-delay code 5 = unsigned integer 8;
${TAB}	option arch code 93 = unsigned integer 16;
${TAB}	ddns-update-style interim;
${TAB}	default-lease-time 3600;
${TAB}	max-lease-time 4800;
${TAB}	option time-offset -8;
${TAB}	option domain-name-servers 10.209.76.198, 10.209.76.197, 192.135.82.132;
${TAB}	option domain-name "us.oracle.com";
${TAB}	class "pxeclients" {
${TAB}	\${TAB}	match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
${TAB}	\${TAB}	next-server \${NEXTSERVER};
${TAB}	\${TAB}	if option arch = 00:02 {
${TAB}	\${TAB}		filename "elilo.efi";
${TAB}	\${TAB}	} else if option arch = 00:06 {
${TAB}	\${TAB}		filename "bootia32.efi";
${TAB}	\${TAB}	} else if option arch = 00:07 {
${TAB}	\${TAB}		filename "bootx64.efi";
${TAB}	\${TAB}	} else {
${TAB}	\${TAB}		filename "pxelinux.0";
${TAB}	\${TAB}	}
${TAB}	}
${TAB}	subnet \${NETWORK} netmask \${NETMASK} {
${TAB}	\${TAB}	range \${START} \${END};
${TAB}	\${TAB}	option routers \${ROUTERS};
${TAB}	\${TAB}	option subnet-mask \${NETMASK};
${TAB}	}
${TAB}	group {
%include /tmp/group.ks
${TAB}	}
${TAB}	EOF
fi
DHCPDPOOL
chmod +x /usr/local/sbin/dhcpdpool

sed -i 's|^\(exec /sbin/mingetty\) \(\$TTY\)$|\1 --autologin root \2|g' /etc/init/tty.conf

cat<<FSTAB >> /etc/fstab
/dev/sr1	/var/lib/tftpboot/os/oel/7.2/x86_64	iso9660	ro,noauto	0 0
/dev/sr2	/var/lib/tftpboot/os/oel/6.7/x86_64	iso9660	ro,noauto	0 0
/dev/sr3	/var/lib/tftpboot/os/ovs/3.4/x86_64	iso9660	ro,noauto	0 0
/dev/xvde	/usr/local/bin				ext4	defaults,noauto	1 2
FSTAB
%end
