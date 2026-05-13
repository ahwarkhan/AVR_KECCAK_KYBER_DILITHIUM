#include <avr/io.h>

.macro mont_red lo, hi
    push r24
    push r25
    movw r24, \lo
    ldi r22, lo8(0xF301)
    ldi r23, hi8(0xF301)
    mul r24, r22
    movw r18, r0
    mul r24, r23
    add r19, r0
    adc r20, r1
    clr r21
    adc r21, r2
    mul r25, r22
    add r19, r0
    adc r20, r1
    adc r21, r2
    mul r25, r23
    add r20, r0
    adc r21, r1
    ldi r22, lo8(3329)
    ldi r23, hi8(3329)
    mul r18, r22
    movw r24, r0
    mul r18, r23
    add r25, r0
    adc r26, r1
    clr r27
    adc r27, r2
    mul r19, r22
    add r25, r0
    adc r26, r1
    adc r27, r2
    mul r19, r23
    add r26, r0
    adc r27, r1
    sub \lo, r24
    sbc \hi, r25
    brcs 1f
    ldi r24, lo8(3329)
    ldi r25, hi8(3329)
    add \lo, r24
    adc \hi, r25
1:
    pop r25
    pop r24
.endm

.macro mul_and_montred src1_l, src1_h, src2_l, src2_h, out_l, out_h
    push r18
    push r19
    push r20
    push r21
    mul \src1_l, \src2_l
    movw r18, r0
    mul \src1_l, \src2_h
    add r19, r0
    adc r20, r1
    clr r21
    adc r21, r2
    mul \src1_h, \src2_l
    add r19, r0
    adc r20, r1
    adc r21, r2
    mul \src1_h, \src2_h
    add r20, r0
    adc r21, r1
    mont_red r18, r20
    mov \out_l, r18
    mov \out_h, r19
    pop r21
    pop r20
    pop r19
    pop r18
.endm

.macro first_butter_fly src1, src2, zeta_l, zeta_h, off
    push r18
    push r19
    push r20
    push r21
    push r24
    push r25
    ldd r24, X+\off
    ldd r25, X+\off+1
    mul_and_montred r24, r25, \zeta_l, \zeta_h, r18, r19
    mov \src2, \src1
    add \src1, r18
    adc \src1+1, r19
    sub \src2, r18
    sbc \src2+1, r19
    pop r25
    pop r24
    pop r21
    pop r20
    pop r19
    pop r18
.endm

.macro butter_fly src1, src2, zeta_l, zeta_h
    push r18
    push r19
    mul_and_montred \src2, \src2+1, \zeta_l, \zeta_h, r18, r19
    mov \src2, \src1
    add \src1, r18
    adc \src1+1, r19
    sub \src2, r18
    sbc \src2+1, r19
    pop r19
    pop r18
.endm

.macro first_butter_fly_imd src1, src2, zeta_l, zeta_h, off
    ldd r24, X+\off
    ldd r25, X+\off+1
    mul_and_montred r24, r25, \zeta_l, \zeta_h, r18, r19
    mov \src2, \src1
    add \src1, r18
    adc \src1+1, r19
    sub \src2, r18
    sbc \src2+1, r19
.endm

.macro butter_fly_imd src1, src2, zeta_l, zeta_h
    mul_and_montred \src2, \src2+1, \zeta_l, \zeta_h, r18, r19
    mov \src2, \src1
    add \src1, r18
    adc \src1+1, r19
    sub \src2, r18
    sbc \src2+1, r19
.endm

.macro merging_2 zeta1_l, zeta1_h, zeta2_l, zeta2_h, zeta3_l, zeta3_h, off1, off2, off3, off4
    push r4
    push r5
    push r6
    push r7
    ldd r4, X+\off1
    ldd r5, X+\off1+1
    ldd r6, X+\off2
    ldd r7, X+\off2+1
    first_butter_fly r4,r6, \zeta1_l,\zeta1_h, \off3
    first_butter_fly r5,r7, \zeta1_l,\zeta1_h, \off4
    butter_fly r4,r5, \zeta2_l,\zeta2_h
    butter_fly r6,r7, \zeta3_l,\zeta3_h
    std X+\off1, r4
    std X+\off1+1, r5
    std X+\off2, r6
    std X+\off2+1, r7
    adiw X, 2
    pop r7
    pop r6
    pop r5
    pop r4
