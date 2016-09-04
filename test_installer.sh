#!/bin/sh
find /usr/local/git > tmp/install_contents_before.txt
echo "Testing..."
sudo rm -rf /usr/local/git

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

find /usr/local/git > tmp/install_contents_after.txt

install_diff=$(diff tmp/install_contents_before.txt tmp/install_contents_after.txt)
if [ "$install_diff" == "" ]; then
  echo "No files went missing!"
else
  echo "A FEW FILES WENT MISSING!
$install_diff"
  exit 1
fi

if (ls -alR /usr/local/git/* | grep `whoami`); then
  echo "Some user-owned files exist!"
  exit 1
fi

echo "Success!"

