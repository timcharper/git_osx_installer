#!/bin/bash

for ARCH in i386 x86_64; do
  # remove old installers
  rm -f Disk\ Image/*.pkg

  GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"

  ARCH=$ARCH ./build.sh $GIT_VERSION

  PACKAGE_NAME="git-$GIT_VERSION-$ARCH-snow-leopard"
  echo $PACKAGE_NAME | pbcopy

  echo "Git version is $GIT_VERSION"

  rm -f Disk\ Image/*.pkg
  sudo bash -c "/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o Disk\ Image/$PACKAGE_NAME.pkg --title 'Git $GIT_VERSION $ARCH'"

  UNCOMPRESSED_IMAGE_FILENAME="$PACKAGE_NAME.uncompressed.dmg"
  IMAGE_FILENAME="$PACKAGE_NAME.dmg" 
  rm -f $UNCOMPRESSED_IMAGE_FILENAME $IMAGE_FILENAME
  hdiutil create $UNCOMPRESSED_IMAGE_FILENAME -srcfolder "Disk Image" -volname "Git $GIT_VERSION $ARCH Snow Leopard" -ov
  hdiutil convert -format UDZO -o $IMAGE_FILENAME $UNCOMPRESSED_IMAGE_FILENAME
  rm $UNCOMPRESSED_IMAGE_FILENAME
done

echo "Testing the $ARCH installer..."

. test_installer.sh

echo "Git Installer $GIT_VERSION - OS X - Snow Leopard - $ARCH" | pbcopy
open "http://code.google.com/p/git-osx-installer/downloads/entry"
sleep 1
open "./"
