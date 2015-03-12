/*
 * Copyright (C) 2015 The CyanogenMod Project
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

package org.cyanogenmod.hardware;

import java.io.File;
import org.cyanogenmod.hardware.util.FileUtils;

/**
 * Glove mode / high touch sensitivity
 */
public class HighTouchSensitivity {

    private static String ENABLE_PATH = "/sys/bus/i2c/devices/1-004a/sensitive_mode";

    /**
     * Whether device supports high touch sensitivity.
     *
     * @return boolean Supported devices must return always true
     */
    public static boolean isSupported()
    {
        return (new File(ENABLE_PATH)).exists();
    }

    /**
     * This method return the current activation status of high touch sensitivity
     *
     * @return boolean Must be false if high touch sensitivity is not supported or not activated,
     * or the operation failed while reading the status; true in any other case.
     */
    public static boolean isEnabled()
    {
        return Integer.parseInt(FileUtils.readOneLine(ENABLE_PATH)) != 0;
    }

    /**
     * This method allows to setup high touch sensitivity status.
     *
     * @param status The new high touch sensitivity status
     * @return boolean Must be false if high touch sensitivity is not supported or the operation
     * failed; true in any other case.
     */
    public static boolean setEnabled(boolean status)
    {
        return FileUtils.writeLine(ENABLE_PATH, status ? "1" : "0");
    }

}
