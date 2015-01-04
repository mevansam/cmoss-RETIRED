#!/bin/sh
set -e

# Copyright (c) 2015, dorgon(horizon-studio)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of dorgon may not be used to endorse or
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
if [ ! -e "curl-${CURL_VERSION}.tar.gz" ]
then
  curl $PROXY -O "http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz"
fi

# Extract source
rm -rf "curl-${CURL_VERSION}"
tar xvf "curl-${CURL_VERSION}.tar.gz"

# Build
pushd "curl-${CURL_VERSION}"

cmake -G "${SDK_NAME}" -DCURL_ZLIB=ON \
		-DZLIB_INCLUDE_DIR=${ROOTDIR}/include/zlib \
		-DZLIB_LIBRARY=${ROOTDIR}/lib/zlib/Release/zlibstatic.lib \
		-DCURL_DISABLE_VERBOSE_STRINGS=ON \
		-DENABLE_IPV6=ON \
		-DENABLE_THREADED_RESOLVER=ON
#-Dwith-zlib=${ROOTDIR}/zlib -Denable-static \
#            -Ddisable-shared \
#            -Ddisable-verbose \
#            -Denable-threaded-resolver \
#            -Denable-libgcc \
 #           -Denable-ipv6 
CONFIG=Release
cmake --build . --config ${CONFIG}

mkdir -p ${ROOTDIR}/include/curl/ || true
cp include/curl/*.h ${ROOTDIR}/include/curl/
mkdir -p ${ROOTDIR}/lib/curl/${CONFIG} || true
cp lib/${CONFIG}/* ${ROOTDIR}/lib/curl/${CONFIG}
popd

# Clean up
#rm -rf "curl-${CURL_VERSION}"
