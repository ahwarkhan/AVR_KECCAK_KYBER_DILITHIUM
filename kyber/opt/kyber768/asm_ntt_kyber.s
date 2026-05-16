#include <avr/io.h>

#define         KYBER_Q         r10
#define         QINV            r11

#define         mul_res_hi      r14

#define         ptrL            r30
#define         ptrH            r31

#define         forstopL        r20
#define         forstopH        r21

.macro load16 dst_lo, dst_hi, base_lo, base_hi, byte_offset
        ldi     r24, lo8(\byte_offset)
        ldi     r25, hi8(\byte_offset)
        movw    r26, r30
        add     r26, r24
        adc     r27, r25
        ld      \dst_lo, X+
        ld      \dst_hi, X
.endm

.macro store16 src_lo, src_hi, base_lo, base_hi, byte_offset
        ldi     r24, lo8(\byte_offset)
        ldi     r25, hi8(\byte_offset)
        movw    r26, r30
        add     r26, r24
        adc     r27, r25
        st      X+, \src_lo
        st      X, \src_hi
.endm

.macro muls16x16_hi prod_hi_lo, prod_hi_hi, aL, aH, bL, bH
        mul     \aL, \bL
        movw    r22, r0
        mulsu   \aH, \bL
        sbc     r25, r25
        add     r23, r0
        adc     r24, r1
        adc     r25, r25
        mulsu   \bH, \aL
        sbc     r17, r17
        add     r23, r0
        adc     r24, r1
        adc     r25, r17
        muls    \aH, \bH
        add     r24, r0
        adc     r25, r1
        movw    \prod_hi_lo, r24
.endm

.macro mont mul_low_lo, mul_low_hi, mul_hi_lo, mul_hi_hi

        muls16x16_hi    r22, r23, \mul_low_lo, \mul_low_hi, r11, r12

        muls16x16_hi    r22, r23, r22, r23, KYBER_Q, r13

        sub     \mul_hi_lo, r22
        sbc     \mul_hi_hi, r23

.endm

.macro mont_imd mul_low_lo, mul_low_hi, mul_hi_lo, mul_hi_hi

        ldi     r24, lo8(-3327)
        ldi     r25, hi8(-3327)
        muls16x16_hi    r22, r23, \mul_low_lo, \mul_low_hi, r24, r25

        ldi     r24, lo8(3329)
        ldi     r25, hi8(3329)
        muls16x16_hi    r22, r23, r22, r23, r24, r25

        sub     \mul_hi_lo, r22
        sbc     \mul_hi_hi, r23

.endm

.macro first_butter_fly src1_lo, src1_hi, src2_lo, src2_hi, zeta_lo, zeta_hi, byte_off

        load16  r6, r7, r30, r31, \byte_off

        muls16x16_hi    r14, r15, \zeta_lo, \zeta_hi, r6, r7

        muls16x16_hi    r22, r23, r14, r15, QINV, r13

        muls16x16_hi    r22, r23, r22, r23, KYBER_Q, r13

        sub     r14, r22
        sbc     r15, r23

        movw    \src2_lo, \src1_lo
        add     \src1_lo, r14
        adc     \src1_hi, r15
        sub     \src2_lo, r14
        sbc     \src2_hi, r15

.endm

.macro butter_fly src1_lo, src1_hi, src2_lo, src2_hi, zeta_lo, zeta_hi

        muls16x16_hi    r14, r15, \zeta_lo, \zeta_hi, \src2_lo, \src2_hi

        muls16x16_hi    r22, r23, r14, r15, QINV, r13

        muls16x16_hi    r22, r23, r22, r23, KYBER_Q, r13

        sub     r14, r22
        sbc     r15, r23

        movw    \src2_lo, \src1_lo
        add     \src1_lo, r14
        adc     \src1_hi, r15
        sub     \src2_lo, r14
        sbc     \src2_hi, r15

.endm

.macro first_butter_fly_imd src1_lo, src1_hi, src2_lo, src2_hi, zeta_lo, zeta_hi, byte_off

        load16  r6, r7, r30, r31, \byte_off

        muls16x16_hi    r14, r15, \zeta_lo, \zeta_hi, r6, r7

        ldi     r24, lo8(-3327)
        ldi     r25, hi8(-3327)
        muls16x16_hi    r22, r23, r14, r15, r24, r25

        ldi     r24, lo8(3329)
        ldi     r25, hi8(3329)
        muls16x16_hi    r22, r23, r22, r23, r24, r25

        sub     r14, r22
        sbc     r15, r23

        movw    \src2_lo, \src1_lo
        add     \src1_lo, r14
        adc     \src1_hi, r15
        sub     \src2_lo, r14
        sbc     \src2_hi, r15

