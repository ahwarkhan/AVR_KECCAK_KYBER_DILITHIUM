#include <avr/io.h>

#define         KYBER_Q_L       r10
#define         KYBER_Q_H       r11
#define         QINV_L          r12
#define         QINV_H          r13

#define         KYBER_Q         r10
#define         QINV            r12

#define         mul_res_lo_L    r8
#define         mul_res_lo_H    r9
#define         mul_res_hi_L    r14
#define         mul_res_hi_H    r15

#define         forstop_L       r20
#define         forstop_H       r21

.macro muls16x16 aL, aH, bL, bH
        mul     \aL, \bL
        movw    r2, r0
        mulsu   \aH, \bL
        sbc     r3, r3
        add     r3, r0
        adc     r2, r1
        adc     r3, r3
        mulsu   \bH, \aL
        sbc     r25, r25
        add     r3, r0
        adc     r2, r1
        adc     r3, r25
        muls    \aH, \bH
        add     r2, r0
        adc     r3, r1
.endm

.macro load16_z dst_lo, dst_hi, byte_offset
        movw    r28, r30
        ldi     r26, lo8(\byte_offset)
        ldi     r27, hi8(\byte_offset)
        add     r28, r26
        adc     r29, r27
        ld      \dst_lo, Y+
        ld      \dst_hi, Y
.endm

.macro store16_z src_lo, src_hi, byte_offset
        movw    r28, r30
        ldi     r26, lo8(\byte_offset)
        ldi     r27, hi8(\byte_offset)
        add     r28, r26
        adc     r29, r27
        st      Y+, \src_lo
        st      Y, \src_hi
.endm

.macro inv_barrett argL, argH
        muls16x16 \argL, \argH, r16, r17
        muls16x16 r2, r3, KYBER_Q_L, KYBER_Q_H
        sub     \argL, r0
        sbc     \argH, r1
.endm

.macro inv_barrett_imd argL, argH
        ldi     r26, 20
        ldi     r27, 0
        muls16x16 \argL, \argH, r26, r27
        ldi     r26, lo8(3329)
        ldi     r27, hi8(3329)
        muls16x16 r2, r3, r26, r27
        sub     \argL, r0
        sbc     \argH, r1
.endm

.macro inv_mont mul_low_L, mul_low_H, mul_hi_L, mul_hi_H
        muls16x16 \mul_low_L, \mul_low_H, QINV_L, QINV_H
        muls16x16 r0, r1, KYBER_Q_L, KYBER_Q_H
        sub     \mul_hi_L, r2
        sbc     \mul_hi_H, r3
.endm

.macro inv_mont_imd mul_low_L, mul_low_H, mul_hi_L, mul_hi_H
        ldi     r26, lo8(-3327)
        ldi     r27, hi8(-3327)
        muls16x16 \mul_low_L, \mul_low_H, r26, r27
        ldi     r26, lo8(3329)
        ldi     r27, hi8(3329)
        muls16x16 r0, r1, r26, r27
        sub     \mul_hi_L, r2
        sbc     \mul_hi_H, r3
.endm

.macro inv_butter_fly src1L, src1H, src2L, src2H, zetaL, zetaH
        movw    r8, \src1L
        add     \src1L, \src2L
        adc     \src1H, \src2H
        sub     \src2L, r8
        sbc     \src2H, r9

        inv_barrett \src1L, \src1H

        muls16x16 \zetaL, \zetaH, \src2L, \src2H
        movw    \src2L, r2

        muls16x16 r0, r1, QINV_L, QINV_H
        muls16x16 r0, r1, KYBER_Q_L, KYBER_Q_H
        sub     \src2L, r2
        sbc     \src2H, r3
.endm

.macro inv_butter_fly_ src1L, src1H, src2L, src2H, zetaL, zetaH
        movw    r8, \src1L
        add     \src1L, \src2L
        adc     \src1H, \src2H
        sub     \src2L, r8
        sbc     \src2H, r9

        muls16x16 \zetaL, \zetaH, \src2L, \src2H
        movw    mul_res_lo_L, r0
        movw    \src2L, r2

        inv_mont mul_res_lo_L, mul_res_lo_H, \src2L, \src2H
.endm

.macro inv_butter_fly_imd src1L, src1H, src2L, src2H, zetaL, zetaH
        movw    r8, \src1L
        add     \src1L, \src2L
        adc     \src1H, \src2H
        sub     \src2L, r8
        sbc     \src2H, r9

        inv_barrett_imd \src1L, \src1H

        muls16x16 \zetaL, \zetaH, \src2L, \src2H
        movw    \src2L, r2

        ldi     r26, lo8(-3327)
        ldi     r27, hi8(-3327)
        muls16x16 r0, r1, r26, r27
        ldi     r26, lo8(3329)
        ldi     r27, hi8(3329)
        muls16x16 r0, r1, r26, r27
        sub     \src2L, r2
        sbc     \src2H, r3
