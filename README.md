# X205TA_ARCH_INSTALL
X205TAにArch Linuxをインストールする自分用のメモ

## create install media

1. Arch linuxのISOを[ダウンロード](https://www.archlinux.jp/download/)
2. Rufusを使用しGPTパーテーションでISOをUSBに書き込む (USBラベルは`ARCH_ISO`にする)
3. [bootia32.efi](https://github.com/hirotakaster/baytail-bootia32.efi/blob/master/bootia32.efi)
をUSBの`/EFI/boot/bootia32.efi`に配置
4. [glub.cfg](https://github.com/heptaliane/X205TA_ARCH_INSTALL/blob/master/grub.cfg)をUSBの`/boot/glub/glub.cfg`に配置

## boot with install media

1. F2キーを連打しながら電源を入れる
2. Secure bootをdisabledにする
3. USB controllerをEHCIにする
4. インストールメディアを指定して起動

## before install process
キーマップを日本語配列にします
``` bash
$ loadkeys jp106
```

## partition
ストレージが32GBと心もとないので、付属の32GB micro SDカードを含めたパーテーション構成を作成します

### `dev/mmcblk1`
* `/boot`: 512MB, EFI System, FAT32
* `[swap]`: 2GB, Linux swap
* `/`:  残りすべて, Linux filesystem, ext4

### `dev/mmcblk2`
* `/home`: All, Linux filesystem, ext4, **crypt**

## encryption
`/home`を暗号化します

### prepare partation
``` bash
cryptsetup open --type plain /dev/mmcblk2p1 container --key-file /dev/random
dd if=/dev/zero of=/dev/mapper/container status=progress
```

### encryption
```
```
