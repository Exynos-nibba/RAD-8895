#!/bin/bash

echo "------------------------------------------------------"
echo "---             RAD-KERNEL-BUILD-SCRIPT            ---"
echo "------------------------------------------------------"

DATE=$(date +'%Y%m%d-%H%M')
JOBS=$(nproc)
KERNELDIR=$(pwd)
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache

echo "Select which device you want to build for";
echo "1. Samsung Galaxy S8/S8+ (Exynos) (SM-G95(0/5)(N/F/FD))";
echo "2. Samsung Galaxy Note 8 (Exynos) (SM-N950F/FD)";
read -p "Your choice? <1> <2> > " dv
if [ "$dv" = "1" ]; then
     echo ""
     echo "S8/S8+ selected"
     export DEVICE=S8/S8+
     echo ""
  elif [ "$dv" = "2" -o "$dv" = "n8" ]; then
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

if [ "${DEVICE}" == "S8/S8+" ]; then
		export DEFCONFIG=dreamlte-dream2lte;
		export AK3_S8_PATH=ak3-s8;
		export AK3_S8p_PATH=ak3-s8+;
	elif [ "${DEVICE}" == "N8" ]; then
		export DEFCONFIG=greatlte;
		export AK3_N8_PATH=ak3-n8;
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
	echo "Executing make clean & make mrproper!";
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
make O=out exynos8895-${DEFCONFIG}_defconfig && make O=out CC=clang -j${JOBS}

echo ""
echo ""Making AK3 zip!""
echo ""
if [ ! -e ${KERNELDIR}/RAD/Releases ]; then
		mkdir ${KERNELDIR}/RAD/Releases;
	fi;
	
if [ -e ${KERNELDIR}/out/arch/arm64/boot/Image ]; then
	rm -rf ${KERNELDIR}/RAD/${AK3_S8_PATH}/dt.img
	rm -rf ${KERNELDIR}/RAD/${AK3_S8p_PATH}/dt.img
	rm -rf ${KERNELDIR}/RAD/${AK3_N8_PATH}/dt.img
	rm -rf ${KERNELDIR}/RAD/${AK3_S8_PATH}/Image
	rm -rf ${KERNELDIR}/RAD/${AK3_S8p_PATH}/Image	
	rm -rf ${KERNELDIR}/RAD/${AK3_N8_PATH}/Image
	rm -rf ${KERNELDIR}/RAD/${AK3_S8_PATH}/kernel.zip
	rm -rf ${KERNELDIR}/RAD/${AK3_S8p_PATH}/kernel.zip
	rm -rf ${KERNELDIR}/RAD/${AK3_N8_PATH}/kernel.zip
else
	echo "Kernel didnt build successfully!"
	echo "No zIMAGE in out dir"
	echo "Exiting!"
	exit 0
fi;	
	
	echo ""
	echo "Copying zImage & dt.img to AK3 dir!"
	echo ""
if [ "${DEVICE}" == "S8/S8+" ]; then
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AK3_S8_PATH};
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_dreamlte.img ${KERNELDIR}/RAD/${AK3_S8_PATH};
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AK3_S8p_PATH};
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_dream2lte.img ${KERNELDIR}/RAD/${AK3_S8p_PATH};
	elif [ "${DEVICE}" == "N8" ]; then
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AK3_N8_PATH};
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_greatlte.img ${KERNELDIR}/RAD/${AK3_N8_PATH};
	fi;
		
	echo ""
	echo "Zipping up AK3!"
	echo ""
if [ "${DEVICE}" == "S8/S8+" ]; then
	cd $(pwd)/RAD/${AK3_S8_PATH}
	mv dtb_dreamlte.img dt.img
	zip -r9 kernel.zip * -x README.md kernel.zip/
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	mv kernel.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-dreamlte-${DATE}.zip
	cd $(pwd)/RAD/${AK3_S8p_PATH}
	mv dtb_dream2lte.img dt.img
	zip -r9 kernel.zip * -x README.md kernel.zip/
	mv kernel.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-dream2lte-${DATE}.zip
    elif [ "${DEVICE}" == "N8" ]; then
    	cd $(pwd)/RAD/${AK3_N8_PATH}
	mv dtb_greatlte.img dt.img
	zip -r9 kernel.zip * -x README.md kernel.zip/
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	mv kernel.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-greatlte-${DATE}.zip
    fi;
    
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo "";
	echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.";
	echo ""

exit 0

