# override CM resource
PRODUCT_PACKAGE_OVERLAYS += device/xiaomi/pisces/productoverlay

# Release name
PRODUCT_RELEASE_NAME := pisces

# Inherit some common CM stuff.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

# Enhanced NFC
$(call inherit-product, vendor/cm/config/nfc_enhanced.mk)

# Inherit device configuration
$(call inherit-product, device/xiaomi/pisces/device_pisces.mk)

## Device identifier. This must come after all inclusions
PRODUCT_DEVICE := pisces
PRODUCT_NAME := cm_pisces
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := MI 3
PRODUCT_MANUFACTURER := Xiaomi

# Boot animation
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920

# device specific settings menu supported by CM
BOARD_HARDWARE_CLASS := device/xiaomi/pisces/cmhw/

# Enable Torch
PRODUCT_PACKAGES += Torch

