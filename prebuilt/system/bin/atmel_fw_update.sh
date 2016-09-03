#!/system/bin/sh
result=`cat /sys/bus/i2c/devices/1-004a/update_fw`
case "$result" in
	"family_id=0x82, variant_id=0x2c, version=0x21, build=0x00, vendor=0x04")
	echo 1 > /sys/bus/i2c/devices/1-004a/update_fw_flag;;
	"family_id=0x82, variant_id=0x2c, version=0x30, build=0x0d, vendor=0x04")
	echo "Firmware 3.0";;
	esac
