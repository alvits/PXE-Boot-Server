# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
#clearpart --all --drives=${DISK:-xvda} --disklabel=gpt
part biosboot --fstype=biosboot --size=1 --ondisk=${DISK:-xvda}
part /boot --fstype=xfs --fsoptions="defaults,discard" --size=512 --ondisk=${DISK:-xvda}
part pv.100000 --size=1 --grow --ondisk=${DISK:-xvda}
volgroup ${vgname:-vg00} --pesize=32768 pv.100000
logvol swap --vgname=${vgname:-vg00} --fstype=swap --name=lv_swap --recommended
logvol none --thinpool --vgname=${vgname:-vg00} --name=${thinpool:-thinp} --size=1 --grow
logvol / --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_root --size=1024
logvol /usr --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_usr --size=5120
logvol /var --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_var --size=3072
logvol /tmp --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_tmp --size=4096
logvol /home --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_home --size=1024
logvol /${datadisk:-u01} --vgname=${vgname:-vg00} --thin --poolname ${thinpool:-thinp} --fstype=xfs --fsoptions="defaults,discard" --name=lv_${datadisk:-u01} --percent=17
