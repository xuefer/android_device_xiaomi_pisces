LOCAL_PATH := device/xiaomi/pisces

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

$(call inherit-product-if-exists, vendor/xiaomi/pisces/pisces-vendor.mk)

ifeq ($(TARGET_PREBUILT_KERNEL),)
    LOCAL_KERNEL := $(LOCAL_PATH)/kernel
else
    LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif
PRODUCT_COPY_FILES += $(LOCAL_KERNEL):kernel

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
PRODUCT_CHARACTERISTICS := nosdcard

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp,adb \
    persist.sys.isUsbOtgEnabled=1 \

PRODUCT_PROPERTY_OVERRIDES += \
    drm.service.enabled=true \
    ro.com.android.dateformat=yyyy-MM-dd \

# permissions file from AOSP
PRODUCT_COPY_FILES += \
    frameworks/base/nfc-extras/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:system/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.software.sip.xml:system/etc/permissions/android.software.sip.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \

# permissions file from vendor
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/permissions/com.broadcom.bt.xml:system/etc/permissions/com.broadcom.bt.xml \
    $(LOCAL_PATH)/permissions/com.broadcom.nfc.xml:system/etc/permissions/com.broadcom.nfc.xml \
    $(LOCAL_PATH)/permissions/com.nvidia.graphics.xml:system/etc/permissions/com.nvidia.graphics.xml \
    $(LOCAL_PATH)/permissions/com.nvidia.miracast.xml:system/etc/permissions/com.nvidia.miracast.xml \
    $(LOCAL_PATH)/permissions/com.nvidia.nvsi.xml:system/etc/permissions/com.nvidia.nvsi.xml \
    $(LOCAL_PATH)/permissions/com.nvidia.nvstereoutils.xml:system/etc/permissions/com.nvidia.nvstereoutils.xml \
    $(LOCAL_PATH)/permissions/com.nvidia.wifi.xml:system/etc/permissions/com.nvidia.wifi.xml \
    $(LOCAL_PATH)/permissions/com.vzw.nfc.xml:system/etc/permissions/com.vzw.nfc.xml \
    $(LOCAL_PATH)/permissions/org.simalliance.openmobileapi.xml:system/etc/permissions/org.simalliance.openmobileapi.xml \

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/prebuilt/system,system) \

# init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/ramdisk/fstab.pisces:root/fstab.pisces \
    $(LOCAL_PATH)/ramdisk/fstab.zram_128:root/fstab.zram_128 \
    $(LOCAL_PATH)/ramdisk/fstab.zram_256:root/fstab.zram_256 \
    $(LOCAL_PATH)/ramdisk/fstab.zram_512:root/fstab.zram_512 \
    $(LOCAL_PATH)/ramdisk/init.hdcp.rc:root/init.hdcp.rc \
    $(LOCAL_PATH)/ramdisk/init.modem_imc.rc:root/init.modem_imc.rc \
    $(LOCAL_PATH)/ramdisk/init.modem_sprd.rc:root/init.modem_sprd.rc \
    $(LOCAL_PATH)/ramdisk/init.nv_dev_board.usb.rc:root/init.nv_dev_board.usb.rc \
    $(LOCAL_PATH)/ramdisk/init.pisces.rc:root/init.pisces.rc \
    $(LOCAL_PATH)/ramdisk/ueventd.pisces.rc:root/ueventd.pisces.rc \

# safe mount_ext4, dualboot/mount helper script
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bin/dualboot.sh:system/bin/dualboot.sh \
    $(LOCAL_PATH)/bin/mount_ext4.sh:system/bin/mount_ext4.sh \
    $(LOCAL_PATH)/bin/upgrade_layout.sh:system/bin/upgrade_layout.sh \

PRODUCT_PACKAGES += \
    dumpe2fs \

# phone
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bin/fild:system/bin/fild \

# gps
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/gps/gps.conf:system/etc/gps.conf \
    $(LOCAL_PATH)/gps/gpsconfigftm.xml:system/etc/gpsconfigftm.xml \
    $(LOCAL_PATH)/gps/gpsconfig.xml:system/etc/gps/gpsconfig.xml \

# bluetooth
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bluetooth/bt_vendor.conf:system/etc/bluetooth/bt_vendor.conf \

# camera
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/camera/model_frontal.xml:system/etc/model_frontal.xml \
    $(LOCAL_PATH)/camera/nvcamera.conf:system/etc/nvcamera.conf \

# media
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles.xml \
    $(LOCAL_PATH)/media/media_codecs.xml:system/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/enctune.conf:system/etc/enctune.conf \

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/asound.conf:system/etc/asound.conf \
    $(LOCAL_PATH)/audio/audio_effects.conf:system/vendor/etc/audio_effects.conf \
    $(LOCAL_PATH)/audio/audio_policy.conf:system/etc/audio_policy.conf \
    $(LOCAL_PATH)/audio/nvaudio_conf.xml:system/etc/nvaudio_conf.xml \

PRODUCT_PACKAGES += \
    audio.a2dp.default \
    audio.usb.default \
    audio.r_submix.default \
    libaudioutils \
    tinycap \
    tinymix \
    tinypcminfo \
    tinyplay \

# Misc hardwares
PRODUCT_PACKAGES += \
    lights.pisces \

# Charger
PRODUCT_PACKAGES += \
    charger_res_images \

# Misc
PRODUCT_PACKAGES += \
    librs_jni \
    libnetcmdiface  \

# NFC
PRODUCT_PACKAGES += \
    nfc_nci.bcm2079x.default \
    NfcNci \
    Tag \
    com.android.nfc_extras \

# USB
PRODUCT_PACKAGES += \
    com.android.future.usb.accessory \

# Vibrator
PRODUCT_PACKAGES += \
    immvibed \
    libImmVibeJ

# Vendor Apps
PRODUCT_PACKAGES += \
    AMAPNetworkLocation \
    Cit \
    FM \
    NvCPLSvc \

PRODUCT_PACKAGES += \
    libwpa_client \
    hostapd \
    dhcpcd.conf \
    wpa_supplicant \
    wpa_supplicant.conf \

