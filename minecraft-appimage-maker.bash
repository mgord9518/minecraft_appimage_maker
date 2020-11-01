#!/bin/bash
# VERSION 0.1

# Variables
TMP_DIR="/tmp/.minecraft_appimage_maker_${RANDOM}"
START_DIR=${PWD}
MINECRAFT_LINK='https://launcher.mojang.com/download/Minecraft.tar.gz'
MINECRAFT_ICON='https://launcher.mojang.com/download/minecraft-launcher.svg'
APPIMAGETOOL_LINK='https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage'

DESKTOPFILE='[Desktop Entry]
Type=Application
Version=1.0
Name=Minecraft Launcher
Comment=Official Minecraft Launcher
Exec=AppRun
Icon=minecraft-launcher
Terminal=false
Categories=Game;Application;'

# Colors
G="\e[0;92m"
R="\e[0;91m"
W="\e[0;97m"

clear
echo -e "${G}STARTING MINECRAFT APPIMAGE BUILDER"

# Create and move to working directory
mkdir ${TMP_DIR} && cd ${TMP_DIR}
mkdir AppDir
echo -e " > ${W}Working directory: ${PWD}"

# Download latest Minecraft tarball
echo -e "${G} > ${W}Downloading latest Minecraft archive..."
wget ${MINECRAFT_LINK} -O Minecraft.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download Minecraft.tar.gz. Check out.log"
	exit 1
fi

# Download the icon
echo -e "${G} > ${W}Downloading Minecraft icon..."
wget ${MINECRAFT_ICON} -O AppDir/minecraft-launcher.svg -o out.log

if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download minecraft-launcher.svg. Check out.log"
	exit 2
fi

# Extract the Minecraft tarball
echo -e "${G} > ${W}Extracting files..."
tar -xzf Minecraft.tar.gz -C AppDir/

# Write our ${DESKTOPFILE} variable to the desktop entry
echo -e "${G} > ${W}Creating desktop file..."
echo "${DESKTOPFILE}" > AppDir/minecraft-launcher.desktop
chmod +x AppDir/minecraft-launcher.desktop

# Link up files
echo -e "${G} > ${W}Making links..."
ln -s minecraft-launcher/minecraft-launcher AppDir/AppRun
ln -s minecraft-launcher.svg AppDir/.DirIcon

echo -e "${G} > ${W}Checking if AppImageTool is installed..."
# Check if user has AppImageTool in path (under the possible names of "appimagetool", "appimagetool.AppImage" and appimagetool-x86_64.AppImage) if not, download it
if hash appimagetool &> /dev/null; then
	APPIMAGETOOL='appimagetool'
elif hash appimagetool.AppImage &> /dev/null; then
	APPIMAGETOOL='appimagetool.AppImage'
elif hash appimagetool-x86_64.AppImage &> /dev/null; then
	APPIMAGETOOL='appimagetool-x86_64.AppImage'
else
	echo -e "${G} > ${W}Nope! (couldn't find it) Downloading it now..."
	wget ${APPIMAGETOOL_LINK} -O appimagetool.AppImage -o out.log
	if [ ! ${?} = 0 ]; then
		echo -e "${R} > ERROR:${W} Failed to download AppImageTool.AppImage. Check out.log"
		exit 3
	fi
	chmod +x appimagetool.AppImage
	APPIMAGETOOL='./appimagetool.AppImage'
fi

echo -e "${G} > ${W}Using ${APPIMAGETOOL}..."

echo -e "${G} > ${W}Building Minecraft.AppImage..."
${APPIMAGETOOL} AppDir/ &> out.log

if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to build Minecraft.AppImage. Check out.log"
	exit 4
fi

echo -e "${G} > ${W}Moving Minecraft.AppImage to current directory..."
if [ -f ${START_DIR}/Minecraft.AppImage ]; then
	echo -e "${G} > ${W}File exists; overwriting..."
	rm ${START_DIR}/Minecraft.AppImage
fi
mv 'Minecraft_Launcher-x86_64.AppImage' ${START_DIR}/Minecraft.AppImage

echo -e "${G} > ${W}Cleaning up..."
rm -r /tmp/.minecraft_appimage_maker_*

echo -e "${G}DONE! Enjoy playing!${W}"

