# X205TA_ARCH_INSTALL
X205TAにArch Linuxをインストールする自分用のメモ

## create install media

1. Arch linuxのISOを[ダウンロード](https://www.archlinux.jp/download/)
2. Rufusを使用しGPTパーテーションでISOをUSBに書き込む (USBラベルは`ARCH_ISO`にする)
3. [bootia32.efi](https://github.com/hirotakaster/baytail-bootia32.efi/blob/master/bootia32.efi)
をUSBの`/EFI/boot/bootia32.efi`に配置
4. glub.cfgをUSBの`/boot/glub/glub.cfg`に配置

## boot with install media

1. F2キーを連打しながら電源を入れる
2. Secure bootをdisabledにする
3. USB controllerをEHCIにする
4. インストールメディアを指定して起動
