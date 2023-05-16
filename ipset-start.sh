#!/bin/sh -e

/usr/sbin/ipset -R -exist -f /usr/local/etc/chnroute.ipset
/usr/sbin/ipset -R -exist -f /usr/local/etc/chnroute6.ipset
/usr/sbin/ipset create chnip4 hash:net family inet
/usr/sbin/ipset create chnip6 hash:net family inet6
/usr/sbin/ipset create gfwip4 hash:net family inet
/usr/sbin/ipset create gfwip6 hash:net family inet6
exit 0
