#!/bin/bash -x

. env.sh

set -e -o pipefail
if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi 
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
PREFIX=/usr/local/git
# Undefine to not use sudo
SUDO=sudo

echo "Building GIT_VERSION $GIT_VERSION"

$SUDO mv $PREFIX{,_`date +%s`} || echo "Git not installed currently"

mkdir -p git_build

export TARGET_FLAGS="-mmacosx-version-min=10.6 -isysroot $SDK_PATH -DMACOSX_DEPLOYMENT_TARGET=10.6"
export CFLAGS="$TARGET_FLAGS -arch i386 -arch x86_64"
export LDFLAGS="$TARGET_FLAGS -arch i386 -arch x86_64"

export C_INCLUDE_PATH=/usr/include
export CPLUS_INCLUDE_PATH=/usr/include
export LD_LIBRARY_PATH=/usr/lib

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.gz ] && curl https://codeload.github.com/git/git/tar.gz/v${GIT_VERSION} > git-$GIT_VERSION.tar.gz
    [ ! -d git-$GIT_VERSION ] && tar zxvf git-$GIT_VERSION.tar.gz
    pushd git-$GIT_VERSION

        make -j32 NO_GETTEXT=1 NO_DARWIN_PORTS=1 prefix="$PREFIX" all strip install
        # $SUDO make -j32 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX"

        # contrib
        $SUDO mkdir -p $PREFIX/contrib/completion
        $SUDO cp contrib/completion/git-completion.bash $PREFIX/contrib/completion/
        $SUDO cp contrib/completion/git-completion.zsh $PREFIX/contrib/completion/
        $SUDO cp contrib/completion/git-prompt.sh $PREFIX/contrib/completion/

        # This is needed for Git-Gui, GitK
        $SUDO cp perl/private-Error.pm $PREFIX/lib/perl5/site_perl/Error.pm

        # git-credential-osxkeychain
        pushd contrib/credential/osxkeychain
            CFLAGS="$TARGET_FLAGS -arch x86_64" LDFLAGS="$TARGET_FLAGS -arch x86_64" make
            $SUDO cp git-credential-osxkeychain $PREFIX/bin/git-credential-osxkeychain
        popd
    popd
    
    GIT_MANPAGES_FOLDER="../git-manpages/.git"
    echo "-----------------------"
    echo
    echo "Please ensure that the folder `pwd`/$GIT_MANPAGES_FOLDER is at version $GIT_VERSION"
    printf "Press enter:"
    read
    echo
    $SUDO mkdir -p $PREFIX/share/man
    GIT_MANPAGES_ARCHIVE=git-manpages-$GIT_VERSION.tar.gz
    git archive --format=tar --remote $GIT_MANPAGES_FOLDER HEAD | gzip > $GIT_MANPAGES_ARCHIVE
    echo "sudo tar xf <(git archive --format=tar --remote $GIT_MANPAGES_FOLDER HEAD) -C $PREFIX/share/man"
    if ( ! sudo tar xzf $GIT_MANPAGES_ARCHIVE -C $PREFIX/share/man ); then
      echo "Error extracting manpages!!! Maybe download location has changed / failed? Look at `pwd`/$git_man_archive. Remove it and re-run build to attempt redownload."
      exit 1
    fi
    $SUDO chmod -R go+rx $PREFIX/share/man
popd

# Copy assets (e.g. system gitconfig)
rsync -av assets/git/ $PREFIX

# change hardlinks for symlinks
$SUDO ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
$SUDO sh -c "echo .DS_Store >> $PREFIX/share/git-core/templates/info/exclude"

$SUDO chown -R root:wheel /usr/local/git

[ -d /etc/paths.d ]    && $SUDO cp assets/etc/paths.d/git /etc/paths.d
[ -d /etc/manpaths.d ] && $SUDO cp assets/etc/manpaths.d/git /etc/manpaths.d
