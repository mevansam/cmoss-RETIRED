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
BINDIR=$TOPDIR/bin/certs
ROOTDIR=$TOPDIR/tmp/build/cacerts
TMPDIR=$TOPDIR/tmp/build/cacerts/tmp
popd

rm -fr ${BINDIR}
mkdir -p ${BINDIR}

rm -fr ${ROOTDIR}
mkdir -p ${TMPDIR}

for certname in $(${JAVA_HOME}/bin/keytool -list -keystore ${JAVA_HOME}/lib/security/cacerts -storepass ${KEYSTOREPASSWD} -v | grep "Alias name" | sed "s/Alias name: //")
do
	${JAVA_HOME}/bin/keytool -export -keystore ${JAVA_HOME}/lib/security/cacerts -storepass ${KEYSTOREPASSWD} -alias $certname -rfc -file ${TMPDIR}/$certname.pem
done

c_rehash ${TMPDIR}
cp ${TMPDIR}/*.0 ${ROOTDIR}
rm -r ${TMPDIR}

CERTS_ZIP=${ROOTDIR}/certs.zip

pushd ${ROOTDIR}/..
zip -r ${CERTS_ZIP} cacerts/
popd

rm ${ROOTDIR}/*.0

cat > ${BINDIR}/openssl_certs.h <<EOF
/* Generated header containing zipped certs binary and inline function to unzip it : do not modify */

#if !defined(_OPENSSL_CERTS_H__INCLUDED_)
#define _OPENSSL_CERTS_H__INCLUDED_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <utime.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "zip/unzip.h"
#include "log.h"

EOF

cat ${CERTS_ZIP} | ( echo "unsigned char _certsZipBinaryData[] = {"; xxd -i; echo "};" ) >> ${BINDIR}/openssl_certs.h

cat >> ${BINDIR}/openssl_certs.h <<EOF

#define WRITEBUFFERSIZE  8192
#define MAXFILENAMELEN   256

#ifndef ANDROID
extern int errno;
#endif

char __CERTS_PATH[MAXFILENAMELEN];
char __CACERTS_PATH[MAXFILENAMELEN];

