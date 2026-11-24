# Yukinoshita Yukino GRUB theme

To install the theme and show only operating system entries in GRUB, run this from this directory:

```bash
sudo bash install.sh --os-only
```

The option hides UEFI Firmware Settings and filters entries imported from EFI. It recognizes common Linux and Windows EFI loader paths and uses `os-prober` to identify additional OS entries. Custom EFI loaders may be hidden if they go undetected. You can still access the firmware's own boot options through its boot menu.

Run `sudo bash install.sh` for a theme-only install. Running it without the flag does not undo a filter you already applied.

The single Arch entry with its icon comes from this machine's separate `/etc/grub.d/15_uki` customization. It boots the Arch unified kernel image with `--class arch`, which selects Yukino's `arch.png`. Its script runs before the EFI entry generator, so Arch appears first.
