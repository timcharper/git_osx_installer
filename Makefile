SHELL := /bin/bash
SUDO := sudo
C_INCLUDE_PATH := /usr/include
CPLUS_INCLUDE_PATH := /usr/include
LD_LIBRARY_PATH := /usr/lib

PACKAGE_MAKER_APP := $(shell bin/find-dir {/Developer,}/Applications/Utilities/PackageMaker.app)

MAC_OSX_VERSION_TARGET := 10.6
SDK_PATH := $(shell bin/find-dir /Developer/SDKs/MacOSX$(MAC_OSX_VERSION_TARGET).sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform)
TARGET_FLAGS := -mmacosx-version-min=$(MAC_OSX_VERSION_TARGET) -isysroot $(SDK_PATH) -DMACOSX_DEPLOYMENT_TARGET=$(MAC_OSX_VERSION_TARGET)
ARCH := x86_64
CFLAGS := $(TARGET_FLAGS) -arch $(ARCH)
LDFLAGS := $(TARGET_FLAGS) -arch $(ARCH)

GIT_SUB_FOLDER := $(shell date +%s)
PREFIX := /usr/local/git

DOWNLOAD_LOCATION=https://www.kernel.org/pub/software/scm/git

XML_CATALOG_FILES=$(shell bin/find-file /usr/local/etc/xml/catalog)

SUBMAKE := $(MAKE) C_INCLUDE_PATH="$(C_INCLUDE_PATH)" CPLUS_INCLUDE_PATH="$(CPLUS_INCLUDE_PATH)" LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" TARGET_FLAGS="$(TARGET_FLAGS)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" NO_GETTEXT=1 NO_DARWIN_PORTS=1 prefix=$(PREFIX)

PACKAGE_SUFFIX := intel-$(ARCH)-snow-leopard

CORES := $(shell bash -c "sysctl hw.ncpu | awk '{print \$$2}'")

.PHONY: compile download install install-assets install-bin install-man image package deploy reinstall setup

.SECONDARY:

/usr/local/etc/xml/catalog:
	brew install docbook

/usr/local/bin/xmlto:
	brew install xmlto

/usr/local/bin/asciidoc:
	brew install asciidoc


setup: /usr/local/etc/xml/catalog /usr/local/bin/xmlto /usr/local/bin/asciidoc
	grep -q docbook-xsl /usr/local/etc/xml/catalog && exit 0 || (echo "You need docbook-xsl installed to build docs; If it is already installed, uninstall and reinstall it"; brew install docbook-xsl)
$(PREFIX)/VERSION-%:
	[ -d $(PREFIX) ] && $(SUDO) mv $(PREFIX) ./$(GIT_SUB_FOLDER) || echo "Git not installed currently"
	rm -f git_build/git-$*/osx-installed*
	$(SUDO) mkdir -p $(PREFIX)
	$(SUDO) chown $(shell whoami) $(PREFIX)
	touch $@

git_build/%.tar.gz:
	mkdir -p git_build
	curl -o git_build/$*.tar.gz.working "$(DOWNLOAD_LOCATION)/$*.tar.gz"
	mv git_build/$*.tar.gz.working git_build/$*.tar.gz

git_build/git-%/Makefile: git_build/git-%.tar.gz
	tar xzf git_build/git-$*.tar.gz -C git_build
	touch $@

git_build/git-%/osx-built: git_build/git-%/Makefile
	cd git_build/git-$*; $(SUBMAKE) -j $(CORES) all strip
	touch $@

git_build/git-%/osx-built-keychain: git_build/git-%/Makefile
ifeq ("$(ARCH)", "x86_64")
	cd git_build/git-$*/contrib/credential/osxkeychain; CFLAGS="$(TARGET_FLAGS) -arch $(ARCH)" LDFLAGS="$(TARGET_FLAGS) -arch $(ARCH)" $(MAKE)
endif
	touch $@

git_build/git-%/osx-built-subtree: git_build/git-%/Makefile | setup
	cd git_build/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" all git-subtree.1
	touch $@

git_build/git-%/osx-installed-subtree: git_build/git-%/osx-built-subtree
	cd git_build/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" install install-man
	touch $@

git_build/git-%/osx-installed-assets: git_build/git-%/osx-installed-bin
	mkdir -p $(PREFIX)/etc
	cp assets/git/etc/gitconfig.default $(PREFIX)/etc/gitconfig
ifeq ("$(ARCH)", "x86_64")
	cat assets/git/etc/gitconfig.osxkeychain >> $(PREFIX)/etc/gitconfig
