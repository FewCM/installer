#!/bin/bash

# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
# To silent an error || true
set -euo pipefail
IFS=$'\n\t' 

if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
	set -x
fi

###############################################################################
# Questions part
###############################################################################

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "
You're about to install my basic user session.
Require a xf86-video driver, an internet connection, base and base-devel packages.
Please enter 'yes' to confirm:
"
read yes

# Confirm video driver
if [ "$yes" != "yes" ]; then
    echo "Please install a xf86-video driver"
	pacman -Ss xf86-video
    exit 1
fi

# Check internet connection
if ! [ "$(ping -c 1 8.8.8.8)" ]; then
    echo "Please check your internet connection"
    exit 1
fi

if ! source install.conf; then
	echo "
	Virtual box install?
	Please enter 'yes' to confirm, 'no' to reject:
	"
	read vbox_install

	echo "Please enter hostname:"
	read hostname

	echo "Please enter username:"
	read username

	echo "Please enter password:"
	read -s password

	echo "Please repeat password:"
	read -s password2

	# Check both passwords match
	if [ "$password" != "$password2" ]; then
	    echo "Passwords do not match"
	    exit 1
	fi

	echo "Please enter full name:"
	read fullname

	echo "Please enter email:"
	read email
fi

if ! [ -z ${proxy:+x} ]; then
	export http_proxy=$proxy
	export https_proxy=$http_proxy
	export ftp_proxy=$http_proxy
fi

# Save current pwd
pwd=`pwd`

echo "
###############################################################################
# Pacman conf
###############################################################################
"
# Rankmirrors
pacman --noconfirm -S reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -c Singapore -f 10 -p http --save /etc/pacman.d/mirrorlist

sed -i 's/^#Color/Color/' /etc/pacman.conf

# keyring conf
pacman --noconfirm -Syu haveged
systemctl --no-ask-password start haveged
systemctl --no-ask-password enable haveged

echo "
###############################################################################
# Install part
###############################################################################
"

pacman_packages=()

# Install linux headers
pacman_packages+=( linux-headers linux-firmware base base-devel arch-install-scripts b43-fwcutter broadcom-wl btrfs-progs clonezilla crda darkhttpd ddrescue dhclient dhcpcd dialog diffutils dnsmasq dnsutils dosfstools ethtool exfat-utils f2fs-tools fsarchiver gnu-netcat gpm gptfdisk hdparm ipw2100-fw ipw2200-fw irssi iwd jfsutils lftp linux-atm linux-firmware lsscsi lvm2 man-db man-pages mc mdadm mtools nano ndisc6 netctl nfs-utils nilfs-utils nmap ntfs-3g ntp openconnect openssh openvpn partclone parted partimage ppp pptpclient refind-efi reiserfsprogs rsync sdparm sg3_utils smartmontools sudo tcpdump testdisk usb_modeswitch usbutils vi vpnc wget wireless-regdb wireless_tools wpa_supplicant wvdial xfsprogs xl2tpd )

# Install X essentials
pacman_packages+=( xorg-xsetroot xorg-xset xorg-xrdb xorg-xrandr xorg-xprop xorg-xlsfont xorg-xfd xorg-server xorg-apps xorg-xinit xorg-fonts-misc dbus xsel acpi xbindkeys xorg-server xorg-xbacklight xorg-fonts-misc xorg-xfd xorg-xkill xorg-xrandr xorg-xrdb )

# Install font essentials
pacman_packages+=( cairo fontconfig freetype2 )

# Install linux fonts
pacman_packages+=( ttf-dejavu ttf-liberation ttf-inconsolata ttf-anonymous-pro ttf-ubuntu-font-family )

# Install google fonts
pacman_packages+=( ttf-droid ttf-roboto )

# Install bitmap fonts
pacman_packages+=( dina-font terminus-font tamsyn-font artwiz-fonts )

# Install admin tools
pacman_packages+=( xf86-video-intel sudo pacman-contrib pacmatic git zsh tmux openssh ntfs-3g sysstat ripgrep tree )

# Install network tools
pacman_packages+=( ifplugd wpa_actiond wpa_supplicant syncthing networkmanager nm-connection-editor)

# Install window manager
pacman_packages+=( openbox obconf slock dmenu libnotify dunst arc-gtk-theme arc-icon-theme papirus-icon-theme )

# Install dev tools
pacman_packages+=( vim editorconfig-core-c )

# Work tools
pacman_packages+=( nodejs npm rustup optipng )

# Install audio
pacman_packages+=( alsa-utils pulseaudio )

# Install useful apps
pacman_packages+=( keepass mpv mpd mpc vlc gimp firefox chromium scribus rtorrent weechat scrot feh )
pacman_packages+=( libreoffice-fresh thunar lxappearance unrar alsa-plugins alsa-tools alsa-utils atril binutils bmon calc dunst fakeroot feh ffmpeg ffmpegthumbnailer gcc geany gparted gtk-engine-murrine gvfs gvfs-mtp htop imagemagick inetutils jq leafpad lxappearance lxdm-gtk3 make mpc mpd mplayer ncdu ncmpcpp neofetch nitrogen p7zip patch pkg-config plank polkit pulseaudio pulseaudio-alsa pv ranger scrot termite terminus-font-otb thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman ttf-dejavu tumbler udisks2 unrar unzip viewnior vim xarchiver xclip xdg-user-dirs xfce4-power-manager xfce4-settings xmlstarlet yad zip )

pacman --noconfirm --needed -S  ${pacman_packages[@]}

# Better fonts rendering
ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d

chsh -s /bin/zsh

# Install vbox guest addition
if [ "$vbox_install" == "yes" ]; then
pacman --noconfirm -S virtualbox-guest-modules
echo "vboxguest
vboxsf
vboxvideo
" > /etc/modules-load.d/virtualbox.conf
fi

echo "
###############################################################################
# Systemd part
###############################################################################
"
# Generate locales
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Set timezone
timedatectl --no-ask-password set-timezone Asia/Kuala_Lumpur

# Set NTP clock
timedatectl --no-ask-password set-ntp 1

# Set locale
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_COLLATE="C" LC_TIME="en_US.UTF-8"

# Set keymaps
localectl --no-ask-password set-keymap us

# Hostname
hostnamectl --no-ask-password set-hostname $hostname

# SSH
systemctl --no-ask-password enable sshd
systemctl --no-ask-password start sshd

echo "
###############################################################################
# Modules
###############################################################################
"
# Disable PC speaker beep
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

echo "
###############################################################################
# User part
###############################################################################
"
# Create user with home
if ! id -u $username; then
	useradd -m --groups users,wheel $username
	echo "$username:$password" | chpasswd
	chsh -s /bin/zsh $username
fi

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "
###############################################################################
# Install user
###############################################################################
"

cp ./install_user.sh /home/$username/

if [ -z ${proxy:+x} ]; then
	sudo -i -u $username ./install_user.sh
else
	sudo -i -u $username env http_proxy=$http_proxy https_proxy=$https_proxy ftp_proxy=$ftp_proxy ./install_user.sh
fi

echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Clean orphans pkg
if [[ ! -n $(pacman -Qdt) ]]; then
	echo "No orphans to remove."
else
	pacman -Rns $(pacman -Qdtq)
fi

# Replace in the same state
cd $pwd
echo "
###############################################################################
# Done
###############################################################################
"
