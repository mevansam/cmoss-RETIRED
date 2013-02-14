#!/bin/bash
set -e

# Changes for tinyxml Copyright (c) 2012, Lothar May
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
if [ ! -e "tinyxml_${TINYXML_FILE}.tar.gz" ]
then
  curl $PROXY -L -O "http://downloads.sourceforge.net/project/tinyxml/tinyxml/${TINYXML_VERSION}/tinyxml_${TINYXML_FILE}.tar.gz"
fi

# Extract source
rm -rf "tinyxml"
tar xvf "tinyxml_${TINYXML_FILE}.tar.gz"
cp ${TOPDIR}/build-ios/Makefile.tinyxml tinyxml/Makefile

# Build
pushd "tinyxml"
BIGFILES=-D_FILE_OFFSET_BITS=64
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -Wno-unknown-pragmas -Wno-format -miphoneos-version-min=2.2 -L${ROOTDIR}/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=2.2 -I${ROOTDIR}/include -g ${BIGFILES}"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

make CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
cp libtinyxml.a ${ROOTDIR}/lib
cp tinyxml.h ${ROOTDIR}/include
popd

# Clean up
rm -rf "tinyxml"
