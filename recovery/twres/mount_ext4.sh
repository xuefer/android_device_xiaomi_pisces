#!/system/bin/sh
export PATH=/system/bin:/system/xbin:$PATH
BLOCK_DEVICE=$1
MOUNT_POINT=$2

case "${MOUNT_POINT}" in
/storage_int)
	if [ ! -e $BLOCK_DEVICE ]; then
		mkdir /data/media
		chmod 770 /data/media
		chown media_rw media_rw /data/media
		mount -o bind /data/media "$MOUNT_POINT"
		return $?
	fi
;;
esac

"$0.orig" "$@"
