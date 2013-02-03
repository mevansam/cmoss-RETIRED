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

BOOST_SOURCE_NAME=boost_${BOOST_VERSION//./_}

# Download source
if [ ! -e "${BOOST_SOURCE_NAME}.tar.gz" ]
then
  curl $PROXY -O "http://surfnet.dl.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_SOURCE_NAME}.tar.gz"
fi

# Build

#===============================================================================
# Filename:  boost.sh
# Author:    Pete Goodliffe
# Copyright: (c) Copyright 2009 Pete Goodliffe
# Licence:   Please feel free to use this, with attribution
#===============================================================================
#
# Builds a Boost framework for the iPhone.
# Creates a set of universal libraries that can be used on an iPhone and in the
# iPhone simulator. Then creates a pseudo-framework to make using boost in Xcode
# less painful.
#
# To configure the script, define:
#    BOOST_LIBS:        which libraries to build
#    BOOST_VERSION:     version number of the boost library (e.g. 1_41_0)
#    IPHONE_SDKVERSION: iPhone SDK version (e.g. 3.0)
#
# Then go get the source tar.bz of the boost you want to build, shove it in the
# same directory as this script, and run "./boost.sh". Grab a cuppa. And voila.
#===============================================================================

: ${IPHONE_SDKVERSION:=${SDK}}
: ${BOOST_LIBS:="date_time filesystem program_options regex signals system thread iostreams"}
: ${EXTRA_CPPFLAGS:="-Os -DBOOST_AC_USE_PTHREADS -DBOOST_SP_USE_PTHREADS"}

# The EXTRA_CPPFLAGS definition works around a thread race issue in
# shared_ptr. I encountered this historically and have not verified that
# the fix is no longer required. Without using the posix thread primitives
# an invalid compare-and-swap ARM instruction (non-thread-safe) was used for the
# shared_ptr use count causing nasty and subtle bugs.
#
# Should perhaps also consider/use instead: -BOOST_SP_USE_PTHREADS

: ${TARBALLDIR:=`pwd`}
: ${SRCDIR:=`pwd`/boost/src}
: ${BUILDDIR:=`pwd`/boost/build}
: ${PREFIXDIR:=`pwd`/boost/prefix}

BOOST_TARBALL=$TARBALLDIR/${BOOST_SOURCE_NAME}.tar.gz
BOOST_SRC=$SRCDIR/${BOOST_SOURCE_NAME}

#===============================================================================

ARM_DEV_DIR=${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/
SIM_DEV_DIR=${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/usr/bin/

ARM_COMBINED_LIB=$BUILDDIR/lib_boost_arm.a
SIM_COMBINED_LIB=$BUILDDIR/lib_boost_x86.a

#===============================================================================

echo "BOOST_VERSION:     $BOOST_VERSION"
echo "BOOST_LIBS:        $BOOST_LIBS"
echo "BOOST_TARBALL:     $BOOST_TARBALL"
echo "BOOST_SRC:         $BOOST_SRC"
echo "BUILDDIR:          $BUILDDIR"
echo "PREFIXDIR:         $PREFIXDIR"
echo "IPHONE_SDKVERSION: $IPHONE_SDKVERSION"
echo

#===============================================================================
# Functions
#===============================================================================

abort()
{
    echo
    echo "Aborted: $@"
    exit 1
}

doneSection()
{
    echo
    echo "    ================================================================="
    echo "    Done"
    echo
}

#===============================================================================

cleanEverythingReadyToStart()
{
    echo Cleaning everything before we start to build...
    rm -rf $BOOST_SRC
    rm -rf $BUILDDIR
    rm -rf $PREFIXDIR
    doneSection
}

#===============================================================================
unpackBoost()
{
    echo Unpacking boost into $SRCDIR...
    [ -d $SRCDIR ]    || mkdir -p $SRCDIR
    [ -d $BOOST_SRC ] || ( cd $SRCDIR; tar zxvf $BOOST_TARBALL )
    [ -d $BOOST_SRC ] && echo "    ...unpacked as $BOOST_SRC"
    doneSection
}

#===============================================================================

writeBjamUserConfig()
{
    # You need to do this to point bjam at the right compiler
    # ONLY SEEMS TO WORK IN HOME DIR GRR
    echo Writing usr-config
    #mkdir -p $BUILDDIR
    #cat > ~/user-config.jam <<EOF
    cat >> $BOOST_SRC/tools/build/v2/user-config.jam <<EOF
using darwin : ${SDK}~iphone
   : ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc -arch armv7 -mthumb -fvisibility=hidden -fvisibility-inlines-hidden $EXTRA_CPPFLAGS
   : <striper>
   : <architecture>arm <target-os>iphone
   ;
using darwin : ${SDK}~iphonesim
   : ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc -arch i386 -fvisibility=hidden -fvisibility-inlines-hidden $EXTRA_CPPFLAGS
   : <striper>
   : <architecture>x86 <target-os>iphone
   ;
EOF
    doneSection
}

#===============================================================================

inventMissingHeaders()
{
    # These files are missing in the ARM iPhoneOS SDK, but they are in the simulator.
    # They are supported on the device, so we copy them from x86 SDK to a staging area
    # to use them on ARM, too.
    echo Invent missing headers
    cp ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk/usr/include/{crt_externs,bzlib}.h $BOOST_SRC
}

#===============================================================================

bootstrapBoost()
{
    cd $BOOST_SRC
    BOOST_LIBS_COMMA=$(echo $BOOST_LIBS | sed -e "s/ /,/g")
    echo "Bootstrapping (with libs $BOOST_LIBS_COMMA)"
    ./bootstrap.sh --with-libraries=$BOOST_LIBS_COMMA
    doneSection
}

#===============================================================================

buildBoostForiPhoneOS()
{
    cd $BOOST_SRC

    ./bjam --prefix="$PREFIXDIR" toolset=darwin architecture=arm target-os=iphone macosx-version=iphone-${IPHONE_SDKVERSION} define=_LITTLE_ENDIAN link=static install
    doneSection

    ./bjam toolset=darwin architecture=x86 target-os=iphone macosx-version=iphonesim-${IPHONE_SDKVERSION} link=static stage
    doneSection
}

#===============================================================================

scrunchAllLibsTogetherInOneLibPerPlatform()
{
    ALL_LIBS_ARM=""
    ALL_LIBS_SIM=""
    for NAME in $BOOST_LIBS; do
        ALL_LIBS_ARM="$ALL_LIBS_ARM $BOOST_SRC/bin.v2/libs/$NAME/build/darwin-${SDK}~iphone/release/architecture-arm/link-static/macosx-version-iphone-$IPHONE_SDKVERSION/target-os-iphone/threading-multi/libboost_$NAME.a";
        ALL_LIBS_SIM="$ALL_LIBS_SIM $BOOST_SRC/bin.v2/libs/$NAME/build/darwin-${SDK}~iphonesim/release/architecture-x86/link-static/macosx-version-iphonesim-$IPHONE_SDKVERSION/target-os-iphone/threading-multi/libboost_$NAME.a";
    done;

    mkdir -p $BUILDDIR/armv6/obj
    mkdir -p $BUILDDIR/armv7/obj
    mkdir -p $BUILDDIR/i386/obj

    mkdir -p ${TMPDIR}/build/ios/iPhoneOS-V6/lib
    mkdir -p ${TMPDIR}/build/ios/iPhoneOS-V7/lib
    mkdir -p ${TMPDIR}/build/ios/iPhoneSimulator/lib

    ALL_LIBS=""

    echo Splitting all existing fat binaries...
    for NAME in $BOOST_LIBS; do
        ALL_LIBS="$ALL_LIBS libboost_$NAME.a"
        lipo "$BOOST_SRC/bin.v2/libs/$NAME/build/darwin-${SDK}~iphone/release/architecture-arm/link-static/macosx-version-iphone-$IPHONE_SDKVERSION/target-os-iphone/threading-multi/libboost_$NAME.a" -thin armv6 -o $BUILDDIR/armv6/libboost_$NAME.a
        lipo "$BOOST_SRC/bin.v2/libs/$NAME/build/darwin-${SDK}~iphone/release/architecture-arm/link-static/macosx-version-iphone-$IPHONE_SDKVERSION/target-os-iphone/threading-multi/libboost_$NAME.a" -thin armv7 -o $BUILDDIR/armv7/libboost_$NAME.a
        cp "$BOOST_SRC/bin.v2/libs/$NAME/build/darwin-${SDK}~iphonesim/release/architecture-x86/link-static/macosx-version-iphonesim-$IPHONE_SDKVERSION/target-os-iphone/threading-multi/libboost_$NAME.a" $BUILDDIR/i386/libboost_$NAME.a

        cp $BUILDDIR/armv6/libboost_$NAME.a ${TMPDIR}/build/ios/iPhoneOS-V6/lib
        cp $BUILDDIR/armv7/libboost_$NAME.a ${TMPDIR}/build/ios/iPhoneOS-V7/lib
        cp $BUILDDIR/i386/libboost_$NAME.a ${TMPDIR}/build/ios/iPhoneSimulator/lib
    done

    echo "Decomposing each architecture's .a files"
    for NAME in $ALL_LIBS; do
        echo Decomposing $NAME...
        (cd $BUILDDIR/armv6/obj; ar -x ../$NAME );
        (cd $BUILDDIR/armv7/obj; ar -x ../$NAME );
        (cd $BUILDDIR/i386/obj; ar -x ../$NAME );
    done

    echo "Linking each architecture into an uberlib ($ALL_LIBS => libboost.a )"
    rm -f ${TMPDIR}/build/ios/*/lib/libboost.a
    echo ...armv6
    (cd $BUILDDIR/armv6; $ARM_DEV_DIR/ar crus ${TMPDIR}/build/ios/iPhoneOS-V6/lib/libboost.a obj/*.o; )
    echo ...armv7
    (cd $BUILDDIR/armv7; $ARM_DEV_DIR/ar crus ${TMPDIR}/build/ios/iPhoneOS-V7/lib/libboost.a obj/*.o; )
    echo ...i386
    (cd $BUILDDIR/i386;  $SIM_DEV_DIR/ar crus ${TMPDIR}/build/ios/iPhoneSimulator/lib/libboost.a obj/*.o; )

    echo "Copying header files"
    cp -r ${PREFIXDIR}/include ${TMPDIR}/build/ios/iPhoneOS-V6
    cp -r ${PREFIXDIR}/include ${TMPDIR}/build/ios/iPhoneOS-V7
    cp -r ${PREFIXDIR}/include ${TMPDIR}/build/ios/iPhoneSimulator
}

#===============================================================================
# Execution starts here
#===============================================================================

[ -f "$BOOST_TARBALL" ] || abort "Source tarball missing."

mkdir -p $BUILDDIR

cleanEverythingReadyToStart
unpackBoost
inventMissingHeaders
writeBjamUserConfig
bootstrapBoost
buildBoostForiPhoneOS
scrunchAllLibsTogetherInOneLibPerPlatform

echo "Completed successfully"

#===============================================================================

# Clean up
rm -rf "$TARBALLDIR/boost"
