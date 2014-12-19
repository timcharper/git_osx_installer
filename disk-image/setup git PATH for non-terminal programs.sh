#!/bin/sh

append_path () {
  input="$1"
  value="$2"
  if ! echo $input | /usr/bin/egrep -q "(^|:)$value($|:)" ; then
     if [ "$3" = "after" ] ; then
        echo $input:$value
     else
        echo $value:$input
     fi
  else
    echo $input
  fi
}

append_plist_var() {
  name="$1"
  append_value="$2"
  default_value="$3"
  current_value="`defaults read $HOME/.MacOSX/environment ${name}`"
  [ ! "$current_value" ] && current_value="$default_value"
  new_value="`append_path "$current_value" "$append_value" after`"
  defaults write $HOME/.MacOSX/environment "$name" "$new_value"
  if [ "$current_value" == "$new_value" ]; then
    echo "No change to $name in ~/.MacOSX/environment.plist"
  else
    echo "Variable $name in ~/.MacOSX/environment.plist changed from '$current_value' to '$new_value'"
    echo "You will need to log out of your Mac OS X user account and log back in for changes to take effect."
  fi
}

append_plist_var PATH "/usr/local/git/bin" "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/opt/local/bin"

pushd "$HOME"

popd