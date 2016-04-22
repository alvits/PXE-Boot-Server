sed -i 's/^\([[:blank:]]*thin_pool_autoextend_threshold[[:blank:]]*=\)[[:blank:]]*[0-9]*.*$/\1 80/' /etc/lvm/lvm.conf
