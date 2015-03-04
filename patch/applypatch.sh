#!/bin/sh
#
# applypatch.sh
# apply patches
#


dir=`cd $(dirname $0) && pwd`
top=$dir/../../../..

for patch in `ls $dir/*.patch` ; do
	echo " * Applying patch $patch"
	patch -p1 -N -i $patch -r - -d $top
done

