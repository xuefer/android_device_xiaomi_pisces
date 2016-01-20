/*
 * Copyright (C) 2014 The Android Open Source Project
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

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include <cutils/android_reboot.h>
#include <cutils/klog.h>
#include <cutils/misc.h>
#include <cutils/uevent.h>
#include <cutils/properties.h>

#include <pthread.h>
#include <linux/android_alarm.h>
#include <linux/rtc.h>

#include <healthd.h>

#define LOGE(x...) do { KLOG_ERROR("charger", x); } while (0)
#define LOGI(x...) do { KLOG_INFO("charger", x); } while (0)
#define LOGV(x...) do { KLOG_DEBUG("charger", x); } while (0)

enum alarm_time_type {
	ALARM_TIME,
	RTC_TIME,
};

#define RTC_WAKEALARM_PATH "/sys/class/rtc/rtc0/wakealarm"
#define RTC_EPOCH_PATH     "/sys/class/rtc/rtc0/since_epoch"

/*
 * shouldn't be changed after
 * reading from alarm register
 */
static time_t alm_secs;

static int alarm_get_time(enum alarm_time_type time_type,
						  time_t *secs)
{
	char buf[80];
	char *end;
	struct tm tm;
	unsigned int cmd;
	int rc, fd = -1;
	const char *path;

	if (!secs)
		return -1;

	switch (time_type) {
	case ALARM_TIME:
		path = RTC_WAKEALARM_PATH;
		break;

	case RTC_TIME:
		path = RTC_EPOCH_PATH;
		break;

	default:
		LOGE("Invalid time type\n");
		return -1;
	}

	fd = open(path, O_RDWR);
	if (fd < 0) {
		LOGE("Can't open path %s: %s\n", path, strerror_r(errno, buf, sizeof(buf)));
		return -1;
	}

	rc = read(fd, buf, sizeof(buf));
	if (rc < 0) {
		LOGE("Unable to get time\n");
		goto err;
	}
	end = buf + rc;

	errno = 0;
	*secs = strtol(buf, &end, 10);
	if (errno != 0) {
		LOGE("Invalid seconds = %ld: %s\n", *secs, strerror_r(errno, buf, sizeof(buf)));
		goto err;
	}

	close(fd);
	return 0;

err:
	close(fd);
	return -1;
}

#define ERR_SECS 2
static int alarm_is_alm_expired()
{
	int rc;
	time_t rtc_secs;

	rc = alarm_get_time(RTC_TIME, &rtc_secs);
	if (rc < 0)
		return 0;

	return (alm_secs >= rtc_secs - ERR_SECS &&
			alm_secs <= rtc_secs + ERR_SECS) ? 1 : 0;
}

static int alarm_set_reboot_time_and_wait(time_t secs)
{
	int rc, fd;
	struct timespec ts;

	fd = open("/dev/alarm", O_RDWR);
	if (fd < 0) {
		LOGE("Can't open alarm devfs node\n");
		goto err;
	}

	/* get the elapsed realtime from boot time to now */
	rc = ioctl(fd, ANDROID_ALARM_GET_TIME(
					  ANDROID_ALARM_ELAPSED_REALTIME_WAKEUP), &ts);
	if (rc < 0) {
		LOGE("Unable to get elapsed realtime\n");
		goto err;
	}

	/* calculate the elapsed time from boot time to reboot time */
	ts.tv_sec += secs;
	ts.tv_nsec = 0;

	rc = ioctl(fd, ANDROID_ALARM_SET(
					  ANDROID_ALARM_ELAPSED_REALTIME_WAKEUP), &ts);
	if (rc < 0) {
		LOGE("Unable to set reboot time to %ld\n", secs);
		goto err;
	}

	do {
		rc = ioctl(fd, ANDROID_ALARM_WAIT);
	} while ((rc < 0 && errno == EINTR) || !alarm_is_alm_expired());

	if (rc <= 0) {
		LOGE("Unable to wait on alarm\n");
		goto err;
	}

	close(fd);
	return 0;

err:
	if (fd >= 0)
		close(fd);
	return -1;
}

static void *alarm_thread(void *)
{
	time_t rtc_secs, rb_secs;
	int rc;

	/*
	 * to support power off alarm, the time
	 * stored in alarm register at latest
	 * shutdown time should be some time
	 * earlier than the actual alarm time
	 * set by user
	 */
	rc = alarm_get_time(ALARM_TIME, &alm_secs);
	if (rc < 0 || !alm_secs)
		goto err;

	rc = alarm_get_time(RTC_TIME, &rtc_secs);
	if (rc < 0)
		goto err;

	/*
	 * calculate the reboot time after which
	 * the phone will reboot
	 */
	rb_secs = alm_secs - rtc_secs;
	if (rb_secs <= 0)
		goto err;

	rc = alarm_set_reboot_time_and_wait(rb_secs);
	if (rc < 0)
		goto err;

	LOGI("Exit from power off charging, reboot the phone!\n");
	android_reboot(ANDROID_RB_RESTART2, 0, (char *)"rtc");

err:
	LOGE("Exit from alarm thread\n");
	return NULL;
}

static void power_off_alarm_init()
{
	pthread_t tid;
	int rc;
	char value[PROP_VALUE_MAX];

	property_get("ro.bootmode", value, "");
	if (!strcmp("charger", value)) {
		rc = pthread_create(&tid, NULL, alarm_thread, NULL);
		if (rc < 0)
			LOGE("Create alarm thread failed\n");
	}
}

void healthd_board_init(struct healthd_config*)
{
	// use defaults
	power_off_alarm_init();
}


int healthd_board_battery_update(struct android::BatteryProperties*)
{
	// return 0 to log periodic polled battery status to kernel log
	return 1;
}
