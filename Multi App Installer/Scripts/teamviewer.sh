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

	echo "TeamViewer Host||http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg||TeamViewerHost.dmg||root||/Applications/TeamViewerHost.app|/Applications/TeamViewer.app"
fi

# Install
if [ "$1" == "-i" ]; then
	if [ ! -e "$2/TeamViewerHost.dmg" ]; then
		echo "TeamViewerHost is missing from sourceFolder: $2"
	else
		hdiutil mount -nobrowse -quiet $2/TeamViewerHost.dmg
		sudo installer -allowUntrusted -pkg "/Volumes/TeamViewerHost/Install TeamViewerHost.pkg" -target LocalSystem
		# Softkill process in order to unmount package
		ps aux | grep -i TeamViewer | awk {'print $2'} | xargs kill
		hdiutil unmount -quiet "/Volumes/TeamViewerHost"
		if [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist" ] || [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer.plist" ] || [ ! -e "$2/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist" ]; then
			echo "1 or more TeamViewer Settings files are missing from this folder: $2/TeamViewerSettings/"
		else
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist /Library/Preferences/
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer.plist /Library/LaunchAgents/
			cp $2/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist /Library/LaunchAgents/
            echo "Finished Copying Settings"
		fi
	fi
	exit 0
fi
