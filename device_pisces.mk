$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

$(call inherit-product-if-exists, vendor/xiaomi/pisces/pisces-vendor.mk)

$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

DEVICE_PACKAGE_OVERLAYS += device/xiaomi/pisces/overlay

LOCAL_PATH := device/xiaomi/pisces
ifeq ($(TARGET_PREBUILT_KERNEL),)
	LOCAL_KERNEL := $(LOCAL_PATH)/kernel
else
	LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES += \
    $(LOCAL_KERNEL):kernel

TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080

#$(call inherit-product, build/target/product/full.mk)


PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0
PRODUCT_NAME := full_pisces
PRODUCT_DEVICE := pisces

#safe mount_ext4
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/bin/mount_ext4.sh:system/bin/mount_ext4.sh

#ramdisk
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/ramdisk/ueventd.pisces.rc:root/ueventd.pisces.rc \
    device/xiaomi/pisces/ramdisk/init.modem_sprd.rc:root/init.modem_sprd.rc \
    device/xiaomi/pisces/ramdisk/init.modem_imc.rc:root/init.modem_imc.rc \
    device/xiaomi/pisces/ramdisk/init.nv_dev_board.usb.rc:root/init.nv_dev_board.usb.rc \
    device/xiaomi/pisces/ramdisk/init.pisces.rc:root/init.pisces.rc \
    device/xiaomi/pisces/ramdisk/init.hdcp.rc:root/init.hdcp.rc \
    device/xiaomi/pisces/ramdisk/init.nv_dev_board.usb.rc:root/init.pisces.usb.rc \
    device/xiaomi/pisces/ramdisk/fstab.pisces:root/fstab.pisces

#gps
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/gps/gps.conf:system/etc/gps.conf \
    device/xiaomi/pisces/gps/gpsconfigftm.xml:system/etc/gpsconfigftm.xml \
    device/xiaomi/pisces/gps/gpsconfig.xml:system/etc/gps/gpsconfig.xml

#audio
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/audio/asound.conf:system/etc/asound.conf \
    device/xiaomi/pisces/audio/audio_effects.conf:system/etc/audio_effects.conf \
    device/xiaomi/pisces/audio/audio_policy.conf:system/etc/audio_policy.conf \
    device/xiaomi/pisces/audio/nvaudio_conf.xml:system/etc/nvaudio_conf.xml

PRODUCT_COPY_FILES_OVERRIDES := \
    system/etc/audio_effects.conf

#camera
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/camera/model_frontal.xml:system/etc/model_frontal.xml \
    device/xiaomi/pisces/camera/nvcamera.conf:system/etc/nvcamera.conf

#media
PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/media/media_profiles.xml:system/etc/media_profiles.xml \
    device/xiaomi/pisces/media/media_codecs.xml:system/etc/media_codecs.xml \
    device/xiaomi/pisces/media/enctune.conf:system/etc/enctune.conf

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.software.sip.xml:system/etc/permissions/android.software.sip.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:system/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/base/nfc-extras/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml


PRODUCT_COPY_FILES += \
    device/xiaomi/pisces/permissions/com.broadcom.bt.xml:system/etc/permissions/com.broadcom.bt.xml \
    device/xiaomi/pisces/permissions/com.broadcom.nfc.xml:system/etc/permissions/com.broadcom.nfc.xml \
    device/xiaomi/pisces/permissions/com.nvidia.graphics.xml:system/etc/permissions/com.nvidia.graphics.xml \
    device/xiaomi/pisces/permissions/com.nvidia.miracast.xml:system/etc/permissions/com.nvidia.miracast.xml \
    device/xiaomi/pisces/permissions/com.nvidia.nvsi.xml:system/etc/permissions/com.nvidia.nvsi.xml \
    device/xiaomi/pisces/permissions/com.nvidia.nvstereoutils.xml:system/etc/permissions/com.nvidia.nvstereoutils.xml \
    device/xiaomi/pisces/permissions/com.vzw.nfc.xml:system/etc/permissions/com.vzw.nfc.xml \
    device/xiaomi/pisces/permissions/org.simalliance.openmobileapi.xml:system/etc/permissions/org.simalliance.openmobileapi.xml \
    device/xiaomi/pisces/permissions/platform.xml:system/etc/permissions/platform.xml

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/prebuilt/root,root) \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/prebuilt/system,system)

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
        ro.secure=0 \
        ro.allow.mock.location=1 \
        persist.sys.usb.config=mtp \
        ro.adb.secure=0 \
        ro.debuggable=1

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.override_null_lcd_density = 1 \
    persist.tegra.compositor=glcomposer \
    debug.hwui.render_dirty_regions=false \
    persist.tegra.nvmmlite = 1 \
    drm.service.enabled=true 

# Audio
PRODUCT_PACKAGES += \
        audio.a2dp.default \
        audio.usb.default \
        audio.r_submix.default \
        libaudioutils

# Misc
PRODUCT_PACKAGES += \
    librs_jni \
    com.android.future.usb.accessory \
    libnetcmdiface  \
    tinycap \
    tinymix \
    tinyplay

# NFC packages
PRODUCT_PACKAGES += \
    libnfc-nci \
    libnfc_nci_jni \
    NfcNci \
    Tag \
    com.android.nfc_extras