.endm

.macro merging_3 zeta1_l,zeta1_h,zeta2_l,zeta2_h,zeta3_l,zeta3_h,zeta4_l,zeta4_h,zeta5_l,zeta5_h,zeta6_l,zeta6_h,zeta7_l,zeta7_h
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    ldd r4, X+0
    ldd r5, X+1
    ldd r6, X+4
    ldd r7, X+5
    ldd r8, X+8
    ldd r9, X+9
    ldd r10, X+12
    ldd r11, X+13
    first_butter_fly_imd r4,r8, \zeta1_l,\zeta1_h, 16
    first_butter_fly_imd r5,r9, \zeta1_l,\zeta1_h, 20
    first_butter_fly_imd r6,r10, \zeta1_l,\zeta1_h, 24
    first_butter_fly_imd r7,r11, \zeta1_l,\zeta1_h, 28
    butter_fly_imd r4,r6, \zeta2_l,\zeta2_h
    butter_fly_imd r5,r7, \zeta2_l,\zeta2_h
    butter_fly_imd r8,r10, \zeta3_l,\zeta3_h
    butter_fly_imd r9,r11, \zeta3_l,\zeta3_h
    butter_fly_imd r4,r5, \zeta4_l,\zeta4_h
    butter_fly_imd r6,r7, \zeta5_l,\zeta5_h
    butter_fly_imd r8,r9, \zeta6_l,\zeta6_h
    butter_fly_imd r10,r11, \zeta7_l,\zeta7_h
    std X+0, r4
    std X+1, r5
    std X+4, r6
    std X+5, r7
    std X+8, r8
    std X+9, r9
    std X+12, r10
    std X+13, r11
    adiw X, 2
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
.endm

.section .text
.global asm_ntt_merging
.func asm_ntt_merging
asm_ntt_merging:
    push r2
    push r3
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
    push r16
    push r17
    push r28
    push r29
    clr r2
    movw r26, r24
    movw r28, r24
    adiw r28, 128
    ldi r24, lo8(3329)
    ldi r25, hi8(3329)
    movw r10, r24
    ldi r24, lo8(0xF301)
    ldi r25, hi8(0xF301)
    movw r8, r24
    ldi r24, lo8(-758)
    ldi r25, hi8(-758)
    movw r14, r24
    ldi r24, lo8(-359)
    ldi r25, hi8(-359)
    movw r16, r24
    ldi r24, lo8(-1517)
    ldi r25, hi8(-1517)
    movw r18, r24
layer1_2merge:
    merging_2 r16,r17, r14,r15, r18,r19, 0,128,256,384
    cp r26, r28
    cpc r27, r29
    brne layer1_2merge
    sbiw r26, 128
    sbiw r28, 96
    ldi r24, lo8(1493)
    ldi r25, hi8(1493)
    movw r14, r24
    ldi r24, lo8(-171)
    ldi r25, hi8(-171)
    movw r16, r24
    ldi r24, lo8(622)
    ldi r25, hi8(622)
    movw r18, r24
layer3_2merge_1:
    merging_2 r16,r17, r14,r15, r18,r19, 0,32,64,96
    cp r26, r28
    cpc r27, r29
    brne layer3_2merge_1
    adiw r26, 96
    adiw r28, 128
    ldi r24, lo8(1422)
    ldi r25, hi8(1422)
    movw r14, r24
    ldi r24, lo8(1577)
    ldi r25, hi8(1577)
    movw r16, r24
    ldi r24, lo8(182)
    ldi r25, hi8(182)
    movw r18, r24
