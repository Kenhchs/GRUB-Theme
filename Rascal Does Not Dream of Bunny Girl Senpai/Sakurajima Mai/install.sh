#!/bin/bash
# Modified version from Tela Theme [https://github.com/vinceliuice/grub2-themes]
# GRUB2 Theme


ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME="Mai"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

MAX_DELAY=20                                        # max delay for user to enter root password


#colors

CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"



# echo like ...  with  flag type  and display message  colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

usage() {
  printf 'Usage: %s [--os-only]\n' "${0##*/}"
  printf '  --os-only  Hide firmware and device entries from the GRUB menu.\n'
}

os_only=false
case "$#:${1-}" in
  0:) ;;
  1:--os-only) os_only=true ;;
  1:--help|1:-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

configure_os_only_menu() {
  local firmware_helper="$1" bootnext_helper="$2" backup_dir="$3"
  local filter

  if [[ -f "$bootnext_helper" ]]; then
    cp -p -- "$bootnext_helper" "$backup_dir/" || return 1
    filter=$(cat <<'GRUB_FILTER'
    # Mai OS-only EFI loader filter
    if [ -z "$efi_file" ]; then
        # Some efibootmgr versions print /\\EFI\\... instead of File(...).
        efi_file=$(printf '%s' "$devpath" | tr '\134A-Z' '/a-z' |
            sed -n 's|^.*)//\(efi/.*\.efi\)$|/\1|p')
    fi
    [ -n "$efi_file" ] || continue

    mai_known_loader=false
    case "$efi_file" in
        /efi/linux/*.efi | /efi/microsoft/boot/bootmgfw.efi | \
        */shim*.efi | */grub*.efi | */systemd-boot*.efi) mai_known_loader=true ;;
    esac
    if [ "$mai_known_loader" = false ] && [ -z "$OSPROBED" ]; then
        continue
    fi
    # End Mai OS-only EFI loader filter

GRUB_FILTER
)
    # Migrate previous filters and keep GRUB's self-boot check in place.
    if ! MAI_EFI_FILTER="$filter" awk '
      $0 == "    [ \"$label\" = \"ubuntu\" ] || continue" { next }
      /^    # Mai OS-only EFI filter$/ { legacy = 1 }
      /^    # If this entry boots an EFI file and os-prober results are available/ { legacy = 0 }
      legacy { next }
      /^    # Mai OS-only EFI loader filter$/ { managed = 1 }
      /^    # End Mai OS-only EFI loader filter$/ {
        managed = 0
        if (getline && $0 != "") print
        next
      }
      managed { next }
      /^    # Skip a firmware entry that boots this grub/ {
        anchors++
        print ENVIRON["MAI_EFI_FILTER"] "\n"
      }
      /^    if \[ -n "\$\{efi_file\}" \] && \[ -n "\$\{OSPROBED\}" \]/ ||
      /^    if \[ "\$mai_known_loader" = false \] && \[ -n "\$\{OSPROBED\}" \]/ {
        comparisons++
        print "    if [ \"$mai_known_loader\" = false ] && [ -n \"${OSPROBED}\" ]; then"
        next
      }
      { print }
      END { if (anchors != 1 || comparisons != 1 || managed || legacy) exit 1 }
    ' "$bootnext_helper" > "$backup_dir/filtered" ||
       ! sh -n "$backup_dir/filtered"; then
      echo "Could not identify the EFI entry filter in $bootnext_helper." >&2
      return 1
    fi
    cat "$backup_dir/filtered" > "$bootnext_helper" || return 1
  fi

  if [[ -f "$firmware_helper" ]]; then
    cp -p -- "$firmware_helper" "$backup_dir/" &&
      chmod a-x -- "$firmware_helper" || return 1
  fi
}

# Welcome message
  prompt -s "\n\t           *********************************\n\t           * Sakurajima Mai Bootloader Theme *\n\t           *********************************\n
                              GRUB Theme

                                  by

                           Andi Trisna Mukti \n \n"




# checking command availability
function has_command() {
  command -v $1 > /dev/null
}


prompt -i "Press enter to begin installation${CDEF}(automatically install after 10s) ${b_CWAR}:${CDEF}"
read -t10

#checking for root access
prompt -w "\n Checking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
  # Create themes directory if not exists
  prompt -i "\n Checking for the existence of themes directory...\n"
  [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
  mkdir -p "${THEME_DIR}/${THEME_NAME}"



  #copy theme
  prompt -i "\n Installing ${THEME_NAME} theme...\n"
  cp -a -- "$SCRIPT_DIR/${THEME_NAME}/." "${THEME_DIR}/${THEME_NAME}" || exit 1


  # Set theme
  prompt -i "\n Setting ${THEME_NAME} as default...\n"

  # Backup grub config
  cp -an /etc/default/grub /etc/default/grub.bak

  # Configure GRUB theme
  sed -i '/^GRUB_THEME=/d' /etc/default/grub
  echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub

  # Disable automatic boot timeout
  sed -i '/^GRUB_TIMEOUT=/d' /etc/default/grub
  echo "GRUB_TIMEOUT=-1" >> /etc/default/grub






  prompt -i "\n finalizing your installation ...\n \n."
  echo "Updating GRUB config..."
  grub_update=()
  if has_command update-grub; then
    grub_update=(update-grub)
  elif has_command grub-mkconfig; then
    grub_update=(grub-mkconfig -o /boot/grub/grub.cfg)
  elif has_command grub2-mkconfig; then
    if has_command zypper; then
      grub_update=(grub2-mkconfig -o /boot/grub2/grub.cfg)
    elif has_command dnf; then
      grub_update=(grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg)
    fi
  fi

  if (( ${#grub_update[@]} == 0 )); then
    prompt -e "Could not find a command to regenerate GRUB."
    exit 1
  fi

  if "$os_only"; then
    grub_helpers=/etc/grub.d
    backup_dir=$(mktemp -d) || exit 1
    if configure_os_only_menu "$grub_helpers/30_uefi-firmware" "$grub_helpers/31_efi_bootnext" "$backup_dir" &&
       "${grub_update[@]}"; then
      rm -r -- "$backup_dir"
    else
      for helper in 30_uefi-firmware 31_efi_bootnext; do
        if [[ -f "$backup_dir/$helper" ]] &&
           ! cp -p -- "$backup_dir/$helper" "$grub_helpers/"; then
          echo "Could not restore $helper. Backups are in $backup_dir." >&2
          exit 1
        fi
      done
      rm -r -- "$backup_dir"
      exit 1
    fi
  else
    "${grub_update[@]}" || exit 1
  fi

  # Success message
  prompt -s "\n\t            **************************\n\t            * Successfully Installed *\n\t            **************************\n"



else

  # Error message
  prompt -e "\n [ Error! ] -> Run me as root  \n \n "

fi









