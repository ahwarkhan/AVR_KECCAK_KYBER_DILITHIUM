#ifndef API_H
#define API_H

#include <stdint.h>
#include "params.h"

#define CRYPTO_SECRETKEYBYTES KYBER_SECRETKEYBYTES
#define CRYPTO_PUBLICKEYBYTES KYBER_PUBLICKEYBYTES
#define CRYPTO_CIPHERTEXTBYTES KYBER_CIPHERTEXTBYTES
#define CRYPTO_BYTES KYBER_SSBYTES

#define crypto_kem_keypair PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair
#define crypto_kem_enc PQCLEAN_KYBER512_CLEAN_crypto_kem_enc
#define crypto_kem_dec PQCLEAN_KYBER512_CLEAN_crypto_kem_dec

int PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair(uint8_t *pk, uint8_t *sk);
int PQCLEAN_KYBER512_CLEAN_crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
int PQCLEAN_KYBER512_CLEAN_crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);

#endif