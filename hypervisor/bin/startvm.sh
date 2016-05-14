#!/bin/bash

. /usr/local/etc/functions

xl create /xen/VMs/VM.cfg "name='${HOST}'; extra='netroot=vg_${HOST//-/}/lv_root ip=${IPADDR}::${GATEWAY}:${NETMASK}:${HOST}:eth0:none:10.209.76.198:10.209.76.197 elevator=noop'; disk=['phy:/dev/vg_tmpsc1/${HOST}-os,xvda,w']; vcpus=2; memory=4096"
