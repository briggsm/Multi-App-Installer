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

    # Get Localized Description
	if [ "$1" == "-appMeta tr" ]; then
        desc="[tr]Google Drive"
	elif [ "$1" == "-appMeta ru" ]; then
		desc="[ru]Google Drive"
	else
		desc="Google Drive"
    fi
    
	echo "$desc||https://dl-ssl.google.com/drive/installgoogledrive.dmg||installgoogledrive.dmg||user||/Applications/Google Drive.app"
    exit 0
fi

# Install
if [[ "$1" == "-i"* ]]; then
    sourceFolder=${1:3} # Strip off first 3 characters from $1 (-i )
	if [ ! -e "$sourceFolder/installgoogledrive.dmg" ]; then
		echo "Gimp is missing from sourceFolder: $sourceFolder"
	else
		hdiutil mount -nobrowse -quiet $sourceFolder/installgoogledrive.dmg
		cp -R "/Volumes/Install Google Drive/Google Drive.app" /Applications
		hdiutil unmount -quiet "/Volumes/Install Google Drive"
		echo "Installed Google Drive"
	fi
	exit 0
fi
