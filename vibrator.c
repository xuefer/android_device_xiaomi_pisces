/*
 * Copyright (C) 2011 CyanogenMod Project
 * Copyright (C) 2011 Daniel Hillenbrand
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
 
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <dlfcn.h>

#include "stdio.h"
#include "string.h"
#include "stdlib.h"

#define LOG_NDEBUG 0
#define LOG_TAG "tspdrv"
#include <utils/Log.h>
 
// copy from api
#include <sys/types.h>
#include <limits.h>

#define VIBE_TRUE						1
#define VIBE_FALSE						0

typedef int8_t						    VibeInt8;
typedef u_int8_t					    VibeUInt8;
typedef int16_t					        VibeInt16;
typedef u_int16_t					    VibeUInt16;
typedef int32_t						    VibeInt32;
typedef u_int32_t					    VibeUInt32;
typedef u_int8_t					    VibeBool;
typedef unsigned short                  VibeWChar;

#define VIBE_INVALID_EFFECT_HANDLE_VALUE            -1 /*!< Invalid Effect Handle */
#define VIBE_INVALID_DEVICE_HANDLE_VALUE            -1 /*!< Invalid Device Handle */

#define VIBE_SUCCEEDED(n)                           ((n) >= 0)
#define VIBE_FAILED(n)                              ((n) < 0)
#define VIBE_IS_INVALID_DEVICE_HANDLE(n)            (((n) == 0) || ((n) == VIBE_INVALID_DEVICE_HANDLE_VALUE))
#define VIBE_IS_INVALID_EFFECT_HANDLE(n)            (((n) == 0) || ((n) == VIBE_INVALID_EFFECT_HANDLE_VALUE))
#define VIBE_IS_VALID_DEVICE_HANDLE(n)              (((n) != 0) && ((n) != VIBE_INVALID_DEVICE_HANDLE_VALUE))
#define VIBE_IS_VALID_EFFECT_HANDLE(n)              (((n) != 0) && ((n) != VIBE_INVALID_EFFECT_HANDLE_VALUE))

// ImmVibeCore.h
#define VIBE_MAX_MAGNITUDE                          10000 /*!< Maximum Force Magnitude */
#define VIBE_MIN_MAGNITUDE                          0     /*!< Minimum Force Magnitude */   
#define VIBE_MAX_EFFECT_NAME_LENGTH                 128   /*!< Maximum effect name length */
#define VIBE_INVALID_INDEX                          -1    /*!< Invalid Index */

/* Periodic, MagSweep effect Styles */
#define VIBE_STYLE_SMOOTH                           0   /*!< "Smooth" style */
#define VIBE_STYLE_STRONG                           1   /*!< "Strong" style */
#define VIBE_STYLE_SHARP                            2   /*!< "Sharp" style  */

#define VIBE_S_SUCCESS                               0  /*!< Success */
#define VIBE_S_FALSE                                 0  /*!< False */
#define VIBE_S_TRUE                                  1  /*!< True */
#define VIBE_W_NOT_PLAYING                           1  /*!< Effect is not playing */
#define VIBE_W_INSUFFICIENT_PRIORITY                 2  /*!< Effect doesn't have enough priority to play: higher priority effect is playing on the device */
#define VIBE_W_EFFECTS_DISABLED                      3  /*!< Effects are disabled on the device */
#define VIBE_W_NOT_PAUSED                            4  /*!< The ImmVibeResumePausedEffect function cannot resume an effect that is not paused */
#define VIBE_E_ALREADY_INITIALIZED                  -1  /*!< The API is already initialized (NOT USED) */
#define VIBE_E_NOT_INITIALIZED                      -2  /*!< The API is already is not initialized */
#define VIBE_E_INVALID_ARGUMENT                     -3  /*!< Invalid argument was used in a API function call */
#define VIBE_E_FAIL                                 -4  /*!< Generic error */
#define VIBE_E_INCOMPATIBLE_EFFECT_TYPE             -5  /*!< Incompatible Effect type has been passed into  API function call */
#define VIBE_E_INCOMPATIBLE_CAPABILITY_TYPE         -6  /*!< Incompatible Capability type was used into one of the following functions */
#define VIBE_E_INCOMPATIBLE_PROPERTY_TYPE           -7  /*!< Incompatible Property type was used into one of the following functions */
#define VIBE_E_DEVICE_NEEDS_LICENSE                 -8  /*!< Access to the instance of the device is locked until a valid license key is provided. */
#define VIBE_E_NOT_ENOUGH_MEMORY                    -9  /*!< The API function cannot allocate memory to complete the process */
#define VIBE_E_SERVICE_NOT_RUNNING                  -10 /*!< ImmVibeService is not running */
#define VIBE_E_INSUFFICIENT_PRIORITY                -11 /*!< Not enough priority to achieve the request (insufficient license key priority) */
#define VIBE_E_SERVICE_BUSY                         -12 /*!< ImmVibeService is busy and failed to complete the request */
#define VIBE_E_NOT_SUPPORTED                        -13 /*!< The API function is not supported by this version of the API */

typedef VibeInt32   VibeStatus;

// ..

#define VIBE_LICENSE_KEY_GALAXYS "DH75NDX26JR75GCZ5CKKTD25M9JP62TG"
// 3.3.13.1
#define VIBE_GALAXYS_VERSION_NUMBER 0x0303010D

