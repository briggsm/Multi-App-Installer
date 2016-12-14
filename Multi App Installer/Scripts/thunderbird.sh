#!/bin/sh

# Usage
# -appMeta => All Meta Info for this App
# -i => Install

function echoUsage {
    echo "Usage: $0 [-appMeta [en|tr|ru] | -i path/to/sourceFolder/]"
}

if [[ "$1" != "-appMeta"* ]] && [[ "$1" != "-i"* ]]; then
    echoUsage
    exit 1
fi

if [[ "$1" == "-appMeta"* ]]; then
	# Note: format is: (1)||(2)||(3)||(4)||(5)
	#   All must be present, even if null!
	# (1) - App Description (user-friendly name of the App)
	# (2) - Download URL (where to download the app from)
	# (3) - Download Filename to save as (just the filename, not the full path)
	# (4) - Install as root or user (text is just "root" or "user" [w/o the quotes])
	# (5) - Proof Paths - Can be 1 path or multiple. If multiple paths, separate each by single pipe (|) - if ANY of the paths exist, it's proof app is already installed.

    # Get Localized Description & URL
	if [ "$1" == "-appMeta tr" ]; then
        desc="Thunderbird (Türkçe)"
		url="https://download.mozilla.org/?product=thunderbird-38.6.0&os=osx&lang=tr"
	elif [ "$1" == "-appMeta ru" ]; then
		desc="Thunderbird (Русский)"
		url="https://download.mozilla.org/?product=thunderbird-38.6.0&os=osx&lang=ru"
	else
		desc="Thunderbird (English)"
		url="https://download.mozilla.org/?product=thunderbird-38.6.0&os=osx&lang=en-US"
    fi

	echo "$desc||$url||thunderbird.dmg||user||/Applications/thunderbird.app"
    exit 0
fi

# Install
if [[ "$1" == "-i"* ]]; then
    sourceFolder=${1:3} # Strip off first 3 characters from $1 (-i )
	if [ ! -e "$sourceFolder/gimp.dmg" ]; then
		echo "Thunderbird is missing from sourceFolder: $sourceFolder"
	else
		hdiutil mount -nobrowse -quiet $sourceFolder/thunderbird.dmg
		cp -R "/Volumes/Thunderbird/Thunderbird.app" /Applications
		hdiutil unmount -quiet "/Volumes/Thunderbird"
		echo "Installed Thunderbird"
	fi
	exit 0
fi
