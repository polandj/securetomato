# basic setup
include ../common.mak

DISTNAME  := pixelserv
CC        := gcc
OPTS      := -DDROP_ROOT -DIF_MODE
SRCS      := util.c socket_handler.c pixelserv.c certs.c

ROOT      := .
CFLAGS    := -I$(ROOT)/../openssl/include
LDFLAGS    = -L$(ROOT)/../openssl/
SHAREDLIB := -lssl -lcrypto -ldl
STATICLIB  = $(ROOT)/../openssl/$(ARCH)/libssl.a $(ROOT)/../openssl/$(ARCH)/libcrypto.a

# debug flags
CFLAGS_D   = $(CFLAGS) -g -Wall -DDEBUG -DTEST
LDFLAGS_D  = $(LDFLAGS)

# performance flags
CFLAGS_P   = $(CFLAGS) -O3 -s -Wall -ffunction-sections -fdata-sections -fno-strict-aliasing
LDFLAGS_P  = $(LDFLAGS) -Wl,--gc-sections

# aggressive strip command
# note that this breaks the x86 build on x86-64 for some reason
STRIP     := strip -s -R .note -R .comment -R .gnu.version -R .gnu.version_r

# agressive UPX compress
UPX       := upx -9

# packaging macros
PFILES     = LICENSE README.md dist/$(DISTNAME).$(ARCH).performance.*
PVERSION  := $(shell grep VERSION util.h | awk '{print $$NF}' | sed 's|\"||g')
PCMD      := zip

# x86 environment
CC32      := $(CC) -m32

# x86_64 environment
CC64      := $(CC) -m64

# MIPS environment
# I set my path ahead of time, so I've commented out the path command macro below
MIPSTOOLS := /opt/brcm/hndtools-mipsel-uclibc/bin:/opt/brcm/hndtools-mipsel-linux/bin
MIPSPATH  := PATH=$(MIPSTOOLS):$(PATH)
MIPSREFIX := mipsel-uclibc-
MIPSCC    := $(MIPSREFIX)$(CC)
MIPSSTRIP := $(MIPSREFIX)$(STRIP)

# ARM(Asuswrt) environment
ARMTOOLS  := /opt/brcm-arm/bin
ARMPATH   := PATH=$(ARMTOOLS):$(PATH)
ARMPREFIX := arm-brcm-linux-uclibcgnueabi-
ARMCC     := $(ARMPREFIX)$(CC)
ARMSTRIP  := $(ARMPREFIX)$(STRIP)

# ARM(Entware) environment
ARMentTOOLS  := ../arm-unknown-linux-gnueabi/bin
ARMentPATH   := PATH=$(ARMentTOOLS):$(PATH)
ARMentPREFIX := arm-unknown-linux-gnueabi-
ARMentCC     := $(ARMentPREFIX)$(CC)
ARMentSTRIP  := $(ARMentPREFIX)$(STRIP)


# tomatoware environment uses basic setup options because it compiles native

# targets - notes:
# - for each platform, there should be 4 versions: dynamic performance, dynamic debug, static performance, static debug
# - static is not built for x86* targets because it causes glibc-related complaints
# - mips version could be K24 or K26 depending on environment
# - tomatoware is not included in the 'all' target, because it's for compiling natively on a router

.PHONY: all clean distclean printver x86 x86_x64 mips arm tomatoware

all: mips 

install:
	install -D dist/$(DISTNAME).mips.performance.dynamic $(INSTALLDIR)/bin/pixelserv-tls
	chmod 0555 $(INSTALLDIR)/bin/pixelserv-tls

