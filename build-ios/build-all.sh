#!/bin/sh
set -e

# Retrieve iOS SDK to use
SDK=$1
if [ "${SDK}" == "" ]
then
  echo "Please specify an iOS SDK version number from the following possibilities:"
  xcodebuild -showsdks | grep "iphoneos"
  exit 1
fi

export SDK="${SDK}"

if [ -z $2 ]
then
	export PROXY=""
else
	export PROXY="-x $2"
fi

# Project version to use to build minizip (changing this may break the build)
export MINIZIP_VERSION="11"

# Project version to use to build icu (changing this may break the build)
export ICU_VERSION="50.1.1"

# Project version to use to build c-ares (changing this may break the build)
export CARES_VERSION="1.9.1"

# Project version to use to build bzip2 (changing this may break the build)
export BZIP2_VERSION="1.0.6"

# Project version to use to build libidn (changing this may break the build)
export LIBIDN_VERSION="1.26"

# GNU Crypto libraries
export LIBGPG_ERROR_VERSION="1.10"
export LIBGCRYPT_VERSION="1.5.0"
export GNUPG_VERSION="1.4.13"

# Project versions to use to build openssl (changing this may break the build)
export OPENSSL_VERSION="1.0.1"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export LIBSSH2_VERSION="1.3.0"
export CURL_VERSION="7.28.1"

# Project Version to use to build libgsasl
export LIBGSASL_VERSION="1.8.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION="1.52.0"

# Project version to use to build tinyxml
export TINYXML_VERSION="2.6.2"
export TINYXML_FILE="2_6_2"

# Project version to use to build expat (changing this may break the build)
export EXPAT_VERSION="2.0.1"

# Project version to use to build yajl (changing this may break the build)
export YAJL_VERSION="2.0.1"

# Project version to use to build sqlcipher (changing this may break the build)
export SQLCIPHER_VERSION="2.1.1"

# Project versions to use for SOCI (Sqlite3 C++ database library)
export SOCI_VERSION="3.1.0"

# Project version to use to build pion (changing this may break the build)
export PION_VERSION="master"

# Create dist folder
BUILDDIR=$(dirname $0)

pushd $BUILDDIR
export TOPDIR=$(dirname $(pwd))
export BINDIR=$TOPDIR/bin/ios
export LOGDIR=$TOPDIR/log/ios
export TMPDIR=$TOPDIR/tmp
popd

rm -rf ${LOGDIR}
mkdir -p ${LOGDIR}
mkdir -p ${TMPDIR}

pushd ${TMPDIR}

# Platforms to build for (changing this may break the build)
PLATFORMS="iPhoneSimulator iPhoneOS-V6 iPhoneOS-V7"

# Location of SDK
DEVELOPER=`xcode-select --print-path`
export DEVELOPER="${DEVELOPER}"

# Build projects
for PLATFORM in ${PLATFORMS}
do
	ROOTDIR="${TMPDIR}/build/ios/${PLATFORM}"
	rm -rf "${ROOTDIR}"
	mkdir -p "${ROOTDIR}"
done

# Build BOOST
${TOPDIR}/build-ios/build-boost.sh > "${LOGDIR}/boost.log"
PLATFORMS_BUILT=""

