#!/bin/bash

HOSTNAME="MyArch"
USERNAME="fewcm"
TIMEZONE="Asia/Kuala_Lumpur"
LANGUAGE="en_US.UTF-8"

# To determine DRIVE, inspect output of
# $ lsblk
DRIVE=/dev/sda
MOUNT_PATH=/mnt
USERSHELL=/bin/bash

# Test to see if operating in a chrooted environment. See
# http://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# for more information.
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then ### Not chrooted ###

# prepare disk
sgdisk --zap-all ${DRIVE}
sgdisk --set-alignment=2048 ${DRIVE}
sgdisk --clear ${DRIVE}

# Common Partitions Types
#   8300 Linux filesystem
#   8200 linux swap
#   fd00 linux raid
#   ef02 BIOS boot
#
# For more use 'sgdisk -L'.

# create partitions
sgdisk --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI System Partition" ${DRIVE} # partition 1 (EFI)
sgdisk --new=2:0:0     --typecode=2:8300 --change-name=2:"root" ${DRIVE} # partition 4 (Arch)

# format partitions
mkfs.fat -F32 ${DRIVE}1
mkfs.ext4 ${DRIVE}2


# mount partitions
mount ${DRIVE}2 ${MOUNT_PATH}
mkdir ${MOUNT_PATH}/boot && mount ${DRIVE}1 ${MOUNT_PATH}/boot

# install base system
pacstrap ${MOUNT_PATH} base base-devel arch-install-scripts b43-fwcutter broadcom-wl btrfs-progs clonezilla crda darkhttpd ddrescue dhclient dhcpcd dialog diffutils dnsmasq dnsutils dosfstools ethtool exfat-utils f2fs-tools fsarchiver gnu-netcat gpm gptfdisk hdparm ipw2100-fw ipw2200-fw irssi iwd jfsutils lftp linux-atm linux-firmware lsscsi lvm2 man-db man-pages mc mdadm mtools nano ndisc6 netctl nfs-utils nilfs-utils nmap ntfs-3g ntp openconnect openssh openvpn partclone parted partimage ppp pptpclient refind-efi reiserfsprogs rsync sdparm sg3_utils smartmontools sudo tcpdump testdisk usb_modeswitch usbutils vi vpnc wget wireless-regdb wireless_tools wpa_supplicant wvdial xfsprogs xl2tpd xorg-server xorg-xbacklight xorg-fonts-misc xorg-xfd xorg-xkill xorg-xrandr xorg-xrdb xf86-video-intel networkmanager nm-connection-editor
 obconf openbox adapta-gtk-theme alsa-plugins alsa-tools alsa-utils atril binutils bmon calc dunst fakeroot feh ffmpeg ffmpegthumbnailer gcc geany gparted gtk-engine-murrine gvfs gvfs-mtp htop imagemagick inetutils jq leafpad lxappearance lxdm-gtk3 make mpc mpd mplayer ncdu ncmpcpp neofetch nitrogen p7zip patch pkg-config plank polkit pulseaudio pulseaudio-alsa pv ranger scrot termite terminus-font-otb thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman ttf-dejavu tumbler udisks2 unrar unzip viewnior vim xarchiver xclip xdg-user-dirs xfce4-power-manager xfce4-settings xmlstarlet yad zip

# generate file system table
genfstab -p ${MOUNT_PATH} >> ${MOUNT_PATH}/etc/fstab

# prepare chroot script
cp ${0} ${MOUNT_PATH}

# change root
arch-chroot ${MOUNT_PATH} ${0}

# unmount drives
umount -R ${MOUNT_PATH}

# restart into new arch env
reboot
fi ### END chroot check ###

# Test to see if operating in a chrooted environment. See
# http://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# for more information.
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then

# Configure Hostname
echo ${HOSTNAME} > /etc/hostname
sed -i "s/localhost\.localdomain/${HOSTNAME}/g" /etc/hosts

# configure locale
sed -i "s/^#\(${LANGUAGE}.*\)$/\1/" "/etc/locale.gen";
locale-gen
echo LANG=${LANGUAGE} > /etc/locale.conf
export LANG=${LANGUAGE}
cat > /etc/vconsole.conf <<VCONSOLECONF
KEYMAP=${KEYMAP}
FONT=${FONT}
FONT_MAP=
VCONSOLECONF

# configure time
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo ${TIMEZONE} >> /etc/timezone

# Install and Configure Bootloader
pacman --noconfirm -S gdisk refind


# Generate Ram Disk
# Don't need this as the initial ramdisk is created during linux install
# mkinitcpio -p linux

# setup network
systemctl enable NetworkManager


# X Windows System
pacman --noconfirm -S xorg-server xorg-server-utils xorg-xinit xterm ttf-dejavu 

### User Configuration ###

# install and configure sudoers
pacman --noconfirm -S sudo
cp /etc/sudoers /tmp/sudoers.edit
# sed -i "s/#\s*\(%wheel\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
sed -i "s/#\s*\(%sudo\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
visudo -qcsf /tmp/sudoers.edit && cat /tmp/sudoers.edit > /etc/sudoers && groupadd sudo

# change root password
echo "Changing Root password:"
passwd

# create new user
echo "Set new user, ${USERNAME}, password:"
useradd -m -g users -G optical,storage,power,sudo,wheel -s ${USERSHELL} ${USERNAME}
passwd ${USERNAME}

# new usuer config x
echo "exec openbox-session" >> /home/${USERNAME}/.xinitrc
fi ### END chroot check ###
