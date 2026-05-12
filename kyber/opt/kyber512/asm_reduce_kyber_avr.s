; ---------------------------------------------------------------
;  AVR assembler implementation of reduction & to‑Montgomery routines
;  for Kyber512.
;  Public symbols: asm_poly_tomont, asm_poly_barrett, asm_NTT_poly_barrett
; ---------------------------------------------------------------

#include <avr/io.h>

; -------------------------------------------------------------------
;  Macros
; -------------------------------------------------------------------

; --- Montgomery multiplication step: *X = a * 1353 mod 3329 ---------
;     On entry X points to the 16‑bit coefficient (little‑endian).
;     On exit X is advanced by 2, r2 must contain 0.
;     Uses r0,r1, r16‑r25, trashes them.
.macro montmul_step
    ; 1) load a (16 bit) from X
    ld   r24, X        ; low byte
    ldd  r25, X+1      ; high byte

    ; 2) multiply by f = 1353 (0x0549) → 32‑bit product in r18..r21
    ldi  r22, 0x49      ; f low
    ldi  r23, 0x05      ; f high

    mul  r24, r22       ; a_low * f_low
    movw r18, r0         ; r18:r19 = low word
    mul  r24, r23       ; a_low * f_high
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2         ; r2 is zero
    mul  r25, r22       ; a_high * f_low
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23       ; a_high * f_high
    add  r20, r0
    adc  r21, r1
    ; Product: r18(LSB) r19 r20 r21(MSB)   low word r19:r18, high word r21:r20

    ; 3) save original high word
    movw r16, r20        ; r16 = r20, r17 = r21   (high word)

    ; 4) compute t = (low_word * qinv) & 0xFFFF,  qinv = 0xF301
    ldi  r22, 0x01       ; qinv low
    ldi  r23, 0xF3       ; qinv high

    mul  r18, r22       ; low_low * qinv_low → t low
    movw r24, r0
    mul  r18, r23       ; low_low * qinv_high → add to high byte of t
    add  r25, r0
    mul  r19, r22       ; low_high * qinv_low → add to high byte
    add  r25, r0
    ; t in r25:r24 (high:low)

    ; 5) multiply t * q  (q = 3329 = 0x0D01)
    ldi  r22, 0x01       ; q low
    ldi  r23, 0x0D       ; q high

    mul  r24, r22
    movw r18, r0
    mul  r24, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r25, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23
    add  r20, r0
    adc  r21, r1
    ; t*q product: r18:r19 low, r20:r21 high (r21:r20 is high word)

    ; 6) subtract high words: (orig_high) - (t*q_high)
    sub  r16, r20
    sbc  r17, r21
    ; result in r17:r16

    ; 7) conditional add q if borrow (C=0)
    brcs no_add
    ldi  r24, 0x01
    ldi  r25, 0x0D
    add  r16, r24
    adc  r17, r25
no_add:

    ; 8) store back to X and advance pointer
    st   X, r16          ; low byte
    std  X+1, r17        ; high byte
    adiw X, 2
.endm


; --- Barrett reduction step (parameterised) ------------------------
;     On entry X points to coefficient, on exit X advanced by 2.
;     V  – multiplier (immediate)
;     WORD – additive term (immediate, normally 0x200 or 0)
;     q  – modulus (3329) already in r22:r23 or loaded inside macro.
;     Uses r0,r1,r16‑r25, and r2 as zero.
.macro barrett_step V, WORD
    ; 1) load a from X
    ld   r24, X
    ldd  r25, X+1
    ; 2) multiply a * V → 32‑bit product, keep high word in r20:r21
    ;    We'll load V into r22:r23
    ldi  r22, lo8(\V)
    ldi  r23, hi8(\V)

    mul  r24, r22
    movw r18, r0
    mul  r24, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r25, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23
    add  r20, r0
    adc  r21, r1
    ; high word of product is r21:r20

    ; 3) hi = high word + WORD
    ldi  r24, lo8(\WORD)
    ldi  r25, hi8(\WORD)
    add  r20, r24
    adc  r21, r25
    ; result in r21:r20

    ; 4) do the strange swpb + sxt + rra rra sequence

    ; copy to r25:r24
    movw r24, r20        ; r25:r24 = hi+WORD

    ; swap bytes
    mov  r18, r24
    mov  r24, r25
    mov  r25, r18        ; now swapped

    ; sign‑extend the low byte of the swapped value (now in r24)
    ; r24 holds the byte that was the original high byte.
    ; We'll sign‑extend r24 into r19 (high byte).
    mov  r19, r24
    lsl  r19             ; shift bit 7 into carry
    sbc  r19, r19        ; r19 = 0x00 if r24 positive, 0xFF if negative
    ; now the 16‑bit signed value is r19:r24

    ; arithmetic right shift twice
    asr  r19
    ror  r24
    asr  r19
    ror  r24
    ; t = r19:r24 (signed).

    ; 5) multiply t by q (3329) → 32‑bit, keep low 16 bits
    ;    q = 3329 = 0x0D01
    ldi  r22, 0x01
    ldi  r23, 0x0D
    mul  r24, r22
    movw r18, r0
    mul  r24, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r25, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23
    add  r20, r0
    adc  r21, r1
    ; low 16 bits of t*q are r19:r18

