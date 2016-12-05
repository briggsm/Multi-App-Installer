#!/bin/sh

# Usage
# -appMeta => All Meta Info for this App
# -i => Install

function echoUsage {
    echo "Usage: $0 [-appMeta | -i path/to/sourceFolder/]"
}

if [ "$1" != "-appMeta" ] && [ "$1" != "-i" ]; then
    echoUsage
    exit 1
fi

if [ "$1" == "-appMeta" ]; then
	# Note: format is: (1)||(2)||(3)||(4)||(5)
	#   All must be present, even if null!
	# (1) - App Description (user-friendly name of the App)
	# (2) - Download URL (where to download the app from)
	# (3) - Download Filename to save as (just the filename, not the full path)
	# (4) - Install as root or user (text is just "root" or "user" [w/o the quotes])
	# (5) - Proof Paths - Can be 1 path or multiple. If multiple paths, separate each by single pipe (|) - if ANY of the paths exist, it's proof app is already installed.

	echo "Gimp||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"
fi

# Install
if [ "$1" == "-i" ]; then
	if [ ! -e "$2/gimp.dmg" ]; then
		echo "Gimp is missing from sourceFolder: $2"
	else
		hdiutil mount -nobrowse -quiet $2/gimp.dmg
		cp -R "/Volumes/Gimp 2.8.16/GIMP.app" /Applications
		hdiutil unmount -quiet "/Volumes/Gimp 2.8.16"
		echo "Installed Gimp 2.8.16-1"
	fi
	exit 0
fi
