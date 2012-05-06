#!/bin/bash

. env.sh

# remove old installers
rm -f Disk\ Image/*.pkg

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"

./build.sh $GIT_VERSION

PACKAGE_NAME="git-$GIT_VERSION-intel-universal-snow-leopard"
echo $PACKAGE_NAME | pbcopy

rm -f Disk\ Image/*.pkg
sudo bash -c "$PACKAGE_MAKER_APP/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o Disk\ Image/$PACKAGE_NAME.pkg --title 'Git $GIT_VERSION'"

UNCOMPRESSED_IMAGE_FILENAME="$PACKAGE_NAME.uncompressed.dmg"
IMAGE_FILENAME="$PACKAGE_NAME.dmg"

rm -f $UNCOMPRESSED_IMAGE_FILENAME $IMAGE_FILENAME
hdiutil create $UNCOMPRESSED_IMAGE_FILENAME -srcfolder "Disk Image" -volname "Git $GIT_VERSION Snow Leopard Intel Universal" -ov
hdiutil convert -format UDZO -o $IMAGE_FILENAME $UNCOMPRESSED_IMAGE_FILENAME
rm $UNCOMPRESSED_IMAGE_FILENAME

echo "Testing the installer..."

. test_installer.sh

echo "To upload build, run:"
echo
echo "./upload-to-github.rb timcharper timcharper/git_osx_installer $IMAGE_FILENAME 'Git Installer $GIT_VERSION - OS X - Snow Leopard - Intel Universal'"