.endm

.macro butter_fly_imd src1_lo, src1_hi, src2_lo, src2_hi, zeta_lo, zeta_hi

        muls16x16_hi    r14, r15, \zeta_lo, \zeta_hi, \src2_lo, \src2_hi

        ldi     r24, lo8(-3327)
        ldi     r25, hi8(-3327)
        muls16x16_hi    r22, r23, r14, r15, r24, r25

        ldi     r24, lo8(3329)
        ldi     r25, hi8(3329)
        muls16x16_hi    r22, r23, r22, r23, r24, r25

        sub     r14, r22
        sbc     r15, r23

        movw    \src2_lo, \src1_lo
        add     \src1_lo, r14
        adc     \src1_hi, r15
        sub     \src2_lo, r14
        sbc     \src2_hi, r15

.endm

.macro merging_2 zeta1_lo, zeta1_hi, zeta2_lo, zeta2_hi, zeta3_lo, zeta3_hi, byte_off1, byte_off2, byte_off3, byte_off4

        load16  r4, r5, r30, r31, \byte_off1
        load16  r6, r7, r30, r31, \byte_off2

        first_butter_fly    r4, r5, r8, r9, \zeta1_lo, \zeta1_hi, \byte_off3
        first_butter_fly    r6, r7, r9, r10, \zeta1_lo, \zeta1_hi, \byte_off4

        butter_fly          r4, r5, r6, r7, \zeta2_lo, \zeta2_hi
        butter_fly          r8, r9, r9, r10, \zeta3_lo, \zeta3_hi

        store16 r4, r5, r30, r31, \byte_off1
        store16 r6, r7, r30, r31, \byte_off2
        store16 r8, r9, r30, r31, \byte_off3
        store16 r9, r10, r30, r31, \byte_off4

        adiw    r30, 2

.endm

.macro merging_3 zeta1_lo, zeta1_hi, zeta2_lo, zeta2_hi, zeta3_lo, zeta3_hi, zeta4_lo, zeta4_hi, zeta5_lo, zeta5_hi, zeta6_lo, zeta6_hi, zeta7_lo, zeta7_hi

        load16  r4, r5, r30, r31, 0
        load16  r6, r7, r30, r31, 8
        load16  r8, r9, r30, r31, 16
        load16  r10, r11, r30, r31, 24

        first_butter_fly_imd    r4, r5, r12, r13, \zeta1_lo, \zeta1_hi, 32
        first_butter_fly_imd    r6, r7, r14, r15, \zeta1_lo, \zeta1_hi, 40
        first_butter_fly_imd    r8, r9, r16, r17, \zeta1_lo, \zeta1_hi, 48
        first_butter_fly_imd    r10, r11, r18, r19, \zeta1_lo, \zeta1_hi, 56

        butter_fly_imd          r4, r5, r8, r9, \zeta2_lo, \zeta2_hi
        butter_fly_imd          r6, r7, r10, r11, \zeta2_lo, \zeta2_hi
        butter_fly_imd          r12, r13, r16, r17, \zeta3_lo, \zeta3_hi
        butter_fly_imd          r14, r15, r18, r19, \zeta3_lo, \zeta3_hi

        butter_fly_imd          r4, r5, r6, r7, \zeta4_lo, \zeta4_hi
        butter_fly_imd          r8, r9, r10, r11, \zeta5_lo, \zeta5_hi
        butter_fly_imd          r12, r13, r14, r15, \zeta6_lo, \zeta6_hi
        butter_fly_imd          r16, r17, r18, r19, \zeta7_lo, \zeta7_hi

        store16 r4, r5, r30, r31, 0
        store16 r6, r7, r30, r31, 8
        store16 r8, r9, r30, r31, 16
        store16 r10, r11, r30, r31, 24
        store16 r12, r13, r30, r31, 32
        store16 r14, r15, r30, r31, 40
        store16 r16, r17, r30, r31, 48
        store16 r18, r19, r30, r31, 56

        adiw    r30, 2

