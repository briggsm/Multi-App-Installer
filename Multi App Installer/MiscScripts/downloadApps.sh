#!/bin/bash

# To run script "sudo ./downloadApps.sh"
# If needed to change to execite "chmod +x /path/to/yourscript.sh"
# Curl Notes "-o rename file to *.dmg | -O breaks rename {freaks out}, for no rename"

if ! df | awk '{print $NF}' | grep -Ex "/Volumes/PACTInstall"; then
	echo "Insert and Rename USB stick to PACTInstall."
	else
	[[ -d /Volumes/PACTInstall/Apps ]] || mkdir /Volumes/PACTInstall/Apps

cd /Volumes/PACTInstall/Apps

if [ -e "googlechrome.dmg" ] || [ -e "installgoogledrive.dmg" ] || [ -e "thunderbird.dmg" ] || [ -e "TeamViewerHost.dmg" ] || [ -e "mbam.dmg" ] || [ -e "vlc.dmg" ] || [ -e "gimp.dmg" ] || [ -e "Microsoft_Office_2016_Installer.pkg.dmg" ] || [ -e "witopia.pkg" ] || [ -e "truecrypt7.1a.pkg" ] || [ -e "ClamXav7.2.5.dmg" ]; then
	echo "All Apps Present"
else

# Get Chrome
if [ ! -e "googlechrome.dmg" ]; then
echo "Downloading the latest verison of Chrome"
curl -L -O "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
else
echo "Google Chrome Already exists"
fi

# Get Google Drive
if [ ! -e "installgoogledrive.dmg" ]; then
echo "Downloading the latest verison of Google Drive"
curl --progress-bar -L -O "https://dl-ssl.google.com/drive/installgoogledrive.dmg"
else
echo "Google Drive Already exists"
fi

# Get Thunderbird
if [ ! -e "thunderbird.dmg" ]; then
echo "Downloading the latest verison of Thunderbird"
curl -L -o thunderbird.dmg "https://download.mozilla.org/?product=thunderbird-38.6.0&os=osx&lang=en-US"
else
echo "Thunderbird Already exists"
fi

# Get Teamviewer
if [ ! -e "TeamViewerHost.dmg" ]; then
echo "Downloading the latest verison of TeamViewer Host"
curl -L -O http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg
else
echo "TeamViewer Host Already exists"
fi

# Get MalwareAntibytes
if [ ! -e "mbam.dmg" ]; then
echo "Downloading MalwareAntibytes Mac 1.2.4.584"
#curl -L -o mbam.dmg "https://data-cdn.mbamupdates.com/web/MBAM-Mac-1.2.4.584.dmg"
curl -L -o mbam.dmg "https://store.malwarebytes.com/342/purl-mbamm-dl"
else
echo "Malwarebytes Already exists"
fi

# Get VLC Player (Update script with Latest Version Number!!!)
if [ ! -e "vlc.dmg" ]; then
echo "Downloading VLC 2.2.4"
curl -L -o vlc.dmg "http://get.videolan.org/vlc/2.2.4/macosx/vlc-2.2.4.dmg"
else
echo "VLC Already exists"
fi

# Get Gimp (Update with Latest Number!!!)
if [ ! -e "gimp.dmg" ]; then
echo "Downloading Gimp 2.8.16-x86_64-1"
curl -L -o gimp.dmg "https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg"
else
echo "Gimp Already exists"
fi

# Get Microsoft Office 2016
if [ ! -e "Microsoft_Office_2016_Installer.pkg.dmg" ]; then
echo "use the one provided or login to your Microsoft 365 account and download the installer"
else
echo "Microsoft Office 2016 Already exists"
fi

[[ -d /Volumes/PACTInstall/Apps/Office2016Updates ]] || mkdir /Volumes/PACTInstall/Apps/Office2016Updates

cd /Volumes/PACTInstall/Apps/Office2016Updates

#Microsoft Office Lastest Update page https://support.microsoft.com/en-us/kb/3165798
#Updates 15.23.0 Junes 14, 2016

if [ ! -e "word.pkg" ]; then
echo "Downloading Microsoft Office Updates 15.23.0 Junes 14, 2016"
curl -L -o word.pkg "http://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_Word_15.23.0_160611_Updater.pkg"
else
echo "Word Update Already exists"
fi

if [ ! -e "excel.pkg" ]; then
curl -L -o excel.pkg "http://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_Excel_15.23.0_160611_Updater.pkg"
else
echo "Excel Update Already exists"
fi

if [ ! -e "powerpoint.pkg" ]; then
curl -L -o powerpoint.pkg "http://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_PowerPoint_15.23.0_160611_Updater.pkg"
else
echo "PowerPoint Update Already exists"
fi

if [ ! -e "outlook.pkg" ]; then
curl -L -o outlook.pkg "http://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_Outlook_15.23.0_160611_Updater.pkg"
else
echo "Outlook Update Already exists"
fi

if [ ! -e "onenote.pkg" ]; then
curl -L -o onenote.pkg "http://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_OneNote_15.23.0_160611_Updater.pkg"
else
echo "OneNote Update Already exists"
fi

# Get TrueCrypt
if [ ! -e "truecrypt7.1a.pkg" ]; then
echo "TrueCrypt: need to use the one provided"
else
echo "TrueCrypt Already exists"
fi

# Get WiTopia
if [ ! -e "witopia.pkg" ]; then
echo "Witopia: need to use the one provided"
else
echo "Witopia Already exists"
fi

# Get ClamXav
if [ ! -e "ClamXav7.2.5.dmg" ]; then
echo "ClamXav: need to use the one provided"
else
echo "ClamXav Already exists"
fi

[[ -d /Volumes/PACTInstall/Apps/ClamXavUpdates ]] || mkdir /Volumes/PACTInstall/Apps/ClamXavUpdates
cd /Volumes/PACTInstall/Apps/ClamXavUpdates

# Get ClamXav Definitions
if [ ! -e "main.cvd" ]; then
echo "Downloading latest main.cvd"
curl -O http://database.clamav.net/main.cvd
echo "You now have the latest main.cvd"
else
echo "main.cvd Already exists"
fi

if [ ! -e "daily.cvd" ]; then
echo "Downloading latest daily.cvd"
curl -O http://database.clamav.net/daily.cvd
echo "You now have the latest daily.cvd"
else
echo "daily.cvd Already exists"
fi

if [ ! -e "bytecode.cvd" ]; then
echo "Downloading latest bytecode.cvd"
curl -O http://database.clamav.net/bytecode.cvd
echo "You now have the latest bytecode.cvd"
else
echo "bytecode.cvd Already exists"
fi

cd /Volumes/PACTInstall/

# end
echo "Downloads have Finished"
fi

fi