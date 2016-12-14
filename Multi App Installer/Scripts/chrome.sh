#!/bin/sh

# Usage
# -appMeta => All Meta Info for this App
# -i => Install

function echoUsage {
    echo "Usage: $0 [-appMeta [en|tr|ru] | -i path/to/sourceFolder/]"
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

    # Get Localized Description
	if [ "$2" == "tr" ]; then
        desc="[tr]Chrome"
	elif [ "$2" == "ru" ]; then
		desc="[ru]Chrome"
	else
		desc="Chrome"
    fi
    
	echo "$desc||https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg||user||/Applications/Google Chrome.app"
    exit 0
fi

# Install
if [ "$1" == "-i" ]; then
	if [ ! -e "$2/googlechrome.dmg" ]; then
		echo "Chrome is missing from sourceFolder: $2"
	else
		hdiutil mount -nobrowse -quiet $2/googlechrome.dmg
		cp -R "/Volumes/Google Chrome/Google Chrome.app" /Applications
		hdiutil unmount -quiet "/Volumes/Google Chrome"
		echo "Installed Chrome"
	fi
	exit 0
fi
