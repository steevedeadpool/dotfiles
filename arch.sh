#!/usr/bin/env bash
lsblk
echo
echo "Enter EFI patrtition example: sdX"
read disk
echo "Enter username"
read username
echo "MAKE SURE YOU HAVE INERNET CONNECTION"
echo "enter hostname"
read hostname



mkfs.fat -F32 /dev/${disk}2
mkfs.ext4 /dev/${disk}3
mkdir -p /mnt/usb
mount /dev/${disk}3 /mnt/usb
mkdir /mnt/usb/boot
mount /dev/${disk}2 /mnt/usb/boot

#installing base system

pacstrap /mnt/usb linux linux-firmware base nano --noconfirm --needed
genfstab -U /mnt/usb > /mnt/usb/etc/fstab
arch-chroot /mnt/usb

#working with locales

ln -sf /usr/share/zoneinfo/Asia/Novosibirsk /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
hwclock --systohc

#Host settings

echo $hostname > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	archlinux.localdomain	archlinux
EOF
#Root
echo "set root password"
passwd
#Bootloader
pacman -S grub efibootmgr
grub-install --target=i386-pc --recheck /dev/$disk
grub-install --target=x86_64-efi --efi-directory /boot --recheck --removable
grub-mkconfig -o /boot/grub/grub.cfg

#Networking
cat <<EOF > /etc/systemd/network/10-ethernet.network
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes

[DHCPv4]
RouteMetric=10

[IPv6AcceptRA]
RouteMetric=10
EOF
systemctl enable systemd-networkd.service
pacman -S iwd
systemctl enable iwd.service
cat <<EOF > /etc/systemd/network/20-wifi.network
[Match]
Name=wl*

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes

[DHCPv4]
RouteMetric=20

[IPv6AcceptRA]
RouteMetric=20
EOF
systemctl enable systemd-resolved.service
exit
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/usb/etc/resolv.conf
arch-chroot /mnt/usb
systemctl enable systemd-timesyncd.service 

#User

useradd -m $username
echo Enter user password
passwd $username
groupadd wheel
usermod -aG wheel $username
pacman -S sudo
echo %sudo ALL=(ALL) ALL > /etc/sudoers.d/10-sudo
groupadd sudo
usermod -aG sudo $username
pacman -S polkit
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

#journal
mkdir -p /etc/systemd/journald.conf.d
echo <<EOF > /etc/systemd/journald.conf.d/10-volatile.conf
[Journal]
Storage=volatile
SystemMaxUse=16M
RuntimeMaxUse=32M
EOF
echo "------------------------------------"
echo "base install compleated. good luck!"
echo "------------------------------------"