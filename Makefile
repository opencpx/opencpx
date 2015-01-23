## CPX Makefile
## Scott Wiersdorf
## Created: Thu Jun 17 22:49:00 GMT 2004

TARGET        = /usr/local/cp
TEMPLATES     = ./templates
STRINGS       = ./strings
MODULES       = ./modules
IMAGES        = ./cpimages
CPBIN         = ./bin
CPSBIN        = ./sbin
VSAPD         = ./vsapd/vsapd
VSAPDTARGET   = /usr/local/cp/sbin

all:
	@echo "Select an action:"
	@echo "  test-(target)"
	@echo "    - tests (for templates and strings) XML/XSLT syntax"
	@echo "  check-(target)"
	@echo "    - shows you what will happen, but doesn't do it"
	@echo "  install-(target)"
	@echo "    - installs the current directory tree"
	@echo "  update-(target)"
	@echo "    - does a 'cvs update -d' on the target"
	@echo "  dist-(target) (* = these targets only)"
	@echo "    - makes a tarball for each language in the target"
	@echo
	@echo "Available targets:"
	@echo "  templates"
	@echo "  images"
	@echo "  strings"
	@echo "  bin"
	@echo "  sbin"

default: all

make: all

clean:
	@echo "This target does not exist. A 'make install' automatically"
	@echo "removes nonexistant source files in the target hierarchy."

create:
	@if [ ! -d $(TARGET) ]; then \
		echo "Creating $(TARGET)..."; \
		mkdir -p $(TARGET); \
	fi

check:	check-all
check-all:	check-templates check-strings check-images check-bin check-sbin

check-templates:
	@echo "#### checking templates ...................."
	@rsync --dry-run --checksum --archive --verbose --cvs-exclude --delete $(TEMPLATES) $(TARGET)
	@echo

test-templates:
	find templates/ -name "*.xsl" -print | xargs xsltproc --noout

check-strings:
	@echo "#### checking strings ...................."
	@rsync --dry-run --checksum --archive --verbose --cvs-exclude --exclude="doc" --exclude="utils" --delete $(STRINGS) $(TARGET)
	@echo

test-strings:
	find strings/ -name "*.xml" -print | xargs xmllint --noout

check-bin:
	@echo "#### checking bin ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(CPBIN) $(TARGET)
	@echo

check-sbin:
	@echo "#### checking sbin ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(CPSBIN) $(TARGET)
	@echo "#### checking vsapd ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude $(VSAPD) $(VSAPDTARGET)
	@echo

check-images:
	@echo "#### checking images ...................."
	@rsync --dry-run --archive --verbose --cvs-exclude --delete $(IMAGES) $(TARGET)
	@echo


install:	install-all
install-all:	install-templates install-strings install-images install-bin install-sbin

install-templates:	create
	@echo "#### syncing templates ...................."
	@rsync --checksum --archive --verbose --cvs-exclude --delete $(TEMPLATES) $(TARGET)
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

install-bin:		create
	@echo "#### syncing bin ...................."
	@rsync --archive --verbose --cvs-exclude $(CPBIN) $(TARGET)
	@echo

install-sbin:		create
	@echo "#### syncing sbin ...................."
	@rsync --archive --verbose --cvs-exclude $(CPSBIN) $(TARGET)
	@echo
	@echo "#### syncing vsapd ...................."
	@rsync --archive --verbose --cvs-exclude $(VSAPD) $(VSAPDTARGET)
	@echo

install-modules:		create
	@echo "#### syncing modules ...................."

install-images:		create link-images
	@echo "#### syncing images ...................."
	@rsync --archive --verbose --cvs-exclude --delete $(IMAGES) $(TARGET)
	@echo

link-images:
	@if [ ! -e $(TARGET)/images ]; then \
		echo "Creating image symlink..."; \
		cd $(TARGET) && ln -s cpimages/brandx images; \
	fi

dist-strings:
	@(cd strings; \
	for lang in `ls -1d ??_??`; \
	do \
		/usr/bin/tar --exclude="CVS" -zcvf ../strings-$$lang.tar.gz $$lang; \
		echo "===> String archive strings-$$lang.tar.gz created <==="; \
	done)

