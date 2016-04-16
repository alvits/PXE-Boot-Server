#!/bin/su root
trap cleanup 0 1 2 3 4 5 6 7 8
tmpfile=$(mktemp /tmp/XXXXXXXXXXXX)
cleanup() {
	trap - 0 1 2 3 4 5 6 7 8
	sed -n 's/^repo --name=\([^\s]*\).*$/\1/p' /tmp/repo.ks | xargs rmdir 2>/dev/null
	mounted=$(tail -1 /proc/self/mounts)
	while ! grep -Eq "^${mounted}$" $tmpfile 2>/dev/null; do
		loopdev=$(echo $mounted | cut -d' ' -f1)
		imagedir=$(echo $mounted | cut -d' ' -f2)
		umount $imagedir
		mounted=$(tail -1 /proc/self/mounts)
	done
	rm -rf ${imagedir%/install_root*} /tmp/repo.ks /tmp/network.ks /tmp/group.ks $tmpfile
	losetup -d $loopdev 2>/dev/null
}
cp /proc/self/mounts $tmpfile
client=${1%:*}
arch=${1#*:}
TargetCluster=${2:-default}
TargetOS=$(rpm -q --qf '%{version}' -f /etc/redhat-release 2>/dev/null)
TargetOS=${TargetOS:+OL${TargetOS:0:1}}
TargetOS=${3:-${TargetOS:-FC}}
ln -s $(getent passwd $(logname) | cut -d: -f6)/${client%/*}/repo-${TargetOS}.ks /tmp/repo.ks
ln -s $(getent passwd $(logname) | cut -d: -f6)/${client%/*}/${TargetCluster}-net.ks /tmp/network.ks
ln -s $(getent passwd $(logname) | cut -d: -f6)/${client%/*}/${TargetCluster}-group.ks /tmp/group.ks
[ $arch == $client ] && arch=x86_64
setarch ${arch} livecd-creator -c $(getent passwd $(logname) | cut -d: -f6)/$client --cache=/var/cache/repositories/$TargetOS -f PXE-Boot-Server --tmpdir=${LIVECD_TMPDIR:-/var/tmp}
[ -f PXE-Boot-Server.iso ] && chown $(logname):$(id -ng $(logname)) PXE-Boot-Server.iso
