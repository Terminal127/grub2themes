#!/bin/bash

# The Terminal - Grub2 Theme Installer (Tokyo Night Edition)
ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME="Animeholic2"
MAX_DELAY=20 # Max delay for user to enter root password

# Tokyo Night Colors
CDEF=$'\e[0m'
CCIN=$'\e[38;2;122;162;247m'  # #7aa2f7 - Bright blue
CGSC=$'\e[38;2;195;232;141m'  # #c3e88d - Light green
CRER=$'\e[38;2;255;117;127m'  # #ff757f - Soft red
CWAR=$'\e[38;2;255;199;119m'  # #ffc777 - Light orange
b_CDEF=$'\e[1;38;2;192;202;245m'  # #c0caf5 - Bold white
b_CCIN=$'\e[1;38;2;122;162;247m'  # #7aa2f7 - Bold bright blue
b_CGSC=$'\e[1;38;2;195;232;141m'  # #c3e88d - Bold light green
b_CRER=$'\e[1;38;2;255;117;127m'  # #ff757f - Bold soft red
b_CWAR=$'\e[1;38;2;255;199;119m'  # #ffc777 - Bold light orange

prompt() {
    case ${1} in
        "-s"|"--success")
            echo -e "${b_CGSC}${@/-s/}${CDEF}"
            ;;
        "-e"|"--error")
            echo -e "${b_CRER}${@/-e/}${CDEF}"
            ;;
        "-w"|"--warning")
            echo -e "${b_CWAR}${@/-w/}${CDEF}"
            ;;
        "-i"|"--info")
            echo -e "${b_CCIN}${@/-i/}${CDEF}"
            ;;
        *)
            echo -e "$@"
            ;;
    esac
}

# Welcome message
prompt -s "\n ${THEME_NAME} - Grub2 Theme Installer (Tokyo Night Edition) \n"

# Function to check command availability
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and get root access
get_root_access() {
    if [ "$UID" -ne "$ROOT_UID" ]; then
        prompt -w "Root access is required. Attempting to use sudo..."
        if has_command sudo; then
            exec sudo "$0" "$@"
        else
            prompt -e "Error: This script requires root access, but sudo is not available."
            exit 1
        fi
    fi
}

# Function to backup grub config
backup_grub_config() {
    local backup_file="/etc/default/grub.bak"
    if [ ! -f "$backup_file" ]; then
        cp -an /etc/default/grub "$backup_file"
        prompt -s "Grub config backed up to $backup_file"
    else
        prompt -i "Backup already exists at $backup_file"
    fi
}

# Function to update grub config
update_grub_config() {
    local grub_file="/etc/default/grub"
    local theme_path="${THEME_DIR}/${THEME_NAME}/theme.txt"
    
    sed -i '/GRUB_THEME=/d' "$grub_file"
    echo "GRUB_THEME=\"$theme_path\"" >> "$grub_file"
    prompt -s "Grub config updated with new theme"
}

# Function to detect and update grub
update_grub() {
    if has_command update-grub; then
        update-grub
    elif has_command grub-mkconfig; then
        grub-mkconfig -o /boot/grub/grub.cfg
    elif has_command zypper || has_command transactional-update; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    elif has_command dnf || has_command rpm-ostree; then
        if [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
            prompt -s "Found config file at /boot/efi/EFI/fedora/grub.cfg"
            grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        elif [[ -f /boot/grub2/grub.cfg ]]; then
            prompt -s "Found config file at /boot/grub2/grub.cfg"
            grub2-mkconfig -o /boot/grub2/grub.cfg
        else
            prompt -e "Unable to locate grub config file"
            return 1
        fi
    else
        prompt -e "Unsupported distribution. Unable to update grub."
        return 1
    fi
    prompt -s "Grub configuration updated successfully"
}

# Main execution
get_root_access

prompt -i "Checking for the existence of themes directory..."
if [[ -d ${THEME_DIR}/${THEME_NAME} ]]; then
    prompt -w "Existing theme directory found. Removing..."
    rm -rf "${THEME_DIR:?}/${THEME_NAME}"
fi
mkdir -p "${THEME_DIR}/${THEME_NAME}"

prompt -i "Installing ${THEME_NAME} theme..."
cp -a ${THEME_NAME}/* "${THEME_DIR}/${THEME_NAME}"

prompt -i "Setting ${THEME_NAME} as default..."
backup_grub_config
update_grub_config

prompt -i "Updating grub config..."
if update_grub; then
    prompt -s "\nTheme installation completed successfully!"
else
    prompt -e "\nAn error occurred during grub update. Please check your system configuration."
fi
