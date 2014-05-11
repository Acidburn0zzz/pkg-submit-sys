DESTDIR :=
PREFIX := /usr
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib
SYSCONFDIR := /etc

GETOPT := /usr/local/bin/getopt

USER_SCRIPTS := user-bin/repo-send.sh \
                user-bin/repo-command.sh \
                user-lib/common.bash.sh

all: $(USER_SCRIPTS)
	@echo "Done"

install: $(USER_SCRIPTS)
	install -dm755 $(DESTDIR)$(BINDIR)
	install -m755 user-bin/repo-send.sh $(DESTDIR)$(BINDIR)/repo-send
	install -m755 user-bin/repo-command.sh $(DESTDIR)$(BINDIR)/repo-command
	install -dm755 $(DESTDIR)$(SYSCONFDIR)/absd-utils
	install -dm755 $(DESTDIR)$(LIBDIR)/absd-utils
	install -m644 etc/repo-send.conf $(DESTDIR)$(LIBDIR)/absd-utils/repo-send.conf
	install -m644 user-lib/common.bash.sh $(DESTDIR)$(LIBDIR)/absd-utils/common.bash

.SUFFIXES:
.SUFFIXES: .sh .in
.in.sh:
	sed -e 's|%%SYSCONFDIR%%|$(SYSCONFDIR)|g' \
	    -e 's|%%PREFIX%%|$(PREFIX)|g' \
	    -e 's|%%LIBDIR%%|$(LIBDIR)|g' \
	    -e 's|%%GETOPT%%|$(GETOPT)|g' \
	    $< > $@

clean:
	rm -f $(USER_SCRIPTS)
