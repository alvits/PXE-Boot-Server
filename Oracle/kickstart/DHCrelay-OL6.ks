%include ../../PXE-Boot-Server/PXE-Boot-Server.ks

%post

sed -i 's/^\(DHCPSERVERS\).*$/\1="10.132.64.40"/g' /etc/sysconfig/dhcrelay

if grep -q net.ipv4.ip_forward /etc/sysctl.conf; then
        sed -i 's/^[#\s]*\(net.ipv4.ip_forward\).*$/\1 = 1/g' /etc/sysctl.conf
else
        sysctl -w net.ipv4.ip_forward=1 >> /etc/sysctl.conf
fi

chkconfig dhcpd off
chkconfig httpd off
chkconfig dhcrelay on
%end
