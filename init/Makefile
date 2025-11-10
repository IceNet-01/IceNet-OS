# IceNet-Init Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -static
TARGET = icenet-init

.PHONY: all clean install

all: $(TARGET)

$(TARGET): icenet-init.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET) icenet-init.c

clean:
	rm -f $(TARGET) *.o

install: $(TARGET)
	install -D -m 755 $(TARGET) $(DESTDIR)/sbin/$(TARGET)

strip: $(TARGET)
	strip $(TARGET)
