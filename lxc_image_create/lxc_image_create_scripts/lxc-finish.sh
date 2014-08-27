#!/bin/bash

#DATE=`date +%Y%m%d`
DATE='20140815'
ARCH='amd64'
OS_RELEASE='wheezy'
LXC_IMAGE_PATH='.'
LXC_IMAGE_NAME_RAW="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.raw"
LXC_IMAGE_NAME_QCOW2="debian_${OS_RELEASE}_${ARCH}_lxc_${DATE}.qcow2"
LXC_DEFAULT_PATH='/var/lib/lxc'
LXC_NAME='lxc-image'
LXC_ROOTFS='/mnt/lxc'

stdout () {
  echo "$1"
}

stderr () {
  echo "$1" 1>&2
}

stop_lxc () {
stdout "=== stop lxc ${LXC_NAME}"
lxc-stop -n ${LXC_NAME}
}

umount_rootfs () {
  stdout "=== umount rootfs"
  umount ${LXC_ROOTFS}
  if [ $? -ne 0 ]; then
    stderr "umount rootfs failed"
    exit 1
  fi
  rm -rf ${LXC_ROOTFS}
  rm -rf ${LXC_DEFAULT_PATH}/${LXC_NAME}
}

convert_image () {
  stdout "=== convert raw to qcow2"
  qemu-img convert -c -f raw ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_RAW} -O qcow2 ${LXC_IMAGE_PATH}/${LXC_IMAGE_NAME_QCOW2}
}

stop_lxc
umount_rootfs
convert_image

exit 0
