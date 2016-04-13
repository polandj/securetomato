#!/bin/sh

## Modified from Clean, Lean and Mean Adblock v4.5 by haarp
##
## http://www.linksysinfo.org/index.php?threads/script-clean-lean-and-mean-adblocking.68464/
##
## Use at your own risk
##
## See adblock.readme for release notes
##

umask 0022

alias iptables='/usr/sbin/iptables'
alias nslookup='/usr/bin/nslookup'
alias ls='/bin/ls'
alias df='/bin/df'
alias ifconfig='/sbin/ifconfig'

pidfile=/var/run/adblock.pid

release="2015-11-11"

# buffer for log messages in firemode
msgqueue=""

# router memory
ram=$(awk '/^MemTotal/ {print int($2/1024)}' < /proc/meminfo)

# this script
me="$(cd $(dirname "$0") && pwd)/${0##*/}"

[ "${me##*"."}" = "fire" ] && firemode=1

# path to script -  was script called via an autorun link?
if [ "${me##*"."}" = "fire" -o "${me##*"."}" = "wanup" -o  "${me##*"."}" = "shut" ]; then
	# yes - find true script folder
 	s="$( ls -l "$me" )"; s="${s##*" -> "}"
	binprefix="$(cd "$(dirname "$me")" && cd "$(dirname "$s")" && pwd)"
	adblockscript="$binprefix/${s##*"/"}"
	islink=1
else
	# no -  use folder of $me
	binprefix="$(dirname "$me")"
	adblockscript="$me"
	islink=0
fi

#########################################################
#							#
# Default values - can be changed in config file.	#
#							#
#########################################################

# Possible places to store our stuff
freetmp=$(df "/tmp" | awk '!/Filesys/{print int($4/1024)}')
prefixlist="/mnt/* /mmc/* /jffs"
prefix=/var/lib
for p in $prefixlist; do
	df=$(df "$p" 2> /dev/null | awk '!/File/{print int($4/1024)}')
	[ "$df" == "" ] && df=0
	if [ -d "$p/adblock" ]; then
		prefix=$p
	elif [ "$df" -gt "$(($freetmp/3))" ]; then
		prefix=$p
	fi
done

# path to list files
prefix=$prefix/adblock

# pixelserv executable
pixelbin=$binprefix/pixelserv-tls

# temp folder for stripped white/blacklist
tmp=/tmp

# what to consider a small disk in MB
smalldisk=64

# what to consider a small tmp folder in MB
smalltmp=24

# firewall autorun script
fire=/etc/config/99.adblock.fire

# shutdown autorun script
shut=/etc/config/00.adblock.shut

# hosts file link
hostlink=/etc/dnsmasq/hosts/zzz.adblock.hosts

# virtual interface name, should be unique enough to avoid grep overmatching
vif=adblk

# iptables chain name, should be unique enough to avoid grep overmatching
chain=adblk.fw

# testhost
testhost="adblock.is.loaded"

# modehost
modehost="mode.is.loaded"

# listtmp set to /tmp folder for blocklist generation to reduce writes to jffs/usb if more than 64MB ram
# defaults to previous behavior if less ram, or can be set explicitly in config
listtmp=""

# list of generated source files
sourcelistfile=$tmp/sourcelist.$$.tmp

# default cron schedule standard cru format: min hour day month week
SCHEDULE="$(nvram get malad_cron)"
[ "$SCHEDULE" = "" ] && SCHEDULE="55 04 1 * *" 
cronid=adblock.update

# minimum age of blocklist in hours before we re-build
age2update=12

# don't output log for firewall mode
quietfire=1

# path to dnsmasq.conf
dnsmasq_config="/etc/dnsmasq.conf"

# enable logging - a value of "1" will add "log-queries" to $CONF
# and restart dnsmasq if necessary
#
# has no effect if logging is already enabled in dnsmasq.conf
dnsmasq_logqueries=""

# !**** CAUTION ****!
# dnsmasq_custom - use at your own risk
#
# value will be appended to $CONF as entered
#
# example:
# dnsmasq_custom='
# log-facility=/tmp/mylogfile
# log-dhcp
# log-queries
# local-ttl=600
# '
#
# !! do not use unless you know what you are doing !!
#
# dnsmasq is very sensitive and will not start with invalid entries, entries
# that conflict with directives in the primary config, and some duplicated
# entries
#
# no validation of the content is performed by adblock
#
# !**** CAUTION ****!
dnsmasq_custom="
local-ttl=600
"

