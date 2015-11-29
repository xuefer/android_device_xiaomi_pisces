#!/system/bin/sh
# vim:noet

    bootmark_file=/dev/block/platform/sdhci-tegra.3/by-name/misc
     datadev_file=/dev/block/platform/sdhci-tegra.3/by-name/userdata
   systemdev_file=/dev/block/platform/sdhci-tegra.3/by-name/system
  bootmark_offset=4096
     partnum_boot=19
    partnum_boot1=20
   partnum_system=24
  partnum_system1=25

#
# helper functions
#

lecho() {
	case "$language" in
	zh*) echo $3 "$2";;
	*) echo $3 "$1";;
	esac
}

ldie() {
	>&2 \
	lecho "dualboot: Error: $1" \
	      "dualboot: 错误: $2"
	exit 1
}

die() {
	ldie "$1" "$1"
}

is_mounted_mountpoint() {
	mount | grep -q " $1 "
}

mount_ex() {
	if mount "$@" 2>&1 | grep -v "Device or resource busy"; then
		return 1
	else
		return 0
	fi
}

umount_ex() {
	if umount "$@" 2>&1 | grep -v "Invalid argument"; then
		return 1
	else
		return 0
	fi
}

mv_q() {
	if mv "$@" 2>&1 | grep -v "Device or resource busy\\|Invalid argument"; then
		return 1
	else
		return 0
	fi
}

rename_directory() {
	local from="$1"
	local to="$2"
	if [[ -d $from ]] && [[ ! -d $to ]]; then
		mv -v "$from" "$to"
	fi
}

directory_exists() {
	local dir
	for dir in "$@"; do
		[[ -d $dir ]] && return 0
	done
	return 1
}

sync() {
	lecho "Syncing ... " "同步中 ... " -n
	toolbox sync &>/dev/null || toybox sync &>/dev/null || busybox sync
	lecho done "完成"
}

for cmd in \
	chmod \
	chown \
	dd \
	grep \
	mknod \
	printf \
;
do
	type "$cmd" &>/dev/null || alias $cmd="busybox $cmd"
done

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
	mknod /dev/block/mmcblk0p${partnum_boot}    b 179 "$minor_boot"   || ldie "Failed hacking boot node"     "hack boot    设备节点失败"
	mknod /dev/block/mmcblk0p${partnum_boot1}   b 179 "$minor_boot"   || ldie "Failed hacking boot1 node"    "hack boot1   设备节点失败"
	mknod /dev/block/mmcblk0p${partnum_system}  b 179 "$minor_system" || ldie "Failed hacking system node"   "hack system  设备节点失败"
	mknod /dev/block/mmcblk0p${partnum_system1} b 179 "$minor_system" || ldie "Failed hacking system1 node"  "hack system1 设备节点失败"
	chmod 600 $devblks
}

#
# dual boot manager APIs
#

dualdata_migrate_() {
	local from=$1
	local to=$2
	if [[ -d $from ]]; then
		lecho "Migrating legacy $from to $to" \
		      "正在升级旧的 $from 到 $to"

		if [[ -d "$to" ]]; then
			lecho "new data found, discarding legacy data" \
			      "已有对应新数据, 废弃旧数据"
			rm -rf "$from"
		else
			mv "$from" "$to" \
			|| lecho "failed" \
			         "失败"
		fi
	fi
}

dualdata_create_layout_version_() {
	local layout_version_file="$1"
	if [[ -e $layout_version_file ]]; then
		return
	fi

	# copy existing if found
	local path
	for path in $DATA/.layout_version "$SYSTEMS/system-1/.layout_version" "$SYSTEMS/system-2/.layout_version"; do
		if [[ -e $DATA/.layout_version ]]; then
			cp -a "$DATA/.layout_version" "$layout_version_file"
			return
		fi
	done

	touch "$layout_version_file"
	chmod 700 "$layout_version_file"
	chown root:root "$layout_version_file"
}

dualdata_open() {
	is_mounted_mountpoint /data \
	|| ldie "/data must be mounted" \
	        "必须先挂载 /data"

	DUALDATA_ENABLED=
	DATA=/dev/data
	SYSTEMS=$DATA/media

	mkdir -p $DATA
	mount_ex -o bind /data $DATA || die "Can't mount /data"
	if [[ ! -d $DATA/media ]]; then
		mkdir $DATA/media
		chmod 770 $DATA/media
		chown media_rw:media_rw $DATA/media
	fi

	# clean empty directory
	rmdir $DATA/media/system-[12] 2>/dev/null
	rmdir $DATA/system[01] 2>/dev/null

	local movingid
	# finish previous partial move
	for movingid in 1 2; do
		if [[ -d $SYSTEMS/system-$movingid.tmp ]]; then
			mv_q "$DATA/"* "$DATA/".* "$SYSTEMS/system-$movingid.tmp/"
			mv "$SYSTEMS/system-$movingid.tmp" "$SYSTEMS/system-$movingid"
			sync
		fi
	done

	dualdata_migrate_ "$DATA/system0" "$SYSTEMS/system-1"
	dualdata_migrate_ "$DATA/system1" "$SYSTEMS/system-2"

	if directory_exists "$SYSTEMS/system-1" "$SYSTEMS/system-2"; then
		DUALDATA_ENABLED=1
	fi
}