#ifdef __cplusplus
inline int extractCerts(const char* path)
#else
inline static int extractCerts(const char* path)
#endif
{
	__CERTS_PATH[0] = '\0';
	__CACERTS_PATH[0] = '\0';

    char fileName[MAXFILENAMELEN];

    int err = UNZ_OK;
    struct utimbuf ut;

    struct tm zipTimestamp;
    zipTimestamp.tm_mon = $(date '+%m') - 1;
    zipTimestamp.tm_mday = $(date '+%d');
    zipTimestamp.tm_year = $(date '+%Y') - 1900;
	zipTimestamp.tm_hour = $(date '+%H');
    zipTimestamp.tm_min = $(date '+%M');
    zipTimestamp.tm_sec = $(date '+%S');
    zipTimestamp.tm_isdst = -1;

    ut.actime = ut.modtime = mktime(&zipTimestamp);

	TRACE("verifying cert path '%s'", path);

	if ((err = mkdir(path, 0775)) && errno != EEXIST) {
        ERROR("Error %d returned while creating destination directory '%s'.", err, path);
		return err;
	}

	snprintf(__CERTS_PATH, MAXFILENAMELEN, "%s", path);
	snprintf(__CACERTS_PATH, MAXFILENAMELEN, "%s/cacerts", path);
	snprintf(fileName, MAXFILENAMELEN, "%s/certs.zip", path);

	time_t timestamp = 0;
	int fd = open(fileName, O_RDONLY);
	if (fd != -1) {
		struct stat fileStat;
		if (fstat(fd, &fileStat) == 0)
		{
#ifdef __APPLE__
			timestamp = fileStat.st_mtimespec.tv_sec;
#else
			timestamp = fileStat.st_mtime;
#endif
			if (ut.modtime <= timestamp) {
				TRACE("certs zip file '%s' is up to date.", fileName);
				close(fd);
				return 0;
			}
		}
	}
	close(fd);

	TRACE("extracting certs zip file '%s'.", fileName);

	FILE* certZipFile = fopen(fileName, "wb");
	fwrite(_certsZipBinaryData, 1, sizeof(_certsZipBinaryData), certZipFile);
	fclose(certZipFile);

	utime(fileName, &ut);

	unzFile uf = NULL;
	if (!(uf = unzOpen(fileName)))
		return UNZ_INTERNALERROR;

    uLong i;
    unz_global_info gi;

    err = unzGetGlobalInfo(uf, &gi);
    if (err != UNZ_OK) {
        ERROR("Error %d returned by unzGetGlobalInfo().", err);
        unzClose(uf);
        return err;
    }

    char fileNameInZip[MAXFILENAMELEN];
    unz_file_info fileInfo;

    FILE* fout = NULL;

    int len;
    char* ch;
    void* buf;

    buf = (void *) malloc(WRITEBUFFERSIZE);
    if (!buf) {
        ERROR("Error allocating memory for buffer.");
        return UNZ_INTERNALERROR;
    }

    for (i = 0; i < gi.number_entry; i++) {

        err = unzGetCurrentFileInfo(uf, &fileInfo, fileNameInZip, MAXFILENAMELEN, NULL, 0, NULL, 0);
        if (err != UNZ_OK) {
            ERROR("Error %d returned by unzGetCurrentFileInfo()", err);
            break;
        }
        snprintf(fileName, MAXFILENAMELEN, "%s/%s", path, fileNameInZip);

        len = strlen(fileName);
        ch = fileName + len - 1;

        if (*ch == '/') {

        	TRACE("Creating directory '%s'.", fileName);

        	if ((err = mkdir(fileName, 0775)) && errno != EEXIST) {
                ERROR("Error %d returned while creating directory '%s' to extract file to", err, fileName);
				break;
        	}

        } else {

        	TRACE("Extracting file '%s'.", fileName);

            err = unzOpenCurrentFilePassword(uf, NULL);
            if (err != UNZ_OK) {
                ERROR("Error %d returned by unzOpenCurrentFilePassword\n", err);
                break;
            }

			fout = fopen(fileName, "wb");

			/* some zipfiles does not contain directory alone before file */
			if (!fout) {

				ch = strrchr(fileName, '/');
				if (!ch) {
	                ERROR("unable to create/overwrite file '%s'.", fileName);
	                err = UNZ_INTERNALERROR;
	                break;
				}

				*ch = 0;
	        	TRACE("creating directory '%s'", fileName);

	        	if ((err = mkdir(fileName, 0775)) && errno != EEXIST) {
	                ERROR("Error %d returned while creating directory '%s' to extract file to", err, fileName);
					break;
	        	}
				*ch = '/';

				fout = fopen(fileName, "wb");
				if (!fout) {
	                ERROR("Unable to create/overwrite file '%s'", fileName);
	                err = UNZ_INTERNALERROR;
	                break;
				}
			}

			do {
				err = unzReadCurrentFile(uf, buf, WRITEBUFFERSIZE);
				if (err < 0) {
					ERROR("Error %d returned by unzReadCurrentFile\n", err);
					break;
				}

				if (err > 0) {

					fwrite(buf, err, 1, fout);
					if ((err = ferror(fout))) {
						ERROR("Error %d returned by fwrite() while writing extracted file.", err);
						return err;
					}
				}
			}
			while (err > 0);

			fclose(fout);

			err = unzCloseCurrentFile(uf);
			if (err != UNZ_OK) {
				ERROR("Error %d returned by unzCloseCurrentFile()", err);
				break;
			}
        }

        if ((i+1) < gi.number_entry)
        {
            err = unzGoToNextFile(uf);
            if (err != UNZ_OK)
            {
            	ERROR("Error %d returned by unzGoToNextFile()", err);
                unzCloseCurrentFile(uf);
                return err;
            }
        }
    }

    free(buf);
    unzClose(uf);

    return 0;
}

#endif // !defined(_OPENSSL_CERTS_H__INCLUDED_)
EOF
