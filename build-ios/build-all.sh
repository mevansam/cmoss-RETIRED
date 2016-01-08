#!/bin/sh
set -e

# Retrieve iOS SDK VERSION to use
SDK_VER=$1
if [ "${SDK_VER}" == "" ]
then
  echo "Please specify an iOS SDK version number from the following possibilities:"
  xcodebuild -showsdks | grep "iphoneos"
  exit 1
fi

export SDK_VER="${SDK_VER}"

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
export CURL_VERSION="7.46.0"

# Project Version to use to build libgsasl
export LIBGSASL_VERSION="1.8.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION="1.59.0"
#context, thread lib not supported
export BOOST_LIBS="atomic chrono container context coroutine \
				   coroutine2 date_time exception filesystem graph graph_parallel iostreams \
				   locale log math mpi program_options \
				   random regex serialization signals system test thread timer wave"

# Project version to use to build tinyxml
export TINYXML_VERSION="2.6.2"
export TINYXML_FILE="2_6_2"

# Project version to use to build expat (changing this may break the build)
export EXPAT_VERSION="2.0.1"

# Project version to use to build yajl (changing this may break the build)
export YAJL_VERSION="2.0.3"

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
#iPhoneSimulator
#PLATFORMS="iPhoneOS_arm iPhoneOS_arm64"
TARGETS="iPhoneSimulator iPhoneOS_arm64 iPhoneOS_armv7"
#PLATFORMS="iPhoneSimulator iPhoneOS iPhoneSimulator"
# Location of SDK
DEVELOPER=`xcode-select --print-path`
export DEVELOPER="${DEVELOPER}"

# Build projects
for TARGET in ${TARGETS}
do
	ROOTDIR="${TMPDIR}/build/ios/${TARGET}"
	rm -rf "${ROOTDIR}" || true
	mkdir -p "${ROOTDIR}"
done