# additional options for wget
wget_opts=""

# list mode
LISTMODE="OPTIMIZE"

# default to using primary lan interface
BRIDGE="$(nvram get lan_ifname)"

# default to strict firewall rules
FWRULES=STRICT

# default interface(s) for firewall rules
# supports multiple interfaces as well, ie: "br0 br1 br3"
FWBRIDGE="br+ lo"

# set haarp config defaults - config file overrides
# 0: disable pixelserv, 1-254: last octet of IP to run pixelserv on
[ "$(nvram get malad_mode)" != "" ] && PIXEL_IP=0 || PIXEL_IP=254

# let system determin pixelserv ip based on PIXEL_IP and existing
redirip=""

# additional options for pixelserv
PIXEL_CERTS="$prefix/certs"
PIXEL_OPTS="-l -z $PIXEL_CERTS"

# 1: keep blocklist in RAM (e.g. for small JFFS)
RAMLIST=0

# dnsmasq custom config (must be sourced by dnsmasq!) confused? then leave this be!
CONF=/etc/dnsmasq.custom

# whitelist and blacklist contents
BLACKLIST="$(nvram get malad_bkl)"
WHITELIST="$(nvram get malad_wtl)"

# Default data sources
SOURCES=""
XTRA_SOURCES="$(nvram get malad_xtra)"
for name in $(echo "$XTRA_SOURCES" | awk 'BEGIN{FS=">"}{print $1,$NF;}'); do
        enabled=$(echo "$name" | cut -d "<" -f 1)
        url=$(echo "$name" | cut -d "<" -f 2)
        if [ $enabled = "1" ]; then
                SOURCES="$SOURCES $url"
        fi
done
DFLT_SOURCES="http://adaway.org/hosts.txt"
DFLT_SOURCES="$DFLT_SOURCES http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext"
DFLT_SOURCES="$DFLT_SOURCES http://winhelp2002.mvps.org/hosts.txt"
DFLT_SOURCES="$DFLT_SOURCES http://someonewhocares.org/hosts/hosts"
DFLT_SOURCES="$DFLT_SOURCES http://www.malwaredomainlist.com/hostslist/hosts.txt"
DFLT_SOURCES="$DFLT_SOURCES http://adblock.gjtech.net/?format=unix-hosts"
DFLT_SOURCES="$DFLT_SOURCES http://hosts-file.net/ad_servers.txt"
for s in $DFLT_SOURCES; do
        md5abbrev="$(echo -n $s | md5sum | cut -c 1-8)"
        if ! echo $(nvram get malad_dflt) | grep -qi $md5abbrev; then
                SOURCES="$SOURCES $s"
        fi
done

# SSL CA
CA_CRT="$(nvram get malad_cacrt)"
CA_KEY="$(nvram get malad_cakey)"

STATUS_FILE="$prefix/STATUS"

#########################################################
# End of default values					#
#########################################################

elog() {
 local tag="ADBLOCK[$$]"
 local myline
 local pad="                    "
 local len=${2:-"0"}
 pad=${pad:0:$len}

 local p1=${1:-"-"}
 echo "$1" > $STATUS_FILE

 [ "$firemode" = "1" ] && {
   [ "$p1" = "-" ] &&  {
     [ -t 0 ] || while read myline; do msgqueue="$msgqueue""$pad$myline\n" ; done
   } || msgqueue="$msgqueue""$pad$p1\n"
 } || {
   [ "$p1" = "-" ] && {
     [ -t 0 ] || while read myline; do logger -st "$tag" "$pad$myline"; done
   } || logger -st "$tag" "$pad$p1"
 }
}

flushlog() {
# display queue and disable fire modes
 [ "$msgqueue" != "" ] && {
	firemode=0
	[ "$msgqueue" != "" ] && echo -ne "$msgqueue" | elog
	msgqueue=""
 }
}

pexit() {
	flushlog
	elog "Exiting $me $@"
	rm -f "$pidfile" &>/dev/null
	logvars2
	exit $@
}

logfw() {
	elog "iptables"
	{ echo -e "filter\n========================================================================"
	  iptables -vnL
	  echo -e "\nnat\n========================================================================"
	  iptables -vnL -t nat
	  echo -e "\nmangle\n========================================================================"
          iptables -vnL -t mangle
	} | elog - 4
}

