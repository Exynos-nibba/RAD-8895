#!/bin/bash

echo "------------------------------------------------------"
echo "---             RAD-KERNEL-BUILD-SCRIPT            ---"
echo "------------------------------------------------------"

DATE=$(date +'%Y%m%d')
KERNELDIR=$(pwd)

echo "Make sure you have specified your device! [export DEVICE=<N8/S8/S8p>]"
echo "Make sure you have specified your Kernel build version! [export VERSION=<build_number>]"

if [ "${DEVICE}" == "S8" ]; then
		export DEFCONFIG=dreamlte;
		export AK3_PATH=ak3-s8;
	elif [ "${DEVICE}" == "S8p" ]; then
		export DEFCONFIG=dream2lte;
		export AK3_PATH=ak3-s8+;
	elif [ "${DEVICE}" == "N8" ]; then
		export DEFCONFIG=greatlte;
		export AK3_PATH=ak3-n8;
	fi;

export LOCALVERSION=-RAD-${VERSION}-${DATE}-AOSP

echo "...................................."
echo "...................................."
echo ".. ""SETTING TOOLCHAIN AND ARCH"" .."
echo "...................................."
echo "...................................."
export ARCH=arm64
export PATH="$(pwd)/clang/bin/:$(pwd)/toolchain/bin:${PATH}"
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-gnu-

echo ....................................
echo ....................................
echo .. ""CREATING/REMOVING OUT DIR""  ..
echo ....................................
echo ....................................
rm -rf out
mkdir -p out

echo ....................................
echo ....................................
echo ........""CLEANING SOURCE"".........
echo ....................................
echo ....................................
make O=out clean && make O=out mrproper

echo ....................................
echo ....................................
echo ...""BUILDING KERNEL "".............
echo ....................................
echo ....................................
make O=out exynos8895-${DEFCONFIG}_defconfig && make O=out CC=clang -j4

echo ""making zip""
if [ -e $(pwd)/out/arch/arm64/boot/Image ]; then
	echo -e "Making AK3 ZIP"
	rm -rf $(pwd)/RAD/${AK3_PATH}/Image
 	
	rm -rf $(pwd)/RAD/${AK3_PATH}/kernel.zip

	echo -e "copying zimage to ak3 folder"
	cp $(pwd)/out/arch/arm64/boot/Image $(pwd)/RAD/${AK3_PATH}
 	
	echo ""

	echo -e "zipping up ak3"
	cd $(pwd)/RAD/${AK3_PATH}
	zip -r9 kernel.zip * -x README.md kernel.zip/
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	mv kernel.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-${DEFCONFIG}-${DATE}.zip
 	
	echo "Done!"

	echo ""
else
	echo Kernel didnt build successfully!
	echo No zIMAGE in out dir
	echo Exiting!
fi;

exit 0

