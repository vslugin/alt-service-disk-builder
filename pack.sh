#!/bin/bash
SRC_ISO='regular-rescue-latest-x86_64.iso'
cp .service.env squashfs-root/root/
cp service.sh squashfs-root/bin/
chmod +x squashfs-root/bin/service.sh

# for debug only !
cp debug.sh squashfs-root/opt
chmod +x squashfs-root/opt/debug.sh

cat << 'EOF' > squashfs-root/root/.bashrc
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias d='ls'
alias s='cd ..'
alias p='cd -'

[ -n "$INPUTRC" ] || export INPUTRC=/etc/inputrc

PATH=/root/bin:/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
ENV=$HOME/.bashrc
USERNAME="root"
export USERNAME ENV PATH
/bin/service.sh
EOF

rm -f iso_contents/rescue
mksquashfs squashfs-root/ iso_contents/rescue
#-b 1M -noappend

cp -r squashfs-root/usr/lib/syslinux/* iso_contents/syslinux/

dd if=${SRC_ISO} of=iso_contents/syslinux/isohdpfx.bin bs=512 count=1

#custom configs
/bin/cp -f cfgs/isolinux.cfg iso_contents/syslinux/
/bin/cp -f cfgs/grub.cfg iso_contents/boot/grub/

UUID_ISO=`date -u +%Y-%m-%d-%H-%M-%S-00`
UUID_ISO_SHRT=`echo ${UUID_ISO} | sed 's/-//g'`

sed -i "s/_UUID_ISO_SHRT_/$UUID_ISO/g" iso_contents/syslinux/isolinux.cfg
sed -i "s/_UUID_ISO_SHRT_/$UUID_ISO/g" iso_contents/boot/grub/grub.cfg

TIMESTAMP_FILE="iso_contents/$(ls iso_contents/ | grep ....-..-..-..-..-..-..)"

if [ -f ${TIMESTAMP_FILE} ]; then
/bin/rm ${TIMESTAMP_FILE}
fi

touch iso_contents/${UUID_ISO}

cd iso_contents/
xorriso -follow param \
  -read_mkisofsrc \
  ${UUID_ISO_SHRT:+-volume_date uuid "$UUID_ISO_SHRT"} \
  -as mkisofs \
  -J -l -r \
  -b syslinux/isolinux.bin \
  --eltorito-catalog boot/grub/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -isohybrid-mbr syslinux/isohdpfx.bin \
  -partition_offset 16 \
  --grub2-boot-info \
  --grub2-mbr ../squashfs-root/usr/lib64/grub/i386-pc/boot_hybrid.img \
  -iso-level 3 -full-iso9660-filenames -sysid "LINUX" \
  -volid "AltRerscue10" -volset "ALT" -publisher "NNTC" \
  -appid "AltRerscue10 X86_64" -copyright "LICENSE_ALL_HTML"\
  --mbr-force-bootable \
  -eltorito-alt-boot \
  -e EFI/.efiboot.img \
  -no-emul-boot \
  -append_partition 2 0xef EFI/.efiboot.img \
  -appended_part_as_gpt \
  -o ${DESTINATION_ISO_FILE_PATH} .

#xorriso -follow param \+
#        -read_mkisofsrc +\
#        ${UUID_ISO_SHRT:+-volume_date uuid "$UUID_ISO_SHRT"} \+
#        -as mkisofs \+
#        $verbose -J -l -r \+?
#        -exclude-list /tmp/.exclude \?
#        -eltorito-boot boot/grub/bios.img \
#        -no-emul-boot \ +
#        -boot-load-size 4 \ +
#        -boot-info-table \ +
#        -partition_offset 16 \ +
#        --eltorito-catalog  boot/grub/boot.cat \
#        --grub2-boot-info \
#        --grub2-mbr \$libdir/grub/i386-pc/boot_hybrid.img \
#        --mbr-force-bootable \
#        -eltorito-alt-boot \
#        -e EFI/.efiboot.img \
#        -no-emul-boot \
#        -append_partition 2 0xef /.image/EFI/.efiboot.img \
#        -appended_part_as_gpt \
#        "\$imgdir/" || rc=\$?

cd ..

echo "Result in file: ${DESTINATION_ISO_FILE_PATH}"