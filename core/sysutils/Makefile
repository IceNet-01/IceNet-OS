# System Utilities Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11

TARGETS = icetop icefree icedf

.PHONY: all clean install

all: $(TARGETS)

icetop: icetop.c
	$(CC) $(CFLAGS) -o icetop icetop.c

icefree: icefree.c
	$(CC) $(CFLAGS) -o icefree icefree.c

icedf: icedf.c
	$(CC) $(CFLAGS) -o icedf icedf.c

clean:
	rm -f $(TARGETS) *.o

install: $(TARGETS)
	install -D -m 755 icetop $(DESTDIR)/usr/bin/icetop
	install -D -m 755 icefree $(DESTDIR)/usr/bin/icefree
	install -D -m 755 icedf $(DESTDIR)/usr/bin/icedf
	# Create common aliases
	ln -sf icetop $(DESTDIR)/usr/bin/top
	ln -sf icefree $(DESTDIR)/usr/bin/free
	ln -sf icedf $(DESTDIR)/usr/bin/df
