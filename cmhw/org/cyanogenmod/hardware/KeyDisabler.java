/*
 * Copyright (C) 2014 The CyanogenMod Project
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

package org.cyanogenmod.hardware;

import java.io.File;
import org.cyanogenmod.hardware.util.FileUtils;

/**
 * Disable capacitive keys
 *
 * This is intended for use on devices in which the capacitive keys
 * can be fully disabled for replacement with a soft navbar. You
 * really should not be using this on a device with mechanical or
 * otherwise visible-when-inactive keys
 *
 */

public class KeyDisabler {
    private static final String ATMEL_PATH = "/sys/bus/i2c/drivers/atmel_mxt_ts/1-004a";
    private static final String KEYS_OFF_PATH = "/sys/bus/i2c/drivers/atmel_mxt_ts/1-004a/keys_off";

    private static boolean hasTouchScreen()
    {
        return (new File(ATMEL_PATH)).exists();
    }

    /*
     * All HAF classes should export this boolean.
     * Real implementations must, of course, return true
     */

    public static boolean isSupported()
    {
        return !hasTouchScreen() || (new File(KEYS_OFF_PATH)).exists();
    }

    /*
     * Are the keys currently blocked?
     */

    public static boolean isActive() {
        return !hasTouchScreen() || FileUtils.readOneLine(KEYS_OFF_PATH).equals("1");
    }

    /*
     * Disable capacitive keys
     */

    public static boolean setActive(boolean state) {
        if (hasTouchScreen()) {
            return FileUtils.writeLine(KEYS_OFF_PATH, (state ? "1" : "0"));
        } else {
            return state ? true : false;
        }
    }
}
