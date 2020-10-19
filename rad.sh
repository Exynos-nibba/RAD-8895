#!/bin/bash

echo "------------------------------------------------------"
echo "---             RAD-KERNEL-BUILD-SCRIPT            ---"
echo "------------------------------------------------------"

DATE=$(date +'%Y%m%d-%H%M')
KERNELDIR=$(pwd)
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache

read -p "Select device (S8/S8+/N8) > " dv
if [ "$dv" = "S8" -o "$dv" = "s8" ]; then
     echo ""
     echo "S8 selected"
     export DEVICE=S8
     echo ""
  elif [ "$dv" = "S8+" -o "$dv" = "s8+" ]; then
     echo ""
     echo "S8+ selected"
     export DEVICE=S8+
     echo ""
  elif [ "$dv" = "N8" -o "$dv" = "n8" ]; then
     echo ""
     echo "N8 selected"
     export DEVICE=N8
     echo ""
  elif [ "$dv" = "" -o "$dv" = " " ]; then
     echo "No device selected!"
     echo "Exiting!"
     exit 0
fi

echo "-----------------------------------------"

read -p "Type version number > " vr
export VERSION=$vr
if [ "$vr" = "" -o "$vr" = "exit" ]; then
     echo ""
     echo "No version selected!"
     echo "Exiting now!"
     echo ""
     exit 0
else
     echo ""
     echo "<${VERSION}> version number has been set!"
     echo ""
fi;

if [ "${DEVICE}" == "S8" ]; then
		export DEFCONFIG=dreamlte;
		export AK3_PATH=ak3-s8;
	elif [ "${DEVICE}" == "S8+" ]; then
		export DEFCONFIG=dream2lte;
		export AK3_PATH=ak3-s8+;
	elif [ "${DEVICE}" == "N8" ]; then
		export DEFCONFIG=greatlte;
		export AK3_PATH=ak3-n8;
	fi;
	
echo "-----------------------------------------"
	
read -p "Clean source (y/n) > " yn
if [ "$yn" = "Y" -o "$yn" = "y" ]; then
     echo "Cleaning Source!"
     export CLEAN=yes
else
     echo "Not cleaning source!"
     export CLEAN=no
fi

export LOCALVERSION=-RAD-${VERSION}-${DATE}-AOSP

export ARCH=arm64
export PATH="$(pwd)/clang/bin/:$(pwd)/toolchain/bin:${PATH}"
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-gnu-

rm -rf out
mkdir -p out

if [ "${CLEAN}" == "yes" ]; then
	echo "executing make clean & make mrproper";
	BUILD_START=$(date +"%s");
	make O=out clean && make O=out mrproper;
  elif [ "${CLEAN}" == "no" ]; then
	echo "Initiating Dirty build!";
	BUILD_START=$(date +"%s");
	fi;
	
echo "-----------------------------------------"	

echo ....................................
echo ....................................
echo ...""BUILDING KERNEL "".............
echo ....................................
echo ....................................
make O=out exynos8895-${DEFCONFIG}_defconfig && make O=out CC=clang -j4

echo ""
echo ""Making AK3 zip!""
echo ""
if [ ! -e ${KERNELDIR}/RAD/Releases ]; then
		mkdir ${KERNELDIR}/RAD/Releases;
	fi;
	
if [ -e ${KERNELDIR}/out/arch/arm64/boot/Image ]; then
	rm -rf ${KERNELDIR}/RAD/${AK3_PATH}/dtb.img
	rm -rf ${KERNELDIR}/RAD/${AK3_PATH}/Image	
	rm -rf ${KERNELDIR}/RAD/${AK3_PATH}/kernel.zip
	
	echo ""
	echo "Copying zImage & Dt.img to AK3 dir!"
	echo ""
	cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AK3_PATH}
	cp ${KERNELDIR}/out/arch/arm64/boot/dtb.img ${KERNELDIR}/RAD/${AK3_PATH}
		
	echo ""
	echo "Zipping up AK3!"
	echo ""
	cd $(pwd)/RAD/${AK3_PATH}
	zip -r9 kernel.zip * -x README.md kernel.zip/
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	mv kernel.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-${DEFCONFIG}-${DATE}.zip
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo "";
	echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.";
	echo ""
else
	echo "Kernel didnt build successfully!"
	echo "No zIMAGE in out dir"
	echo "Exiting!"
fi;

exit 0

