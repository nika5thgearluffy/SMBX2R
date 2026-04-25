#!/bin/bash
PGE_WIN32ZIP="https://codehaus.moe/builds/ubuntu-18-04/pge_project-linux-master-64.tar.bz2"
# ================================================================================
#                         !!! IMPORTANT NOTE !!!
# Before release new SMBX build, make the replica of current in-repo config pack
# state, upload it into docs/_laboratory/config_packs/SMBX2 folder, store URL to
# it here, then, set SMBX2_IS_RELEASE with `true` value (without quotes)
# ================================================================================
PGE_SMBX20PACK="https://codehaus.moe/builds/SMBX2-Integration.zip"
SMBX2_IS_RELEASE=false
PGE_IS_COPY=false

echo "================================================"
echo "       Welcome to X2 Devkit update tool!"
echo "================================================"

if [[ -f update-pge.sh && "$1" != "--no-pause" ]]; then
    echo "    Please, close Editor, Engine, Maintainer,"
    echo "      and Calibrator until continue update"
    echo "================================================"
    echo "  To quit from this utility just hit the Ctrl+C"
    echo ""
    echo "Overwise, to begin update process, just"
    echo "press any key..."
    read -n 1
fi


echo ""
echo ""
echo "* (1/4) Downloading..."
echo ""

if [[ ! -d configs ]]; then
    ln -s ../PGE/configs configs
fi

if [[ ! -f update-pge.sh ]]; then
    ln -s download-devkit.sh update-pge.sh
fi

if [[ ! -d settings ]]; then
    mkdir settings
fi

echo "- Downloading update for X2 Devkit package..."
wget ${PGE_WIN32ZIP} -O "settings/pgezip.tar.bz2"
if [[ "$?" != "0" ]]; then
    echo "Failed to download ${PGE_WIN32ZIP}!"

    if [["$1" != "--no-pause" ]]; then
        echo "Press any key to quit..."
        read -n 1
    fi
    exit 1
fi

if $SMBX2_IS_RELEASE; then
    echo "- Downloading update for config pack..."
    wget ${PGE_SMBX20PACK} -O "settings/configpack.zip"
    if [[ "$?" != "0" ]]; then
        echo "Failed to download ${PGE_SMBX20PACK}!"

        if [["$1" != "--no-pause" ]]; then
            echo "Press any key to quit..."
            read -n 1
        fi
	    exit 1
    fi
fi

echo "* (2/4) Extracting..."
mkdir -p settings/PGE
tar -xvf "settings/pgezip.tar.bz2" -C settings/PGE > /dev/null
if $SMBX2_IS_RELEASE; then
    unzip -o settings/configpack.zip -d settings/PGE/PGE_Project/configs > /dev/null
fi

echo "* (3/4) Copying..."
find settings/PGE/PGE_Project/ -name "*.exe" -exec chmod 755 {} \;
cp -a settings/PGE/PGE_Project/* .
if [[ "$?" != "0" ]]; then
    echo "======= ERROR! ======="
    echo "Some files can't be updated! Seems you still have opened some PGE applications"
    echo "Please close all of them and retry update again!"
    echo "======================"

    echo "Press any key to quit..."
    read -n 1
    exit 1
fi

if [[ "${PGE_IS_COPY}" == "true" ]]; then
    if [[ -d configs/SMBX2-Integration ]]; then
        rm -Rf configs/SMBX2-Integration
    fi
    cp -a ../PGE/configs .
fi

echo "* (4/4) Clean-up..."
rm settings/pgezip.tar.bz2
if $SMBX2_IS_RELEASE; then
    rm settings/configpack.zip
fi
rm -Rf settings/PGE

# Nuke useless themes are was added as examples
if [[ -d "themes/Some Thing" ]]; then rm -Rf "themes/Some Thing"; fi
if [[ -d "themes/test" ]]; then rm -Rf "themes/test"; fi
if [[ -d "themes/pge_default" ]]; then rm -Rf "themes/pge_default"; fi
if [[ -f "themes/README.txt" ]]; then rm "themes/README.txt"; fi

if [[ -f "pge_engine" ]]; then
    rm "pge_engine";
    rm -f "languages/engine_"*".qm"
fi

if [[ -f "ipc/38a_ipc_bridge.exe" ]]; then
    rm "ipc/38a_ipc_bridge.exe";
fi

echo ""
echo "Everything has been completed! ===="

if [[ "$1" != "--no-pause" ]]; then
    echo "Press any key to quit..."
    read -n 1
fi

exit 0
