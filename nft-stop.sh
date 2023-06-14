#!/bin/sh

/usr/sbin/nft list set inet nat chnip4 > /usr/local/etc/chnip4.nftset
/usr/sbin/nft list set inet nat chnip6 > /usr/local/etc/chnip6.nftset
/usr/sbin/nft list set inet nat gfwip4 > /usr/local/etc/gfwip4.nftset
/usr/sbin/nft list set inet nat gfwip6 > /usr/local/etc/gfwip6.nftset

/usr/sbin/nft flush set inet global chnroute
/usr/sbin/nft flush set inet global chnroute6
/usr/sbin/nft flush set inet nat chnip4
/usr/sbin/nft flush set inet nat chnip6
/usr/sbin/nft flush set inet nat gfwip4
/usr/sbin/nft flush set inet nat gfwip6

exit 0
