# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
#clearpart --all --initlabel --drives=${DISK:-sda}
part biosboot --fstype=biosboot --size=1 --ondisk=${DISK:-sda}
part /boot --fstype ext4 --size=512 --ondisk=${DISK:-sda}
part / --fstype ext4 --size=10240 --ondisk=${DISK:-sda}
part swap --size=2048 --ondisk=${DISK:-sda}
part /usr --fstype=$fstype --size=10240 --ondisk=${DISK:-sda}
part /var --fstype=$fstype --size=10240 --ondisk=${DISK:-sda}
part /tmp --fstype=$fstype --size=4096 --ondisk=${DISK:-sda}
part /var/lib --fstype=$fstype --size=153600 --ondisk=${DISK:-sda}
part /srv/node/sdb --fstype=xfs --size=1 --grow --ondisk=${DISK:-sda}
