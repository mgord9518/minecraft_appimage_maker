#!/bin/bash

# VERSION 0.3.1
# Changes:
#  * Added the 'include' directory to be stripped out of the embedded OpenJRE
#  * Moved the code to get the current JRE download to under the code of changing directories into the TEMP_DIR. This is so out.log doesn't generate in the starting directory

# CONSTANTS
TMP_DIR="/tmp/.minecraft_appimage_maker_${RANDOM}"
START_DIR=${PWD}
MINECRAFT_LINK='https://launcher.mojang.com/download/Minecraft.tar.gz'
MINECRAFT_ICON='https://launcher.mojang.com/download/minecraft-launcher.svg'
APPIMAGETOOL_LINK='https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage'
OUTPUT_APPIMAGE='Minecraft.AppImage'

# Create and move to working directory
mkdir ${TMP_DIR} && cd ${TMP_DIR}
mkdir AppDir

# Get the link source using standard GNU commands, this needs to be done because the link doesn't stay the same with new versions
JRE_LINK=$(wget 'https://jdk.java.net/java-se-ri/8-MR3' -O - -o out.log | grep 'linux-x64' | cut -d '"' -f 2 | head -n 1) # This could possibly break in the future if they change the layout of the website
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to obtain the current release of OpenJRE 8 (this could be caused by a change in the website layout). Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# The desktop entry to be packed into the final AppImage
DESKTOPFILE='[Desktop Entry]
Type=Application
Version=1.0
Name=Minecraft Launcher
Comment=Official Minecraft Launcher (unofficial AppImage build)
Exec=AppRun
Icon=minecraft-launcher
Terminal=false
Categories=Game;Application;'

# AppRun script (needed to start the Minecraft Launcher)
APPRUN='#!/bin/bash
export PATH="${APPDIR}/OpenJRE/jre/bin/:${PATH}"
${APPDIR}/minecraft-launcher/minecraft-launcher'

# Colors
G="\e[0;92m"
R="\e[0;91m"
W="\e[0;97m"
# END CONSTANTS

echo -e "${G}STARTING MINECRAFT APPIMAGE BUILDER"
echo -e " > ${W}Working directory: ${PWD}"

# Download the latest Minecraft tarball
echo -e "${G} > ${W}Downloading latest Minecraft archive..."
wget ${MINECRAFT_LINK} -O Minecraft.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download Minecraft.tar.gz (make sure you're connected to the internet). Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# Download the latest JRE tarball
echo -e "${G} > ${W}Downloading latest OpenJRE archive..."
wget ${JRE_LINK} -O OpenJRE.tar.gz -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download OpenJRE.tar.gz. Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# Download the icon
echo -e "${G} > ${W}Downloading Minecraft icon..."
wget ${MINECRAFT_ICON} -O AppDir/minecraft-launcher.svg -o out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to download minecraft-launcher.svg (make sure you're connected to the internet). Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# Extract the tarballs
echo -e "${G} > ${W}Extracting files..."
tar -xzf Minecraft.tar.gz -C AppDir/
tar -xzf OpenJRE.tar.gz -C AppDir/

# Rename the extracted JRE to something more accessable
mv AppDir/*java* AppDir/OpenJRE

# Remove the source code, demos, man pages, JDK and header files from OpenJRE because we don't need them in the AppImage and would just take up space
echo -e "${G} > ${W}Removing unneccessary files from the JRE..."
rm -r AppDir/OpenJRE/src.zip \
      AppDir/OpenJRE/demo    \
      AppDir/OpenJRE/sample  \
      AppDir/OpenJRE/man     \
      AppDir/OpenJRE/bin     \
      AppDir/OpenJRE/lib     \
	  AppDir/OpenJRE/include

# Write our ${DESKTOPFILE} variable to the desktop entry
echo "${DESKTOPFILE}" > AppDir/minecraft-launcher.desktop
echo "${APPRUN}" > AppDir/AppRun

# Make both the desktop file and the AppRun script executable
chmod +x AppDir/minecraft-launcher.desktop \
         AppDir/AppRun

# Link up the icon to '.DirIcon', because it is neccessary in order to display the icon on the resulting AppImage (assuming that a thumbnailer daemon is running)
ln -s minecraft-launcher.svg AppDir/.DirIcon

# Check if user has AppImageTool in path (under the likely names of "appimagetool", "appimagetool.AppImage" and appimagetool-x86_64.AppImage) if not, download it
echo -e "${G} > ${W}Checking if AppImageTool is installed..."
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
		mv out.log ${START_DIR}/out.log
		exit 1
	fi
	chmod +x appimagetool.AppImage
	APPIMAGETOOL='./appimagetool.AppImage'
fi

# Use whichever AppImageTool we found to create the AppImage
echo -e "${G} > ${W}Building ${OUTPUT_APPIMAGE}..."
${APPIMAGETOOL} AppDir/ &> out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to build ${OUTPUT_APPIMAGE}. Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# Move the AppImage into the current directory
echo -e "${G} > ${W}Moving ${OUTPUT_APPIMAGE} to current directory..."
if [ -f ${START_DIR}/${OUTPUT_APPIMAGE} ]; then
	echo -e "${G} > ${W}File exists; overwriting..."
	rm ${START_DIR}/${OUTPUT_APPIMAGE}
fi
mv 'Minecraft_Launcher-x86_64.AppImage' ${START_DIR}/${OUTPUT_APPIMAGE} &> out.log
if [ ! ${?} = 0 ]; then
	echo -e "${R} > ERROR:${W} Failed to move ${OUTPUT_APPIMAGE} into the current directory. Check out.log"
	mv out.log ${START_DIR}/out.log
	exit 1
fi

# Remove all temporary files (including ones from previous runs that may have been cancelled)
echo -e "${G} > ${W}Cleaning up..."
rm -rf /tmp/.minecraft_appimage_maker_*

echo -e "${G}DONE! Enjoy playing!${W}"
