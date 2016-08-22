SHIBBY_VERSION=138
ADVTOM_VERSION=3.3
SECURE_VERSION=C
VERSION=$(ADVTOM_VERSION)$(SECURE_VERSION)-$(SHIBBY_VERSION)

rtn16:
	make -C release/src-rt r2s V1=v$(VERSION) V2=RTN16

rtn66:
	make -C release/src-rt r64s V1=v$(VERSION) V2=RTN66

all: rtn16 rtn66

clean:
	make -C release/src-rt clean

distclean:
	make -C release/src-rt distclean

gitclean:
	git clean -xfd
	git checkout -- .
