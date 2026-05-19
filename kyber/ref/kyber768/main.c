#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include "api.h"
#include "fips202.h"

/* ── simavr cycle-count markers ─────────────────────────────────────*/
#ifdef __AVR__
#include <avr/io.h>
#define SIM_TIMER_START() \
	do                    \
	{                     \
		DDRB = 0xFF;      \
		PORTB = 0x01;     \
	} while (0)
#define SIM_TIMER_STOP() \
	do                   \
	{                    \
		PORTB = 0x02;    \
	} while (0)
#else
#define SIM_TIMER_START() \
	do                    \
	{                     \
	} while (0)
#define SIM_TIMER_STOP() \
	do                   \
	{                    \
	} while (0)
#endif

/* ── NIST KAT vector: SHA3-256("") ─────────────────────────────────
 * Source: FIPS 202 Appendix B / NIST CAVP SHA-3 test vectors.        */
static const uint8_t SHA3_256_EMPTY[32] = {
	0xa7, 0xff, 0xc6, 0xf8, 0xbf, 0x1e, 0xd7, 0x66,
	0x51, 0xc1, 0x47, 0x56, 0xa0, 0x61, 0xd6, 0x62,
	0xf5, 0x80, 0xff, 0x4d, 0xe4, 0x3b, 0x49, 0xfa,
	0x82, 0xd8, 0x0a, 0x4b, 0x80, 0xf8, 0x43, 0x4a};

int main(void)
{
	int all_pass = 1;

	/* ── TEST 1: KAT – SHA3-256 of empty input ───────────────────── */
	{
		uint8_t out[32];
		sha3_256(out, (const uint8_t *)"", 0);

		int kat_pass = (memcmp(out, SHA3_256_EMPTY, 32) == 0);
		if (!kat_pass)
			all_pass = 0;

		printf("TEST 1 – SHA3-256 KAT:  %s\n", kat_pass ? "PASS" : "FAIL");
		if (!kat_pass)
		{
			printf("  Expected: ");
			for (int i = 0; i < 32; i++)
				printf("%02x", SHA3_256_EMPTY[i]);
			printf("\n  Got:      ");
			for (int i = 0; i < 32; i++)
				printf("%02x", out[i]);
			printf("\n");
		}
	}

	/* ── TEST 2: Functional KEM (KeyGen + Encaps + Decaps) ─────────── */
	{
		uint8_t pk[CRYPTO_PUBLICKEYBYTES];
		uint8_t sk[CRYPTO_SECRETKEYBYTES];
		uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
		uint8_t ss[CRYPTO_BYTES];
		uint8_t ss2[CRYPTO_BYTES];

		SIM_TIMER_START();
		crypto_kem_keypair(pk, sk);
		SIM_TIMER_STOP();

		SIM_TIMER_START();
		crypto_kem_enc(ct, ss, pk);
		SIM_TIMER_STOP();

		SIM_TIMER_START();
		crypto_kem_dec(ss2, ct, sk);
		SIM_TIMER_STOP();

		int kem_pass = (memcmp(ss, ss2, CRYPTO_BYTES) == 0);
		if (!kem_pass)
			all_pass = 0;

		printf("TEST 2 – KEM round-trip: %s\n", kem_pass ? "PASS" : "FAIL");
		printf("  Shared secret (encapsulate): ");
		for (int i = 0; i < 16; i++)
			printf("%02x", ss[i]);
		printf("...\n");
		printf("  Shared secret (decapsulate): ");
		for (int i = 0; i < 16; i++)
			printf("%02x", ss2[i]);
		printf("...\n");
	}

	/* ── Summary ─────────────────────────────────────────────────── */
	printf("\nOverall: %s\n", all_pass ? "ALL TESTS PASSED" : "SOME TESTS FAILED");
	return all_pass ? 0 : 1;
}