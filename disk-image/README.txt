Git OSX Installer
=================
=================

https://github.com/timcharper/git_osx_installer/


INSTALLATION
============

Step 1 - Install Package
------------------------
Double-click the package in this disk image to install. This installs
git to /usr/local/git. Root access is required.


Step 2 - Remove stubs
---------------------
OS X has started to ship with stubs; in order to stay nice and
easy-to-uninstall, the git installer places all of it's assets under
`/usr/local/git`. As a result, the git in /usr/local/git/bin/git takes
second place to /usr/bin/git.

    sudo mv /usr/bin/git /usr/bin/git-system

Step 3 - Restart bash sessions
------------------------------
This include GNU screen sessions, TMUX sessions, etc. If you wish to
preserve your precious screen session, just `source /etc/profile`.


Step 4 - Run shell script
-------------------------
This step is optional.

Non-terminal programs don't inherit the system wide PATH and MANPATH
variables that your terminal does. If you'd like them to be able to
see Git, for whatever reason, you can run this script. It will add the
PATH and MANPATH to your ~/.MacOSX/environment.plist file. You'll need
to log out of your user account for that to take effect.



UPGRADING
=========

Simply download the latest Git installer, run the provided
uninstall.sh script, and then install as normal.



UNINSTALLING
============

Git installer has made you sad? Run the provided uninstall.sh script
in this disk image.



NOTES ABOUT THIS BUILD
============

* This build targets Snow Leopard and Lion. It may work on earlier or
  later versions of OS X.

* Since Mac OS X does not ship with gettext, this build does not
  include gettext support. If popular demand requests (via the git
  issue tracker
  http://code.google.com/p/git-osx-installer/issues/list) the
  installer may bundle gettext in the future to provide localization
  support.


KNOWN ISSUES
============


Git GUI / gitk won't open - complain of missing Tcl / Tk Aqua libraries
-----------------------------------------------------------------------

If you don't already have Tcl/Tk Aqua installed on your computer (most
MacOS X installs have it), you will get this error message. To resolve
it, simply go to the website for Tcl / Tk Aqua and download the latest
version:

http://www.categorifiedcoder.info/tcltk/

If you have an older version of Tcl / Tk Aqua, you'll benefit from
upgrading.

More information:

http://code.google.com/p/git-osx-installer/issues/detail?id=41



Installer hangs during install (and I have iPhone developer tools installed)
----------------------------------------------------------------------------

The iPhone developer tools require some kind of gnarly system lock
that causes the MacOS X installer system to hang. Just quit the iPhone
SDK and try again.

More information:

http://code.google.com/p/git-osx-installer/issues/detail?id=35



"git-svn is missing"
--------------------
Actually, it's probably NOT missing. If you missed the memo, here it
is again: the hyphenated syntax for calling git commands is history
(since 1.6.0). Invoke "git svn" instead.



Handling of international characters in file is broken
------------------------------------------------------

If you would like some validation, read this: http://is.gd/5NAN9.
You're not alone.

This is not an issue with git, not the installer. Apparently
subversion has it too.



"Can't locate Term/ReadKey.pm in @INC"
--------------------------------------
That perl library is normally installed on OS X machines. For whatever
reason, you're lucky enough not to have it.

You may find the following post helpful:

http://www.kkovacs.hu/2008/08/git-svn-for-os-x-fix/ 

