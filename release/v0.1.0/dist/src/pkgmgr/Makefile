# ice-pkg Package Manager Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -lcurl
TARGET = ice-pkg

.PHONY: all clean install

all: $(TARGET)

$(TARGET): ice-pkg.c
	$(CC) $(CFLAGS) -o $(TARGET) ice-pkg.c $(LDFLAGS)

clean:
	rm -f $(TARGET) *.o

install: $(TARGET)
	install -D -m 755 $(TARGET) $(DESTDIR)/usr/bin/$(TARGET)

strip: $(TARGET)
	strip $(TARGET)
