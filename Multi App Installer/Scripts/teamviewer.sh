#!/bin/sh

# Usage
# -d => Description
# -ad => Already Downloaded
# -ai => Already Installed
# -dl => Download
# -i => Install
function echoUsage {
	echo "Usage: $0 [-d | -ad path/to/sourceFolder/ | -ai | -dl path/to/sourceFolder/ | -i path/to/sourceFolder/]"
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
	echo "Invalid directory passed as sourceFolder argument: $2"
	echoUsage
	exit 1
fi

# Description (will show up as the line-item in the GUI)
if [ "$1" == "-d" ]; then
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

# Download
if [ "$1" == "-dl" ]; then
	#curl -L -O http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg #2&>1 /dev/null
	curl -L -o $2/TeamViewerHost.dmg http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg 2&>1 /dev/null
	exit 0
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