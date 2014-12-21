SHELL := /bin/bash
SUDO := sudo
C_INCLUDE_PATH := /usr/include
CPLUS_INCLUDE_PATH := /usr/include
LD_LIBRARY_PATH := /usr/lib

PACKAGE_MAKER_APP := $(shell bin/find-dir {/Developer,}/Applications/Utilities/PackageMaker.app)

MAC_OSX_VERSION_TARGET := 10.6
SDK_PATH := $(shell bin/find-dir /Developer/SDKs/MacOSX$(MAC_OSX_VERSION_TARGET).sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform)
TARGET_FLAGS := -mmacosx-version-min=$(MAC_OSX_VERSION_TARGET) -isysroot $(SDK_PATH) -DMACOSX_DEPLOYMENT_TARGET=$(MAC_OSX_VERSION_TARGET)
CFLAGS := $(TARGET_FLAGS) -arch x86_64 -arch i386
LDFLAGS := $(TARGET_FLAGS) -arch x86_64 -arch i386

BAK_FOLDER := $(shell date +%s)
PREFIX := /usr/local/git

DOWNLOAD_LOCATION=https://www.kernel.org/pub/software/scm/git

XML_CATALOG_FILES=$(shell bin/find-file /usr/local/etc/xml/catalog)

SUBMAKE := $(MAKE) C_INCLUDE_PATH="$(C_INCLUDE_PATH)" CPLUS_INCLUDE_PATH="$(CPLUS_INCLUDE_PATH)" LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" TARGET_FLAGS="$(TARGET_FLAGS)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" NO_GETTEXT=1 NO_DARWIN_PORTS=1 prefix=$(PREFIX)

PACKAGE_SUFFIX := intel-universal-snow-leopard

CORES := $(shell bash -c "sysctl hw.ncpu | awk '{print \$$2}'")

.PHONY: compile download install install-assets install-bin install-man install-subtree image package deploy reinstall setup

.SECONDARY:

/usr/local/etc/xml/catalog:
	brew install docbook

/usr/local/bin/xmlto:
	brew install xmlto

/usr/local/bin/asciidoc:
	brew install asciidoc


setup: /usr/local/etc/xml/catalog /usr/local/bin/xmlto /usr/local/bin/asciidoc
	grep -q docbook-xsl /usr/local/etc/xml/catalog && exit 0 || (echo "You need docbook-xsl installed to build docs; If it is already installed, uninstall and reinstall it"; brew install docbook-xsl)

$(PREFIX)/VERSION-%-universal:
	mkdir -p bak
	[ -d $(PREFIX) ] && $(SUDO) mv $(PREFIX) ./bak/$(BAK_FOLDER) || echo "Git not installed currently"
	rm -f build/git-$*/osx-installed*
	$(SUDO) mkdir -p $(PREFIX)
	$(SUDO) chown $(shell whoami) $(PREFIX)
	touch $@

build/%.tar.gz:
	mkdir -p build
	curl -o build/$*.tar.gz.working "$(DOWNLOAD_LOCATION)/$*.tar.gz"
	mv build/$*.tar.gz.working build/$*.tar.gz

build/git-%/Makefile: build/git-%.tar.gz
	tar xzf build/git-$*.tar.gz -C build
	touch $@

build/git-%/osx-built: build/git-%/Makefile
	cd build/git-$*; $(SUBMAKE) -j $(CORES) all strip
	touch $@

build/git-%/osx-built-keychain: build/git-%/Makefile
	cd build/git-$*/contrib/credential/osxkeychain; $(SUBMAKE) CFLAGS="$(CFLAGS) -g -O2 -Wall"
	touch $@

build/git-%/osx-built-subtree: build/git-%/Makefile | setup
	cd build/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" all git-subtree.1
	touch $@

build/git-%/osx-installed-subtree: build/git-%/osx-built-subtree
	cd build/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" install install-man
	touch $@

build/git-%/osx-installed-assets: build/git-%/osx-installed-bin
	mkdir -p $(PREFIX)/etc
	cp assets/git/etc/gitconfig.default $(PREFIX)/etc/gitconfig
	cat assets/git/etc/gitconfig.osxkeychain >> $(PREFIX)/etc/gitconfig
	sh -c "echo .DS_Store >> $(PREFIX)/share/git-core/templates/info/exclude"
	echo $(PREFIX)/bin > assets/etc/paths.d/git
	echo $(PREFIX)/share/man > assets/etc/manpaths.d/git
	[ -d /etc/paths.d ]    && $(SUDO) cp assets/etc/paths.d/git /etc/paths.d
	[ -d /etc/manpaths.d ] && $(SUDO) cp assets/etc/manpaths.d/git /etc/manpaths.d
	touch $@

