# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
#clearpart --all --drives=${DISK:-xvda} --disklabel=gpt
part biosboot --fstype=biosboot --size=1 --ondisk=${DISK:-xvda}
part /boot --fstype=ext4 --fsoptions="defaults,discard" --size=512 --ondisk=${DISK:-xvda}
part pv.100000 --size=1 --grow --ondisk=${DISK:-xvda}
volgroup ${vgname:-vg00} --pesize=32768 pv.100000
#logvol swap --vgname=${vgname:-vg00} --fstype=swap --name=lv_swap --recommended
#Thick LVM
logvol / --vgname=${vgname:-vg00}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_root --size=768
logvol /usr --vgname=${vgname:-vg00}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_usr --size=2048
logvol /tmp --vgname=${vgname:-vg00}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_tmp --size=512
logvol /var --vgname=${vgname:-vg00}  --fstype=ext4 --fsoptions="defaults,discard" --name=lv_var --size=768
