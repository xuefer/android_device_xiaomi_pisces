/*
 * Copyright (C) 2008 The Android Open Source Project
 * Copyright (C) 2015 Xuefer <xuefer@gmail.com>
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

#define LOG_NDEBUG 0
#define LOG_TAG "lights"
#include <cutils/log.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <hardware/lights.h>

static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

static struct light_state_t g_attention;
static struct light_state_t g_notification;
static struct light_state_t g_battery;

char const *const LCD_0_FILE  = "/sys/class/backlight/lm3533-backlight0/brightness";
char const *const LCD_1_FILE  = "/sys/class/backlight/lm3533-backlight1/brightness";
char const *const BUTTON_FILE = "/sys/class/leds/button-backlight/brightness";

char const *const LED_RED_FILE    = "/sys/class/leds/red/brightness";
char const *const LED_GREEN_FILE  = "/sys/class/leds/green/brightness";
char const *const LED_BLUE_FILE   = "/sys/class/leds/blue/brightness";
char const *const LED_UPDATE_FILE = "/sys/class/leds/red/update";


static int write_int(char const *path, int value)
{
	int fd;
	static int already_warned = 0;

	ALOGV("write_int: path %s, value %d", path, value);
	fd = open(path, O_RDWR);
	if (fd >= 0) {
		char buffer[20];
		int bytes = sprintf(buffer, "%d\n", value);
		int amt = write(fd, buffer, bytes);
		close(fd);
		return amt == -1 ? -errno : 0;
	} else {
		if (already_warned == 0) {
			ALOGE("write_int failed to open %s\n", path);
			already_warned = 1;
		}
		return -errno;
	}
}

static int is_lit(struct light_state_t const* state)
{
	return state->color & 0x00ffffff;
}

static int rgb_to_brightness(struct light_state_t const *state)
{
	int color = state->color & 0x00ffffff;

	return ((77*((color>>16) & 0x00ff))
			+ (150*((color>>8) & 0x00ff)) + (29*(color & 0x00ff))) >> 8;
}

static int rgb_to_brightness_2(struct light_state_t const *state)
{
	int color = state->color & 0x00ffffff;

	return ((2*77*((color>>16) & 0x00ff))
			+ (2*150*((color>>8) & 0x00ff)) + (2*29*(color & 0x00ff))) >> 8;
}

static void dump_light_state(char const* name, struct light_state_t const* state)
{
	ALOGV("%s: color=%06X, mode=%d onMs=%d offMs=%d brightnessMode=%d"
		  , name
		  , state->color
		  , state->flashMode
		  , state->flashOnMS
		  , state->flashOffMS
		  , state->brightnessMode
		  );
}

static int set_light_backlight(struct light_device_t* dev, struct light_state_t const* state)
{
	int err = 0;
	int brightness = rgb_to_brightness_2(state);
	static int old_brightness = -1;

	pthread_mutex_lock(&g_lock);
	if (old_brightness < 0 || (old_brightness != brightness)) {
		err = write_int(LCD_0_FILE, brightness / 2);
		if (!err) {
			err = write_int(LCD_1_FILE, (brightness + 1) / 2);
		}
	}
	old_brightness = brightness;
	pthread_mutex_unlock(&g_lock);

	return err;
}

static int set_light_buttons(struct light_device_t* dev, struct light_state_t const* state)
{
	int err = 0;
	int brightness = rgb_to_brightness(state);
	static int old_brightness = -1;

	pthread_mutex_lock(&g_lock);
	if (old_brightness < 0 || (old_brightness != brightness)) {
		err = write_int(BUTTON_FILE, brightness);
	}
	old_brightness = brightness;
	pthread_mutex_unlock(&g_lock);

	return err;
}

static int set_speaker_light_locked(struct light_device_t* dev, struct light_state_t const* state)
{
	int err = 0;
	dump_light_state("attention",    &g_attention);
	dump_light_state("notification", &g_notification);
	dump_light_state("battery",      &g_battery);

	if (is_lit(state)) {
		// turn off before on to reset timer
		write_int(LED_RED_FILE, 0);
		write_int(LED_GREEN_FILE, 0);
		write_int(LED_BLUE_FILE, 0);
		write_int(LED_UPDATE_FILE, 1);
		usleep(100000);
	}

	write_int(LED_RED_FILE, (state->color >> 16) & 0xFF);
	write_int(LED_GREEN_FILE, (state->color >> 8) & 0xFF);
	write_int(LED_BLUE_FILE, state->color & 0xFF);
	return write_int(LED_UPDATE_FILE, 1);
}

static int update_speaker_light_locked(struct light_device_t* dev)
{
	if (is_lit(&g_attention)) {
		return set_speaker_light_locked(dev, &g_attention);
	} else if (is_lit(&g_notification)) {
		return set_speaker_light_locked(dev, &g_notification);
	} else {
		return set_speaker_light_locked(dev, &g_battery);
	}
}

static int set_light_attention(struct light_device_t* dev, struct light_state_t const* state)
{
	ALOGV(__func__);
	pthread_mutex_lock(&g_lock);
	g_attention = *state;
	int ret = update_speaker_light_locked(dev);
	pthread_mutex_unlock(&g_lock);
	return ret;
}

static int set_light_notifications(struct light_device_t* dev, struct light_state_t const* state)
{
	ALOGV(__func__);
	pthread_mutex_lock(&g_lock);
	g_notification = *state;
	int ret = update_speaker_light_locked(dev);
	pthread_mutex_unlock(&g_lock);
	return ret;
}

static int set_light_battery(struct light_device_t* dev, struct light_state_t const* state)
{
	ALOGV(__func__);
	pthread_mutex_lock(&g_lock);
	g_battery = *state;
	int ret = update_speaker_light_locked(dev);
	pthread_mutex_unlock(&g_lock);
	return ret;
}

static int close_lights(struct light_device_t *dev)
{
	if (dev) {
		free(dev);
	}
	return 0;
}


/** Open a new instance of a lights device using name */
static int open_lights(const struct hw_module_t *module, char const *name,
						struct hw_device_t **device)
{
	int (*set_light)(struct light_device_t *dev,
		struct light_state_t const *state);

