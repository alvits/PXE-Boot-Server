if [ ${VER%.*} -lt 7 ]; then
	echo any net default gw ${StaticRoute} > /etc/sysconfig/static-routes
	echo 'add_dracutmodules+=" network"' > /etc/dracut.conf.d/network.conf
	sed -i 's/^\(\[ -z "\$netroot" \] \&\&\) \(.*\)$/\1 : \2/g' /usr/share/dracut/modules.d/40network/ifup /usr/share/dracut/modules.d/40network/net-genrules.sh
	for kver in $(rpm -q --qf "%{version}-%{release}.%{arch}\n" kernel-uek); do
		dracut -a network -f /boot/initramfs-${kver}.img ${kver}
	done
fi
