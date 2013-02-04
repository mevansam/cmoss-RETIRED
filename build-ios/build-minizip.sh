#!/bin/bash
set -e

# Copyright (c) 2011, Mevan Samaratunga
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Mevan Samaratunga may not be used to endorse or
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
if [ ! -e "unzip${MINIZIP_VERSION}.zip" ]
then
  curl $PROXY -O "http://www.winimage.com/zLibDll/unzip${MINIZIP_VERSION}.zip"
fi

# Extract source
rm -rf "unzip${MINIZIP_VERSION}"

mkdir "unzip${MINIZIP_VERSION}"
pushd "unzip${MINIZIP_VERSION}"
unzip "../unzip${MINIZIP_VERSION}.zip"

# Copy customized make files
cp -f ${TOPDIR}/build-ios/Makefile.minizip .

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=2.2 -L${ROOTDIR}/lib -lz -dynamiclib"
export CFLAGS="-Os -D_FILE_OFFSET_BITS=64 -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=2.2 -I${ROOTDIR}/include -Dfopen64=fopen -Dfseeko64=fseeko -Dftello64=ftello"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

make -f Makefile.minizip install CC="${CC}" CFLAGS="${CFLAGS}" RANLIB="${RANLIB}" LDFLAGS="${LDFLAGS}" PREFIX="${ROOTDIR}"
popd

# Clean up
rm -rf unzip${MINIZIP_VERSION}
