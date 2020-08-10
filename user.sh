#!/bin/bash

echo "
###############################################################################
# PGP
###############################################################################
"
# Create gpg db
gpg --list-keys

# Packages signature checking
echo "keyserver-options auto-key-retrieve" >> .gnupg/gpg.conf
echo "keyserver hkp://pgp.mit.edu" >> .gnupg/gpg.conf

echo "
###############################################################################
# User packages
###############################################################################
"

function install_aur {
	for ARG in "$@"
	do
		if ! command -v $ARG; then
			git clone https://aur.archlinux.org/${ARG}.git
			cd $ARG
			makepkg -sri --noconfirm
		fi
	done
}

# Install AUR packages
install_aur yay 

# Install more fonts
# ttf-lato ttf-paratype ttf-clear-sans ttf-fira-mono ttf-monaco