dualdata_close() {
	umount_ex "$DATA"
	unset DUALDATA_ENABLED=
	unset DATA
	unset SYSTEMS
}

dualdata_reopen() {
	dualdata_close
	dualdata_open
}

# $1 = hint about current system id
dualdata_enable() {
	local currentsysid=$1

	lecho "Enabling dual data ..." \
	      "正在启用双数据 ..."

	rename_directory "$SYSTEMS/system-1.disabled" "$SYSTEMS/system-1"
	rename_directory "$SYSTEMS/system-2.disabled" "$SYSTEMS/system-2"
	dualdata_reopen
	case "$DUALDATA_ENABLED" in
	1)
		# enabled, do nothing
		lecho "Dualdata enabled" \
		      "双数据已启用"
		;;
	*)
		# guessing current systemid
		if [[ -d $SYSTEMS/system-1 ]] && [[ ! -d $SYSTEMS/system-2 ]]; then
			currentsysid=2
		fi
		if [[ -d $SYSTEMS/system-2 ]] && [[ ! -d $SYSTEMS/system-1 ]]; then
			currentsysid=1
		fi

		if [[ -z $currentsysid ]]; then
			case "$(getprop ro.syspart)" in
			system1) currentsysid=2;;
			*) currentsysid=1;;
			esac
		fi

		lecho "Assuming current system is system-$currentsysid" \
		      "假设当前系统是 system-$currentsysid"

		local newsysid=
		case "$currentsysid" in
		1) newsysid=2;;
		2) newsysid=1;;
		esac

		lecho "Creating new data for system-$newsysid" \
		      "正在创建系统 system-$newsysid 的新数据"
		mkdir -p "$SYSTEMS/system-$newsysid"
		dualdata_create_layout_version_ "$SYSTEMS/system-$newsysid/.layout_version"
		;;
	esac
	lecho "Done" \
	      "完成"
}

dualdata_disable() {
	lecho "Disabling dual data ..." \
	      "正在禁用双数据 ..."
	rename_directory "$SYSTEMS/system-1" "$SYSTEMS/system-1.disabled"
	rename_directory "$SYSTEMS/system-2" "$SYSTEMS/system-2.disabled"
	lecho "Done" \
	      "完成"
	dualdata_reopen
}

dualdata_switchtodata() {
	if [[ -z $DUALDATA_ENABLED ]]; then
		lecho "Dualdata disabled, not switching data" \
		      "双数据已禁用, 不切换数据"
		return
	fi

	local unpacksysid="$1"
	local packsysid
	case "$unpacksysid" in
	1) packsysid=2;;
	2) packsysid=1;;
	*)
		ldie "Invalidate system id to switch" \
		     "要切换的系统 ID 无效"
		return
	;;
	esac

	lecho "Dual Data enabled, using data $unpacksysid" \
	      "双数据已启用, 正在启用数据 $unpacksysid"

	local packtodir="$SYSTEMS/system-$packsysid"
	if [[ ! -d $packtodir ]]; then
		lecho "Packing /data to seal location: /data/media/system-$packsysid" \
		      "正在将 /data 打包到封存位置: /data/media/system-$packsysid"
		mkdir -p "$packtodir.tmp"
		mv_q "$DATA/"* "$DATA/".* "$packtodir.tmp"
		mv "$packtodir.tmp" "$packtodir"
		sync
	fi

	local unpackfromdir="$SYSTEMS/system-$unpacksysid"
	if [[ -d $unpackfromdir ]] && [[ ! -d $unpackfromdir.tmp ]]; then
		lecho "Unpacking /data from seal location: /data/media/system-$unpacksysid" \
		      "正在从封存位置释放到 /data: /data/media/system-$unpacksysid"
		mv "$unpackfromdir" "$unpackfromdir.tmp"
	fi
	if [[ -d $unpackfromdir.tmp ]]; then
		mv_q "$unpackfromdir.tmp/"* "$unpackfromdir.tmp/".* "$DATA"/
		rmdir "$unpackfromdir.tmp"
		sync
	fi

	dualdata_create_layout_version_ "$DATA/.layout_version"
}

