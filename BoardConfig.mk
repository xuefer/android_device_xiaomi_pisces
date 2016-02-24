# inherit from the proprietary version
-include vendor/xiaomi/pisces/BoardConfigVendor.mk

LOCAL_PATH := device/xiaomi/pisces

TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_TEGRA_VERSION := t114
TARGET_TEGRA_FAMILY := t11x

TARGET_BOARD_PLATFORM := tegra
TARGET_BOOTLOADER_BOARD_NAME := pisces

# Architecture
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_SMP := true
TARGET_CPU_VARIANT := cortex-a15
TARGET_ARCH_VARIANT_CPU := cortex-a15

TARGET_USE_TEGRA_BIONIC_OPTIMIZATION := true
TARGET_USE_TEGRA11_MEMCPY_OPTIMIZATION := true
ARCH_ARM_HAVE_TLS_REGISTER := true

BOARD_KERNEL_CMDLINE     += androidboot.hardware=$(TARGET_BOOTLOADER_BOARD_NAME)
BOARD_KERNEL_BASE        := 0x10000000
BOARD_KERNEL_PAGESIZE    := 2048
BOARD_MKBOOTIMG_ARGS     := --ramdisk_offset 0x01000000 --tags_offset 0x00000100

# fix this up by examining /proc/mtd on a running device
TARGET_USERIMAGES_USE_EXT4         := true
BOARD_BOOTIMAGE_PARTITION_SIZE     := 0x01000000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x01000000
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 671088640
BOARD_USERDATAIMAGE_PARTITION_SIZE := 3758096384
BOARD_CACHEIMAGE_PARTITION_SIZE    := 402653184
BOARD_PERSISTIMAGE_PARTITION_SIZE  := 16777216
BOARD_FLASH_BLOCK_SIZE             := 131072

# Flags
COMMON_GLOBAL_CFLAGS += -DADD_LEGACY_MEMORY_DEALER_CONSTRUCTOR_SYMBOL
COMMON_GLOBAL_CFLAGS += -DNO_SECURE_DISCARD
TARGET_SPECIFIC_HEADER_PATH := $(LOCAL_PATH)/include
TARGET_ENABLE_NON_PIE_SUPPORT := true

# logd
TARGET_USES_LOGD := false

# kernel
TARGET_PREBUILT_KERNEL := $(LOCAL_PATH)/kernel

# Power
COMMON_GLOBAL_CFLAGS += -DHAVE_PRE_LOLLIPOP_POWER_BLOB

# Audio
USE_LEGACY_AUDIO_POLICY := 1
COMMON_GLOBAL_CFLAGS += -DHAVE_MIUI_AUDIO_BLOB -DHAVE_PRE_LOLLIPOP_AUDIO_BLOB
TARGET_NEED_CUTILS_LIST_SYMBOLS := 1
TARGET_LDPRELOAD := libp4hread.so

# Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(LOCAL_PATH)/bluetooth

# init
INIT_MI3TD_HACK := true
TARGET_INIT_VENDOR_LIB := libinit_pisces

# Recovery
TARGET_RECOVERY_FSTAB            := $(LOCAL_PATH)/recovery/recovery.fstab
RECOVERY_FSTAB_VERSION           := 2
TARGET_RECOVERY_PIXEL_FORMAT     := "RGBX_8888"
BOARD_HAS_NO_SELECT_BUTTON       := true

# TWRP recovery
RECOVERY_SDCARD_ON_DATA          := true
RECOVERY_GRAPHICS_USE_LINELENGTH := true
DEVICE_RESOLUTION                := 1080x1920
TW_CUSTOM_BATTERY_PATH           := /sys/class/power_supply/max170xx_battery
TW_BRIGHTNESS_PATH               := /sys/class/backlight/lm3533-backlight0/brightness
TW_SECONDARY_BRIGHTNESS_PATH     := /sys/class/backlight/lm3533-backlight1/brightness
TW_INCLUDE_CRYPTO                := true
TW_USE_BUSYBOX                   := true
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true
TW_ADDITIONAL_RES := \
	$(LOCAL_PATH)/recovery/twres/mount_ext4.sh \

TW_RECOVERY_ADDITIONAL_RELINK_FILES := \
    $(CURDIR)/out/target/product/pisces/system/bin/resize2fs \
    $(CURDIR)/out/target/product/pisces/system/bin/dumpe2fs \

TARGET_RECOVERY_DEVICE_MODULES += \
    auto-mkfs \
    dualboot \
    init.recovery.pisces.rc \
    repartition \
    twrp.fstab \

# ril
#BOARD_PROVIDES_LIBRIL:= true

# GPS
BOARD_HAVE_GPS_BCM := true

# Vibrator
BOARD_HAS_VIBRATOR_IMPLEMENTATION := ../../device/xiaomi/pisces/vibrator.c

# Charger, healthd, alarm
BOARD_CHARGER_DISABLE_INIT_BLANK := true
BOARD_CHARGER_ENABLE_SUSPEND := true
BOARD_CHARGER_SHOW_PERCENTAGE := true
BOARD_HAL_STATIC_LIBRARIES += libhealthd.pisces
BOARD_RTC_WAKEALARM_PATH := /sys/class/rtc/rtc0/wakealarm
BOARD_HEALTHD_CUSTOM_CHARGER_RES := $(LOCAL_PATH)/libhealthd/images
BACKLIGHT_PATH           := /sys/class/backlight/lm3533-backlight0/brightness
SECONDARY_BACKLIGHT_PATH := /sys/class/backlight/lm3533-backlight1/brightness

# Graphics
USE_OPENGL_RENDERER := true
VSYNC_EVENT_PHASE_OFFSET_NS := 7500000
SF_VSYNC_EVENT_PHASE_OFFSET_NS := 5000000
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3

# Wlan
BOARD_WLAN_DEVICE                := bcmdhd
WPA_SUPPLICANT_VERSION           := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER      := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_HOSTAPD_DRIVER             := NL80211
BOARD_HOSTAPD_PRIVATE_LIB        := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_FW_PATH_PARAM        := "/sys/module/bcmdhd/parameters/firmware_path"
WIFI_DRIVER_FW_PATH_AP           := "/vendor/firmware/bcm43341/fw_bcmdhd_apsta.bin"
WIFI_DRIVER_FW_PATH_STA          := "/vendor/firmware/bcm43341/fw_bcmdhd.bin"
WIFI_DRIVER_FW_PATH_P2P          := "/vendor/firmware/bcm43341/fw_bcmdhd_p2p.bin"
WIFI_DRIVER_MODULE_DEVICE        := bcmdhd

# VPN
NETD_DISABLE_MULTIUSER_VPN := true

# Sensors
COMMON_GLOBAL_CFLAGS += -DHAVE_MIUI_SENSORS_BLOB

# SELinux
POLICYVERS := 26
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_SEPOLICY_DIRS += $(LOCAL_PATH)/sepolicy

# The list below is order dependent
#BOARD_SEPOLICY_UNION := \
    file_contexts \
    genfs_contexts \
    app.te \
    bdaddwriter.te \
    device.te \
    drmserver.te \
    init_shell.te \
    file.te \
    sensors_config.te \
    zygote.te \
    healthd.te \
    ueventd.te

