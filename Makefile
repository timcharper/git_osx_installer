SHELL := /bin/bash
SUDO := sudo
C_INCLUDE_PATH := /usr/include
CPLUS_INCLUDE_PATH := /usr/include
LD_LIBRARY_PATH := /usr/lib

PACKAGE_MAKER_APP := $(shell bin/find-dir {/Developer,}/Applications/Utilities/PackageMaker.app)

OSX_VERSION := 10.6
SDK_PATH := $(shell bin/find-dir /Developer/SDKs/MacOSX$(OSX_VERSION).sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$(OSX_VERSION).sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform)
TARGET_FLAGS := -mmacosx-version-min=$(OSX_VERSION) -isysroot $(SDK_PATH) -DMACOSX_DEPLOYMENT_TARGET=$(OSX_VERSION)

ifeq ("$(OSX_VERSION)", "10.6")
OSX_NAME := Snow Leopard
endif
ifeq ("$(OSX_VERSION)", "10.7")
OSX_NAME := Lion
endif
ifeq ("$(OSX_VERSION)", "10.8")
OSX_NAME := Mountain Lion
endif
ifeq ("$(OSX_VERSION)", "10.9")
OSX_NAME := Mavericks
endif
ifeq ("$(OSX_VERSION)", "10.10")
OSX_NAME := Yosemite
endif

