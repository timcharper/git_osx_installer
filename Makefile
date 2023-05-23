SHELL := /bin/bash
SUDO := sudo
C_INCLUDE_PATH := /usr/include
CPLUS_INCLUDE_PATH := /usr/include
LD_LIBRARY_PATH := /usr/lib

VERSION := $(shell bin/latest-git-version)
DOWNLOAD_LOCATION := https://www.kernel.org/pub/software/scm/git

ARCH_FLAGS_intel := -target x86_64-apple-macos10.12
ARCH_FLAGS_arm := -target arm64-apple-macos11

CFLAGS_intel := $(ARCH_FLAGS_intel)
LDFLAGS_intel := $(ARCH_FLAGS_intel)
CFLAGS_arm := $(ARCH_FLAGS_arm)
LDFLAGS_arm := $(ARCH_FLAGS_arm)

PREFIX := /usr/local
GIT_PREFIX := $(PREFIX)/git
BUILD_DIR := build
DESTDIR_arm := $(PWD)/stage-arm/
DESTDIR_intel := $(PWD)/stage-intel/
DESTDIR := $(PWD)/stage/git-$(VERSION)

ifdef INCLUDE_GUI
FLAGS :=
COMP_PLIST := --component-plist ./git-components.plist
else
FLAGS := NO_TCLTK=1
COMP_PLIST :=
endif

SUBMAKE_base := "$(MAKE)" C_INCLUDE_PATH="$(C_INCLUDE_PATH)" CPLUS_INCLUDE_PATH="$(CPLUS_INCLUDE_PATH)" LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" $(FLAGS) NO_GETTEXT=1 NO_DARWIN_PORTS=1 prefix="$(GIT_PREFIX)"
SUBMAKE_arm := $(SUBMAKE_base) DESTDIR="$(DESTDIR_arm)" CFLAGS="$(CFLAGS_arm)" LDFLAGS="$(LDFLAGS_arm)"
SUBMAKE_intel := $(SUBMAKE_base) DESTDIR="$(DESTDIR_intel)" CFLAGS="$(CFLAGS_intel)" LDFLAGS="$(LDFLAGS_intel)"

XML_CATALOG_FILES := $(shell bin/find-file /usr/local/etc/xml/catalog /opt/homebrew/etc/xml/catalog)

.PHONY: setup download compile stage install package

.SECONDARY:

package: git-$(VERSION).pkg
install: $(BUILD_DIR)/osx-installed
stage: $(BUILD_DIR)/osx-staged-arm $(BUILD_DIR)/osx-staged-intel
compile: $(BUILD_DIR)/osx-compiled-arm $(BUILD_DIR)/osx-compiled-intel
download: build/git-$(VERSION).tar.gz build/git-manpages-$(VERSION).tar.gz
ifdef INCLUDE_SUBTREE_DOC
tmp/setup-verified:
	brew install docbook xmlto asciidoc docbook-xsl
	grep -q docbook-xsl "$(XML_CATALOG_FILES)"
	touch "$@"
setup: tmp/setup-verified
else
setup:
endif
clean:
	rm -rf "$(BUILD_DIR)"/git-*/ "$(DESTDIR_arm)" "$(DESTDIR_intel)" "git-$(VERSION).pkg"
	$(SUDO) rm -rf "$(DESTDIR)"
	rm -f "$(BUILD_DIR)"/osx-compiled-* "$(BUILD_DIR)"/osx-staged-* "$(BUILD_DIR)"/osx-installed*

vars:
	# VERSION = $(VERSION)
	# PREFIX = $(PREFIX)
	# DESTDIR = $(DESTDIR)
	# GIT_PREFIX = $(GIT_PREFIX)
	# BUILD_DIR = $(BUILD_DIR)
	# SUBMAKE_arm = $(SUBMAKE_arm)
	# SUBMAKE_intel = $(SUBMAKE_intel)
	# INCLUDE_GUI = $(INCLUDE_GUI)
	# INCLUDE_SUBTREE_DOC = $(INCLUDE_SUBTREE_DOC)
	# XML_CATALOG_FILES = $(XML_CATALOG_FILES)


