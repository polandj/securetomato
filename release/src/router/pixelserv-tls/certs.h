#ifndef _CERTS_H_
#define _CERTS_H_

#define PIXEL_CERT_PIPE "/tmp/pixelcerts"

typedef struct {
    const char* pem_dir;
} cert_tlstor_t;

void *cert_generator(void *cert_tlstor);

#endif
