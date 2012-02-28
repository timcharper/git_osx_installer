#!/bin/bash

# remove old installers
rm -f Disk\ Image/*.pkg

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"

for ARCH in "i386" "x86_64"
do
    ./build.sh -g $GIT_VERSION -a $ARCH

    PACKAGE_NAME="git-$GIT_VERSION-intel-$ARCH-leopard"
    echo $PACKAGE_NAME | pbcopy

    rm -f Disk\ Image/*.pkg
    sudo bash -c "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o Disk\ Image/$PACKAGE_NAME.pkg --title 'Git $GIT_VERSION'"

    UNCOMPRESSED_IMAGE_FILENAME="$PACKAGE_NAME.uncompressed.dmg"
    IMAGE_FILENAME="$PACKAGE_NAME.dmg"

    rm -f $UNCOMPRESSED_IMAGE_FILENAME $IMAGE_FILENAME
    hdiutil create $UNCOMPRESSED_IMAGE_FILENAME -srcfolder "Disk Image" -volname "Git $GIT_VERSION Leopard Intel $ARCH" -ov
    hdiutil convert -format UDZO -o $IMAGE_FILENAME $UNCOMPRESSED_IMAGE_FILENAME
    rm $UNCOMPRESSED_IMAGE_FILENAME

    echo "Testing the installer..."

# Don't do this for the time being
#. test_installer.sh

    echo "Git Installer $GIT_VERSION - OS X - Leopard - Intel $ARCH" | pbcopy
done

# What is this for? Google Code return a 404 for this
:<<'*#'
open "http://code.google.com/p/git-osx-installer/downloads/entry"
sleep 1
open "./"
*#