.endm

.macro inv_butter_fly_imd_ src1L, src1H, src2L, src2H, zetaL, zetaH
        movw    r8, \src1L
        add     \src1L, \src2L
        adc     \src1H, \src2H
        sub     \src2L, r8
        sbc     \src2H, r9

        muls16x16 \zetaL, \zetaH, \src2L, \src2H
        movw    \src2L, r2

        ldi     r26, lo8(-3327)
        ldi     r27, hi8(-3327)
        muls16x16 r0, r1, r26, r27
        ldi     r26, lo8(3329)
        ldi     r27, hi8(3329)
        muls16x16 r0, r1, r26, r27
        sub     \src2L, r2
        sbc     \src2H, r3
.endm

.macro inv_merging_2 zeta1L, zeta1H, zeta2L, zeta2H, zeta3L, zeta3H, boff1, boff2, boff3, boff4
        load16_z  r4,  r5,  \boff1
        load16_z  r6,  r7,  \boff2
        load16_z  r22, r23, \boff3
        load16_z  r24, r25, \boff4

        inv_butter_fly  r4, r5, r6, r7, \zeta1L, \zeta1H
        inv_butter_fly  r22, r23, r24, r25, \zeta2L, \zeta2H

        inv_butter_fly_ r4, r5, r22, r23, \zeta3L, \zeta3H
        inv_butter_fly_ r6, r7, r24, r25, \zeta3L, \zeta3H

        store16_z r4,  r5,  \boff1
        store16_z r6,  r7,  \boff2
        store16_z r22, r23, \boff3
        store16_z r24, r25, \boff4

        adiw    r30, 2
.endm

.macro inv_merging_22 zeta1L, zeta1H, zeta2L, zeta2H, zeta3L, zeta3H, boff1, boff2, boff3, boff4
        load16_z  r4,  r5,  \boff1
        load16_z  r6,  r7,  \boff2
        load16_z  r22, r23, \boff3
        load16_z  r24, r25, \boff4

        inv_butter_fly_ r4, r5, r6, r7, \zeta1L, \zeta1H
        inv_butter_fly_ r22, r23, r24, r25, \zeta2L, \zeta2H

        inv_butter_fly_ r4, r5, r22, r23, \zeta3L, \zeta3H
        inv_butter_fly_ r6, r7, r24, r25, \zeta3L, \zeta3H

        store16_z r4,  r5,  \boff1
        store16_z r6,  r7,  \boff2
        store16_z r22, r23, \boff3
        store16_z r24, r25, \boff4

        adiw    r30, 2
.endm

.macro inv_merging_3 z1L, z1H, z2L, z2H, z3L, z3H, z4L, z4H, z5L, z5H, z6L, z6H, z7L, z7H
        load16_z  r4,  r5,  0
        load16_z  r6,  r7,  8
        load16_z  r22, r23, 16
        load16_z  r24, r25, 24
        load16_z  r16, r17, 32
        load16_z  r18, r19, 40
        load16_z  r10, r11, 48
        load16_z  r12, r13, 56

        inv_butter_fly_imd_ r4,  r5,  r6,  r7,  \z1L, \z1H
        inv_butter_fly_imd_ r22, r23, r24, r25, \z2L, \z2H
        inv_butter_fly_imd_ r16, r17, r18, r19, \z3L, \z3H
        inv_butter_fly_imd_ r10, r11, r12, r13, \z4L, \z4H

        inv_butter_fly_imd_ r4,  r5,  r22, r23, \z5L, \z5H
        inv_butter_fly_imd_ r6,  r7,  r24, r25, \z5L, \z5H
        inv_butter_fly_imd_ r16, r17, r10, r11, \z6L, \z6H
        inv_butter_fly_imd_ r18, r19, r12, r13, \z6L, \z6H

        inv_butter_fly_imd  r4,  r5,  r16, r17, \z7L, \z7H
        inv_butter_fly_imd  r6,  r7,  r18, r19, \z7L, \z7H
        inv_butter_fly_imd  r22, r23, r10, r11, \z7L, \z7H
        inv_butter_fly_imd  r24, r25, r12, r13, \z7L, \z7H

        store16_z r4,  r5,  0
        store16_z r6,  r7,  8
        store16_z r22, r23, 16
        store16_z r24, r25, 24
        store16_z r16, r17, 32
        store16_z r18, r19, 40
        store16_z r10, r11, 48
        store16_z r12, r13, 56

        adiw    r30, 2
