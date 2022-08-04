# Creates a macOS installer for git

This is updated to create universal Intel + Apple Silicon binaries. It targets only macOS Sierra and later.

## Install

Download the most recent release and run it. This installs to `/usr/local` on both Intel and Apple Silicon. This may conflict with brew's installed `git` on Intel.

## Uninstall

Run `/usr/local/bin/git/uninstall`

## Notes

This does not include:

* `gettext` support and thus does not include translations (macOS has never included a `gettext` library)
* `git-svn` (macOS does not include `svn`)

Optionally this does not include:

* `git gui` or `gitk` (macOS has deprecated the system Tk, doesn't seem to work at all anyways)
* Documentation for `git-subtree`

## To build a new package

Requires Xcode Command Line Tools to build (which can be installed with `xcode-select --install`). To include `git-subtree` documentation, you also require `brew` (see [brew.sh](https://brew.sh/)).

```shell
git clone https://github.com/MoravianUniversity/git_osx_installer.git
cd git_osx_installer
#make INCLUDE_SUBTREE_DOC=1 setup  # only required if including git-subtree documentation 
make package  # options: INCLUDE_SUBTREE_DOC=1 INCLUDE_GUI=1
```
