#!/bin/bash
set -e

# Retrieve NDK path to use
NDK=$1
echo NDK path="$NDK"

if [ "${NDK}" == "" ] || [ ! -e ${NDK}/build/tools/make-standalone-toolchain.sh ]
then
  cat ${NDK}/build/tools/make-standalone-toolchain.sh
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

# Project version to use to build minizip (changing this may break the build)
export MINIZIP_VERSION="11"

# Project version to use to build icu (changing this may break the build)
#export ICU_VERSION="4.8.1.1"
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
export OPENSSL_VERSION="1.0.2e"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export LIBSSH2_VERSION="1.3.0"
export CURL_VERSION="7.46.0"

# Project Version to use to build libgsasl
export LIBGSASL_VERSION="1.8.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION="1.59.0"
#python
export BOOST_LIBS="atomic chrono container context coroutine \
				   coroutine2 date_time exception filesystem graph graph_parallel iostreams \
				   locale log math mpi program_options  \
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
export SOCI_VERSION="3.2.2"

# Project version to use to build pion (changing this may break the build)
export PION_VERSION="master"

# Create dist folder
BUILDDIR=$(dirname $0)

pushd $BUILDDIR
export TOPDIR=$(dirname $(pwd))
export BINDIR=$TOPDIR/bin/droid
export LOGDIR=$TOPDIR/log/droid
export TMPDIR=$TOPDIR/tmp
popd

rm -rf $LOGDIR || true
mkdir -p $LOGDIR
mkdir -p $TMPDIR

pushd $TMPDIR
#http://stackoverflow.com/questions/27091001/how-to-use-mkfifo-using-androids-ndk/27093163#27093163
#set ndk api level to 19, because 3~19's signature is same but api-level 21 change some
export ANDROID_API_LEVEL="19"
#export ARM_TARGET="armv5te"

if [ -z $TOOLCHAIN_VERSION ]
then
	export TOOLCHAIN_VERSION="4.9"
fi


echo ANDROID_API_LEVEL:           ${ANDROID_API_LEVEL}
echo TOOLCHAIN_VERSION:           ${TOOLCHAIN_VERSION}

# Platforms to build for (changing this may break the build)
#PLATFORMS="arm-linux-androideabi x86"
#PLATFORMS="arm-linux-androideabi"
#TARGETS="arm-linux-androideabi"

TARGETS="armeabi armeabi-v7a x86"

# Create tool chains for each supported platform
for TARGET in ${TARGETS}
do
	echo "Checking toolchain for platform ${TARGET}..."

	if [ "${TARGET}" == "x86" ]
	then
		PLATFORM=x86
	else
		PLATFORM=arm-linux-androideabi
	fi

	if [ ! -d "${TMPDIR}/droidtoolchains/${TARGET}" ]
	then
		echo "Creating toolchain for platform ${TARGET}..."
		$NDK/build/tools/make-standalone-toolchain.sh \
			--verbose \
			--platform=android-${ANDROID_API_LEVEL} \
			--toolchain=${PLATFORM}-${TOOLCHAIN_VERSION} \
			--install-dir=${TMPDIR}/droidtoolchains/${TARGET}
	fi
done

