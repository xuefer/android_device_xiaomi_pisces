/*
 * Copyright (C) 2013 The CyanogenMod Project
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

import android.os.SystemProperties;

/* 
 * Vibrator intensity adjustment
 *
 * Exports methods to get the valid value boundaries, the
 * default and current intensities, and a method to set
 * the vibrator.
 *
 * Values exported by min/max can be the direct values required
 * by the hardware, or a local (to VibratorHW) abstraction that's
 * internally converted to something else prior to actual use. The
 * Settings user interface will normalize these into a 0-100 (percentage)
 * scale before showing them to the user, but all values passed to/from
 * the client (Settings) are in this class' scale.
 */

/* This would be just "Vibrator", but it conflicts with android.os.Vibrator */
public class VibratorHW {

    /* 
     * All HAF classes should export this boolean. 
     * Real implementations must, of course, return true 
     */

    public static boolean isSupported() { return true; }

    /*
     * Set the vibrator intensity to given integer input. That'll
     * be a value between the boundaries set by get(Max|Min)Intensity
     * (see below), and it's meant to be locally interpreted/used.
     */

    public static boolean setIntensity(int intensity)  {
        SystemProperties.set("persist.vibrator_intensity", Long.toString(intensity));
        return true;
    }

    /* 
     * What's the maximum integer value we take for setIntensity()?
     */

    public static int getMaxIntensity()  {
        return 10000;
    }

    /* 
     * What's the minimum integer value we take for setIntensity()?
     */

    public static int getMinIntensity()  {
        return 0;
    }

    /* 
     * Is there a value between the 2 above which is considered
     * the safe max? If not, return anything < 0
     */

    public static int getWarningThreshold()  {
        return -1;
    }

    /* 
     * What's the current intensity value?
     */

    public static int getCurIntensity()  {
        return SystemProperties.getInt("persist.vibrator_intensity", getDefaultIntensity());
    }

    /* 
     * What's the shipping intensity value?
     */

    public static int getDefaultIntensity()  {
        return 5000;
    }
}