endif
	sh -c "echo .DS_Store >> $(PREFIX)/share/git-core/templates/info/exclude"
	echo $(PREFIX)/bin > assets/etc/paths.d/git
	echo $(PREFIX)/share/man > assets/etc/manpaths.d/git
	[ -d /etc/paths.d ]    && $(SUDO) cp assets/etc/paths.d/git /etc/paths.d
	[ -d /etc/manpaths.d ] && $(SUDO) cp assets/etc/manpaths.d/git /etc/manpaths.d
	touch $@

git_build/git-%/osx-installed-bin: git_build/git-%/osx-built git_build/git-%/osx-built-keychain $(PREFIX)/VERSION-%
	cd git_build/git-$*; $(SUBMAKE) install
ifeq ("$(ARCH)", "x86_64")
	cp git_build/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain $(PREFIX)/bin/git-credential-osxkeychain
endif
	mkdir -p $(PREFIX)/contrib/completion
	cp git_build/git-$*/contrib/completion/git-completion.bash $(PREFIX)/contrib/completion/
	cp git_build/git-$*/contrib/completion/git-completion.zsh $(PREFIX)/contrib/completion/
	cp git_build/git-$*/contrib/completion/git-prompt.sh $(PREFIX)/contrib/completion/
	# This is needed for Git-Gui, GitK
	mkdir -p $(PREFIX)/lib/perl5/site_perl
	[ ! -f $(PREFIX)/lib/perl5/site_perl/Error.pm ] && cp git_build/git-$*/perl/private-Error.pm $(PREFIX)/lib/perl5/site_perl/Error.pm || echo done
	ruby UserScripts/symlink_git_hardlinks.rb
	touch $@

git_build/git-%/osx-installed-man: git_build/git-manpages-%.tar.gz git_build/git-%/osx-installed-bin
	tar xzfo git_build/git-manpages-$*.tar.gz -C $(PREFIX)/share/man
	touch $@

git_build/git-%/osx-installed: git_build/git-%/osx-installed-bin git_build/git-%/osx-installed-man git_build/git-%/osx-installed-assets git_build/git-%/osx-installed-subtree
	$(SUDO) chown -R root:wheel $(PREFIX)
	find $(PREFIX) -type d -exec chmod ugo+rx {} \;
	find $(PREFIX) -type f -exec chmod ugo+r {} \;
	touch $@

disk-image/VERSION-%:
	rm -f disk-image/*.pkg disk-image/VERSION-* disk-image/.DS_Store
	touch "$@"

disk-image/git-%-$(PACKAGE_SUFFIX).pkg: disk-image/VERSION-% $(PREFIX)/VERSION-% git_build/git-%/osx-installed
	$(SUDO) bash -c "$(PACKAGE_MAKER_APP)/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o disk-image/git-$*-$(PACKAGE_SUFFIX).pkg --title 'Git $*'"

git-%-$(PACKAGE_SUFFIX).dmg: disk-image/git-%-$(PACKAGE_SUFFIX).pkg
	rm -f git-$*-$(PACKAGE_SUFFIX)*.dmg
	hdiutil create git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg -srcfolder disk-image -volname "Git $* Snow Leopard Intel $(ARCH)" -ov
	hdiutil convert -format UDZO -o $@ git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg
	rm -f git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg

tmp/deployed-%: git-%-$(PACKAGE_SUFFIX).dmg
	mkdir -p tmp
	scp git-$*-$(PACKAGE_SUFFIX).dmg timcharper@frs.sourceforge.net:/home/pfs/project/git-osx-installer | tee $@.working
	mv $@.working $@

package: disk-image/git-$(GIT_VERSION)-$(PACKAGE_SUFFIX).pkg
install-assets: git_build/git-$(GIT_VERSION)/osx-installed-assets
install-bin: git_build/git-$(GIT_VERSION)/osx-installed-bin
install-man: git_build/git-$(GIT_VERSION)/osx-installed-man
install-subtree: git_build/git-$(GIT_VERSION)/osx-installed-subtree

install: git_build/git-$(GIT_VERSION)/osx-installed

download: git_build/git-$(GIT_VERSION).tar.gz git_build/git-manpages-$(GIT_VERSION).tar.gz

compile: git_build/git-$(GIT_VERSION)/osx-built git_build/git-$(GIT_VERSION)/osx-built-keychain

install-man: install-bin

deploy: tmp/deployed-$(GIT_VERSION)

clean:
	$(SUDO) rm -f git_build/git-$(GIT_VERSION)/osx-* /usr/local/git/v$(GIT_VERSION)
	cd git_build/git-$(GIT_VERSION) && $(SUBMAKE) clean

reinstall:
	$(SUDO) rm -rf /usr/local/git
	rm -f git_build/git-$(GIT_VERSION)/osx-installed*
	$(MAKE) install

image: git-$(GIT_VERSION)-$(PACKAGE_SUFFIX).dmg
