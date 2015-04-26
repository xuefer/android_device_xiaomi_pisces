LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

ALL_PREBUILT += $(INSTALLED_KERNEL_TARGET)

# include the non-open-source counterpart to this file
-include vendor/xiaomi/pisces/AndroidBoardVendor.mk

# this file is included too early, so copy required values from build/core/Makefile
DEFAULT_KEY_CERT_PAIR := $(DEFAULT_SYSTEM_DEV_CERTIFICATE)
ifneq ($(OTA_PACKAGE_SIGNING_KEY),)
  DEFAULT_KEY_CERT_PAIR := $(OTA_PACKAGE_SIGNING_KEY)
endif

name := TWRP2.8
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-$(CM_VERSION)
RECOVERY_OTA_ZIP := $(PRODUCT_OUT)/$(name).zip
RECOVERY_OTA_FROM_TARGET_SCRIPT := $(PRODUCT_OUT)/recovery_ota_from_target_files
RECOVERY_OTA_FROM_TARGET_PATCH := $(LOCAL_PATH)/recovery/ota_from_target_files.patch

$(RECOVERY_OTA_FROM_TARGET_SCRIPT): $(OTA_FROM_TARGET_SCRIPT) $(RECOVERY_OTA_FROM_TARGET_PATCH)
	cp -a "$(OTA_FROM_TARGET_SCRIPT)" "$@".tmp
	patch "$@".tmp $(RECOVERY_OTA_FROM_TARGET_PATCH)
	chmod +x "$@".tmp
	mv "$@".tmp "$@"

$(RECOVERY_OTA_ZIP): KEY_CERT_PAIR := $(DEFAULT_KEY_CERT_PAIR)
$(RECOVERY_OTA_ZIP): $(BUILT_TARGET_FILES_PACKAGE) $(DISTTOOLS) $(RECOVERY_OTA_FROM_TARGET_SCRIPT)
	@echo -e ${CL_YLW}"Recovery OTA:"${CL_RST}" $@"
	MKBOOTIMG=$(MKBOOTIMG) PYTHONPATH="$$PYTHONPATH:$$(readlink -f $$(dirname $(OTA_FROM_TARGET_SCRIPT)))" \
	  "$(RECOVERY_OTA_FROM_TARGET_SCRIPT)" \
	  --block \
	  -p $(HOST_OUT) \
	  -k $(KEY_CERT_PAIR) \
	  $(if $(OEM_OTA_CONFIG), -o $(OEM_OTA_CONFIG)) \
	  $(BUILT_TARGET_FILES_PACKAGE) $@

.PHONY: recoveryotazip
recoveryotazip: $(RECOVERY_OTA_ZIP)
