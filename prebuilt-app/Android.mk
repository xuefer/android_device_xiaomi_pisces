# Copyright (C) 2015 The CyanogenMod Project
# Copyright (C) 2015 Xuefer <xuefer@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := AMAPNetworkLocation
LOCAL_SRC_FILES := AMAPNetworkLocation.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := Cit
LOCAL_SRC_FILES := Cit.apk
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := FM
LOCAL_SRC_FILES := FM.apk
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := NvCPLSvc
LOCAL_SRC_FILES := NvCPLSvc.apk
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := NvwfdProtocolsPack
LOCAL_SRC_FILES := NvwfdProtocolsPack.apk
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := NvwfdService
LOCAL_SRC_FILES := NvwfdService.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/app
LOCAL_MODULE_TAGS := optional
LOCAL_ADDITIONAL_DEPENDENCIES := NvwfdProtocolsPack
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := SmartcardService
LOCAL_SRC_FILES := SmartcardService.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_SUFFIX := .apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_PATH := $(TARGET_OUT)/priv-app
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

