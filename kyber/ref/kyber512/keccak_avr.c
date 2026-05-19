/*
 * keccak_avr.c  --  Keccak-f[1600] for Kyber-512 on 8-bit AVR
 *                   with the TWISTING optimisation from:
 *
 *   Shin, Kim, Khalid, O'Neill, Seo,
 *   "Optimized Implementations of Keccak, Kyber, and Dilithium
 *    on the MSP430 Microcontroller," TCHES 2026.
 *
 * Author:  Ahwar Khan  (AVR port)
 */

#include <stdint.h>
#include <string.h>
#include "fips202.h"

/* ── Keccak constants ─────────────────────────────────────────────── */

static const uint64_t RC[24] = {
    UINT64_C(0x0000000000000001), UINT64_C(0x0000000000008082),
    UINT64_C(0x800000000000808A), UINT64_C(0x8000000080008000),
    UINT64_C(0x000000000000808B), UINT64_C(0x0000000080000001),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008009),
    UINT64_C(0x000000000000008A), UINT64_C(0x0000000000000088),
    UINT64_C(0x0000000080008009), UINT64_C(0x000000008000000A),
    UINT64_C(0x000000008000808B), UINT64_C(0x800000000000008B),
    UINT64_C(0x8000000000008089), UINT64_C(0x8000000000008003),
    UINT64_C(0x8000000000008002), UINT64_C(0x8000000000000080),
    UINT64_C(0x000000000000800A), UINT64_C(0x800000008000000A),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008080),
    UINT64_C(0x0000000080000001), UINT64_C(0x8000000080008008)};

/* rho rotation amounts in standard (row-major) lane order [x + 5*y] */
static const uint8_t RHO[25] = {
    0, 1, 62, 28, 27,
    36, 44, 6, 55, 20,
    3, 10, 43, 25, 39,
    41, 45, 15, 21, 8,
    18, 2, 61, 56, 14};

/* pi permutation: new_index[i] = PI[i] in standard order */
static const uint8_t PI[25] = {
    0, 10, 20, 5, 15,
    16, 1, 11, 21, 6,
    7, 17, 2, 12, 22,
    23, 8, 18, 3, 13,
    14, 24, 9, 19, 4};

/* ── Rotation helper ──────────────────────────────────────────────── */
static inline uint64_t rol64(uint64_t v, unsigned int n)
{
    return (v << n) | (v >> (64u - n));
}

/* ── Twisting helpers ─────────────────────────────────────────────── */
static inline void twist(uint64_t dst[25], const uint64_t src[25])
{
    /* dst[5*x + y] = src[x + 5*y]  i.e. transpose x<->y */
    for (int x = 0; x < 5; x++)
        for (int y = 0; y < 5; y++)
            dst[5 * x + y] = src[x + 5 * y];
}

static inline void untwist(uint64_t dst[25], const uint64_t src[25])
{
    /* dst[x + 5*y] = src[5*x + y] */
    for (int x = 0; x < 5; x++)
        for (int y = 0; y < 5; y++)
            dst[x + 5 * y] = src[5 * x + y];
}

/* ── Core permutation ─────────────────────────────────────────────── */
__attribute__((optimize("O3"))) void avr_keccak_f1600_twisted(uint64_t *state, uint64_t *t, uint64_t *d)
{
    (void)t;
    (void)d;

    uint64_t A[5][5]; /* A[x][y] */
    uint64_t B[5][5]; /* rho+pi result                              */
    uint64_t C[5];    /* column XORs for theta                      */
    uint64_t D[5];    /* theta correction                           */

    /* Load state                                                     */
    for (int x = 0; x < 5; x++)
        for (int y = 0; y < 5; y++)
            A[x][y] = state[x + 5 * y];

    /* ── 24 rounds ──────────────────────────────────────────────── */
    for (int round = 0; round < 24; round++)
    {

        /* ── Pre-theta: C[x] = XOR of column x ──────────────────  */
        for (int x = 0; x < 5; x++)
            C[x] = A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4];

        D[0] = C[4] ^ rol64(C[1], 1);
        D[3] = C[2] ^ rol64(C[4], 1);
        D[1] = C[0] ^ rol64(C[2], 1);
        D[4] = C[3] ^ rol64(C[0], 1);
        D[2] = C[1] ^ rol64(C[3], 1);

        /* ── Theta + rho + pi ────────────────────────────────────*/
        for (int x = 0; x < 5; x++)
        {
            for (int y = 0; y < 5; y++)
            {
                int src_idx = x + 5 * y; /* standard index   */
                uint64_t v = A[x][y] ^ D[x];
                uint8_t r = RHO[src_idx];
                uint64_t rv = (r == 0) ? v : rol64(v, r);
                int pi_dst = PI[src_idx]; /* standard dst idx */
                int nx = pi_dst % 5;
                int ny = pi_dst / 5;
                B[nx][ny] = rv;
            }
        }

        /* ── Chi + iota  (zig-zag order: x=4 down to x=0) ───────*/
        for (int y = 0; y < 5; y++)
        {
            uint64_t b4 = B[4][y];
            uint64_t b0 = B[0][y];
            uint64_t b1 = B[1][y];
            uint64_t b2 = B[2][y];
            uint64_t b3 = B[3][y];

            A[4][y] = b4 ^ ((~b0) & b1);
            A[3][y] = b3 ^ ((~b4) & b0);
            A[2][y] = b2 ^ ((~b3) & b4);
            A[1][y] = b1 ^ ((~b2) & b3);
            A[0][y] = b0 ^ ((~b1) & b2);
        }

        /* ── Iota: XOR round constant into A[0][0] ──────────── */
        A[0][0] ^= RC[round];
    }

    /* ── Write result back to state (standard layout) ────────────── */
    for (int x = 0; x < 5; x++)
        for (int y = 0; y < 5; y++)
            state[x + 5 * y] = A[x][y];
}