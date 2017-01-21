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
        desc="[tr]OSXFuse 3.5.4"
	elif [ "$1" == "-appMeta ru" ]; then
		desc="[ru]OSXFuse 3.5.4"
	else
		desc="OSXFuse 3.5.4"
    fi

	echo "$desc||https://github.com/osxfuse/osxfuse/releases/download/osxfuse-3.5.4/osxfuse-3.5.4.dmg||osxfuse.dmg||user||/Library/Frameworks/OSXFUSE.framework"
    exit 0
fi

# Install
if [[ "$1" == "-i"* ]]; then
    sourceFolder=${1:3} # Strip off first 3 characters from $1 (-i )
	if [ ! -e "$sourceFolder/osxfuse.dmg" ]; then
		echo "OSXFuse is missing from sourceFolder: $sourceFolder"
	else
		hdiutil mount -nobrowse -quiet $sourceFolder/osxfuse.dmg
		sudo installer -allowUntrusted -pkg "/Volumes/Fuse for macOS/Fuse for macOS.pkg" -target LocalSystem
		# Softkill process in order to unmount package
		hdiutil unmount -quiet "/Volumes/Fuse for macOS"
	fi
	exit 0
fi
