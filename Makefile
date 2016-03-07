VERSION=0.1

rtn16:
	make -C release/src-rt r2z V1=$(VERSION) V2=RTN16

rtn66:
	make -C release/src-rt r64z V1=$(VERSION) V2=RTN66

all: rtn16

clean:
	make -C release/src-rt clean

distclean:
	make -C release/src-rt distclean

gitclean:
	git clean -xfd
	git checkout -- .
