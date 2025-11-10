# IceNet-OS Core Utilities
# Main Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -static

SUBDIRS = fileutils netutils sysutils textutils scripts

.PHONY: all clean install $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	rm -rf bin

install:
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir install; done