.endm

.section .text

.global asm_ntt_merging
asm_ntt_merging:

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
        push    r28
        push    r29

        movw    r30, r24

        movw    r20, r30
        ldi     r24, lo8(128)
        ldi     r25, hi8(128)
        add     r20, r24
        adc     r21, r25

        ldi     r24, lo8(3329)
        ldi     r25, hi8(3329)
        movw    KYBER_Q, r24

        ldi     r24, lo8(-3327)
        ldi     r25, hi8(-3327)
        movw    QINV, r24

        ldi     r8, lo8(-758)
        ldi     r9, hi8(-758)
        ldi     r24, lo8(-359)
        ldi     r25, hi8(-359)
        movw    r10, r24
        ldi     r24, lo8(-1517)
        ldi     r25, hi8(-1517)
        movw    r12, r24

layer1_2merge:
        merging_2   r8, r9, r10, r11, r12, r13, 0, 256, 512, 768
        cp      r30, r20
        cpc     r31, r21
        brmi    layer1_2merge

        ldi     r24, lo8(128)
        ldi     r25, hi8(128)
        sub     r30, r24
        sbc     r31, r25

        ldi     r24, lo8(96)
        ldi     r25, hi8(96)
        sub     r20, r24
        sbc     r21, r25

        ldi     r8, lo8(1493)
        ldi     r9, hi8(1493)
        ldi     r24, lo8(-171)
        ldi     r25, hi8(-171)
        movw    r10, r24
        ldi     r24, lo8(622)
        ldi     r25, hi8(622)
        movw    r12, r24

layer3_2merge_1:
        merging_2   r8, r9, r10, r11, r12, r13, 0, 64, 128, 192
        cp      r30, r20
        cpc     r31, r21
        brmi    layer3_2merge_1

        ldi     r24, lo8(96)
        ldi     r25, hi8(96)
        add     r30, r24
        adc     r31, r25

        ldi     r24, lo8(128)
        ldi     r25, hi8(128)
        add     r20, r24
        adc     r21, r25

        ldi     r8, lo8(1422)
        ldi     r9, hi8(1422)
        ldi     r24, lo8(1577)
        ldi     r25, hi8(1577)
        movw    r10, r24
        ldi     r24, lo8(182)
        ldi     r25, hi8(182)
        movw    r12, r24

layer3_2merge_2:
        merging_2   r8, r9, r10, r11, r12, r13, 0, 64, 128, 192
        cp      r30, r20
        cpc     r31, r21
        brmi    layer3_2merge_2

        ldi     r24, lo8(96)
        ldi     r25, hi8(96)
        add     r30, r24
        adc     r31, r25

        ldi     r24, lo8(128)
        ldi     r25, hi8(128)
        add     r20, r24
        adc     r21, r25

        ldi     r8, lo8(287)
        ldi     r9, hi8(287)
        ldi     r24, lo8(962)
        ldi     r25, hi8(962)
        movw    r10, r24
        ldi     r24, lo8(-1202)
        ldi     r25, hi8(-1202)
        movw    r12, r24

layer3_2merge_3:
        merging_2   r8, r9, r10, r11, r12, r13, 0, 64, 128, 192
        cp      r30, r20
        cpc     r31, r21
        brmi    layer3_2merge_3

        ldi     r24, lo8(96)
        ldi     r25, hi8(96)
        add     r30, r24
        adc     r31, r25

        ldi     r24, lo8(128)
        ldi     r25, hi8(128)
        add     r20, r24
        adc     r21, r25

        ldi     r8, lo8(202)
        ldi     r9, hi8(202)
        ldi     r24, lo8(-1474)
        ldi     r25, hi8(-1474)
        movw    r10, r24
        ldi     r24, lo8(1468)
        ldi     r25, hi8(1468)
        movw    r12, r24

layer3_2merge_4:
        merging_2   r8, r9, r10, r11, r12, r13, 0, 64, 128, 192
        cp      r30, r20
        cpc     r31, r21
        brmi    layer3_2merge_4

        ldi     r24, lo8(416)
        ldi     r25, hi8(416)
        sub     r30, r24
        sbc     r31, r25

