#!/bin/bash -v
#Variables
USR="usernamegoeshere"
MYHOSTNAME="hostnamegoeshere"
#Bash Script to automate Encrypted ArchLinux Insallation UEFI systems
#Installation script will install git,vim,zsh by default
#Utilizes LVM on LUKS methold | Cipher = aes-xts-plain 64 | Hashtype = sha512, keysize = 512 |

dd if=/dev/urandom of=/dev/sda bs=1M

timedatectl set-ntp true
#Paritions via fdisk
(
echo n
echo p
echo 1
echo 
echo +256M
echo t
echo ef
echo n
echo p
echo 2
echo 
echo 
echo a
echo 1
echo p
echo w
echo q
) | fdisk /dev/sda
#Format Paritions
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

#Setup Encryption
cryptsetup -v -y -c aes-xts-plain64 -s 512 -h sha512 -i 5000 --use-random luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 system

#Create Encrypted Partitions  /home /root /swap
pvcreate /dev/mapper/system
vgcreate vg0 /dev/mapper/system
lvcreate --size 4G vg0 --name swap
lvcreate --size 8G vg0 --name root
lvcreate -l +100%FREE vg0 --name home

#Format Encrypted Filesystem
mkfs.ext4 /dev/mapper/vg0-root
mkfs.ext4 /dev/mapper/vg0-home
mkswap /dev/mapper/vg0-swap

#Mount the new filesystem
mount /dev/mapper/vg0-root /mnt # /mnt is the installed system
mkdir /mnt/home
mount /dev/mapper/vg0-home /mnt/home
swapon /dev/mapper/vg0-swap # Not needed but a good thing to test
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

#Install Arch (technically all you need is base,grub,efibootmgr these are just here to make life easier)
pacstrap /mnt base base-devel grub-efi-x86_64 zsh vim git efibootmgr dialog wpa_supplicant

#fstab
genfstab -pU /mnt >> /mnt/etc/fstab
#this is where i would add ssd optmizations

#optmized lvmetad.socket
mkdir /mnt/hostrun
mount --bind /run /mnt/hostrun

cat <<EOF >/mnt/root/part2.sh

mkdir /run/lvm
mount --bind /hostrun/lvm /run/lvm

ln -s /usr/share/zoneinfo/Canada/Central 
hwclock --systohc --utc 

#Hostname + locale 
echo $MYHOSTNAME > /etc/hostname 
echo LANG=en_US.UTF-8 >> /etc/locale.conf 
sed -ie 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 
#Set up root password 
passwd 

#Set up regular user
useradd -m -g users -G wheel -s /bin/zsh $USR 
passwd $USR 

# Configure mkinitcpio with modules needed for the initrd image

# Regenerate initrd image
sed -ie 's/HOOKS="base udev autodetect modconf block filesystems keyboard fsck"/HOOKS="base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck"/' /etc/mkinitcpio.conf 
mkinitcpio -p linux 

sed -ie 's@GRUB_CMDLINE_LINUX=""@GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:system"@' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg 
# Setup grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux 
#sed -ie 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice"=/dev/sda2:system resume=/dev/mappervg-swap"/' /etc/default/grub 

# Final Steps 
exit
EOF
chmod 777 /mnt/root/part2.sh
arch-chroot /mnt /root/part2.sh
umount -R /mnt
swapoff -a
reboot
