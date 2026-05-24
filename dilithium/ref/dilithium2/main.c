#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/sleep.h>
#include <stdint.h>
#include <string.h>

#include <avr_mcu_section.h>
AVR_MCU(16000000UL, "atmega2560");
AVR_MCU_SIMAVR_COMMAND(&GPIOR1);

#include "api.h"
#include "params.h"

#define MSG_BYTES 32
static uint8_t g_pk[CRYPTO_PUBLICKEYBYTES];
static uint8_t g_sk[CRYPTO_SECRETKEYBYTES];
static uint8_t g_sig[CRYPTO_BYTES];
static uint8_t g_m[MSG_BYTES];
static size_t g_siglen;

/* ---- Timer1 32-bit counter --------------------------------------- */
static volatile uint16_t g_t1_ovf = 0;
ISR(TIMER1_OVF_vect) { g_t1_ovf++; }

static void timer_init(void)
{
    TCCR1A = 0;
    TCCR1B = (1 << CS10);
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

/* ---- UART0 @ 115200 baud ----------------------------------------- */
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
    UDR0 = c;
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
static void uart_puti(int v)
{
    if (v < 0)
    {
        uart_putc('-');
        v = -v;
    }
    uart_putu32((uint32_t)v);
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

    for (uint8_t i = 0; i < MSG_BYTES; i++)
        g_m[i] = i;

    uart_puts("=== Dilithium2 REF Benchmark (AVR/simavr) ===\n");
    uart_puts("MCU: atmega2560 @ 16 MHz  SRAM: 64 KB\n");

    /* --- KeyGen ---------------------------------------------------- */
    memset(g_pk, 0, sizeof g_pk);
    memset(g_sk, 0, sizeof g_sk);
    timer_reset();
    crypto_sign_keypair(g_pk, g_sk);
    uint32_t cyc_keygen = timer_read();
    uart_puts("KeyGen  cycles: ");
    uart_putu32(cyc_keygen);
    uart_putc('\n');

    /* --- Sign ------------------------------------------------------ */
    memset(g_sig, 0, sizeof g_sig);
    g_siglen = 0;
    timer_reset();
    int ret_sign = crypto_sign_signature(g_sig, &g_siglen, g_m, MSG_BYTES, g_sk);
    uint32_t cyc_sign = timer_read();
    uart_puts("Sign    cycles: ");
    uart_putu32(cyc_sign);
    uart_puts("  siglen=");
    uart_putu32((uint32_t)g_siglen);
    uart_puts("  ret=");
    uart_puti(ret_sign);
    uart_putc('\n');

    /* --- Verify ---------------------------------------------------- */
    timer_reset();
    int ret_verify = crypto_sign_verify(g_sig, g_siglen, g_m, MSG_BYTES, g_pk);
    uint32_t cyc_verify = timer_read();
    uart_puts("Verify  cycles: ");
    uart_putu32(cyc_verify);
    uart_puts("  ret=");
    uart_puti(ret_verify);
    uart_putc('\n');

    /* --- Summary --------------------------------------------------- */
    uart_puts("--- Summary (k cycles) ---\n");
    uart_puts("KeyGen: ");
    uart_putu32(cyc_keygen / 1000u);
    uart_puts(" k  Sign: ");
    uart_putu32(cyc_sign / 1000u);
    uart_puts(" k  Verify: ");
    uart_putu32(cyc_verify / 1000u);
    uart_puts(" k\n");
    uart_puts("Verify result (0=OK): ");
    uart_puti(ret_verify);
    uart_putc('\n');
    uart_puts("DONE\n");

    sim_exit();
    return 0;
}