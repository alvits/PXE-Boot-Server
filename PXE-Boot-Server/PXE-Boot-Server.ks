%include /tmp/repo.ks

timezone --utc America/Los_Angeles
%include /tmp/network.ks

lang en_US.UTF-8
keyboard us
auth --useshadow --passalgo=sha512
firewall --disabled
selinux --disabled
bootloader --timeout=5 --append="systemd.unit=multi-user.target selinux=0"
part / --size 1024 --fstype xfs
services --enabled=network,httpd,dhcpd

%packages --excludedocs --nobase --ignoremissing
# no need for kudzu if the hardware doesn't change
-prelink
-setserial
-ed

# Remove the authconfig pieces
-authconfig
-wireless-tools

# Remove the kbd bits
-kbd
-usermode

# these are all kind of overkill but get pulled in by mkinitrd ordering
-kpartx
-dmraid
-mdadm
-lvm2
tar

# selinux toolchain of policycoreutils, libsemanage, ustr
-policycoreutils
-checkpolicy
-selinux-policy*
-libselinux-python
-libselinux

# Things it would be nice to loose
-fedora-logos
-fedora-release-notes
-oracle-logos
-oraclelinux-release-notes

#fedora-release
bash
kernel
grubby
passwd
rootfiles
-patch
tftp-server
dhcp
dhclient
syslinux
httpd
mkisofs
curl
createrepo
vim-minimal
# needed for root fs
openssh-clients
squashfs-tools
# allow cd verification
isomd5sum
# Needed to disable selinux
lokkit
# Needed to disable firewall
firewalld
# Needed for EFI systems
shim
grub
grub2-efi
# ifconfig
net-tools
-acl
-anaconda
-atk
-attr
-audit
-cronie
-cronie-anacron
-crontabs
-cups-libs
-dnsmasq
-desktop-file-utils
-elfutils-libs
-gnutls
-hicolor-icon-theme
-libdaemon
-libICE
-libIDL
-libpcap
-libtiff
-libXcursor
-libXdmcp
-newt
-rsyslog
-sendmail
-slang
-sudo
-system-config-keyboard
-vconfig

%end

%post
ARCH=$(uname -i)
if [ ${ARCH} == x86_64 ]; then
	SHMMAX=68719476736
	SHMALL=4294967296
else
	SHMMAX=4294967295
	SHMALL=268435456
fi
if grep -q net.ipv4.tcp_syncookies /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(net.ipv4.tcp_syncookies\).*$/\1 = 1/g' /etc/sysctl.conf
else
	echo "# Controls the use of TCP syncookies" >> /etc/sysctl.d/99-network.conf
	echo net.ipv4.tcp_syncookies = 1 >> /etc/sysctl.d/99-network.conf
fi
if grep -q kernel.msgmnb /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(kernel.msgmnb\).*$/\1 = 65536/g' /etc/sysctl.conf
else
	echo "# Controls the maximum size of a message, in bytes" >> /etc/sysctl.d/99-msgbuff.conf
	echo kernel.msgmnb = 65536 >> /etc/sysctl.d/99-msgbuff.conf
fi
if grep -q kernel.msgmax /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(kernel.msgmax\).*$/\1 = 65536/g' /etc/sysctl.conf
else
	echo -e "\n# Controls the default maxmimum size of a mesage queue" >> /etc/sysctl.d/99-msgbuff.conf
	echo kernel.msgmax = 65536 >> /etc/sysctl.d/99-msgbuff.conf
fi
if grep -q kernel.shmmax /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(kernel.shmmax\).*$/\1 = '${SHMMAX}'/g' /etc/sysctl.conf
else
	echo "# Controls the maximum shared segment size, in bytes" >> /etc/sysctl.d/99-sharedmem.conf
	echo kernel.shmmax = ${SHMMAX} >> /etc/sysctl.d/99-sharedmem.conf
fi
if grep -q kernel.shmall /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(kernel.shmall\).*$/\1 = '${SHMALL}'/g' /etc/sysctl.conf
else
	echo -e "\n# Controls the maximum number of shared memory segments, in pages" >> /etc/sysctl.d/99-sharedmem.conf
	echo kernel.shmall = ${SHMALL} >> /etc/sysctl.d/99-sharedmem.conf
