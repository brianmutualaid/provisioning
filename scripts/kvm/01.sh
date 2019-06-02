#!/bin/sh

#
# Script to set up KVM on a minimal CentOS 7 with the standard security profile
#

# Install QEMU/KVM/libvirt stuff

yum -y install qemu-kvm qemu-img libvirt virt-install libvirt-client
yum -y install lm_sensors

# Configure LVM for the KVM storage pool

pvcreate /dev/"$1"
if [ "$?" != "0" ]; then
	printf "Couldn't create physical volume. Make sure the disk you specified is empty and uninitialized with LVM.\n"
	exit 1
fi
vgcreate kvm_pool_vg /dev/"$1"
lvcreate -l 100%FREE -n kvm_pool_lv kvm_pool_vg
mkfs.xfs /dev/mapper/kvm_pool_vg-kvm_pool_lv
mkdir /kvm_pool

# Configure fstab to mount the KVM storage pool on boot and mount it now

cp /etc/fstab /etc/fstab.orig
printf "/dev/mapper/kvm_pool_vg-kvm_pool_lv /kvm_pool xfs defaults 0 0" >> /etc/fstab
mount /kvm_pool

# Configure storage pool with virsh

virsh pool-define-as kvm_pool dir - - - - "/kvm_pool"
virsh pool-build kvm_pool
virsh pool-start kvm_pool
virsh pool-autostart kvm_pool

# Start and enable libvirtd

systemctl start libvirtd
systemctl enable libvirtd

# Make a directory for ISOs

mkdir /kvm_pool/isos

# Enable IPv4 routing

printf "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Copy scripts to home directory

cp -R "$3"/kvm/home/bin /home/"$2"/
