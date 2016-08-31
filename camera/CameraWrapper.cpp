/*
 * Copyright (C) 2015, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
* @file CameraWrapper.cpp
*
* This file wraps a vendor camera module.
*
*/

//#define LOG_NDEBUG 0
//#define LOG_PARAMETERS

#define LOG_TAG "CameraWrapper"
#include <cutils/log.h>

#include <utils/threads.h>
#include <utils/String8.h>
#include <hardware/hardware.h>
#include <hardware/camera.h>
#include <camera/Camera.h>
#include <camera/CameraParameters.h>

#include <utils/Errors.h>
#include <utils/RefBase.h>

#include <binder/IBinder.h>
#include <binder/IServiceManager.h>
#include <gui/ISensorServer.h>

static android::Mutex gCameraWrapperLock;

struct wrapper_camera_device_t {
    camera_device_t base;
    int id;
    camera_device_t *vendor;
    bool firstFocusWithFlash;
    bool previewStarted;
    bool activeFocusMove;

    camera_notify_callback notifyCallback;
    camera_data_callback dataCallback;
    camera_data_timestamp_callback dataTimestampCallback;
    camera_request_memory requestMemoryCallback;
    void *callbackUserData;
};

struct nvcamera_device_ops_t : camera_device_ops_t {
    int (*set_custom_parameters)(struct camera_device *, const char *parms);
    char *(*get_custom_parameters)(struct camera_device *);
    int (*get_flash_on)(struct camera_device *);
    int (*get_focus_position)(struct camera_device *);
    int (*get_iso_value)(struct camera_device *);
    float (*get_wb_cct)(struct camera_device *);
};

#define VENDOR_CALL(device, func, ...) ({ \
    wrapper_camera_device_t *__wrapper_dev = (wrapper_camera_device_t*) device; \
    reinterpret_cast<nvcamera_device_ops_t*>(__wrapper_dev->vendor->ops)->func(__wrapper_dev->vendor, ##__VA_ARGS__); \
})

#define CAMERA_ID(device) (((wrapper_camera_device_t *)(device))->id)

static inline wrapper_camera_device_t *toWrapper(struct camera_device *device)
{
    return reinterpret_cast<wrapper_camera_device_t *>(device);
}

static inline wrapper_camera_device_t *toWrapper(void *device)
{
    return reinterpret_cast<wrapper_camera_device_t *>(device);
}

static camera_module_t *loadVendorModule()
{
    ALOGV("%s", __FUNCTION__);

    camera_module_t *module = NULL;
    int rv = hw_get_module_by_class("camera", "vendor",
            (const hw_module_t**)&module);
    if (rv)
        ALOGE("failed to load vendor camera module: %d", rv);

    return module;
}

static camera_module_t *getVendorModule()
{
    static camera_module_t *vendorModule = loadVendorModule();
    return vendorModule;
}

static char *camera_fixup_getparams(wrapper_camera_device_t *wrapper __attribute__((unused)),
        const char *settings)
{
    android::CameraParameters params;
    params.unflatten(android::String8(settings));

#ifdef LOG_PARAMETERS
    ALOGV("%s: Original parameters:", __FUNCTION__);
    params.dump();
#endif

#ifdef LOG_PARAMETERS
    ALOGV("%s: Fixed parameters:", __FUNCTION__);
    params.dump();
#endif

    android::String8 strParams = params.flatten();
    return strdup(strParams.string());
}

static char *camera_fixup_setparams(wrapper_camera_device_t *wrapper __attribute__((unused)),
                                    const char *settings)
{
    android::CameraParameters params;
    params.unflatten(android::String8(settings));

#ifdef LOG_PARAMETERS
    ALOGV("%s: original parameters:", __FUNCTION__);
    params.dump();
#endif

#ifdef LOG_PARAMETERS
    ALOGV("%s: fixed parameters:", __FUNCTION__);
    params.dump();
#endif

    android::String8 strParams = params.flatten();
    return strdup(strParams.string());
}

/*******************************************************************
 * implementation of camera_device_ops functions
 *******************************************************************/

static int camera_set_preview_window(struct camera_device *device,
        struct preview_stream_ops *window)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, set_preview_window, window);
}

