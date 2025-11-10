# File Utilities Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11

TARGETS = icels

.PHONY: all clean install

all: $(TARGETS)

icels: icels.c
	$(CC) $(CFLAGS) -o icels icels.c

clean:
	rm -f $(TARGETS) *.o

install: $(TARGETS)
	install -D -m 755 icels $(DESTDIR)/usr/bin/icels
	ln -sf icels $(DESTDIR)/usr/bin/ls
