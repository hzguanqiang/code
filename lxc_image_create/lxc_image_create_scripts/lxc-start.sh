#!/bin/bash

#DATE=`date +%Y%m%d`
DATE='20140815'
VARIANT='minbase'
INCLUDE='iproute,iputils-ping,ifupdown,locales,dialog,netbase,net-tools,dnsutils,apt-utils,isc-dhcp-client,aptitude,openssh-server,vim'
#INCLUDE="ifupdown,locales,net-tools,dnsutils,apt-utils,isc-dhcp-client,iputils-ping,tcpdump,aptitude,iproute,openssh-server,vim"
ARCH='amd64'
OS_RELEASE='wheezy'
LXC_IMAGE_PATH='.'
LXC_IMAGE_NAME_RAW="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.raw"
LXC_IMAGE_NAME_QCOW2="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.qcow2"
LXC_DEFAULT_PATH='/var/lib/lxc'
LXC_NAME='lxc-image'
LXC_ROOTFS='/mnt/lxc'
LXC_INTERFACES='./interfaces'
LXC_INITTAB='./inittab'

stdout () {
  echo "$1"
}

stderr () {
  echo "$1" 1>&2
}

test_debootstrap () {
  debootstrap --version > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    stdout "=== Installing Debootstrap"
    aptitude install debootstrap -y
  fi
}

prepare_image(){
  [[ -d ${LXC_ROOTFS} ]] || mkdir -p ${LXC_ROOTFS}
  qemu-img create -f raw ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_RAW} 20G
  mkfs.ext4 -F ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_RAW}
  mount -o loop ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_RAW} ${LXC_ROOTFS}
  stdout "=== mount ${LXC_ROOTFS} ready"
}

debootstrap_install () {
  test_debootstrap
  prepare_image
  stdout "=== Installing base system"
  debootstrap --verbose --variant="${VARIANT}" --arch="${ARCH}" --include "${INCLUDE}" ${OS_RELEASE} "${LXC_ROOTFS}" http://mirrors.aliyun.com/debian/
  if [ $? -ne 0 ]; then
    stderr "stderr installing base system"
    exit 1
  fi
  chroot ${LXC_ROOTFS} /bin/sh -c "echo root:aaaa | chpasswd"

  stdout "=== Configure lxc network interfaces:"
  cp ${LXC_INTERFACES} ${LXC_ROOTFS}/etc/network/interfaces
  #chroot ${LXC_ROOTFS} /bin/echo "${LXC_INTERFACES}" > /etc/network/interfaces
  
  stdout "=== Configure lxc inittab"
  cp ${LXC_INITTAB} ${LXC_ROOTFS}/etc/inittab
}

lxc_config_init () {
echo "creating configuration file ${LXC_DEFAULT_PATH}/${LXC_NAME}/config"
cat <<EOT >${LXC_DEFAULT_PATH}/${LXC_NAME}/config
lxc.utsname = ${LXC_NAME}
lxc.tty = 6
lxc.pts = 1024
lxc.rootfs = ${LXC_ROOTFS}
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
#network
#lxc.network.type = veth
#lxc.network.flags = up
#lxc.network.name = eth0
EOT
}

start_lxc () {
  stdout "=== start lxc named ${LXC_NAME}"
  [[ -d ${LXC_DEFAULT_PATH}/${LXC_NAME} ]] | mkdir -p ${LXC_DEFAULT_PATH}/${LXC_NAME}
  ln -s ${LXC_ROOTFS} ${LXC_DEFAULT_PATH}/${LXC_NAME}/rootfs
  lxc_config_init
  stdout "=== lxc-start -n ${LXC_NAME}"
  lxc-start -n ${LXC_NAME}
}

umount_rootfs () {
  stdout "=== umount rootfs"
  umount ${LXC_ROOTFS}
  if [ $? -ne 0 ]; then
    stderr "umount rootfs failed"
    exit 1
  fi
  rm -rf ${LXC_ROOTFS}
}

convert_image () {
  stdout "=== convert raw to qcow2"
  qemu-img convert -c -f raw ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_RAW} -O qcow2 ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_QCOW2}
}

debootstrap_install
start_lxc
#umount_rootfs
#convert_image

exit 0
