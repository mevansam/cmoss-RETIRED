#!/bin/bash
set -e

# Copyright (c) 2010, Pierre-Olivier Latour
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Pierre-Olivier Latour may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Download source
if [ "${PION_VERSION}" == "master" ] && [ ! -e "pion-master.zip" ]
then
	curl $PROXY -o "pion-master.zip" -L "https://github.com/cloudmeter/pion/archive/master.zip"
elif [ ! -e "pion-${PION_VERSION}.zip" ]
then
	curl $PROXY -o "pion-${PION_VERSION}.zip" -L "https://nodeload.github.com/cloudmeter/pion/zip/${PION_VERSION}"
fi

# Extract source
rm -fr "pion-${PION_VERSION}"
unzip "pion-${PION_VERSION}.zip"

# Build
pushd "pion-${PION_VERSION}"

GNUSTL_LIBS=${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}

export CC=${DROIDTOOLS}-gcc
export LD=${DROIDTOOLS}-ld
export CPP=${DROIDTOOLS}-cpp
export CXX=${DROIDTOOLS}-g++
export AR=${DROIDTOOLS}-ar
export AS=${DROIDTOOLS}-as
export NM=${DROIDTOOLS}-nm
export STRIP=${DROIDTOOLS}-strip
export CXXCPP=${DROIDTOOLS}-cpp
export RANLIB=${DROIDTOOLS}-ranlib

export LDFLAGS="-Os -fPIC -L${GNUSTL_LIBS}/libs/armeabi-v7a -lgnustl_static -L${ROOTDIR}/lib"
export CPPFLAGS="-Os --sysroot ${SYSROOT} -Wno-variadic-macros -Wno-unused-but-set-variable -Wno-vla -fexceptions -frtti -fpic -ffunction-sections -funwind-tables -march=armv5te -mtune=xscale -msoft-float -mthumb -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -fvisibility=hidden -fvisibility-inlines-hidden -fdata-sections -DANDROID -D__ANDROID__ -DNDEBUG  -D__arm__ -D_REENTRANT -D_GLIBCXX__PTHREADS -I${GNUSTL_LIBS}/include -I${GNUSTL_LIBS}/libs/armeabi-v7a/include -I${ROOTDIR}/include"

./autogen.sh

# Apply patches to icu
tar xvf "${TOPDIR}/build-droid/droid-pion-patch.tar.gz"

PATCHES_DIR=${TMPDIR}/pion-${PION_VERSION}/droid-pion-patch
if [ ! -d "$PATCHES_DIR" ] ; then
	echo "ERROR: Could not locate droid build patch files."
	exit 1
fi

PATCHES=`(cd $PATCHES_DIR && find . -name "*.patch" | sort) 2> /dev/null`
if [ -z "$PATCHES" ] ; then
	echo "No patches files in $PATCHES_DIR"
else
	PATCHES=`echo $PATCHES | sed -e s%^\./%%g`
	SRC_DIR=${TMPDIR}/icu/source
	for PATCH in $PATCHES; do
		PATCHDIR=`dirname $PATCH`
		PATCHNAME=`basename $PATCH`
		echo "Applying $PATCHNAME into $SRC_DIR/$PATCHDIR"
		patch -p1 < $PATCHES_DIR/$PATCH
		if [ $? != 0 ] ; then
			dump "ERROR: Patch failure !! Please check your patches directory! Try to perform a clean build using --clean"
			exit 1
		fi
	done
fi

# Configure build
./configure --host=${ARCH}-android-linux --target=${PLATFORM} --enable-static --disable-shared --prefix=${ROOTDIR} --with-boost=${ROOTDIR} --with-zlib=${ROOTDIR} --with-bzlib=${ROOTDIR} --with-openssl=${ROOTDIR} --disable-logging --disable-tests --disable-doxygen-doc

# Patch to fix link errors
sed 's/-shared //g' services/Makefile > services/Makefile.1
cp -f services/Makefile.1 services/Makefile

make
make install
popd

# Clean up
rm -rf "pion-${PION_VERSION}"
