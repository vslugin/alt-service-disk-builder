# Mini HowTo

## Install Packages (Alt Linux Workstation P10 or analog)

from root
```bash
apt-get install -y xorriso squashfs-tools cdrkit-utils genisoimage
```

## Clone

```bash
git clone https://github.com/vslugin/alt-service-disk-builder
cd alt-service-disk-builder
```

## Download base ISO

```bash
wget http://nightly.altlinux.org/sisyphus/tested/regular-rescue-latest-x86_64.iso
```

## Unpack (from root)

```bash
./unpack.sh
```

## Modify squashfs in chroot (if need)

```bash
./sqfs_chroot.sh
```

## Pack (from root)

```bash
export DESTINATION_ISO_FILE_PATH="/tmp/service_disk.iso"

./pack.sh
```

## Cleanup (from root)
```bash
/bin/rm -r squashfs-root iso_contents
```