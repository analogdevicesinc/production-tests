#!/bin/sh
ROOTFS=$(pwd)/pluto-0.30.sysroot
CROSS_COMPILE="$3"
HOST=${HOST:-x86_64}
GCC_ARCH=arm-linux-gnueabihf

[ -n "$CROSS_COMPILE" ] || {
	CROSS_COMPILE=${GCC_ARCH}-gcc
	if type "${GCC_ARCH}-gcc" >/dev/null 2>&1 ; then
		CROSS_COMPILE="${GCC_ARCH}-"
	else
		GCC_VERSION="8.3-2019.03"
		GCC_DIR="gcc-arm-${GCC_VERSION}-${HOST}-${GCC_ARCH}"
		GCC_TAR="$GCC_DIR.tar.xz"
		GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/${GCC_VERSION}/binrel/${GCC_TAR}"
		if [ ! -d "$GCC_DIR" ] && [ ! -e "$GCC_TAR" ] ; then
			wget "$GCC_URL"
		fi
		if [ ! -d "$GCC_DIR" ] ; then
			tar -xvf $GCC_TAR || {
				echo "'$GCC_TAR' seems invalid ; remove it and re-download it"
				exit 1
			}
		fi
		CROSS_COMPILE=$(pwd)/$GCC_DIR/bin/${GCC_ARCH}-gcc
	fi
}


make CC=$CROSS_COMPILE CFLAGS="-mfloat-abi=hard  --sysroot=${ROOTFS} -I./include -L${ROOTFS}/lib"