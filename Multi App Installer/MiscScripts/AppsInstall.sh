#!/bin/bash
# Created by Michael Merritt on 06/06/16.


# To run script "sudo ./AppInstall.sh"
# If needed to change to execite "chmod +x /path/to/yourscript.sh"
# Curl Notes "-o rename file to *.dmg | -O breaks rename {freaks out}, fine if file doesn't need renamed"
# Rename "mv oldname.dmg newname.dmg

# Installing VLC Player (Update with Latest Number!!!)
if [ -e "/Applications/vlc.app" ] || [ -e "/Applications/Google Chrome.app"] || [ -e "/Applications/Gimp.app" ] || [ -e "/Applications/Google Drive.app" ] || [ -e "/Applications/Thunderbird.app" ] || [ -e "/Applications/Malwarebytes Anti-Malware.app" ] || [ -e "/Applications/TrueCrypt.app" ] || [ -e "/Applications/TeamViewerHost.app" ] || [ -e "/Applications/Microsoft Word.app" ] || [ -e "/Applications/ClamXav.app" ]; then
	echo "All Apps Installed"
else
	if [ -e "/Applications/vlc.app" ]; then
		echo "VLC is already installed"
	else
		if [ ! -e "vlc.dmg" ]; then
			echo "VLC is missing"
		else
			hdiutil mount -nobrowse -quiet vlc.dmg
			cp -R "/Volumes/vlc-2.2.4/VLC.app" /Applications
			hdiutil unmount -quiet "/Volumes/vlc-2.2.4"
			echo "Installed VLC 2.2.4"
		fi
	fi
# Installing Gimp (Update with Latest Number!!!)
	if [ -e "/Applications/Gimp.app" ]; then
		echo "Gimp is already installed"
	else
		if [ ! -e "gimp.dmg" ]; then
			echo "Gimp is missing"
		else
			hdiutil mount -nobrowse -quiet gimp.dmg
			cp -R "/Volumes/Gimp 2.8.16/GIMP.app" /Applications
			hdiutil unmount -quiet "/Volumes/Gimp 2.8.16"
			echo "Installed Gimp 2.8.16-1"
		fi
	fi
# Installing Chrome
	if [ -e "/Applications/Google Chrome.app" ]; then
		echo "Google Chrome is already installed"
	else
		if [ ! -e "googlechrome.dmg" ]; then
			echo "Google Chrome is missing"
		else
			hdiutil mount -nobrowse -quiet googlechrome.dmg
			cp -R "/Volumes/Google Chrome/Google Chrome.app" /Applications
			hdiutil unmount -quiet "/Volumes/Google Chrome"
			echo "Installed Chrome"
		fi
	fi
# Installing Google Drive
	if [ -e "/Applications/Google Drive.app" ]; then
		echo "Google Drive is already Installed"
	else
		if [ ! -e "installgoogledrive.dmg" ]; then
			echo "Google Drive is missing"
		else
			hdiutil mount -nobrowse -quiet installgoogledrive.dmg
			cp -R "/Volumes/Install Google Drive/Google Drive.app" /Applications
			hdiutil unmount -quiet "/Volumes/Install Google Drive"
		fi
# Installing Google Chrome
		if [ -e "/Applications/Google Chrome.app" ]; then
			echo "Installed Google Drive"
		else
			echo "Google Drive Install Broke"
		fi
	fi
# Installing Thunderbird
	if [ -e "/Applications/Thunderbird.app" ]; then
		echo "Thunderbird is already installed"
	else
		if [ ! -e "thunderbird.dmg" ]; then
			echo "Thuderbird is missing"
		else
			hdiutil mount -nobrowse -quiet thunderbird.dmg
			cp -R "/Volumes/Thunderbird/Thunderbird.app" /Applications
			hdiutil unmount -quiet "/Volumes/Thunderbird"
			echo "Installed Thunderbird"
		fi
	fi
# Installing MalwareAntibytes
	if [ -e "/Applications/Malwarebytes Anti-Malware.app" ]; then
		echo "Malwarebytes Anti-Malware is already installed"
	else
		if [ ! -e "mbam.dmg" ]; then
			echo "Malwarebytes Anti-Malwareis missing"
		else
			hdiutil mount -nobrowse -quiet mbam.dmg
			cp -R "/Volumes/Malwarebytes Anti-Malware/Malwarebytes Anti-Malware.app" /Applications
			hdiutil unmount -quiet "/Volumes/Malwarebytes Anti-Malware"
			echo "Installed Malwarebytes Anti-Malware"
		fi
	fi
