#!/bin/bash
source ~/.service.env

TITLE="Сервисный диск на базе Alt Rescue Regular"

#### начало определения функций ####

function dlg_network_mode(){
DLG_NETWORK_MODE_OPTIONS="NONE Не_настраивать_сеть off DHCP Автоматическая_настройка_сети off STATIC Настройка_IP-адреса_и_шлюза off"
echo `dialog --stdout --title "Выбор способа настройки сети" --radiolist "Как настраиваем сеть?" 10 60 10 ${DLG_NETWORK_MODE_OPTIONS}`
}

function dlg_store_mode(){
DLG_STORE_MODE_OPTIONS="LOCAL Локальный_диск on FTP FTP_сервер off"
echo `dialog --stdout --title "Выбор варианта хранилища" --radiolist "Выберите вид хранилища?" 10 60 10 ${DLG_STORE_MODE_OPTIONS}`
}

function dlg_mode(){
DLG_MODE_OPTIONS="NONE Выберите off UDPCAST Широковещательное_клонирование(udpcast) off BACKUPRESTORE Сохранение_или_восстановление_резервной_копии off"
echo `dialog --stdout --title "Выбор режима работы" --radiolist "Выберите режим" 10 80 10 ${DLG_MODE_OPTIONS}`
}

function dlg_mode_udpcast() {
    DLG_MODE_UDPCAST_OPTIONS="RECEIVE Приниматор_(udp-receiver) off SEND Посылатор_(udp-sender) off"
    echo `dialog --stdout --title "Выбор режима работы udpcast" --radiolist "Принимаем или посылаем?" 10 60 10 ${DLG_MODE_UDPCAST_OPTIONS}`
}

function dlg_dhcpsrv_setup() {
    DLG_DHCPSRV_SETUP_OPTIONS="YES Да off NO Нет on"
        echo `dialog --stdout --title "Запуск DHCP сервера" --radiolist "Включить DHCP сервер?" 10 60 10 ${DLG_DHCPSRV_SETUP_OPTIONS}`
}

function dlg_network_setup(){
ETH_OPTIONS=$(ip -br link show | awk {'print $1'} | grep -v lo | awk {'print $1 " " $1 " off"'} | tr '\n' ' ' | sed "0,/off/s/off/on/")
echo \
`dialog --stdout --title "Настройка сети вручную" --radiolist "Сетевой интерфейс:" 10 60 10 ${ETH_OPTIONS}` \
`dialog --stdout --title "Настройка сети вручную" --inputbox "IP-адрес" 10 60 "192.168.254.254/24"` \
`dialog --stdout --title "Настройка сети вручную" --inputbox "Адрес основного шлюза" 10 60 "192.168.254.2"`
}

function dlg_mode_udpcast_get_iface(){
DLG_MODE_UDPCAST_GET_IFACE=$(ip -br link show | awk {'print $1'} | grep -v lo | awk {'print $1 " " $1 " off"'} | tr '\n' ' ' | sed "0,/off/s/off/on/")
echo \
`dialog --stdout --title "Настройка сети вручную" --radiolist "Сетевой интерфейс:" 10 60 10 ${DLG_MODE_UDPCAST_GET_IFACE}`
}

