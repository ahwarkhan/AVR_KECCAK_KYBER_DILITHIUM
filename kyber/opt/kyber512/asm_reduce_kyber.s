#include <avr/io.h>

.macro montmul_str ptr_lo, ptr_hi, f_lo, f_hi, qinv_lo, qinv_hi, kyberq_lo, kyberq_hi, res_lo_r, res_hi_r, tmp0, tmp1, tmp2, tmp3

    ld      tmp0, \ptr_lo:\ptr_hi
    ldd     tmp1, \ptr_lo:\ptr_hi+1

    muls    tmp1, \f_hi
    movw    tmp2, r0

    mul     tmp0, \f_lo
    add     tmp2, r0
    adc     tmp3, r1

    mulsu   tmp1, \f_lo
    add     tmp2, r0
    adc     tmp3, r1

    mulsu   \f_hi, tmp0
    add     tmp2, r0
    adc     tmp3, r1

    movw    \res_lo_r, tmp2

    movw    tmp2, \res_lo_r

    muls    tmp3, \qinv_hi
    movw    \res_hi_r, r0

    mul     tmp2, \qinv_lo
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    mulsu   tmp3, \qinv_lo
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    mulsu   \qinv_hi, tmp2
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    movw    tmp2, \res_hi_r

    muls    tmp3, \kyberq_hi
    movw    \res_hi_r, r0

    mul     tmp2, \kyberq_lo
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    mulsu   tmp3, \kyberq_lo
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    mulsu   \kyberq_hi, tmp2
    add     \res_hi_r, r0
    adc     \res_hi_r+1, r1

    sub     \res_lo_r, \res_hi_r
    sbc     \res_lo_r+1, \res_hi_r+1

    st      \ptr_lo:\ptr_hi, \res_lo_r
    std     \ptr_lo:\ptr_hi+1, \res_lo_r+1

    adiw    \ptr_lo:\ptr_hi, 2

.endm


.macro barrett_str ptr_lo, ptr_hi, v_lo, v_hi, kyberq_lo, kyberq_hi, word_lo, word_hi, tmp0, tmp1, tmp2, tmp3, tmp4, tmp5

    ld      tmp0, \ptr_lo:\ptr_hi
    ldd     tmp1, \ptr_lo:\ptr_hi+1

    muls    tmp1, \v_hi
    movw    tmp2, r0

    mul     tmp0, \v_lo
    add     tmp2, r0
    adc     tmp3, r1

    mulsu   tmp1, \v_lo
    add     tmp2, r0
    adc     tmp3, r1

    mulsu   \v_hi, tmp0
    add     tmp2, r0
    adc     tmp3, r1

    add     tmp3, \word_lo
    adc     tmp4, \word_hi

    mov     tmp5, tmp4

    lsl     tmp3
    rol     tmp4
    lsl     tmp3
    rol     tmp4

    mov     tmp3, tmp4
    ldi     tmp4, 0
    sbrc    tmp3, 7
    dec     tmp4

    muls    tmp3, \kyberq_hi
    movw    tmp4, r0

    mul     tmp2, \kyberq_lo
    add     tmp4, r0
    adc     tmp5, r1

    mulsu   tmp3, \kyberq_lo
    add     tmp4, r0
    adc     tmp5, r1

    mulsu   \kyberq_hi, tmp2
    add     tmp4, r0
    adc     tmp5, r1

    ld      tmp2, \ptr_lo:\ptr_hi
    ldd     tmp3, \ptr_lo:\ptr_hi+1

    sub     tmp2, tmp4
    sbc     tmp3, tmp5

    st      \ptr_lo:\ptr_hi, tmp2
    std     \ptr_lo:\ptr_hi+1, tmp3

    adiw    \ptr_lo:\ptr_hi, 2

.endm


.section .text

.global asm_poly_tomont
asm_poly_tomont:

    push    r2
    push    r3
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15
    push    r16
    push    r17
    push    r28
    push    r29

    movw    r26, r24

    ldi     r18, lo8(1353)
    ldi     r19, hi8(1353)

    ldi     r20, lo8(3329)
    ldi     r21, hi8(3329)

    ldi     r22, lo8(-3327)
    ldi     r23, hi8(-3327)

    movw    r30, r26
    adiw    r30, lo8(512)
    movw    r28, r30

