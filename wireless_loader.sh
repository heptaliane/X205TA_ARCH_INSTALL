#!/bin/bash

#------------
# root is required
#-----------

GetInterface () {
    NETWORK=`ip link`
    arr=( `echo $NETWORK`)

    FLAG=0
    for arg in ${arr[@]}
    do
        if [ $FLAG -eq 1 ]
        then
            if [[ $arg =~ ^$1 ]]
            then
                echo ${arg:0:-1}
            fi
            FLAG=0
        fi

        if [[ $arg =~ ^[0-9]{1,2}\:$ ]]
        then
            FLAG=1
        fi
    done
}


InstallWirelessDriver () {
    ETHENET_iINTERFACE=`GetInterface e`
    if [ -z $INTERFACE ]
    then
        echo "ethenet interface is not found. Please check the connection."
        return 1
    else
        sudo dhcpcd $ETHENET_INTERFACE
    fi

    echo "download wireless driver"

    FILE="bcm43341"
    mkdir $FILE
    cd $FILE

    # get wireless driver via wired network
    wget https://android.googlesource.com/platform/hardware/broadcom/wlan/+archive/master/bcmdhd/firmware/bcm43341.tar.gz
    tar -xf bcm43341.tar.gz

    sudo mkdir -p /lib/firmware/brcm/
    sudo cp fw_bcm43341.bin /lib/firmware/brcm/brcmfmac43340-sdio.bin
    sudo cp /sys/firmware/efi/efivars/nvram-74b00bd9-805a-4d61-b51f-43268123d113 /lib/firmware/brcm/brcmfmac43340-sdio.txt

    # enable wireless driver
    sudo rmmod brcmfmac
    sudo modprobe brcmfmac

    # clean downloaded files
    cd ../
    rm -rf $FILE
}

WIRELESS_INTERFACE=`GetInterface w`
if [ -z $WIRELESS_INTERFACE ]
then
    InstallWirelessDriver
    WIRELESS_INTERFACE=`GetInterface w`
fi

echo ping -c 2 -q -I $WIRELESS_INTERFACE  www.google.com
ping -c 2 -q -I $WIRELESS_INTERFACE  www.google.com

if [ $? -ne 0 ]
then
    sudo wifi-menu
fi
