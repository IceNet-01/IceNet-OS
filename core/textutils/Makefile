# Text Utilities Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11

TARGETS = icecat icegrep

.PHONY: all clean install

all: $(TARGETS)

icecat: icecat.c
	$(CC) $(CFLAGS) -o icecat icecat.c

icegrep: icegrep.c
	$(CC) $(CFLAGS) -o icegrep icegrep.c

clean:
	rm -f $(TARGETS) *.o

install: $(TARGETS)
	install -D -m 755 icecat $(DESTDIR)/usr/bin/icecat
	install -D -m 755 icegrep $(DESTDIR)/usr/bin/icegrep
	ln -sf icecat $(DESTDIR)/usr/bin/cat
	ln -sf icegrep $(DESTDIR)/usr/bin/grep