build/git-%/osx-installed-bin: build/git-%/osx-built build/git-%/osx-built-keychain $(PREFIX)/VERSION-%-universal
	cd build/git-$*; $(SUBMAKE) install
	cp build/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain $(PREFIX)/bin/git-credential-osxkeychain
	mkdir -p $(PREFIX)/contrib/completion
	cp build/git-$*/contrib/completion/git-completion.bash $(PREFIX)/contrib/completion/
	cp build/git-$*/contrib/completion/git-completion.zsh $(PREFIX)/contrib/completion/
	cp build/git-$*/contrib/completion/git-prompt.sh $(PREFIX)/contrib/completion/
	# This is needed for Git-Gui, GitK
	mkdir -p $(PREFIX)/lib/perl5/site_perl
	[ ! -f $(PREFIX)/lib/perl5/site_perl/Error.pm ] && cp build/git-$*/perl/private-Error.pm $(PREFIX)/lib/perl5/site_perl/Error.pm || echo done
	ruby UserScripts/symlink_git_hardlinks.rb
	touch $@

build/git-%/osx-installed-man: build/git-manpages-%.tar.gz build/git-%/osx-installed-bin
	tar xzfo build/git-manpages-$*.tar.gz -C $(PREFIX)/share/man
	touch $@

build/git-%/osx-installed: build/git-%/osx-installed-bin build/git-%/osx-installed-man build/git-%/osx-installed-assets build/git-%/osx-installed-subtree
	$(SUDO) chown -R root:wheel $(PREFIX)
	find $(PREFIX) -type d -exec chmod ugo+rx {} \;
	find $(PREFIX) -type f -exec chmod ugo+r {} \;
	touch $@

build/git-%/osx-installed-assert-universal: build/git-%/osx-installed
	File build/git-$*/git | grep "Mach-O universal binary with 2 architectures"
	File build/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain | grep "Mach-O universal binary with 2 architectures"
	touch $@


disk-image/VERSION-%-universal:
	rm -f disk-image/*.pkg disk-image/VERSION-* disk-image/.DS_Store
	touch "$@"

disk-image/git-%-$(PACKAGE_SUFFIX).pkg: disk-image/VERSION-%-universal $(PREFIX)/VERSION-%-universal build/git-%/osx-installed build/git-%/osx-installed-assert-universal
	$(SUDO) bash -c "$(PACKAGE_MAKER_APP)/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o disk-image/git-$*-$(PACKAGE_SUFFIX).pkg --title 'Git $* universal'"

git-%-$(PACKAGE_SUFFIX).dmg: disk-image/git-%-$(PACKAGE_SUFFIX).pkg
	rm -f git-$*-$(PACKAGE_SUFFIX)*.dmg
	hdiutil create git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg -srcfolder disk-image -volname "Git $* Snow Leopard Intel Universal" -ov
	hdiutil convert -format UDZO -o $@ git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg
	rm -f git-$*-$(PACKAGE_SUFFIX).uncompressed.dmg

tmp/deployed-%: git-%-$(PACKAGE_SUFFIX).dmg
	mkdir -p tmp
	scp git-$*-$(PACKAGE_SUFFIX).dmg timcharper@frs.sourceforge.net:/home/pfs/project/git-osx-installer | tee $@.working
	mv $@.working $@

package: disk-image/git-$(VERSION)-$(PACKAGE_SUFFIX).pkg
install-assets: build/git-$(VERSION)/osx-installed-assets
install-bin: build/git-$(VERSION)/osx-installed-bin
install-man: build/git-$(VERSION)/osx-installed-man
install-subtree: build/git-$(VERSION)/osx-installed-subtree

install: build/git-$(VERSION)/osx-installed

download: build/git-$(VERSION).tar.gz build/git-manpages-$(VERSION).tar.gz

compile: build/git-$(VERSION)/osx-built build/git-$(VERSION)/osx-built-keychain

deploy: tmp/deployed-$(VERSION)

clean:
	$(SUDO) rm -f build/git-$(VERSION)/osx-* /usr/local/git/VERSION-*
	cd build/git-$(VERSION) && $(SUBMAKE) clean
	cd build/git-$(VERSION)/contrib/credential/osxkeychain; $(SUBMAKE) clean
	cd build/git-$(VERSION)/contrib/subtree; $(SUBMAKE) clean

reinstall:
	$(SUDO) rm -rf /usr/local/git/VERSION-*
	rm -f build/git-$(VERSION)/osx-installed*
	$(SUBMAKE) install

image: git-$(VERSION)-$(PACKAGE_SUFFIX).dmg