logvars() {
	[ "$debug" != "1" ] && return
	elog "Running on $( nvram get os_version )"
	elog "PID  $(ps -w | grep $$ | grep -v grep) SHLVL $SHLVL"
	elog "PPID $(ps -w | grep $PPID | grep -v grep)"
	elog "Initialized Environment:"
	set | elog - 4
	elog "Mounted Drives"
	mount | elog - 4
	elog "Free Space"
	df -h | elog - 4
	elog "prefix folder - $prefix"
	ls -lh $prefix | elog - 4
	elog "listprefix folder - $listprefix"
	ls -lh $listprefix | elog - 4
	elog "listtmp folder - $listtmp"
	ls -lh $listtmp | elog - 4
	logfw
}

logvars2() {
	[ "$debug" != "1" ] && return
	elog "Environment at exit:"
	elog "Free Space"
	df -h | elog - 4
	elog "prefix folder - $prefix"
	ls -lh $prefix | elog - 4
	elog "listprefix folder - $listprefix"
	ls -lh $listprefix | elog - 4
	elog "listtmp folder - $listtmp"
	ls -lh $listtmp | elog - 4
	elog "blocklist contents - $blocklist"
	head $blocklist | elog - 4
	elog "    ..."
	tail -n2 $blocklist | elog - 4
	elog "CONF contents - $CONF"
	cat $CONF | elog - 4
	logfw
}

readdnsmasq() {
	[ "$3" != "r" ] && loopcheck=""
	loopcheck="$loopcheck ""$1"
	for c in $( head -n 100 $1 | sed 's/#.*$//g' | sed -e 's/^[ \t]*//' 2> /dev/null )
	do
		l="${c%=*}"
		r="${c#*=}"
		case "$l" in
		$2 )
		echo "$r"
      		;;
		conf-file )
		if ! echo $loopcheck | grep "$r " ; then
			readdnsmasq "$r" "$2" "r"
		fi
		;;
		esac
	done
}

startserver() {
	if [ "$PIXEL_IP" != "0" ]; then
		[ -d $PIXEL_CERTS ] || mkdir $PIXEL_CERTS
		[ "$CA_CRT" = "" ] || echo "$CA_CRT" > $PIXEL_CERTS/ca.crt
		[ "$CA_KEY" = "" ] || echo "$CA_KEY" > $PIXEL_CERTS/ca.key

		if ! ifconfig | grep -q $BRIDGE:$vif; then
			elog "Setting up $rediripandmask on $BRIDGE:$vif"
			ifconfig $BRIDGE:$vif $rediripandmask up
		fi
		if ps -w | grep -v grep | grep -q "${pixelbin##*"/"} $redirip"; then
			elog "pixelserv already running, skipping"
		else
			elog "Setting up pixelserv on $redirip"
			"$pixelbin" $redirip $PIXEL_OPTS 2>&1 | elog
		fi
		# create autorun links
		[ -d /etc/config ] || mkdir /etc/config
		[ $islink = 0 ] && ln -sf "$me" "$fire"
		[ $islink = 0 ] && ln -sf "$me" "$shut"
	else
		# something odd has happened if we need this, but better safe...
		rm -f "$fire" &>/dev/null
		rm -f "$shut" &>/dev/null
		stopserver
	fi
	fire
}

stopserver() {
	killall pixelserv-tls
	ifconfig $BRIDGE:$vif down
} &> /dev/null

rmfiles() {
	{
		rm -f "$fire"
		rm -f "$shut"
		rm -f "$hostlink"
		rm -f "$tmpstatus"
	} &>/dev/null
	CONFchanged=0
	if [ -e "$CONF" ]; then
		local CONFmd51=$(md5sum "$CONF" 2>/dev/null)
		echo -n > "$CONF"
		local CONFmd52=$(md5sum "$CONF" 2>/dev/null)
		if [ "$CONFmd51" = "$CONFmd52" ]; then
			elog "CONF file $CONF unchanged"
		else
			CONFchanged=1
			elog "CONF file $CONF truncated"
		fi
	fi
}

stop() {
	elog "Stopping"
	rmfiles
	stopserver
	cleanfire
	restartdns
	currentmode="OFF"
}

restartdns() {
	[ $LISTMODE = "HOST" ] &&  [ "$logging" = "$dnsmasq_logqueries" ] && [ "$CONFchanged" != "1" ] && {
		[ $currentmode = "HOST" -o $currentmode = "OFF" ] && {
			elog "Loading hosts file for dnsmasq"
			kill -HUP $( pidof dnsmasq )
			return
		}
	}
	elog "Restarting dnsmasq"
	service dnsmasq restart | elog
}

