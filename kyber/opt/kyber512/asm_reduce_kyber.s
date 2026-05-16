#include <avr/io.h>

#define         KYBER_Q         r4
#define         QINV            r5
#define         f               r6
#define         v               r7

#define         res_lo          r8
#define         res_hi          r9

#define         zero            r10
#define         word            r11

#define         ptr             r26
#define         forstop_lo      r12
#define         forstop_hi      r13
#define         a               r14

.macro montmul_str

        ld      r24, X
        ldi     r25, 0
        muls    r24, f
        movw    res_lo, r0

        muls    res_lo, QINV
        muls    r0, KYBER_Q

        sub     res_hi, r1

        st      X+, res_hi
        st      X+, r25

.endm

.macro origin_barrett

        ld      r24, X
        ldi     r25, 0
        muls    r24, v
        mov     r5, r1
        add     r5, word

        swap    r5
        mov     r16, r5
        andi    r16, 0x0F
        lsl     r16
        mov     r17, r5
        andi    r17, 0xF0
        lsr     r17
        lsr     r17
        lsr     r17
        or      r16, r17
        mov     r5, r16
        lsl     r5
        asr     r5
        asr     r5
        asr     r5

        muls    r5, KYBER_Q

        ld      r24, X
        sub     r24, r0
        st      X+, r24
        adiw    r26, 1

.endm

.section .text

.global asm_poly_tomont
asm_poly_tomont:

        push    r4
        push    r5
        push    r6
        push    r7
        push    r8
        push    r9
        push    r10
        push    r11

        push    r28
        push    r29

        movw    r26, r24

        ldi     r16, lo8(1353)
        ldi     r17, hi8(1353)
        movw    f, r16

        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        movw    KYBER_Q, r16

        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        movw    QINV, r16

        movw    r12, r26
        ldi     r16, lo8(512)
        ldi     r17, hi8(512)
        add     r12, r16
        adc     r13, r17

loop_mont:
        montmul_str
        cp      r26, r12
        cpc     r27, r13
        brmi    loop_mont

        pop     r29
        pop     r28

        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     r7
        pop     r6
        pop     r5
        pop     r4

        ret

.global asm_poly_barrett
asm_poly_barrett:

        push    r4
        push    r5
        push    r6
        push    r7
        push    r8
        push    r9
        push    r10
        push    r11

        push    r28
        push    r29

        movw    r26, r24

        ldi     r16, lo8(0x4ebf)
        ldi     r17, hi8(0x4ebf)
        movw    v, r16

        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        movw    KYBER_Q, r16

        ldi     r16, lo8(0x200)
        ldi     r17, hi8(0x200)
        movw    word, r16

        clr     zero

        movw    r12, r26
        ldi     r16, lo8(512)
        ldi     r17, hi8(512)
        add     r12, r16
        adc     r13, r17

loop_barrett:
        origin_barrett
        cp      r26, r12
        cpc     r27, r13
        brmi    loop_barrett

        pop     r29
        pop     r28

        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     r7
        pop     r6
        pop     r5
        pop     r4

        ret

.global asm_NTT_poly_barrett
asm_NTT_poly_barrett:

        push    r4
        push    r5
        push    r6
        push    r7
        push    r8
        push    r9
        push    r10
        push    r11

        push    r28
        push    r29

        movw    r26, r24

        ldi     r16, 20
        ldi     r17, 0
        movw    v, r16

        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        movw    KYBER_Q, r16

        movw    r12, r26
        ldi     r16, lo8(512)
        ldi     r17, hi8(512)
        add     r12, r16
        adc     r13, r17

loop_barrett_NTT:
        origin_barrett
        cp      r26, r12
        cpc     r27, r13
        brmi    loop_barrett_NTT

        pop     r29
        pop     r28

        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     r7
        pop     r6
        pop     r5
        pop     r4

        ret