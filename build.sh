#!/bin/sh
if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi 
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
PREFIX=/usr/local/git
# Undefine to not use sudo
SUDO=sudo

echo "Building GIT_VERSION $GIT_VERSION with arch $HOSTTYPE"

$SUDO mv $PREFIX{,_`date +%s`}

mkdir -p git_build

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.gz ] && curl -O http://git-core.googlecode.com/files/git-$GIT_VERSION.tar.gz
    [ ! -d git-$GIT_VERSION ] && tar zxvf git-$GIT_VERSION.tar.gz
    pushd git-$GIT_VERSION

        [ -f Makefile_head ] && rm Makefile_head
        # If you're on PPC, you may need to uncomment this line: 
        # echo "MOZILLA_SHA1=1" >> Makefile_head

        # Tell make to use $PREFIX/lib rather than MacPorts:
        echo "NO_DARWIN_PORTS=1" >> Makefile_head
        cat Makefile >> Makefile_head
        mv Makefile_head Makefile

	# Make fat binaries with ppc/32 bit/64 bit
        CFLAGS="-mmacosx-version-min=10.6 -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch $HOSTTYPE"
        LDFLAGS="-mmacosx-version-min=10.6 -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch $HOSTTYPE"
        make -j32 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" all
        make -j32 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" strip
        $SUDO make -j32 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" install

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

$SUDO chown -R root:wheel /usr/local/git

[ -d /etc/paths.d ]    && $SUDO cp etc/paths.d/git /etc/paths.d
[ -d /etc/manpaths.d ] && $SUDO cp etc/manpaths.d/git /etc/manpaths.d
