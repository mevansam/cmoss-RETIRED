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

#SDK_VERSION=`cat ${SDK}/RELEASE.TXT | sed "s/.*-crystax-.*/crystax/"`
#if [ "$SDK_VERSION" != "crystax" ]
#then
#	echo "Boost can only be built using the crystax build of the NDK. You can download it from http://www.crystax.net/en/android/ndk"
#	exit
#fi

BOOST_SOURCE_NAME=boost_${BOOST_VERSION//./_}
BOOST_DOWNLOAD_FILE_SURFIX=".tar.bz2"
# Download source
if [ ! -e "${BOOST_SOURCE_NAME}${BOOST_DOWNLOAD_FILE_SURFIX}" ]
then
  curl $PROXY -O -L "http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_SOURCE_NAME}${BOOST_DOWNLOAD_FILE_SURFIX}"
fi


#rm -rf "${BOOST_SOURCE_NAME}"
# Extract source
if [ ! -d "${BOOST_SOURCE_NAME}" ]
then
  tar xvf "${BOOST_SOURCE_NAME}${BOOST_DOWNLOAD_FILE_SURFIX}"
fi


cp -rf  ${TOPDIR}/patches/* ${TMPDIR}/

pushd "${BOOST_SOURCE_NAME}"


#tar xvf "${TOPDIR}/build-droid/droid-boost-patch.tar.gz"


# Build

# ---------
# Bootstrap
# ---------
rm -f project-config.jam
# Make the initial bootstrap
BOOST_LIBS_COMMA=$(echo $BOOST_LIBS | sed -e "s/ /,/g")
echo "Bootstrapping (with libs $BOOST_LIBS_COMMA)"
./bootstrap.sh --with-libraries=$BOOST_LIBS_COMMA
if [ $? != 0 ] ; then
	echo "ERROR: Could not perform boostrap! See $TMPLOG for more info."
	exit 1
fi

# -------------------------------------------------------------
# Patching will be done only if we had a successfull bootstrap!
# -------------------------------------------------------------

# Apply patches to boost
#PATCHES_DIR=droid-boost-patch
#if [ ! -d "$PATCHES_DIR" ] ; then
	#echo "ERROR: Could not locate droid build patch files."
	#exit 1
#fi

#PATCHES=`(cd $PATCHES_DIR && find . -name "*.patch" | sort) 2> /dev/null`
#if [ -z "$PATCHES" ] ; then
#	echo "No patches files in $PATCHES_DIR"
#else
#	PATCHES=`echo $PATCHES | sed -e s%^\./%%g`
#	SRC_DIR=${TMPDIR}/${BOOST_SOURCE_NAME}
#	for PATCH in $PATCHES; do
#		PATCHDIR=`dirname $PATCH`
#		PATCHNAME=`basename $PATCH`
#		echo "Applying $PATCHNAME into $SRC_DIR/$PATCHDIR"
#		patch -p1 < $PATCHES_DIR/$PATCH
#		if [ $? != 0 ] ; then
#			dump "ERROR: Patch failure !! Please check your patches directory! Try to perform a clean build using --clean"
#			exit 1
#		fi
#	done
#fi


cat > ~/user-config.jam <<EOF

using gcc : i686 : ${CXX} :
<compileflags>-Os
<compileflags>-O2
<compileflags>-g
<compileflags>-std=c++11
<compileflags>-Wno-variadic-macros
<compileflags>-Wno-unused-but-set-variable
<compileflags>-Wno-vla
<compileflags>-fexceptions
<compileflags>-fpic
<compileflags>-ffunction-sections
<compileflags>-funwind-tables
<compileflags>-fomit-frame-pointer
<compileflags>-fno-strict-aliasing
<compileflags>-finline-limit=64
<compileflags>-DANDROID
<compileflags>-D__ANDROID__
<compileflags>-DNDEBUG
<compileflags>-I${SDK}/platforms/android-${ANDROID_API_LEVEL}/arch-${ARCHITECTURE}/usr/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/{APP_ABI}}/include
<compileflags>-I${TMPDIR}/${BOOST_SOURCE_NAME}
<compileflags>-I${ROOTDIR}/include
<linkflags>-nostdlib
<linkflags>-lc
<linkflags>-Wl,-rpath-link=${SYSROOT}/usr/lib
<linkflags>-L${SYSROOT}/usr/lib
<linkflags>-L${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/${APP_ABI}
<linkflags>-L${ROOTDIR}/lib
# Flags above are for android
<architecture>x86
<compileflags>-fvisibility=hidden
<compileflags>-fvisibility-inlines-hidden
<compileflags>-fdata-sections
<cxxflags>-frtti
<cxxflags>-D_REENTRANT
<cxxflags>-D_GLIBCXX__PTHREADS
;

using gcc : armv5 : ${CXX} :
<compileflags>-Os
<compileflags>-O2
<compileflags>-g
<compileflags>-std=c++11
<compileflags>-Wno-variadic-macros	
<compileflags>-Wno-unused-but-set-variable
<compileflags>-Wno-vla
<compileflags>-fexceptions
<compileflags>-fpic
<compileflags>-ffunction-sections
<compileflags>-funwind-tables
<compileflags>-march=${ARCH}
<compileflags>-mtune=xscale
<compileflags>-msoft-float
<compileflags>-mthumb
<compileflags>-fomit-frame-pointer
<compileflags>-fno-strict-aliasing
<compileflags>-finline-limit=64
<compileflags>-D__ANDROID__
<compileflags>-DANDROID=1
<compileflags>-D__ARM_ARCH__
<compileflags>-D__ARM_ARCH_5__
<compileflags>-D__ARM_ARCH_5T__
<compileflags>-D__ARM_ARCH_5E__
<compileflags>-D__ARM_ARCH_5TE__
<compileflags>-DNDEBUG
<compileflags>-I${SDK}/platforms/android-${ANDROID_API_LEVEL}/arch-${ARCHITECTURE}/usr/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/${APP_ABI}/include
<compileflags>-I${TMPDIR}/${BOOST_SOURCE_NAME}
<compileflags>-I${ROOTDIR}/include
<linkflags>-nostdlib
<linkflags>-lc
<linkflags>-Wl,-rpath-link=${SYSROOT}/usr/lib
<linkflags>-L${SYSROOT}/usr/lib
<linkflags>-L${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/${APP_ABI}
<linkflags>-L${ROOTDIR}/lib
# Flags above are for android
<architecture>${ARCH}
<compileflags>-fvisibility=hidden
<compileflags>-fvisibility-inlines-hidden
<compileflags>-fdata-sections
<cxxflags>-frtti
<cxxflags>-D__arm__
<cxxflags>-D_REENTRANT
<cxxflags>-D_GLIBCXX__PTHREADS
;



using gcc : armv7 : ${CXX} :
<compileflags>-Os
<compileflags>-O2
<compileflags>-g
<compileflags>-std=c++11
<compileflags>-Wno-variadic-macros	
<compileflags>-Wno-unused-but-set-variable
<compileflags>-Wno-vla
<compileflags>-fexceptions
<compileflags>-fpic
<compileflags>-ffunction-sections
<compileflags>-funwind-tables
<compileflags>-march=${ARCH}
<compileflags>-mtune=xscale
<compileflags>-msoft-float
<compileflags>-mthumb
<compileflags>-fomit-frame-pointer
<compileflags>-fno-strict-aliasing
<compileflags>-finline-limit=64
<compileflags>-D__ANDROID__
<compileflags>-DANDROID=1
<compileflags>-D__ARM_ARCH__
<compileflags>-D__ARM_ARCH_7__
<compileflags>-D__ARM_ARCH_7A__
<compileflags>-DNDEBUG
<compileflags>-I${SDK}/platforms/android-${ANDROID_API_LEVEL}/arch-${ARCHITECTURE}/usr/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/include
<compileflags>-I${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/${APP_ABI}/include
<compileflags>-I${TMPDIR}/${BOOST_SOURCE_NAME}
<compileflags>-I${ROOTDIR}/include
<linkflags>-nostdlib
<linkflags>-lc
<linkflags>-Wl,-rpath-link=${SYSROOT}/usr/lib
<linkflags>-L${SYSROOT}/usr/lib
<linkflags>-L${SDK}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}/libs/${APP_ABI}
<linkflags>-L${ROOTDIR}/lib
# Flags above are for android
<architecture>${ARCH}
<compileflags>-fvisibility=hidden
<compileflags>-fvisibility-inlines-hidden
<compileflags>-fdata-sections
<cxxflags>-frtti
<cxxflags>-D__arm__
<cxxflags>-D_REENTRANT
<cxxflags>-D_GLIBCXX__PTHREADS
;



option.set prefix : ${ROOTDIR}/ ;
option.set exec-prefix : ${ROOTDIR}/bin ;
option.set libdir : ${ROOTDIR}/lib ;
option.set includedir : ${ROOTDIR}/include ;
EOF



#./b2 --prefix=$ROOTDIR -sBOOST_BUILD_USER_CONFIG=$JAM_FILE \
#--toolset=darwin-${SDK_VER}~iphone cxxflags="-std=c++11 -stdlib=libc++" \
# variant=release linkflags="-stdlib=libc++" architecture=${ARCHITECTURE} target-os=iphone \
# address-model=${ADDRESS_MODEL} abi=${ABI} binary-format=mach-o \
# macosx-version=${BOOST_PLAT}-${SDK_VER} define=_LITTLE_ENDIAN link=static install

./b2 --prefix=${ROOTDIR} \
	 --toolset=gcc-${TOOLSET} abi=${ABI} address-model=${ADDRESS_MODEL} \
	 variant=release binary-format=elf \
	 link=static threading=multi \
	--layout=versioned target-os=android install 


# Combine boost libraries into one static archive
echo ==ROOTDIR======${ROOTDIR} =========$(find "${ROOTDIR}/lib" -name "libboost_*.a" -print)
mkdir -p "${BOOST_SOURCE_NAME}/tmp/obj"
for a in $(find "${ROOTDIR}/lib" -name "libboost_*.a" -print); do

	echo Decomposing $a...
	(cd ${BOOST_SOURCE_NAME}/tmp/obj; ${AR} -x $a );

done

OBJFILES=`find "${BOOST_SOURCE_NAME}/tmp/obj" -name "*.o" -print`
${AR} rv "${ROOTDIR}/lib/libboost.a" $OBJFILES
#find "${ROOTDIR}/lib" -name "libboost_*.a" -exec rm -f {} \;

#===============================================================================

# Clean up
popd
#rm -rf "${BOOST_SOURCE_NAME}"
