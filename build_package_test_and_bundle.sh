#!/bin/bash

set -e -o pipefail

# remove old installers
rm -f Disk\ Image/*.pkg

if [ -z "$GIT_VERSION" ]; then
  if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
  GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep '<span class="version">' -A 1 | tail -n 1 | sed $sed_regexp 's/ *//'`}"
fi

echo $GIT_VERSION

make GIT_VERSION=$GIT_VERSION clean
make GIT_VERSION=$GIT_VERSION package

echo "Testing the installer..."

. test_installer.sh

make GIT_VERSION=$GIT_VERSION deploy