for TARGET in ${TARGETS}
do

	echo "Building libraries for target platform: ${TARGET}..."

	LOGPATH="${LOGDIR}/${TARGET}"
	ROOTDIR="${TMPDIR}/build/ios/${TARGET}"
	
	ADDRESS_MODEL=32
	PLATFORM="iPhoneOS"
	if [ "${TARGET}" == "iPhoneOS_armv7" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="armv7"
		ARCHITECTURE="arm"
		ADDRESS_MODEL=32
		ABI=aapcs
	elif [ "${TARGET}" == "iPhoneOS_arm64" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="arm64"
		ARCHITECTURE="arm"
		ADDRESS_MODEL=64
		ABI=aapcs
	elif [ "${TARGET}" == "iPhoneSimulator" ]
	then
		PLATFORM="iPhoneSimulator"
		ARCH="i386"
		ARCHITECTURE="x86"
		ADDRESS_MODEL=32_64
		ABI=sysv
	else
		PLATFORM="MacOSX"
		ARCH="i386"
		ARCHITECTURE="x86"
		ADDRESS_MODEL=32_64
		ABI=sysv
	fi

	SDK_NAME=iphoneos${SDK_VER}
	if [ "${PLATFORM}" == "iPhoneOS" ]
	then
		SDK_NAME=iphoneos${SDK_VER}
	elif [ "${PLATFORM}" == "iPhoneSimulator" ]
	then
		SDK_NAME=iphonesimulator${SDK_VER}
	else
		SDK_NAME=macosx${SDK_VER}
	fi

	export SDK_NAME="${SDK_NAME}"
	export ROOTDIR="${ROOTDIR}"
	export PLATFORM="${PLATFORM}"
	export ARCH="${ARCH}"
	export ARCHITECTURE="${ARCHITECTURE}"
	export ADDRESS_MODEL="${ADDRESS_MODEL}"
	export ABI="${ABI}"

	export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${SDK_VER}.sdk"


	echo exported SDK_NAME: 	${SDK_NAME}
	echo exported ROOTDIR: 		${ROOTDIR}
	echo exported PLATFORM: 	${PLATFORM}
	echo exported ARCH: 		${ARCH}
	echo exported ARCHITECTURE: ${ARCHITECTURE}
	echo exported ADDRESS_MODEL:${ADDRESS_MODEL}
	echo exported ABI: 			${ABI}
	echo exported BUILD_DEVROOT:${BUILD_DEVROOT}
	echo exported BUILD_SDKROOT:${BUILD_SDKROOT}

	if [ ! -d ${BUILD_SDKROOT} ]
	then
		rm -fr ${ROOTDIR} || true
		echo "WARNING! Unable to locate SDK for architecture ${ARCH}: ${BUILD_SDKROOT}"
		continue
	fi

	PLATFORMS_BUILT="${PLATFORMS_BUILT}${TARGET} "

	export CC="$(xcrun --sdk ${SDK_NAME} -find clang)"
	export LD="$(xcrun --sdk ${SDK_NAME} -find ld)"
	export CXX="$(xcrun --sdk ${SDK_NAME} -find clang++)"
	export AR="$(xcrun --sdk ${SDK_NAME} -find ar)"
	export AS="$(xcrun --sdk ${SDK_NAME} -find as)"
	export NM="$(xcrun --sdk ${SDK_NAME} -find nm)"
	export STRIP="$(xcrun --sdk ${SDK_NAME} -find strip)"
	export RANLIB="$(xcrun --sdk ${SDK_NAME} -find ranlib)"

	echo CC:             ${CC}
	echo LD:             ${LD}
	echo CXX:            ${CXX}
	echo AR:			 ${AR}
	echo AS:			 ${AS}
	echo NM:			 ${NM}
	echo STRIP:			 ${STRIP}
	echo RANLIB:		 ${RANLIB}
	# Build minizip
	#${TOPDIR}/build-ios/build-minizip.sh > "${LOGPATH}-minizip.log"

	# Build icu
	#${TOPDIR}/build-ios/build-icu.sh #> "${LOGPATH}-icu.log"

	# Build c-ares
	#${TOPDIR}/build-ios/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	#${TOPDIR}/build-ios/build-bzip2.sh > "${LOGPATH}-bzip2.log"

	# Build libidn (before curl and gsasl)
	#${TOPDIR}/build-ios/build-libidn.sh > "${LOGPATH}-libidn.log"

	# Build libgpg-error
	#${TOPDIR}/build-ios/build-libgpg-error.sh > "${LOGPATH}-libgpg-error.log"

	# Build libgcrypt
	#${TOPDIR}/build-ios/build-libgcrypt.sh > "${LOGPATH}-libgcrypt.log"

	# Build GnuPG
	#${TOPDIR}/build-ios/build-GnuPG.sh > "${LOGPATH}-GnuPG.log"

	# Build OpenSSL
	${TOPDIR}/build-ios/build-openssl.sh > "${LOGPATH}-OpenSSL.log"

	# Build libssh2
	#${TOPDIR}/build-ios/build-libssh2.sh > "${LOGPATH}-libssh2.log"

	# Build cURL
	${TOPDIR}/build-ios/build-cURL.sh > "${LOGPATH}-cURL.log"

	# Build libgsasl
	#${TOPDIR}/build-ios/build-libgsasl.sh > "${LOGPATH}-libgsasl.log"

	# Build BOOST
	#echo "start build boost ${BOOST_VERSION}, be patient..."
	#${TOPDIR}/build-ios/build-boost.sh > "${LOGPATH}-boost.log"

	# Build tinyxml
	#${TOPDIR}/build-ios/build-tinyxml.sh > "${LOGPATH}-tinyxml.log"

	# Build expat
	#${TOPDIR}/build-ios/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	#${TOPDIR}/build-ios/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	#${TOPDIR}/build-ios/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	#${TOPDIR}/build-ios/build-soci.sh > "${LOGPATH}-soci.log"

	# Build PION
	#${TOPDIR}/build-ios/build-pion.sh > "${LOGPATH}-pion.log"

	# Remove junk
	rm -rf "${ROOTDIR}/bin" || true
	rm -rf "${ROOTDIR}/certs"  || true
	rm -rf "${ROOTDIR}/libexec"  || true
	rm -rf "${ROOTDIR}/man"  || true
	rm -rf "${ROOTDIR}/misc"  || true
	rm -rf "${ROOTDIR}/private"  || true
	rm -rf "${ROOTDIR}/sbin"  || true
	rm -rf "${ROOTDIR}/share"  || true
	rm -rf "${ROOTDIR}/openssl.cnf"  || true
	rm -rf "${ROOTDIR}/obj"  || true

done


echo "Build completed for TARGETS: ${TARGETS}"


echo BINDIR: ${BINDIR}
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

rm -f $TMPDIR/build/ios*/lib/${FRAMEWORK_NAME}.a  || true
for TARGET in ${TARGETS}
do
	rm -rf $TMPDIR/build/ios/${TARGET}/obj  || true
	mkdir -p $TMPDIR/build/ios/${TARGET}/obj
done
#if [[ "${PLATFORMS}" == *iPhoneOS-V6* ]]

find $TMPDIR/build/ios -name "*.a" -exec basename {} \; > $BINDIR/libs
for a in $(cat $BINDIR/libs | sort | uniq); do

	echo Decomposing $a...
	for TARGET in ${TARGETS}
	do
		(cd $TMPDIR/build/ios/${TARGET}/obj; $AR -x $TMPDIR/build/ios/${TARGET}/lib/$a );
	done

	echo Creating fat archive $BINDIR/lib/$a...

	/usr/bin/lipo -output "$BINDIR/lib/$a" -create \
		-arch armv7 "$TMPDIR/build/ios/iPhoneOS_armv7/lib/$a" \
		-arch arm64 "$TMPDIR/build/ios/iPhoneOS_arm64/lib/$a" \
		-arch i386 "$TMPDIR/build/ios/iPhoneSimulator/lib/$a"
done
rm -f $BINDIR/libs  || true

echo "Linking each architecture into an archive ${FRAMEWORK_NAME}.a for each platform to be built into the framework"

for TARGET in ${TARGETS}
do
	PLATFORM="iPhoneOS"
	if [ "${TARGET}" == "iPhoneOS_armv7" ]
	then
		PLATFORM="iPhoneOS"
	elif [ "${TARGET}" == "iPhoneOS_arm64" ]
	then
		PLATFORM="iPhoneOS"
	elif [ "${TARGET}" == "iPhoneSimulator" ]
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="MacOSX"
	fi

	SDK_NAME=iphoneos${SDK_VER}
	if [ "${PLATFORM}" == "iPhoneOS" ]
	then
		SDK_NAME=iphoneos${SDK_VER}
	elif [ "${PLATFORM}" == "iPhoneSimulator" ]
	then
		SDK_NAME=iphonesimulator${SDK_VER}
	else
		SDK_NAME=macosx${SDK_VER}
	fi
	AR="$(xcrun --sdk ${SDK_NAME} -find ar)"
	echo ...$PLATFORM
	(cd $TMPDIR/build/ios/${TARGET}/obj; $AR crus $TMPDIR/build/ios/${TARGET}/lib/${FRAMEWORK_NAME}.a *.o; )
done


if [ -d $TMPDIR/build/ios/iPhoneSimulator/include ]
then
	cp -r "$TMPDIR/build/ios/iPhoneSimulator/include" "$BINDIR"
fi


rm -rf $FRAMEWORK_BUNDLE  || true

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
#TARGETS="iPhoneSimulator iPhoneOS_arm64 iPhoneOS_armv7"
lipo \
    -create \
    -arch armv7 "$TMPDIR/build/ios/iPhoneOS_armv7/lib/${FRAMEWORK_NAME}.a" \
    -arch arm64 "$TMPDIR/build/ios/iPhoneOS_arm64/lib/${FRAMEWORK_NAME}.a" \
    -arch i386  "$TMPDIR/build/ios/iPhoneSimulator/lib/${FRAMEWORK_NAME}.a" \
    -output     "$FRAMEWORK_INSTALL_NAME"


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
