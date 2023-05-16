#!/bin/sh -e

/usr/sbin/ipset -F chnroute
/usr/sbin/ipset -F chnroute6
/usr/sbin/ipset save chnip4 -f /home/yaofei/chnip4.ipset
/usr/sbin/ipset save chnip6 -f /home/yaofei/chnip6.ipset
/usr/sbin/ipset save gfwip4 -f /home/yaofei/gfwip4.ipset
/usr/sbin/ipset save gfwip6 -f /home/yaofei/gfwip6.ipset

exit 0
