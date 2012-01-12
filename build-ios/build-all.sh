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

# Project version to use to build c-ares (changing this may break the build)
export CARES_VERSION="1.7.5"

# Project version to use to build bzip2 (changing this may break the build)
export BZIP2_VERSION="1.0.6"

# GNU Crypto libraries
export LIBGPG_ERROR_VERSION="1.10"
export LIBGCRYPT_VERSION="1.5.0"
export GNUPG_VERSION="1.4.11"

# Project versions to use to build openssl (changing this may break the build)
export OPENSSL_VERSION="1.0.0f"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export LIBSSH2_VERSION="1.3.0"
export CURL_VERSION="7.23.1"

# Project version to use to build expat (changing this may break the build)
export EXPAT_VERSION="2.0.1"

# Project version to use to build yajl (changing this may break the build)
export YAJL_VERSION="2.0.1"

# Project version to use to build sqlcipher
export SQLCIPHER_VERSION="1.1.8"

# Project versions to use for SOCI (Sqlite3 C++ database library)
export SOCI_VERSION="3.1.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION=1.48.0

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

# Build projects
DEVELOPER=`xcode-select --print-path`
for PLATFORM in ${PLATFORMS}
do
	LOGPATH="${LOGDIR}/${PLATFORM}-${SDK}"
	ROOTDIR="${TMPDIR}/build/ios/${PLATFORM}-${SDK}"
	if [ "${PLATFORM}" == "iPhoneOS-V7" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="armv7"
	elif [ "${PLATFORM}" == "iPhoneOS-V6" ]
	then
		PLATFORM="iPhoneOS"
		ARCH="armv6"
	else
		ARCH="i386"
	fi
	rm -rf "${ROOTDIR}"
	mkdir -p "${ROOTDIR}"

	export DEVELOPER="${DEVELOPER}"
	export ROOTDIR="${ROOTDIR}"
	export PLATFORM="${PLATFORM}"
	export ARCH="${ARCH}"

	# Build c-ares
	${TOPDIR}/build-ios/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	${TOPDIR}/build-ios/build-bzip2.sh > "${LOGPATH}-bzip2.log"

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

	# Build expat
	${TOPDIR}/build-ios/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	${TOPDIR}/build-ios/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	${TOPDIR}/build-ios/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	${TOPDIR}/build-ios/build-soci.sh > "${LOGPATH}-soci.log"

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

done

# Build boost
${TOPDIR}/build-ios/build-boost.sh > "${LOGDIR}/boost.log"

# Create Lipo Archives and Framework bundle

DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer

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
	rm -rf $TMPDIR/build/ios/${PLATFORM}-${SDK}/obj
	mkdir -p $TMPDIR/build/ios/${PLATFORM}-${SDK}/obj
done

find $TMPDIR/build -name "*.a" -exec basename {} \; > $BINDIR/libs
for a in $(cat $BINDIR/libs | sort | uniq); do

	echo Decomposing $a...
	for PLATFORM in ${PLATFORMS}
	do
		if [ "${PLATFORM}" == "iPhoneSimulator" ]
		then
			AR="/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar"
		else
			AR="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ar"
		fi
		(cd $TMPDIR/build/ios/${PLATFORM}-${SDK}/obj; $AR -x $TMPDIR/build/ios/${PLATFORM}-${SDK}/lib/$a );
	done

	echo Creating fat archive $BINDIR/lib/$a...
	$DEVROOT/usr/bin/lipo -output "$BINDIR/lib/$a" -create -arch armv6 "$TMPDIR/build/ios/iPhoneOS-V6-$SDK/lib/$a" -arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7-$SDK/lib/$a" -arch i386 "$TMPDIR/build/ios/iPhoneSimulator-$SDK/lib/$a"

done

echo "Linking each architecture into an archive ${FRAMEWORK_NAME}.a for each platform to be built into the framework"

for PLATFORM in ${PLATFORMS}
do
	if [ "${PLATFORM}" == "iPhoneSimulator" ]
	then
		AR="/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar"
	else
		AR="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ar"
	fi
	echo ...$PLATFORM
	(cd $TMPDIR/build/ios/${PLATFORM}-${SDK}/obj; $AR crus $TMPDIR/build/ios/${PLATFORM}-${SDK}/lib/${FRAMEWORK_NAME}.a *.o; )
done

cp -r "$TMPDIR/build/ios/iPhoneSimulator-$SDK/include" "$BINDIR"

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
    lipo \
        -create \
        -arch armv6 "$TMPDIR/build/ios/iPhoneOS-V6-${SDK}/lib/${FRAMEWORK_NAME}.a" \
        -arch armv7 "$TMPDIR/build/ios/iPhoneOS-V7-${SDK}/lib/${FRAMEWORK_NAME}.a" \
        -arch i386  "$TMPDIR/build/ios/iPhoneSimulator-${SDK}/lib/${FRAMEWORK_NAME}.a" \
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

rm -rf $TMPDIR/build

echo "**** iOS ${FRAMEWORK_NAME} Framework build completed ****"

popd
