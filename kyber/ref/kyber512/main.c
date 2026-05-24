#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/sleep.h>
#include <stdint.h>
#include <string.h>

#include <avr_mcu_section.h>
AVR_MCU(16000000UL, "atmega2560");
AVR_MCU_SIMAVR_COMMAND(&GPIOR1);

#include "kem.h"
#include "params.h"

static uint8_t g_pk[PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES];
static uint8_t g_sk[PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES];
static uint8_t g_ct[PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES];
static uint8_t g_ss[PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES];
static uint8_t g_ss2[PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES];

static volatile uint16_t g_t1_ovf = 0;

ISR(TIMER1_OVF_vect) { g_t1_ovf++; }

static void timer_init(void)
{
  TCCR1A = 0;
  TCCR1B = (1 << CS10); /* no prescaler */
  TIMSK1 = (1 << TOIE1);
}

static void timer_reset(void)
{
  cli();
  TCNT1 = 0;
  g_t1_ovf = 0;
  sei();
}

static uint32_t timer_read(void)
{
  cli();
  uint16_t t = TCNT1, o = g_t1_ovf;
  if ((TIFR1 & (1 << TOV1)) && t < 0x8000u)
  {
    t = TCNT1;
    o++;
  }
  sei();
  return ((uint32_t)o << 16) | t;
}

static void uart_init(void)
{
  UCSR0A = (1 << U2X0);
  UBRR0 = 8;
  UCSR0B = (1 << TXEN0);
  UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

static void uart_putc(char c)
{
  while (!(UCSR0A & (1 << UDRE0)))
    ;
  UDR0 = (uint8_t)c;
}

static void uart_puts(const char *s)
{
  while (*s)
    uart_putc(*s++);
}

static void uart_putu32(uint32_t v)
{
  char buf[11];
  uint8_t i = 10;
  buf[10] = '\0';
  if (!v)
  {
    uart_putc('0');
    return;
  }
  while (v && i)
  {
    buf[--i] = '0' + (uint8_t)(v % 10u);
    v /= 10u;
  }
  uart_puts(buf + i);
}

static void uart_puthex(uint8_t b)
{
  const char h[] = "0123456789ABCDEF";
  uart_putc(h[b >> 4]);
  uart_putc(h[b & 0xF]);
}

static void sim_exit(void)
{
  uart_puts("\n");
  GPIOR1 = 0;
  cli();
  while (1)
    sleep_cpu();
}

/* ------------------------------------------------------------------ */
int main(void)
{
  MCUSR = 0;
  wdt_disable();
  SP = 0xFFFF;

  uart_init();
  timer_init();
  sei();

  uart_puts("=== Kyber512 REF Benchmark (AVR/simavr) ===\n");
  uart_puts("MCU: atmega2560 @ 16 MHz  SRAM: 64 KB\n");

  /* --- KeyGen ---------------------------------------------------- */
  memset(g_pk, 0, sizeof g_pk);
  memset(g_sk, 0, sizeof g_sk);
  timer_reset();
  PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair(g_pk, g_sk);
  uint32_t cyc_keygen = timer_read();
  uart_puts("KeyGen  cycles: ");
  uart_putu32(cyc_keygen);
  uart_putc('\n');

  /* --- Encaps ---------------------------------------------------- */
  timer_reset();
  PQCLEAN_KYBER512_CLEAN_crypto_kem_enc(g_ct, g_ss, g_pk);
  uint32_t cyc_enc = timer_read();
  uart_puts("Encaps  cycles: ");
  uart_putu32(cyc_enc);
  uart_putc('\n');

  /* --- Decaps ---------------------------------------------------- */
  timer_reset();
  PQCLEAN_KYBER512_CLEAN_crypto_kem_dec(g_ss2, g_ct, g_sk);
  uint32_t cyc_dec = timer_read();
  uart_puts("Decaps  cycles: ");
  uart_putu32(cyc_dec);
  uart_putc('\n');

  /* --- Correctness ----------------------------------------------- */
  uint8_t ok = 1;
  for (uint8_t i = 0; i < PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES; i++)
    if (g_ss[i] != g_ss2[i])
    {
      ok = 0;
      break;
    }
  uart_puts("SS match: ");
  uart_putc(ok ? '1' : '0');
  uart_putc('\n');

  uart_puts("SS  : ");
  for (uint8_t i = 0; i < 16; i++)
  {
    uart_puthex(g_ss[i]);
    uart_putc(' ');
  }
  uart_puts("...\n");
  uart_puts("SS2 : ");
  for (uint8_t i = 0; i < 16; i++)
  {
    uart_puthex(g_ss2[i]);
    uart_putc(' ');
  }
  uart_puts("...\n");

  /* --- Summary --------------------------------------------------- */
  uart_puts("--- Summary (k cycles) ---\n");
  uart_puts("KeyGen: ");
  uart_putu32(cyc_keygen / 1000u);
  uart_puts(" k  Encaps: ");
  uart_putu32(cyc_enc / 1000u);
  uart_puts(" k  Decaps: ");
  uart_putu32(cyc_dec / 1000u);
  uart_puts(" k\n");
  uart_puts("DONE\n");

  sim_exit();
  return 0;
}