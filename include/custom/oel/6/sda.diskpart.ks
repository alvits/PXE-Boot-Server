# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
#clearpart --all --drives=${DISK:-sda} --disklabel=gpt
part biosboot --fstype=biosboot --size=1 --ondisk=${DISK:-sda}
part /boot --fstype=ext4 --fsoptions="defaults,discard" --size=512 --ondisk=${DISK:-sda}
part pv.100000 --size=1 --grow --ondisk=${DISK:-sda}
volgroup ${vgname} --pesize=32768 pv.100000
logvol swap --vgname=${vgname} --fstype=swap --name=lv_swap --recommended
#Thick LVM
logvol / --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_root --size=10240
logvol /usr --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_usr --size=10240
logvol /var --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_var --size=10240
logvol /tmp --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_tmp --size=4096
logvol /home --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_home --size=10240
logvol /${datadisk:-u01} --vgname=${vgname}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_${datadisk:-u01} --size=1 --grow
