#!/bin/sh
#
# applypatch.sh
# apply patches
#

greprealpatching() {
	awk '
		BEGIN { patching = ""; }
		/^patching file/ {
			if (patching) {
				print $patching;
			}
			patching = $0;
			next;
		}
		/^Reversed/ {
			patching = "";
			next;
		}
		/ ignored$/ { next; }
		{
			print $0;
		}
		END {
			if (patching) {
				print $patching;
			}
		}
	'
}


localdir=$(cd "$(dirname "$0")" && pwd)
topdir=$(cd "$localdir/../../../.." && pwd)
(cd $localdir; find . -iname '*.patch' -type f) | while read relpatch; do
	dir="$topdir/$(dirname "$relpatch")/"
	patch="$localdir/$relpatch"
	if patch --dry-run -p1 -N -i "$patch" -r - -d "$dir" | greprealpatching | grep . > /dev/null; then
		echo "[34m*** Applying patch $relpatch[0m"
		patch "$@" -p1 -N -i "$patch" -r - -d "$dir"
	else
		echo "[32m*** skipping already applied $relpatch[0m"
	fi
done

