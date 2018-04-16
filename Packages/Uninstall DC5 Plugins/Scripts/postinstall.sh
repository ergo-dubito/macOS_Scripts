#!/bin/sh

#  Uninstall DC5 ID Plugin.sh
#
#
#  Created by Twana, Suleyman on 09/12/2013.
#  Edited by Walker, Phil on 28/02/2017.
#

dr="/Applications/Adobe InDesign CS5/Plug-Ins/Bauer/"

if [[ -d "$dr" ]]; then
echo "Folder Exists"
rm -r "$dr"
fi

scpt="/Applications/Adobe InDesign CS5/Scripts/startup scripts/markup_plugin_settings.jsx"

if [[ -f "$scpt" ]]; then
echo "Script Exists"
rm "$scpt"
fi

exit 0
