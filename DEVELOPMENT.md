# Development

**How to build and develop Secure Tomato**

## Preparation

Any Linux environment should work.  Ubuntu is known to work well.  Install the following dependencies:

-

Get the source code:
```
git clone git@github.com:polandj/securetomato.git


ln -s $HOME/tomato/tools/brcm /opt/brcm

export PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin
```

## Build

```
cd $HOME/tomato/release/src-rt
make <target(s)> V1=v52 V2=_tailored_name
```

make help to see all the hardware.  Results will be in image/
