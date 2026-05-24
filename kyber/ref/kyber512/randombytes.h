#ifndef RANDOMBYTES_H
#define RANDOMBYTES_H
#include <stdint.h>
#include <stddef.h>
int randombytes(void *buf, const size_t n);
#endif