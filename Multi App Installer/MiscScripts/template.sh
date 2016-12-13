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
	# TODO - !!!!!! should probably pass ISO 2-letter code for language (for description) !!!!!!!!1
	# Note: format is: (1)||(2)||(3)||(4)||(5)
	#   All must be present, even if null!
	# (1) - App Description (user-friendly name of the App)
	# (2) - Download URL (where to download the app from)
	# (3) - Download Filename to save as (just the filename, not the full path)
	# (4) - Install as root or user (text is just "root" or "user" [w/o the quotes])
	# (5) - Proof Paths - Can be 1 path or multiple. If multiple paths, separate each by single pipe (|) - if ANY of the paths exist, it's proof app is already installed.

	# If you want a localized description for the App Name, you can do something like this:
	# Get Localized Description
	if [ "$2" == "tr" ]; then
		desc="[tr]Gimp"
	elif [ "$2" == "ru" ]; then
		desc="[ru]Gimp"
	else
		desc="Gimp"
	fi
	# e.g.: echo "$desc||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"
	
	# If you want same App Name, no matter what language, just hard code it:
	# e.g.: echo "Gimp||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"
	# e.g.: echo "TeamViewer Host||http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg||root||/Applications/TeamViewer Host.app|/Applications/TeamViewer.app"

	echo "A.B.C. Cool App||http://example.com/download/abc.dmg||ABC.app||user||/Applications/ABC.app"
    exit 0
fi

# Install
if [ "$1" == "-i" ]; then
	if [ ! -e "$2/ABC.app" ]; then
		echo "ABC.app is missing from sourceFolder: $2"
	else
		hdiutil mount -nobrowse -quiet $2/abc.dmg
		cp -R "/Volumes/Abc 1.2.3/ABC.app" /Applications
		hdiutil unmount -quiet "/Volumes/Abc 1.2.3"
		echo "Installed Abc 1.2.3"
	fi
	exit 0
fi
