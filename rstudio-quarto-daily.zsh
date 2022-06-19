#!/bin/zsh

# - script: rstudio-quarto-daily.zsh
# - description: ZSH script to download and install the latest RStudio (electron) daily along with the latest Quarto relase
# - version: 0.5.0
# - author: @hrbrmstr

echo "Installing latest macOS RStudio (electron) and latest Quarto"
echo
echo "NOTE: You may be prompted at least once for your password for operations that require the use of 'sudo'"
echo 
echo "Checking for 'jq' binary…"

JQ_BIN=$(whence jq)

if [[ "" == "${JQ_BIN}" ]]; then
  echo "'jq' is required. Please install it and try again. Homebrew users can 'brew install jq'"
  exit
fi 

echo
echo "Checking if it's OK to install the Electron version of RStudio…"
echo

ARCH=$(arch)
if [[ "arm64" == "${ARCH}" ]]; then
  HAS_QMD_OPEN=$(grep -c -d recurse qmd ${HOME}/.local/share/rstudio | grep -c -v "0$")
  if [[ ${HAS_QMD_OPEN} -gt 0 ]]; then
    echo "OPEN QMD FILES DETECTED."
    echo 
    echo "RStudio Electron (on Apple Silicon) presently has issues with QMD files."
    echo 
    echo "Please see:"
    echo "  <https://github.com/hrbrmstr/rstudio-electron-quarto-installer/issues/2>"
    echo "on how to reset your RStudio desktop state."
    echo 
    echo "Then try using this utility again."
    exit 0
  fi
fi

echo "Beginning RStudio installation"

# Get metadata for the latest Electron for macOS
echo "  - Retrieving macOS RStudio (electron) daily metadata"
curl --silent https://dailies.rstudio.com/rstudio/spotted-wakerobin/index.json -o /tmp/index.json

# Get the DMG URL and name
DMG=$(cat /tmp/index.json | $JQ_BIN -r .electron.platforms.macos.link)
FIL=$(cat /tmp/index.json | $JQ_BIN -r .electron.platforms.macos.filename)
VER=$(cat /tmp/index.json | $JQ_BIN -r .electron.platforms.macos.version)

if [[ -f "${HOME}/Downloads/${FIL}" ]] ; then # Already have it
  echo "  - Found DMG in Downloads folder"
else # Get the latest DMG
  echo "  - Retrieving DMG"
  curl -# -o "${HOME}/Downloads/${FIL}" $DMG
fi

# Attach it and get the mount into
echo "  - Attaching DMG"
hdiutil attach -plist "${HOME}/Downloads/${FIL}" > /tmp/rs.plist

# Find the volume
if ($(plutil -extract "system-entities.1.mount-point" raw -expect string -o /dev/null /tmp/rs.plist > /dev/null 2>&1)); then
  VOL=$(plutil -extract "system-entities.1.mount-point" raw -expect string -o - /tmp/rs.plist)
fi

if ($(plutil -extract "system-entities.2.mount-point" raw -expect string -o /dev/null /tmp/rs.plist > /dev/null 2>&1)); then
  VOL=$(plutil -extract "system-entities.2.mount-point" raw -expect string -o - /tmp/rs.plist)
fi

if ($(plutil -extract "system-entities.3.mount-point" raw -expect string -o /dev/null /tmp/rs.plist > /dev/null 2>&1)); then
  VOL=$(plutil -extract "system-entities.3.mount-point" raw -expect string -o - /tmp/rs.plist)
fi

if ($(plutil -extract "system-entities.4.mount-point" raw -expect string -o /dev/null /tmp/rs.plist > /dev/null 2>&1)); then
  VOL=$(plutil -extract "system-entities.4.mount-point" raw -expect string -o - /tmp/rs.plist)
fi

diff "/Applications/RStudio.app/Contents/Info.plist" "${VOL}/RStudio.app/Contents/Info.plist" > /dev/null 2>&1
INSTALLED=$?

if [[ $INSTALLED -ne 0 ]]; then

  # Quit all running instances of RStudio
  echo "  - Quitting running instances of RStudio (if any)"
  ps -ef | grep -i "/Applications/RStudio.app/Contents/MacOS/RStudio" | grep -v grep | while read APP ; do osascript -e 'quit app "RStudio"' ; sleep 5 ; done

  # Move existing RStudio to the Trash
  if [[ -d "/Applications/RStudio.app" ]]; then
    echo "  - Moving existing RStudio install to the Trash"
    UUID=$(uuidgen)
    mv /Applications/RStudio.app ${HOME}/.Trash/RStudio-${UUID}.app
  fi

  cp -R "${VOL}/RStudio.app" /Applications

  # Remove quarantine flag (if present)
  echo "  - Installing RStudio.app (${VER})"
  sudo xattr -r -d com.apple.quarantine "/Applications/RStudio.app"

else 
  echo "  - Existing RStudio version is latest daily."
fi

# Unmount RStudio DMG
echo "  - Unmounting DMG"
hdiutil detach -quiet "${VOL}"

echo
echo "Beginning Quarto installation"

# Get latest Quarto metadata
echo "  - Retrieving macOS Quarto (latest) metadata"
curl --silent -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest -o /tmp/quarto.json

# Get Quarto URL and name
PKG=$(grep "http.*macos.pkg" /tmp/quarto.json | sed -e 's/^.*htt/htt/' -e 's/".*$//')
FIL=$(grep "name.*macos.pkg" /tmp/quarto.json | sed -e 's/^.*q/q/' -e 's/".*$//')

if [[ -f "${HOME}/Downloads/${FIL}" ]] ; then
  # Already have it
  echo "  - Found Quarto pkg in Downloads folder"
else
  # Get the latest PKG
  echo "  - Retrieving Quarto pkg"
  curl -# -o ${HOME}/Downloads/${FIL} $PKG
fi

INSTALL_QUARTO="true"
if [[ -f "/usr/local/bin/quarto" ]] ; then
  # Comapre versions
  PKG_VER=$(echo $(basename "${HOME}/Downloads/${FIL}") | sed -e 's/^quarto-//' -e 's/-mac.*$//')
  INST_VER=$(/usr/local/bin/quarto --version)
  if [[ "${PKG_VER}" == "${INST_VER}" ]]; then
    echo "  - Existing Quarto version is the latest."
    INSTALL_QUARTO="false"
  fi
fi

if [[ "${INSTALL_QUARTO}" == "true" ]]; then
  # Install it
  echo "  - Installing Quarto"
  sudo installer -pkg "${HOME}/Downloads/${FIL}" -target /
  echo "Quarto installation complete"
fi
