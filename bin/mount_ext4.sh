#!/system/bin/sh
export PATH=/system/bin:/system/xbin:$PATH
BLOCK_DEVICE=$1
MOUNT_POINT=$2
LOG_FILE="/dev/null"
LOG_LOCATION="/data/.fsck_log/"

if [ "${MOUNT_POINT}" == "/storage_int" ]; then
    mkdir ${LOG_LOCATION}
    busybox find /data/.fsck_log/ -type f -mtime +7  -exec rm {} \;
    TIMESTAMP=`date +%F_%H-%M-%S`
    LOG_FILE=${LOG_LOCATION}/storage_${TIMESTAMP}.log
fi

if [ -e ${BLOCK_DEVICE} ]; then
    if /system/bin/dumpe2fs -V &>/dev/null && ! /system/bin/dumpe2fs -h ${BLOCK_DEVICE} 2>&1 >${LOG_FILE}; then
        mke2fs -T ext4 -j -L ${MOUNT_POINT} ${BLOCK_DEVICE}
        ret2=$?
        echo "${PART_ALIAS} partition format ret = $ret2"
        if [ $ret2 -ne 0 ];then
            exit 1
        fi
    fi

    e2fsck -y ${BLOCK_DEVICE} 2>&1 >>${LOG_FILE}
    ret3=$?
    echo "e2fsck on ${BLOCK_DEVICE} ret = $ret3" 2>&1 >>${LOG_FILE}

    mount -t ext4 -o nosuid,nodev,barrier=1,noauto_da_alloc ${BLOCK_DEVICE} ${MOUNT_POINT}

    if [ -e ${MOUNT_POINT}/extend_size.userdata -o -e ${MOUNT_POINT}/extend_size.storage ]; then
        umount ${MOUNT_POINT}
        e2fsck -f -y ${BLOCK_DEVICE}
        ret4=$?
        echo "Forced e2fsck on ${BLOCK_DEVICE} ret = $ret4"
        if [ $ret4 -eq 4 ]; then
            e2fsck -y ${BLOCK_DEVICE}
        fi
        resize2fs -f ${BLOCK_DEVICE}
        ret5=$?
        echo "resize ${BLOCK_DEVICE} ret = $ret5"
        e2fsck -y ${BLOCK_DEVICE}
        ret6=$?
        echo "e2fsck on ${BLOCK_DEVICE} ret = $ret6"
        mount -t ext4 -o nosuid,nodev,barrier=1,noauto_da_alloc ${BLOCK_DEVICE} ${MOUNT_POINT}
        if [ $ret5 -eq 0 -o $ret5 -eq 2 ]; then
            rm ${MOUNT_POINT}/extend_size*
        fi
    fi
fi
