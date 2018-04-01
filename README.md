# X205TA_ARCH_INSTALL
X205TAにArch Linuxをインストールする自分用のメモ

## create install media

1. Arch linuxのISOを[ダウンロード](https://www.archlinux.jp/download/)
2. Rufusを使用しGPTパーテーションでISOをUSBに書き込む (USBラベルは`ARCH_ISO`にする)
3. [bootia32.efi](https://github.com/hirotakaster/baytail-bootia32.efi/blob/master/bootia32.efi)
をUSBの`/EFI/boot/bootia32.efi`に配置
4. [grub.cfg](https://github.com/heptaliane/X205TA_ARCH_INSTALL/blob/master/grub.cfg)をUSBの`/boot/grub/grub.cfg`に配置

## boot with install media
1. F2キーを連打しながら電源を入れる
2. Secure bootをdisabledにする
3. USB controllerをEHCIにする
4. インストールメディアを指定して起動

## before install process
起動時に有線に接続してください  
また、インターネットへの接続を確認してください
```
# ping -c 3 archlinux.jp
```

キーマップを日本語配列にします  
```
# loadkeys jp106
```

## partition
ストレージが32GBと心もとないので、付属の32GB micro SDカードを含めたパーテーション構成を作成します  
暗号化が必要な`/home`を除いて、それぞれフォーマットを行います

### `dev/mmcblk1`
* `/boot`: 512MB, EFI System, FAT32
* `[swap]`: 2GB, Linux swap
* `/`:  残りすべて, Linux filesystem, ext4

### `dev/mmcblk2`
* `/home`: All, Linux filesystem, ext4, **crypt**


## mount
```
# mount /dev/mmcblk1p2 /mnt
# mkdir /mnt/boot
# mount /dev/mmcblk1p1 /mnt/boot
# mkdir /mnt/home
# mount /dev/mmcblk2p1 /mnt/home
# mkswap /dev/mmcblk1p3
# swapon /dev/mmcblk1p3
```
とりあえず`/dev/mmcblk2p1`を未暗号化のままマウント

## timedatactl
```
# timedatectl set-ntp true
```

## install base packages
`/etc/pacman.d/mirrorlist`を編集して日本のサーバーを先頭に配置する  
`Japan`で検索をかけるとよい

```
# pacstrap /mnt base base-devel
```

## after install
```
# arch-chroot /mnt
# ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
# hwclock --systohc --utc
# pacman -S vim
```

`/etc/locale.gen`を編集し、`en_US.UTF-8 UTF-8`と`ja_JP.UTF-8 UTF-8`をアンコメント
```
# locale-gen
# echo LANG=en_US.UTF-8 > /etc/locale.conf
# echo KEYMAP=jp106 > /etc/vconsole.conf
```

```
# echo ${myhostname} > /etc/hostname
```

`/etc/hosts`に以下を追記
```
127.0.1.1	${myhostname}.localdomain	${myhostname}
```

`${myhostname}`は適宜置き換えてください


## encryption
`/home`を暗号化します

### prepare partation
```
# cryptsetup open --type plain /dev/mmcblk2p1 container --key-file /dev/random
# dd if=/dev/zero of=/dev/mapper/container status=progress
# cryptsetup close container
```

### encryption
`/home`をアンマウントしておきます
```
# umount /home
```
`/etc/luks-keys/home`に鍵を保存して暗号化します
```
# mkdir -m 700 /etc/luks-keys
# dd if=/dev/random of=/etc/luks-keys/home bs=1 count=256 status=progress
# cryptsetup luksFormat -v -s 512 /dev/mmcblk2p1 /etc/luks-keys/home
# cryptsetup -d /etc/luks-keys/home open /dev/mmcblk2p1 home
# mkfs.ext4 /dev/mapper/home
```
`fstab`の設定を行うためいったんchrootの外に出ます
```
# exit
# mount /dev/mapper/home /mnt/home
# genfstab -U /mnt >> /mnt/etc/fstab
# arch-chroot /mnt
```
`/etc/crypttab`に以下を追記
```
home  /dev/mmcblk2p1    /etc/luks-keys/home
```

## accounts
```
# passwd
# useradd -m -G wheel ${user}
# passwd ${user}
```

administer権限をwheelに与える場合、`visudo`を実行し、`%wheel      ALL=(ALL) ALL`の行をアンコメントする

## setup bootloader
```
# pacman -S grub dosfstools efibootmgr
# grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck
# mkdir -p /boot/EFI/boot
# cp /boot/EFI/arch_grub/grubia32.efi /boot/EFI/boot/bootia32.efi
```
`/etc/default/grub`を編集し、`GRUB_TIMEOUT=0`に設定
```
# grub-mkconfig -o /boot/grub/grub.cfg
```
ここまできたらrebootしても動くはず

## setup wireless
```
# cp /sys/firmware/efi/efivars/nvram-74b00bd9-805a-4d61-b51f-43268123d113 /lib/firmware/brcm/brcmfmac43340-sdio.txt
# rmmod brcmfmac
# modprobe brcmfmac
```
ファームウェアは一応インストールされてるっぽい  
ファームウェア関係で失敗するなら以下を実行
```
# wget -qO- https://android.googlesource.com/platform/hardware/broadcom/wlan/+archive/master/bcmdhd/firmware/bcm43341.tar.gz | tar xvz
# cp fw_bcm43341.bin /lib/firmware/brcm/brcmfmac43340-sdio.bin
```
