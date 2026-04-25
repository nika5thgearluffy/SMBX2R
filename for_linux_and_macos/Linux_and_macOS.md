# Running SMBX2 on Linux and macOS
It's possible to run SMBX2 on Linux and macOS via Wine (or Proton)

If you already got this far, and am viewing this file after running the SMBX2
installer exe in Wine, you're probably good! In some cases, depending on your
desktop environment, you may even have a "SMBX2b5" shortcut in your application
launcher which should work. Otherwise, you can just run
```
wine SMBXLauncher.exe
```
from the `data` folder, and it will probably work.

# Troubleshooting and Questions

## "The game window just shows a black screen!"

If you experience this, and you're running **Arch Linux** or a derivative
distribution such as **Manjaro**, you probably need to install the
`lib32-libxcomposite` package.

This can be done with the command:
```
sudo pacman -S lib32-libxcomposite
```

## "What version of Wine is best?"

Most recent versions of Wine ought to work, but Wine 8.x is probably the best
tested major version of Wine for SMBX2 as of this writing.

Wine 8.12 and Proton 8.0-5 are two particular versions that have been tested
and are both known to work.

If you are having problems with the copy of Wine from your distribution, you
may wish to try installing the latest version of Wine from the the official
Wine project page:
https://wiki.winehq.org/Download

- Choose your distro in the list (for example, Debian or Ubuntu)
- Follow the guide on the page to add the Wine's repository to your system.
- Note: If you already Wine installed via your distribution's repositories,
  you should uninstall it first.
- Then install the updated copy of Wine as per the instructions in the guide.

Running via Proton 8.0 in Steam as a "non-Steam game" is also a viable
approach.

If you wish to use a much older version of Wine, there is a chance it may be
necessary to install some DirectX runtime files:
- https://download.codehaus.moe/deps/directx_Jun2010_redist.exe
but this is __not__ recommended. Please use a newer version of Wine if
possible. If it's really not possible, there's also a install-for-old-wine.sh
script here.

## "I copied my SMBX2 install from a Windows machine and it isn't working"

This is not recommended. It is recommended to run the installer under Wine.

The installer will include VB6 runtime files in the SMBX2 `data` folder, but
only if the system the installer is running on doesn't have a system copy of
the VB6 runtime. This allows SMBX2 to work seamlessly on systems (i.e. Wine)
missing this runtime, but means a copy-pasted install won't handle this
scenario.

If you insist on running an install copied from a Windows machine, it is
recommended that you install the VB6 runtime in your Wine prefix via
winetricks, but there is more that can go wrong with this approach.

## "I'm having trouble getting it to run on macOS!"

**NOTE:** Since macOS 10.15 (Catalina), it is likely not possible to run the
game because Apple removed support for 32-bit applications, and this includes
via Wine. It is possible there may be some workaround in the future, but
you may need to consider using a virtual machine or older version of macOS
(10.14 Mojave or older).

Please follow the instructions on:
https://wiki.winehw.org/MacOS
to install Wine.

If this seems insufficient, here are some other notes that may be helpful:

First, make sure you ahve Homebrew installed. If you don't yet, see here:
https://brew.sh/

Then, XQuartz may be required to support Wine properly:
```
brew install Caskroom/cask/xquartz
```
After XQuartz installation, it may be necessary to log out of your system and
log in again.

Then install Wine:
```
brew install wine
```

## "Is there a native Linux version of the editor?"

Yes, the editor does have Linux builds, but it is worth noting that they are
not as extensively tested usually.

If you want to try this, you can open the `data/PGE-Linux` directory in the
terminal and run the `./download-devkit.sh` script to download the prebuilt
version of the X2 Devkit.

This script requires having `wget`, `unzip` and `bzip2` installed in your
system.

Once script finishes, you can launch the `./pge_editor` executable to start the
editor, and you should be good.

## "What if I want to build the Linux version of the editor myself?"

If pre-built toolkit doesn't work for you, you can compile by yourself from
the source code here:
https://github.com/Emral/Moondust-Project-SMBX2
and instructions here
https://wohlsoft.ru/pgewiki/Building_Moondust_Project_from_sources

Note that using the `Emral/Moondust-Project-SMBX2` repoistory is **required**,
as it is a fork of the Moondust Devkit specifically for SMBX2.

AFter building it, copy all files from `bin-cmake-release/PGE_Project` into the
`data/PGE-Linux` directory. After which you can create a symbolic
link to the other `configs` directory:
```
ln -s ../PGE/configs configs
```

And then, you can run `./pge_editor` to start the editor.