# helper function
installoverridefile() {
	local newfile="$1"
	local targetfile="$2"
	if [[ ! -e "$targetfile.orig" ]]; then
		mv "$targetfile" "$targetfile.orig"
	fi
	cp -a "$newfile" "$targetfile" \
	|| ldie "Can't copy file $newfile to $targetfile" \
	        "无法复制文件 $newfile 到 $targetfile"
	chmod 755 "$targetfile"
	chown root:shell "$targetfile"
}

#
# commands
#

do_set() {
	dualboot_write "$1" || ldie "Usage: dualboot set <1|2>" "用法: dualboot set <1|2>"
	dualboot_hacknodes "$1"

	mount_ex "$datadev_file" /data || die "Can't mount /data"
	dualdata_open
	dualdata_switchtodata "$1"
	dualdata_close
}

do_get() {
	case "`dualboot_read`" in
	1)
		lecho "Active/next boot: System-1, using partition boot & system" \
		      "当前/下次引导: 系统-1, 使用分区 boot & system"
	;;
	2)
		lecho "Active/next boot: System-2, using partition boot1 & system1" \
		      "当前/下次引导: 系统-2, 使用分区 boot1 & system1"
	;;
	esac

	dualdata_open

	case "$DUALDATA_ENABLED" in
	1)
		lecho "Dual data: enabled" \
		      "双数据: 已启用"
	;;
	*)
		lecho "Dual data: disabled" \
		      "双数据: 已禁用"
	;;
	esac

	lecho "Sealed data:" \
	      "封存数据:"
	local dir
	for dir in \
		$SYSTEMS/system-1* \
		$SYSTEMS/system-2* \
		; do
		if [[ -d $dir ]]; then
			echo " - $dir"
		fi
	done
	dualdata_close
}

recovery_umount() {
	umount_ex /boot
	umount_ex /system
}

recovery_save() {
	recovery_umount

	local which="`getprop dualboot.system`"
	dualboot_write "$which" || die "Failed saving dualboot setting"
	dualboot_hacknodes "$which"

	mount_ex "$datadev_file" /data || die "Can't mount /data"
	dualdata_open
	dualdata_switchtodata "$which"
	dualdata_close
}

recovery_load() {
	recovery_umount

	local which=`dualboot_read`
	setprop dualboot.system "$which" || die "Failed loading dualboot setting"
	dualboot_hacknodes "$which"

	mount_ex "$datadev_file" /data || die "Can't mount /data"
	dualdata_open
	setprop dualboot.dualdata "$DUALDATA_ENABLED"
	dualdata_switchtodata "$which"
	dualdata_close
}

recovery_installpatch() {
	mount_ex "$systemdev_file" /system || die "Can't mount /system"
	mount -o remount,rw /system
	installoverridefile /twres/mount_ext4.sh /system/bin/mount_ext4.sh || die "Can't install override file"
	sync
}

recovery_enabledualdata() {
	local which=$(getprop dualboot.system)

	mount_ex "$datadev_file" /data || die "Can't mount /data"
	dualdata_open
	dualdata_enable "$which"
	# recheck
	dualdata_reopen
	setprop dualboot.dualdata "$DUALDATA_ENABLED"
	dualdata_switchtodata "$which"
	dualdata_close
}

recovery_disabledualdata() {
	mount_ex "$datadev_file" /data || die "Can't mount /data"
	dualdata_open
	dualdata_disable
	# recheck
	dualdata_reopen
	setprop dualboot.dualdata "$DUALDATA_ENABLED"
	dualdata_close
}

#
# main
#

language=`getprop user.language`

# log to recovery
case "$1" in
-ll)
	shift
	exec >>/tmp/recovery.log 2>&1
	lecho "Executing $0 $@" \
	     "正在执行 $0 $@"
;;
-l)
	shift
	exec 2>&1
	lecho "Executing $0 $@" \
	      "正在执行 $0 $@"
;;
esac

readprop() {
	local name=$1
	local value="`getprop "ro.$name"`"
	[[ -z $value ]] \
	&& ldie "Missing ro.$name" \
	        "缺少 ro.$name"
	eval $name='"'"$value"'"'
}

command="$1"
shift
case "$command" in
set|get)
	do_$command "$@"
;;
save|load|installpatch|enabledualdata|disabledualdata)
	recovery_$command "$@"
;;
*)
	ldie "Unknown command $command. available command: get, set" \
	     "未知命令 $command. 有效命令: get, set"
;;
esac