for PLATFORM in ${PLATFORMS}
do
	p=${PLATFORM}
	echo "Building libraries for ${p}..."

	LOGPATH="${LOGDIR}/${PLATFORM}"
	ROOTDIR="${TMPDIR}/build/ios/${PLATFORM}"
	CSDK=${SDK}

	if [ "${PLATFORM}" == "iPhoneOS-V7" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="armv7"
	elif [ "${PLATFORM}" == "iPhoneOS-V6" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="armv6"
		HAS_SDK_SUPPORT=`echo "${SDK} < 6.0" | bc`

		if [ $HAS_SDK_SUPPORT == 0 ]
		then
			CSDK=5.1
		fi
	else
		ARCH="i386"
	fi

	export ROOTDIR="${ROOTDIR}"
	export PLATFORM="${PLATFORM}"
	export ARCH="${ARCH}"

	export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${CSDK}.sdk"
	if [ ! -d ${BUILD_SDKROOT} ]
	then
		rm -fr ${ROOTDIR}
		echo "WARNING! Unable to locate SDK for architecture ${ARCH}: ${BUILD_SDKROOT}"
		continue
	fi

	PLATFORMS_BUILT="${PLATFORMS_BUILT}${p} "

	export CC="${BUILD_DEVROOT}/usr/bin/gcc"
	export LD="${BUILD_DEVROOT}/usr/bin/ld"
	export CXX="${BUILD_DEVROOT}/usr/bin/g++"
	export AR="${BUILD_DEVROOT}/usr/bin/ar"
	export AS="${BUILD_DEVROOT}/usr/bin/as"
	export NM="${BUILD_DEVROOT}/usr/bin/nm"
	export STRIP="${BUILD_DEVROOT}/usr/bin/strip"
	export RANLIB="${BUILD_DEVROOT}/usr/bin/ranlib"

	# Build minizip
	${TOPDIR}/build-ios/build-minizip.sh > "${LOGPATH}-minizip.log"

	# Build icu
	${TOPDIR}/build-ios/build-icu.sh > "${LOGPATH}-icu.log"

	# Build c-ares
	${TOPDIR}/build-ios/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	${TOPDIR}/build-ios/build-bzip2.sh > "${LOGPATH}-bzip2.log"

	# Build libidn (before curl and gsasl)
	${TOPDIR}/build-ios/build-libidn.sh > "${LOGPATH}-libidn.log"

	# Build libgpg-error
	${TOPDIR}/build-ios/build-libgpg-error.sh > "${LOGPATH}-libgpg-error.log"

	# Build libgcrypt
	${TOPDIR}/build-ios/build-libgcrypt.sh > "${LOGPATH}-libgcrypt.log"

	# Build GnuPG
	${TOPDIR}/build-ios/build-GnuPG.sh > "${LOGPATH}-GnuPG.log"

	# Build OpenSSL
	${TOPDIR}/build-ios/build-openssl.sh > "${LOGPATH}-OpenSSL.log"

	# Build libssh2
	${TOPDIR}/build-ios/build-libssh2.sh > "${LOGPATH}-libssh2.log"

	# Build cURL
	${TOPDIR}/build-ios/build-cURL.sh > "${LOGPATH}-cURL.log"

	# Build libgsasl
	${TOPDIR}/build-ios/build-libgsasl.sh > "${LOGPATH}-libgsasl.log"

	# Build tinyxml
	${TOPDIR}/build-ios/build-tinyxml.sh > "${LOGPATH}-tinyxml.log"

	# Build expat
	${TOPDIR}/build-ios/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	${TOPDIR}/build-ios/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	${TOPDIR}/build-ios/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	${TOPDIR}/build-ios/build-soci.sh > "${LOGPATH}-soci.log"

	# Build PION
	${TOPDIR}/build-ios/build-pion.sh > "${LOGPATH}-pion.log"

	# Remove junk
	rm -rf "${ROOTDIR}/bin"
	rm -rf "${ROOTDIR}/certs"
	rm -rf "${ROOTDIR}/libexec"
	rm -rf "${ROOTDIR}/man"
	rm -rf "${ROOTDIR}/misc"
	rm -rf "${ROOTDIR}/private"
	rm -rf "${ROOTDIR}/sbin"
	rm -rf "${ROOTDIR}/share"
	rm -rf "${ROOTDIR}/openssl.cnf"
	rm -rf "${ROOTDIR}/obj"

done

PLATFORMS=`echo ${PLATFORMS_BUILT}`
echo "Build completed for platforms: ${PLATFORMS}"

# Remove individual boost libraries as all were combined into one 
# libboost.a (comment this line if individual libraries are required)
find ${TMPDIR}/build/ios -name "libboost_*.*" -exec rm -f {} \;

# Create Lipo Archives and Framework bundle

BUILD_DEVROOT=${DEVELOPER}/Platforms/iPhoneOS.platform/Developer

VERSION_TYPE=Release
FRAMEWORK_NAME=CMOSS
FRAMEWORK_VERSION=A

FRAMEWORK_CURRENT_VERSION=1.0
FRAMEWORK_COMPATIBILITY_VERSION=1.0

FRAMEWORK_BUNDLE="$BINDIR/$FRAMEWORK_NAME.framework"

mkdir -p $BINDIR/lib
mkdir -p $BINDIR/include

rm -f $TMPDIR/build/ios*/lib/${FRAMEWORK_NAME}.a
for PLATFORM in ${PLATFORMS}
do
	rm -rf $TMPDIR/build/ios/${PLATFORM}/obj
	mkdir -p $TMPDIR/build/ios/${PLATFORM}/obj
done

find $TMPDIR/build/ios -name "*.a" -exec basename {} \; > $BINDIR/libs
for a in $(cat $BINDIR/libs | sort | uniq); do

	echo Decomposing $a...
	for PLATFORM in ${PLATFORMS}
	do
		if [ "${PLATFORM}" == "iPhoneSimulator" ]
		then
			AR="${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar"
		else
			AR="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/ar"
		fi
		(cd $TMPDIR/build/ios/${PLATFORM}/obj; $AR -x $TMPDIR/build/ios/${PLATFORM}/lib/$a );
	done

	echo Creating fat archive $BINDIR/lib/$a...
	if [[ "${PLATFORMS}" == *iPhoneOS-V6* ]]
	then
		$BUILD_DEVROOT/usr/bin/lipo -output "$BINDIR/lib/$a" -create \
			-arch armv6 "$TMPDIR/build/ios/iPhoneOS-V6/lib/$a" \
			-arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7/lib/$a" \
			-arch i386 "$TMPDIR/build/ios/iPhoneSimulator/lib/$a"
	else
		$BUILD_DEVROOT/usr/bin/lipo -output "$BINDIR/lib/$a" -create \
			-arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7/lib/$a" \
			-arch i386 "$TMPDIR/build/ios/iPhoneSimulator/lib/$a"
	fi

done
rm -f $BINDIR/libs

echo "Linking each architecture into an archive ${FRAMEWORK_NAME}.a for each platform to be built into the framework"

for PLATFORM in ${PLATFORMS}
do
	if [ "${PLATFORM}" == "iPhoneSimulator" ]
	then
		AR="${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar"
	else
		AR="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/ar"
	fi
	echo ...$PLATFORM
	(cd $TMPDIR/build/ios/${PLATFORM}/obj; $AR crus $TMPDIR/build/ios/${PLATFORM}/lib/${FRAMEWORK_NAME}.a *.o; )
done

cp -r "$TMPDIR/build/ios/iPhoneSimulator/include" "$BINDIR"

rm -rf $FRAMEWORK_BUNDLE

echo "Framework: Setting up directories..."
mkdir -p $FRAMEWORK_BUNDLE
mkdir -p $FRAMEWORK_BUNDLE/Versions
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Resources
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Headers
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Documentation

echo "Framework: Creating symlinks..."
ln -s $FRAMEWORK_VERSION               $FRAMEWORK_BUNDLE/Versions/Current
ln -s Versions/Current/Headers         $FRAMEWORK_BUNDLE/Headers
ln -s Versions/Current/Resources       $FRAMEWORK_BUNDLE/Resources
ln -s Versions/Current/Documentation   $FRAMEWORK_BUNDLE/Documentation
ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_BUNDLE/$FRAMEWORK_NAME

FRAMEWORK_INSTALL_NAME=$FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/$FRAMEWORK_NAME

echo "Lipoing library into $FRAMEWORK_INSTALL_NAME..."
if [[ "${PLATFORMS}" == *iPhoneOS-V6* ]]
then
    lipo \
        -create \
        -arch armv6 "$TMPDIR/build/ios/iPhoneOS-V6/lib/${FRAMEWORK_NAME}.a" \
        -arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7/lib/${FRAMEWORK_NAME}.a" \
        -arch i386  "$TMPDIR/build/ios/iPhoneSimulator/lib/${FRAMEWORK_NAME}.a" \
        -output     "$FRAMEWORK_INSTALL_NAME"
else
    lipo \
        -create \
        -arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7/lib/${FRAMEWORK_NAME}.a" \
        -arch i386  "$TMPDIR/build/ios/iPhoneSimulator/lib/${FRAMEWORK_NAME}.a" \
        -output     "$FRAMEWORK_INSTALL_NAME"
fi

echo "Framework: Copying includes..."
cp -r "$BINDIR/include/" "$FRAMEWORK_BUNDLE/Headers/"

echo "Framework: Creating plist..."
cat > $FRAMEWORK_BUNDLE/Resources/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>${FRAMEWORK_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>org.boost</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>${FRAMEWORK_CURRENT_VERSION}</string>
</dict>
</plist>
EOF

echo "**** iOS ${FRAMEWORK_NAME} Framework build completed ****"

popd
