#!/bin/sh


# wipe out the symlinks
if [ -d /usr/local/git ]; then
  find /usr/local/git -type f  | sed 's|/usr/local/git|/usr/local|g' | while read f; do [ -h "$f" ] && sudo rm $f || true; done
  sudo rm -rf /usr/local/git
fi

echo "OK - running the installer. Come back and press a key when you're done."
open disk-image/git*.pkg 

read -n 1

for file in /usr/local/git/bin/git "/usr/local/git/share/git-gui/lib/Git Gui.app/Contents/Info.plist"; do
  printf "'$file'"
  if [ -f "$file" ]; then
    echo " - exists"
  else
    echo " DOES NOT EXIST!"
    for n in {1..20}; do
      echo "FAIL FAIL FAIL"
    done
    exit 1
  fi
done

echo "Testing..."

(cd stage/*-$GIT_VERSION; find usr) | while read f; do
  if ! [ -e "/$f" ]; then
    echo "/$f did not get installed!"
    exit 1
  fi
done

if (ls -alR /usr/local/git/* | awk '{print $3}' | grep `whoami`); then
  echo "Some user-owned files exist!"
  exit 1
fi

echo "Success!"

