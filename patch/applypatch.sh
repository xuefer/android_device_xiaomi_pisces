#!/bin/sh
#
# applypatch.sh
# apply patches
#


localdir=$(cd "$(dirname "$0")" && pwd)
topdir=$(cd "$localdir/../../../.." && pwd)

(cd $localdir; find . -iname '*.patch' -type f) | while read patch; do
	echo " *** Applying patch $patch"
	patch -p1 -N -i "$localdir/$patch" -r - -d "$topdir/$(dirname "$patch")/"
done

