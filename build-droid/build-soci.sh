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
if [ ! -e "soci-${SOCI_VERSION}.zip" ]
then
  curl $PROXY -O "http://surfnet.dl.sourceforge.net/project/soci/soci/soci-${SOCI_VERSION}/soci-${SOCI_VERSION}.zip"
fi

# Extract source
rm -rf "soci-${SOCI_VERSION}"
unzip "soci-${SOCI_VERSION}.zip"

# Copy customized make files
cp -f ${TOPDIR}/build-droid/Makefile.soci-core soci-${SOCI_VERSION}/core
cp -f ${TOPDIR}/build-droid/Makefile.soci-sqlite3 soci-${SOCI_VERSION}/backends/sqlite3

# Build
BIGFILES=-D_FILE_OFFSET_BITS=64
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
export LDFLAGS="-Os -nostdlib -lc -shared -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${ROOTDIR}/lib"
export CFLAGS="-Os -D_FILE_OFFSET_BITS=64 -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -g ${BIGFILES}"
export CXXFLAGS="-Os -D_FILE_OFFSET_BITS=64 -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -g ${BIGFILES}"

pushd soci-${SOCI_VERSION}/core
make -f Makefile.soci-core install CXX="${CXX}" CXXFLAGS="${CXXFLAGS}" PREFIX="${ROOTDIR}"
popd
pushd soci-${SOCI_VERSION}/backends/sqlite3
make -f Makefile.soci-sqlite3 install CXX="${CXX}" CXXFLAGS="${CXXFLAGS}" PREFIX="${ROOTDIR}"
popd

# Clean up
rm -rf soci-${SOCI_VERSION}

