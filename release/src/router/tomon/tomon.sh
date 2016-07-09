#!/bin/sh

freetmp=$(df "/tmp" | awk '!/Filesys/{print int($4/1024)}')
prefixlist="/mnt/* /mmc/* /jffs"
prefix=/var/lib
for p in $prefixlist; do
        df=$(df "$p" 2> /dev/null | awk '!/File/{print int($4/1024)}')
        [ "$df" == "" ] && df=0
        if [ -d "$p/tomon" ]; then
                prefix=$p
        elif [ "$df" -gt "$(($freetmp/3))" ]; then
                prefix=$p
        fi
done
mkdir "$profix/tomon"
echo "tomon running in $profix/tomon"
tomon $profix/tomon 

