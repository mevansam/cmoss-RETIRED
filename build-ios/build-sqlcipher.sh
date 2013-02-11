#!/bin/sh
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
if [ "${SQLCIPHER_VERSION}" == "master" ] && [ ! -e "sqlcipher-master.zip" ]
then
	curl $PROXY -o "sqlcipher-master.zip" -L "https://github.com/sqlcipher/sqlcipher/archive/master.zip"
elif [ ! -e "sqlcipher-${SQLCIPHER_VERSION}.zip" ]
then
  curl $PROXY -o "sqlcipher-${SQLCIPHER_VERSION}.zip" -L "https://github.com/sqlcipher/sqlcipher/archive/v${SQLCIPHER_VERSION}.zip"
fi

# Extract source
rm -rf sqlcipher-${SQLCIPHER_VERSION}
unzip "sqlcipher-${SQLCIPHER_VERSION}.zip"
pushd sqlcipher-${SQLCIPHER_VERSION}

# Build
export LDFLAGS="-Os -arch ${ARCH} -L${ROOTDIR}/lib"
export CFLAGS="-Os -D_FILE_OFFSET_BITS=64 -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=2.2 -I${ROOTDIR}/include -DSQLITE_HAS_CODEC"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

./configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} --disable-readline --disable-tcl --enable-threadsafe --enable-cross-thread-connections --enable-tempstore=no
make
make install
popd

# Clean up
rm -rf sqlcipher-${SQLCIPHER_VERSION}