writeconf() {

	[ ! -e "$CONF" ] &&  echo -n > "$CONF"

	local CONFmd51=$(md5sum "$CONF" 2>/dev/null)
	echo -n > "$CONF"

	if [ ! -f $blocklist  -o ! -s $blocklist ]; then
		elog "Blocklist Missing or empty - REMOVING DNSMASQ FILES / ADBLOCK MAY BE DISABLED!"
		rm -f "$hostlink" &>/dev/null
		return
	fi

	if [ $LISTMODE = "HOST" ] ; then
		elog "Creating Hosts File Link $hostlink"
		if ! ln -sf "$blocklist" "$hostlink" ; then
			elog "Could not create host file link $hostlink"
			rm -f "$hostlink" &>/dev/null
			return
		fi
	else
		elog "Writing File $CONF"
		rm -f "$hostlink" &>/dev/null
		echo "conf-file=$blocklist" >> "$CONF"
	fi

	# enable logging if needed
	[ "$dnsmasq_logqueries" = "1" ] && echo "log-queries" >> "$CONF"

	# add custom dnsmasq settings
	[ "$dnsmasq_custom" != "" ] && echo "$dnsmasq_custom" >> "$CONF"

	local CONFmd52=$(md5sum "$CONF" 2>/dev/null)
	if [ "$CONFmd51" = "$CONFmd52" ]; then
		CONFchanged=0
		elog "CONF file $CONF unchanged"
	else
		CONFchanged=1
		elog "CONF file $CONF changed"
	fi
}

