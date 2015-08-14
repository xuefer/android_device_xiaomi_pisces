#!/bin/sh
SYSDIR=$1
if [ "x$SYSDIR" = "x" ]; then
echo "You must specify system directory as first argument";
exit
fi
\
files=(
	audio/audio_effects.conf
	audio/audio_policy.conf
	audio/nvaudio_conf.xml
	audio/asound.conf
	media/media_profiles.xml
	media/enctune.conf
	media/media_codecs.xml
	gps/gpsconfig.xml
	gps/gps.conf
	gps/gpsconfigftm.xml
	libril/libril.so
	prebuilt-app/FM.apk
	prebuilt-app/NvCPLSvc.apk
	prebuilt-app/NvwfdService.apk
	prebuilt-app/NvwfdProtocolsPack.apk
	prebuilt-app/Cit.apk
)
# prebuilt-app/AMAPNetworkLocation.apk

for targetfile in "${files[@]}"; do
	name=$(basename $targetfile)
	found=$(ls $SYSDIR/{etc,etc/gps,bin,lib,app}/$name 2>/dev/null)
	if [[ -z $found ]] || [[ ! -e $found ]]; then
		echo "source for $targetfile not found"
		exit 2
	else
		diff -u $targetfile $found
	fi
done
