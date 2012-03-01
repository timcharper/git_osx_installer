#!/bin/bash

# Repeating this is redundant. It should only be in a place but
# I'm feeling lazy now. I'll fix it later

: << '*#'
Since using universal binaries generates a huge dmg I'm adding argument parsing
to the script. This way the arch and the git version can be set with arguments.

This are the allowed options
    -g: git version
    -a: architecture
    -o: OS X version to target. We use the X.Y format (10.5, 10.6 ...)
*#

# target git version to build
GIT_VERSION=
# target CPU architecture
ARCH=
# target OS X version
OS=

# : at te beginign avoids raising an error for illegar args
while getopts ":g:a:o:" OPT
do
    case $OPT in
        g)
            GIT_VERSION=$OPTARG
            ;;
        a)
            ARCH=$OPTARG
            ;;
	o)
	    OS=$OPTARG
	    ;;
    esac
done

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi

if [[ -z $GIT_VERSION ]]; then
    GIT_VERSION=`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`
    echo "Git version is missing. Using $GIT_VERSION as value"
fi

if [[ -z $ARCH ]]; then
    ARCH="`uname -p`"
    echo "Target architecture is missing. Using $ARCH as value."
fi

# Full path for the OS SDK directory
OSDKDIR="/Developer/SDKs/"
if [[ -z $OS ]]; then
    OS="`ls -w1 ${OSDKDIR} | head -n1 | sed $sed_regexp 's/MacOSX(10\.[0-9]).*/\1/'`"
    echo "Target OS X version is missing. Using $OS as value."
fi

OSDKDIR="`ls -d ${OSDKDIR}*${OS}*`"

# remove old installers
rm -f Disk\ Image/*.pkg

./build.sh -g $GIT_VERSION -a $ARCH -o $OS

PACKAGE_NAME="git-$GIT_VERSION-intel-$ARCH-OSX-$OS"
echo $PACKAGE_NAME | pbcopy

rm -f Disk\ Image/*.pkg
sudo bash -c "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o Disk\ Image/$PACKAGE_NAME.pkg --title 'Git $GIT_VERSION'"

UNCOMPRESSED_IMAGE_FILENAME="$PACKAGE_NAME.uncompressed.dmg"
IMAGE_FILENAME="$PACKAGE_NAME.dmg"

rm -f $UNCOMPRESSED_IMAGE_FILENAME $IMAGE_FILENAME
hdiutil create $UNCOMPRESSED_IMAGE_FILENAME -srcfolder "Disk Image" -volname "Git $GIT_VERSION OS X $OS Intel $ARCH" -ov
hdiutil convert -format UDZO -o $IMAGE_FILENAME $UNCOMPRESSED_IMAGE_FILENAME
rm $UNCOMPRESSED_IMAGE_FILENAME


while true; do
    echo "Test the DMG? [yes|no]"
    read ANS
    
    case $ANS in
        [Yy]|[Yy][Ee][Ss])
            echo "Testing the installer..."
            . test_installer.sh
	    break
            ;;
        [Nn]|[Nn][Oo])
            echo "Very confident, aren't you?"
	    break
            ;;
	*)
	    echo "Invalid answer. Please write yes or no."
	    ;;
   esac
done

echo "Git Installer $GIT_VERSION - OS X $OS - Intel $ARCH" | pbcopy

# What is this for? Google Code return a 404 for this
:<<'*#'
open "http://code.google.com/p/git-osx-installer/downloads/entry"
sleep 1
open "./"
*#