loop_mont:

    ld      r2, X
    ldd     r3, X+1

    muls    r3, r19
    movw    r4, r0

    mul     r2, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r3, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r19, r2
    add     r4, r0
    adc     r5, r1

    movw    r6, r4

    muls    r5, r23
    movw    r8, r0

    mul     r6, r22
    add     r8, r0
    adc     r9, r1

    mulsu   r5, r22
    add     r8, r0
    adc     r9, r1

    mulsu   r23, r6
    add     r8, r0
    adc     r9, r1

    movw    r10, r8

    muls    r9, r21
    movw    r12, r0

    mul     r10, r20
    add     r12, r0
    adc     r13, r1

    mulsu   r9, r20
    add     r12, r0
    adc     r13, r1

    mulsu   r21, r10
    add     r12, r0
    adc     r13, r1

    sub     r4, r12
    sbc     r5, r13

    st      X, r4
    std     X+1, r5

    adiw    r26, 2

    cp      r26, r28
    cpc     r27, r29
    brlo    loop_mont

    pop     r29
    pop     r28
    pop     r17
    pop     r16
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     r7
    pop     r6
    pop     r5
    pop     r4
    pop     r3
    pop     r2

    ret


.global asm_poly_barrett
asm_poly_barrett:

    push    r2
    push    r3
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15
    push    r16
    push    r17
    push    r28
    push    r29

    movw    r26, r24

    ldi     r18, lo8(0x4ebf)
    ldi     r19, hi8(0x4ebf)

    ldi     r20, lo8(3329)
    ldi     r21, hi8(3329)

    ldi     r22, lo8(0x200)
    ldi     r23, hi8(0x200)

    movw    r30, r26
    adiw    r30, lo8(512)
    movw    r28, r30

loop_barrett:

    ld      r2, X
    ldd     r3, X+1

    muls    r3, r19
    movw    r4, r0

    mul     r2, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r3, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r19, r2
    add     r4, r0
    adc     r5, r1

    add     r5, r22
    adc     r6, r23

    mov     r7, r6

    lsl     r5
    rol     r6
    lsl     r5
    rol     r6

    mov     r5, r6
    ldi     r6, 0
    sbrc    r5, 7
    dec     r6

    muls    r5, r21
    movw    r8, r0

    mul     r4, r20
    add     r8, r0
    adc     r9, r1

    mulsu   r5, r20
    add     r8, r0
    adc     r9, r1

    mulsu   r21, r4
    add     r8, r0
    adc     r9, r1

    ld      r10, X
    ldd     r11, X+1

    sub     r10, r8
    sbc     r11, r9

    st      X, r10
    std     X+1, r11

    adiw    r26, 2

    cp      r26, r28
    cpc     r27, r29
    brlo    loop_barrett

    pop     r29
    pop     r28
    pop     r17
    pop     r16
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     r7
    pop     r6
    pop     r5
    pop     r4
    pop     r3
    pop     r2

    ret


.global asm_NTT_poly_barrett
asm_NTT_poly_barrett:

    push    r2
    push    r3
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15
    push    r16
    push    r17
    push    r28
    push    r29

    movw    r26, r24

    ldi     r18, lo8(20)
    ldi     r19, hi8(20)

    ldi     r20, lo8(3329)
    ldi     r21, hi8(3329)

    movw    r30, r26
    adiw    r30, lo8(512)
    movw    r28, r30

loop_barrett_NTT:

    ld      r2, X
    ldd     r3, X+1

    muls    r3, r19
    movw    r4, r0

    mul     r2, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r3, r18
    add     r4, r0
    adc     r5, r1

    mulsu   r19, r2
    add     r4, r0
    adc     r5, r1

    mov     r6, r5

    lsl     r5
    rol     r6

    lsl     r5
    rol     r6

    mov     r5, r6
    ldi     r6, 0
    sbrc    r5, 7
    dec     r6

    muls    r5, r21
    movw    r8, r0

    mul     r4, r20
    add     r8, r0
    adc     r9, r1

    mulsu   r5, r20
    add     r8, r0
    adc     r9, r1

    mulsu   r21, r4
    add     r8, r0
    adc     r9, r1

    ld      r10, X
    ldd     r11, X+1

    sub     r10, r8
    sbc     r11, r9

    st      X, r10
    std     X+1, r11

    adiw    r26, 2

    cp      r26, r28
    cpc     r27, r29
    brlo    loop_barrett_NTT

    pop     r29
    pop     r28
    pop     r17
    pop     r16
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     r7
    pop     r6
    pop     r5
    pop     r4
    pop     r3
    pop     r2

    ret