.endm

; -------------------------------------------------------------------
;  Public functions
; -------------------------------------------------------------------

.section .text

; ------------------------------------------------------
; void asm_poly_tomont(int16_t *a)
;   a is passed in r25:r24 (first argument)
; ------------------------------------------------------
.global asm_poly_tomont
.func asm_poly_tomont
asm_poly_tomont:
    push r2               ; r2 = 0
    push r28
    push r29              ; Y will be forstop
    clr  r2               ; zero register

    ; move pointer to X (r26:r27)
    movw r26, r24
    ; compute forstop = a + 512 in Y
    movw r28, r24
    adiw r28, 512

loop_tomont:
    montmul_step
    ; compare X with Y (forstop)
    cp   r26, r28
    cpc  r27, r29
    brne loop_tomont

    pop  r29
    pop  r28
    pop  r2
    ret
.endfunc


; ------------------------------------------------------
; void asm_poly_barrett(int16_t *a)
;   Barrett reduction with V = 0x4EBF, WORD = 0x200
; ------------------------------------------------------
.global asm_poly_barrett
.func asm_poly_barrett
asm_poly_barrett:
    push r2
    push r28
    push r29
    clr  r2               ; zero

    movw r26, r24         ; X = a
    movw r28, r26
    adiw r28, 512         ; Y = a+512

    ; Constants for this Barrett version
    ; V = 0x4EBF, WORD = 0x0200, q = 3329
loop_barrett_v1:
    ; load a into r16:r17
    ld   r16, X
    ldd  r17, X+1

    ; multiply a by V (0x4EBF)
    ldi  r22, lo8(0x4EBF)
    ldi  r23, hi8(0x4EBF)
    mul  r16, r22
    movw r18, r0
    mul  r16, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r17, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r17, r23
    add  r20, r0
    adc  r21, r1
    ; high word r21:r20

    ; add WORD (0x200)
    subi r20, lo8(-0x200)  ; add 0x200
    sbci r21, hi8(-0x200)

    ; swpb, sxt, rra,rra sequence
    movw r24, r20          ; r25:r24 = hi+WORD
    ; swap bytes
    mov  r18, r24
    mov  r24, r25
    mov  r25, r18

    ; sign‑extend r24 (low byte) to r19
    mov  r19, r24
    lsl  r19
    sbc  r19, r19
    ; signed value in r19:r24
    asr  r19
    ror  r24
    asr  r19
    ror  r24       ; now t in r19:r24

    ; multiply t * q (3329)
    ldi  r22, 0x01
    ldi  r23, 0x0D
    mul  r24, r22
    movw r18, r0
    mul  r24, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r25, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23
    add  r20, r0
    adc  r21, r1
    ; low word r19:r18

    ; subtract from original a (r16:r17)
    sub  r16, r18
    sbc  r17, r19
    ; store back
    st   X, r16
    std  X+1, r17
    adiw X, 2

    cp   r26, r28
    cpc  r27, r29
    brne loop_barrett_v1

    pop  r29
    pop  r28
    pop  r2
    ret
.endfunc


; ------------------------------------------------------
; void asm_NTT_poly_barrett(int16_t *a)
;   Barrett reduction with V = 20, WORD = 0
; ------------------------------------------------------
.global asm_NTT_poly_barrett
.func asm_NTT_poly_barrett
asm_NTT_poly_barrett:
    push r2
    push r28
    push r29
    clr  r2

    movw r26, r24
    movw r28, r26
    adiw r28, 512

loop_barrett_v2:
    ld   r16, X
    ldd  r17, X+1

    ; multiply a by V = 20
    ldi  r22, 20
    ldi  r23, 0
    mul  r16, r22
    movw r18, r0
    mul  r16, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r17, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r17, r23
    add  r20, r0
    adc  r21, r1
    ; high word r21:r20

    ; WORD = 0, so no addition (add zero would be no‑op)

    ; swpb, sxt, rra,rra
    movw r24, r20
    mov  r18, r24
    mov  r24, r25
    mov  r25, r18

    mov  r19, r24
    lsl  r19
    sbc  r19, r19
    asr  r19
    ror  r24
    asr  r19
    ror  r24

    ; t * q
    ldi  r22, 0x01
    ldi  r23, 0x0D
    mul  r24, r22
    movw r18, r0
    mul  r24, r23
    add  r19, r0
    adc  r20, r1
    clr  r21
    adc  r21, r2
    mul  r25, r22
    add  r19, r0
    adc  r20, r1
    adc  r21, r2
    mul  r25, r23
    add  r20, r0
    adc  r21, r1

    sub  r16, r18
    sbc  r17, r19
    st   X, r16
    std  X+1, r17
    adiw X, 2

    cp   r26, r28
    cpc  r27, r29
    brne loop_barrett_v2

    pop  r29
    pop  r28
    pop  r2
    ret
.endfunc

.end