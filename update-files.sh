#!/bin/sh

SYSDIR=$1
if [ "x$SYSDIR" = "x" ]; then
echo "You must specify system directory as first argument";
exit
fi

base=prebuilt/system
(cd "$base" || exit $?; find -type f) | while read -r f; do
	if [[ -e $SYSDIR/$f ]]; then
		echo found $f
		cat "$SYSDIR/$f" > "$base/$f"
	else
		echo not found $f
		rm "$base/$f"
	fi
done

