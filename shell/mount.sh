#!/bin/sh
#sh ln.sh
 mount -t tmpfs cgroup_root /sys/fs/cgroup/
 mkdir /sys/fs/cgroup/cpuset
 mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset
 mkdir /sys/fs/cgroup/memory
 mount -t cgroup memory /sys/fs/cgroup/memory/ -omemory
 mkdir /sys/fs/cgroup/blkio
 mount -t cgroup blkio -oblkio /sys/fs/cgroup/blkio/
 mkdir /sys/fs/cgroup/cpuacct
 mount -t cgroup cpuacct -ocpuacct /sys/fs/cgroup/cpuacct/
 mkdir /sys/fs/cgroup/freezer
 mount -t cgroup -ofreezer freezer /sys/fs/cgroup/freezer/
 mkdir /sys/fs/cgroup/devices
 mount -t cgroup devices -odevices /sys/fs/cgroup/devices/
 mkdir /sys/fs/cgroup/cpu
 mount -t cgroup -ocpu cpu /sys/fs/cgroup/cpu

#service libvirt-bin restart
#service nova-api restart
#service nova-compute restart
#service nova-scheduler restart
#service nova-network restart 
