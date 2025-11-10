# Network Utilities Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS_CURL = -lcurl

TARGETS = iceping icenetstat icedownload

.PHONY: all clean install

all: $(TARGETS)

iceping: iceping.c
	$(CC) $(CFLAGS) -o iceping iceping.c

icenetstat: icenetstat.c
	$(CC) $(CFLAGS) -o icenetstat icenetstat.c

icedownload: icedownload.c
	$(CC) $(CFLAGS) -o icedownload icedownload.c $(LDFLAGS_CURL)

clean:
	rm -f $(TARGETS) *.o

install: $(TARGETS)
	install -D -m 755 iceping $(DESTDIR)/usr/bin/iceping
	install -D -m 755 icenetstat $(DESTDIR)/usr/bin/icenetstat
	install -D -m 755 icedownload $(DESTDIR)/usr/bin/icedownload
	# Create common aliases
	ln -sf iceping $(DESTDIR)/usr/bin/ping
	ln -sf icenetstat $(DESTDIR)/usr/bin/netstat
	ln -sf icedownload $(DESTDIR)/usr/bin/wget
