#!/bin/zsh

# - script: rstudio-quarto-daily.zsh
# - description: ZSH script to download and install the latest RStudio (electron) daily along with the latest Quarto relase
# - version: 0.1.0
# - author: @hrbrmstr

echo "Installing latest macOS RStudio (electron) and latest Quarto"
echo "You will be prompted at least once for your password for operations that require the use of 'sudo'"
echo 
echo "Beginning RStudio installation"

# Get metadata for the latest Electron for macOS
echo "  - Retrieving macOS RStudio (electron) daily metadata"
curl --silent https://dailies.rstudio.com/rstudio/spotted-wakerobin/electron/macos/index.json -o /tmp/index.json

# Get the DMG URL and name
DMG=$(grep link /tmp/index.json | sed -e 's/^.*h/h/' -e 's/".*$//')
FIL=$(grep filename /tmp/index.json | sed -e 's/^.*R/R/' -e 's/".*$//')
VER=$(grep version /tmp/index.json | sed -e 's/^.*: "2/2/' -e 's/".*$//')

# Get the latest DMG
echo "  - Retrieving DMG"
curl --silent -o ~/Downloads/${FIL} $DMG

# Attach it and get the mount into
echo "  - Attaching DMG"
hdiutil attach -plist ~/Downloads/${FIL} > /tmp/rs.plist

# Find the volume
VOL=$(plutil -extract "system-entities.1.mount-point" raw -expect string -o - /tmp/rs.plist)

# Quit all running instances of RStudio
echo "  - Quitting running instances of RStudio (if any)"
ps -ef | grep "/Applications/RStudio.app/Contents/MacOS/RStudio" | grep -v grep | while read APP ; do osascript -e 'quit app "RStudio"' ; sleep 5 ; done

# Move existing RStudio to the Trash
if [[ -d "/Applications/RStudio.app" ]]; then
  echo "  - Moving existing RStudio install to the Trash"
  mv /Applications/RStudio.app ~/.Trash
fi

cp -R ${VOL}/RStudio.app /Applications

# Remove quarantine flag (if present)
echo "  - Installing RStudio.app (${VER})"
sudo xattr -r -d com.apple.quarantine /Applications/RStudio.app

# Unmount RStudio DMG
echo "  - Unmounting DMG"
hdiutil detach -quiet ${VOL}

echo "RStudio installation complete"
echo
echo "Beginning Quarto installation"

# Get latest Quarto metadata
echo "  - Retrieving macOS Quarto (latest) metadata"
curl --silent -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest -o /tmp/quarto.json

# Get Quarto URL and name
PKG=$(grep "http.*macos.pkg" /tmp/quarto.json | sed -e 's/^.*htt/htt/' -e 's/".*$//')
FIL=$(grep "name.*macos.pkg" /tmp/quarto.json | sed -e 's/^.*q/q/' -e 's/".*$//')

# Get the latest PKG
echo "  - Retrieving Quarto pkg"
curl --silent -L -o ~/Downloads/${FIL} $PKG

# Install it
echo "  - Installing Quarto"
sudo installer -pkg ~/Downloads/${FIL} -target /
echo "Quarto installation complete"
