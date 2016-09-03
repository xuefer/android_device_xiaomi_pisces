#!/system/bin/sh
am startservice -e com.nvidia.NvCPLSvc.NV_POWER_MODE $1 com.nvidia.NvCPLSvc/com.nvidia.NvCPLSvc.NvCPLService
