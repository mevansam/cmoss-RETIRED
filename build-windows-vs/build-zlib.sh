#!/bin/bash
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


FILE_FOLDER="zlib-${ZLIB_VERSION}"
SUFFIX=".tar.gz"
ZIP_FILE=${FILE_FOLDER}${SUFFIX}
# Download source
if [ ! -e "http://zlib.net/${ZIP_FILE}" ]
then
  curl $PROXY -O "http://zlib.net/${ZIP_FILE}"
fi

# Extract source
rm -rf "${FILE_FOLDER}"
tar xvf "${ZIP_FILE}"

# Build
pushd "${FILE_FOLDER}"
cmake -G "${SDK_NAME}" #-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=${ROOTDIR}
CONFIG=Release
cmake --build . --config ${CONFIG}
mkdir -p ${ROOTDIR}/include/zlib/ || true
cp *.h ${ROOTDIR}/include/zlib/
mkdir -p ${ROOTDIR}/lib/zlib/${CONFIG} || true
cp ${CONFIG}/* ${ROOTDIR}/lib/zlib/${CONFIG}
popd

# Clean up
rm -rf "${FILE_FOLDER}"