// {{{ intercept callbacks
static void intercept_notify(int32_t msg_type,
                             int32_t ext1,
                             int32_t ext2,
                             void *user)
{ 
    wrapper_camera_device_t *wrapper = toWrapper(user);
    switch (msg_type) {
    case CAMERA_MSG_FOCUS:
        break;

    case CAMERA_MSG_FOCUS_MOVE:
        if (ext1) {
            ALOGV("GOT FOCUS MOVE START");
            if (wrapper->activeFocusMove) {
                // avoid move start inside move start
                return;
            }
            wrapper->activeFocusMove = true;
        } else {
            ALOGV("GOT FOCUS MOVE STOP");
            wrapper->activeFocusMove = false;
        }
        break;
    }
    wrapper->notifyCallback(msg_type, ext1, ext2, wrapper->callbackUserData);
}

static void intercept_data(int32_t msg_type,
                           const camera_memory_t *data, unsigned int index,
                           camera_frame_metadata_t *metadata, void *user)
{
    toWrapper(user)->dataCallback(msg_type, data, index, metadata, toWrapper(user)->callbackUserData);
}

static void intercept_dataTimestamp(int64_t timestamp,
                                    int32_t msg_type,
                                    const camera_memory_t *data, unsigned int index,
                                    void *user)
{
    toWrapper(user)->dataTimestampCallback(timestamp, msg_type, data, index, toWrapper(user)->callbackUserData);
}

static camera_memory_t *intercept_requestMemory(int fd, size_t buf_size, unsigned int num_bufs,
                                                void *user)
{
    return toWrapper(user)->requestMemoryCallback(fd, buf_size, num_bufs, toWrapper(user)->callbackUserData);
}
// }}}

static void camera_set_callbacks(struct camera_device *device,
                                 camera_notify_callback notifyCallback,
                                 camera_data_callback dataCallback,
                                 camera_data_timestamp_callback dataTimestampCallback,
                                 camera_request_memory requestMemoryCallback,
                                 void *user)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    wrapper_camera_device_t *wrapper = toWrapper(device);
    wrapper->notifyCallback = notifyCallback;
    wrapper->dataCallback = dataCallback;
    wrapper->dataTimestampCallback = dataTimestampCallback;
    wrapper->requestMemoryCallback = requestMemoryCallback;
    wrapper->callbackUserData = user;

    VENDOR_CALL(device, set_callbacks, intercept_notify, intercept_data, intercept_dataTimestamp,
            intercept_requestMemory, (void *)wrapper);
}

static void camera_enable_msg_type(struct camera_device *device,
        int32_t msg_type)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, enable_msg_type, msg_type);
}

static void camera_disable_msg_type(struct camera_device *device,
        int32_t msg_type)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, disable_msg_type, msg_type);
}

static int camera_msg_type_enabled(struct camera_device *device,
        int32_t msg_type)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return 0;

    return VENDOR_CALL(device, msg_type_enabled, msg_type);
}

static int camera_start_preview(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, start_preview);
}

static void camera_stop_preview(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, stop_preview);
}

static int camera_preview_enabled(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, preview_enabled);
}

static int camera_store_meta_data_in_buffers(struct camera_device *device,
        int enable)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, store_meta_data_in_buffers, enable);
}

static int camera_start_recording(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return EINVAL;

    return VENDOR_CALL(device, start_recording);
}

static void camera_stop_recording(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, stop_recording);
}

static int camera_recording_enabled(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, recording_enabled);
}

static void camera_release_recording_frame(struct camera_device *device,
        const void *opaque)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, release_recording_frame, opaque);
}

static int camera_auto_focus(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    if (toWrapper(device)->activeFocusMove) {
        ALOGV("FORCED FOCUS MOVE STOP");
        VENDOR_CALL(device, cancel_auto_focus);
        toWrapper(device)->activeFocusMove = false;
    }

    return VENDOR_CALL(device, auto_focus);
}

static int camera_cancel_auto_focus(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    toWrapper(device)->activeFocusMove = false;
    return VENDOR_CALL(device, cancel_auto_focus);
}

