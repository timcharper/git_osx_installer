#!/bin/sh
if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi 
GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"

echo "Building GIT_VERSION $GIT_VERSION"

sudo mv /usr/local/git{,_`date +%s`}
sudo UserScripts/cplibs.sh

mkdir -p git_build

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.bz2 ] && curl -O http://kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.bz2
    [ ! -d git-$GIT_VERSION ] && tar jxvf git-$GIT_VERSION.tar.bz2
    pushd git-$GIT_VERSION

        rm Makefile_tmp
        # If you're on PPC, you may need to uncomment this line: 
        # echo "MOZILLA_SHA1=1" >> Makefile_tmp

        # Tell make to use /usr/local/git/lib rather than MacPorts:
        echo "NO_DARWIN_PORTS=1" >> Makefile_tmp
        cat Makefile >> Makefile_tmp
        mv Makefile_tmp Makefile

        make LDFLAGS="-L/usr/local/git/lib,/usr/lib" prefix=/usr/local/git all
        make LDFLAGS="-L/usr/local/git/lib,/usr/lib" prefix=/usr/local/git strip
        sudo make LDFLAGS="-L/usr/local/git/lib,/usr/lib" prefix=/usr/local/git install

        # contrib
        sudo mkdir -p /usr/local/git/contrib/completion
        sudo cp contrib/completion/git-completion.bash /usr/local/git/contrib/completion/
    popd
    
    [ ! -f git-manpages-$GIT_VERSION.tar.bz2 ] && curl -O http://www.kernel.org/pub/software/scm/git/git-manpages-$GIT_VERSION.tar.bz2
    sudo mkdir -p /usr/local/git/man
    sudo tar xjvo -C /usr/local/git/man -f git-manpages-$GIT_VERSION.tar.bz2
popd

# change hardlinks for symlinks
sudo ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
sudo sh -c "echo .DS_Store >> /usr/local/git/share/git-core/templates/info/exclude"
