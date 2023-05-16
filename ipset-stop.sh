#!/bin/sh -e

/usr/sbin/ipset -F chnroute
/usr/sbin/ipset -F chnroute6
/usr/sbin/ipset save chnip4 -f /usr/local/etc/chnip4.ipset
/usr/sbin/ipset save chnip6 -f /usr/local/etc/chnip6.ipset
/usr/sbin/ipset save gfwip4 -f /usr/local/etc/gfwip4.ipset
/usr/sbin/ipset save gfwip6 -f /usr/local/etc/gfwip6.ipset

exit 0
