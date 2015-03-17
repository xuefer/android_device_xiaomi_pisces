#!/system/bin/sh
exec >/upgrade_layout.log

export PATH=/system/bin:/system/xbin:$PATH
layoutFile=/data/.layout_version

oldVersion=0
if [ -e $layoutFile ]; then
	read -r oldVersion < $layoutFile
	echo $oldVersion
fi
version=$oldVersion

if [ $version -eq 0 ]; then
	echo -n "Upgrading /data/media for multi-user ... "
	if [ ! -e /data/media/0 ]; then
		mkdir /data/media/0
		chmod 770 /data/media/0
		chown 1023:1023 /data/media/0
		echo mv /data/media/.* /data/media/* /data/media/0/
		mv /data/media/.* /data/media/* /data/media/0/
	fi
	echo "Done"
	version=1
fi

if [ $version -ne $oldVersion ]; then
	echo -n "$version" > "$layoutFile"
	echo "Overwrote version id from $oldVersion to $version"
fi

echo Done
