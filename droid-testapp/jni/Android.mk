LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE     := minizip
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libminizip.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := crypto
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libcrypto.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := ssl
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libssl.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := curl
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libcurl.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := boost
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libboost.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := pion-common
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libpion-common.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := pion-net
LOCAL_SRC_FILES  := ../../bin/droid/lib/armv7/libpion-net.a
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../bin/droid/include

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE    := cmoss-tests
LOCAL_SRC_FILES := SSLInit.c cmoss-tests.cpp
#LOCAL_SRC_FILES := cmoss-tests.c

LOCAL_C_INCLUDES += ${NDK_ROOT}/platforms/android-14/arch-arm/usr/includes 
LOCAL_C_INCLUDES += ${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/include 
LOCAL_C_INCLUDES += ${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/libs/armeabi-v7a/include 
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../bin/droid/include 
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../bin/certs 
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../nadax/NadaxUtility/src/include

LOCAL_CFLAGS += -DUNIX -DLOG_LEVEL_TRACE
LOCAL_CPPFLAGS += -frtti -fexceptions

LOCAL_LDFLAGS += ${NDK_ROOT}/platforms/android-14/arch-arm/usr/lib/crtbegin_so.o
LOCAL_LDFLAGS += -Os -nostdlib -Wl,-rpath-link=${NDK_ROOT}/platforms/android-14/arch-arm/usr/lib
LOCAL_LDLIBS += -lc -ldl -llog -lz

#LOCAL_STATIC_LIBRARIES := curl ssl crypto minizip boost pion-common pion-net
LOCAL_STATIC_LIBRARIES := curl ssl crypto minizip boost

include $(BUILD_SHARED_LIBRARY)
