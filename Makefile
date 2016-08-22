SHIBBY_VERSION=138
ADVTOM_VERSION=3.3
SECURE_VERSION=C
VERSION=$(ADVTOM_VERSION)$(SECURE_VERSION)-$(SHIBBY_VERSION)

rtn16:
	make -C release/src-rt r2s V1=0000 V2=-$(VERSION)

rtn66:
	make -C release/src-rt r64s V1=0000 V2=$(VERSION)

all: rtn16 rtn66

clean:
	make -C release/src-rt clean

distclean:
	make -C release/src-rt distclean

gitclean:
	git clean -xfd
	git checkout -- .