.endm

.macro la_fqmul
        ld      r26, Z
        ldd     r27, Z+1

        muls16x16 r6, r7, r26, r27

        movw    mul_res_lo_L, r0
        movw    mul_res_hi_L, r2

        inv_mont mul_res_lo_L, mul_res_lo_H, mul_res_hi_L, mul_res_hi_H

        st      Z+, mul_res_hi_L
        st      Z+, mul_res_hi_H
.endm

.section .text

.global asm_invntt_merging
asm_invntt_merging:

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
        push    r18
        push    r19
        push    r20
        push    r21
        push    r22
        push    r23
        push    r24
        push    r25
        push    r28
        push    r29

        movw    r30, r24

layer7_merge3:

        inv_merging_3  lo8(1628),  hi8(1628),  lo8(1522),  hi8(1522),  lo8(-1460), hi8(-1460), lo8(958),   hi8(958),   lo8(-1275), hi8(-1275), lo8(677),   hi8(677),   lo8(-1571), hi8(-1571)
        inv_merging_3  lo8(1628),  hi8(1628),  lo8(1522),  hi8(1522),  lo8(-1460), hi8(-1460), lo8(958),   hi8(958),   lo8(-1275), hi8(-1275), lo8(677),   hi8(677),   lo8(-1571), hi8(-1571)
        adiw    r30, 56

        inv_merging_3  lo8(991),   hi8(991),   lo8(996),   hi8(996),   lo8(-308),  hi8(-308),  lo8(-108),  hi8(-108),  lo8(-1065), hi8(-1065), lo8(448),   hi8(448),   lo8(-205),  hi8(-205)
        inv_merging_3  lo8(991),   hi8(991),   lo8(996),   hi8(996),   lo8(-308),  hi8(-308),  lo8(-108),  hi8(-108),  lo8(-1065), hi8(-1065), lo8(448),   hi8(448),   lo8(-205),  hi8(-205)
        adiw    r30, 56

        inv_merging_3  lo8(478),   hi8(478),   lo8(-870),  hi8(-870),  lo8(-854),  hi8(-854),  lo8(-1510), hi8(-1510), lo8(-725),  hi8(-725),  lo8(-1508), hi8(-1508), lo8(411),   hi8(411)
        inv_merging_3  lo8(478),   hi8(478),   lo8(-870),  hi8(-870),  lo8(-854),  hi8(-854),  lo8(-1510), hi8(-1510), lo8(-725),  hi8(-725),  lo8(-1508), hi8(-1508), lo8(411),   hi8(411)
        adiw    r30, 56

        inv_merging_3  lo8(794),   hi8(794),   lo8(-1278), hi8(-1278), lo8(-1530), hi8(-1530), lo8(-1185), hi8(-1185), lo8(961),   hi8(961),   lo8(-398),  hi8(-398),  lo8(-1542), hi8(-1542)
        inv_merging_3  lo8(794),   hi8(794),   lo8(-1278), hi8(-1278), lo8(-1530), hi8(-1530), lo8(-1185), hi8(-1185), lo8(961),   hi8(961),   lo8(-398),  hi8(-398),  lo8(-1542), hi8(-1542)
        adiw    r30, 56

        inv_merging_3  lo8(-1659), hi8(-1659), lo8(-1187), hi8(-1187), lo8(220),   hi8(220),   lo8(-874),  hi8(-874),  lo8(-951),  hi8(-951),  lo8(-247),  hi8(-247),  lo8(608),   hi8(608)
        inv_merging_3  lo8(-1659), hi8(-1659), lo8(-1187), hi8(-1187), lo8(220),   hi8(220),   lo8(-874),  hi8(-874),  lo8(-951),  hi8(-951),  lo8(-247),  hi8(-247),  lo8(608),   hi8(608)
        adiw    r30, 56

        inv_merging_3  lo8(-1335), hi8(-1335), lo8(1218),  hi8(1218),  lo8(-136),  hi8(-136),  lo8(-1215), hi8(-1215), lo8(-1421), hi8(-1421), lo8(107),   hi8(107),   lo8(732),   hi8(732)
        inv_merging_3  lo8(-1335), hi8(-1335), lo8(1218),  hi8(1218),  lo8(-136),  hi8(-136),  lo8(-1215), hi8(-1215), lo8(-1421), hi8(-1421), lo8(107),   hi8(107),   lo8(732),   hi8(732)
        adiw    r30, 56

        inv_merging_3  lo8(384),   hi8(384),   lo8(-1465), hi8(-1465), lo8(-1285), hi8(-1285), lo8(1322),  hi8(1322),  lo8(830),   hi8(830),   lo8(-271),  hi8(-271),  lo8(1017),  hi8(1017)
        inv_merging_3  lo8(384),   hi8(384),   lo8(-1465), hi8(-1465), lo8(-1285), hi8(-1285), lo8(1322),  hi8(1322),  lo8(830),   hi8(830),   lo8(-271),  hi8(-271),  lo8(1017),  hi8(1017)
        adiw    r30, 56

        inv_merging_3  lo8(610),   hi8(610),   lo8(603),   hi8(603),   lo8(1097),  hi8(1097),  lo8(817),   hi8(817),   lo8(-90),   hi8(-90),   lo8(-853),  hi8(-853),  lo8(-681),  hi8(-681)
        inv_merging_3  lo8(610),   hi8(610),   lo8(603),   hi8(603),   lo8(1097),  hi8(1097),  lo8(817),   hi8(817),   lo8(-90),   hi8(-90),   lo8(-853),  hi8(-853),  lo8(-681),  hi8(-681)
        adiw    r30, 56

        inv_merging_3  lo8(-75),   hi8(-75),   lo8(-156),  hi8(-156),  lo8(329),   hi8(329),   lo8(418),   hi8(418),   lo8(1469),  hi8(1469),  lo8(126),   hi8(126),   lo8(-130),  hi8(-130)
        inv_merging_3  lo8(-75),   hi8(-75),   lo8(-156),  hi8(-156),  lo8(329),   hi8(329),   lo8(418),   hi8(418),   lo8(1469),  hi8(1469),  lo8(126),   hi8(126),   lo8(-130),  hi8(-130)
        adiw    r30, 56

        inv_merging_3  lo8(349),   hi8(349),   lo8(-872),  hi8(-872),  lo8(644),   hi8(644),   lo8(-1590), hi8(-1590), lo8(-1162), hi8(-1162), lo8(-1618), hi8(-1618), lo8(-1602), hi8(-1602)
        inv_merging_3  lo8(349),   hi8(349),   lo8(-872),  hi8(-872),  lo8(644),   hi8(644),   lo8(-1590), hi8(-1590), lo8(-1162), hi8(-1162), lo8(-1618), hi8(-1618), lo8(-1602), hi8(-1602)
        adiw    r30, 56

        inv_merging_3  lo8(1119),  hi8(1119),  lo8(-602),  hi8(-602),  lo8(1483),  hi8(1483),  lo8(-777),  hi8(-777),  lo8(-666),  hi8(-666),  lo8(-320),  hi8(-320),  lo8(1458),  hi8(1458)
        inv_merging_3  lo8(1119),  hi8(1119),  lo8(-602),  hi8(-602),  lo8(1483),  hi8(1483),  lo8(-777),  hi8(-777),  lo8(-666),  hi8(-666),  lo8(-320),  hi8(-320),  lo8(1458),  hi8(1458)
        adiw    r30, 56

        inv_merging_3  lo8(-147),  hi8(-147),  lo8(1159),  hi8(1159),  lo8(778),   hi8(778),   lo8(-246),  hi8(-246),  lo8(-8),    hi8(-8),    lo8(516),   hi8(516),   lo8(-829),  hi8(-829)
        inv_merging_3  lo8(-147),  hi8(-147),  lo8(1159),  hi8(1159),  lo8(778),   hi8(778),   lo8(-246),  hi8(-246),  lo8(-8),    hi8(-8),    lo8(516),   hi8(516),   lo8(-829),  hi8(-829)
        adiw    r30, 56

        inv_merging_3  lo8(1653),  hi8(1653),  lo8(1574),  hi8(1574),  lo8(-460),  hi8(-460),  lo8(-291),  hi8(-291),  lo8(-1544), hi8(-1544), lo8(-282),  hi8(-282),  lo8(383),   hi8(383)
        inv_merging_3  lo8(1653),  hi8(1653),  lo8(1574),  hi8(1574),  lo8(-460),  hi8(-460),  lo8(-291),  hi8(-291),  lo8(-1544), hi8(-1544), lo8(-282),  hi8(-282),  lo8(383),   hi8(383)
        adiw    r30, 56

        inv_merging_3  lo8(-235),  hi8(-235),  lo8(177),   hi8(177),   lo8(587),   hi8(587),   lo8(422),   hi8(422),   lo8(1491),  hi8(1491),  lo8(-1293), hi8(-1293), lo8(264),   hi8(264)
        inv_merging_3  lo8(-235),  hi8(-235),  lo8(177),   hi8(177),   lo8(587),   hi8(587),   lo8(422),   hi8(422),   lo8(1491),  hi8(1491),  lo8(-1293), hi8(-1293), lo8(264),   hi8(264)
        adiw    r30, 56

        inv_merging_3  lo8(105),   hi8(105),   lo8(1550),  hi8(1550),  lo8(871),   hi8(871),   lo8(-1251), hi8(-1251), lo8(1015),  hi8(1015),  lo8(-552),  hi8(-552),  lo8(-1325), hi8(-1325)
        inv_merging_3  lo8(105),   hi8(105),   lo8(1550),  hi8(1550),  lo8(871),   hi8(871),   lo8(-1251), hi8(-1251), lo8(1015),  hi8(1015),  lo8(-552),  hi8(-552),  lo8(-1325), hi8(-1325)
        adiw    r30, 56

        inv_merging_3  lo8(843),   hi8(843),   lo8(555),   hi8(555),   lo8(430),   hi8(430),   lo8(-1103), hi8(-1103), lo8(652),   hi8(652),   lo8(1223),  hi8(1223),  lo8(573),   hi8(573)
        inv_merging_3  lo8(843),   hi8(843),   lo8(555),   hi8(555),   lo8(430),   hi8(430),   lo8(-1103), hi8(-1103), lo8(652),   hi8(652),   lo8(1223),  hi8(1223),  lo8(573),   hi8(573)

        ldi     r26, lo8(968)
        ldi     r27, hi8(968)
        sub     r30, r26
        sbc     r31, r27

        ldi     r26, lo8(3329)
        ldi     r27, hi8(3329)
        movw    KYBER_Q_L, r26

        ldi     r26, lo8(-3327)
        ldi     r27, hi8(-3327)
        movw    QINV_L, r26

        ldi     r16, lo8(1468)
        ldi     r17, hi8(1468)
        ldi     r18, lo8(-1474)
        ldi     r19, hi8(-1474)
        ldi     r14, lo8(202)
        ldi     r15, hi8(202)

