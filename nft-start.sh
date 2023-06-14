#!/bin/bash

NFT=/usr/sbin/nft

$NFT flush set inet global chnroute
$NFT flush set inet global chnroute6
$NFT -f /usr/local/etc/chnroute.nftset
$NFT -f /usr/local/etc/chnroute6.nftset

[[ -f /usr/local/etc/chnip4.nftset ]] && $NFT -f /usr/local/etc/chnip4.nftset 
[[ -f /usr/local/etc/chnip6.nftset ]] && $NFT -f /usr/local/etc/chnip6.nftset 
[[ -f /usr/local/etc/gfwip4.nftset ]] && $NFT -f /usr/local/etc/gfwip4.nftset 
[[ -f /usr/local/etc/gfwip6.nftset ]] && $NFT -f /usr/local/etc/gfwip6.nftset 

exit 0