cleanfiles() {
	cru d $cronid
	stop
	elog "Cleaning files"
	rm -f $prefix/lastmod-* &> /dev/null
	rm -f $prefix/source-* &> /dev/null
	rm -f $prefix/ca.crt &> /dev/null
	rm -f $prefix/ca.key &> /dev/null
	rm -f $tmpstatus &> /dev/null
	rm -f $blocklist  &> /dev/null
	elog "The following files remain for manual removal:"
	ls -1Ad $me $listprefix/* $prefix/* 2>/dev/null| sort -u | elog - 4
}

shutdown() {
	rmfiles
	stopserver
}

fire() {
	cleanfire

	# Nothing to do if not running pixelserv
	[ "$PIXEL_IP" = "0" ] && return

	[ "$FWRULES" = "NONE" ] && return

	[ $(( $(nvram get log_in) & 1 )) = 1 ] && {
		drop=logdrop
		logreject=1
		limit=$(nvram get log_limit)
		[ $limit = 0 ] && limitstr="" || limitstr=" -m limit --limit $limit/m "
	} || {
		drop=DROP
		logreject=0
	}

	[ $(( $(nvram get log_in) & 2 )) = 2 ] && accept=logaccept || accept=ACCEPT

	vpnline=$( iptables --line-numbers -vnL INPUT | grep -Em1  "ACCEPT .* all.*(tun[0-9]|tap[0-9]).*0.0.0.0.*0.0.0.0/0" | cut -f 1 -d " ")
	stateline=$(iptables --line-numbers -vnL INPUT | grep -m1 "ACCEPT.*state.*RELATED,ESTABLISHED" | cut -f 1 -d" ")
	[ "$vpnline" != "" ] && [ "$vpnline" -lt "$stateline" ] && inputline="" || inputline=$(( stateline + 1 ))
	iptables -N $chain
	iptables -I INPUT $inputline -d $redirip -j $chain
	iptables -A $chain -m state --state INVALID -j DROP
	iptables -A $chain -m state --state RELATED,ESTABLISHED -j ACCEPT
	for i in $FWBRIDGE; do
		netstat -ltn | grep -q "$redirip:443" && {
			# we are listening for ssl, so let both 80 and 443 through
			iptables -A $chain -i $i -p tcp -m multiport --dports 443,80 -j $accept
		} || {
			# else only allow port 80 and redirect 443 (assumes pixelserv v32 or later)
			iptables -A $chain -i $i -p tcp --dport 80 -j $accept
			# comment following lines if v31 or earlier
			iptables -t nat -nL $chain &>/dev/null || {
				iptables -t nat -N $chain
				iptables -t nat -A PREROUTING -p tcp -d $redirip --dport 443 -j $chain
			}
			iptables -t nat -A $chain -i $i -p tcp -d $redirip --dport 443 -j DNAT --to $redirip:80
		}
		iptables -A $chain -i $i -p icmp --icmp-type echo-request  -j $accept
		[ $logreject = 1 ] && iptables -A $chain -i $i $limitstr -j LOG --log-prefix "REJECT " --log-macdecode --log-tcp-sequence --log-tcp-options --log-ip-option
		iptables -A $chain -i $i -p tcp -j REJECT --reject-with tcp-reset
		iptables -A $chain -i $i -p all -j REJECT --reject-with icmp-host-prohibited
	done
	[ "$FWRULES" = "STRICT" ] &&  iptables -A $chain -j $drop
}

cleanfire() {
	iptables -D INPUT "0$( iptables --line-numbers -vnL INPUT | grep -Fm1 "$chain" | cut -f 1 -d " ")" &>/dev/null
	iptables -F $chain &>/dev/null
	iptables -X $chain &>/dev/null

	iptables -t nat -D PREROUTING "0$( iptables --line-numbers -t nat -vnL PREROUTING | grep -Fm1 "$chain" | cut -f 1 -d " ")" &>/dev/null
	iptables -t nat -F $chain &>/dev/null
	iptables -t nat -X $chain &>/dev/null
}

grabsource() {
	local host=$(echo $1 | awk -F"/" '{print $3}')
	local path=$(echo $1 | awk -F"/" '{print substr($0, index($0,$4))}')
	local lastmod=$(echo -e "HEAD /$path HTTP/1.1\r\nHost: $host\r\n\r\n" | nc -w30 $host 80 | tr -d '\r' | grep "Last-Modified")

	local lmfile="$listprefix/lastmod-$(echo -n $1 | md5sum | cut -c 1-8)"
	local sourcefile="$listprefix/source-$(echo -n $1 | md5sum | cut -c 1-8)"
	local sourcesize=$(ls -l "$sourcefile" 2>/dev/null | awk '{ print int(($5/1024/1024) + 0.5) }')
	local freedisk=$(df "$prefix" | awk '!/File/{print int($4/1024)}')

	[ "$force" != "1" -a -f "$sourcefile" -a -n "$lastmod" -a "$lastmod" = "$(cat "$lmfile" 2>/dev/null)" ] && {
		elog "Unchanged: $1 ($lastmod)"
		echo -n "$sourcefile " >> "$sourcelistfile"
		echo 2 >>"$tmpstatus"
		return 2
	}

	# delete the source file we are replacing if larger than free space
	[ -s "$sourcefile" ] && [ "$freedisk" -le "$(( sourcesize + 1 ))" ] && {
		elog "removing $sourcefile size:$sourcesize free:$freedisk"
		rm -f "$sourcefile" &>/dev/null
	}

	elog "Downloading: $1"
	{
		if wget  $1 -O - $wget_opts ; then
			elog "Completed: $1"
			echo 0 >>"$tmpstatus"
		else
			elog "Failed: $1"
			echo 1 >>"$tmpstatus"
		fi
	} | tr -d "\r" | sed -e '/^[[:alnum:]:]/!d' | awk '{print $2}' | sed -e '/^localhost$/d' > "$sourcefile.$$.tmp"

	if [ -s "$sourcefile.$$.tmp" ]  ; then
		[ -n "$lastmod" ] && echo "$lastmod" > "$lmfile"
		mv -f "$sourcefile.$$.tmp" "$sourcefile"
		echo -n "$sourcefile " >> "$sourcelistfile"
	else
		rm -f "$sourcefile.$$.tmp" &>/dev/null
	fi
}

buildlist() {
	elog "Download starting"

	tmpstatus=$tmp/status.$$.tmp

	until ping -q -c1 google.com >/dev/null; do
		elog "Waiting for connectivity..."
		sleep 30
	done

	trap 'elog "Signal received, cancelling"; rm -f "$listprefix"/source-* "$listprefix"/lastmod-* "$tmpstatus" &>/dev/null; pexit 130' SIGQUIT SIGINT SIGTERM SIGHUP

	echo -n "" > "$tmpstatus"
	echo -n "" > "$sourcelistfile"
	for s in $SOURCES; do
		grabsource $s &
	done
	wait

	while read ret; do
		case "$ret" in
			0)	downloaded=1;;
			1)	failed=1;;
			2)	unchanged=1;;
		esac
	done < "$tmpstatus"
	rm "$tmpstatus"

	sourcelist=$(cat "$sourcelistfile")
	rm -f "$sourcelistfile" &>/dev/null

	trap - SIGQUIT SIGINT SIGTERM SIGHUP

	if [ -z "$sourcelist" ] && [ -n "$BLACKLIST" -o -s "$blacklist" ]; then
		elog "Processing blacklist only"
		confgen
	elif [ -z "$sourcelist" ]; then
		elog "No source files found"
		pexit 3
	elif [ "$downloaded" = "1" ]; then
		elog "Downloaded"
		confgen
	elif [ "$unchanged" = "1" ]; then
		elog "Filters unchanged"
		if [ ! -f "$blocklist" -o ! -s "$blocklist" ]; then
			elog "Blocklist does not exist"
			confgen
		elif [ "$LISTMODE" != "$currentmode" -a "$currentmode" != "OFF" ]; then
			elog "Mode changed"
			confgen
		elif [ "$LISTMODE" = "$currentmode" ]; then
			elog "Mode unchanged"
			# no changes to list and already running in current mode
			writeconf # re-write conf or link if needed
			# if no dnsmasq_custom changes, nothing else to do, so exit
			[ "$CONFchanged" = "0" ] && pexit 2
		fi
	else
		elog "Download failed"
		if [ -s "$blocklist" ] && [ ! -f "$CONF" -o ! -s "$CONF" -o  "$logging" != "$dnsmasq_logqueries" -o "$dnsmasq_custom" != "" ]; then #needlink
			:
		else pexit 3
		fi
	fi
}

confgen() {
	cg1=$(date +%s)
	elog "Generating $blocklist - $LISTMODE mode"
	tmpwhitelist="$tmp/whitelist.$$.tmp"
	tmpblocklist="$listtmp/blocklist.$$.tmp"

  	trap 'elog "Signal received, cancelling"; rm -f "$tmpwhitelist" "$tmpblocklist"  &>/dev/null; echo -n "" > "$blocklist"; pexit 140' SIGQUIT SIGINT SIGTERM SIGHUP

	{
		# only allow valid hostname characters
		echo "[^a-zA-Z0-9._-]+"

		if [ -f "$whitelist" ]; then
			# strip comments, blank lines, spaces and carriage returns from whitelist
			sed -e 's/#.*$//g;s/^[ |\t|\r]*//;/^$/d' "$whitelist" 2>/dev/null
		fi

		# add config file whitelist entries to temp file
		for w in $WHITELIST; do
			echo $w
		done

	}  > "$tmpwhitelist"

	{
		# use sourcefiles list (and not all files in folder which could have old/unwanted files)
		[ -n "$sourcelist" ] && cat $sourcelist | grep -Ev -f "$tmpwhitelist"

		rm -f "$tmpwhitelist" &>/dev/null

		[ -f "$blacklist" ] && {
			# strip comments, blank lines, spaces and carriage returns from blacklist
			sed -e 's/#.*$//g;s/^[ |\t|\r]*//;/^$/d' "$blacklist" 2>/dev/null
		}
		for b in $BLACKLIST; do
			echo "$b"
		done

		# add hosts to test if adblock is loaded
		echo $testhost

		echo $LISTMODE.$modehost

	}  > "$tmpblocklist"

	{
		# add header to blocklist, used to determine what mode the list was built for
		# do not alter format without adjusting the grep regex that tests the mode/ip
		echo "# adblock blocklist, MODE=$LISTMODE, IP=$redirip, generated $(date)"

		case $LISTMODE in
			HOST)
				sort -u  "$tmpblocklist" |
				sed -e "s:^:$redirip :"
			;;
			OPTIMIZE)
				sed -e :a -e 's/\([^\.]*\)\.\([^\.]*\)/\2#\1/;ta'  "$tmpblocklist" | sort |
  				awk -F '#' 'BEGIN{d = "%"} { if(index($0"#",d)!=1&&NF!=0){d=$0"#";print $0;} }' |
				sed -e :a -e 's/\([^#]*\)#\([^#]*\)/\2\.\1/;ta' -e "s/\(.*\)/address=\/\1\/$redirip/"
			;;
			LEGACY)
				sort -u  "$tmpblocklist" |
				sed  -e '/^$/d'  -e  "s/\(.*\)/address=\/\1\/$redirip/"
			;;
		esac
		hostcount=$(( $(wc -l < "$blocklist") - 1 ))
		echo "# $hostcount records"

 		rm -f "$tmpblocklist" &>/dev/null
		elog "Blocklist generated - $(( $(date +%s) - cg1 )) seconds"
		elog "$hostcount unique hosts to block"
	}  > "$blocklist"

  	trap -  SIGQUIT SIGINT SIGTERM SIGHUP

}

