ifeq ($(TARGET_INIT_VENDOR_LIB),libinit_pisces)

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_C_INCLUDES := system/core/init
LOCAL_CFLAGS := -Wall -DANDROID_TARGET=\"$(TARGET_BOARD_PLATFORM)\"
LOCAL_SRC_FILES := init_pisces.c

LOCAL_MODULE := libinit_pisces
include $(BUILD_STATIC_LIBRARY)

endif
