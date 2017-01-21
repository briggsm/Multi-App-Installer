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
        desc="[tr]VeraCrypt 1.19"
	elif [ "$1" == "-appMeta ru" ]; then
		desc="[ru]VeraCrypt 1.19"
	else
		desc="VeraCrypt 1.19"
    fi

	echo "$desc||https://launchpad.net/veracrypt/trunk/1.19/+download/VeraCrypt_1.19.dmg||veracrypt.dmg||user||/Applications/VeraCrypt.app"
    exit 0
fi

# Install
if [[ "$1" == "-i"* ]]; then
    sourceFolder=${1:3} # Strip off first 3 characters from $1 (-i )
	if [ ! -e "$sourceFolder/veracrypt.dmg" ]; then
		echo "VeraCrypt is missing from sourceFolder: $sourceFolder"
	else
		hdiutil mount -nobrowse -quiet $sourceFolder/veracrypt.dmg
		sudo installer -allowUntrusted -pkg "/Volumes/VeraCrypt for OSX/VeraCrypt_Installer.pkg" -target LocalSystem
		# Softkill process in order to unmount package
		hdiutil unmount -quiet "/Volumes/VeraCrypt for OSX"
	fi
	exit 0
fi
