%include ../../PXE-Boot-Server/PXE-Boot-Server.ks

%post
cd /usr/local/Downloads
find kickstart -type f -o -type l | xargs -n 1 -I {} ln ../Downloads/{} /usr/local/bin
cat<<-DHCPDPOOL>/usr/local/sbin/dhcpdpool
#!/bin/sh
eval \$@
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
eval \$(\${IPCALC} -n -m -b \${INETADDR})
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

systemctl disable hwclock-save.service
rm -f /etc/systemd/system/syslog.service
rm -f /lib/udev/rules.d/80-net-name-slot.rules
cat<<-DHCPDPOOL > /etc/systemd/system/multi-user.target.wants/dhcpdpool.service
[Unit]
Description=Change DHCP pool with the current network
After=syslog.target network-online.target
Before=dhcpd.service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/kickstart
ExecStart=/usr/local/sbin/dhcpdpool DEV=\$DEV DHCPDCONF=\$DHCPDCONF NEXTSERVER=\$NEXTSERVER
DHCPDPOOL

systemctl enable tftp.socket

mkdir /etc/systemd/system/getty@tty{1..5}.service.d
cat<<-AUTOLOGIN > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
AUTOLOGIN
ln /etc/systemd/system/getty@tty1.service.d/autologin.conf /etc/systemd/system/getty@tty2.service.d/autologin.conf
ln /etc/systemd/system/getty@tty1.service.d/autologin.conf /etc/systemd/system/getty@tty3.service.d/autologin.conf
ln /etc/systemd/system/getty@tty1.service.d/autologin.conf /etc/systemd/system/getty@tty4.service.d/autologin.conf
ln /etc/systemd/system/getty@tty1.service.d/autologin.conf /etc/systemd/system/getty@tty5.service.d/autologin.conf

cat<<-SYSTEMD >> /etc/systemd/system/multi-user.target.wants/var-lib-tftpboot-os-oel-6.6-x86_64.mount
[Unit]
Description=OEL 6.6 x86_64 Install Directory
Before=local-fs.target
ConditionPathExists=/dev/sr1

[Mount]
What=/dev/sr1
Where=/var/lib/tftpboot/os/oel/6.6/x86_64
Type=iso9660
Options=ro
SYSTEMD
cat<<-SYSTEMD >> /etc/systemd/system/multi-user.target.wants/var-lib-tftpboot-os-oel-5.10-x86_64.mount
[Unit]
Description=OEL 5.10 x86_64 Install Directory
Before=local-fs.target
ConditionPathExists=/dev/sr2

[Mount]
What=/dev/sr2
Where=/var/lib/tftpboot/os/oel/5.10/x86_64
Type=iso9660
Options=ro
SYSTEMD
cat<<-SYSTEMD >> /etc/systemd/system/multi-user.target.wants/var-lib-tftpboot-os-ovs-3.3-x86_64.mount
[Unit]
Description=OVS 3.3 x86_64 Install Directory
Before=local-fs.target
ConditionPathExists=/dev/sr3

[Mount]
What=/dev/sr3
Where=/var/lib/tftpboot/os/ovs/3.3/x86_64
Type=iso9660
Options=ro
SYSTEMD
cat<<-SYSTEMD >> /etc/systemd/system/multi-user.target.wants/usr-local-bin.mount
[Unit]
Description=Writable /usr/local/bin
Before=local-fs.target
ConditionPathExists=/dev/xvde

[Mount]
What=/dev/xvde
Where=/usr/local/bin
Type=ext4
SYSTEMD
%end
