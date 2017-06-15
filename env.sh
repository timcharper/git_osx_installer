
CURRENT_GIT_VERSION=""

function current-git-version() {
  if [ -z "$CURRENT_GIT_VERSION" ]; then
    if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
    CURRENT_GIT_VERSION=$(curl -L http://git-scm.com/ 2>&1 | grep '<span class="version">' -A 1 | tail -n 1 | sed $sed_regexp 's/ *//')
  fi
  echo "$CURRENT_GIT_VERSION"
}

function do-make() {
  make OSX_VERSION=${OSX_VERSION:-10.9} VERSION=${GIT_VERSION:-$(current-git-version)} "${@}"
}

