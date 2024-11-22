#!/bin/bash
#需要传参，参数为需要转换的镜像路径
CURRENTWD=$PWD
IMGFILE=$1
length=${#IMGFILE}
diskimg=$(echo ${IMGFILE::length-4})
loop=$(losetup -f)
#检查依赖文件是否存在
sudo apt install img2simg

if [ ! -f $IMGFILE ];then
  echo "No such file:$IMGFILE !"
  exit
fi

if [ ! -d "output/amlimg" ];then
  sudo mkdir output/amlimg
  sudo chmod -R 777 output/amlimg
fi


if [ ! -d "/tmp/amlimg" ];then
  mkdir /tmp/amlimg
fi


if [ ! -f "output/amlimg/AmlImg" ];then
  sudo curl -L -o output/amlimg/AmlImg https://github.com/hzyitc/AmlImg/releases/download/v0.3.1/AmlImg_v0.3.1_linux_amd64
  sudo chmod +x output/amlimg/AmlImg
fi

if [ ! -f "output/amlimg/eMMC.burn.img" ];then
  #sudo curl -L -o output/amlimg/eMMC.burn.img https://github.com/hzyitc/u-boot-onecloud/releases/download/build-20221028-0940/eMMC.burn.img
  sudo cp -f userpatches/eMMC.burn.img output/amlimg/
fi

#解包转换为线刷包所需格式
sudo ./output/amlimg/AmlImg unpack output/amlimg/eMMC.burn.img output/amlimg
sudo losetup  --show --partscan $loop $IMGFILE
sudo img2simg ${loop}p1 output/amlimg/boot.simg
sudo img2simg ${loop}p2 output/amlimg/rootfs.simg
sudo losetup -d $loop
#sudo chown $(id -u):$(id -g) -R output/amlimg/

#写入刷机文件，去除分区校验
sudo cat <<EOF >output/amlimg/commands.txt
USB:DDR:normal:0.DDR.USB
USB:UBOOT_COMP:normal:1.UBOOT_COMP.USB
ini:aml_sdc_burn:normal:2.aml_sdc_burn.ini
conf:platform:normal:3.platform.conf
PARTITION:bootloader:normal:4.bootloader.PARTITION
PARTITION:resource:normal:6.resource.PARTITION
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF
sudo rm ./output/amlimg/5.bootloader.VERIFY ./output/amlimg/7.resource.VERIFY

#打包为线刷镜像
burnimg=$diskimg.burn.img
sudo ./output/amlimg/AmlImg pack $burnimg output/amlimg/
echo "complete! File:$burnimg"

