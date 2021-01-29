#!/bin/bash
apt install nfs-kernel-server nfs-common -y
mkdir -p /mnt/sharefolder
chmod 755 /mnt/sharedfolder/
echo "/mnt/sharedfolder *(r,sync,no_subtree_check)" >> /etc/exports
exportfs -ra
systemctl restart nfs-kernel-server