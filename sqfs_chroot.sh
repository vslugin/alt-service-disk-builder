#!/bin/bash

root_mntpnt="$(pwd)/squashfs-root"

mount -t proc /proc ${root_mntpnt}/proc
mount -t sysfs /sys ${root_mntpnt}/sys
mount --bind /dev/ ${root_mntpnt}/dev

echo 'nameserver 8.8.8.8' > ${root_mntpnt}/etc/resolv.conf

cat << 'EOF' > ${root_mntpnt}/etc/apt/sources.list.d/yandex.list
rpm [alt] http://mirror.yandex.ru/altlinux Sisyphus/x86_64 classic
rpm [alt] http://mirror.yandex.ru/altlinux Sisyphus/x86_64-i586 classic
rpm [alt] http://mirror.yandex.ru/altlinux Sisyphus/noarch classic
EOF

chroot ${root_mntpnt}/  << EOF
apt-get update
apt-get install -y udpcast dhcp-server
EOF

umount ${root_mntpnt}/dev
umount ${root_mntpnt}/sys
umount ${root_mntpnt}/proc