layer5_3merge:
        merging_3   lo8(573), hi8(573), lo8(1223), hi8(1223), lo8(652), hi8(652), lo8(-1103), hi8(-1103), lo8(430), hi8(430), lo8(555), hi8(555), lo8(843), hi8(843)
        merging_3   lo8(573), hi8(573), lo8(1223), hi8(1223), lo8(652), hi8(652), lo8(-1103), hi8(-1103), lo8(430), hi8(430), lo8(555), hi8(555), lo8(843), hi8(843)
        adiw    r30, 56

        merging_3   lo8(-1325), hi8(-1325), lo8(-552), hi8(-552), lo8(1015), hi8(1015), lo8(-1251), hi8(-1251), lo8(871), hi8(871), lo8(1550), hi8(1550), lo8(105), hi8(105)
        merging_3   lo8(-1325), hi8(-1325), lo8(-552), hi8(-552), lo8(1015), hi8(1015), lo8(-1251), hi8(-1251), lo8(871), hi8(871), lo8(1550), hi8(1550), lo8(105), hi8(105)
        adiw    r30, 56

        merging_3   lo8(264), hi8(264), lo8(-1293), hi8(-1293), lo8(1491), hi8(1491), lo8(422), hi8(422), lo8(587), hi8(587), lo8(177), hi8(177), lo8(-235), hi8(-235)
        merging_3   lo8(264), hi8(264), lo8(-1293), hi8(-1293), lo8(1491), hi8(1491), lo8(422), hi8(422), lo8(587), hi8(587), lo8(177), hi8(177), lo8(-235), hi8(-235)
        adiw    r30, 56

        merging_3   lo8(383), hi8(383), lo8(-282), hi8(-282), lo8(-1544), hi8(-1544), lo8(-291), hi8(-291), lo8(-460), hi8(-460), lo8(1574), hi8(1574), lo8(1653), hi8(1653)
        merging_3   lo8(383), hi8(383), lo8(-282), hi8(-282), lo8(-1544), hi8(-1544), lo8(-291), hi8(-291), lo8(-460), hi8(-460), lo8(1574), hi8(1574), lo8(1653), hi8(1653)
        adiw    r30, 56

        merging_3   lo8(-829), hi8(-829), lo8(516), hi8(516), lo8(-8), hi8(-8), lo8(-246), hi8(-246), lo8(778), hi8(778), lo8(1159), hi8(1159), lo8(-147), hi8(-147)
        merging_3   lo8(-829), hi8(-829), lo8(516), hi8(516), lo8(-8), hi8(-8), lo8(-246), hi8(-246), lo8(778), hi8(778), lo8(1159), hi8(1159), lo8(-147), hi8(-147)
        adiw    r30, 56

        merging_3   lo8(1458), hi8(1458), lo8(-320), hi8(-320), lo8(-666), hi8(-666), lo8(-777), hi8(-777), lo8(1483), hi8(1483), lo8(-602), hi8(-602), lo8(1119), hi8(1119)
        merging_3   lo8(1458), hi8(1458), lo8(-320), hi8(-320), lo8(-666), hi8(-666), lo8(-777), hi8(-777), lo8(1483), hi8(1483), lo8(-602), hi8(-602), lo8(1119), hi8(1119)
        adiw    r30, 56

        merging_3   lo8(-1602), hi8(-1602), lo8(-1618), hi8(-1618), lo8(-1162), hi8(-1162), lo8(-1590), hi8(-1590), lo8(644), hi8(644), lo8(-872), hi8(-872), lo8(349), hi8(349)
        merging_3   lo8(-1602), hi8(-1602), lo8(-1618), hi8(-1618), lo8(-1162), hi8(-1162), lo8(-1590), hi8(-1590), lo8(644), hi8(644), lo8(-872), hi8(-872), lo8(349), hi8(349)
        adiw    r30, 56

        merging_3   lo8(-130), hi8(-130), lo8(126), hi8(126), lo8(1469), hi8(1469), lo8(418), hi8(418), lo8(329), hi8(329), lo8(-156), hi8(-156), lo8(-75), hi8(-75)
        merging_3   lo8(-130), hi8(-130), lo8(126), hi8(126), lo8(1469), hi8(1469), lo8(418), hi8(418), lo8(329), hi8(329), lo8(-156), hi8(-156), lo8(-75), hi8(-75)
        adiw    r30, 56

        merging_3   lo8(-681), hi8(-681), lo8(-853), hi8(-853), lo8(-90), hi8(-90), lo8(817), hi8(817), lo8(1097), hi8(1097), lo8(603), hi8(603), lo8(610), hi8(610)
        merging_3   lo8(-681), hi8(-681), lo8(-853), hi8(-853), lo8(-90), hi8(-90), lo8(817), hi8(817), lo8(1097), hi8(1097), lo8(603), hi8(603), lo8(610), hi8(610)
        adiw    r30, 56

        merging_3   lo8(1017), hi8(1017), lo8(-271), hi8(-271), lo8(830), hi8(830), lo8(1322), hi8(1322), lo8(-1285), hi8(-1285), lo8(-1465), hi8(-1465), lo8(384), hi8(384)
        merging_3   lo8(1017), hi8(1017), lo8(-271), hi8(-271), lo8(830), hi8(830), lo8(1322), hi8(1322), lo8(-1285), hi8(-1285), lo8(-1465), hi8(-1465), lo8(384), hi8(384)
        adiw    r30, 56

        merging_3   lo8(732), hi8(732), lo8(107), hi8(107), lo8(-1421), hi8(-1421), lo8(-1215), hi8(-1215), lo8(-136), hi8(-136), lo8(1218), hi8(1218), lo8(-1335), hi8(-1335)
        merging_3   lo8(732), hi8(732), lo8(107), hi8(107), lo8(-1421), hi8(-1421), lo8(-1215), hi8(-1215), lo8(-136), hi8(-136), lo8(1218), hi8(1218), lo8(-1335), hi8(-1335)
        adiw    r30, 56

        merging_3   lo8(608), hi8(608), lo8(-247), hi8(-247), lo8(-951), hi8(-951), lo8(-874), hi8(-874), lo8(220), hi8(220), lo8(-1187), hi8(-1187), lo8(-1659), hi8(-1659)
        merging_3   lo8(608), hi8(608), lo8(-247), hi8(-247), lo8(-951), hi8(-951), lo8(-874), hi8(-874), lo8(220), hi8(220), lo8(-1187), hi8(-1187), lo8(-1659), hi8(-1659)
        adiw    r30, 56

        merging_3   lo8(-1542), hi8(-1542), lo8(-398), hi8(-398), lo8(961), hi8(961), lo8(-1185), hi8(-1185), lo8(-1530), hi8(-1530), lo8(-1278), hi8(-1278), lo8(794), hi8(794)
        merging_3   lo8(-1542), hi8(-1542), lo8(-398), hi8(-398), lo8(961), hi8(961), lo8(-1185), hi8(-1185), lo8(-1530), hi8(-1530), lo8(-1278), hi8(-1278), lo8(794), hi8(794)
        adiw    r30, 56

        merging_3   lo8(411), hi8(411), lo8(-1508), hi8(-1508), lo8(-725), hi8(-725), lo8(-1510), hi8(-1510), lo8(-854), hi8(-854), lo8(-870), hi8(-870), lo8(478), hi8(478)
        merging_3   lo8(411), hi8(411), lo8(-1508), hi8(-1508), lo8(-725), hi8(-725), lo8(-1510), hi8(-1510), lo8(-854), hi8(-854), lo8(-870), hi8(-870), lo8(478), hi8(478)
        adiw    r30, 56

        merging_3   lo8(-205), hi8(-205), lo8(448), hi8(448), lo8(-1065), hi8(-1065), lo8(-108), hi8(-108), lo8(-308), hi8(-308), lo8(996), hi8(996), lo8(991), hi8(991)
        merging_3   lo8(-205), hi8(-205), lo8(448), hi8(448), lo8(-1065), hi8(-1065), lo8(-108), hi8(-108), lo8(-308), hi8(-308), lo8(996), hi8(996), lo8(991), hi8(991)
        adiw    r30, 56

        merging_3   lo8(-1571), hi8(-1571), lo8(677), hi8(677), lo8(-1275), hi8(-1275), lo8(958), hi8(958), lo8(-1460), hi8(-1460), lo8(1522), hi8(1522), lo8(1628), hi8(1628)
        merging_3   lo8(-1571), hi8(-1571), lo8(677), hi8(677), lo8(-1275), hi8(-1275), lo8(958), hi8(958), lo8(-1460), hi8(-1460), lo8(1522), hi8(1522), lo8(1628), hi8(1628)

        pop     r29
        pop     r28
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

        ret