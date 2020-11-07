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

if [ "${DEVICE}" == "S8/S8+" ]; then
		export DEFCONFIG=dreamlte-dream2lte;
		export AIK_S8_PATH=AIK-G950;
		export AIK_S8p_PATH=AIK-G955;
	elif [ "${DEVICE}" == "N8" ]; then
		export DEFCONFIG=greatlte;
		export AIK_N8_PATH=AIK-N950;
	fi;
	
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
	
read -p "Clean source (y/n) > " yn
if [ "$yn" = "Y" -o "$yn" = "y" ]; then
     echo "Cleaning Source!"
     export CLEAN=yes
else
     echo "Not cleaning source!"
     export CLEAN=no
fi

export LOCALVERSION=-RAD-${VERSION}-${DATE}

export ARCH=arm64
export PATH="$(pwd)/clang/bin/:$(pwd)/toolchain/bin:${PATH}"
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-gnu-

if [ "${CLEAN}" == "yes" ]; then
	echo "Executing make clean & make mrproper!";
	BUILD_START=$(date +"%s");
	rm -rf out;
	mkdir -p out;
	make O=out clean && make O=out mrproper;
  elif [ "${CLEAN}" == "no" ]; then
	echo "Initiating Dirty build!";
	BUILD_START=$(date +"%s");
	fi;
	
echo "-----------------------------------------"	

echo "------------------------------------------------------"
echo "---                Building Kernel!                ---"
echo "------------------------------------------------------"
make O=out exynos8895-${DEFCONFIG}_defconfig && script -q ~/Compile.log -c "
make O=out CC=clang -j${JOBS}"

if [ ! -e ${KERNELDIR}/RAD/logs ]; then
		mkdir ${KERNELDIR}/RAD/logs;
	fi;
	
if [ ! -e ${KERNELDIR}/RAD/Releases ]; then
		mkdir ${KERNELDIR}/RAD/Releases;
	fi;
	
if [ -e ${KERNELDIR}/out/arch/arm64/boot/Image ]; then
        echo ""
        echo ""Making Flashable Zip!""
        echo ""
	rm -rf ${KERNELDIR}/RAD/${AIK_S8_PATH}/split_img/boot.img-dt
	rm -rf ${KERNELDIR}/RAD/${AIK_S8p_PATH}/split_img/boot.img-dt
	rm -rf ${KERNELDIR}/RAD/${AIK_N8_PATH}/split_img/boot.img-dt
	rm -rf ${KERNELDIR}/RAD/${AIK_S8_PATH}/split_img/boot.img-zImage
	rm -rf ${KERNELDIR}/RAD/${AIK_S8p_PATH}/split_img/boot.img-zImage
	rm -rf ${KERNELDIR}/RAD/${AIK_N8_PATH}/split_img/boot.img-zImage
	rm -rf ${KERNELDIR}/RAD/${AIK_S8_PATH}/image-new.img
	rm -rf ${KERNELDIR}/RAD/${AIK_S8p_PATH}/image-new.img
	rm -rf ${KERNELDIR}/RAD/${AIK_N8_PATH}/image-new.img
else
	echo ""
	echo "Kernel didnt build successfully!"
	echo "No zIMAGE in out dir"
	export BUILD=FAIL
	echo "Copying Logs!"
	rm -rf ${KERNELDIR}/RAD/logs/build_fail-${VERSION}-${DATE}-${DEFCONFIG}.log
	mv ~/Compile.log ${KERNELDIR}/RAD/logs/build_fail-${VERSION}-${DATE}-${DEFCONFIG}.log
fi;

if [ "${BUILD}" == "FAIL" ]; then
	read -p "Do you want to read the logs? (y/n) > " log
fi;

if [ "$log" = "Y" -o "$log" = "y" ]; then
     echo "Opening log!"
     nano ${KERNELDIR}/RAD/logs/build_fail-${VERSION}-${DATE}-${DEFCONFIG}.log
     echo "Exiting!"
     exit 0
  elif [ "$log" = "N" -o "$log" = "n" ]; then
	echo "Exiting!";
	exit 0
fi;

	echo ""
	echo "Copying zImage & dt.img to AIK dir!"
	echo ""
if [ "${DEVICE}" == "S8/S8+" ]; then
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AIK_S8_PATH}/split_img/boot.img-zImage;
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_dreamlte.img ${KERNELDIR}/RAD/${AIK_S8_PATH}/split_img/boot.img-dt;
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AIK_S8p_PATH}/split_img/boot.img-zImage;
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_dream2lte.img ${KERNELDIR}/RAD/${AIK_S8p_PATH}/split_img/boot.img-dt;
	elif [ "${DEVICE}" == "N8" ]; then
		cp ${KERNELDIR}/out/arch/arm64/boot/Image ${KERNELDIR}/RAD/${AIK_N8_PATH}/split_img/boot.img-zImage;
		cp ${KERNELDIR}/out/arch/arm64/boot/dtb_greatlte.img ${KERNELDIR}/RAD/${AIK_N8_PATH}/split_img/boot.img-dt;
	fi;
		
	echo ""
	echo "Zipping up AIK!"
	echo ""
if [ "${DEVICE}" == "S8/S8+" ]; then
	cd ${KERNELDIR}/RAD/${AIK_S8_PATH}
	bash repackimg.sh
	mv image-new.img ${KERNELDIR}/RAD/Flashable/boot_G950.img
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	cd ${KERNELDIR}
	cd $(pwd)/RAD/${AIK_S8p_PATH}
	bash repackimg.sh
	mv image-new.img ${KERNELDIR}/RAD/Flashable/boot_G955.img
	cd ${KERNELDIR}/RAD/Flashable && zip -r9 RAD-${VERSION}-${DATE}.zip * -x README.md RAD-${VERSION}-${DATE}.zip/
	mv RAD-${VERSION}-${DATE}.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-${DATE}.zip
    elif [ "${DEVICE}" == "N8" ]; then
    	cd ${KERNELDIR}/RAD/${AIK_N8_PATH}
	bash repackimg.sh
	mv image-new.img ${KERNELDIR}/RAD/Flashable/boot_N950.img
	mkdir ${KERNELDIR}/RAD/Releases/${VERSION}
	cd ${KERNELDIR}/RAD/Flashable && zip -r9 RAD-${VERSION}-${DATE}.zip * -x README.md RAD-${VERSION}-${DATE}.zip/
	mv RAD-${VERSION}-${DATE}.zip ${KERNELDIR}/RAD/Releases/${VERSION}/RAD-${VERSION}-${DATE}.zip
    fi;
    
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo "";
	echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.";
	echo ""

