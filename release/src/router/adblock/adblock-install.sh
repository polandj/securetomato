#!/bin/sh

alias wget=/usr/bin/wget
alias tar=/bin/tar

elog(){
logger -st adblock-install $1
}

abort() {
elog "$1"
elog aborting install
rm -r $tmpfolder 2>/dev/null
exit
}

url="http://tomato-adblock.weebly.com/uploads/6/0/0/7/60074921/adblock-install.tgz"

tmpfolder=/tmp/adblock-install.$$
machine=$(uname -m)
kernel=$(uname -r); kernel=${kernel:0:3}

armdir=pixelserv/arm
mipsdir=pixelserv/mips
k24dir=pixelserv/mipsK24

folders="opt jffs mmc cifs1 cifs2"

bin=""

if [ "$machine" = "mips" ] ; then
  [ "$kernel" = "2.4" ] && pixbin="$k24dir/pixelserv.mips.performance.dynamic" || pixbin="$mipsdir/pixelserv.tomatoware.performance.static"
elif [ "${machine:0:3}" = "arm" ] ; then
  pixbin="$armdir/pixelserv.tomatoware.performance.static"
else
  abort "unknown processor"
fi

rm -r $tmpfolder 2> /dev/null
mkdir -p $tmpfolder ||  abort "could not create $tmpfolder"
cd $tmpfolder

if [ "$PREFIX" != "" ]; then
  [ "${PREFIX:0:1}" != "/" ] &&  abort "PREFIX cannot be a relative path"
  bin="$PREFIX"
  etc="$PREFIX"
else
  elog "PREFIX not set, looking for default folders"
  if [ -d /opt/bin -a -d /opt/etc ]; then
    bin=/opt/bin
    etc=/opt/etc
  else
    for f in $folders
    do
      if mkdir -p /$f/adblock; then
        bin=/$f/adblock
        etc=$bin
        break
      fi
    done
  fi
fi

[ "$bin" = "" ] && abort "PREFIX not set or no default folder accessible"

elog "installing binaries and scripts to $bin, config to $etc/adblock.ini"

mkdir -p "$bin" || abort "could not create install directory $bin"

touch "$bin/adblock.tmp.$$" || abort "could not write to $bin"
rm -f "$bin/adblock.tmp.$$"

wget -O adblock-install.tgz $url || abort "error downloading install archive"

tar xvzf adblock-install.tgz

{
chmod +x adblock.sh
chmod +x adblockweb.sh
chmod +x $pixbin
} 2>/dev/null

for file in adblock.changelog adblock.ini.readme adblock.ini.default adblock.sh adblockweb.sh $pixbin
do
  elog "installing $bin/${file##*/}"
  cp -p $file "$bin/" 2>/dev/null
done

elog "creating 'pixelserv' link for $bin/${file##*/}"
if ! ln -sf $bin/${pixbin##*/} $bin/pixelserv 2>/dev/null ; then
  echo "could not create link, attempting copy instead"
  cp $bin/${pixbin##*/} $bin/pixelserv
fi

if [ -f "$etc/adblock.ini" -o -f "$etc/config" ]; then
  elog "a config file appears to exist - skipping config install"
else
  elog "installing default config file $etc/adblock.ini"
  cp -p adblock.ini.default $etc/adblock.ini
fi
cd /tmp
rm -r $tmpfolder 2>/dev/null
