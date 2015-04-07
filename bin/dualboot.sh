#!/system/bin/sh
# vim:noet

    bootmark_file=/dev/block/platform/sdhci-tegra.3/by-name/misc
  bootmark_offset=4096
     partnum_boot=19
    partnum_boot1=20
   partnum_system=24
  partnum_system1=25

#
# helper functions
#

die() {
	echo "dualboot: Error: $@" >&2
	exit 1
}

#
# dual boot manager APIs
#

dualboot_write() {
	local which="$1"

	case "$which" in
	1|2)
		case "$which" in
		1) printf boot-system'\0\0';;
		2) printf boot-system1'\0';;
		esac | dd of="$bootmark_file" seek="$bootmark_offset" bs=1 count=13 2>/dev/null
		return $?
		;;
	*)
		return 1
		;;
	esac
}

dualboot_read() {
	if dd if="$bootmark_file" skip="$bootmark_offset" bs=1 count=13 2>/dev/null | grep -q boot-system1; then
		echo -n 2
	else
		echo -n 1
	fi
}

dualboot_hacknodes() {
	local which="$1"

	local minor_boot=
	local minor_system=
	case "$which" in
	1)
		minor_boot=$partnum_boot
		minor_system=$partnum_system
		;;
	2)
		minor_boot=$partnum_boot1
		minor_system=$partnum_system1
		;;
	*)
		return 1
	esac

	local devblks="
	/dev/block/mmcblk0p${partnum_boot}
	/dev/block/mmcblk0p${partnum_boot1}
	/dev/block/mmcblk0p${partnum_system}
	/dev/block/mmcblk0p${partnum_system1}
	"
	rm -f $devblks
	mknod /dev/block/mmcblk0p${partnum_boot}    b 179 "$minor_boot"   || die "Failed hacking boot node"
	mknod /dev/block/mmcblk0p${partnum_boot1}   b 179 "$minor_boot"   || die "Failed hacking boot1 node"
	mknod /dev/block/mmcblk0p${partnum_system}  b 179 "$minor_system" || die "Failed hacking system node"
	mknod /dev/block/mmcblk0p${partnum_system1} b 179 "$minor_system" || die "Failed hacking system1 node"
	chmod 600 $devblks
}

# helper function
installoverridefile() {
	local newfile="$1"
	local targetfile="$2"
	if [[ ! -e "$targetfile.orig" ]]; then
		mv "$targetfile" "$targetfile.orig"
	fi
	cp -a "$newfile" "$targetfile" || die "Can't copy file $newfile to $targetfile"
	chmod 755 "$targetfile"
	chown root:shell "$targetfile"
}

#
# commands
#

do_set() {
	dualboot_write "$1" || die "Usage: dualboot set <1|2>"
	dualboot_hacknodes "$1"
	exit
}

do_get() {
	case "`dualboot_read`" in
	1) echo "Active/next boot: System-1, using partition boot & system";;
	2) echo "Active/next boot: System-2, using partition boot1 & system1";;
	esac
}

recovery_umount() {
	umount /boot 2>&1 | grep -v "Invalid argument"
	umount /system 2>&1 | grep -v "Invalid argument"
}

recovery_save() {
	recovery_umount

	local which="`getprop dualboot.system`"
	dualboot_write "$which" || die "Failed saving dualboot setting"
	dualboot_hacknodes "$which"
}

recovery_load() {
	recovery_umount

	local which=`dualboot_read`
	setprop dualboot.system "$which" || die "Failed loading dualboot setting"
	dualboot_hacknodes "$which"
}

recovery_installpatch() {
	mount /system || die "Can't mount /system"
	installoverridefile /twres/mount_ext4.sh /system/bin/mount_ext4.sh || die "Can't install override file"
}

#
# main
#

# log to recovery
case "$1" in
-l)
	shift
	exec >>/tmp/recovery.log 2>&1
	echo "Executing $0 $@"
;;
esac

readprop() {
	local name=$1
	local value="`getprop "ro.$name"`"
	[[ -z $value ]] && die "Missing ro.$name"
	eval $name='"'"$value"'"'
}

command="$1"
shift
case "$command" in
set|get)
	do_$command "$@"
;;
save|load|installpatch)
	recovery_$command "$@"
;;
*)
	die "Unknown command $command, available command: get, set"
;;
esac
