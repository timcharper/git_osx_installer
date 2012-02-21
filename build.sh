#!/bin/bash

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi 
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
PREFIX=/usr/local/git
# Undefine to not use sudo
SUDO=sudo

echo "Building GIT_VERSION $GIT_VERSION"

$SUDO mv $PREFIX{,_`date +%s`}

mkdir -p git_build

DOWNLOAD_LOCATION="http://git-core.googlecode.com/files"

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.gz ] && curl -O $DOWNLOAD_LOCATION/git-$GIT_VERSION.tar.gz
    [ ! -d git-$GIT_VERSION ] && tar zxvf git-$GIT_VERSION.tar.gz
    pushd git-$GIT_VERSION

        CFLAGS="-mmacosx-version-min=10.6 -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch i386 -arch x86_64"
        LDFLAGS="-mmacosx-version-min=10.6 -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch i386 -arch x86_64"
        make -j32 NO_GETTEXT=1 NO_DARWIN_PORTS=1 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" all strip install
        # $SUDO make -j32 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX"

        # contrib
        $SUDO mkdir -p $PREFIX/contrib/completion
        $SUDO cp contrib/completion/git-completion.bash $PREFIX/contrib/completion/
        $SUDO cp perl/private-Error.pm $PREFIX/lib/perl5/site_perl/Error.pm
    popd
    
    git_man_archive=git-manpages-$GIT_VERSION.tar.gz
    [ ! -f $git_man_archive ] && curl -O $DOWNLOAD_LOCATION/$git_man_archive
    $SUDO mkdir -p $PREFIX/share/man
    if ( ! $SUDO tar xzvo -C $PREFIX/share/man -f $git_man_archive ); then
      echo "Error extracting manpages!!! Maybe download location has changed / failed? Look at `pwd`/$git_man_archive. Remove it and re-run build to attempt redownload."
      exit 1
    fi
popd

# change hardlinks for symlinks
$SUDO ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
$SUDO sh -c "echo .DS_Store >> $PREFIX/share/git-core/templates/info/exclude"

$SUDO chown -R root:wheel /usr/local/git

[ -d /etc/paths.d ]    && $SUDO cp etc/paths.d/git /etc/paths.d
[ -d /etc/manpaths.d ] && $SUDO cp etc/manpaths.d/git /etc/manpaths.d
