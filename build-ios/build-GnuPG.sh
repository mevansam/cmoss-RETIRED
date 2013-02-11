#!/bin/sh
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
if [ ! -e "gnupg-${GNUPG_VERSION}.tar.bz2" ]
then
  curl $PROXY -O "ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-${GNUPG_VERSION}.tar.bz2"
fi

# Extract source
rm -rf "gnupg-${GNUPG_VERSION}"
tar xvjf "gnupg-${GNUPG_VERSION}.tar.bz2"
pushd "gnupg-${GNUPG_VERSION}"
tar xvf "${TOPDIR}/build-ios/ios-gnupg-patch.tar.gz"

# Apply patches to libgcrypt
PATCHES_DIR=${TMPDIR}/gnupg-${GNUPG_VERSION}/ios-gnupg-patch
if [ ! -d "$PATCHES_DIR" ] ; then
	echo "ERROR: Could not locate ios build patch files."
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

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=2.2 -L${ROOTDIR}/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=2.2 -I${ROOTDIR}/include"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

./configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} --with-zlib=${BUILD_SDKROOT} --with-bzip2=${ROOTDIR} --enable-static --disable-shared
mv "Makefile" "Makefile~"
sed '/checks =/d' "Makefile~" > "Makefile"  # Patch Makefile to disable checks
make
make install
popd

# Clean up
rm -rf "gnupg-${GNUPG_VERSION}"
