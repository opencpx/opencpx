## opencpx Makefile
## Scott Wiersdorf
## Created: Thu Jun 17 22:49:00 GMT 2004
## Updated: Mon Aug 10 21:11:01 MDT 2015

##############################################################################

TARGET		= /usr/local/cp/
BIN		= ./bin
ETC		= ./etc
HELP		= ./help
IMAGES		= ./cpimages
LIB		= ./lib
MODULES		= ./modules
RELEASE		= ./RELEASE
SBIN		= ./sbin
SHARE		= ./share
STRINGS		= ./strings
TEMPLATES	= ./templates
VSAPCONFIG	= ./modules/VSAP-Server-Modules/vsapd.conf
VSAPD		= ./vsapd/vsapd

CPXCONF		= /usr/local/etc/cpx.conf
CPXLOCALSHARE	= /usr/local/share/cpx

RSYNC_DRYRUN	= --dry-run
RSYNC_OPTIONS	= --archive --checksum --verbose --cvs-exclude

APTGET		= /usr/bin/apt-get
SERVICE		= /sbin/service
CHKCONFIG	= /sbin/chkconfig

PLATFORM	= $(shell uname)
DISTRO		= none

ifeq ($(PLATFORM), Linux)
	ifneq ("$(wildcard $(SERVICE))","")
		DISTRO		= rhel
	else ifneq ("$(wildcard $(APTGET))","")
		DISTRO		= debian
	else
		DISTRO		= unknown
	endif
endif

##############################################################################

all:
	@echo
	@echo "Select an action:"
	@echo
	@echo "  make check[-SOURCE]"
	@echo "    - check source against target and displays differences via rsync"
	@echo "    - optional [-SOURCE] can be any of the available sources (except 'modules')"
	@echo
	@echo "  make clean"
	@echo "    - removes all traces of program (except $(CPXCONF))"
	@echo
	@echo "  make create"
	@echo "    - makes the target directory tree ($(TARGET))"
	@echo
	@echo "  make install[-SOURCE]"
	@echo "    - installs opencpx source directory tree to ($(TARGET))"
	@echo "    - optional [-SOURCE] can be any of the available sources (see below)"
	@echo
	@echo "  make restart"
	@echo "    - restart apache and vsapd"
	@echo
	@echo "  make tar"
	@echo "    - creates opencpx tar archive from target ($(TARGET))"
	@echo
	@echo "  make test[-SOURCE]"
	@echo "    - tests XML/XSLT syntax"
	@echo "    - optional [-SOURCE] can be either 'help', 'strings', or 'templates'"
	@echo "    - e.g. 'make test-help', 'make test-strings', or 'make test-templates'"
	@echo
	@echo "  make uninstall"
	@echo "    - removes all traces of program (including $(CPXCONF))"
	@echo
	@echo "-----------------------------------"
	@echo
	@echo "  Available sources:"
	@echo
	@echo "    bin"
	@echo "    etc"
	@echo "    help"
	@echo "    images"
	@echo "    modules"
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

check-all:	check-bin check-etc check-help check-images check-sbin \
		check-share check-strings check-templates

check-bin:
	@echo "#### checking bin ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(BIN) $(TARGET)
	@echo

check-etc:
	@echo "#### checking etc ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(ETC) $(TARGET)
	@echo "#### checking vsapd.conf ..............."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(VSAPCONFIG) $(TARGET)$(ETC)
	@echo

check-help:
	@echo "#### checking help ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) --delete $(HELP) $(TARGET)
	@echo

check-images:
	@echo "#### checking images ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) --delete $(IMAGES) $(TARGET)
	@echo

check-sbin:
	@echo "#### checking sbin ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(SBIN) $(TARGET)
	@echo "#### checking vsapd ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(VSAPD) $(TARGET)$(SBIN)
	@echo

check-share:
	@echo "#### checking cp/share ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(SHARE) $(TARGET)
	@echo "#### checking local/share ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) $(SHARE)/ $(CPXLOCALSHARE)
	@echo

