#!/bin/bash

IPSET=/usr/sbin/ipset

$IPSET -R -exist -f /usr/local/etc/chnroute.ipset
$IPSET -R -exist -f /usr/local/etc/chnroute6.ipset
[[ -f /usr/local/etc/chnip6.ipset ]] && $IPSET -R -exist -f /usr/local/etc/chnip6.ipset  || $IPSET create chnip6 hash:net family inet6
[[ -f /usr/local/etc/chnip4.ipset ]] && $IPSET -R -exist -f /usr/local/etc/chnip4.ipset  || $IPSET create chnip4 hash:net family inet
[[ -f /usr/local/etc/gfwip6.ipset ]] && $IPSET -R -exist -f /usr/local/etc/gfwip6.ipset  || $IPSET create gfwip6 hash:net family inet6
[[ -f /usr/local/etc/gfwip4.ipset ]] && $IPSET -R -exist -f /usr/local/etc/gfwip4.ipset  || $IPSET create gfwip4 hash:net family inet
exit 0
