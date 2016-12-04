#!/bin/sh

# Usage
# -d => Description
# -ad => Already Downloaded
# -ai => Already Installed
# -dl => Download
# -i => Install
function echoUsage {
	echo "!!!Usage: $0 [-d | -ad path/to/folder/ | -ai | -dl path/to/folder/ | -i path/to/folder/]"
}
if [ "$1" != "-allMeta" ] && [ "$1" != "-d" ] && [ "$1" != "-ad" ] && [ "$1" != "-ai" ] && [ "$1" != "-dl" ] && [ "$1" != "-dlMeta" ] && [ "$1" != "-ihow" ] && [ "$1" != "-i" ]; then
    echoUsage
    exit 1
fi
# if [ "$1" == "-ad" ] && [ "$2" == "" ]; then
#     echoUsage
#     exit 1
# fi

if [ "$1" == "-allMeta" ]; then
# !!!!!! should probably pass ISO 2-letter code for language (for description) !!!!!!!!1

    # Note: format is: App Description||Download URL||Download Filename to save||Install as root or user||Proof App already exists
    # Note: format is: (1)||(2)||(3)||(4)||(5)
    #   All must be present, even if null!
    # (1) - App Description (user-friendly name of the App)
    # (2) - Download URL (where to download the app from)
    # (3) - Download Filename to save as (just the filename, not the full path)
    # (4) - Install as root or user (text is just "root" or "user" [w/o the quotes])
    # (5) - Proof App already exists Path (full path. If this file exists, it's proof that the App is already installed)

    # e.g.: echo "Gimp||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"
    # e.g.: echo "TeamViewer Host||http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg||root||/Applications/TeamViewer Host.app"

    echo "Gimp||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"

fi

if ([ "$1" == "-ad" ] || [ "$1" == "-dl" ] || [ "$1" == "-i" ]) && [ ! -d "$2" ]; then
	echo "Invalid directory passed as argument: $2"
	echoUsage
	exit 1
fi

# Description (will show up as the line-item in the GUI)
if [ "$1" == "-d" ]; then
	# Turkish
	if [ "$2" == "tr" ]; then
		echo "[tr]Gimp"
		exit 0
	fi
	
	# Russian
	if [ "$2" == "ru" ]; then
		echo "[ru]Gimp"
		exit 0
	fi
	
	# English
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

# # Download
# if [ "$1" == "-dl" ]; then
# 	curl -L -o $2/gimp.dmg "https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg" 2&>1 /dev/null
# 	exit 0
# fi

# Download Meta
if [ "$1" == "-dlMeta" ]; then
	# Note: format is: "URL||Filename to save"
	echo "https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg"
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
