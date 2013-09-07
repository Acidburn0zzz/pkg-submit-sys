DESTDIR :=
PREFIX := /usr
BINDIR := $(PREFIX)/bin
SYSCONFDIR := /etc

GETOPT := /usr/local/bin/getopt

all: user-bin/repo-send
	@echo "Done"

install: user-bin/repo-send
	install -dm755 $(DESTDIR)$(BINDIR)
	install -m755 user-bin/repo-send $(DESTDIR)$(BINDIR)/repo-send
	install -dm755 $(DESTDIR)$(SYSCONFDIR)
	install -m644 absd-repo-send.conf $(DESTDIR)$(SYSCONFDIR)/absd-repo-send.conf

user-bin/repo-send: user-bin/repo-send.in
	sed -e 's|%%SYSCONFDIR%%|$(SYSCONFDIR)|g' \
	    -e 's|%%GETOPT%%|$(GETOPT)|g' \
	    $*.in > $@

clean:
	rm user-bin/repo-send
