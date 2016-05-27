if [ ${VER%.*} -lt 7 ]; then
	echo any net default gw ${StaticRoute} > /etc/sysconfig/static-routes
	sed -i 's/^\(\[ -z "\$netroot" \] \&\&\) \(.*\)$/\1 : \2/g' /usr/share/dracut/modules.d/40network/ifup /usr/share/dracut/modules.d/40network/net-genrules.sh
	kver=$(rpm -q --qf "%{version}-%{release}.%{arch}\n" kernel-uek | tail -1)
	dracut -a network -f /boot/initramfs-${kver}.img ${kver}
fi
