#!/bin/sh -e

/usr/sbin/ipset -R -exist -f /usr/local/etc/chnroute.ipset
/usr/sbin/ipset -R -exist -f /usr/local/etc/chnroute6.ipset

exit 0
