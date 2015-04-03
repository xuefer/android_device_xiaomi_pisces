/*
   Copyright (c) 2013, The Linux Foundation. All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "vendor_init.h"
#include "property_service.h"
#include "log.h"
#include "util.h"

#define POWERUP_REASON_PATH "/sys/bootinfo/powerup_reason"
#define RTC_WAKEALARM_PATH "/sys/class/rtc/rtc0/wakealarm"

static ssize_t read_string(char const *path, char *string, size_t size)
{
	int fd;
	ssize_t length;

	fd = open(path, O_RDONLY);
	if (fd < 0) {
		ERROR("Failed to open %s: %s", path, strerror(errno));
		return -errno;
	}

	length = read(fd, string, size);
	if (length < 0) {
		length = -errno;
		ERROR("Failed to reading %s: %s", path, strerror(errno));
	}

	close(fd);
	return length;
}

static int read_int(char const *path, int default_value)
{
	char buffer[80];
	char *end;
	ssize_t length;

	length = read_string(path, buffer, sizeof(buffer));
	if (length <= 0) {
		return default_value;
	}

	end = buffer + length;
	if (end[-1] == '\n') {
		--end;
	}

	return strtol(buffer, &end, 10);
}

static int write_int(char const *path, int value)
{
	int fd;

	fd = open(path, O_RDWR);
	if (fd < 0) {
		ERROR("write_int failed to open %s\n", path);
		return -errno;
	} else {
		char buffer[20];
		int bytes = sprintf(buffer, "%d\n", value);
		int ret = 0;

		if (write(fd, buffer, bytes) != bytes) {
			ret = -errno;
			ERROR("write_int failed to write %s: %s", path, strerror(errno));
		}

		close(fd);
		return ret;
	}
}

static void load_bootinfo()
{
	char powerup_reason[80];

	if (read_string(POWERUP_REASON_PATH, powerup_reason, sizeof(powerup_reason)) == 3 && memcmp(powerup_reason, "rtc", 3) == 0) {
		property_set("ro.alarm_boot", "true");
	} else if (read_int(RTC_WAKEALARM_PATH, 0) != 0) {
		property_set("ro.alarm_boot", "true");
		write_int(RTC_WAKEALARM_PATH, 0);
	}
}

void vendor_load_properties()
{
	load_bootinfo();
}
