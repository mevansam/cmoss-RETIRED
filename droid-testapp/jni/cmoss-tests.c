#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <curl/curl.h>

#include "log.h"
#include "openssl_certs.h"

#define BUFFER_SIZE  1024


int curlDebugCallback(CURL* curl, curl_infotype infotype, char* text, size_t len, void* userdata) {

	TRACE("cURL: %s", text);
	return 0;
}

// **** JNI Implementations ****

void Java_org_cmoss_tests_TestLibsActivity_initialize(JNIEnv* env, jobject thiz, jstring path) {

	const char* certPath = (*env)->GetStringUTFChars(env, path, 0);
	TRACE("Extracting certs to path '%s'...", certPath);

	int error = extractCerts(certPath);
	if (error) {
		TRACE("Error extracting certificates: %d", error);
	}

	curl_global_init(CURL_GLOBAL_ALL);

	TRACE("Done initializing CMOSS Tests.");
}

void Java_org_cmoss_tests_TestLibsActivity_shutdown(JNIEnv* env, jobject thiz) {

	curl_global_cleanup();

	TRACE("Done shutting down CMOSS Tests.");
}

jstring Java_org_cmoss_tests_TestLibsActivity_curlTest(JNIEnv* env, jobject thiz) {

	char result[BUFFER_SIZE];
	char error[CURL_ERROR_SIZE];

	CURL* curl = curl_easy_init();
	if (curl) {

		curl_easy_setopt(curl, CURLOPT_URL, "https://www.google.com");
//		curl_easy_setopt(curl, CURLOPT_PROXY, "http.proxy.fmr.com");
//		curl_easy_setopt(curl, CURLOPT_PROXYPORT, 8000L);

		curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error);
	    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	    curl_easy_setopt(curl, CURLOPT_DEBUGFUNCTION, curlDebugCallback);
	    curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

#ifdef SKIP_PEER_VERIFICATION
		/*
		 * If you want to connect to a site who isn't using a certificate that is
		 * signed by one of the certs in the CA bundle you have, you can skip the
		 * verification of the server's certificate. This makes the connection
		 * A LOT LESS SECURE.
		 *
		 * If you have a CA cert for the server stored someplace else than in the
		 * default bundle, then the CURLOPT_CAPATH option might come handy for
		 * you.
		 */
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
#else
		curl_easy_setopt(curl, CURLOPT_CAPATH, __CACERTS_PATH);
#endif

#ifdef SKIP_HOSTNAME_VERFICATION
		/*
		 * If the site you're connecting to uses a different host name that what
		 * they have mentioned in their server certificate's commonName (or
		 * subjectAltName) fields, libcurl will refuse to connect. You can skip
		 * this check, but this will make the connection less secure.
		 */
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
#endif


		TRACE("Sending request...");

		CURLcode res = curl_easy_perform(curl);
		if (res) {
			snprintf(result, BUFFER_SIZE, "cURL HTTP returned error: %s", error);
			TRACE("cURL HTTP returned error: %s", result);
		} else {
			snprintf(result, BUFFER_SIZE, "cURL HTTP request succeeded");
			TRACE("cURL HTTP get succeeded.");
		}

		curl_easy_cleanup(curl);

	} else {

		snprintf(result, BUFFER_SIZE, "Error initializing cURL. A null handle was returned.");
	}

	return (*env)->NewStringUTF(env, result);
}
