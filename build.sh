#!/bin/sh
if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi 
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
PREFIX=/usr/local/git
# Undefine to not use sudo
SUDO=sudo

echo "Building GIT_VERSION $GIT_VERSION"

$SUDO mv $PREFIX{,_`date +%s`}

mkdir -p git_build

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.bz2 ] && curl -O http://kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.bz2
    [ ! -d git-$GIT_VERSION ] && tar jxvf git-$GIT_VERSION.tar.bz2
    pushd git-$GIT_VERSION

        rm Makefile_tmp
        # If you're on PPC, you may need to uncomment this line: 
        # echo "MOZILLA_SHA1=1" >> Makefile_tmp

        # Tell make to use $PREFIX/lib rather than MacPorts:
        echo "NO_DARWIN_PORTS=1" >> Makefile_tmp
        cat Makefile >> Makefile_tmp
        mv Makefile_tmp Makefile

	# Make fat binaries with ppc/32 bit/64 bit
        make CFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" LDFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" prefix=$PREFIX all
        make CFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" LDFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" prefix=$PREFIX strip
        $SUDO make CFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" LDFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386" prefix=$PREFIX install

        # contrib
        $SUDO mkdir -p $PREFIX/contrib/completion
        $SUDO cp contrib/completion/git-completion.bash $PREFIX/contrib/completion/
    popd
    
    [ ! -f git-manpages-$GIT_VERSION.tar.bz2 ] && curl -O http://www.kernel.org/pub/software/scm/git/git-manpages-$GIT_VERSION.tar.bz2
    $SUDO mkdir -p $PREFIX/share/man
    $SUDO tar xjvo -C $PREFIX/share/man -f git-manpages-$GIT_VERSION.tar.bz2
popd

# change hardlinks for symlinks
$SUDO ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
$SUDO sh -c "echo .DS_Store >> $PREFIX/share/git-core/templates/info/exclude"

[ -d /etc/paths.d ]    && $SUDO cp etc/paths.d/git /etc/paths.d
[ -d /etc/manpaths.d ] && $SUDO cp etc/manpaths.d/git /etc/manpaths.d
