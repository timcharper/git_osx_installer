# FAQ

## I have XCode installed (and consequently it's bundled git); how do I get my system to use this version instead?

If you have XCode installed, and want to use a later git, running the following should help:

    sudo mv /usr/bin/git /usr/bin/git-xcode
    sudo ln -sf /usr/local/git/bin/git /usr/bin/git

## 64-bit or 32-bit?

If your Mac was made on or after 2007, it is a 64-bit machine.

# Changes / Recent updates

## 2014-12-20

32-bit builds for Snow Leopard (and later) are back. These were created on a 64-bit installation of Mac OS X Snow Leopard.

## 2014-12-19 - CVE-2014-9390 Fix, and improved build process.

### CVE-2014-9390 security fix

As [announced](http://article.gmane.org/gmane.linux.kernel/1853266) on the git mailing list, git for OS X 

The following versions contain the fix:

- 2.2.1
- 2.1.4
- 2.0.5
- 1.9.5
- 1.8.5.6

### Support for older operating systems restored / apology

64-bit builds for Snow Leopard (and later) have been published. There was an issue with the build script in which the compilation Framework was not being properly specified, and this effectively caused it to be ignored. As a result, the builds were not working on 10.8.x and earlier. I apologize deeply for this error. Further compounding the issue was lack of feedback channels, and the negative reviews were not emailed to me. This was my fault as I did not set up adequate instructions for how to ask for help. I've updated the project home page with a link to the [GitHub issue tracker](https://github.com/timcharper/git_osx_installer/issues), and have done various cleanup to reduce clutter remaining since the transition from Google Code.

### Improved build process

The build process has been greatly improved; the cumbersome script has been replaced with a more declarative Makefile. A check has been added to assert that the 32-bit package actually contain 32-bit executables.
