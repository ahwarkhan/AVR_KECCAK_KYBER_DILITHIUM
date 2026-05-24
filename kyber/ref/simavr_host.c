#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_io.h>
#include <simavr/sim_irq.h>
#include <simavr/avr_uart.h>

/* UART0 output → host stdout */
static void uart_out_cb(struct avr_irq_t *irq, uint32_t value, void *param)
{
    (void)irq;
    (void)param;
    uint8_t ch = (uint8_t)(value & 0xFF);
    putchar(ch);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s <firmware.elf>\n", argv[0]);
        return 1;
    }

    avr_t *avr = avr_make_mcu_by_name("atmega2560");
    if (!avr)
    {
        fprintf(stderr, "ERROR: cannot create atmega2560\n");
        return 1;
    }

    avr->ramend = 0xFFFF;
    avr->frequency = 16000000UL;

    avr_init(avr);

    elf_firmware_t fw;
    memset(&fw, 0, sizeof fw);
    if (elf_read_firmware(argv[1], &fw) != 0)
    {
        fprintf(stderr, "ERROR: cannot read ELF: %s\n", argv[1]);
        return 1;
    }
    avr_load_firmware(avr, &fw);

    /* Connect UART0 output */
    avr_irq_t *uart_irq = avr_io_getirq(avr,
                                        AVR_IOCTL_UART_GETIRQ('0'), UART_IRQ_OUTPUT);
    if (uart_irq)
        avr_irq_register_notify(uart_irq, uart_out_cb, NULL);

    fprintf(stderr, "[host] ramend=0x%04X  freq=%lu Hz\n",
            avr->ramend, (unsigned long)avr->frequency);

    /* Run until cpu_Done / cpu_Crashed, or cycle cap */
    uint64_t cap = 5000000000ULL;
    int state = cpu_Running;
    while (state == cpu_Running)
    {
        state = avr_run(avr);
        if (avr->cycle > cap)
        {
            fprintf(stderr, "\n[host] cycle cap reached (%llu)\n",
                    (unsigned long long)avr->cycle);
            break;
        }
    }
    fflush(stdout);
    fprintf(stderr, "[host] done  state=%d  cycles=%llu\n",
            state, (unsigned long long)avr->cycle);
    avr_terminate(avr);
    return 0;
}