##############################################################################
# File system
##############################################################################
fs.file-max = 6815744
fs.aio-max-nr = 3145728
fs.suid_dumpable = 0

##############################################################################
# Virtual memory
##############################################################################
# Use swap only if really needed
vm.swappiness = 10

# Tune OOM killer
vm.min_free_kbytes = 51200

# Hugepages/bigpages values are strongly tied to SGA size.
# If SGA size changes, then these values need to be adjusted accordingly.
#vm.nr_hugepages = ((1+3%)*SGA_SIZE)/2MB

# Miscellaneous
kernel.sysrq = 1
kernel.core_uses_pid = 1