##### Download #####

$(BUILD_DIR)/%.tar.gz:
	mkdir -p "$(BUILD_DIR)"
	curl -L -o "$(BUILD_DIR)/$*.tar.gz.working" "$(DOWNLOAD_LOCATION)/$*.tar.gz"
	mv "$(BUILD_DIR)/$*.tar.gz.working" "$(BUILD_DIR)/$*.tar.gz"

$(BUILD_DIR)/git-%/Makefile: $(BUILD_DIR)/git-$(VERSION).tar.gz
	mkdir -p "$(BUILD_DIR)"
	tar xzf build/git-$(VERSION).tar.gz -C "$(BUILD_DIR)"
	mv "$(BUILD_DIR)/git-$(VERSION)" "$(BUILD_DIR)/git-$*"
	touch "$@"


##### Compile #####

$(BUILD_DIR)/git-%/osx-built-git: $(BUILD_DIR)/git-%/Makefile
	cd "$(BUILD_DIR)/git-$*"; $(SUBMAKE_${*}) -j 3 all strip
	touch "$@"

$(BUILD_DIR)/git-%/osx-built-keychain: $(BUILD_DIR)/git-%/Makefile
	cd "$(BUILD_DIR)/git-$*/contrib/credential/osxkeychain"; $(SUBMAKE_${*}) CFLAGS="$(CFLAGS_${*}) -g -O2"
	touch "$@"

ifdef INCLUDE_SUBTREE_DOC
$(BUILD_DIR)/git-%/osx-built-subtree: $(BUILD_DIR)/git-%/Makefile | setup
	cd "$(BUILD_DIR)/git-$*/contrib/subtree"; $(SUBMAKE_${*}) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" all git-subtree.1
else
$(BUILD_DIR)/git-%/osx-built-subtree: $(BUILD_DIR)/git-%/Makefile
	cd "$(BUILD_DIR)/git-$*/contrib/subtree"; $(SUBMAKE_${*}) all
endif
	touch "$@"

$(BUILD_DIR)/osx-compiled-%: $(BUILD_DIR)/git-%/osx-built-git $(BUILD_DIR)/git-%/osx-built-keychain $(BUILD_DIR)/git-%/osx-built-subtree
	touch "$@"


##### Stage #####

$(BUILD_DIR)/git-%/osx-staged-git: $(BUILD_DIR)/git-%/osx-built-git
	mkdir -p "$(DESTDIR_${*})$(GIT_PREFIX)"
	cd "$(BUILD_DIR)/git-$*"; $(SUBMAKE_${*}) INSTALL_SYMLINKS=1 install
	touch "$@"

$(BUILD_DIR)/git-%/osx-staged-keychain: $(BUILD_DIR)/git-%/osx-built-keychain
	mkdir -p "$(DESTDIR_${*})$(GIT_PREFIX)"
	cp "$(BUILD_DIR)/git-$*/contrib/credential/osxkeychain/git-credential-osxkeychain" "$(DESTDIR_${*})$(GIT_PREFIX)/bin/git-credential-osxkeychain"
	touch "$@"

$(BUILD_DIR)/git-%/osx-staged-subtree: $(BUILD_DIR)/git-%/osx-built-subtree
	mkdir -p "$(DESTDIR_${*})$(GIT_PREFIX)"
ifdef INCLUDE_SUBTREE_DOC
	cd "$(BUILD_DIR)/git-$*/contrib/subtree"; $(SUBMAKE_${*}) XML_CATALOG_FILES="$(XML_CATALOG_FILES)" install install-man
else
	cd "$(BUILD_DIR)/git-$*/contrib/subtree"; $(SUBMAKE_${*}) install
endif
	touch "$@"

$(BUILD_DIR)/osx-staged-%: $(BUILD_DIR)/git-%/osx-staged-git $(BUILD_DIR)/git-%/osx-staged-keychain $(BUILD_DIR)/git-%/osx-staged-subtree
	touch "$@"


##### Install #####

