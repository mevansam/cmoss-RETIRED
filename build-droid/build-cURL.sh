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
if [ ! -e "curl-${CURL_VERSION}.tar.gz" ]
then
  curl $PROXY -O "http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz"
fi

# Extract source
rm -rf "curl-${CURL_VERSION}"
tar xvf "curl-${CURL_VERSION}.tar.gz"

# Build
pushd "curl-${CURL_VERSION}"

DROID_GCC_LIBS=${TMPDIR}/droidtoolchains/${PLATFORM}/lib/gcc/arm-linux-androideabi/4.4.3

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

#export LDFLAGS="-Os -fPIC -nostdlib -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${DROID_GCC_LIBS} -L${ROOTDIR}/lib -lcrypto -lssl -lgpg-error -lgcrypt -lgcc -lc"
export LDFLAGS="-Os -fPIC -nostdlib -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${DROID_GCC_LIBS} -L${ROOTDIR}/lib -lcrypto -lssl -lgcc -lc"

export CFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include"
export CXXFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include"

#./configure --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --with-zlib=${ROOTDIR} --with-ssl=${ROOTDIR} --enable-ares=${ROOTDIR} --with-libssh2=${ROOTDIR} --with-random=/dev/urandom --enable-optimize --enable-nonblocking --disable-verbose --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-manual --disable-ipv6 --disable-soname-bump --without-polarssl --without-gnutls --without-cyassl --without-axtls

#./configure --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --with-zlib=${ROOTDIR} --with-ssl=${ROOTDIR} --with-libssh2=${ROOTDIR} --with-random=/dev/urandom --enable-optimize --enable-nonblocking --disable-ares --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-ipv6 --disable-soname-bump --without-polarssl --without-gnutls --without-cyassl --without-axtls --disable-manual --disable-verbose

#./configure --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --with-zlib=${ROOTDIR} --with-ssl=${ROOTDIR} --with-random=/dev/urandom --enable-optimize --enable-nonblocking --enable-verbose --disable-ares --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-ipv6 --disable-soname-bump --without-polarssl --without-gnutls --without-cyassl --without-axtls --without-libssh2 --disable-manual

./configure --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --with-zlib=${ROOTDIR} --with-ssl=${ROOTDIR} --with-random=/dev/urandom --enable-optimize --enable-nonblocking --disable-ares --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-ipv6 --disable-soname-bump --without-polarssl --without-gnutls --without-cyassl --without-axtls --without-libssh2 --disable-manual --disable-verbose

# Fix libtool to not create versioned shared libraries
mv "libtool" "libtool~"
sed "s/library_names_spec=\".*\"/library_names_spec=\"~##~libname~##~{shared_ext}\"/" libtool~ > libtool~1
sed "s/soname_spec=\".*\"/soname_spec=\"~##~{libname}~##~{shared_ext}\"/" libtool~1 > libtool~2
sed "s/~##~/\\\\$/g" libtool~2 > libtool
chmod u+x libtool

# Fix curl.h to compile on linux based systems
mv "include/curl/curl.h" "include/curl/curl.h~"
sed 's/#include <sys\/types.h>/#include <sys\/select.h>\
#include <sys\/types.h>/' include/curl/curl.h~ > include/curl/curl.h

pushd "lib"
make
make install
popd
pushd "include"
make
make install
popd
popd

# Clean up
rm -rf "curl-${CURL_VERSION}"
