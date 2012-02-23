#!/bin/sh
set -e

if [ "$(which openssl)" == "" ]
then
  echo "Unable to locate openssl executable for processing certs."
  exit 1
fi

# Retrieve JAVA home to pull certs from
JAVA_HOME=$1
if [ "${JAVA_HOME}" == "" ] || [ ! -e ${JAVA_HOME}/lib/security/cacerts ]
then
  echo "Unable to locate cacerts location within Java install home. Please specify a valid Java home path."
  exit 1
fi

KEYSTOREPASSWD=$2
if [ "${KEYSTOREPASSWD}" == "" ]
then
	KEYSTOREPASSWD=changeit
fi

BUILDDIR=$(dirname $0)

pushd $BUILDDIR
TOPDIR=$(dirname $(pwd))
BINDIR=$TOPDIR/bin/cacerts
TMPDIR=$TOPDIR/tmp/build/cacerts
popd

rm -fr ${BINDIR}
mkdir -p ${BINDIR}

rm -fr ${TMPDIR}
mkdir -p ${TMPDIR}

pushd ${TMPDIR}
for certname in $(${JAVA_HOME}/bin/keytool -list -keystore ${JAVA_HOME}/lib/security/cacerts -storepass ${KEYSTOREPASSWD} -v | grep "Alias name" | sed "s/Alias name: //")
do
	${JAVA_HOME}/bin/keytool -export -keystore ${JAVA_HOME}/lib/security/cacerts -storepass ${KEYSTOREPASSWD} -alias $certname -rfc -file ${TMPDIR}/$certname.pem
done

c_rehash ${TMPDIR}
cp ${TMPDIR}/*.0 ${BINDIR}

popd