function dlg_mode_udpcast_get_src(){
DLG_MODE_UDPCAST_GET_SRC=$(lsblk -o NAME -n | grep -E '^sd|^hd|^vd|^nvme' | awk {'print "/dev/" $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор диска-источника для посылатора(udp-sender-а)" --radiolist "Выберите диск (!ОСТОРОЖНЕЕ С ВЫБОРОМ ПРИ ИСПОЛЬЗОВАНИИ VENTOY!)" 20 70 10 ${DLG_MODE_UDPCAST_GET_SRC}`
}

function dlg_mode_udpcast_get_dst(){
DLG_MODE_UDPCAST_GET_DST=$(lsblk -o NAME -n | grep -E '^sd|^hd|^vd|^nvme' | awk {'print "/dev/" $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор диска-назначения для приниматора(udp-receiver-а)" --radiolist "Выберите диск (!ОСТОРОЖНЕЕ С ВЫБОРОМ ПРИ ИСПОЛЬЗОВАНИИ VENTOY!)" 20 70 10 ${DLG_MODE_UDPCAST_GET_DST}`
}

function dlg_mount(){
echo \
`dialog --stdout --title "Подключение к FTP серверу" --inputbox "Адрес FTP-сервера:" 10 60 "$FTP_HOST"` \
`dialog --stdout --title "Подключение к FTP серверу" --inputbox "Логин на FTP-сервере:" 10 60 "$FTP_USER"` \
`dialog --stdout --title "Подключение к FTP серверу" --inputbox "Пароль на FTP-сервере:" 10 60 "$FTP_PASSWD"` \
`dialog --stdout --title "Подключение к FTP серверу" --inputbox "Каталог на FTP-сервере:" 10 60 "$FTP_DIR"`
}

function dlg_mount_disk(){
DLG_MODE_MOUNT_DISK=$(fdisk -l | grep -E '^/dev/sd|^/dev/hd|^/dev/vd|^/dev/nvme' | awk {'print $1'}  | tr '\n' ' ')
echo `dialog --stdout --title "Выбор раздела для монтирования" --radiolist "Выберите раздел (!ОСТОРОЖНЕЕ С ВЫБОРОМ ПРИ ИСПОЛЬЗОВАНИИ VENTOY!)" 20 80 10 "${DLG_MODE_MOUNT_DISK}"`
}

function dlg_hostname() {
    echo `dialog --stdout --title "Параметры подключения к домену" --inputbox "Имя машины (не более 15 символов!):" 10 60 "$MACHINE_NAME"`
}

function dlg_domain_params() {
    echo \
    `dialog --stdout --title "Параметры подключения к домену" --inputbox "IP-адрес контроллера домена:" 10 60 "$DOMAIN_IP"` \
    `dialog --stdout --title "Параметры подключения к домену" --inputbox "Имя контроллера домена:" 10 60 "$DOMAIN_NAME"` \
    `dialog --stdout --title "Параметры подключения к домену" --inputbox "Логин для входа в домен:" 10 60 "$DOMAIN_USER"`
}

function dlg_select_mode(){
DLG_SELECT_MODE_OPTIONS="NONE Выберите on BACKUP Создание_резервной_копии off RESTORE Восстановление_из_резервной_копии off"
echo `dialog --stdout --title "Выбор режима работы" --radiolist "Выберите режим" 10 60 10 ${DLG_SELECT_MODE_OPTIONS}`
}

function dlg_select_root_device(){
DLG_SELECT_ROOT_DEVICE_OPTIONS=$(lsblk -l -o NAME -n | grep -E '^sd|^hd|^vd|^nvme' | awk {'print "/dev/" $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор диска-источника" --radiolist "Выберите раздел (том) с корневой файловой системой" 20 60 10 ${DLG_SELECT_ROOT_DEVICE_OPTIONS}`
}

function dlg_select_root_device_dst(){
DLG_SELECT_ROOT_DEVICE_OPTIONS=$(lsblk -o NAME -n | grep -E '^sd|^hd|^vd|^nvme' | awk {'print "/dev/" $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор диска-назначения" --radiolist "Выберите диск для развёртывания (!ОСТОРОЖНЕЕ С ВЫБОРОМ ПРИ ИСПОЛЬЗОВАНИИ VENTOY!)" 20 70 10 ${DLG_SELECT_ROOT_DEVICE_OPTIONS}`
}

function dlg_efi_or_legacy() {
DLG_EFI_OR_LEGACY_OPTIONS="BIOS BIOS(legacy) on EFI EFI(new) off"
echo `dialog --stdout --title "Выбор режима сохранения" --radiolist "При выборе EFI(new) будет необходимо выбрать устройство с EFI" 10 60 10 ${DLG_EFI_OR_LEGACY_OPTIONS}`
}

function dlg_efi_or_legacy_dst() {
DLG_EFI_OR_LEGACY_OPTIONS="BIOS BIOS(legacy) on EFI EFI(new) off"
echo `dialog --stdout --title "Выбор режима восстановления" --radiolist "Выберите режим развёртывания" 10 60 10 ${DLG_EFI_OR_LEGACY_OPTIONS}`
}

function dlg_select_efi_device(){
DLG_SELECT_EFI_DEVICE_OPTIONS=$(lsblk -l -o NAME -n | grep -E '^sd|^hd|^vd|^nvme' | awk {'print "/dev/" $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор диска-источника " --radiolist "Выберите раздел (том) с EFI" 20 60 10 ${DLG_SELECT_EFI_DEVICE_OPTIONS}`
}

function dlg_select_dest_dir(){
default_dir_name="BACKUP_$(date +%Y_%m_%d__%H_%M_%S)"
echo `dialog --stdout --title "Задайте каталог резервной копии на FTP-сервере (префикс 'BACKUP_' в имени нужно сохранять!)" --inputbox "${FTP_URL}" 10 60 "${default_dir_name}"`
}

function dlg_select_dest_dir_disk(){
default_dir_name="BACKUP_$(date +%Y_%m_%d__%H_%M_%S)"
echo `dialog --stdout --title "Задайте каталог резервной копии на диске (префикс 'BACKUP_' в имени нужно сохранять!)" --inputbox "${DISK_MNTPNT}" 10 60 "${default_dir_name}"`
}

function dlg_select_backup() {
DLG_SELECT_BACKUP_OPTIONS=$(ls ${FTP_MNTPNT} | grep -E '^BACKUP' | awk {'print $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор резервной копии " --radiolist "Выберите резервную копию" 20 110 10 ${DLG_SELECT_BACKUP_OPTIONS}`
}

function dlg_select_backup_disk(){
DLG_SELECT_BACKUP_DISK_OPTIONS=$(ls ${DISK_MNTPNT} | grep -E '^BACKUP' | awk {'print $1 " " $1 " off"'} | tr '\n' ' ')
echo `dialog --stdout --title "Выбор резервной копии " --radiolist "Выберите резервную копию" 20 110 10 ${DLG_SELECT_BACKUP_DISK_OPTIONS}`
}

function dlg_message(){
TITLE=$1
MESSAGE=$2
echo `dialog --stdout --title "${TITLE}" --infobox "${MESSAGE}" 10 60`
}

function mode_backup(){

if [ "$DLG_STORE_MODE" = "LOCAL" ]; then
  # LOCAL
  BACKUP_DST_DIR_NAME=$(dlg_select_dest_dir_disk)
  RESULT_BACKUP_DIR="Наблюдайте за файлами в каталоге:\n${DISK_MNTPNT}/${BACKUP_DST_DIR_NAME}"
  backup_dir="${DISK_MNTPNT}/${BACKUP_DST_DIR_NAME}"
else
  # FTP
  BACKUP_DST_DIR_NAME=$(dlg_select_dest_dir)
  RESULT_BACKUP_DIR="Наблюдайте за файлами в каталоге:\n${FTP_URL}/${BACKUP_DST_DIR_NAME}"
  backup_dir="${FTP_MNTPNT}/${BACKUP_DST_DIR_NAME}"
fi

[ -d "${backup_dir}" ] || mkdir ${backup_dir}

BACKUP_MODE=$(dlg_efi_or_legacy)
BACKUP_SRC_ROOT=$(dlg_select_root_device)

if [ "${BACKUP_MODE}" = "EFI" ]; then
BACKUP_SRC_EFI=$(dlg_select_efi_device)
efi_mntpnt="/mnt/efi_mntpnt"
[ -d ${efi_mntpnt} ] && umount ${efi_mntpnt}
[ -d ${efi_mntpnt} ] && /bin/rm -r ${efi_mntpnt}
[ -d ${efi_mntpnt} ] || mkdir ${efi_mntpnt}
mount ${BACKUP_SRC_EFI} ${efi_mntpnt}
fi

root_mntpnt="/mnt/root_mntpnt"
[ -d ${root_mntpnt} ] && umount ${root_mntpnt}
[ -d ${root_mntpnt} ] && /bin/rm -r ${root_mntpnt}
[ -d ${root_mntpnt} ] || mkdir ${root_mntpnt}
mount ${BACKUP_SRC_ROOT} ${root_mntpnt}

dlg_message "Информация" "Идёт резервное копирование...\n\n${RESULT_BACKUP_DIR}"
cd ${root_mntpnt} && tar -czpf ${backup_dir}/root.tgz .
cd
umount ${root_mntpnt}
if [ "${BACKUP_MODE}" = "EFI" ]; then
cd ${efi_mntpnt} && tar -czpf ${backup_dir}/efi.tgz .
cd
umount ${efi_mntpnt}
fi

dlg_message "Информация" "Резервное копирование завершено\n\nДля продолжения нажмите любую клавишу..."
read
}

function mode_restore(){



  if [ "$DLG_STORE_MODE" = "LOCAL" ]; then
    # LOCAL
    BACKUP_NAME=$(dlg_select_backup_disk)
    backup_dir="${DISK_MNTPNT}/${BACKUP_NAME}"
  else
    # FTP
    BACKUP_NAME=$(dlg_select_backup)
    backup_dir="${FTP_MNTPNT}/${BACKUP_NAME}"
  fi



  RESTORE_MODE=$(dlg_efi_or_legacy_dst)

  BACKUP_DST=$(dlg_select_root_device_dst)
  BACKUP_DST_PARTITION_SUFFIX=""
  [[ ${BACKUP_DST} == /dev/nvme* ]] && BACKUP_DST_PARTITION_SUFFIX="p"

  dialog --stdout --title "Ввод в домен" --yesno "Ввести рабочую станцию в домен после развёртывания?" 10 60
  IS_GO_IN_DOMAIN=$?

  MACHINE_HOST_NAME=$(dlg_hostname)

  if [ ${IS_GO_IN_DOMAIN} -eq 0 ]; then
    DOMAIN_DATA=$(dlg_domain_params)
    DOMAIN_IP=$(echo ${DOMAIN_DATA} | awk {'print $1'})
    DOMAIN_NAME=$(echo ${DOMAIN_DATA} | awk {'print $2'})
    DOMAIN_USER=$(echo ${DOMAIN_DATA} | awk {'print $3'})
    DOMAIN_PASSWORD
  fi

  dlg_message "Информация" "Очистка и разметка диска, создание файловых систем..."

  # очистка диска
  wipefs -af ${BACKUP_DST}
  # разметка диска

  if [ "${RESTORE_MODE}" = "EFI" ]; then
gdisk ${BACKUP_DST} << EOF
o
Y
n


+256M


n


+2G

n




w
Y
EOF
  #создание файловых систем
  mkfs.fat "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1"
  mkswap "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2"
  mkfs.ext4 -F "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}3"
else
fdisk ${BACKUP_DST} << EOF
o
n



+2G
Yes
n




w
EOF
  #создание файловых систем
  mkswap "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1"
  mkfs.ext4 -F "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2"
fi

  if [ "${RESTORE_MODE}" = "EFI" ]; then
  dlg_message "Информация" "Идёт распаковка EFI раздела..."
  efi_mntpnt="/mnt/efi_mntpnt"
  [ -d ${efi_mntpnt} ] && umount ${efi_mntpnt}
  [ -d ${efi_mntpnt} ] && /bin/rm -r ${efi_mntpnt}
  [ -d ${efi_mntpnt} ] || mkdir ${efi_mntpnt}
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1" ${efi_mntpnt}
  cd ${efi_mntpnt}
  echo "#$(pwd)" >> /tmp/e1
  echo "tar -xzpf ${backup_dir}/efi.tgz" >> /tmp/e1
  tar -xzpf ${backup_dir}/efi.tgz
  if [ $? -ne '0' ]; then
    dlg_message "Ошибка!" "Ошибка при распаковке EFI раздела"
    read
    exit 1
  fi

  cd
  umount ${efi_mntpnt}

  dlg_message "Информация" "Идёт распаковка корневого раздела..."
  root_mntpnt="/mnt/root_mntpnt"
  [ -d ${root_mntpnt} ] && umount ${root_mntpnt}
  [ -d ${root_mntpnt} ] && /bin/rm -r ${root_mntpnt}
  [ -d ${root_mntpnt} ] || mkdir ${root_mntpnt}
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}3" ${root_mntpnt}
  cd ${root_mntpnt}
  echo "#$(pwd)" >> /tmp/e2
  echo "tar -xzpf ${backup_dir}/root.tgz" >> /tmp/e2
  tar -xzpf ${backup_dir}/root.tgz
  if [ $? -ne '0' ]; then
    dlg_message "Ошибка!" "Ошибка при распаковке корневого раздела"
    read
    exit 1
  fi
  cd
  umount ${root_mntpnt}
  else
  dlg_message "Информация" "Идёт распаковка корневого раздела..."
  root_mntpnt="/mnt/root_mntpnt"
  [ -d ${root_mntpnt} ] && umount ${root_mntpnt}
  [ -d ${root_mntpnt} ] && /bin/rm -r ${root_mntpnt}
  [ -d ${root_mntpnt} ] || mkdir ${root_mntpnt}
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2" ${root_mntpnt}
  cd ${root_mntpnt}
  tar -xzpf ${backup_dir}/root.tgz
  cd
  umount ${root_mntpnt}
  fi

  dlg_message "Информация" "Выполняется настройка системы и установка загрузчика..."

if [ "${RESTORE_MODE}" = "EFI" ]; then
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}3" ${root_mntpnt}
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1" ${root_mntpnt}/boot/efi
else
  mount "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2" ${root_mntpnt}
fi

cat << EOF > ${root_mntpnt}/etc/hostname
${MACHINE_HOST_NAME}
EOF

cat << EOF > ${root_mntpnt}/etc/sysconfig/network
# When set to no, this may cause most daemons' initscripts skip starting.
NETWORKING=yes

# Used by hotplug/pcmcia/ifplugd scripts to detect current network config
# subsystem.
CONFMETHOD=etcnet

# Used by rc.sysinit to setup system hostname at boot.
HOSTNAME=${MACHINE_HOST_NAME}

# This is used by ALTLinux ppp-common to decide if we want to install
# nameserver lines into /etc/resolv.conf or not.
RESOLV_MODS=yes
EOF

if [ "${RESTORE_MODE}" = "EFI" ]; then
  UUID_EFI=$(blkid | grep "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1" | awk {'print $3'} | awk -F '=' {'print $2'} | sed 's/"//g')
  UUID_SWAP=$(blkid | grep "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2" | awk {'print $2'} | awk -F '=' {'print $2'} | sed 's/"//g')
  UUID_ROOT=$(blkid | grep "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}3" | awk {'print $2'} | awk -F '=' {'print $2'} | sed 's/"//g')

cat << EOF > ${root_mntpnt}/etc/fstab
proc		/proc			proc	nosuid,noexec,gid=proc		0 0
devpts		/dev/pts		devpts	nosuid,noexec,gid=tty,mode=620	0 0
tmpfs		/tmp			tmpfs	nosuid				0 0
UUID=${UUID_ROOT}	/	ext4	relatime	1 1
UUID=${UUID_EFI}	/boot/efi	vfat	umask=0,quiet,showexec,iocharset=utf8,codepage=866	1	2
UUID=${UUID_SWAP}	swap	swap	defaults	0 0
EOF
else
  UUID_SWAP=$(blkid | grep "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}1" | awk {'print $2'} | awk -F '=' {'print $2'} | sed 's/"//g')
  UUID_ROOT=$(blkid | grep "${BACKUP_DST}${BACKUP_DST_PARTITION_SUFFIX}2" | awk {'print $2'} | awk -F '=' {'print $2'} | sed 's/"//g')

cat << EOF > ${root_mntpnt}/etc/fstab
proc		/proc			proc	nosuid,noexec,gid=proc		0 0
devpts		/dev/pts		devpts	nosuid,noexec,gid=tty,mode=620	0 0
tmpfs		/tmp			tmpfs	nosuid				0 0
UUID=${UUID_ROOT}	/	ext4	relatime	1 1
UUID=${UUID_SWAP}	swap	swap	defaults	0 0
EOF
fi

cat << EOF > ${root_mntpnt}/etc/default/grub
GRUB_AUTOUPDATE_CFG=true
GRUB_AUTOUPDATE_CFGNAME=/boot/grub/grub.cfg
GRUB_VMLINUZ_SYMLINKS=default
GRUB_VMLINUZ_FAILSAFE=default
GRUB_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_CMDLINE_LINUX_DEFAULT=' usbcore.autosuspend=-1 resume=/dev/disk/by-uuid/${UUID_SWAP} panic=30 quiet loglevel=3 splash'
GRUB_CMDLINE_LINUX='failsafe vga=normal'
GRUB_TERMINAL_OUTPUT='gfxterm'
GRUB_GFXMODE='auto'
GRUB_DEFAULT='saved'
GRUB_SAVEDEFAULT=true
GRUB_BACKGROUND=
GRUB_WALLPAPER=
GRUB_COLOR_NORMAL=white/black
GRUB_COLOR_HIGHLIGHT=black/white
GRUB_DISTRIBUTOR="ALT Linux"
GRUB_BOOTLOADER_ID="altlinux"
GRUB_THEME=/boot/grub/themes/starterkit/theme.txt
EOF

  mount -t proc /proc ${root_mntpnt}/proc
  mount -t sysfs /sys ${root_mntpnt}/sys
  mount --bind /dev/ ${root_mntpnt}/dev

#chroot
chroot ${root_mntpnt}/  << EOF
kernel_version=$(ls -la /boot/vmlinuz | awk {'print $11'} | sed 's/vmlinuz-//g')
make-initrd -k ${kernel_version}
grub-install ${BACKUP_DST}
update-grub
EOF

if [ ${IS_GO_IN_DOMAIN} -eq 0 ]; then
  dlg_message "Информация" "Подготавливается скрипт для ввода компьютера в домен..."

DOMAIN_NAME_SHORT=$(echo ${DOMAIN_NAME} | awk -F '.' {'print $1'})

cat << EOF > ${root_mntpnt}/usr/bin/go2domain
#!/bin/bash
read -p "Enter password from SAMBA DC user '${DOMAIN_USER}':" -s pass
if [ -z $pass ]; then
echo "Password is empty. Exit."
exit 1
fi

ntpdate pool.ntp.org
realm leave ${DOMAIN_NAME} ${DOMAIN_USER}
system-auth write ad ${DOMAIN_NAME} ${MACHINE_HOST_NAME} ${DOMAIN_NAME_SHORT} ${DOMAIN_USER} '${pass}'
#apt-get install -y gpupdate alterator-auth alterator-gpupdate
gpupdate-setup write enable workstation
EOF

  chmod +x ${root_mntpnt}/usr/bin/go2domain

  sleep 3

  dlg_message "Информация" "Для ввода компьютера в домен после загрузки системы\nвыполните от суперпользователя команду:\n\ngo2domain\n\nЗатем перезагрузите компьютер\n\nДля продолжения нажмите любую клавишу..."

  read

fi

  # umount
  cd
  umount ${root_mntpnt}/proc
  umount ${root_mntpnt}/sys
  umount ${root_mntpnt}/dev
  umount ${root_mntpnt}/boot/efi
  umount ${root_mntpnt}

  dlg_message "Информация" "Развёртывание системы завершено\n\nДля продолжения нажмите любую клавишу..."
  read
}

function free_drive() {
  image_mntpnt=$(df | grep image | awk {'print $6'})
  if [ "$image_mntpnt" = "/image" ]; then
    dlg_message "Информация" "Освобождаем загрузочный носитель..."
    sleep 1
    umount /image
    dlg_message "Информация" "Освобождаем загрузочный носитель. Готово."
    sleep 1
  fi
}

#### конец определения функций ####

#### начало определения основной логики ####

# выбрасываем диск
free_drive

# настраиваем сеть
DLG_NETWORK_MODE=$(dlg_network_mode)
if [ "$DLG_NETWORK_MODE" = "DHCP" ]; then
  dlg_message "Информация" "Получаем настройки сети автоматически..."
  killall dhcpcd
  dhcpcd
  sleep 2
elif [ "$DLG_NETWORK_MODE" = "STATIC" ]; then
  dlg_message "Информация" "Настраиваем сеть вручную..."
  DATA=$(dlg_network_setup)
  DEV=$(echo $DATA | awk {'print $1'})
  IPMASK=$(echo $DATA | awk {'print $2'})
  GW=$(echo $DATA | awk {'print $3'})
  ifconfig ${DEV} down
  ifconfig ${DEV} up
  ifconfig ${DEV} ${IPMASK}
  [ -z "${GW}" ] || ip ro del default;ip ro add default via ${GW}
  sleep 2

  DLG_DHCPSRV_SETUP=$(dlg_dhcpsrv_setup)
  if [ "$DLG_DHCPSRV_SETUP" = "YES" ]; then
    IFACE=$(dlg_mode_udpcast_get_iface)
    IP_BASE=`ifconfig ${IFACE} | head -2 | tail -1 | sed 's/:/ /g' | awk {'print $3'} | awk -F '.' {'print $1"."$2"."$3'}`
    SUBNET_IP="${IP_BASE}.0"
    RANGE_FROM="${IP_BASE}.10"
    RANGE_TO="${IP_BASE}.210"
    ROUTE_AND_DNS="${IP_BASE}.1"
    NETMASK=`ifconfig ${IFACE} | head -2 | tail -1 | sed 's/:/ /g' | awk {'print $7'}`

cat << EOF > /etc/dhcp/dhcpd.conf
ddns-update-style none;
subnet ${SUBNET_IP} netmask ${NETMASK} {
	option routers			${ROUTE_AND_DNS};
	option subnet-mask		${NETMASK};
	option domain-name-servers	${ROUTE_AND_DNS};
	range ${RANGE_FROM} ${RANGE_TO};
	default-lease-time 43200;
	max-lease-time 86400;
}
EOF

    killall dhcpcd
    ifconfig ${IFACE} down
    ifconfig ${IFACE} up
    killall dhcpd
    dhcpd -cf /etc/dhcp/dhcpd.conf
    dlg_message "Информация" "Запущен DHCP сервер\n\nДля продолжения нажмите любую клавишу..."
    read
  else
    dlg_message "Информация" "Запуск DHCP сервера пропущен\n\nДля продолжения нажмите любую клавишу..."
    read
  fi

else
  dlg_message "Информация" "Настройка сети не производилась\n\nДля продолжения нажмите любую клавишу..."
  read
fi

# выбираем режим работы
DLG_MODE=$(dlg_mode)
if [ "$DLG_MODE" = "UDPCAST" ]; then
# backup or restore start
UDPCAST_MODE=$(dlg_mode_udpcast)
IFACE=$(dlg_mode_udpcast_get_iface)

if [ "$UDPCAST_MODE" = "SEND" ]; then
  UDP_SRC=$(dlg_mode_udpcast_get_src)
  dlg_message "Запущен процесс посылатора (udp-sender). Наблюдайте за выводом команды..."
  /usr/sbin/udp-sender --interface ${IFACE} --pipe '/bin/gzip -c -' -f ${UDP_SRC} > /dev/console 2>&1
elif [ "$UDPCAST_MODE" = "RECEIVE" ]; then
  UDP_DST=$(dlg_mode_udpcast_get_dst)
  dlg_message "Запущен процесс приниматора (udp-receiver). Наблюдайте за выводом команды..."
  /usr/sbin/udp-receiver --interface ${IFACE} --pipe '/bin/gzip -d -c -' -f ${UDP_DST} > /dev/console 2>&1
else
  dlg_message "ОШИБКА!" "Отменено пользователем\n\nДля продолжения нажмите любую клавишу..."
  read
  exit 1
fi

# backup or restore end
elif [ "$DLG_MODE" = "BACKUPRESTORE" ]; then
# backup or restore start
DLG_STORE_MODE=$(dlg_store_mode)
if [ "$DLG_STORE_MODE" = "LOCAL" ]; then
  echo "local"
   DISK_DEV=$(dlg_mount_disk)
   DISK_MNTPNT="/mnt/disk"
   [ -d ${DISK_MNTPNT} ] || mkdir ${DISK_MNTPNT}
   umount ${DISK_MNTPNT}
   mount ${DISK_DEV} ${DISK_MNTPNT}
   if [ $? -ne '0' ]; then
       dlg_message "Ошибка!" "Ошибка монтирования хранилища\n\nДля продолжения нажмите любую клавишу..."
       read
       exit 1
   fi
  dlg_message "Информация" "Хранилище смонтировано\n\nДля продолжения нажмите любую клавишу..."
  read
elif [ "$DLG_STORE_MODE" = "FTP" ]; then
  echo "ftp"
  # подключаемся к FTP-серверу
  DLG_MOUNT_DATA=$(dlg_mount)
  H=`echo $DLG_MOUNT_DATA | awk {'print $1'}`
  L=`echo $DLG_MOUNT_DATA | awk {'print $2'}`
  P=`echo $DLG_MOUNT_DATA | awk {'print $3'}`
  D=`echo $DLG_MOUNT_DATA | awk {'print $4'}`
  FTP_URL="ftp://${L}:${P}@${H}${D}"
  FTP_MNTPNT="/mnt/ftp"

  [ -d ${FTP_MNTPNT} ] || mkdir ${FTP_MNTPNT}
  umount ${FTP_MNTPNT}
  curlftpfs ${FTP_URL} ${FTP_MNTPNT}
  if [ $? -ne '0' ]; then
    dlg_message "Ошибка!" "Ошибка монтирования FTP-ресурса\n\nДля продолжения нажмите любую клавишу..."
    read
    exit 1
  fi

  dlg_message "Информация" "FTP-ресурс смонтирован\n\nДля продолжения нажмите любую клавишу..."
  read
else
  dlg_message "ОШИБКА!" "Отменено пользователем\n\nДля продолжения нажмите любую клавишу..."
  read
  exit 1
fi

dlg_message "Информация" "Хранилище выбрано\n\nДля продолжения нажмите любую клавишу..."
read

# выбираем режим работы
MODE=$(dlg_select_mode)
if [ "$MODE" = "BACKUP" ]; then
  dlg_message "Информация" "Выбран режим создания резервной копии\n\nДля продолжения нажмите любую клавишу..."
  read
  mode_backup
elif [ "$MODE" = "RESTORE" ]; then
  dlg_message "Информация" "Выбран режим восстановления из резервной копии\n\nДля продолжения нажмите любую клавишу..."
  read
  mode_restore
elif [ "$MODE" = "NONE" ]; then
  dlg_message "ОШИБКА!" "Нужно обязательно выбрать один из режимов:\n\t(BACKUP или RESTORE)!\n\nДля продолжения нажмите любую клавишу..."
  read
  exit 1
else
  dlg_message "ОШИБКА!" "Отменено пользователем\n\nДля продолжения нажмите любую клавишу..."
  read
  exit 1
fi
# backup or restore end
else
  dlg_message "ОШИБКА!" "Отменено пользователем\n\nДля продолжения нажмите любую клавишу..."
  read
  exit 1
fi

#### конец определения основной логики ####

exit 0