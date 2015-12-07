LOCAL_PATH := $(call my-dir)

# Define ANDROID_SMP appropriately.
ifeq ($(TARGET_CPU_SMP),true)
    libc_common_cflags += -DANDROID_SMP=1
else
    libc_common_cflags += -DANDROID_SMP=0
endif

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
	bionic/pthread.c \

LOCAL_C_INCLUDES := $(LOCAL_PATH)/bionic $(LOCAL_PATH)/private
LOCAL_CFLAGS := $(libc_common_cflags)
LOCAL_SYSTEM_SHARED_LIBRARIES := libc
LOCAL_MODULE := libp4hread
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)
