#!/bin/sh

# AUTHOR: hzsunzixiang
# hzsunzixiang@corp.netease.com

set -e
set -x
LC_ALL=C

# Functions

# cgroup 

#调用grub_init() 是为了解决一个bug,
#Optional: Enable memory cgroup support (534964) (CONFIG_CGROUP_MEM_RES_CTLR) - Since 2.6.39-bpo60-2 for Squeeze the memory cgroup support is built in, so lxc-checkconfig will give you a green result about this point. At the same time, it is deactivated by default. You need to activate memory cgroup support with a kernel parameter. When using grub2, this can be easily done by adding GRUB_CMDLINE_LINUX="cgroup_enable=memory" in /etc/default/grub and running update-grub2. Same for CONFIG_CGROUP_MEM_RES_CTLR_SWAP - see http://lists.debian.org/debian-kernel/2012/01/msg00804.html . 


# 这个操作涉及重启，必须手工操作
#grub_init() {
#    GRUB_FILE="/etc/default/grub"
#    # 如果没有这一行，需要加上
#    if ! grep "cgroup_enable=memory" $GRUB_FILE 
#    then 
#    cat <<EOG > "$GRUB_FILE"
#GRUB_CMDLINE_LINUX="cgroup_enable=memory"
#EOG
#    #else "there have been cgroup_enable=memory"
#    fi
#    ## 如果运行下面一行之后不起作用，需要重启机器
#    update-grub2
#    ## 这里必须手工干预,重启机器，不然会出现
#    #root@localhost:/rootfs# service mount-cgroup start
#    #mount: special device memory does not exist
#
#}
cgroup_init() {
    # 手工初初始化 grub initialize
    #grub_init
    # 添加配置 
    CGROUP_FILE="/etc/init.d/mount-cgroup"
    # 检查这个文件是否存在，并且是可执行文件
    if [ ! -x "$CGROUP_FILE" ]
    then
        cat <<EOT >> "$CGROUP_FILE"
#! /bin/sh
#
# mount script for cgroup
#
#
### BEGIN INIT INFO
# Provides:          Cgroup
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      hal avahi cgconfig
# Should-Stop:       hal avahi cgconfig
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: mount cgroup
### END INIT INFO
# mount Cgroup
mount -t tmpfs cgroup_root /sys/fs/cgroup/
mkdir /sys/fs/cgroup/cpuset
mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset
mkdir /sys/fs/cgroup/blkio
mount -t cgroup -oblkio blkio /sys/fs/cgroup/blkio/
mkdir /sys/fs/cgroup/cpuacct
mount -t cgroup -ocpuacct cpuacct /sys/fs/cgroup/cpuacct/
mkdir /sys/fs/cgroup/freezer
mount -t cgroup -ofreezer freezer /sys/fs/cgroup/freezer/
mkdir /sys/fs/cgroup/devices
mount -t cgroup -odevices devices /sys/fs/cgroup/devices/
mkdir /sys/fs/cgroup/cpu
mount -t cgroup -ocpu cpu /sys/fs/cgroup/cpu
mkdir /sys/fs/cgroup/memory
mount -t cgroup -omemory memory /sys/fs/cgroup/memory
EOT
     chmod u+x $CGROUP_FILE
    else 
        echo "the file $CGROUP_FILE exist"
    fi
    service mount-cgroup start
    #  加入开机自启动
    update-rc.d mount-cgroup  defaults
    # 断定这些文件存在 ,如果不存在，说明没配置好
    
   # cgroup_files=( blkio cpu cpuacct cpuset devices freezer memory )
   # for i in ${cgroup_files[@]}                #将@替换为*亦可
   # do
   #        if ! ls /sys/fs/cgroup/$i
   #        then 
   #            echo "/sys/fs/cgroup/$i not  exist"
   #            exit 1
   #        else 
   #            echo "/sys/fs/cgroup/$i exist"
   #        fi
   # done
}


net_bridge_if="br100"
net_address="192.168.2.77"
net_mask="255.255.255.0"

# 准备网桥
bridge_init() {
    apt-get -y install vlan bridge-utils
    modprobe 8021q
    
    SYSCTL_FILE=/etc/sysctl.conf
    # allow ip forwardin 可以写入配置文件

    #sysctl -w net.ipv4.ip_forward=1
    
    if ! grep  ^net.ipv4.ip_forward  /etc/sysctl.conf
    then
    cat >> $SYSCTL_FILE <<EOM
net.ipv4.ip_forward=1
EOM
    fi
    # create internal bridge and allow forwarding. Adjust address for your allocation
    # 因为一个接口一旦挂接到一个网桥上，那么这个接口就不可用了，
    # 而且虚拟中一般只有一个网卡，所以这里使用vlan的方式
    cat >> /etc/network/interfaces <<EOM

auto eth0.1
iface eth0.1 inet manual
    vlan-raw-device eth0

auto  $net_bridge_if
iface $net_bridge_if inet static
        bridge_ports eth0.1
        address $net_address
        netmask $net_mask 
EOM
    ifup $net_bridge_if 
}


usage() {
    cat <<EOT
prepare for creating LXC container.
Usage: $0 -w -c 
-w | network preparing
-c | cgroup preparing
-h | help 

Example :
   $0 -w  -c 
   $0 -w  
   $0 -c  
   $0 -h  
EOT
}



## Main

if [ $# -le 0 ]; then
   usage
   exit 1
fi

WITH_NET=0
CGROUP_INIT=0
while getopts ":cwh" arg
do
    case $arg in
      w)
        echo "with network bridge config" 
        WITH_NET=1
        ;;
      c)
        echo "with cgroup init" 
        CGROUP_INIT=1
        ;;
      h)
        usage
        exit 0
        ;;
      *)
        usage
        exit 1
        ;;
    esac
done

# 手工grub初始化
#grub_init

# cgroup初始化
if [ $CGROUP_INIT -eq 1 ]
then 
    cgroup_init
fi

# 网络初始化
if [ $WITH_NET -eq 1 ]
then 
    bridge_init
fi

echo "Done."
