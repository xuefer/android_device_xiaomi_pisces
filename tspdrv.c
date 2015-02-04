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
#include "qemu.h"

#include "stdio.h"
#include "string.h"
#include "stdlib.h"

#define LOG_NDEBUG 0
#define LOG_TAG "tspdrv"
#include <utils/Log.h>
 
#define THE_DEVICE				"/sys/class/timed_output/vibrator/enable"
#define TSPDRV_DEVICE			"/dev/tspdrv"
 
#define TSPDRV_MAGIC_NUMBER                 0x494D4D52
#define TSPDRV_IOCTL_GROUP                  0x52
#define TSPDRV_STOP_KERNEL_TIMER            _IO(TSPDRV_IOCTL_GROUP, 1) /* obsolete, may be removed in future */
#define TSPDRV_SET_MAGIC_NUMBER             _IO(TSPDRV_IOCTL_GROUP, 2)
#define TSPDRV_ENABLE_AMP                   _IO(TSPDRV_IOCTL_GROUP, 3)
#define TSPDRV_DISABLE_AMP                  _IO(TSPDRV_IOCTL_GROUP, 4)
#define TSPDRV_GET_NUM_ACTUATORS            _IO(TSPDRV_IOCTL_GROUP, 5)
#define TSPDRV_SET_DEVICE_PARAMETER         _IO(TSPDRV_IOCTL_GROUP, 6)
#define TSPDRV_SET_DBG_LEVEL                _IO(TSPDRV_IOCTL_GROUP, 7)
#define TSPDRV_GET_DBG_LEVEL                _IO(TSPDRV_IOCTL_GROUP, 8)
 
/* 
** Frequency constant parameters to control force output values and signals.
*/
#define VIBE_KP_CFG_FREQUENCY_PARAM1        85
#define VIBE_KP_CFG_FREQUENCY_PARAM2        86
#define VIBE_KP_CFG_FREQUENCY_PARAM3        87
#define VIBE_KP_CFG_FREQUENCY_PARAM4        88
#define VIBE_KP_CFG_FREQUENCY_PARAM5        89
#define VIBE_KP_CFG_FREQUENCY_PARAM6        90
 
/* 
** Force update rate in milliseconds.
*/
#define VIBE_KP_CFG_UPDATE_RATE_MS          95
 
#define VIBE_MAX_DEVICE_NAME_LENGTH			64
#define SPI_HEADER_SIZE                     3   /* DO NOT CHANGE - SPI buffer header size */
#define VIBE_OUTPUT_SAMPLE_SIZE             50  /* DO NOT CHANGE - maximum number of samples */
#define MAX_DEBUG_BUFFER_LENGTH             1024
 
typedef int8_t		VibeInt8;
typedef u_int8_t	VibeUInt8;
typedef int16_t		VibeInt16;
typedef u_int16_t	VibeUInt16;
typedef int32_t		VibeInt32;
typedef u_int32_t	VibeUInt32;
typedef u_int8_t	VibeBool;
typedef VibeInt32	VibeStatus;
 
#define VIBE_NUM 50
VibeInt8 timedForce[VIBE_NUM+SPI_HEADER_SIZE] = {0,8,VIBE_NUM, 5,10,20,30,40,50,60,70,80,126,126,126,126,126,126,126,126,126,126,50,40,30,20,10,126,126,126,126,126,126,126,126,80,60,50,40,30,20,10,0,0,0,0,0,0,0,0,0,0,0};
 
/* Device parameters sent to the kernel module, tspdrv.ko */
typedef struct
{
    VibeInt32 nDeviceIndex;
    VibeInt32 nDeviceParamID;
    VibeInt32 nDeviceParamValue;
} device_parameter;
 
/* Error and Return value codes */
#define VIBE_S_SUCCESS                      0	/* Success */
#define VIBE_E_FAIL						    -4	/* Generic error */
 
