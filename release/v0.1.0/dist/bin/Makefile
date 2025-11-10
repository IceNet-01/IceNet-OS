# Scripts Makefile

SCRIPTS = icenet-network icenet-sysinfo

.PHONY: all clean install

all:
	@echo "Scripts ready for installation"

clean:
	@echo "Nothing to clean"

install:
	install -D -m 755 icenet-network $(DESTDIR)/usr/bin/icenet-network
	install -D -m 755 icenet-sysinfo $(DESTDIR)/usr/bin/icenet-sysinfo
	# Create convenience aliases
	ln -sf icenet-sysinfo $(DESTDIR)/usr/bin/sysinfo
