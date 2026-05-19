#include <stdint.h>
#include <stddef.h>
#include "randombytes.h"

int randombytes(void *buf, const size_t n)
{
    uint8_t *p = (uint8_t *)buf;
    for (size_t i = 0; i < n; i++)
        p[i] = (uint8_t)i;
    return 0;
}
