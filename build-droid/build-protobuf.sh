#!/bin/bash
set -e

# Changes for protobuf Copyright (c) 2012, Lothar May
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
if [ ! -e "protobuf-${PROTOBUF_VERSION}.tar.bz2" ]
then
  curl $PROXY -L -O "https://protobuf.googlecode.com/files/protobuf-${PROTOBUF_VERSION}.tar.bz2"
fi

# Extract source
rm -rf "protobuf-${PROTOBUF_VERSION}"
tar xvjf "protobuf-${PROTOBUF_VERSION}.tar.bz2"

# Build
pushd "protobuf-${PROTOBUF_VERSION}"
export CC=${DROIDTOOLS}-gcc
#export LD=${DROIDTOOLS}-ld
#export CPP=${DROIDTOOLS}-cpp
#export CXX=${DROIDTOOLS}-g++
#export AR=${DROIDTOOLS}-ar
#export AS=${DROIDTOOLS}-as
#export NM=${DROIDTOOLS}-nm
#export STRIP=${DROIDTOOLS}-strip
#export CXXCPP=${DROIDTOOLS}-cpp
#export RANLIB=${DROIDTOOLS}-ranlib
#export LDFLAGS="-Os -fpic -L${SYSROOT}/usr/lib -L${ROOTDIR}/lib"
#export CFLAGS="-Os -I${ROOTDIR}/include -I${SYSROOT}/usr/include"
#export CXXFLAGS="-Os -I${ROOTDIR}/include -I${SYSROOT}/usr/include -DNDEBUG"
#export LIBS="-lc"
./configure --with-protoc=protoc --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --with-sysroot=$SYSROOT CC=$CC --enable-cross-compile

# make CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
make
make install
pushd ${ROOTDIR}/lib
mv libprotobuf.so.8.0.0 libprotobuf.so
mv libprotobuf-lite.so.8.0.0 libprotobuf-lite.so
mv libprotoc.so.8.0.0 libprotoc.so
rm libprotoc.so.8 libprotobuf.so.8 libprotobuf-lite.so.8
popd

popd

# Clean up
rm -rf "protobuf-${PROTOBUF_VERSION}"
