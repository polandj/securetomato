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
 
Get the source code:
```
git clone git@github.com:polandj/securetomato.git
```

Setup the MIPS tools:
```
ln -s $HOME/securetomato/tools/brcm /opt/brcm
export PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin
```

## Build

```
cd $HOME/tomato/release/src-rt
make <target(s)> V1=v52 V2=_tailored_name
```

make help to see all the hardware.  Results will be in image/

## Submitting changes

FOllow [this workflow](https://gun.io/blog/how-to-github-fork-branch-and-pull-request/)
