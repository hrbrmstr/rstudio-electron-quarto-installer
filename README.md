# rstudio-electron-quarto-installer

Download and install the latest macOS RStudio (electron) daily along with the latest Quarto.

Why?

The electron build of RStudio does not require Rosetta and is coming along nicely. 

Also, the RStudio dev team is making tons of progress with each build so I download it frequently. 

Quarto and RStudio are joined at the hip and one often has to update a local Quarto install immediately after installing the latest RStudio daily.

## Installation

- Download the script
- Move it to a place on your `$PATH`
- Ensure it is executable (i.e. `chmod 755 /path/tp/rstudio-quarto-daily.zsh`)

## NOTE

There is (for now) minimal error condition checking and the script itself is somewhat rude and wasteful in that:

- it doesn't check if any local Quarto and RStudio installs are at the latest already
- it doesn't use any existing files in `~/Downloads` if they exist (so bandwidth is potentially wasted)
- it quits running RStudio instances without asking
- it expects you to delete RStudio.app from the Trash before running the script again
- it can clobber stuff in `/tmp` if similarly named files already exist

I may make it less brutish, but it does what I need it to do in current form.

## Usage

```bash
$ rstudio-quarto-daily.zsh
Installing latest macOS RStudio (electron) and latest Quarto
You will be prompted at least once for your password for operations that require the use of 'sudo'

Beginning RStudio installation
  - Retrieving macOS RStudio (electron) daily metadata
  - Retrieving DMG
  - Attaching DMG
  - Quitting running instances of RStudio (if any)
  - Moving existing RStudio install to the Trash
  - Installing RStudio.app (2022.06.0-daily+208)
  - Unmounting DMG
RStudio installation complete


Beginning Quarto installation
  - Retrieving macOS Quarto (latest) metadata
  - Retrieving Quarto pkg
  - Installing Quarto
installer: Package name is Quarto
installer: Upgrading at base path /
installer: The upgrade was successful.
Quarto installation complete
```