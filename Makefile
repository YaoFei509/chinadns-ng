CC = gcc

ifeq ($(findstring clang,$(shell $(CC) --version)),)
	LTOFLAGS = -flto -flto-partition=none
else
	LTOFLAGS = -flto
endif

ifdef DEBUG
	CFLAGS = -pipe -std=c99 -Wall -Wextra -Wvla -Og -fno-pie -fno-PIE -ggdb3
	LDFLAGS = -pipe -no-pie
	ifneq ($(DEBUG),1)
		CFLAGS += -DDEBUG
	endif
else
	CFLAGS = -pipe -std=c99 -Wall -Wextra -Wvla -O3 $(LTOFLAGS) -fno-pie -fno-PIE -DNDEBUG
	LDFLAGS = -pipe -no-pie -O3 $(LTOFLAGS) -s
endif

ifdef STATIC
	LDFLAGS += -static
endif

ifdef LDDIRS
	LDFLAGS += $(LDDIRS)
endif

SRCS = main.c opt.c dns.c dnl.c net.c ipset.c nl.c
OBJS = $(SRCS:.c=.o)
LDLIBS =
MAIN = chinadns-ng
DESTDIR = /usr/local/bin

.PHONY: all install uninstall clean

all: $(MAIN)

install: $(MAIN)
	install -d $(DESTDIR)
	install -m 0755 $(MAIN) $(DESTDIR)
	install -m 0755 ipset-*.sh nft-*.sh $(DESTDIR)
	cp chinadns-ng.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable --now chinadns-ng.service
	cp nftables.conf /etc

uninstall:
	$(RM) $(DESTDIR)/$(MAIN)
	$(RM) $(DESTDIR)/ipset-*.sh
	$(RM) $(DESTDIR)/net-*.sh

clean:
	$(RM) *.o *.gch $(MAIN)

.c.o:
	$(CC) $(CFLAGS) -c -o $@ $<

$(MAIN): $(OBJS)
	$(CC) $(LDFLAGS) -o $(MAIN) $(OBJS) $(LDLIBS)

update: export HTTPS_PROXY = socks5h://127.0.0.1:1080

update: 
	./res/update-chnlist.sh
	./res/update-chnroute6-nft.sh
	./res/update-chnroute-nft.sh
	./res/update-gfwlist.sh
	sudo cp res/*.nftset res/*.txt /usr/local/etc
	sudo systemctl restart chinadns-ng
