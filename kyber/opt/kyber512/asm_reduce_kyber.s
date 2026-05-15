#include <avr/io.h>

.def KYBER_Q_L = r4
.def KYBER_Q_H = r5
.def QINV_L = r6
.def QINV_H = r7
.def f_L = r8
.def f_H = r9
.def v_L = r10
.def v_H = r11
.def res_lo_L = r12
.def res_lo_H = r13
.def res_hi_L = r14
.def res_hi_H = r15
.def zero = r16
.def word_L = r17
.def word_H = r18
.def ptrL = r30
.def ptrH = r31
.def forstopL = r28
.def forstopH = r29

.macro montmul_str
    ld r0, Z+
    ld r1, Z-
    movw r2, r0
    movw r0, r2
    movw r20, f_L
    call mul16_32
    movw res_hi_L, r22
    movw res_lo_L, r20
    movw r0, res_lo_L
    movw r20, QINV_L
    call mul16_32
    movw r0, r20
    movw r20, KYBER_Q_L
    call mul16_32
    sub res_hi_L, r22
    sbc res_hi_H, r23
    st Z, res_hi_L
    std Z+1, res_hi_H
    adiw Z, 2
.endm

.macro origin_barrett
    ld r0, Z+
    ld r1, Z-
    movw r20, v_L
    call mul16_32
    movw r2, r22
    add r2, word_L
    adc r3, word_H
    swap r2
    swap r3
    mov r4, r2
    andi r4, 0x0f
    mov r5, r3
    andi r5, 0x0f
    mov r6, r2
    swap r6
    andi r6, 0xf0
    or r4, r6
    mov r6, r3
    swap r6
    andi r6, 0xf0
    or r5, r6
    sbrc r5, 7
    com r4
    asr r5
    ror r4
    asr r5
    ror r4
    movw r20, r4
    movw r0, r20
    movw r20, KYBER_Q_L
    call mul16_32
    ld r0, Z
    ld r1, Z+
    sub r0, r20
    sbc r1, r21
    st -Z, r0
    std Z+1, r1
    adiw Z, 2
.endm

mul16_32:
    clr r24
    clr r25
    clr r26
    clr r27
    mov r18, r0
    mov r19, r1
    mov r20, r2
    mov r21, r3
    mul r18, r20
    movw r22, r0
    mul r18, r21
    add r23, r0
    adc r24, r1
    clr r25
    mul r19, r20
    add r23, r0
    adc r24, r1
    adc r25, r2
    mul r19, r21
    add r24, r0
    adc r25, r1
    clr r26
    adc r26, r2
    movw r20, r22
    movw r22, r24
    ret

.global asm_poly_tomont
asm_poly_tomont:
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    push r28
    push r29
    push r30
    push r31
    ldi f_L, 0x49
    ldi f_H, 0x05
    ldi KYBER_Q_L, 0x01
    ldi KYBER_Q_H, 0x0d
    ldi QINV_L, 0x01
    ldi QINV_H, 0xf3
    movw forstopL, ptrL
    adiw forstopL, 512
loop_mont:
    montmul_str
    cp ptrL, forstopL
    cpc ptrH, forstopH
    brne loop_mont
    pop r31
    pop r30
    pop r29
    pop r28
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    ret

.global asm_poly_barrett
asm_poly_barrett:
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    push r28
    push r29
    push r30
    push r31
    ldi v_L, 0xbf
    ldi v_H, 0x4e
    ldi KYBER_Q_L, 0x01
    ldi KYBER_Q_H, 0x0d
    ldi word_L, 0x00
    ldi word_H, 0x02
    clr zero
    movw forstopL, ptrL
    adiw forstopL, 512
loop_barrett:
    origin_barrett
    cp ptrL, forstopL
    cpc ptrH, forstopH
    brne loop_barrett
    pop r31
    pop r30
    pop r29
    pop r28
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    ret

.global asm_NTT_poly_barrett
asm_NTT_poly_barrett:
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    push r28
    push r29
    push r30
    push r31
    ldi v_L, 0x14
    ldi v_H, 0x00
    ldi KYBER_Q_L, 0x01
    ldi KYBER_Q_H, 0x0d
    movw forstopL, ptrL
    adiw forstopL, 512
loop_barrett_NTT:
    origin_barrett
    cp ptrL, forstopL
    cpc ptrH, forstopH
    brne loop_barrett_NTT
    pop r31
    pop r30
    pop r29
    pop r28
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    ret