#!/bin/bash

. /usr/local/etc/functions

xl create /xen/VMs/VM.cfg "name='${HOST}'; extra='ip=${IPADDR}::${GATEWAY}:${NETMASK}:${HOST}:eth0:none:10.209.76.198:10.209.76.197 elevator=noop'; disk=['phy:/dev/${vgname}/${HOST}-os,xvda,w']; vcpus=2; memory=4096"