loadconfig() {
	# check prefix folder again - exit on fail this time
	[ -d "$prefix" ] || mkdir "$prefix" || {
		elog "Prefix folder ($prefix) does not exist and cannot be created"
        	pexit 12
	}
	
	#ensure tthe correct path
	cd "$prefix" &>/dev/null

	if [ "$PIXEL_IP" = "0" ]; then
		[ "$redirip" = "" ] && redirip="0.0.0.0"
	else
		[ "$redirip" = "" ] || {
			elog "PIXEL_IP should be \"0\" if redirip is set in config!"
			pexit 10
		}
		[ -x "$pixelbin" ] || {
			elog "$pixelbin not found/executable!"
			pexit 10
		}
	fi

	#########################################################
	# redirip can be explicitly set in the config file,	#
	# but make sure it is valid as no checks are done	#
	#							#
	# PIXEL_IP still needs to be set to non-zero for 	#
	# pixelserv to be started				#
	#########################################################
	[ "$redirip" = "" ] && {
		rediripandmask=$(ifconfig $BRIDGE | awk -F ' +|:' '/inet addr/{sub(/[0-9]*$/,'$PIXEL_IP',$4); print $4" netmask "$8}')
		redirip=${rediripandmask%% *}
	}

	# $FWRULES must be NONE, LOOSE, or STRICT, if value is unknown, default to STRICT
	FWRULES=$(echo $FWRULES | tr "[a-z]" "[A-Z]")
	echo $FWRULES | grep -Eq "(^NONE$|^LOOSE$|^STRICT$)" || {
		elog "Unknown FWRULES value ($FWRULES), using STRICT settings"
		FWRULES="STRICT"
	}

	# $LISTMODE must be LEGACY, OPTIMIZE, or HOST, if value is unknown, default to OPTIMIZE
	LISTMODE=$(echo $LISTMODE | tr "[a-z]" "[A-Z]")
	echo $LISTMODE | grep -Eq "(^LEGACY$|^OPTIMIZE$|^HOST$)" && {
		elog "Requested list mode is $LISTMODE"
	} || {
		elog "Unknown LISTMODE value ($LISTMODE), using OPTIMIZE settings"
		LISTMODE="OPTIMIZE"
	}

	if [ "$RAMLIST" = "1" ]; then
		listprefix="/var/lib/adblock"
	else
		listprefix="$prefix"
	fi

	[ -d "$listprefix" ] || mkdir "$listprefix" || {
		elog "Blocklist folder ($listprefix) does not exist and cannot be created"
		pexit 12
	}

	# Link /etc/adblock to prefix   
	if [ ! -L "/etc/adblock" ]; then                 
		if ! ln -sf "$listprefix" "/etc/adblock" ; then
			elog "Could not create adblock etc link to listprefix($listprefix)"
			rm -f /etc/adblock           
			return                                                  
		fi                       
	fi

	local freetmp=$(df "$tmp" | awk '!/Filesys/{print int($4/1024)}')
	# if listtmp hasn't been explicitly set and more than $smalltmp available on /tmp
	if [ "$listtmp" = "" -a "$freetmp" -gt "$smalltmp" ]; then
		# use /tmp for temp blocklist file
		listtmp=$tmp
	elif [ "$listtmp" = "" ]; then
		# if not set, default to legacy behavior for compatibility
		listtmp="$listprefix"
	else
		# if specified in config, make sure it's there
		[ -d "$listtmp" ] || mkdir "$listtmp" || {
			elog "Blocklist temp folder ($listtmp) does not exist and cannot be created"
			pexit 12
		}
	fi

	if [ "$dnsmasq_logqueries" = "1" ]; then
		elog "Enabling dnsmasq logging"
	fi

	if [ "$(readdnsmasq "$dnsmasq_config" "log-queries")" != "" ]; then
		logging=1
		elog "Logging previously enabled"
	fi

	local dnslogfile="$(readdnsmasq "$dnsmasq_config" "log-facility")"
	if [ "$dnsmasq_logqueries" = "1" -o "$logging" = "1" ]; then
		if [ "$dnslogfile" = "" ]; then
			if [ "$(nvram get log_file)" = 1 ]; then
				elog "Logging to syslog"
			else
				elog "Warning: dnsmasq logging to syslog, but syslog is disabled"
			fi
		else
			elog "Logging to $dnslogfile"
		fi
	fi

	currentmode=OFF
	nslookup $testhost &>/dev/null  && currentmode=UNKNOWN
	nslookup host.$modehost &>/dev/null && currentmode=HOST
	nslookup legacy.$modehost &>/dev/null && currentmode=LEGACY
	nslookup optimize.$modehost &>/dev/null && currentmode=OPTIMIZE

	blocklist="$listprefix/blocklist"
	whitelist="$prefix/whitelist"
	blacklist="$prefix/blacklist"

	thisconfig="$(echo "$SOURCES" | md5sum)"
	thisconfig="$thisconfig|$whitelist:$(date -r "$whitelist" 2>/dev/null)"
	thisconfig="$thisconfig|$blacklist:$(date -r "$blacklist" 2>/dev/null)"
	thisconfig="$thisconfig|$adblockscript:$(date -r "$adblockscript" 2>/dev/null)"
	lastconfig="$(cat "$prefix/lastmod-config" 2>/dev/null)"
}