clean:
	@echo "=== Cleaning intermediate build products ==="
	rm -rf ./*.o

distclean: clean
	@echo "=== Cleaning deployment products ==="
	rm -rf ./dist

dist:
	@echo "=== Creating deployment directory ==="
	mkdir -p dist

printver:
	@echo "=== Building $(DISTNAME) version $(PVERSION) ==="

x86: printver dist
	@echo "=== Building x86 ==="
	$(CC32) $(CFLAGS_D) $(LDFLAGS_D) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.debug.dynamic
	$(CC32) $(CFLAGS_P) $(LDFLAGS_P) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.performance.dynamic
	$(CC32) $(CFLAGS_D) -static $(LDFLAGS_D) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.debug.static
	$(CC32) $(CFLAGS_P) -static $(LDFLAGS_P) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.performance.static
	$(STRIP) dist/$(DISTNAME).$@.performance.*
	$(UPX) dist/$(DISTNAME).$@.performance.*
	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)

amd64: ARCH = amd64
amd64: LDFLAGS += -lpthread
amd64: CFLAGS += -DUSE_PTHREAD
amd64: printver dist
	@echo "=== Building amd64 ==="
	$(CC64) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.dynamic $(OPTS) $(SRCS) $(LDFLAGS_D) $(SHAREDLIB)
	$(CC64) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.dynamic $(OPTS) $(SRCS) $(LDFLAGS_P) $(SHAREDLIB) 
	$(CC64) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.static $(OPTS) $(SRCS) $(STATICLIB) -static $(LDFLAGS_D) $(SHAREDLIB)
	$(CC64) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.static \
	        $(OPTS) $(SRCS) $(STATICLIB) -static $(LDFLAGS_P) $(SHAREDLIB)
	$(STRIP) dist/$(DISTNAME).$@.performance.*
#	$(UPX) dist/$(DISTNAME).$@.performance.*
	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)

mips: ARCH = mips
mips: printver dist
	@echo "=== Building MIPS ==="
	$(MIPSPATH) $(MIPSCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.dynamic $(OPTS) $(SRCS) $(LDFLAGS_D) $(SHAREDLIB)
	$(MIPSPATH) $(MIPSCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.dynamic $(OPTS) $(SRCS) $(LDFLAGS_P) $(SHAREDLIB)
#	$(MIPSPATH) $(MIPSCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.static \
	        $(OPTS) $(SRCS) $(STATICLIB) -static $(LDFLAGS_D) $(SHAREDLIB)
#	$(MIPSPATH) $(MIPSCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.static \
	        $(OPTS) $(SRCS) $(STATICLIB) -static $(LDFLAGS_P) $(SHAREDLIB)
#	$(MIPSPATH) $(MIPSSTRIP) dist/$(DISTNAME).$@.performance.*
#	$(UPX) dist/$(DISTNAME).$@.performance.*
#	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
#	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)

arm: ARCH = arm
arm: printver dist
	@echo "=== Building ARM ==="
	$(ARMPATH) $(ARMCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.dynamic $(OPTS) $(SRCS) $(LDFLAGS_D) $(SHAREDLIB) 
	$(ARMPATH) $(ARMCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.dynamic $(OPTS) $(SRCS) $(LDFLAGS_P) $(SHAREDLIB)
	$(ARMPATH) $(ARMCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.static \
	        $(OPTS) $(SRCS) $(STATICLIB) $(SHAREDLIB) -static $(LDFLAGS_D) 
	$(ARMPATH) $(ARMCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.static \
	        $(OPTS) $(SRCS) $(STATICLIB) $(SHAREDLIB) -static $(LDFLAGS_P)
	$(ARMPATH) $(ARMSTRIP) dist/$(DISTNAME).$@.performance.*
#	$(UPX) dist/$(DISTNAME).$@.performance.*
	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)

arm.ent: LDFLAGS += -Wl,-rpath=/opt/lib,--dynamic-linker=/opt/lib/ld-linux.so.3 -lpthread -L../arm-unknown-linux-gnueabi/arm-unknown-linux-gnueabi/sysroot
arm.ent: CFLAGS += -DUSE_PTHREAD -isystem../arm-unknown-linux-gnueabi/arm-unknown-linux-gnueabi/sysroot/include
arm.ent: ARCH = arm.ent
arm.ent: printver dist
	@echo "=== Building ARM (Entware) ==="
	$(ARMentPATH) $(ARMentCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.dynamic $(OPTS) $(SRCS) $(LDFLAGS_D) $(SHAREDLIB) 
	$(ARMentPATH) $(ARMentCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.dynamic $(OPTS) $(SRCS) $(LDFLAGS_P) $(SHAREDLIB)
	$(ARMentPATH) $(ARMentCC) $(CFLAGS_D) -o dist/$(DISTNAME).$@.debug.static \
	        $(OPTS) $(SRCS) $(STATICLIB) $(SHAREDLIB) -static $(LDFLAGS_D) 
	$(ARMentPATH) $(ARMentCC) $(CFLAGS_P) -o dist/$(DISTNAME).$@.performance.static \
	        $(OPTS) $(SRCS) $(STATICLIB) $(SHAREDLIB) -static $(LDFLAGS_P)
	$(ARMentPATH) $(ARMentSTRIP) dist/$(DISTNAME).$@.performance.static
#	$(UPX) dist/$(DISTNAME).$@.performance.*
	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)

tomatoware: printver dist
	@echo "=== Building tomatoware ==="
	$(CC) $(CFLAGS_D) $(LDFLAGS_D) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.debug.dynamic
	$(CC) $(CFLAGS_P) $(LDFLAGS_P) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.performance.dynamic
	$(CC) $(CFLAGS_D) -static $(LDFLAGS_D) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.debug.static
	$(CC) $(CFLAGS_P) -static $(LDFLAGS_P) $(OPTS) $(SRCS) -o dist/$(DISTNAME).$@.performance.static
	$(STRIP) dist/$(DISTNAME).$@.performance.*
	$(UPX) dist/$(DISTNAME).$@.performance.*
	rm -f dist/$(DISTNAME).$(PVERSION).$@.zip
	$(PCMD) dist/$(DISTNAME).$(PVERSION).$@.zip $(PFILES)
