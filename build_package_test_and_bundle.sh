#!/bin/bash -x

set -e -o pipefail

# remove old installers
rm -f Disk\ Image/*.pkg

. ./env.sh

GIT_VERSION=${1:-$(current-git-version)}

echo $GIT_VERSION

do-make clean
do-make package

echo "Testing the installer..."

. test_installer.sh

do-make deploy
