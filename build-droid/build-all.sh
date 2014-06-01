#!/bin/bash
set -e

export BUILD_ALL=true
if ! source ${TOPDIR}/build-droid/env-setup.sh $@
then
    exit 1
fi
pushd $TMPDIR

# Build projects
for PLATFORM in ${PLATFORMS}
do
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

	# Build minizip
	${TOPDIR}/build-droid/build-minizip.sh > "${LOGPATH}-minizip.log"

	# Build icu
	${TOPDIR}/build-droid/build-icu.sh > "${LOGPATH}-icu.log"

	# Build c-ares
	${TOPDIR}/build-droid/build-cares.sh > "${LOGPATH}-cares.log"

	# Build bzip2
	${TOPDIR}/build-droid/build-bzip2.sh > "${LOGPATH}-bzip2.log"

	# Build libidn (before curl and gsasl)
	${TOPDIR}/build-droid/build-libidn.sh > "${LOGPATH}-libidn.log"

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

	# Build libgsasl
	${TOPDIR}/build-droid/build-libgsasl.sh > "${LOGPATH}-libgsasl.log"

	# Build BOOST
	${TOPDIR}/build-droid/build-boost.sh > "${LOGPATH}-boost.log"

	# Build tinyxml
	${TOPDIR}/build-droid/build-tinyxml.sh > "${LOGPATH}-tinyxml.log"

	# Build expat
	${TOPDIR}/build-droid/build-expat.sh > "${LOGPATH}-expat.log"

	# Build yajl
	${TOPDIR}/build-droid/build-yajl.sh > "${LOGPATH}-yajl.log"

	# Build SQLCipher
	${TOPDIR}/build-droid/build-sqlcipher.sh > "${LOGPATH}-sqlcipher.log"

	# Build SOCI
	${TOPDIR}/build-droid/build-soci.sh > "${LOGPATH}-soci.log"

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

    mkdir -p ${BINDIR}/include
    cp -r ${ROOTDIR}/include ${BINDIR}/

    mkdir -p ${BINDIR}/lib/${ARM_TARGET}


    cp ${ROOTDIR}/lib/*.a ${BINDIR}/lib/${ARM_TARGET}
    cp ${ROOTDIR}/lib/*.la ${BINDIR}/lib/${ARM_TARGET}

    (cd ${ROOTDIR}/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/${ARM_TARGET} && tar xfB - )
    #(cd ${ROOTDIR}/lib && tar cf - *.so.* ) | ( cd ${BINDIR}/lib/${ARM_TARGET} && tar xfB - )

    echo "**** Android c/c++ open source ${PLATFORM} build completed ****"
done

echo "**** Android c/c++ open source build completed ****"

popd
