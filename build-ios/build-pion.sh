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
pushd pion-${PION_VERSION}

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=2.2 -L${ROOTDIR}/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=2.2 -I${ROOTDIR}/include -fvisibility=hidden -fvisibility-inlines-hidden -fdata-sections"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

# export CPPFLAGS="-Os --sysroot ${SYSROOT} -Wno-variadic-macros -fexceptions -frtti -fpic -ffunction-sections -funwind-tables -march=armv5te -mtune=xscale -msoft-float -mthumb -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -fvisibility=hidden -fvisibility-inlines-hidden -fdata-sections -DANDROID -D__ANDROID__ -DNDEBUG  -D__arm__ -D_REENTRANT -D_GLIBCXX__PTHREADS -I${ROOTDIR}/include"

./autogen.sh
./configure --host=${ARCH}-apple-darwin --with-cpu=${ARCH} --prefix=${ROOTDIR} --with-boost=${ROOTDIR} --with-zlib=${ROOTDIR} --with-bzlib=${ROOTDIR} --with-openssl=${ROOTDIR} --enable-static --disable-logging --disable-tests --disable-doxygen-doc

# Patch to fix link errors
sed 's/\/src\/libpion/\/src\/\.libs\/libpion/g' utils/Makefile > utils/Makefile.1
sed 's/\.la/\.a/g' utils/Makefile.1 > utils/Makefile.2
cp -f utils/Makefile.2 utils/Makefile

make
make install
popd

# Clean up
rm -rf "pion-${PION_VERSION}"
