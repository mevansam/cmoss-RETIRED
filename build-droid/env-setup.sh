#!/bin/bash

# Retrieve NDK path to use
NDK=$1
if [ "${NDK}" == "" ] || [ ! -e ${NDK}/build/tools/make-standalone-toolchain.sh ]
then
  echo "Please specify a valid NDK path."
  return 1
fi

export SDK="${NDK}"

if [ -z $2 ]
then
	export PROXY=""
else
	export PROXY="-x $2"
fi

export ANDROID_API_LEVEL="14"
export ARM_TARGET="armv7"

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
export OPENSSL_VERSION="1.0.1"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export LIBSSH2_VERSION="1.3.0"
export CURL_VERSION="7.28.1"

# Project Version to use to build libgsasl
export LIBGSASL_VERSION="1.8.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION="1.52.0"
export BOOST_LIBS="chrono context date_time exception filesystem graph graph_parallel iostreams mpi program_options random regex serialization signals system test thread timer wave"

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

# Project version to use to build protobuf (changing this may break the build)
export PROTOBUF_VERSION="2.5.0"

# Create dist folder
export BUILDDIR=$(dirname $0)

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

if [ -z $TOOLCHAIN_VERSION ]
then
	export TOOLCHAIN_VERSION="4.7"
fi

# Platforms to build for (changing this may break the build)
PLATFORMS="arm-linux-androideabi"

# Create tool chains for each supported platform
for PLATFORM in ${PLATFORMS}
do
	echo "Creating toolchain for platform ${PLATFORM}..."

	if [ ! -d "${TMPDIR}/droidtoolchains/${PLATFORM}" ]
	then
		$NDK/build/tools/make-standalone-toolchain.sh \
			--verbose \
			--platform=android-${ANDROID_API_LEVEL} \
			--toolchain=${PLATFORM}-${TOOLCHAIN_VERSION} \
			--install-dir=${TMPDIR}/droidtoolchains/${PLATFORM}
	fi
done

# Set Up single build env var
if [ -n "$BUILD_ALL"]
then
    echo "Setting up single build env variables"
    PLATFORM="arm-linux-androideabi"

    LOGPATH="${LOGDIR}/${PLATFORM}"
    ROOTDIR="${TMPDIR}/build/droid/${PLATFORM}"

    mkdir -p "${ROOTDIR}"

    if [ "${PLATFORM}" == "arm-linux-androideabi" ]
    then
        export ARCH=${ARM_TARGET}
    else
        export ARCH="x86"
    fi

    export ROOTDIR=${ROOTDIR}
    export PLATFORM=${PLATFORM}
    export DROIDTOOLS=${TMPDIR}/droidtoolchains/${PLATFORM}/bin/${PLATFORM}
    export SYSROOT=${TMPDIR}/droidtoolchains/${PLATFORM}/sysroot
fi

popd
