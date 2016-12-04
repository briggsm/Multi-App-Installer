#!/bin/sh

# Usage
# -d => Description
# -ad => Already Downloaded
# -ai => Already Installed
# -dl => Download
# -i => Install
function echoUsage {
	echo "!!!Usage: $0 [-d | -ad path/to/sourceFolder/ | -ai | -dl path/to/sourceFolder/ | -i path/to/sourceFolder/]"
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
# Note: format is: App Description||Download URL||Download Filename to save||Install as root or user||Proof App already exists
# Note: format is: (1)||(2)||(3)||(4)||(5)
#   All must be present, even if null!
# (1) - App Description (user-friendly name of the App)
# (2) - Download URL (where to download the app from)
# (3) - Download Filename to save as (just the filename, not the full path)
# (4) - Install as root or user (text is just "root" or "user" [w/o the quotes])
# (5) - Proof App already exists (full path. If this file exists, it's proof that the App is already installed)

# e.g.: echo "gimp||https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg||gimp.dmg||user||/Applications/GIMP.app"
# e.g.: echo "TeamViewer Host||http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg||root||/Applications/TeamViewer Host.app"

    echo "TeamViewer Host||http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg||root||/Applications/TeamViewerHost.app"
fi

if ([ "$1" == "-ad" ] || [ "$1" == "-dl" ] || [ "$1" == "-i" ]) && [ ! -d "$2" ]; then
	echo "Invalid directory passed as sourceFolder argument: $2"
	echoUsage
	exit 1
fi

# Description (will show up as the line-item in the GUI)
if [ "$1" == "-d" ]; then
	# Turkish
	if [ "$2" == "tr" ]; then
		echo "[tr]TeamViewer Host"
		exit 0
	fi
	
	# Russian
	if [ "$2" == "ru" ]; then
		echo "[ru]TeamViewer Host"
		exit 0
	fi
	
	# English
    echo "TeamViewer Host"
    exit 0
fi

# Already Downloaded?
if [ "$1" == "-ad" ]; then
    if [ -e "$2/TeamViewerHost.dmg" ]; then
		echo "true"
	else
		echo "false"
	fi
    exit 0
fi

# Already Installed?
if [ "$1" == "-ai" ]; then
	# if [ -e "/Applications/GIMP.app" ]; then
# 		echo "true"
# 	else
# 		echo "false"
# 	fi
# ??????????????????????????
	exit 0
fi

# # Download
# if [ "$1" == "-dl" ]; then
# 	#curl -L -O http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg #2&>1 /dev/null
# 	curl -L -o $2/TeamViewerHost.dmg http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg 2&>1 /dev/null
# 	exit 0
# fi

# Download Meta
if [ "$1" == "-dlMeta" ]; then
	# Note: format is: "URL||Filename to save"
	echo "http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg"
	exit 0
fi

# How to Install (user or root)
if [ "$1" == "-ihow" ]; then
	echo "root"
	exit 0
fi

# Install
if [ "$1" == "-i" ]; then
	# Note: this needs to be called by ROOT.
	
	if [ ! -e "$2/TeamViewerHost.dmg" ]; then
		echo "TeamViewerHost is missing from sourceFolder: $2"
	else
		hdiutil mount -nobrowse -quiet $2/TeamViewerHost.dmg
		sudo installer -allowUntrusted -pkg "/Volumes/TeamViewerHost/Install TeamViewerHost.pkg" -target LocalSystem
		# Softkill process in order to unmount package
		ps aux | grep -i TeamViewer | awk {'print $2'} | xargs kill
		hdiutil unmount -quiet "/Volumes/TeamViewerHost"
#		cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist /Library/Preferences/
# 		cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer.plist /Library/LaunchAgents/
# 		cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist /Library/LaunchAgents/
		if [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist" ] || [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer.plist" ] || [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist" ]; then
			echo "1 or more TeamViewer Settings files are missing from this folder: $2/TeamViewerSettings/"
		else
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist /Library/Preferences/
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer.plist /Library/LaunchAgents/
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist /Library/LaunchAgents/
		fi
		echo "Finished Copying Settings"
	fi
	exit 0
fi
