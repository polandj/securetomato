#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>

#ifdef USE_PTHREAD
#include <pthread.h>
#include <signal.h>
#endif

#include "certs.h"
#include "util.h"

static void generate_cert(char* pem_fn, const char *pem_dir, const char *issuer, EVP_MD_CTX *p_ctx)
{
    char *fname = NULL;
    EVP_PKEY *key = NULL;
    X509 *x509 = NULL;
    
    if(pem_fn[0] == '_') pem_fn[0] = '*';
 
    // -- generate cert
    RSA *rsa = RSA_generate_key(1024, RSA_F4, NULL, NULL);
    if(rsa == NULL)
        goto free_all;
#ifdef DEBUG
    printf("%s: rsa key generated for [%s]\n", __FUNCTION__, pem_fn);
#endif
    key = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(key, rsa); // rsa will be freed when key is freed
#ifdef DEBUG
    printf("%s: rsa key assigned\n", __FUNCTION__);
#endif
    if((x509 = X509_new()) == NULL)
        goto free_all;
    ASN1_INTEGER_set(X509_get_serialNumber(x509),(unsigned)time(NULL));
    X509_set_version(x509,2); // X509 v3
    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 315360000L); // cert valid for 10yrs
    X509_NAME *name = X509_get_issuer_name(x509);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (unsigned char *)issuer, -1, -1, 0);
    name = X509_get_subject_name(x509);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (unsigned char *)pem_fn, -1, -1, 0);
    X509_set_pubkey(x509, key);
    X509_sign_ctx(x509, p_ctx);
#ifdef DEBUG
    printf("%s: x509 cert created\n", __FUNCTION__);
#endif
    // -- save cert
    if(pem_fn[0] == '*') pem_fn[0] = '_';
    asprintf(&fname, "%s/%s", pem_dir, pem_fn);
    FILE *fp = fopen(fname, "wb");
    if(fp == NULL) {
        syslog(LOG_ERR, "Failed to open file %s", fname);
        goto free_all;
    }
    PEM_write_X509(fp, x509);
    PEM_write_PrivateKey(fp, key, NULL, NULL, 0, NULL, NULL);
    fclose(fp);
    syslog(LOG_NOTICE, "cert %s generated and saved", pem_fn);

free_all:
    EVP_PKEY_free(key);
    X509_free(x509);
    free(fname);
}


static int pem_passwd_cb(char *buf, int size, int rwflag, void *u) { 
    int rv = 0;
    char *fname = NULL; 
    asprintf(&fname, "%s/ca.key.passphrase", ((cert_tlstor_t*)u)->pem_dir);

    int fp = open(fname, O_RDONLY);    
    if(fp == -1)
        syslog(LOG_ERR, "Failed to open ca.key.passphrase");
    else {
        rv = read(fp, buf, size);
        close(fp);
#ifdef DEBUG
        buf[rv] = '\0';
        printf("%s: %d, %d\n", buf, size, rv);
#endif
    }
    free(fname);
    return --rv; // trim \n at the end
} 


void *cert_generator(void *cert_tlstor) {

    char *buf = malloc(PIXELSERV_MAX_SERVER_NAME*4);
    int fd = open(PIXEL_CERT_PIPE, O_RDONLY);

    for (;;) {
        int cnt;
        if(fd == -1)
            syslog(LOG_ERR, "Failed to open %s: %s", PIXEL_CERT_PIPE, strerror(errno));

        if((cnt = read(fd, buf, PIXELSERV_MAX_SERVER_NAME*4)) == 0) {
#ifdef DEBUG
             printf("%s: pipe EOF\n", __FUNCTION__);
#endif
            close(fd);
            fd = open(PIXEL_CERT_PIPE, O_RDONLY);
            continue;
        }
        buf[cnt] = '\0';
#ifdef DEBUG
        printf("%s: %s\n", __FUNCTION__, buf);
#endif
        int pid = fork();
        if(pid == 0)
        {
            char *p_buf=NULL, *p_buf_sav=NULL;
            char *fname = malloc(PIXELSERV_MAX_PATH);
            
            EVP_PKEY *key = NULL;
            EVP_MD_CTX *md_ctx = NULL;
            
            // -- skip cert if already exists on disk
            p_buf = strtok_r(buf, ":", &p_buf_sav);
            while (p_buf != NULL) {
                strcpy(fname, ((cert_tlstor_t*)cert_tlstor)->pem_dir);
                strcat(fname, "/");
                strcat(fname, p_buf); 
                struct stat st;
                if(stat(fname, &st) == 0) // already exists
                    p_buf = strtok_r(NULL, ":", &p_buf_sav);
                else
                    break;
            }
            if (p_buf == NULL)
                goto free_all;

            char issuer[65]; // max 64 characters as per X509 
            strcpy(fname, ((cert_tlstor_t*)cert_tlstor)->pem_dir);
            strcat(fname, "/ca.crt");
            FILE *fp = fopen(fname, "r");
            X509 *x509 = X509_new();
            if(fp == NULL || PEM_read_X509(fp, &x509, NULL, NULL) == NULL)
                syslog(LOG_ERR, "Failed to open/read ca.crt"); 
            if(X509_NAME_get_text_by_NID(X509_get_issuer_name(x509), NID_commonName, issuer, sizeof issuer) < 0)
                syslog(LOG_ERR, "Failed to get issuer name from ca.crt");
            X509_free(x509);
            fclose(fp);
            
            strcpy(fname, ((cert_tlstor_t*)cert_tlstor)->pem_dir);
            strcat(fname, "/ca.key");
            fp = fopen(fname, "r");
            RSA *rsa = NULL;
            if(fp == NULL || PEM_read_RSAPrivateKey(fp, &rsa, pem_passwd_cb, cert_tlstor) == NULL) {
                syslog(LOG_ERR, "Failed to open/read ca.key"); 
            }
            fclose(fp);

            key = EVP_PKEY_new();
            EVP_PKEY_assign_RSA(key, rsa);
            md_ctx = EVP_MD_CTX_create();
            
            while (p_buf != NULL) {
                // we don't check disk for cert. Simply re-gen and let it overwrite if exists on disk.
                if(EVP_DigestSignInit(md_ctx, NULL, EVP_sha256(), NULL, key) != 1)
                    syslog(LOG_ERR, "Failed to init signing context");
                else
                    generate_cert(p_buf, ((cert_tlstor_t*)cert_tlstor)->pem_dir, issuer, md_ctx);
                p_buf = strtok_r(NULL, ":", &p_buf_sav);
            }
free_all:
            //EVP_PKEY_free(key);
            //EVP_MD_CTX_destroy(md_ctx);
            //free(fname);
            exit(0);
        }
        if(pid > 0){
            int status;
            wait(&status);
        }
    }
    //free(buf);
    return NULL;
}
