#!/bin/bash
# VERSION 0.2

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
Comment=Official Minecraft Launcher (unofficial AppImage build)
Exec=AppRun
Icon=minecraft-launcher
Terminal=false
Categories=Game;Application;'

APPRUN='#!/bin/bash
export PATH="${APPDIR}/OpenJRE/jre/bin/:${PATH}"
${APPDIR}/minecraft-launcher/minecraft-launcher'

# Colors
G="\e[0;92m"
R="\e[0;91m"
W="\e[0;97m"

echo -e "${G}STARTING MINECRAFT APPIMAGE BUILDER"

# Create and move to working directory
mkdir ${TMP_DIR} && cd ${TMP_DIR}
mkdir AppDir
echo -e " > ${W}Working directory: ${PWD}"

# Download the latest Minecraft tarball
echo -e "${G} > ${W}Downloading latest Minecraft archive..."
wget ${MINECRAFT_LINK} -O Minecraft.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download Minecraft.tar.gz (make sure you're connected to the internet). Check out.log"
	exit 1
fi

# Download the latest JRE tarball
echo -e "${G} > ${W}Downloading latest OpenJRE archive..."

# Get the link source using standard GNU commands, this needs to be done because the link doesn't stay the same with new versions
JRE_LINK=$(wget 'https://jdk.java.net/java-se-ri/8-MR3' -O - -o out.log | grep 'linux-x64' | cut -d '"' -f 2 | head -n 1) # This could possibly break in the future if they change the layout of the website
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to obtain the current release of OpenJRE 8 (this could be caused by a change in the website layout). Check out.log"
	exit 1
fi

wget ${JRE_LINK} -O OpenJRE.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download OpenJRE.tar.gz. Check out.log"
	exit 1
fi

# Download the icon
echo -e "${G} > ${W}Downloading Minecraft icon..."
wget ${MINECRAFT_ICON} -O AppDir/minecraft-launcher.svg -o out.log

if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download minecraft-launcher.svg (make sure you're connected to the internet). Check out.log"
	exit 2
fi

# Extract the tarballs
echo -e "${G} > ${W}Extracting files..."
tar -xzf Minecraft.tar.gz -C AppDir/
tar -xzf OpenJRE.tar.gz -C AppDir/

# Rename the extracted JRE to something more accessable
mv AppDir/*java* AppDir/OpenJRE

echo -e "${G} > ${W}Removing unneccessary files from the JRE..."

# Remove the source code, demos, man pages, JDK and header files from OpenJRE because we don't need them in the AppImage
rm AppDir/OpenJRE/src.zip
rm -r AppDir/OpenJRE/demo
rm -r AppDir/OpenJRE/sample
rm -r AppDir/OpenJRE/man
rm -r AppDir/OpenJRE/bin
rm -r AppDir/OpenJRE/lib

# Write our ${DESKTOPFILE} variable to the desktop entry
echo "${DESKTOPFILE}" > AppDir/minecraft-launcher.desktop
echo "${APPRUN}" > AppDir/AppRun

# Make both the desktop file and the AppRun script executable
chmod +x AppDir/minecraft-launcher.desktop
chmod +x AppDir/AppRun

# Link up files
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
rm -rf /tmp/.minecraft_appimage_maker_*

echo -e "${G}DONE! Enjoy playing!${W}"