	ALOGV("open_lights: open with %s", name);

	if (0 == strcmp(LIGHT_ID_BACKLIGHT, name))
		set_light = set_light_backlight;
	else if (0 == strcmp(LIGHT_ID_BUTTONS, name))
		set_light = set_light_buttons;
    else if (0 == strcmp(LIGHT_ID_ATTENTION, name))
        set_light = set_light_attention;
	else if (0 == strcmp(LIGHT_ID_NOTIFICATIONS, name))
		set_light = set_light_notifications;
	else if (0 == strcmp(LIGHT_ID_BATTERY, name))
		set_light = set_light_battery;
	else
		return -EINVAL;

	struct light_device_t *dev = malloc(sizeof(struct light_device_t));
	memset(dev, 0, sizeof(*dev));

	dev->common.tag = HARDWARE_DEVICE_TAG;
	dev->common.version = 0;
	dev->common.module = (struct hw_module_t *)module;
	dev->common.close = (int (*)(struct hw_device_t *))close_lights;
	dev->set_light = set_light;

	*device = (struct hw_device_t *)dev;
	return 0;
}

static struct hw_module_methods_t lights_module_methods = {
	.open =  open_lights,
};

/*
 * The lights Module
 */
struct hw_module_t HAL_MODULE_INFO_SYM = {
	.tag = HARDWARE_MODULE_TAG,
	.version_major = 1,
	.version_minor = 0,
	.id = LIGHTS_HARDWARE_MODULE_ID,
	.name = "NVIDIA Pluto lights module",
	.author = "Xuefer",
	.methods = &lights_module_methods,
};