OSX_CODE := $(shell echo "$(OSX_NAME)" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

ARCH := Universal
ARCH_CODE := $(shell echo "$(ARCH)" | tr '[:upper:]' '[:lower:]')
ARCH_FLAGS_universal := -arch x86_64 -arch i386
ARCH_FLAGS_i386 := -arch i386
ARCH_FLAGS_x86_64 := -arch x86_64

CFLAGS := $(TARGET_FLAGS) $(ARCH_FLAGS_${ARCH_CODE})
LDFLAGS := $(TARGET_FLAGS) $(ARCH_FLAGS_${ARCH_CODE})

BAK_FOLDER := $(shell date +%s)
PREFIX := /usr/local/git

DOWNLOAD_LOCATION=https://www.kernel.org/pub/software/scm/git

XML_CATALOG_FILES=$(shell bin/find-file /usr/local/etc/xml/catalog)

SUBMAKE := $(MAKE) C_INCLUDE_PATH="$(C_INCLUDE_PATH)" CPLUS_INCLUDE_PATH="$(CPLUS_INCLUDE_PATH)" LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" TARGET_FLAGS="$(TARGET_FLAGS)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" NO_GETTEXT=1 NO_DARWIN_PORTS=1 prefix=$(PREFIX)

BUILD_CODE := intel-$(ARCH_CODE)-$(OSX_CODE)
BUILD_DIR := build/$(BUILD_CODE)

CORES := $(shell bash -c "sysctl hw.ncpu | awk '{print \$$2}'")

vars:
	# OSX_NAME = $(OSX_NAME)
	# OSX_CODE = $(OSX_CODE)
	# ARCH = $(ARCH)
	# ARCH_CODE = $(ARCH_CODE)
	# CFLAGS = $(CFLAGS)
	# BUILD_CODE = $(BUILD_CODE)

.PHONY: compile download install install-assets install-bin install-man install-subtree image package deploy reinstall setup readme

.SECONDARY:

/usr/local/etc/xml/catalog:
	brew install docbook

/usr/local/bin/xmlto:
	brew install xmlto

/usr/local/bin/asciidoc:
	brew install asciidoc


tmp/setup-verified: /usr/local/etc/xml/catalog /usr/local/bin/xmlto /usr/local/bin/asciidoc
	grep -q docbook-xsl /usr/local/etc/xml/catalog && exit 0 || (echo "You need docbook-xsl installed to build docs; If it is already installed, uninstall and reinstall it"; brew install docbook-xsl)
	touch	$@

setup: tmp/setup-verified

$(PREFIX)/VERSION-%-$(BUILD_CODE):
	mkdir -p bak
	[ -d $(PREFIX) ] && $(SUDO) mv $(PREFIX) ./bak/$(BAK_FOLDER) || echo "Git not installed currently"
	rm -f $(BUILD_DIR)/git-$*/osx-installed*
	$(SUDO) mkdir -p $(PREFIX)
	$(SUDO) chown $(shell whoami) $(PREFIX)
	touch $@

build/%.tar.gz:
	mkdir -p build
	curl -o build/$*.tar.gz.working "$(DOWNLOAD_LOCATION)/$*.tar.gz"
	mv build/$*.tar.gz.working build/$*.tar.gz

$(BUILD_DIR)/git-%/Makefile: build/git-%.tar.gz
	mkdir -p $(BUILD_DIR)
	tar xzf build/git-$*.tar.gz -C $(BUILD_DIR)
	touch $@

$(BUILD_DIR)/git-%/osx-built: $(BUILD_DIR)/git-%/Makefile
	cd $(BUILD_DIR)/git-$*; $(SUBMAKE) -j $(CORES) all strip
	touch $@

$(BUILD_DIR)/git-%/osx-built-keychain: $(BUILD_DIR)/git-%/Makefile
	cd $(BUILD_DIR)/git-$*/contrib/credential/osxkeychain; $(SUBMAKE) CFLAGS="$(CFLAGS) -g -O2 -Wall"
	touch $@

$(BUILD_DIR)/git-%/osx-built-subtree: $(BUILD_DIR)/git-%/Makefile | setup
	cd $(BUILD_DIR)/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" all git-subtree.1
	touch $@

$(BUILD_DIR)/git-%/osx-installed-subtree: $(BUILD_DIR)/git-%/osx-built-subtree
	cd $(BUILD_DIR)/git-$*/contrib/subtree; $(SUBMAKE) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" install install-man
	touch $@

$(BUILD_DIR)/git-%/osx-installed-assets: $(BUILD_DIR)/git-%/osx-installed-bin
	mkdir -p $(PREFIX)/etc
	cp assets/git/etc/gitconfig.default $(PREFIX)/etc/gitconfig
	cat assets/git/etc/gitconfig.osxkeychain >> $(PREFIX)/etc/gitconfig
	sh -c "echo .DS_Store >> $(PREFIX)/share/git-core/templates/info/exclude"
	echo $(PREFIX)/bin > assets/etc/paths.d/git
	echo $(PREFIX)/share/man > assets/etc/manpaths.d/git
	[ -d /etc/paths.d ]    && $(SUDO) cp assets/etc/paths.d/git /etc/paths.d
	[ -d /etc/manpaths.d ] && $(SUDO) cp assets/etc/manpaths.d/git /etc/manpaths.d
	touch $@

$(BUILD_DIR)/git-%/osx-installed-bin: $(BUILD_DIR)/git-%/osx-built $(BUILD_DIR)/git-%/osx-built-keychain $(PREFIX)/VERSION-%-$(BUILD_CODE)
	cd $(BUILD_DIR)/git-$*; $(SUBMAKE) install
	cp $(BUILD_DIR)/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain $(PREFIX)/bin/git-credential-osxkeychain
	mkdir -p $(PREFIX)/contrib/completion
	cp $(BUILD_DIR)/git-$*/contrib/completion/git-completion.bash $(PREFIX)/contrib/completion/
	cp $(BUILD_DIR)/git-$*/contrib/completion/git-completion.zsh $(PREFIX)/contrib/completion/
	cp $(BUILD_DIR)/git-$*/contrib/completion/git-prompt.sh $(PREFIX)/contrib/completion/
	# This is needed for Git-Gui, GitK
	mkdir -p $(PREFIX)/lib/perl5/site_perl
	[ ! -f $(PREFIX)/lib/perl5/site_perl/Error.pm ] && cp $(BUILD_DIR)/git-$*/perl/private-Error.pm $(PREFIX)/lib/perl5/site_perl/Error.pm || echo done
	ruby UserScripts/symlink_git_hardlinks.rb
	touch $@

$(BUILD_DIR)/git-%/osx-installed-man: build/git-manpages-%.tar.gz $(BUILD_DIR)/git-%/osx-installed-bin
	tar xzfo build/git-manpages-$*.tar.gz -C $(PREFIX)/share/man
	touch $@

$(BUILD_DIR)/git-%/osx-installed: $(BUILD_DIR)/git-%/osx-installed-bin $(BUILD_DIR)/git-%/osx-installed-man $(BUILD_DIR)/git-%/osx-installed-assets $(BUILD_DIR)/git-%/osx-installed-subtree
	$(SUDO) chown -R root:wheel $(PREFIX)
	find $(PREFIX) -type d -exec chmod ugo+rx {} \;
	find $(PREFIX) -type f -exec chmod ugo+r {} \;
	touch $@

$(BUILD_DIR)/git-%/osx-built-assert-$(ARCH_CODE): $(BUILD_DIR)/git-%/osx-built
ifeq ("$(ARCH_CODE)", "universal")
	File $(BUILD_DIR)/git-$*/git | grep "Mach-O universal binary with 2 architectures"
	File $(BUILD_DIR)/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain | grep "Mach-O universal binary with 2 architectures"
else
	[ "$$(File $(BUILD_DIR)/git-$*/git | cut -f 5 -d' ')" == "$(ARCH_CODE)" ]
	[ "$$(File $(BUILD_DIR)/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain | cut -f 5 -d' ')" == "$(ARCH_CODE)" ]
endif
	touch $@


disk-image/VERSION-%-$(ARCH_CODE)-$(OSX_CODE):
	rm -f disk-image/*.pkg disk-image/VERSION-* disk-image/.DS_Store
	touch "$@"

disk-image/git-%-$(BUILD_CODE).pkg: disk-image/VERSION-%-$(ARCH_CODE)-$(OSX_CODE) $(PREFIX)/VERSION-%-$(BUILD_CODE) $(BUILD_DIR)/git-%/osx-installed $(BUILD_DIR)/git-%/osx-built-assert-$(ARCH_CODE)
	$(SUDO) bash -c "$(PACKAGE_MAKER_APP)/Contents/MacOS/PackageMaker --doc Git\ Installer.pmdoc/ -o disk-image/git-$*-$(BUILD_CODE).pkg --title 'Git $* $(ARCH)'"

git-%-$(BUILD_CODE).dmg: disk-image/git-%-$(BUILD_CODE).pkg
	rm -f git-$*-$(BUILD_CODE)*.dmg
	hdiutil create git-$*-$(BUILD_CODE).uncompressed.dmg -srcfolder disk-image -volname "Git $* $(OSX_NAME) Intel $(ARCH)" -ov
	hdiutil convert -format UDZO -o $@ git-$*-$(BUILD_CODE).uncompressed.dmg
	rm -f git-$*-$(BUILD_CODE).uncompressed.dmg

tmp/deployed-%-$(BUILD_CODE): git-%-$(BUILD_CODE).dmg
	mkdir -p tmp
	scp git-$*-$(BUILD_CODE).dmg timcharper@frs.sourceforge.net:/home/pfs/project/git-osx-installer | tee $@.working
	mv $@.working $@

package: disk-image/git-$(VERSION)-$(BUILD_CODE).pkg
install-assets: $(BUILD_DIR)/git-$(VERSION)/osx-installed-assets
install-bin: $(BUILD_DIR)/git-$(VERSION)/osx-installed-bin
install-man: $(BUILD_DIR)/git-$(VERSION)/osx-installed-man
install-subtree: $(BUILD_DIR)/git-$(VERSION)/osx-installed-subtree

install: $(BUILD_DIR)/git-$(VERSION)/osx-installed

download: build/git-$(VERSION).tar.gz build/git-manpages-$(VERSION).tar.gz

compile: $(BUILD_DIR)/git-$(VERSION)/osx-built $(BUILD_DIR)/git-$(VERSION)/osx-built-keychain $(BUILD_DIR)/git-$(VERSION)/osx-built-subtree

deploy: tmp/deployed-$(VERSION)-$(BUILD_CODE)

tmp/deployed-readme: README.md
	scp README.md timcharper@frs.sourceforge.net:/home/pfs/project/git-osx-installer | tee $@.working
	mv $@.working $@

readme: tmp/deployed-readme


clean:
	$(SUDO) rm -f $(BUILD_DIR)/git-$(VERSION)/osx-* /usr/local/git/VERSION-*
	cd $(BUILD_DIR)/git-$(VERSION) && $(SUBMAKE) clean
	cd $(BUILD_DIR)/git-$(VERSION)/contrib/credential/osxkeychain; $(SUBMAKE) clean
	cd $(BUILD_DIR)/git-$(VERSION)/contrib/subtree; $(SUBMAKE) clean

reinstall:
	$(SUDO) rm -rf /usr/local/git/VERSION-*
	rm -f $(BUILD_DIR)/git-$(VERSION)/osx-installed*
	$(SUBMAKE) install

image: git-$(VERSION)-$(BUILD_CODE).dmg
