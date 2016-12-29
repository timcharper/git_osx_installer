#!/bin/bash -x

set -e -o pipefail

# remove old installers
rm -f Disk\ Image/*.pkg

. ./env.sh

GIT_VERSION=${1:-$(CURRENT-GIT-VERSION)}

echo $GIT_VERSION

do-make clean
do-make package

echo "Testing the installer..."

. test_installer.sh

make OSX_VERSION=${OSX_VERSION:-10.9} VERSION=${GIT_VERSION} GIT_VERSION=${GIT_VERSION} deploy
