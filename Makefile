CC = gcc
CFLAGS = -std=c99 -Wall -Wextra -O2
SRCS = chinadns.c dnsutils.c dnlutils.c netutils.c
OBJS = $(SRCS:.c=.o)
MAIN = chinadns-ng
DESTDIR = /usr/local/bin

.PHONY: all install clean

all: $(MAIN)

install: $(MAIN)
	mkdir -p $(DESTDIR)
	install -m 0755 $(MAIN) $(DESTDIR)

clean:
	$(RM) *.o $(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) -s -o $(MAIN) $(OBJS)

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
