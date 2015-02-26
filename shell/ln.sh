#!/bin/sh
rm -f /usr/lib/libvirt.so.0 /usr/lib/libvirt.so /usr/lib/libvirt-qemu.so.0 /usr/lib/libvirt-qemu.so
ln -s libvirt-qemu.so.0.9.11 /usr/lib/libvirt-qemu.so.0
ln -s libvirt.so.0.9.11 /usr/lib/libvirt.so.0
