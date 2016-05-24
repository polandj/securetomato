include ../common.mak

CFLAGS = -O2 -Wall $(EXTRACFLAGS) -fPIC
CFLAGS += -I$(TOP)/shared -I$(SRCBASE)/include -I.
CFLAGS += -I$(TOP)/libevent/staged/usr/local/include
CFLAGS += -I$(TOP)/libcurl/staged/include

LIBS += -L$(TOP)/openssl -lssl -lcrypto
LIBS += -L$(TOP)/libcurl/staged/lib -lcurl -L$(TOP)/zlib -lz
LIBS = -L$(TOP)/libevent/staged/usr/local/lib -levent

OBJS=tomon.o

all: tomon

tomon: $(OBJS)
	@echo " [tomon] CC $@"
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LIBS)
	$(SIZECHECK)
	$(CPTMP)
	
install: all
	install -D tomon $(INSTALLDIR)/bin/tomon
	$(STRIP) $(INSTALLDIR)/bin/tomon
	chmod 0555 $(INSTALLDIR)/bin/tomon

clean:
	rm -f tomon *.o *.a *.so

	
%.o: %.c .%.depend
	@echo " [tomon] CC $@"
	$(CC) $(CFLAGS) -o $@ -c $<

.depend: $(OBJS:%.o=%.c)
	@$(CC) $(CFLAGS) -M $^ > .depend

.%.depend: %.c
	@$(CC) $(CFLAGS) -M $< > $@

-include $(OBJS:%.o=.%.depend)
