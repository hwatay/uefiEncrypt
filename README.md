# Encrypted Arch-Linux Installation Script

Description:

      A bash script to automate an UEFI encrypted arch-Linux installation perfect for hiding/securing anything :), was originally intended for virtual machines easier but can also be used on bare metal. Please read the script and attempt to grasp each step as it has the potential to permanently wipe your drive, refer to the Arch Wiki if you are unclear. The very first line starts a wipe of the given drive (sda) with random bits of data to thwart forensic analysis. If you intend to install on another disk other than /dev/sda please modify the script accordingly. 

  Usage:
   • Git Clone the script
   • Download Arch Iso and boot off Arch ISO (https://www.archlinux.org/download/)
   • Transfer script to system via  scp,ftp,usb etc.
   • Make Sure to edit the bash variables for username hostname in lines 3 & 4 
   • ./uefiEncrypt.sh

Note: For virtual machines ensure that UEFI is configured properly. For VMware Workstation in particular this means editing the .vmx file of the virtual machine with a given text editor and adding the line.

firmware=”efi”

Enjoy!

