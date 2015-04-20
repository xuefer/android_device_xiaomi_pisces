LOCAL_PATH := external/e2fsprogs/misc

#########################################################################
# Build dumpe2fs
dumpe2fs_src_files := \
	dumpe2fs.c \
	util.c \
	default_profile.c

dumpe2fs_c_includes := \
	external/e2fsprogs/lib \
	external/e2fsprogs/e2fsck

dumpe2fs_cflags := -O2 -g -W -Wall \
	-DHAVE_UNISTD_H \
	-DHAVE_ERRNO_H \
	-DHAVE_NETINET_IN_H \
	-DHAVE_SYS_IOCTL_H \
	-DHAVE_SYS_MMAN_H \
	-DHAVE_SYS_MOUNT_H \
	-DHAVE_SYS_RESOURCE_H \
	-DHAVE_SYS_SELECT_H \
	-DHAVE_SYS_STAT_H \
	-DHAVE_SYS_TYPES_H \
	-DHAVE_STDLIB_H \
	-DHAVE_STRCASECMP \
	-DHAVE_STRDUP \
	-DHAVE_MMAP \
	-DHAVE_UTIME_H \
	-DHAVE_GETPAGESIZE \
	-DHAVE_EXT2_IOCTLS \
	-DHAVE_TYPE_SSIZE_T \
	-DHAVE_GETOPT_H \
	-DHAVE_SYS_TIME_H \
        -DHAVE_SYS_PARAM_H \
	-DHAVE_SYSCONF

dumpe2fs_cflags_linux := \
	-DHAVE_LINUX_FD_H \
	-DHAVE_SYS_PRCTL_H \
	-DHAVE_LSEEK64 \
	-DHAVE_LSEEK64_PROTOTYPE

dumpe2fs_cflags += -DNO_CHECK_BB

dumpe2fs_shared_libraries := \
	libext2fs \
	libext2_blkid \
	libext2_uuid \
	libext2_profile \
	libext2_quota \
	libext2_com_err \
	libext2_e2p

dumpe2fs_system_shared_libraries := libc

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(dumpe2fs_src_files)
LOCAL_C_INCLUDES := $(dumpe2fs_c_includes)
LOCAL_CFLAGS := $(dumpe2fs_cflags) $(dumpe2fs_cflags_linux)
LOCAL_SYSTEM_SHARED_LIBRARIES := $(dumpe2fs_system_shared_libraries)
LOCAL_SHARED_LIBRARIES := $(dumpe2fs_shared_libraries)
LOCAL_MODULE := dumpe2fs
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(dumpe2fs_src_files)
LOCAL_C_INCLUDES := $(dumpe2fs_c_includes)
LOCAL_CFLAGS := $(dumpe2fs_cflags) $(dumpe2fs_cflags_linux)
LOCAL_STATIC_LIBRARIES := $(dumpe2fs_shared_libraries)
LOCAL_STATIC_LIBRARIES += $(dumpe2fs_system_shared_libraries) libext2fs
LOCAL_MODULE := recovery_dumpe2fs
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin
LOCAL_UNSTRIPPED_PATH := $(PRODUCT_OUT)/symbols/recovery
LOCAL_MODULE_STEM := dumpe2fs
LOCAL_FORCE_STATIC_EXECUTABLE := true
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(dumpe2fs_src_files)
LOCAL_C_INCLUDES := $(dumpe2fs_c_includes)
LOCAL_CFLAGS := $(dumpe2fs_cflags) $(dumpe2fs_cflags_linux)
LOCAL_STATIC_LIBRARIES := $(dumpe2fs_shared_libraries)
LOCAL_STATIC_LIBRARIES += $(dumpe2fs_system_shared_libraries) libext2fs
LOCAL_MODULE := utility_dumpe2fs
LOCAL_MODULE_TAGS := eng
LOCAL_MODULE_CLASS := UTILITY_EXECUTABLES
LOCAL_MODULE_PATH := $(PRODUCT_OUT)/utilities
LOCAL_UNSTRIPPED_PATH := $(PRODUCT_OUT)/symbols/utilities
LOCAL_MODULE_STEM := dumpe2fs
LOCAL_FORCE_STATIC_EXECUTABLE := true
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(dumpe2fs_src_files)
LOCAL_C_INCLUDES := $(dumpe2fs_c_includes)
ifeq ($(HOST_OS),linux)
LOCAL_CFLAGS := $(dumpe2fs_cflags) $(dumpe2fs_cflags_linux)
else
LOCAL_CFLAGS := $(dumpe2fs_cflags)
endif
LOCAL_SHARED_LIBRARIES := $(addsuffix _host, $(dumpe2fs_shared_libraries))
LOCAL_MODULE := dumpe2fs_host
LOCAL_MODULE_STEM := dumpe2fs
LOCAL_MODULE_TAGS := optional

include $(BUILD_HOST_EXECUTABLE)
