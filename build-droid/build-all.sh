#!/bin/bash
set -e

# Retrieve NDK path to use
NDK=$1
if [ "${NDK}" == "" ] || [ ! -e ${NDK}/build/tools/make-standalone-toolchain.sh ]
then
  echo "Please specify a valid NDK path."
  exit 1
fi

export SDK="${NDK}"

if [ -z $2 ]
then
	export PROXY=""
else
	export PROXY="-x $2"
fi

# Project version to use to build zlib (changing this may break the build)
export ZLIB_VERSION="1.2.7"
export MINIZIP_VERSION="101h"

# Project version to use to build icu (changing this may break the build)
export ICU_VERSION=4.8.1.1

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
export CURL_VERSION="7.24.0"

# Project version to use to build expat (changing this may break the build)
export EXPAT_VERSION="2.0.1"

# Project version to use to build yajl (changing this may break the build)
export YAJL_VERSION="2.0.1"

# Project version to use to build sqlcipher
export SQLCIPHER_VERSION="2.0.3"

# Project versions to use for SOCI (Sqlite3 C++ database library)
export SOCI_VERSION="3.1.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION=1.49.0

# Project version to use to build pion (changing this may break the build)
export PION_VERSION=4.0.11

# Create dist folder
BUILDDIR=$(dirname $0)

pushd $BUILDDIR
export TOPDIR=$(dirname $(pwd))
export BINDIR=$TOPDIR/bin/droid
export LOGDIR=$TOPDIR/log/droid
export TMPDIR=$TOPDIR/tmp
popd

rm -rf $LOGDIR
mkdir -p $LOGDIR
mkdir -p $TMPDIR

pushd $TMPDIR

ANDROID_API_LEVEL="14"
TOOLCHAIN_VERSION="4.4.3"

# Platforms to build for (changing this may break the build)
#PLATFORMS="i686-android-linux arm-linux-androideabi"
PLATFORMS="arm-linux-androideabi"

# Create tool chains for each supported platform
for PLATFORM in ${PLATFORMS}
do
	echo "Creating toolchain for platform ${PLATFORM}..."

	if [ "${PLATFORM}" == "arm-linux-androideabi" ]
	then
		export TC_PLATFORM=${PLATFORM}
	else
		export TC_PLATFORM="x86"
	fi

	if [ ! -d "${TMPDIR}/droidtoolchains/${PLATFORM}" ]
	then
		$NDK/build/tools/make-standalone-toolchain.sh \
			--verbose \
			--platform=android-${ANDROID_API_LEVEL} \
			--toolchain=${TC_PLATFORM}-${TOOLCHAIN_VERSION} \
			--install-dir=${TMPDIR}/droidtoolchains/${PLATFORM}
	fi
done

# Build projects
for PLATFORM in ${PLATFORMS}
do
	LOGPATH="${LOGDIR}/${PLATFORM}"
	ROOTDIR="${TMPDIR}/build/droid/${PLATFORM}"

	mkdir -p "${ROOTDIR}"

	if [ "${PLATFORM}" == "arm-linux-androideabi" ]
	then
		export ARCH="armv7"
	else
		export ARCH="x86"
	fi

	export ROOTDIR=${ROOTDIR}
	export PLATFORM=${PLATFORM}
	export DROIDTOOLS=${TMPDIR}/droidtoolchains/${PLATFORM}/bin/${PLATFORM}
	export SYSROOT=${TMPDIR}/droidtoolchains/${PLATFORM}/sysroot

	# Build zlib
	${TOPDIR}/build-droid/build-zlib.sh > "${LOGPATH}-zlib.log"

	# Build minizip
	${TOPDIR}/build-droid/build-minizip.sh > "${LOGPATH}-minizip.log"

	# Build icu
	${TOPDIR}/build-droid/build-icu.sh > "${LOGPATH}-icu.log"

	# Build c-ares
	${TOPDIR}/build-droid/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	${TOPDIR}/build-droid/build-bzip2.sh > "${LOGPATH}-bzip2.log"

	# Build libgpg-error
	${TOPDIR}/build-droid/build-libgpg-error.sh > "${LOGPATH}-libgpg-error.log"

	# Build libgcrypt
	${TOPDIR}/build-droid/build-libgcrypt.sh > "${LOGPATH}-libgcrypt.log"

	# Build GnuPG
	${TOPDIR}/build-droid/build-GnuPG.sh > "${LOGPATH}-GnuPG.log"

	# Build OpenSSL
	${TOPDIR}/build-droid/build-openssl.sh > "${LOGPATH}-OpenSSL.log"

	# Build libssh2
	${TOPDIR}/build-droid/build-libssh2.sh > "${LOGPATH}-libssh2.log"

	# Build cURL
	${TOPDIR}/build-droid/build-cURL.sh > "${LOGPATH}-cURL.log"

	# Build expat
	${TOPDIR}/build-droid/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	${TOPDIR}/build-droid/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	${TOPDIR}/build-droid/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	${TOPDIR}/build-droid/build-soci.sh > "${LOGPATH}-soci.log"

	# Build BOOST
	${TOPDIR}/build-droid/build-boost.sh > "${LOGPATH}-boost.log"

	# Build PION
	${TOPDIR}/build-droid/build-pion.sh > "${LOGPATH}-pion.log"

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

mkdir -p ${BINDIR}/include
cp -r ${TMPDIR}/build/droid/arm-linux-androideabi/include ${BINDIR}/

#mkdir -p ${BINDIR}/lib/x86
mkdir -p ${BINDIR}/lib/armv7

#cp ${TMPDIR}/build/droid/i686-android-linux/lib/*.a ${BINDIR}/lib/x86
#cp ${TMPDIR}/build/droid/i686-android-linux/lib/*.la ${BINDIR}/lib/x86

#(cd ${TMPDIR}/build/droid/i686-android-linux/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/x86 && tar xfB - )
#(cd ${TMPDIR}/build/droid/i686-android-linux/lib && tar cf - *.so.* ) | ( cd ${BINDIR}/lib/x86 && tar xfB - )

cp ${TMPDIR}/build/droid/arm-linux-androideabi/lib/*.a ${BINDIR}/lib/armv7
cp ${TMPDIR}/build/droid/arm-linux-androideabi/lib/*.la ${BINDIR}/lib/armv7

(cd ${TMPDIR}/build/droid/arm-linux-androideabi/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/armv7 && tar xfB - )
#(cd ${TMPDIR}/build/droid/arm-linux-androideabi/lib && tar cf - *.so.* ) | ( cd ${BINDIR}/lib/armv7 && tar xfB - )

echo "**** Android c/c++ open source build completed ****"

popd