layer3_2merge_2:
    merging_2 r16,r17, r14,r15, r18,r19, 0,32,64,96
    cp r26, r28
    cpc r27, r29
    brne layer3_2merge_2
    adiw r26, 96
    adiw r28, 128
    ldi r24, lo8(287)
    ldi r25, hi8(287)
    movw r14, r24
    ldi r24, lo8(962)
    ldi r25, hi8(962)
    movw r16, r24
    ldi r24, lo8(-1202)
    ldi r25, hi8(-1202)
    movw r18, r24
layer3_2merge_3:
    merging_2 r16,r17, r14,r15, r18,r19, 0,32,64,96
    cp r26, r28
    cpc r27, r29
    brne layer3_2merge_3
    adiw r26, 96
    adiw r28, 128
    ldi r24, lo8(202)
    ldi r25, hi8(202)
    movw r14, r24
    ldi r24, lo8(-1474)
    ldi r25, hi8(-1474)
    movw r16, r24
    ldi r24, lo8(1468)
    ldi r25, hi8(1468)
    movw r18, r24
layer3_2merge_4:
    merging_2 r16,r17, r14,r15, r18,r19, 0,32,64,96
    cp r26, r28
    cpc r27, r29
    brne layer3_2merge_4
    sbiw r26, 416
layer5_3merge:
    merging_3 0x3D,0x02, 0xC7,0x04, 0x8C,0x02, 0xB9,0xFC, 0xAE,0x01, 0x2B,0x02, 0x4B,0x03
    merging_3 0x3D,0x02, 0xC7,0x04, 0x8C,0x02, 0xB9,0xFC, 0xAE,0x01, 0x2B,0x02, 0x4B,0x03
    adiw r26, 28
    merging_3 0xD9,0xFA, 0xD8,0xFD, 0xF7,0x03, 0x1D,0xFB, 0x67,0x03, 0x0E,0x06, 0x69,0x00
    merging_3 0xD9,0xFA, 0xD8,0xFD, 0xF7,0x03, 0x1D,0xFB, 0x67,0x03, 0x0E,0x06, 0x69,0x00
    adiw r26, 28
    merging_3 0x08,0x01, 0xF3,0xFA, 0xD3,0x05, 0xA6,0x01, 0x4B,0x02, 0xB1,0x00, 0x15,0xFF
    merging_3 0x08,0x01, 0xF3,0xFA, 0xD3,0x05, 0xA6,0x01, 0x4B,0x02, 0xB1,0x00, 0x15,0xFF
    adiw r26, 28
    merging_3 0x7F,0x01, 0xE6,0xFE, 0xF8,0xF9, 0xDB,0xFE, 0x34,0xFE, 0x26,0x06, 0x75,0x06
    merging_3 0x7F,0x01, 0xE6,0xFE, 0xF8,0xF9, 0xDB,0xFE, 0x34,0xFE, 0x26,0x06, 0x75,0x06
    adiw r26, 28
    merging_3 0xC3,0xFC, 0x04,0x02, 0xF8,0xFF, 0x0A,0xFF, 0x0A,0x03, 0x87,0x04, 0x6D,0xFF
    merging_3 0xC3,0xFC, 0x04,0x02, 0xF8,0xFF, 0x0A,0xFF, 0x0A,0x03, 0x87,0x04, 0x6D,0xFF
    adiw r26, 28
    merging_3 0xB2,0x05, 0xC0,0xFE, 0x66,0xFD, 0xF7,0xFC, 0xCB,0x05, 0xA6,0xFD, 0x5F,0x04
    merging_3 0xB2,0x05, 0xC0,0xFE, 0x66,0xFD, 0xF7,0xFC, 0xCB,0x05, 0xA6,0xFD, 0x5F,0x04
    adiw r26, 28
    merging_3 0xBE,0xF9, 0xB6,0xF9, 0x7A,0xFB, 0xA2,0xF9, 0x84,0x02, 0x98,0xFC, 0x5D,0x01
    merging_3 0xBE,0xF9, 0xB6,0xF9, 0x7A,0xFB, 0xA2,0xF9, 0x84,0x02, 0x98,0xFC, 0x5D,0x01
    adiw r26, 28
    merging_3 0x7E,0xFF, 0x7E,0x00, 0xBD,0x05, 0xA2,0x01, 0x49,0x01, 0x64,0xFF, 0xB5,0xFF
    merging_3 0x7E,0xFF, 0x7E,0x00, 0xBD,0x05, 0xA2,0x01, 0x49,0x01, 0x64,0xFF, 0xB5,0xFF
    adiw r26, 28
    merging_3 0x57,0xFD, 0xAB,0xFC, 0xA6,0xFF, 0x31,0x03, 0x49,0x04, 0x5B,0x02, 0x62,0x02
    merging_3 0x57,0xFD, 0xAB,0xFC, 0xA6,0xFF, 0x31,0x03, 0x49,0x04, 0x5B,0x02, 0x62,0x02
    adiw r26, 28
    merging_3 0xF9,0x03, 0xF1,0xFE, 0x3E,0x03, 0x2A,0x05, 0xFB,0xFA, 0x47,0xFA, 0x80,0x01
    merging_3 0xF9,0x03, 0xF1,0xFE, 0x3E,0x03, 0x2A,0x05, 0xFB,0xFA, 0x47,0xFA, 0x80,0x01
    adiw r26, 28
    merging_3 0xDC,0x02, 0x6B,0x00, 0x73,0xFA, 0x41,0xFB, 0x78,0xFF, 0xC2,0x04, 0xA9,0xFA
    merging_3 0xDC,0x02, 0x6B,0x00, 0x73,0xFA, 0x41,0xFB, 0x78,0xFF, 0xC2,0x04, 0xA9,0xFA
    adiw r26, 28
    merging_3 0x60,0x02, 0x09,0xFF, 0x49,0xFC, 0x76,0xFC, 0xDC,0x00, 0x5B,0xFB, 0x89,0xF9
    merging_3 0x60,0x02, 0x09,0xFF, 0x49,0xFC, 0x76,0xFC, 0xDC,0x00, 0x5B,0xFB, 0x89,0xF9
    adiw r26, 28
    merging_3 0xFA,0xF9, 0x72,0xFE, 0xC1,0x03, 0x63,0xFB, 0x06,0xFA, 0x02,0xFB, 0x1A,0x03
    merging_3 0xFA,0xF9, 0x72,0xFE, 0xC1,0x03, 0x63,0xFB, 0x06,0xFA, 0x02,0xFB, 0x1A,0x03
    adiw r26, 28
    merging_3 0x9B,0x01, 0x18,0xFA, 0xD3,0xFD, 0x1A,0xFA, 0xAA,0xFC, 0x9A,0xFC, 0xDE,0x01
    merging_3 0x9B,0x01, 0x18,0xFA, 0xD3,0xFD, 0x1A,0xFA, 0xAA,0xFC, 0x9A,0xFC, 0xDE,0x01
    adiw r26, 28
    merging_3 0x33,0xFF, 0xC0,0x01, 0xBB,0xFC, 0x94,0xFF, 0xCC,0xFE, 0xE4,0x03, 0xDF,0x03
    merging_3 0x33,0xFF, 0xC0,0x01, 0xBB,0xFC, 0x94,0xFF, 0xCC,0xFE, 0xE4,0x03, 0xDF,0x03
    adiw r26, 28
    merging_3 0xDD,0xF9, 0xA5,0x02, 0xFD,0xFC, 0xBE,0x03, 0x4A,0xFA, 0xF2,0x05, 0x5C,0x06
    merging_3 0xDD,0xF9, 0xA5,0x02, 0xFD,0xFC, 0xBE,0x03, 0x4A,0xFA, 0xF2,0x05, 0x5C,0x06
    pop r29
    pop r28
    pop r17
    pop r16
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
    pop r3
    pop r2
    ret
.endfunc
.end