int vibrator_exists()
{
    int fd;
 
#ifdef QEMU_HARDWARE
    if (qemu_check()) {
        return 1;
    }
#endif
 
    fd = open(THE_DEVICE, O_RDWR);
    if(fd < 0)
        return 0;
    close(fd);
    return 1;
}
 
int sendit(int timeout_ms)
{
    int i, ret, fd, tspd, tspret, actuators;
    char value[20];
    device_parameter deviceParam;
 
    tspd = open(TSPDRV_DEVICE, O_RDWR);
    if(tspd < 0) {
        ALOGE("failed on opening /dev/tspdrv\n");
        return -1;
    } else {
        ALOGV("opened device /dev/tspdrv\n");
    }
 
    /* send tspdrv magic number */
    tspret = ioctl(tspd, TSPDRV_SET_MAGIC_NUMBER, TSPDRV_MAGIC_NUMBER);
    if(tspret != VIBE_S_SUCCESS) {
        ALOGE("TSPDRV_MAGIC_NUMBER error\n");
    } else {
        ALOGV("TSPDRV_MAGIC_NUMBER success\n");
    }
 
    /* get number of actuators */
    actuators = ioctl(tspd, TSPDRV_GET_NUM_ACTUATORS);
    if(actuators < 1) {
        ALOGE("TSPDRV_GET_NUM_ACTUATORS error, no actuators available\n");
    } else {
        ALOGV("TSPDRV_GET_NUM_ACTUATORS success, actuators = %d\n", actuators);
 
        if(timeout_ms > 0) {
            /* enable tspdrv amp */
            tspret = ioctl(tspd, TSPDRV_ENABLE_AMP, actuators);
            if(tspret != 0) {
                ALOGE("TSPDRV_ENABLE_AMP error\n");
            } else {
                ALOGV("TSPDRV_ENABLE_AMP success\n");
            }
        }
    }

    deviceParam.nDeviceIndex = actuators;
    deviceParam.nDeviceParamID = VIBE_KP_CFG_UPDATE_RATE_MS;
    deviceParam.nDeviceParamValue = 3;
	tspret = ioctl(tspd, TSPDRV_SET_DEVICE_PARAMETER, &deviceParam);
	if(tspret != VIBE_S_SUCCESS) {
        ALOGE("TSPDRV_SET_DEVICE_PARAMETER error\n");
    } else {
        ALOGV("TSPDRV_SET_DEVICE_PARAMETER success\n");
    }
 
    ALOGV("timeout_ms: %d\n", timeout_ms);  
 
    if(timeout_ms == 0) {
		/* disable tspdrv amp */
		tspret = ioctl(tspd, TSPDRV_DISABLE_AMP, actuators);
		if(tspret != 0) {
			ALOGE("TSPDRV_DISABLE_AMP error\n");
		} else {
			ALOGV("TSPDRV_DISABLE_AMP success\n");
		}
    }
    else
    {
    	timedForce[0] = actuators - 1;
    	timedForce[2] = VIBE_OUTPUT_SAMPLE_SIZE;
    	//tspret = write(tspd, timedForce, VIBE_NUM+SPI_HEADER_SIZE);
    	if (timeout_ms > VIBE_OUTPUT_SAMPLE_SIZE) timeout_ms = VIBE_OUTPUT_SAMPLE_SIZE;
    	for(i=0 ; i<VIBE_OUTPUT_SAMPLE_SIZE; i+=2)
    	{
    		timedForce[i+SPI_HEADER_SIZE] = 0;
    		timedForce[i+SPI_HEADER_SIZE + 1] = 127;
    	}
    	tspret = write(tspd, timedForce, VIBE_OUTPUT_SAMPLE_SIZE+SPI_HEADER_SIZE);
    	
		if(tspret == 0) {
			ALOGE("TSPDRV write error\n");
		} else {
			ALOGV("TSPDRV write success, %d\n", tspret);
		}
    }
 
    close(tspd);
 
    return 0;//(tspret == VIBE_NUM) ? 0 : -1;
}
