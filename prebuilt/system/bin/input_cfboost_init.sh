#!/system/bin/sh

# Copyright (c) 2013, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

# input_cfboost_init.sh -- initialize CPU boost parameters
#
# This script reads max cpu lp frequency and programs it as default
# boost frequency for input cfboost kernel module. In case max lp
# frequency can't be read using sysfs some sane value is set. Default
# boost time is set to 50ms.
#
# Defaults can be override by passing -f and -t options.
# cfboost: CPU Frequency Booster

READ_MAXLP_FREQ="/sys/devices/system/cpu/cpuquiet/tegra_cpuquiet/idle_top_freq"
WRITE_BOOST_FREQ="/sys/module/input_cfboost/parameters/boost_freq"
WRITE_BOOST_TIME="/sys/module/input_cfboost/parameters/boost_time"

# defaults
FREQ_KHZ=600000
TIME_MS=50

# try to read max cpu lp frequency from sysfs
if [ -f $READ_MAXLP_FREQ ];
then
    FREQ_KHZ=`cat $READ_MAXLP_FREQ`
fi

# scan override options
while getopts f:t: OPT; do
    case "$OPT" in
        f)
            FREQ_KHZ=$OPTARG
            ;;
        t)
            TIME_MS=$OPTARG
            ;;
    esac
done

if [ -f $WRITE_BOOST_FREQ ];
then
    echo $FREQ_KHZ > $WRITE_BOOST_FREQ
fi

if [ -f $WRITE_BOOST_TIME ];
then
    echo $TIME_MS > $WRITE_BOOST_TIME
fi