check-strings:
	@echo "#### checking strings ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) --exclude="doc" --exclude="utils" --delete $(STRINGS) $(TARGET)
	@echo

check-templates:
	@echo "#### checking templates ...................."
	@rsync $(RSYNC_DRYRUN) $(RSYNC_OPTIONS) --delete $(TEMPLATES) $(TARGET)
	@echo

##############################################################################

clean:		clean-etc
	@echo "#### cleaning $(MODULES)"
	@(cd $(MODULES); \
	for module in `ls -1`; \
	do \
		cd $$module; \
		makefile=Makefile; \
		if [ -e $$makefile ]; then \
			make clean >/dev/null; \
			rm -f Makefile.old; \
		fi; \
		cd ..; \
	done)
	@echo "#### removing $(TARGET)"
	@echo "#### removing $(CPXLOCALSHARE)"
	@(rm -rf $(TARGET); \
	rm -rf $(CPXLOCALSHARE));

clean-etc:
	@echo "#### FIX ME: need to uninstall perl_opencpx.conf"
	@echo "#### FIX ME: need to uninstall firewall rules?"
	@echo "#### FIX ME: need to uninstall init script"
	@echo "#### FIX ME: need to uninstall init run levels"

##############################################################################

create:
	@if [ ! -d $(TARGET) ]; then \
		echo "Creating $(TARGET) directory..."; \
		mkdir -p $(TARGET); \
		mkdir -p $(TARGET)$(BIN); \
		mkdir -p $(TARGET)$(ETC); \
		mkdir -p $(TARGET)$(HELP); \
		mkdir -p $(TARGET)$(IMAGES); \
		mkdir -p $(TARGET)$(LIB); \
		mkdir -p $(TARGET)$(SBIN); \
		mkdir -p $(TARGET)$(SHARE); \
		mkdir -p $(TARGET)$(STRINGS); \
		mkdir -p $(TARGET)$(TEMPLATES); \
	fi

##############################################################################

install:	install-all

install-all:	install-bin install-etc install-help install-images \
		install-modules install-release install-sbin \
		install-share install-strings install-templates

install-bin:		create
	@echo "#### syncing bin ...................."
	@rsync --checksum $(RSYNC_OPTIONS) $(BIN) $(TARGET)
	@echo

install-etc:		create
	@echo "#### checking etc ...................."
	@rsync $(RSYNC_OPTIONS) $(ETC) $(TARGET)
	@echo "#### syncing vsapd.conf ..............."
	@rsync $(RSYNC_OPTIONS) $(VSAPCONFIG) $(TARGET)$(ETC)
	@echo "#### installing opencpx.conf ..............."
ifeq ($(PLATFORM), FreeBSD)
	@cp -p /usr/local/cp/etc/conf.d/opencpx.conf /usr/local/apache2/conf.d/perl_opencpx.conf
else ifeq ($(DISTRO), debian)
	@cp -p /usr/local/cp/etc/conf.d/opencpx.conf /usr/local/apache2/conf.d/perl_opencpx.conf
else ifeq ($(DISTRO), rhel)
	@cp -p /usr/local/cp/etc/conf.d/opencpx.conf /etc/httpd/conf.d/perl_opencpx.conf
endif
	@echo "#### installing iptables ..............."
	@cp -p /usr/local/cp/etc/fwlevels/DEFAULT /etc/sysconfig/iptables
ifeq ($(PLATFORM), FreeBSD)
	@echo "#### installing init script ..............."
	@cp -p /usr/local/cp/etc/rc.d/vsapd.sh /usr/local/etc/rc.d/vsapd.sh
else ifneq ("$(wildcard $(CHKCONFIG))","")
	@echo "#### installing init script ..............."
	@cp -p /usr/local/cp/etc/rc.d/init.d/vsapd /etc/init.d/vsapd
	@echo "#### running chkconfig to add service ..............."
	@$(CHKCONFIG) --add vsapd
