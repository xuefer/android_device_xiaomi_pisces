#!/bin/sh
#
# applypatch.sh
# apply patches
#


localdir=$(cd "$(dirname "$0")" && pwd)
topdir=$(cd "$localdir/../../../.." && pwd)
(cd $localdir; find . -iname '*.patch' -type f) | while read relpatch; do
	dir="$topdir/$(dirname "$relpatch")/"
	patch="$localdir/$relpatch"
	if patch --dry-run -p1 -N -i "$patch" -r - -d "$dir" | grep -v 'Skipping patch\|hunks\? ignored\|patching file ' | grep . > /dev/null; then
		echo "[34m*** Applying patch $relpatch[0m"
		patch "$@" -p1 -N -i "$patch" -r - -d "$dir"
	else
		echo "[32m*** skipping already applied $relpatch[0m"
	fi
done

