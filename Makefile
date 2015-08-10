## opencpx Makefile
## Scott Wiersdorf
## Created: Thu Jun 17 22:49:00 GMT 2004

##############################################################################

TARGET		= /usr/local/cp
BIN		= ./bin
ETC		= ./etc
HELP		= ./help
IMAGES		= ./cpimages
MODULES		= ./modules
RELEASE		= ./RELEASE
SBIN		= ./sbin
STRINGS		= ./strings
TEMPLATES	= ./templates
VSAPCONFIG	= ./modules/VSAP-Server-Modules/vsapd.conf
VSAPD		= ./vsapd/vsapd

RSYNC_OPTIONS	= "--dry-run --archive --verbose --cvs-exclude"

##############################################################################

all:
	@echo
	@echo "Select an action:"
	@echo
	@echo "  make check[-SOURCE]"
	@echo "    - check source against target and displays differences via rsync"
	@echo "    - optional [-SOURCE] can be any of the available sources (see below)"
	@echo
	@echo "  make clean"
	@echo "    - not yet supported"
	@echo
	@echo "  make create"
	@echo "    - makes the target directory tree ($(TARGET))"
	@echo
	@echo "  make install[-SOURCE]"
	@echo "    - installs opencpx source directory tree to ($(TARGET))"
	@echo "    - optional [-SOURCE] can be any of the available sources (see below)"
	@echo
	@echo "  make tar"
	@echo "    - creates opencpx tar archive from target ($(TARGET))"
	@echo
	@echo "  make test[-SOURCE]"
	@echo "    - tests XML/XSLT syntax"
	@echo "    - optional [-SOURCE] can be either 'help', 'strings', or 'templates'"
	@echo "    - e.g. 'make test-help', 'make test-strings', or 'make test-templates'"
	@echo
	@echo "-----------------------------------"
	@echo
	@echo "  Available sources:"
	@echo
	@echo "    bin"
	@echo "    etc"
	@echo "    help"
	@echo "    images"
	@echo "    sbin"
	@echo "    share"
	@echo "    strings"
	@echo "    templates"
	@echo

default: all

help: all

make: all

##############################################################################

check:	check-all
check-all:	check-bin check-etc check-help check-images check-sbin check-strings check-templates

check-bin:
	@echo "#### checking bin ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(BIN) $(TARGET)
	@echo

check-etc:
	@echo "#### checking vsapd.conf ..............."
	@rsync --dry-run --archive --verbose --cvs-exclude $(VSAPCONFIG) $(ETC)
	@echo

check-help:
	@echo "#### checking help ...................."
	@rsync --dry-run --checksum --archive --verbose --cvs-exclude --delete $(HELP) $(TARGET)
	@echo

check-images:
	@echo "#### checking images ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude --delete $(IMAGES) $(TARGET)
	@echo

check-sbin:
	@echo "#### checking sbin ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(SBIN) $(TARGET)
	@echo "#### checking vsapd ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(VSAPD) $(SBIN)
	@echo

check-share:
	@echo "#### checking share ...................."
	@echo

check-strings:
	@echo "#### checking strings ...................."
	@rsync --dry-run --checksum --archive --verbose --cvs-exclude --exclude="doc" --exclude="utils" --delete $(STRINGS) $(TARGET)
	@echo

check-templates:
	@echo "#### checking templates ...................."
	@rsync --dry-run --checksum --archive --verbose --cvs-exclude --delete $(TEMPLATES) $(TARGET)
	@echo

##############################################################################

clean:
	@echo "This target does not exist. A 'make install' automatically"
	@echo "removes nonexistant source files in the target hierarchy."

##############################################################################

create:
	@if [ ! -d $(TARGET) ]; then \
		echo "Creating $(TARGET)..."; \
		mkdir -p $(TARGET); \
	fi

##############################################################################

install:	install-all
install-all:	install-bin install-etc install-help install-images install-release install-sbin install-strings install-templates

install-bin:		create
	@echo "#### syncing bin ...................."
	@rsync --archive --verbose --cvs-exclude $(BIN) $(TARGET)
	@echo

install-help:	create
	@echo "#### syncing help ...................."
	@rsync --checksum --archive --verbose --cvs-exclude --delete $(HELP) $(TARGET)
	@(cd $(TARGET)/help; \
	for lang in `ls -1`; \
	do \
		langlink=`echo $$lang | sed -e 's|_.*||'`; \
		if [ -d $$lang -a ! -e $$langlink ]; then \
			echo "Creating link for $$lang -> $$langlink"; \
			ln -s $$lang $$langlink; \
		fi \
	done)
	@echo

install-etc:		create
	@echo "#### syncing vsapd.conf ..............."
	@rsync --archive --verbose --cvs-exclude $(VSAPCONFIG) $(ETC)
	@echo

install-images:		create link-images
	@echo "#### syncing images ...................."
	@rsync --archive --verbose --cvs-exclude --delete $(IMAGES) $(TARGET)
	@echo

install-modules:	create
	@echo "#### syncing modules ...................."
	@echo "FIX ME, NOT YET SUPPORTED"
	@echo

install-release:		create
	@echo "#### syncing RELEASE ..............."
	@rsync --archive --verbose --cvs-exclude $(RELEASE) $(TARGET)
	@echo

install-sbin:		create
	@echo "#### syncing sbin ...................."
	@rsync --archive --verbose --cvs-exclude $(SBIN) $(TARGET)
	@echo
	@echo "#### syncing vsapd ...................."
	@rsync --archive --verbose --cvs-exclude $(VSAPD) $(SBIN)
	@echo

install-strings:	create
	@echo "#### syncing strings ...................."
	@rsync --checksum --archive --verbose --cvs-exclude --exclude="doc" --exclude="utils" --delete $(STRINGS) $(TARGET)
	@(cd $(TARGET)/strings; \
	for lang in `ls -1`; \
	do \
		langlink=`echo $$lang | sed -e 's|_.*||'`; \
		if [ -d $$lang -a ! -e $$langlink ]; then \
			echo "Creating link for $$lang -> $$langlink"; \
			ln -s $$lang $$langlink; \
		fi \
	done)
	@echo

install-templates:	create
	@echo "#### syncing templates ...................."
	@rsync --checksum --archive --verbose --cvs-exclude --delete $(TEMPLATES) $(TARGET)
	@echo

##############################################################################

link-images:
	@if [ ! -e $(TARGET)/images ]; then \
		echo "Creating image symlink..."; \
		cd $(TARGET) && ln -s cpimages/brandx images; \
	fi

##############################################################################

test:	test-all
test-all:	test-help test-strings test-templates

test-help:
	find help/ -name "*.xml" -print | xargs xmllint --noout

test-strings:
	find strings/ -name "*.xml" -print | xargs xmllint --noout

test-templates:
	find templates/ -name "*.xsl" -print | xargs xsltproc --noout

##############################################################################

tar:
	@(cd rpmbuild/SOURCES; \
	rm -f /usr/local/cp/etc/server.crt /usr/local/cp/etc/server.key; \
	find /usr/local/cp -not -type d -print0 | sort -z | tar --exclude=".packlist" --exclude="perllocal.pod" -cf opencpx.tar --null -T - ;\
        gzip -9 opencpx.tar; \
        mv -f opencpx.tar.gz opencpx-0.12.tar.gz)

##############################################################################