else
	@echo "#### installing init script ..............."
	@cp -p /usr/local/cp/etc/rc.d/init.d/vsapd /etc/init.d/vsapd
	@echo "#### adding vsapd to run levels ..............."
	for i in 2 3 4 5; do
		ln -sf /etc/init.d/vsapd /etc/rc.d/rc${i}.d/S46vsapd
	done
	for i in 1 6; do
		ln -sf /etc/init.d/vsapd /etc/rc.d/rc${i}.d/K64vsapd
	done
endif
	@echo

install-help:	create
	@echo "#### syncing help ...................."
	@rsync $(RSYNC_OPTIONS) --delete $(HELP) $(TARGET)
	@(cd $(TARGET)/help; \
	for lang in `ls -1`; \
	do \
		langlink=`echo $$lang | sed -e 's|_.*||'`; \
		if [ -d $$lang -a ! -e $$langlink ]; then \
			echo "Creating link for $$lang -> $$langlink"; \
			ln -s $$lang $$langlink; \
		fi; \
	done)
	@echo

install-images:		create link-images
	@echo "#### syncing images ...................."
	@rsync $(RSYNC_OPTIONS) --delete $(IMAGES) $(TARGET)
	@echo

install-modules:	create
	@echo "#### installing modules ...................."
	@(cd $(MODULES); \
	for module in `ls -1`; \
	do \
		cd $$module; \
		makefile=Makefile; \
		if [ ! -e $$makefile ]; then \
			echo "	building $$module"; \
			perl Makefile.PL LIB=/usr/local/cp/lib/ >/dev/null; \
			make >/dev/null; \
			make install >/dev/null; \
			make clean >/dev/null; \
			rm -f Makefile.old; \
		else \
			echo "	installing $$module"; \
			make install >/dev/null; \
		fi; \
		cd ..; \
	done)
	@echo

install-release:	create
	@echo "#### syncing RELEASE ..............."
	@rsync $(RSYNC_OPTIONS) $(RELEASE) $(TARGET)
	@echo

install-share:		create
	@echo "#### syncing cp/share ..............."
	@rsync $(RSYNC_OPTIONS) $(SHARE) $(TARGET)
	@echo "#### syncing local/share ..............."
	@rsync $(RSYNC_OPTIONS) $(SHARE)/ $(CPXLOCALSHARE)
	@echo

install-sbin:		create
	@echo "#### syncing sbin ...................."
	@rsync $(RSYNC_OPTIONS) $(SBIN) $(TARGET)
	@echo
	@echo "#### syncing vsapd ...................."
	@rsync $(RSYNC_OPTIONS) $(VSAPD) $(TARGET)$(SBIN)
	@echo

install-strings:	create
	@echo "#### syncing strings ...................."
	@rsync $(RSYNC_OPTIONS) --exclude="doc" --exclude="utils" --delete $(STRINGS) $(TARGET)
	@(cd $(TARGET)/strings; \
	for lang in `ls -1`; \
	do \
		langlink=`echo $$lang | sed -e 's|_.*||'`; \
		if [ -d $$lang -a ! -e $$langlink ]; then \
			echo "Creating link for $$lang -> $$langlink"; \
			ln -s $$lang $$langlink; \
		fi; \
	done)
	@echo

install-templates:	create
	@echo "#### syncing templates ...................."
	@rsync $(RSYNC_OPTIONS) --delete $(TEMPLATES) $(TARGET)
	@echo

##############################################################################

link-images:
	@if [ ! -e $(TARGET)/images ]; then \
		echo "Creating image symlink..."; \
		cd $(TARGET) && ln -s cpimages/brandx images; \
	fi

##############################################################################

restart:
	@echo "#### restarting services ...................."
ifeq ($(PLATFORM), FreeBSD)
	/usr/local/etc/rc.d/apache.sh restart
	/usr/local/etc/rc.d/vsapd.sh restart
else ifeq ($(DISTRO), debian)
	$(SERVICE) vsapd restart
	$(SERVICE) apache2 restart
else ifeq ($(DISTRO), rhel)
	$(SERVICE) vsapd restart
	$(SERVICE) httpd restart
endif

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

uninstall:	clean
	@echo "#### removing $(CPXCONF)"
	@(rm -f $(CPXCONF))

##############################################################################

