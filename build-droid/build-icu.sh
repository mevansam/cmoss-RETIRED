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
if [ ! -e "icu4c-${ICU_VERSION//./_}-src.tgz" ]
then
	curl $PROXY -O "http://download.icu-project.org/files/icu4c/4.8.1.1/icu4c-${ICU_VERSION//./_}-src.tgz"
fi

# Extract source
rm -rf "icu"
tar zxvf "icu4c-${ICU_VERSION//./_}-src.tgz"

# Build

HOSTBUILD=${TMPDIR}/icu/hostbuild

mkdir -p "icu/hostbuild"
pushd "icu/hostbuild"
../source/configure --prefix="${HOSTBUILD}"
make
popd

pushd "icu/source"

tar zxvf "${TOPDIR}/build-droid/droid-icu-patch.tar.gz"

# Apply patches to icu
PATCHES_DIR=${TMPDIR}/icu/source/droid-icu-patch
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

DROID_GCC_LIBS=${TMPDIR}/droidtoolchains/${PLATFORM}/lib/gcc/arm-linux-androideabi/4.4.3

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

export LDFLAGS="-Os -fPIC -nostdlib -Wl,--entry=main,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${DROID_GCC_LIBS} -L${ROOTDIR}/lib -lc -lgcc"
export CFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -D__STDC_INT64__ -DU_HAVE_NAMESPACE=1"
export CXXFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -D__STDC_INT64__ -DU_HAVE_NAMESPACE=1"

if [ "${PLATFORM}" == "arm-linux-androideabi" ]
then
	./configure --host=arm-eabi-linux --prefix=${ROOTDIR} --with-cross-build="${HOSTBUILD}" --enable-extras=no --enable-strict=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --with-data-packaging=archive
else
	./configure --host=i386-linux --prefix=${ROOTDIR} --with-cross-build="${HOSTBUILD}" --enable-extras=no --enable-strict=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --with-data-packaging=archive
fi

# Fix libtool to not create versioned shared libraries
#mv "libtool" "libtool~"
#sed "s/library_names_spec=\".*\"/library_names_spec=\"~##~libname~##~{shared_ext}\"/" libtool~ > libtool~1
#sed "s/soname_spec=\".*\"/soname_spec=\"~##~{libname}~##~{shared_ext}\"/" libtool~1 > libtool~2
#sed "s/~##~/\\\\$/g" libtool~2 > libtool
#chmod u+x libtool

make
make install
popd

# Clean up
rm -rf "icu"