static int camera_take_picture(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    bool flashModeOn;
    {
        android::CameraParameters params;
        char *currentParams = VENDOR_CALL(device, get_parameters);
        params.unflatten(android::String8(currentParams));
        VENDOR_CALL(device, put_parameters, currentParams);
        const char *flashMode = params.get(android::CameraParameters::KEY_FLASH_MODE);
        flashModeOn = flashMode && strcmp(flashMode, android::CameraParameters::FLASH_MODE_OFF) != 0;
    }

    if (flashModeOn) {
        if (!toWrapper(device)->firstFocusWithFlash) {
            toWrapper(device)->firstFocusWithFlash = true;
            // focus once to avoid black picture issue
            VENDOR_CALL(device, cancel_auto_focus);
            VENDOR_CALL(device, auto_focus);
            VENDOR_CALL(device, stop_preview);
            VENDOR_CALL(device, start_preview);
        }
    }

    int ret = VENDOR_CALL(device, take_picture);

    if (flashModeOn) {
        // state messed up, restart preview to sync status and flush buffer
        VENDOR_CALL(device, stop_preview);
        VENDOR_CALL(device, start_preview);
    }

    return ret;
}

static int camera_cancel_picture(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, cancel_picture);
}

static int camera_set_parameters(struct camera_device *device,
        const char *params)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    char *fixed_params = camera_fixup_setparams(toWrapper(device), params);
    int ret = VENDOR_CALL(device, set_parameters, fixed_params);
    free(fixed_params);
    return ret;
}

static char *camera_get_parameters(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return NULL;

    char *params = VENDOR_CALL(device, get_parameters);
    char *fixed_params = camera_fixup_getparams(toWrapper(device), params);
    VENDOR_CALL(device, put_parameters, params);
    return fixed_params;
}

static void camera_put_parameters(struct camera_device *device, char *params)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (params)
        free(params);
}

static int camera_send_command(struct camera_device *device,
        int32_t cmd, int32_t arg1, int32_t arg2)
{
#if 0
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));
#endif

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, send_command, cmd, arg1, arg2);
}

static void camera_release(struct camera_device *device)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return;

    VENDOR_CALL(device, release);
}

static int camera_dump(struct camera_device *device, int fd)
{
    ALOGV("%s->%08X->%08X", __FUNCTION__, (uintptr_t)device,
            (uintptr_t)(((wrapper_camera_device_t*)device)->vendor));

    if (!device)
        return -EINVAL;

    return VENDOR_CALL(device, dump, fd);
}

extern "C" void heaptracker_free_leaked_memory(void);

static int camera_device_close(hw_device_t *device)
{
    wrapper_camera_device_t *wrapper_dev = reinterpret_cast<wrapper_camera_device_t *>(device);

    ALOGV("%s", __FUNCTION__);

    android::Mutex::Autolock lock(gCameraWrapperLock);

    int ret = 0;
    if (!device) {
        ret = -EINVAL;
        goto done;
    }

    wrapper_dev->vendor->common.close((hw_device_t*)wrapper_dev->vendor);
    if (wrapper_dev->base.ops)
        delete wrapper_dev->base.ops;
    delete wrapper_dev;
done:
#ifdef HEAPTRACKER
    heaptracker_free_leaked_memory();
#endif
    return ret;
}

/*******************************************************************
 * implementation of camera_module functions
 *******************************************************************/

/* open device handle to one of the cameras
 *
 * assume camera service will keep singleton of each camera
 * so this function will always only be called once per camera instance
 */

