#!/bin/bash

. /usr/local/etc/functions

xl create /xen/VMs/VM.cfg "name='${HOST}'; extra='ip=${IPADDR}:${BROADCAST}:${GATEWAY}:${NETMASK}:${HOST}:eth0:none elevator=noop'; disk=['phy:/dev/vg_tmpsc1/${HOST}-os,xvda,w']; vcpus=2; memory=4096"