$(BUILD_DIR)/osx-installed-bin: $(BUILD_DIR)/osx-staged-arm $(BUILD_DIR)/osx-staged-intel
	mkdir -p "$(DESTDIR)$(GIT_PREFIX)"
	# recreate directory structure and add in all symlinks
	cd "$(DESTDIR_arm)"; find . -type d -exec mkdir -p "$(DESTDIR)/{}" \;
	cd "$(DESTDIR_arm)"; find . -type l -exec cp -fPR "{}" "$(DESTDIR)/{}" \;
	# look at all other files: copy non-executables, merge executables
	cd "$(DESTDIR_arm)"; find . -type f -exec bash -c '[[ "$$(file -b "{}")" == "Mach-O 64-bit executable arm64" ]]' \; -exec lipo -create -output "$(DESTDIR)/{}" "$(DESTDIR_intel)/{}" "$(DESTDIR_arm)/{}" \;
	cd "$(DESTDIR_arm)"; find . -type f -exec bash -c '[[ "$$(file -b "{}")" != "Mach-O 64-bit executable arm64" ]]' \; -exec cp -f "$(DESTDIR_arm)/{}" "$(DESTDIR)/{}" \;
	touch "$@"

$(BUILD_DIR)/osx-installed-man: build/git-manpages-$(VERSION).tar.gz
	mkdir -p "$(DESTDIR)$(GIT_PREFIX)/share/man"
	tar xzfo "build/git-manpages-$(VERSION).tar.gz" -C "$(DESTDIR)$(GIT_PREFIX)/share/man"
	touch "$@"

$(BUILD_DIR)/osx-installed-assets: $(BUILD_DIR)/osx-installed-bin $(BUILD_DIR)/osx-installed-man
	mkdir -p "$(DESTDIR)$(GIT_PREFIX)/etc"
	cat assets/etc/gitconfig.default assets/etc/gitconfig.osxkeychain > "$(DESTDIR)$(GIT_PREFIX)/etc/gitconfig"
	cp -f assets/uninstall "$(DESTDIR)$(GIT_PREFIX)/uninstall"
	echo .DS_Store >> "$(DESTDIR)$(GIT_PREFIX)/share/git-core/templates/info/exclude"
	mkdir -p "$(DESTDIR)$(GIT_PREFIX)/contrib"
	cp -r "$(BUILD_DIR)/git-arm/contrib/completion/" "$(DESTDIR)$(GIT_PREFIX)/contrib/completion/"
ifdef INCLUDE_GUI
	mkdir -p "$(DESTDIR)$(GIT_PREFIX)/lib/perl5/site_perl"
	cp -f "$(BUILD_DIR)/git-arm/perl/FromCPAN/Error.pm" "$(DESTDIR)$(GIT_PREFIX)/lib/perl5/site_perl/Error.pm"
endif
	mkdir -p "$(DESTDIR)$(PREFIX)/bin"
	cd "$(DESTDIR)$(PREFIX)/bin"; find ../git/bin -type f -exec ln -sf {} \;
	for man in $(ls "$(DESTDIR)$(GIT_PREFIX)/share/man/"); do mkdir -p "$(DESTDIR)$(PREFIX)/share/man/$$man"; (cd "$(DESTDIR)$(PREFIX)/share/man/$$man"; ln -sf ../../../git/share/man/$$man/* ./); done
	touch "$@"

$(BUILD_DIR)/osx-installed: $(BUILD_DIR)/osx-installed-bin $(BUILD_DIR)/osx-installed-man $(BUILD_DIR)/osx-installed-assets
	$(SUDO) chown -R root:wheel $(DESTDIR)$(GIT_PREFIX)
	find $(DESTDIR)$(GIT_PREFIX) -type d -exec chmod ugo+rx {} \;
	find $(DESTDIR)$(GIT_PREFIX) -type f -exec chmod ugo+r {} \;
	touch "$@"


##### Package #####

git-$(VERSION).pkg: $(BUILD_DIR)/osx-installed
	pkgbuild --identifier com.git.pkg --version $(VERSION) --root "$(DESTDIR)$(PREFIX)" --install-location "$(PREFIX)" $(COMP_PLIST) git-$(VERSION).pkg
