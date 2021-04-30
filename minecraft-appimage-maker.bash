#!/bin/bash

# Copyright (C) 2020-2021 Mathew R Gordon
#    <https://github.com/mgord9518>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# VERSION 0.5

# Variables
TMP_DIR="/tmp/.minecraft_appimage_maker_${RANDOM}"
START_DIR=${PWD}
MINECRAFT_LINK='https://launcher.mojang.com/download/Minecraft.tar.gz'
MINECRAFT_ICON='https://launcher.mojang.com/download/minecraft-launcher.svg'
APPIMAGETOOL_LINK='https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage'

# Define what should be in the desktop entry
DESKTOPFILE='[Desktop Entry]
Version=1.0
Type=Application
Name=Minecraft
Comment=Minecraft Launcher
Exec=minecraft-launcher
Icon=minecraft-launcher
Terminal=false
Categories=Game;Application;
X-AppImage-Name=Minecraft'

# Define what should be in the AppRun script
APPRUN='#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="$HERE/:PATH"
exec minecraft-launcher $@'

# Set color vars to their ANSI values
R="\e[0;91m"
W="\e[0;97m"

# Create and move to working directory
mkdir ${TMP_DIR} && cd ${TMP_DIR}
mkdir AppDir
echo -e "Working directory: ${PWD}"

# Download the latest Minecraft tarball
echo -e "Downloading Minecraft..."
wget ${MINECRAFT_LINK} -O Minecraft.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R}ERROR:${W} Failed to download Minecraft.tar.gz (make sure you're connected to the internet). Check out.log"
	exit 1
fi

# Download the Minecraft icon
wget ${MINECRAFT_ICON} -O AppDir/minecraft-launcher.svg -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R}ERROR:${W} Failed to download minecraft-launcher.svg (make sure you're connected to the internet). Check out.log"
	exit 2
fi

# Extract the tarball
echo -e "Extracting..."
tar -xzf Minecraft.tar.gz --strip-components=1 -C AppDir/

# Write our ${DESKTOPFILE} variable to the desktop entry
echo "${DESKTOPFILE}" > AppDir/minecraft-launcher.desktop
echo "${APPRUN}" > AppDir/AppRun

# Make both the desktop file and the AppRun script executable
chmod +x AppDir/minecraft-launcher.desktop
chmod +x AppDir/AppRun

# Link up the icon we have to .DirIcon (needed file to display the icon on the finished AppImage)
ln -s minecraft-launcher.svg AppDir/.DirIcon

echo -e "Checking if AppImageTool is installed..."
# Check if user has AppImageTool in path (under the possible names of "appimagetool", "appimagetool.AppImage" and appimagetool-x86_64.AppImage) if not, download it
if hash appimagetool &> /dev/null; then
	APPIMAGETOOL='appimagetool'
elif hash appimagetool.AppImage &> /dev/null; then
	APPIMAGETOOL='appimagetool.AppImage'
elif hash appimagetool-x86_64.AppImage &> /dev/null; then
	APPIMAGETOOL='appimagetool-x86_64.AppImage'
else
	echo -e "Nope! (couldn't find it) Downloading it now..."
	wget ${APPIMAGETOOL_LINK} -O appimagetool.AppImage -o out.log
	if [ ! ${?} = 0 ]; then
		echo -e "${R}ERROR:${W} Failed to download AppImageTool.AppImage (make sure you're connected to the internet). Check out.log"
		exit 3
	fi
	chmod +x appimagetool.AppImage
	APPIMAGETOOL='./appimagetool.AppImage'
fi

# Use the found AppImageTool to build our AppImage
echo -e "Building Minecraft.AppImage..."
ARCH=x86_64 ${APPIMAGETOOL} AppDir/ &> out.log

if [ ! ${?} = 0 ]; then
	echo -e "${R}ERROR:${W} Failed to build Minecraft.AppImage. Check out.log"
	exit 4
fi

# Take the newly created AppImage and move it into the starting directory
if [ -f ${START_DIR}/Minecraft-x86_64.AppImage ]; then
	echo -e "AppImage already exists; overwriting..."
	rm ${START_DIR}/Minecraft-x86_64.AppImage
fi
mv 'Minecraft-x86_64.AppImage' ${START_DIR}

# Remove all temporary files
echo -e "Cleaning up..."
rm -rf /tmp/.minecraft_appimage_maker_*

echo -e "DONE! Enjoy playing!${W}"