#define IN
#define OUT
#define IMMVIBEAPI(return_type, function_name) typedef return_type (*function_name##_t)

IMMVIBEAPI(VibeStatus, ImmVibeInitialize)
(
	IN VibeInt32 nVersion
);

IMMVIBEAPI(VibeStatus, ImmVibeTerminate)(void);

IMMVIBEAPI(VibeStatus, ImmVibeOpenDevice)
(
	IN VibeInt32 nDeviceIndex,
	OUT VibeInt32 *phDeviceHandle
);

IMMVIBEAPI(VibeStatus, ImmVibeCloseDevice)
(
	IN VibeInt32 hDeviceHandle
);

IMMVIBEAPI(VibeStatus, ImmVibePlayMagSweepEffect)
(
	IN VibeInt32 hDeviceHandle,
	IN VibeInt32 nDuration,
	IN VibeInt32 nMagnitude,
	IN VibeInt32 nStyle,
	IN VibeInt32 nAttackTime,
	IN VibeInt32 nAttackLevel,
	IN VibeInt32 nFadeTime,
	IN VibeInt32 nFadeLevel,
	OUT VibeInt32 *phEffectHandle
);

IMMVIBEAPI(VibeStatus, ImmVibeStopAllPlayingEffects)
(
	IN VibeInt32 hDeviceHandle
);

#define DoWithImmSymbols(action) \
	action(ImmVibeInitialize); \
	action(ImmVibeTerminate); \
	action(ImmVibeOpenDevice); \
	action(ImmVibeCloseDevice); \
	action(ImmVibePlayMagSweepEffect); \
	action(ImmVibeStopAllPlayingEffects);

#define define_symbol(name) static name##_t name
DoWithImmSymbols(define_symbol)
#undef define_symbol

static void *libImmVibeJ_so_handle;
static void libImmVibeJ_init()
{
	if (!(libImmVibeJ_so_handle = dlopen("libImmVibeJ.so", RTLD_LOCAL))) {
		ALOGE("error opening libImmVibeJ.so");
		goto err;
	}

#define load_symbol(name) do { \
	if (!(name = (name##_t) dlsym(libImmVibeJ_so_handle, #name))) { \
		ALOGE("error loading symbol %s", #name); \
		goto err; \
	} \
} while (0)

	DoWithImmSymbols(load_symbol)
#undef load_symbol
	return;

err:
#define clear_symbol(name) name = NULL
	DoWithImmSymbols(clear_symbol)
#undef clear_symbol
}

static VibeInt32 devHandle = VIBE_INVALID_DEVICE_HANDLE_VALUE;
static int immVibeInitialized = 0;

static void vibrate_terminate();
static VibeStatus vibrate_init()
{
	if (!ImmVibeInitialize) {
		libImmVibeJ_init();
		if (!ImmVibeInitialize) {
			return VIBE_E_NOT_INITIALIZED;
		}
	}

	VibeStatus vs = VIBE_S_SUCCESS;
	if (!immVibeInitialized) {
		vs = ImmVibeInitialize(VIBE_GALAXYS_VERSION_NUMBER);
		if (VIBE_FAILED(vs)) {
			ALOGE("Initialization Failed: status=%d", (int) vs);

			if (vs == VIBE_E_INVALID_ARGUMENT) {
				ALOGE("Version number do not match");
			}
			return vs;
		}
		immVibeInitialized = 1;
		ALOGI("Initialized ok");
	}

	if (!VIBE_IS_VALID_DEVICE_HANDLE(devHandle)) {
		vs = ImmVibeOpenDevice(0, &devHandle);

		if (VIBE_FAILED(vs)) {
			ALOGE("Open device Failed, status=%d", (int) vs);
			vibrate_terminate();
			return vs;
		}
	}
	return vs;
}

static void vibrate_terminate()
{
	if (VIBE_IS_VALID_DEVICE_HANDLE(devHandle)) {
		ImmVibeCloseDevice(devHandle);
		devHandle = VIBE_INVALID_DEVICE_HANDLE_VALUE;
	}

	if (immVibeInitialized) {
		ImmVibeTerminate();
		immVibeInitialized = 0;
	}
}

static VibeStatus vibrate_on(int duration)
{
	ALOGI("Vibrating");
	VibeInt32 effectHandle;
	VibeStatus vs = ImmVibePlayMagSweepEffect(devHandle, duration, VIBE_MAX_MAGNITUDE, VIBE_STYLE_SHARP, 0, 0, 0, 0, &effectHandle);
	if (VIBE_FAILED(vs)) {
		ALOGE("ImmVibePlayMagSweepEffect failed, status=%d", (int) vs);
		vibrate_terminate();
	}
	return vs;
}

static VibeStatus vibrate_off()
{
	ALOGI("Stopping");
	VibeStatus vs = ImmVibeStopAllPlayingEffects(devHandle);
	if (VIBE_FAILED(vs)) {
		ALOGE("ImmVibeStopAllPlayingEffects failed, status=%d", (int) vs);
		vibrate_terminate();
	}
	return vs;
}

int vibrator_exists()
{
    return 1;
}

int sendit(int timeout_ms)
{
	if (VIBE_FAILED(vibrate_init())) {
		return -1;
	}

	ALOGI("vibrate sendit(%d)", timeout_ms);

    VibeStatus vs = timeout_ms ? vibrate_on(timeout_ms) : vibrate_off();
	return VIBE_FAILED(vs) ? 0 : -1;
}

