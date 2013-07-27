if [ ! -r "/usr/local/git" ]; then
  echo "Git doesn't appear to be installed via this installer.  Aborting"
  exit 1
fi
echo "This will uninstall git by removing /usr/local/git/**/*, /etc/paths.d/git, /etc/manpaths.d/git"
printf "Type 'yes' if you sure you wish to continue: "
read response
if [ "$response" == "yes" ]; then
  sudo rm -rf /usr/local/git/
  sudo rm /etc/paths.d/git
  sudo rm /etc/manpaths.d/git
  pkgutil --packages | grep GitOSX.Installer | xargs -I {} sudo pkgutil --forget {}
  echo "Uninstalled"
else
  echo "Aborted"
  exit 1
fi

exit 0
