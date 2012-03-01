#!/bin/bash

: << '*#'
Since using universal binaries generates a huge dmg I'm adding argument parsing
to the script. This way the arch and the git version can be set with arguments.

This are the allowed options
    -g: git version
    -a: architecture
    -o: OS X version to target. We use the X.Y format (10.5, 10.6 ...)
*#

# target git version to build
GIT_VERSION=
# target CPU architecture
ARCH=
# target OS X version
OS=

# : at te beginign avoids raising an error for illegar args
while getopts ":g:a:o:" OPT
do
    case $OPT in
        g)
            GIT_VERSION=$OPTARG
            ;;
        a)
            ARCH=$OPTARG
            ;;
	o)
	    OS=$OPTARG
	    ;;
    esac
done

#if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
#$GIT_VERSION="${GIT_VERSION:=`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
#$ARCH="${ARCH:="i386"}"

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi

if [[ -z $GIT_VERSION ]]; then
    GIT_VERSION=`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`
    echo "Git version is missing. Using $GIT_VERSION as value"
fi

if [[ -z $ARCH ]]; then
    ARCH="`uname -p`"
    echo "Target architecture is missing. Using $ARCH as value."
fi

# Full path for the OS SDK directory
OSDKDIR="/Developer/SDKs/"
if [[ -z $OS ]]; then
#OS="`ls -w1 $OSDKPATH | head -n1 | sed $sed_regexp 's/[a-zA-Z]*(10\.[0-9]).*/\1/'`"
    OS="`ls -w1 ${OSDKDIR} | head -n1 | sed $sed_regexp 's/MacOSX(10\.[0-9]).*/\1/'`"
    echo "Target OS X version is missing. Using $OS as value."
fi

OSDKDIR="`ls -d ${OSDKDIR}*${OS}*`"

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

        CFLAGS="-mmacosx-version-min=$OS -isysroot $OSDKDIR -arch $ARCH"
        LDFLAGS="-mmacosx-version-min=$OS -isysroot $OSDKDIR -arch $ARCH"
        $SUDO make -j32 NO_GETTEXT=1 NO_DARWIN_PORTS=1 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" all strip install
#$SUDO make -j32 NO_GETTEXT=1 NO_DARWIN_PORTS=1 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" all strip dist-doc

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
    else
        $SUDO gzip $PREFIX/share/man/man[1-9]/*
    fi
popd

# change hardlinks for symlinks
$SUDO ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
$SUDO sh -c "echo .DS_Store >> $PREFIX/share/git-core/templates/info/exclude"

$SUDO chown -R root:wheel /usr/local/git

[ -d /etc/paths.d ]    && $SUDO cp etc/paths.d/git /etc/paths.d
[ -d /etc/manpaths.d ] && $SUDO cp etc/manpaths.d/git /etc/manpaths.d
