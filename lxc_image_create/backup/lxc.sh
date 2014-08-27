#!/bin/bash

DATE=`date +%Y%m%d%H%M`
VARIANT='minbase'
INCLUDE='iproute,iputils-ping,ifupdown,locales,dialog,netbase,net-tools,dnsutils,apt-utils,isc-dhcp-client,iputils-ping,aptitude,iproute,openssh-server,vim'
ARCH='amd64'
OS_RELEASE='wheezy'
LXC_IMAGE_PATH='.'
LXC_IMAGE_NAME_RAW="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.raw"
LXC_IMAGE_NAME_QCOW2="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.qcow2"
LXC_ROOTFS='/mnt/lxc'

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
  debootstrap --verbose --variant="${VARIANT}" --arch="${ARCH}" --include "${INCLUDE}" ${OS_RELEASE} "${LXC_ROOTFS}" http://ftp.cn.debian.org/debian/
  if [ $? -ne 0 ]; then
    stderr "stderr installing base system"
    exit 1
  fi
  chroot ${LXC_ROOTFS} /bin/sh -c "echo root:aaaa | chpasswd"
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
umount_rootfs
convert_image

exit 0