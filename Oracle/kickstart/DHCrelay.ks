%include ../../PXE-Boot-Server/PXE-Boot-Server.ks

%post
sed -i 's/^\(ExecStart=\/usr\/sbin\/dhcrelay.*\)$/\1 10.132.64.40/g' /usr/lib/systemd/system/dhcrelay.service

if grep -q net.ipv4.ip_forward /etc/sysctl.conf; then
	sed -i 's/^[#\s]*\(net.ipv4.ip_forward\).*$/\1 = 1/g' /etc/sysctl.conf
else
	sysctl -w net.ipv4.ip_forward=1 >> /etc/sysctl.conf
fi

systemctl disable httpd.service
systemctl disable dhcpd.service
systemctl enable dhcrelay.service
%end