# Installing TrueCrypt
	if [ -e "/Applications/TrueCrypt.app" ]; then
		echo "TrueCrypt is already installed"
	else
		if [ ! -e "TrueCrypt 7.1a.mpkg" ]; then
			echo "TrueCrypt is missing"
		else
			sudo installer -allowUntrusted -pkg "TrueCrypt 7.1a.mpkg" -target LocalSystem
		fi
	fi
# Installing Teamviewer
	if [ -e "/Applications/TeamViewerHost.app" ]; then
		echo "TeamViewer is already installed"
	else
		if [ ! -e "TeamViewerHost.dmg" ]; then
			echo "TeamViewerHost is missing"
		else
			hdiutil mount -nobrowse -quiet TeamViewerHost.dmg
			sudo installer -allowUntrusted -pkg "/Volumes/TeamViewerHost/Install TeamViewerHost.pkg" -target LocalSystem
			# Softkill process in order to unmount package
			ps aux | grep -i TeamViewer | awk {'print $2'} | xargs kill
			hdiutil unmount -quiet "/Volumes/TeamViewerHost"
			cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer.preferences.plist /Library/Preferences/
			cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer.plist /Library/LaunchAgents/
			cp /Volumes/PACTInstall/Apps/TeamViewerSettings/com.teamviewer.teamviewer_desktop.plist /Library/LaunchAgents/
			echo "Finished Copying Settings"
		fi
	fi
# Installing Microsoft Office 2016
	if [ -e "/Applications/Microsoft Word.app" ]; then
		echo "Microsoft Office is Already Insalled"
	else
		sudo installer -allowUntrusted -pkg Microsoft_Office_2016_Installer.pkg -target /
		# Installing Office Updates
		cd /Volumes/PACTInstall/Apps/Office2016Updates
		if [ ! -e "word.pkg" ]; then
			echo "Word Update is missing"
		else
			sudo installer -allowUntrusted -pkg word.pkg -target /
		fi
		if [ ! -e "excel.pkg" ]; then
			echo "Excel Update is missing"
		else
			sudo installer -allowUntrusted -pkg excel.pkg -target /
		fi
		if [ ! -e "powerpoint.pkg" ]; then
			echo "PowerPoint Update is missing"
		else
			sudo installer -allowUntrusted -pkg powerpoint.pkg -target /
		fi
		if [ ! -e "outlook.pkg" ]; then
			echo "Outlook Update is missing"
		else
			sudo installer -allowUntrusted -pkg outlook.pkg -target /
		fi
		if [ ! -e "onenote.pkg" ]; then
			echo "Onenote Update is missing"
		else
			sudo installer -allowUntrusted -pkg onenote.pkg -target /
		fi
	fi
# Installing ClamXav
	if [ -e "/Applications/ClamXav.app" ]; then
		echo "ClamXav is Already Insalled"
	else
		cd /Volumes/PACTInstall/Apps/
		if [ ! -e "ClamXav2.7.5.dmg" ]; then
			echo "Find ClamXav Version 2.7.5 and Place in Apps Folder"
		else
			hdiutil mount -quiet ClamXav2.7.5.dmg
			cp -R "/Volumes/ClamXav/ClamXav.app" /Applications
			installer -pkg "/Applications/ClamXav.app/Contents/Resources/clamavEngineInstaller.pkg" -target /
			hdiutil unmount -quiet "/Volumes/ClamXav"
			# copy ClamXav virus definition files, download first if not present
			cd /Volumes/PACTInstall/Apps/ClamXavUpdates
			if [ ! -e "main.cvd" -o ! -e "daily.cvd" -o ! -e "bytecode.cvd" ]; then
				echo "1 or more ClamXav Updates are Missing"
			else
				cp /Volumes/PACTInstall/Apps/ClamXavUpdates/main.cvd /usr/local/ClamXav/share/clamav/main.cvd
				chown _clamav:_clamav /usr/local/ClamXav/share/clamav/main.cvd
				cp /Volumes/PACTInstall/Apps/ClamXavUpdates/daily.cvd /usr/local/ClamXav/share/clamav/daily.cvd
				chown _clamav:_clamav /usr/local/ClamXav/share/clamav/daily.cvd
				cp /Volumes/PACTInstall/Apps/ClamXavUpdates/bytecode.cvd /usr/local/ClamXav/share/clamav/bytecode.cvd
				chown _clamav:_clamav /usr/local/ClamXav/share/clamav/bytecode.cvd
			fi
			# configure ClamXav
			cp /Volumes/PACTInstall/Apps/ClamXavUpdates/uk.co.markallan.clamxav.plist /Library/Preferences/
			echo "Finished Copying Settings"
		fi
	#close ClamXav PACTInstall
	fi
# end all
fi