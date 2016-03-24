SHIBBY_VERSION=132
ADVTOM_VERSION=3.1
SECURE_VERSION=A
VERSION=$(ADVTOM_VERSION)$(SECURE_VERSION)-$(SHIBBY_VERSION)

rtn16:
	make -C release/src-rt r2s V1=v$(VERSION) V2=RTN16

rtn66:
	make -C release/src-rt r64z V1=v$(VERSION) V2=RTN66

all: rtn16

clean:
	make -C release/src-rt clean

distclean:
	make -C release/src-rt distclean

gitclean:
	git clean -xfd
	git checkout -- .
