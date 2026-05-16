#include <avr/io.h>

#define         a0              r4
#define         a1              r5
#define         b0              r6
#define         b1              r7

#define         zeta            r9
#define         mul_res_lo      r10
#define         mul_res_hi      r11
#define         ptr_C           r12
#define         ptr_A           r13
#define         ptr_B           r14
#define         ptr_zeta        r15

#define         forstop         r8

.macro pw_mont mul_low, mul_hi

        muls    \mul_low, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    \mul_low, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     \mul_hi, r1

.endm

.section .text

.global asm_poly_basemul
asm_poly_basemul:

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
        push    r26
        push    r27
        push    r30
        push    r31

        movw    r30, r24
        movw    r28, r22
        movw    r26, r20
        movw    r14, r18

        movw    r8, r30
        adiw    r8, lo8(512)

round1:

        ldd     r4, Z+0
        ldd     r5, Z+1
        ldd     r6, Z+2
        ldd     r7, Z+3
        ld      r6, X+
        ld      r7, X+
        ld      r9, Y+
        ld      r10, Y+

        muls    a1, b1
        movw    mul_res_lo, r0
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        muls    mul_res_hi, zeta
        movw    r18, r0
        muls    a0, b0
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        st      X+, mul_res_hi
        st      X+, r0

        muls    a1, b0
        movw    r18, r0
        muls    a0, b1
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1
        st      X+, mul_res_hi
        st      X+, r0

round2:

        ldd     r4, Z+4
        ldd     r5, Z+5
        ldd     r6, Z+6
        ldd     r7, Z+7
        ld      r6, X+
        ld      r7, X+
        ld      r6, X+
        ld      r7, X+
        com     zeta
        inc     zeta

        muls    a1, b1
        movw    mul_res_lo, r0
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        muls    mul_res_hi, zeta
        movw    r18, r0
        muls    a0, b0
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        st      X+, mul_res_hi
        st      X+, r0

        muls    a1, b0
        movw    r18, r0
        muls    a0, b1
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1
        st      X+, mul_res_hi
        st      X+, r0

        adiw    r30, 8
        adiw    r28, 8
        adiw    r26, 8
        adiw    r14, 2

        cp      r30, r8
        cpc     r31, r9
        brmi    round1

        pop     r31
        pop     r30
        pop     r27
        pop     r26
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

.global asm_basemul
asm_basemul:

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
        push    r26
        push    r27
        push    r30
        push    r31

        movw    r30, r24
        movw    r28, r22
        movw    r26, r20
        movw    r14, r18

        ldd     r4, Z+0
        ldd     r5, Z+1
        ldd     r6, Z+2
        ldd     r7, Z+3
        ld      r6, X+
        ld      r7, X+
        ld      r6, X+
        ld      r7, X+

        muls    a1, b1
        movw    mul_res_lo, r0
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        muls    mul_res_hi, ptr_zeta
        movw    r18, r0
        muls    a0, b0
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        st      X+, mul_res_hi
        st      X+, r0

        muls    a1, b0
        movw    r18, r0
        muls    a0, b1
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1
        st      X+, mul_res_hi
        st      X+, r0

        ldd     r4, Z+4
        ldd     r5, Z+5
        ldd     r6, Z+6
        ldd     r7, Z+7
        ld      r6, X+
        ld      r7, X+
        ld      r6, X+
        ld      r7, X+
        com     ptr_zeta
        inc     ptr_zeta

        muls    a1, b1
        movw    mul_res_lo, r0
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        muls    mul_res_hi, ptr_zeta
        movw    r18, r0
        muls    a0, b0
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1

        st      X+, mul_res_hi
        st      X+, r0

        muls    a1, b0
        movw    r18, r0
        muls    a0, b1
        add     r18, r0
        adc     r19, r1
        movw    mul_res_lo, r18
        muls    mul_res_lo, r16
        ldi     r16, lo8(-3327)
        ldi     r17, hi8(-3327)
        muls    mul_res_lo, r16
        movw    r18, r0
        ldi     r16, lo8(3329)
        ldi     r17, hi8(3329)
        muls    r18, r16
        sub     mul_res_hi, r1
        st      X+, mul_res_hi
        st      X+, r0

        pop     r31
        pop     r30
        pop     r27
        pop     r26
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