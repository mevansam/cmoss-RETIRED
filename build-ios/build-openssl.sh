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
if [ ! -e "openssl-${OPENSSL_VERSION}.tar.gz" ]
then
  curl $PROXY -O "http://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
fi

# Extract source
rm -rf "openssl-${OPENSSL_VERSION}"
tar zxvf "openssl-${OPENSSL_VERSION}.tar.gz"
pushd "openssl-${OPENSSL_VERSION}"

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=2.2 -dynamiclib"
export CFLAGS="-Os -D_DARWIN_C_SOURCE -UOPENSSL_BN_ASM_PART_WORDS -arch ${ARCH} -isysroot ${BUILD_SDKROOT}"

./config no-shared no-asm no-krb5 no-gost zlib --openssldir=${ROOTDIR}

make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}"
make install
popd

# Clean up
rm -rf "openssl-${OPENSSL_VERSION}"
