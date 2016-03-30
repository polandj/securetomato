# Development

**How to build and develop Secure Tomato**

## Preparation

Any Linux environment should work.  Ubuntu is known to work well.  Install the following dependencies:

- git
- make
- gcc
- libncurses5-dev
- bison
- flex
- pkg-config
- autoconf
- libtool
- texinfo
- gawk
 
Get the source code:
```
git clone https://github.com/polandj/securetomato.git
```

Setup the MIPS tools:
```
ln -s $HOME/securetomato/tools/brcm /opt/brcm
export PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin
```

## Build

```
cd $HOME/securetomato/release/src-rt
make <target(s)> V1=v52 V2=_tailored_name
```

make help to see all the hardware.  Results will be in image/

## Submitting changes

FOllow [this workflow](https://gun.io/blog/how-to-github-fork-branch-and-pull-request/)

## Upstream Remotes
https://github.com/Jackysi/advancedtomato2.git - The advanced tomato MIPS repo (everything except release/src-6.x..)
git@bitbucket.org:jackysi/advancedtomato-arm.git - The advanced tomato ARM repo (release/src-6.x...)
https://github.com/kvic-z/pixelserv-tls.git - PixelservTLS (router/pixelserv-tls)