# Build projects
for TARGET in ${TARGETS}
do

	if [ "${TARGET}" == "x86" ]
	then
		TOOL_PREFIX=i686-linux-android
	else
		TOOL_PREFIX=arm-linux-androideabi
	fi
	LOGPATH="${LOGDIR}/${TARGET}"
	ROOTDIR="${TMPDIR}/build/droid/${TARGET}"

	mkdir -p "${ROOTDIR}"


	if [ "${TARGET}" == "armeabi" ]
	then
		ARCH="armv5te"
		ARCHITECTURE="arm"
		ADDRESS_MODEL=32
		ABI=aapcs
		APP_ABI=armeabi
		TOOLSET=armv5
	elif [ "${TARGET}" == "armeabi-v7a" ]
	then
		ARCH="armv7-a"
		ARCHITECTURE="arm"
		ADDRESS_MODEL=32
		ABI=aapcs
		APP_ABI=armeabi-v7a
		TOOLSET=armv7
	elif [ "${TARGET}" == "x86" ]
	then
		ARCH="i686"
		ARCHITECTURE="x86"
		ADDRESS_MODEL=32
		ABI=sysv
		APP_ABI=x86
		TOOLSET=i686
	else
		echo "${TARGET} not supported"
	fi
	

	export ROOTDIR=${ROOTDIR}
	export DROIDTOOLS=${TMPDIR}/droidtoolchains/${TARGET}/bin/${TOOL_PREFIX}
	export SYSROOT=${TMPDIR}/droidtoolchains/${TARGET}/sysroot
	export ARCH="${ARCH}"
	export ARCHITECTURE="${ARCHITECTURE}"
	export ADDRESS_MODEL="${ADDRESS_MODEL}"
	export ABI="${ABI}"
	export APP_ABI="${APP_ABI}"
	export TOOLSET="${TOOLSET}"

	echo ROOTDIR:               ${ROOTDIR}
	echo TOOL_PREFIX:           ${TOOL_PREFIX}
	echo DROIDTOOLS:            ${DROIDTOOLS}
	echo SYSROOT:			 	${SYSROOT}
	echo ARCH:			 		${ARCH}
	echo ARCHITECTURE:			${ARCHITECTURE}
	echo ADDRESS_MODEL:			${ADDRESS_MODEL}
	echo ABI:					${ABI}
	echo APP_ABI:				${APP_ABI}
	echo TOOLSET:				${TOOLSET}
	export CC="${DROIDTOOLS}-gcc"
	export LD="${DROIDTOOLS}-ld"
	export CXX="${DROIDTOOLS}-g++"
	export AR="${DROIDTOOLS}-ar"
	export AS="${DROIDTOOLS}-as"
	export NM="${DROIDTOOLS}-nm"
	export STRIP="${DROIDTOOLS}-strip"
	export RANLIB="${DROIDTOOLS}-ranlib"

	echo CC:             ${CC}
	echo LD:             ${LD}
	echo CXX:            ${CXX}
	echo AR:			 ${AR}
	echo AS:			 ${AS}
	echo NM:			 ${NM}
	echo STRIP:			 ${STRIP}
	echo RANLIB:		 ${RANLIB}

	# Build minizip
	#${TOPDIR}/build-droid/build-minizip.sh > "${LOGPATH}-minizip.log"

	# Build icu
	#${TOPDIR}/build-droid/build-icu.sh > "${LOGPATH}-icu.log"

	# Build c-ares
	#${TOPDIR}/build-droid/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	${TOPDIR}/build-droid/build-bzip2.sh > "${LOGPATH}-bzip2.log"

	# Build libidn (before curl and gsasl)
	#${TOPDIR}/build-droid/build-libidn.sh > "${LOGPATH}-libidn.log"

	# Build libgpg-error
	#${TOPDIR}/build-droid/build-libgpg-error.sh > "${LOGPATH}-libgpg-error.log"

	# Build libgcrypt
	#${TOPDIR}/build-droid/build-libgcrypt.sh > "${LOGPATH}-libgcrypt.log"

	# Build GnuPG
	#${TOPDIR}/build-droid/build-GnuPG.sh > "${LOGPATH}-GnuPG.log"

	# Build OpenSSL
	${TOPDIR}/build-droid/build-openssl.sh > "${LOGPATH}-OpenSSL.log"

	# Build libssh2
	#${TOPDIR}/build-droid/build-libssh2.sh > "${LOGPATH}-libssh2.log"

	# Build cURL
	${TOPDIR}/build-droid/build-cURL.sh > "${LOGPATH}-cURL.log"

	# Build libgsasl
	#${TOPDIR}/build-droid/build-libgsasl.sh > "${LOGPATH}-libgsasl.log"

	# Build BOOST
	${TOPDIR}/build-droid/build-boost.sh > "${LOGPATH}-boost.log"

	# Build tinyxml
	#${TOPDIR}/build-droid/build-tinyxml.sh > "${LOGPATH}-tinyxml.log"

	# Build expat
	#${TOPDIR}/build-droid/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	#${TOPDIR}/build-droid/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	#${TOPDIR}/build-droid/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	#${TOPDIR}/build-droid/build-soci.sh > "${LOGPATH}-soci.log"

	# Build PION
	#${TOPDIR}/build-droid/build-pion.sh > "${LOGPATH}-pion.log"

	# Remove junk
	rm -rf "${ROOTDIR}/bin" || true
	rm -rf "${ROOTDIR}/certs" || true
	rm -rf "${ROOTDIR}/libexec" || true
	rm -rf "${ROOTDIR}/man" || true
	rm -rf "${ROOTDIR}/misc" || true
	rm -rf "${ROOTDIR}/private" || true
	rm -rf "${ROOTDIR}/sbin" || true
	rm -rf "${ROOTDIR}/share" || true
	rm -rf "${ROOTDIR}/openssl.cnf" || true

done



for TARGET in ${TARGETS}
do
	mkdir -p ${BINDIR}/include
	cp -r ${TMPDIR}/build/droid/${TARGET}/include ${BINDIR}/

	#mkdir -p ${BINDIR}/lib/x86
	mkdir -p ${BINDIR}/lib/${TARGET}

	#cp ${TMPDIR}/build/droid/i686-android-linux/lib/*.a ${BINDIR}/lib/x86
	#cp ${TMPDIR}/build/droid/i686-android-linux/lib/*.la ${BINDIR}/lib/x86

	#(cd ${TMPDIR}/build/droid/i686-android-linux/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/x86 && tar xfB - )
	#(cd ${TMPDIR}/build/droid/i686-android-linux/lib && tar cf - *.so.* ) | ( cd ${BINDIR}/lib/x86 && tar xfB - )

	cp ${TMPDIR}/build/droid/${TARGET}/lib/*.a ${BINDIR}/lib/${TARGET}
	cp ${TMPDIR}/build/droid/${TARGET}/lib/*.la ${BINDIR}/lib/${TARGET} || true

	(cd ${TMPDIR}/build/droid/${TARGET}/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/${TARGET} && tar xfB - )
	#(cd ${TMPDIR}/build/droid/arm-linux-androideabi/lib && tar cf - *.so.* ) | ( cd ${BINDIR}/lib/${ARM_TARGET} && tar xfB - )

done


echo "**** Android c/c++ open source build completed ****"

popd
