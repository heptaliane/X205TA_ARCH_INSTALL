#!/bin/bash

# ------
# This script is expected to be run by root user.
# Do not edit default eMMC partion.
# ------

# check your machine booted with UEFI.
EFI=`efivar -L`
if [ -z "$EFI" ]
then
    echo "This machine did not boot with UEFI mode. Check your machine"
fi

timedatactl set-ntp true

mkfs.ext4 /dev/mmcblk0p2
mkfs.vfat -F32 /dev/mmcblk0p1
mkswap /dev/mmcblk0p3
swapon /dev/mmcblk0p3
mount /dev/mmcblk0p2 /mnt
mkdir -p /mnt/boot
mount /dev/mmcblk0p1 /mnt/boot

SetMirrorlist () {
    mirrorlist="/etc/pacman.d/mirrorlist"
    backup="${mirrorlist}.bak"
    if [ ! -e $backup ]
    then
        cp $mirrorlist $backup
    fi

    arr=(`cat $backup`)
    echo "type your country. ( initial must be captalized. )"
    read region
    flag=0
    count=0

    for arg in ${arr[@]}
    do
        if [ $flag -eq 1 ]
        then
            if [[ $arg =~ ^http ]]
            then
                count=`expr $count + 1`
                server[$count]=$arg
                flag=0
            fi
        fi
        if [[ $arg =~ ^${region}$ ]]
        then
            flag=1
        fi
    done

    echo "$count server found."

    if [ $count -eq 0 ]
    then
        return 1
    fi

    echo "## servers in $region" > $mirrorlist

    for url in ${server[@]}
    do
        echo "Server = $url" >> $mirrorlist
    done

    echo "" >> $mirrorlist
    cat $backup >> $mirrorlist
}

FLAG=1
while [ $FLAG -eq 1 ]
do
    SetMirrorlist
    FLAG=$?
done

FLAG=1
while [ $FLAG -eq 1 ]
do
    ping -c 3 www.google.com
    FLAG=$?
    if [ $FLAG -eq 1]
    then
        echo "No available network is found. Please check the connection."
        sleep 5
    fi
done

pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt /bin/bash

$LOCALE="en_US.UTF-8"
echo $LOCALE > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.gen
export "LANG=$LOCALE"

echo "Enter the hostname"
read HOST
echo $HOST > /etc/hostname
echo "Enter your password"
passwd

pacman -S intel-ucode grub dosfstools efibootmgr
grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck
mkdir -p /boot/EFI/boot
cp /boot/EFI/arch_grub/grubia32.efi /boot/EFI/boot/bootia32.efi
grub-mkconfig -o /boot/grub/grub.cfg

exit
