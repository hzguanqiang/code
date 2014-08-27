#!/bin/bash
# AUTHOR: hzsunzixiang
# hzsunzixiang@corp.netease.com

# lxc-install

set -e
set -x
LC_ALL=C




# 下载镜像的mirror，用cn的镜像更快
DEBIAN_MIRROR="http://ftp.cn.debian.org/debian/"

net_bridge_if="br100"              # 网桥配置
#net_dns_resolver="8.8.8.8"         # dns服务器
DEBIAN_ARCH=amd64
DISTS=wheezy
DEBIAN_SUITE="ifupdown,locales,net-tools,dnsutils,apt-utils,isc-dhcp-client,inetutils-ping,tcpdump,aptitude,iproute,openssh-server,vim"

# Functions


#初始化必要的目录
initialize(){
    # Configuration variables
    # LXC的根目录
    if [ ! -d $LXC_PATH ]
    then 
        mkdir $LXC_PATH
        ln -s /lxc /var/lib/lxc
    fi
    if [ -d $lxc_rootfs ]
    then 
       echo "the name $lxc_name has already exist, exit....................................."
       exit 1
    fi
    echo "creating root directory $lxc_rootfs"
    mkdir -p $lxc_rootfs
}

# 生成镜像
create_image(){
    # 使用qemu-nbd需要依赖其他软件，直接使用dd
    dd if=/dev/zero of=$lxc_rootpath/lxc_image.raw bs=10M count=100 
    sleep 2
    mkfs.ext4 -F  $lxc_rootpath/lxc_image.raw
    sleep 2
    # 挂载到loop设备上
    mount -o loop $lxc_rootpath/lxc_image.raw $lxc_rootfs 
}

# 压缩镜像
convert_image(){
    echo "converting----------------------------------------------------"
    qemu-img convert -c -f raw -O qcow2   $lxc_rootpath/lxc_image.raw $lxc_rootpath/lxc_amd64_final.qcow2 
    #qemu-img convert -c -f qcow2 -O qcow2   $lxc_rootpath/lxc_image.qcow2 $lxc_rootpath/lxc_image_final.qcow2 
}
# 安装镜像
install_lxc() {
    echo "installing----------------------------------------------------"
    aptitude install qemu lxc debootstrap
    # 安装镜像
    debootstrap --verbose --variant=minbase --arch=$DEBIAN_ARCH --include $DEBIAN_SUITE $DISTS $lxc_rootfs $DEBIAN_MIRROR
    echo "install over ----------------------------------------------------"

}

network_init(){
    # 采用dhcp的方式，但是并没有lxc虚拟机能访问的dhcp服务器，
    # 这里可以给其分配ip，但是这样的镜像不符合要求
    # 所以lxc虚拟机如果要启动，需要手工配置
    echo "networking : setting IP configuration"
    cat <<EOT >"$lxc_rootfs/etc/network/interfaces"
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp

auto eth1
allow-hotplug eth1
iface eth1 inet dhcp

auto eth2
allow-hotplug eth2
iface eth2 inet dhcp

source /etc/network/interfaces.d/*.cfg
EOT
}
inittab_init() {

    echo "inittab_init.............."
    # 清除inittab的一些项
    cat  <<EOT >"$lxc_rootfs/etc/inittab"
# /etc/inittab: init(8) configuration.
# $Id: inittab,v 1.91 2002/01/25 13:35:21 miquels Exp $

# The default runlevel.
id:2:initdefault:

# Boot-time system configuration/initialization script.
# This is run first except when booting in emergency (-b) mode.
si::sysinit:/etc/init.d/rcS

# What to do in single-user mode.
~:S:wait:/sbin/sulogin

# /etc/init.d executes the S and K scripts upon change
# of runlevel.
#
# Runlevel 0 is halt.
# Runlevel 1 is single-user.
# Runlevels 2-5 are multi-user.
# Runlevel 6 is reboot.

l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6
# Normally not reached, but fallthrough in case of emergency.
z6:6:respawn:/sbin/sulogin

# What to do when CTRL-ALT-DEL is pressed.
ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

# /sbin/getty invocations for the runlevels.
#
# The "id" field MUST be the same as the last
# characters of the device (after "tty").
#
# Format:
#  :::
#
1:2345:respawn:/sbin/getty 38400 console
EOT

}


lxc_config_init() {
    echo "creating configuration file $lxc_config"
cat <<EOT >$lxc_config
lxc.utsname = $lxc_name
lxc.tty = 6
lxc.pts = 1024
lxc.rootfs = $lxc_rootfs
lxc.cgroup.devices.deny = a
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm
# network
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $net_bridge_if
lxc.network.name = eth0
lxc.network.hwaddr = 00:FF:12:34:56:78
EOT
}

# help
usage() {
    cat <<EOT
Creating LXC image. 
Usage: $0 -n name
-n name | creating LXC image 
-h | help

Example :
   $0 -n example 
EOT
}

# main

if [ $# -le 0 ]; then
	usage
	exit 1
fi

while getopts "n:" arg
do
    case $arg in
     n)
        lxc_name=$OPTARG
        echo "========================================"$lxc_name
        ;;
     *)
       usage
       exit 1
    esac
done



LXC_PATH="/lxc"                    # 镜像的根目录
lxc_rootpath="$LXC_PATH/$lxc_name" # 形如/lxc/example
lxc_rootfs="$lxc_rootpath/rootfs"  # 形如/lxc/example/rootfs
lxc_config="$lxc_rootpath/config"  # 形如/lxc/example/config
#初始化必要的目录
initialize

# 生成镜像,并挂载
create_image

# 安装镜像
install_lxc

# 设置interfaces文件
network_init

inittab_init

#初始化配置
lxc_config_init

# 修改密码
chroot $lxc_rootfs passwd

#echo "starting container with lxc-start"
#lxc-start -d -n $lxc_name
# 压缩镜像

convert_image


echo "Done."
