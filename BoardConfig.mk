# inherit from the proprietary version
-include vendor/xiaomi/pisces/BoardConfigVendor.mk

BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/xiaomi/pisces/bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true

TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := tegra
TARGET_TEGRA_VERSION := t114
TARGET_TEGRA_FAMILY := t11x
TARGET_NO_RADIOIMAGE := true
TARGET_BOOTLOADER_BOARD_NAME := pisces

TARGET_ARCH := arm
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_VARIANT := cortex-a15
TARGET_ARCH_VARIANT_CPU := cortex-a15
TARGET_CPU_SMP := true


TARGET_USE_TEGRA_BIONIC_OPTIMIZATION := true
TARGET_USE_TEGRA11_MEMCPY_OPTIMIZATION := true
ARCH_ARM_HAVE_TLS_REGISTER := true


BOARD_KERNEL_CMDLINE := 
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100

# fix this up by examining /proc/mtd on a running device
TARGET_USERIMAGES_USE_EXT4         := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x01000000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x01000000
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 671088640
BOARD_USERDATAIMAGE_PARTITION_SIZE := 3758096384
BOARD_CACHEIMAGE_PARTITION_SIZE := 402653184
BOARD_PERSISTIMAGE_PARTITION_SIZE := 16777216
#BOARD_TOMBSTONESIMAGE_PARTITION_SIZE := 73400320
BOARD_FLASH_BLOCK_SIZE := 131072


#TARGET_PROVIDES_INIT_TARGET_RC := true
TARGET_PREBUILT_KERNEL := device/xiaomi/pisces/kernel

BOARD_HAS_NO_SELECT_BUTTON := true

TARGET_SPECIFIC_HEADER_PATH := device/xiaomi/pisces/include

#WIFI
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_WLAN_DEVICE := bcmdhd
WIFI_DRIVER_FW_PATH_PARAM   := "/sys/module/bcmdhd/parameters/firmware_path"
WIFI_DRIVER_FW_PATH_AP      := "/vendor/firmware/bcm43341/fw_bcmdhd_apsta.bin"
WIFI_DRIVER_FW_PATH_STA     := "/vendor/firmware/bcm43341/fw_bcmdhd.bin"
WIFI_DRIVER_FW_PATH_P2P     := "/vendor/firmware/bcm43341/fw_bcmdhd_p2p.bin"
WIFI_DRIVER_MODULE_DEVICE   := bcmdhd

#Lights
TARGET_PROVIDES_LIBLIGHT := true

#egl
BOARD_EGL_CFG := device/xiaomi/pisces/egl.cfg
USE_OPENGL_RENDERER := true
#TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
BOARD_USE_SKIA_LCDTEXT := true

#rild
#TARGET_PROVIDES_LIBRIL := vendor/xiaomi/pisces/proprietary/lib/libril-xiaomi-sprd.so
#BOARD_RIL_NO_CELLINFOLIST := true

##audio
#BOARD_USES_ALSA_AUDIO := true
#$BOARD_SUPPORT_NVAUDIOFX := true
#BOARD_SUPPORT_NVOICE := true
#BOARD_USES_TFA := true
# This variable is set first, so it can be overridden
# by BoardConfigVendor.mk
USE_CAMERA_STUB := false
BOARD_USES_GENERIC_AUDIO := false

#USE_E2FSPROGS := true
#BOARD_HAS_NVDPS := true
#NVCMS_CMU_USE_CONFIG := true

TARGET_RECOVERY_FSTAB := device/xiaomi/pisces/fstab.pisces

# GPS
BOARD_HAVE_GPS_BCM := true

# Vibrator
BOARD_HAS_VIBRATOR_IMPLEMENTATION := ../../device/xiaomi/pisces/vibrator.c

# recovery
TARGET_RECOVERY_FSTAB := device/xiaomi/pisces/fstab.pisces
RECOVERY_FSTAB_VERSION           := 2
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"


COMMON_GLOBAL_CFLAGS += -DNO_SECURE_DISCARD -DNEEDS_VECTORIMPL_SYMBOLS

# SELinux
BOARD_SEPOLICY_DIRS += \
   $(COMMON_PATH)/sepolicy

# The list below is order dependent
BOARD_SEPOLICY_UNION := \
    file_contexts \
    genfs_contexts \
    app.te \
    bdaddwriter.te \
    device.te \
    drmserver.te \
    init_shell.te \
    file.te \
    sensors_config.te \
    system.te \
    zygote.te \
    healthd.te \
    domain.te \
    ueventd.te