layer4_merge2:

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        ldi     r26, lo8(192)
        ldi     r27, hi8(192)
        add     r30, r26
        adc     r31, r27

        ldi     r16, lo8(-1202)
        ldi     r17, hi8(-1202)
        ldi     r18, lo8(962)
        ldi     r19, hi8(962)
        ldi     r14, lo8(287)
        ldi     r15, hi8(287)

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        ldi     r26, lo8(192)
        ldi     r27, hi8(192)
        add     r30, r26
        adc     r31, r27

        ldi     r16, lo8(182)
        ldi     r17, hi8(182)
        ldi     r18, lo8(1577)
        ldi     r19, hi8(1577)
        ldi     r14, lo8(1422)
        ldi     r15, hi8(1422)

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        ldi     r26, lo8(192)
        ldi     r27, hi8(192)
        add     r30, r26
        adc     r31, r27

        ldi     r16, lo8(622)
        ldi     r17, hi8(622)
        ldi     r18, lo8(-171)
        ldi     r19, hi8(-171)
        ldi     r14, lo8(1493)
        ldi     r15, hi8(1493)

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192
        inv_merging_22  r16, r17, r18, r19, r14, r15, 0, 64, 128, 192

        ldi     r26, lo8(832)
        ldi     r27, hi8(832)
        sub     r30, r26
        sbc     r31, r27

        movw    r20, r30
        ldi     r26, lo8(256)
        ldi     r27, hi8(256)
        add     r20, r26
        adc     r21, r27

        ldi     r16, lo8(-1517)
        ldi     r17, hi8(-1517)
        ldi     r18, lo8(-359)
        ldi     r19, hi8(-359)
        ldi     r14, lo8(-758)
        ldi     r15, hi8(-758)

layer2_merge2:

        inv_merging_2  r16, r17, r18, r19, r14, r15, 0, 256, 512, 768

        cp      r30, r20
        cpc     r31, r21
        brmi    layer2_merge2

        ldi     r26, lo8(256)
        ldi     r27, hi8(256)
        sub     r30, r26
        sbc     r31, r27

        movw    r20, r30
        ldi     r26, lo8(1024)
        ldi     r27, hi8(1024)
        add     r20, r26
        adc     r21, r27

        ldi     r6, lo8(1441)
        ldi     r7, hi8(1441)

last_fqmul:

        la_fqmul

        cp      r30, r20
        cpc     r31, r21
        brmi    last_fqmul

        pop     r29
        pop     r28
        pop     r25
        pop     r24
        pop     r23
        pop     r22
        pop     r21
        pop     r20
        pop     r19
        pop     r18
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