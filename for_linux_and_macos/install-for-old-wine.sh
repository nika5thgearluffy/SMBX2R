#!/bin/bash

bak=$PWD

# Prints a line with text in middle
# Syntax:
#   printLine <string> <color of text in ANSI format> <color of line>
function printLine()
{
    lineLength=64
    Str=$1
    StrLen=${#Str}
    BeginAt=$(( ($lineLength/2) - ($StrLen/2) ))

    lineColor=$3
    textColor=$2

    if [[ "$lineColor" != "" ]]; then
    printf ${lineColor}; fi

    for((i=0; i < $lineLength; i++))
    do
        if (($i == $BeginAt))
        then
            if [[ "$textColor" != "" ]]; then
            printf ${textColor}; fi
        fi

        if (($i == $BeginAt + $StrLen))
        then
            if [[ "$lineColor" != "" ]]; then
            printf ${lineColor}; fi
        fi

        if (( $i >= $BeginAt && $i < $BeginAt + $StrLen ))
        then
            printf "${Str:$(($i-$BeginAt)):1}"
        else
            printf "="
        fi
    done
    printf "\E[0m"
    printf "\n"
}

function errorofbuild()
{
    printLine "AN ERROR OCCURRED!" "\E[0;41;37m" "\E[0;31m"
    cd ${bak}
    exit 1
}

function checkState()
{
    if [[ ! $? -eq 0 ]]
    then
        if [[ "$1" != "" ]]; then
            echo "ERROR: $1"
        fi
        errorofbuild
    fi
}

echo "== SMBX2 Configure for non-Windows platforms =="

SMBX2_HOME=$PWD/../data
DEP_DX_URL="https://download.codehaus.moe/deps/directx_Jun2010_redist.exe"

SED_CMD=sed

if [[ "$OSTYPE" == "msys"* ]]; then
    echo "Windows platform doesn't needs anything to done by this script. You can use it directly as is!"
    exit 1;
fi

echo "-- Checking Wine version"
wine --version
checkState "wine is not found! Wine is required for work of SMBX2 on a non-Windows platform."

#echo "-- Checking WineTricks version"
#winetricks --version
#checkState "winetricks is not found! WineTricks is required to install dependencies required for work of SMBX2."

echo "-- Checking wget version"
wget --version
checkState "wget is not found! wget is required to install dependencies required for work of SMBX2."




if [[ ! -d dist ]]; then
    mkdir dist
fi

echo "== Installing Wine-side dependencies"

# echo "-- Quartz"
# winetricks quartz
# checkState "Fail to install quartz by winetricks"


echo "-- Direct3D"
if [[ ! -f dist/setup-dx9june2010-x86.exe ]]; then
    wget "${DEP_DX_URL}" -O dist/setup-dx9june2010-x86.exe
    checkState "Fail to download DirectX"
fi
wine dist/setup-dx9june2010-x86.exe /Q "/T:C:\\windows\\temp\\dxjune2010"
checkState "Fail to install DirectX"


echo "-- Preparing the Linux environment..."
cd "${SMBX2_HOME}/PGE-Linux"
checkState

echo "-- Patching SMBX2 config pack..."
./download-devkit.sh --no-pause
checkState
cd ${bak}

printLine "DONE!" "\E[0;42;37m" "\E[0;32m"
echo -e " - To play a game, start \"wine SMBX2.exe\" in the root of SMBX2 folder,"
echo -e "   or alternatively, start \"wine LunaLoader.exe\" from the 'data' folder if launcher won't start."
echo -e " - To use Editor, start the \"./pge_editor\" application from the 'data/PGE-Linux' folder"

# Check for Arch-Linux based distros
if [[ -f /etc/arch-release ]]; then
    # Check is lib32-libxcomposite installed or not
    if ! command -v pacman &> /dev/null || ! pacman -Qi lib32-libxcomposite &> /dev/null; then
        printLine "!!IMPORTANT!!" "\E[0;41;37m" "\E[0;31m"
        echo -e " - When using any Arch-family Linux-based operating system, you should install"
        echo -e "   the following package to get the game to work:"
        echo -e ""
        echo -e "       lib32-libxcomposite"
        echo -e ""
        echo -e "   Otherwise, the game won't be able to render anything."
        printLine "" "\E[0;41;37m" "\E[0;31m"
    fi
fi
