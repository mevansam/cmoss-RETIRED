/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include <jni.h>

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <map>

#include "curl/curl.h"
#include "boost/unordered_map.hpp"

#include "openssl_certs.h"
#include "log.h"

#include "executor.h"
#include "SSLInit.h"

#define BUFFER_SIZE  1024


Executor* executor = NULL;

boost::unordered_map<std::string, std::string> requestResult;
boost::unordered_map<std::string, std::string> responseData;


// **** HTTP Data Get ****

int curlDebugCallback(CURL* curl, curl_infotype infotype, char* text, size_t len, void* userdata) {

	TRACE("cURL: %s", text);
	return 0;
}

size_t respDataCallback(void* contents, size_t size, size_t nmemb, void* userdata) {

	char* buffer = (char *) contents;
	size_t len = size * nmemb;

	std::vector<char>* data = (std::vector<char> *) userdata;

	size_t newSize = data->size() + len;
	if (newSize >= data->capacity())
		data->reserve((newSize / BUFFER_SIZE + 1) * BUFFER_SIZE);

	data->insert(data->end(), buffer, buffer + len);
	return len;
}

void getDataFromUrl(const char* url) {

	std::stringstream result;
	char error[CURL_ERROR_SIZE];

	std::vector<char> data;
	data.reserve(BUFFER_SIZE);

	bool success = false;

	CURL* curl = curl_easy_init();
	if (curl) {

	    curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error);
	    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	    curl_easy_setopt(curl, CURLOPT_DEBUGFUNCTION, curlDebugCallback);
	    curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

		curl_easy_setopt(curl, CURLOPT_PROXY, "http.proxy.fmr.com");
		curl_easy_setopt(curl, CURLOPT_PROXYPORT, 8000L);

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

		curl_easy_setopt(curl, CURLOPT_URL, url);
		curl_easy_setopt(curl, CURLOPT_USERAGENT, "cmoss-test-agent/1.0");

		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, respDataCallback);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &data);

		TRACE("cURL initialized to perform HTTP get from '%s'...", url);

		CURLcode res = curl_easy_perform(curl);
		if (res) {
			result << "Error! - \"";
			result << error;
			result << '"';
			TRACE("cURL HTTP returned error: %s", result.str().c_str());
		} else {
			result << "Success!";
			success = true;
			data.push_back(0);
			TRACE("cURL HTTP get succeeded.");
		}

		curl_easy_cleanup(curl);

		requestResult[url] = result.str();

		if (success) {
			responseData[url] = std::string(&data[0], data.size());
			TRACE("cURL HTTP get from '%s' returned:\n\t%s", url, responseData[url].c_str());
		} else
			responseData[url] = "";

	} else {

		ERROR("Error initializing cURL. A null handle was returned.");
		result << "cURL initialization error!";
	}
}


// **** JNI Implementation ****

extern "C" {

void Java_org_cmoss_tests_TestLibsActivity_initialize(JNIEnv* env, jobject thiz, jstring path) {

	const char* certPath = env->GetStringUTFChars(path, 0);
	TRACE("Extracting certs to path '%s'...", certPath);

	int error = extractCerts(certPath);
	if (error) {
		TRACE("Error extracting certificates: %d", error);
	}

	init_locks();
	curl_global_init(CURL_GLOBAL_ALL);

	executor = new Executor(2);

	TRACE("Done initializing CMOSS Tests.");
}

void Java_org_cmoss_tests_TestLibsActivity_shutdown(JNIEnv* env, jobject thiz) {

	curl_global_cleanup();
	kill_locks();

	delete executor;

	TRACE("Done shutting down CMOSS Tests.");
}

jstring Java_org_cmoss_tests_TestLibsActivity_curlTest(JNIEnv* env, jobject thiz) {

	executor->submit(boost::bind(getDataFromUrl, "https://www.google.com"));
	executor->submit(boost::bind(getDataFromUrl, "https://www.paypal.com/"));

    return env->NewStringUTF("Requests sent.");
}

}