elog "Running as $me $@"

loadconfig

# exit if another instance is running
kill -0 $(cat $pidfile 2>/dev/null) &>/dev/null && {
	flushlog
	elog "Another instance found ($pidfile - $(cat "$pidfile")), exiting!"
	exit 1
}

echo $$ > $pidfile

# called via .fire autorun link - reload firewall rules and exit
if [ "$me" = "$fire" ]; then
	elog "Updating iptables"
	startserver
	[ "$quietfire" = "1" ] && exit 0 || pexit 0 &> /dev/null
fi

flushlog

# called via .shut autorun link - execute shutdown
if [ "$me" = "$shut" ]; then
	elog "System shutdown"
	shutdown
	pexit 0
fi

for p in $@
do
case "$p" in
	"clean")
		logvars
		elog "Processing '$p' option, remaining options ignored"
		cleanfiles
		pexit 0
		;;
	"fire")
		logvars
		elog "Processing '$p' option, remaining options ignored"
		fire
		pexit 0
		;;
	"stop")
		logvars
		elog "Processing '$p' option, remaining options ignored"
		stop
		cru d $cronid
		pexit 0
		;;
	"cron")
		cru a $cronid "$SCHEDULE $me update"
		;;
	"force")
		force="1" # Forces SOURCES to be redownloaded
		;;
	"update")
		update="1" # Update even if we've done it with age2update
		;;
	"debug")
		debug="1"
		;;
	*)
		elog "'$p' not understood! - no action taken."
		elog "Options: {force|debug} (clean|fire|stop|cron|update)"
		pexit 1
		;;
