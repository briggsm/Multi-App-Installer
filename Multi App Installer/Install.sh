#!/bin/bash

# Created by Michael Merritt on 06/06/16.

# Security Settings
# check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Check to see if folders are there
if [ ! -d "/Volumes/PACTInstall/Apps/" ]; then
	echo "Apps folder missing!"
	echo "Please add the Apps Folder to the USB and run again."
	exit 1
fi

# Downloading Apps!
if [ ! -e "/Volumes/PACTInstall/Apps/downloadApps.sh" ]; then
	echo "Download Script Missing Skipping Downloads Install"
else
	cd /Volumes/PACTInstall/Apps
	bash downloadApps.sh
fi
# Install Apps!!!!!!!
if [ ! -e "/Volumes/PACTInstall/Apps/AppsInstall.sh" ]; then
	echo "Apps Script Missing Skipping App Install"
else
	cd /Volumes/PACTInstall/Apps
	bash AppsInstall.sh
fi

# Require password 5 seconds after sleep or screensaver is activated
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Configure screensaver to activate after 10 minutes of inactivity
defaults -currentHost write com.apple.screensaver idleTime 600

# Disable Remote Management
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop >/dev/null

defaults -currentHost write com.apple.bluetooth PrefKeyServicesEnabled 0

# Enable Automatic Check for Software Updates with Daily frequency
softwareupdate --schedule on >/dev/null
defaults write /Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Enable Automatic Download of Software Updates
# defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool yes
defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool TRUE
defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool TRUE

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array Guest ithelp
defaults write /Library/Preferences/com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool FALSE
/usr/bin/dscl . -mcxdelete /Users/Guest >/dev/null

# Installing the Startup Security Settings
[[ -d /Library/PACT ]] || mkdir /Library/PACT

#if [ ! -e "/Library/PACT/securitysettings.sh" ]; then
cp /Volumes/PACTInstall/Apps/securitysettings.sh /Library/PACT/
#fi
if [ -e "/Library/PACT/securitysettings.sh" ]; then
	echo "Security Script is Installed"
else
	echo "Security Script is Missing"
fi

# Installing WiTopia
if [ ! -e "/Applications/Witopia.app" ]; then
	cd /Volumes/PACTInstall/Apps
	open personalVPNPro.pkg
	echo "Finished, Please Install Witopia Manually personalVPNPro.pkg"
fi
if [ -e "/Applications/Witopia.app" ]; then
	echo "Witopia is already installed"
fi

serial="$(ioreg -l | grep IOPlatformSerialNumber | sed -e 's/.*\"\(.*\)\"/\1/')"
echo
echo "Here is the Serial Number"
echo
echo $serial
echo
exit

# End
