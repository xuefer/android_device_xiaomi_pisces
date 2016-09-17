#!/bin/bash
base=$1
deviceDir=$(dirname "$(readlink -f "$0")")
androidRoot=$(dirname "$(readlink -f "$deviceDir/../../")")
patchDir=$deviceDir/patch
cd "$androidRoot"
find "$patchDir" -iname '*.patch' | xargs rm -f
(cd "$patchDir" && find * -type d) | while read patchedDir; do
	pushd "$patchedDir" || continue
	if [[ -d .git ]]; then
		git format-patch "$1" --signature=""
		mv *.patch "$patchDir/$patchedDir/"
	fi
	popd
done
