LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    Vibrator.cpp

LOCAL_SHARED_LIBRARIES := \
    liblog libdl libcutils

LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_MODULE := vibrator.pisces
LOCAL_MODULE_TAGS := optional

include $(BUILD_SHARED_LIBRARY)
