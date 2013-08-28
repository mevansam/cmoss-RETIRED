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
if [ ! -e "yajl-${YAJL_VERSION}.tar.gz" ]
then
  curl $PROXY -o "yajl-${YAJL_VERSION}.tar.gz" -L "http://github.com/lloyd/yajl/tarball/${YAJL_VERSION}"
fi

# Extract source
rm -rf lloyd-yajl-*
tar xvf "yajl-${YAJL_VERSION}.tar.gz"

# Build
pushd lloyd-yajl-*
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
export LDFLAGS="-Os -fpic -nostdlib -lc -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${ROOTDIR}/lib"
export CFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include"
export CXXFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include"

mv "CMakeLists.txt" "CMakeLists.txt~1"
sed 's/ADD_SUBDIRECTORY(test)//' CMakeLists.txt~1 > CMakeLists.txt~2
sed 's/ADD_SUBDIRECTORY(reformatter)//' CMakeLists.txt~2 > CMakeLists.txt~3
sed 's/ADD_SUBDIRECTORY(verify)//' CMakeLists.txt~3 > CMakeLists.txt

# Remove test and doc targets as that fails for device builds
./configure --prefix=${ROOTDIR}

mv "build/Makefile" "build/Makefile~"
sed 's/preinstall\: all/preinstall\:/g' build/Makefile~ > build/Makefile

mv "build/src/CMakeFiles/yajl.dir/build.make" "build/src/CMakeFiles/yajl.dir/build.make~"
sed 's/cd .* cmake_symlink_library .*$//g' build/src/CMakeFiles/yajl.dir/build.make~ > build/src/CMakeFiles/yajl.dir/build.make~1
sed 's/\.dylib/\.so/g' build/src/CMakeFiles/yajl.dir/build.make~1 > build/src/CMakeFiles/yajl.dir/build.make

FILES=`sed 's/^.*dylib CMakeFiles/CMakeFiles/' build/src/CMakeFiles/yajl.dir/link.txt`
cat > build/src/CMakeFiles/yajl.dir/link.txt <<EOF
${CC} -shared -fpic -nostdlib -lc -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -I${SYSROOT}/usr/include -o ../yajl-${YAJL_VERSION}/lib/libyajl.so $FILES
EOF

STATICLINKFILES="${AR} `sed 's/\/usr\/bin\/ar //' build/src/CMakeFiles/yajl_s.dir/link.txt | sed 's/^\/usr\/bin\/ranlib.*//'`"
cat > build/src/CMakeFiles/yajl_s.dir/link.txt <<EOF
$STATICLINKFILES
${RANLIB} ../yajl-${YAJL_VERSION}/lib/libyajl_s.a
EOF

mv "build/src/cmake_install.cmake" "build/src/cmake_install.cmake~"
sed 's/\.dylib/\.so/g' build/src/cmake_install.cmake~ > build/src/cmake_install.cmake~1
sed 's/\".*\/libyajl\.2\.0\.3\.so\"//' build/src/cmake_install.cmake~1 > build/src/cmake_install.cmake~2
sed 's/\".*\/libyajl\.2\.so\"//' build/src/cmake_install.cmake~2 > build/src/cmake_install.cmake

cat > Makefile <<EOF
.PHONY: all distro
all: distro

distro:
	@cd build && make yajl yajl_s

install: all
	@cd build && make install
EOF

make
make install
popd

# Clean up
rm -rf lloyd-yajl-*
