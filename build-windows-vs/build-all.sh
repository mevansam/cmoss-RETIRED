#!/bin/sh
set -e

# Retrieve iOS SDK VERSION to use
SDK_VER=$1
if [ "${SDK_VER}" == "" ]
then
  SDK_VER="2015"
  echo "Using visual studio ${SDK_VER}"
fi

export SDK_VER="${SDK_VER}"

if [ -z $2 ]
then
	export PROXY=""
else
	export PROXY="-x $2"
fi

# Project version to use to build zlib (changing this may break the build)
export ZLIB_VERSION="1.2.8"


# Project versions to use to build openssl (changing this may break the build)
export OPENSSL_VERSION="1.0.1c"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export LIBSSH2_VERSION="1.3.0"
export CURL_VERSION="7.46.0"

# Project version to use to build boost C++ libraries
export BOOST_VERSION="1.59.0"
#context, thread lib not supported
export BOOST_LIBS="atomic chrono container context coroutine \
				   coroutine2 date_time exception filesystem graph graph_parallel iostreams \
				   locale log math mpi program_options \
				   random regex serialization signals system test thread timer wave"

VS_FOLDER="windows-vs"
# Create dist folder
BUILDDIR=$(dirname $0)

pushd $BUILDDIR
export TOPDIR=$(dirname $(pwd))
export BINDIR=$TOPDIR/bin/${VS_FOLDER}
export LOGDIR=$TOPDIR/log/${VS_FOLDER}
export TMPDIR=$TOPDIR/tmp
popd

rm -rf ${LOGDIR}
mkdir -p ${LOGDIR}
mkdir -p ${TMPDIR}

pushd ${TMPDIR}

# Platforms to build for (changing this may break the build)
#TARGETS="x86 x64"
TARGETS="x86"
# Build projects
for TARGET in ${TARGETS}
do
	ROOTDIR="${TMPDIR}/build/${VS_FOLDER}/${TARGET}"
	rm -rf "${ROOTDIR}" || true
	mkdir -p "${ROOTDIR}"
done


for TARGET in ${TARGETS}
do

	echo "Building libraries for target platform: ${TARGET}..."

	LOGPATH="${LOGDIR}/${TARGET}"
	ROOTDIR="${TMPDIR}/build/${VS_FOLDER}/${TARGET}"
	
	ADDRESS_MODEL=32
	PLATFORM="windows"
	BINARY_FOMAT=pe
	if [ "${TARGET}" == "x86" ]
	then
		PLATFORM="windows"
		ARCH="i386"
		ARCHITECTURE="x86"
		ADDRESS_MODEL=32
		ABI=ms
		
	elif [ "${TARGET}" == "x64" ]
	then
		PLATFORM="windows"
		ARCH="x86_64"
		ARCHITECTURE="x64"
		ADDRESS_MODEL=64
		ABI=ms
	fi

	SDK_NAME="Visual Studio ${SDK_VER}"
	if [ "${SDK_VER}" == "2015" ]
	then
		SDK_NAME="Visual Studio 14 2015"
		if [ ${ADDRESS_MODEL} == 64 ]
		then
			SDK_NAME="${SDK_NAME} Win64"
		fi
	else
		echo "SDK_VER: ${SDK_VER} not supported"
		exit 1
	fi

	export SDK_NAME="${SDK_NAME}"
	export ROOTDIR="${ROOTDIR}"
	export PLATFORM="${PLATFORM}"
	export ARCH="${ARCH}"
	export ARCHITECTURE="${ARCHITECTURE}"
	export ADDRESS_MODEL="${ADDRESS_MODEL}"
	export ABI="${ABI}"


	echo exported SDK_NAME: 	${SDK_NAME}
	echo exported ROOTDIR: 		${ROOTDIR}
	echo exported PLATFORM: 	${PLATFORM}
	echo exported ARCH: 		${ARCH}
	echo exported ARCHITECTURE: ${ARCHITECTURE}
	echo exported ADDRESS_MODEL:${ADDRESS_MODEL}
	echo exported ABI: 			${ABI}
	echo exported BINARY_FOMAT: ${BINARY_FOMAT}
	

	# Build zlib
	${TOPDIR}/build-${VS_FOLDER}/build-zlib.sh > "${LOGPATH}-zlib.log"

	# Build OpenSSL
	#${TOPDIR}/build-${VS_FOLDER}/build-openssl.sh #> "${LOGPATH}-OpenSSL.log"

	# Build libssh2
	#${TOPDIR}/build-${VS_FOLDER}/build-libssh2.sh > "${LOGPATH}-libssh2.log"

	# Build cURL
	${TOPDIR}/build-${VS_FOLDER}/build-cURL.sh #> "${LOGPATH}-cURL.log"


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



for TARGET in ${TARGETS}
do
	mkdir -p ${BINDIR}/include
	cp -r ${TMPDIR}/build/${VS_FOLDER}/${TARGET}/include ${BINDIR}/

	#mkdir -p ${BINDIR}/lib/x86
	mkdir -p ${BINDIR}/lib/${TARGET}

	cp -r ${TMPDIR}/build/${VS_FOLDER}/${TARGET}/lib/* ${BINDIR}/lib/${TARGET}

done

echo "**** windows build completed ****"

popd
