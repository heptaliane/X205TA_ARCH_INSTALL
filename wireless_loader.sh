#------------
# root is required
#-----------
# get wireless driver via wired network
wget https://android.googlesource.com/platform/hardware/broadcom/wlan/+archive/master/bcmdhd/firmware/bcm43341.tar.gz
tar -xf bcm43341.tar.gz

mkdir -p /lib/firmware/brcm/
cp fw_bcm43341.bin /lib/firmware/brcm/brcmfmac43340-sdio.bin
cp /sys/firmware/efi/efivars/nvram-74b00bd9-805a-4d61-b51f-43268123d113 /lib/firmware/brcm/brcmfmac43340-sdio.txt

# enable wireless driver
rmmod brcmfmac
modprobe brcmfmac

# clean downloaded files
rm bcm43341.tar.gz
rm fw_bcm43341.*