fi
cat<<-SYSCTLEOF >> /etc/sysctl.d/99-network.conf
##
##
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = "1024 65535"
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_rmem = "4096 87380 16777216"
net.ipv4.tcp_wmem = "4096 65536 16777216"
net.core.optmem_max = 40960
##
net.core.rmem_default = 16777216
net.core.rmem_max = 16777216
net.core.wmem_default = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 10240
##
SYSCTLEOF
mkdir -p /var/lib/tftpboot/os/oel/{7.4,6.9}/x86_64
mkdir -p /var/lib/tftpboot/os/ovs/3.4/x86_64
mkdir /var/lib/tftpboot/pxelinux.cfg
ln /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/pxelinux.0
ln /usr/share/syslinux/vesamenu.c32 /var/lib/tftpboot/vesamenu.c32
ln /usr/share/syslinux/menu.c32 /var/lib/tftpboot/menu.c32
ln /usr/share/syslinux/chain.c32 /var/lib/tftpboot/chain.c32
#ln /boot/efi/EFI/BOOT/BOOTX64.EFI /var/lib/tftpboot/bootx64.efi
#ln /usr/share/anaconda/boot/syslinux-vesa-splash.jpg /var/lib/tftpboot/splash.jpg
cat<<-EOF>/var/lib/tftpboot/pxelinux.cfg/default
default vesamenu.c32
timeout 600

#menu background splash.jpg
menu title Welcome to Allan Vitangcol PXE Boot Server!
menu color border 0 #ffffffff #00000000
menu color sel 7 #ffffffff #ff000000
menu color title 0 #ffffffff #00000000
menu color tabmsg 0 #ffffffff #00000000
menu color unsel 0 #ffffffff #00000000
menu color hotsel 0 #ff000000 #ffffffff
menu color hotkey 7 #ffffffff #ff000000
menu color timeout_msg 0 #ffffffff #00000000
menu color timeout 0 #ffffffff #00000000
menu color cmdline 0 #ffffffff #00000000
menu hiddenrow 5

label local
  menu default
  menu label Boot from Local Disk
  kernel chain.c32
  append hd0

EOF
cat<<-EOF>/etc/httpd/conf.d/pxeBoot.conf
<Directory /var/lib/tftpboot/os>
${TAB}	Options Indexes FollowSymLinks
${TAB}	AllowOverride None
</Directory>
<Directory /usr/local/Downloads>
${TAB}	Options Indexes FollowSymLinks
${TAB}	AllowOverride None
</Directory>
Alias /os/asv /usr/local/Downloads/asv
Alias /os/kickstart /usr/local/Downloads/kickstart
Alias /os/include /usr/local/Downloads/include
Alias /os/OpenStack/6 /usr/local/Downloads/OpenStack/Repository
Alias /os/OpenStack/6Server /usr/local/Downloads/OpenStack/Repository
Alias /os/oel /var/lib/tftpboot/os/oel
Alias /os/ovs /var/lib/tftpboot/os/ovs
EOF
mkdir -p /usr/local/Downloads/{kickstart,include}
cat<<-KICKSTART>/etc/sysconfig/kickstart
DEV=eth0
DHCPDCONF=/etc/dhcp/dhcpd.conf
NEXTSERVER=10.132.64.40
KICKSTART
%end

%post --nochroot
if [ -d $(getent passwd $(logname)|cut -d: -f6)/Public ]; then
	cd $(getent passwd $(logname)|cut -d: -f6)/Public
	find kickstart include -type f -o -type l| cpio -pdmuvL $INSTALL_ROOT/usr/local/Downloads
	chown -R 48:48 $INSTALL_ROOT/usr/local/Downloads
fi
for rhgbfile in EFI/BOOT/isolinux.cfg EFI/BOOT/grub.cfg EFI/BOOT/BOOTX64.conf EFI/BOOT/grub.conf isolinux/isolinux.cfg
do
	if [ -f $LIVE_ROOT/$rhgbfile ]; then
		sed -i 's/ rhgb//g;s/ quiet//g;s|/EFI/boot|/EFI/BOOT|g' $LIVE_ROOT/$rhgbfile
	fi
done
%end
