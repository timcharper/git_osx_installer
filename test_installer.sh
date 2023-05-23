#!/bin/sh

INSTALL_DIR="/usr/local/git/"


[ $# -gt 0 ] && GIT_PKG="$1" || GIT_PKG="$(ls git-*.pkg | head -1)"
if ! [ -f "$GIT_PKG" ]; then echo "$GIT_PKG does not exist"; exit 2; fi
[ $# -gt 1 ] && GIT_DIR="$2" || GIT_DIR="stage/$(echo "${GIT_PKG%.*}" | grep -o 'git-[0-9.]\+')"
if ! [ -d "$GIT_DIR" ]; then echo "$GIT_DIR does not exist"; exit 2; fi


echo "Uninstalling old version..."
[ -x /usr/local/git/uninstall ] && "$INSTALL_DIR/uninstall" --yes
[ -x /usr/local/git/uninstall.sh ] && "$INSTALL_DIR/uninstall.sh" --yes


echo "Installing $GIT_PKG..."
sudo /usr/sbin/installer -pkg "$GIT_PKG" -target / || exit 2


echo "Testing..."
RETVAL=0

for file in "$INSTALL_DIR/bin/git"; do
  if ! [ -f "$file" ]; then
    echo "'$file' DOES NOT EXIST!"
    RETVAL=1
  fi
done

(cd "$GIT_DIR" && find usr) | while read file; do
  if ! [ -e "/$file" ]; then
    echo "/$file did not get installed!"
    RETVAL=1
  fi
done

if ls -alR "$INSTALL_DIR"/* | awk '{print $3}' | awk 'NF' | grep -qv root; then
  echo "Some user-owned files exist!"
  RETVAL=1
fi

[ $RETVAL -eq 0 ] && echo "Success!"
exit $RETVAL
