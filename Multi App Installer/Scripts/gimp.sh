#!/bin/sh

# Usage
# -d => Description
# -ad => Already Downloaded
# -ai => Already Installed
# -dl => Download
# -i => Install
function echoUsage {
	echo "Usage: $0 [-d | -ad path/to/folder/ | -ai | -dl path/to/folder/ | -i path/to/folder/]"
}
if [ "$1" != "-d" ] && [ "$1" != "-ad" ] && [ "$1" != "-ai" ] && [ "$1" != "-dl" ] && [ "$1" != "-i" ]; then
    echoUsage
    exit 1
fi
# if [ "$1" == "-ad" ] && [ "$2" == "" ]; then
#     echoUsage
#     exit 1
# fi
if ([ "$1" == "-ad" ] || [ "$1" == "-dl" ] || [ "$1" == "-i" ]) && [ ! -d "$2" ]; then
	echo "Invalid directory passed as argument: $2"
	echoUsage
	exit 1
fi

# Description (will show up as the line-item in the GUI)
if [ "$1" == "-d" ]; then
    echo "Gimp"
    exit 0
fi

# Already Downloaded?
if [ "$1" == "-ad" ]; then
    if [ -e "$2/gimp.dmg" ]; then
		echo "true"
	else
		echo "false"
	fi
    exit 0
fi

# Already Installed?
if [ "$1" == "-ai" ]; then
	if [ -e "/Applications/GIMP.app" ]; then
		echo "true"
	else
		echo "false"
	fi
	exit 0
fi

# Download
if [ "$1" == "-dl" ]; then
	curl -L -o $2/gimp.dmg "https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg" 2&>1 /dev/null
	exit 0
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