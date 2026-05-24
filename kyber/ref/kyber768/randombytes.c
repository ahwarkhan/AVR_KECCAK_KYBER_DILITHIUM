#include <stdint.h>
#include "fips202.h"

void randombytes(uint8_t *x, size_t len)
{
    static uint8_t seed[32] = {0}; // fixed seed for reproducibility
    shake256(x, len, seed, 32);
}