esac
done

logvars

[ $currentmode != "OFF" ] && elog "Blocklist active in $currentmode mode"

# rebuild blocklist if script, sources, whitelist or blacklist has changed
[ "$thisconfig" != "$lastconfig" ] && {
	elog "Config or script has changed - rebuilding list"
	restartpix=1
	echo -n "" >  $blocklist
}

# remove existing list if not built for $LISTMODE or $redirip
[ -s $blocklist ] && {
	if ! head -n 1 $blocklist | grep -qm1 "MODE=$LISTMODE"; then
		elog "Existing blocklist is not $LISTMODE mode - removing"
		echo -n "" >  $blocklist
	elif ! head -n 1 $blocklist | grep -qm1 "IP=$redirip"; then
		elog "Existing blocklist is not for IP $redirip - removing"
		echo -n "" >  $blocklist
	fi
}

# completely skip update if script is less than $age2update hours old
now=$(date +%s)
listdate=$(date -r "$blocklist" +%s 2> /dev/null)
listage=$(( now - listdate ))

[ $listage -gt $(( age2update * 3600 )) -o "$force" = "1" -o "$update" = "1" -o ! -s "$blocklist" ] && {
	buildlist
} || {
	elog "List not old enough to update"
 	[ "$currentmode" = "$LISTMODE"  ] && {
		startserver
		pexit 0
	}
}

[ "$restartpix" = "1" ] && stopserver
startserver
writeconf
restartdns
echo "$thisconfig" > "$prefix/lastmod-config"

pexit 0