static int camera_device_open(const hw_module_t *module, const char *name,
        hw_device_t **device)
{
    android::Mutex::Autolock lock(gCameraWrapperLock);

    ALOGV("%s", __FUNCTION__);

    if (!name) {
        return -EINVAL;
    }

    if (!getVendorModule()) {
        return -EINVAL;
    }

    int cameraid = atoi(name);
    int num_cameras = getVendorModule()->get_number_of_cameras();
    ALOGI("camera count = %d", num_cameras);

    int rv = 0;

    if (cameraid > num_cameras) {
        ALOGE("camera service provided cameraid out of bounds, "
                "cameraid = %d, num supported = %d",
                cameraid, num_cameras);
        return -EINVAL;
    }

    wrapper_camera_device_t *camera_device = new wrapper_camera_device_t();
    camera_device_ops_t *camera_ops = NULL;

    if (!camera_device) {
        ALOGE("camera_device allocation fail");
        rv = -ENOMEM;
        goto fail;
    }
    memset(camera_device, 0, sizeof(*camera_device));
    camera_device->id = cameraid;

    // camera require sensorservice to be up
    {
        using namespace android;
        const String16 sensorServiceName("sensorservice");
        sp<ISensorServer> sensorServer;
        for (int i = 0; i < 60; i++) {
            status_t err = getService(sensorServiceName, &sensorServer);
            if (err == NAME_NOT_FOUND) {
                ALOGI("Waiting for sensorservice ...");
                sleep(1);
                continue;
            }
            if (err != NO_ERROR) {
                return err;
            }
            break;
        }
    }

    ALOGV("calling vendor camera_device_open ...");
    rv = getVendorModule()->common.methods->open(
            (const hw_module_t*)getVendorModule(), name,
            (hw_device_t**)&(camera_device->vendor));
    if (rv) {
        ALOGE("vendor camera open fail");
        goto fail;
    }
    ALOGV("%s: got vendor camera device 0x%08X",
            __FUNCTION__, (uintptr_t)(camera_device->vendor));

    camera_ops = new camera_device_ops_t();
    if (!camera_ops) {
        ALOGE("camera_ops allocation fail");
        rv = -ENOMEM;
        goto fail;
    }

    memset(camera_ops, 0, sizeof(*camera_ops));

    camera_device->base.common.tag = HARDWARE_DEVICE_TAG;
    camera_device->base.common.version = CAMERA_DEVICE_API_VERSION_1_0;
    camera_device->base.common.module = (hw_module_t *)(module);
    camera_device->base.common.close = camera_device_close;
    camera_device->base.ops = camera_ops;

    camera_ops->set_preview_window = camera_set_preview_window;
    camera_ops->set_callbacks = camera_set_callbacks;
    camera_ops->enable_msg_type = camera_enable_msg_type;
    camera_ops->disable_msg_type = camera_disable_msg_type;
    camera_ops->msg_type_enabled = camera_msg_type_enabled;
    camera_ops->start_preview = camera_start_preview;
    camera_ops->stop_preview = camera_stop_preview;
    camera_ops->preview_enabled = camera_preview_enabled;
    camera_ops->store_meta_data_in_buffers = camera_store_meta_data_in_buffers;
    camera_ops->start_recording = camera_start_recording;
    camera_ops->stop_recording = camera_stop_recording;
    camera_ops->recording_enabled = camera_recording_enabled;
    camera_ops->release_recording_frame = camera_release_recording_frame;
    camera_ops->auto_focus = camera_auto_focus;
    camera_ops->cancel_auto_focus = camera_cancel_auto_focus;
    camera_ops->take_picture = camera_take_picture;
    camera_ops->cancel_picture = camera_cancel_picture;
    camera_ops->set_parameters = camera_set_parameters;
    camera_ops->get_parameters = camera_get_parameters;
    camera_ops->put_parameters = camera_put_parameters;
    camera_ops->send_command = camera_send_command;
    camera_ops->release = camera_release;
    camera_ops->dump = camera_dump;

    *device = &camera_device->base.common;

    return rv;

fail:
    if (camera_ops) {
        delete camera_ops;
        camera_ops = NULL;
    }

    if (camera_device) {
        delete camera_device;
        camera_device = NULL;
    }

    *device = NULL;
    return rv;
}

static int camera_get_number_of_cameras(void)
{
    int ret = getVendorModule() ? getVendorModule()->get_number_of_cameras() : 0;
    ALOGV("%s = %d", __FUNCTION__, ret);
    return ret;
}

static int camera_get_camera_info(int camera_id, struct camera_info *info)
{
    ALOGV("%s", __FUNCTION__);
    return getVendorModule() ? getVendorModule()->get_camera_info(camera_id, info) : 0;
}

static struct hw_module_methods_t camera_module_methods = {
    .open = camera_device_open
};

camera_module_t HAL_MODULE_INFO_SYM = {
    .common = {
         .tag = HARDWARE_MODULE_TAG,
         .module_api_version = CAMERA_MODULE_API_VERSION_1_0,
         .hal_api_version = HARDWARE_HAL_API_VERSION,
         .id = CAMERA_HARDWARE_MODULE_ID,
         .name = "Pisces Camera Wrapper",
         .author = "Xuefer <xuefer@gmail.com>",
         .methods = &camera_module_methods,
         .dso = NULL, /* remove compilation warnings */
         .reserved = {0}, /* remove compilation warnings */
    },
    .get_number_of_cameras = camera_get_number_of_cameras,
    .get_camera_info = camera_get_camera_info,
    .set_callbacks = NULL, /* remove compilation warnings */
    .get_vendor_tag_ops = NULL, /* remove compilation warnings */
    .open_legacy = NULL, /* remove compilation warnings */
    .reserved = {0}, /* remove compilation warnings */
};
