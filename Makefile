version=0.1

rtn16:
	make -C release/src-rt r2z V1=$(version) V2=rtn16

all: rtn16

