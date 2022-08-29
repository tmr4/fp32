; fp32.s

.export str2fp32, pushu32
.export fadd32, fsub32, fmult32, fdiv32
.export fsquare32
.export ftrunc32, floor32, fround32, uitrunc32

.macro acc8
        .a8
        sep #$20
.endmacro
.macro acc16
        .a16
        rep #$20
.endmacro

SHORT = 0       ; use faster mult10 routine; set to 1 for slower but smaller code footprint

.P816
.a16
.i16

; modified from: http://65xx.unet.bz/fpu.txt
; or: https://web.archive.org/web/20170923012704/http://65xx.unet.bz:80/fpu.txt if above is gone
; for a discussion of the original code see: http://forum.6502.org/viewtopic.php?f=2&t=4133

; Original author's copyright:
;;
;; Copyright (c) 2016 Marco Granati <mg@unet.bz>
;;
;; Permission to use, copy, modify, and distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
;;

;*****************************************************************************
; 32-bit floating-point routines (call with 16-bit registers and the X 
; register pointing to the top of the floating-point stack which will point
; to the result of floating-point operations on return):
;
;       fadd32, fsub32          x+y, x-y
;       fmult32, fdiv32         x*y, x/y
;       fsquare32               x^2
;       ftrunc32, uitrunc32     truncating functions
;       floor32, fround32       rounding functions
;       pushu32                 convert unsigned int to float and push to fp stack
;       str2fp32                convert ascii string to float and push to fp stack
;
;       more to come as I have a need
;
;*****************************************************************************
; Why make a 32-bit version:
; 128-bit floating-point is great to have for the 65816 if you need the precision
; but if you don't the extra precision consumes a lot of cycles that serve no
; purpose.  Also, a fair number of cycles are needed to switch to the dedicated
; floating-point direct page and load arguments and retrieve results from the
; dedicated floating-point registers.  I've greatly reduced this overhead by
; using a floating-point stack.  I found the 32-bit package about 5.5 times
; faster than the 128-bit version running a Mandelbrot Set calculation.  I
; haven't done any optimization so perhaps this advantage could be increased.
;
;*****************************************************************************
; Use:
;       Unlike Marco's original 128-bit fp package which uses a dedicated
;       direct page and floating-point regisers, this package utilizes a
;       floating-point stack indexed with the X register.  This loses some
;       efficiency Marco gained by using faster address modes, but it gains
;       efficiency by not having to load and unload the registers for every
;       operation.
;
;       To use, allocate a region of Bank 0 to serve as a floating-point stack.
;       Maintain a pointer to this stack and load the X register with it prior
;       to calling any of the floating-point functions.  Save the pointer
;       upon return from the function as it might have been changed by the
;       operation.  You might think the fp routines should switch to the stack
;       but this is inefficient as it adds overhead to each fp call, whereas 
;       switching to the fp stack before the call allows several fp operations
;       to be called in succession.
;
;       The functions utilize the top two entries on the stack.  Marcos'
;       dedicated registers, the accumulator and argument, are equivalent to
;       top of the stack value, TOS, and the next on stack value, NOS, respectively.
;
;       Each entry on the floating-point stack consists of 8 bytes.  The first
;       four bytes are the floating-point mantissa, with 24-bits devoted to
;       the IEEE-754 single precision mantissa (including the hidden 1) and
;       eight guard bits used for rounding (as well as making the algorithms
;       easier to handle with 16-bit registers).  These are stored little 
;       endian style, with the most significant byte highest in memory. The
;       exponent comes next, with two bytes (only one used for 32-bit, but
;       kept as a word for computational ease).  A sign byte and status byte
;       follow.  *** TODO: consider combining exponent and sign bytes and
;       eliminating the status byte ***
;
;       There are no dedicated floating-point registers.  Your routines need
;       to interact with values on the floating-point stack. The stack fills
;       downward.  Functions that consume an operand will increase the stack
;       pointer by 8 bytes.  Functions that add an item to the stack will
;       decrease the pointer by 8 bytes.   
;
;*****************************************************************************
; Notes on port to ca65:
;       Marco used an assembler/linker from the 2500AD assembler series.  I've
;       ported the original 128-bit version to CA65.  It's available in the
;       file  "fp.s".  These port notes are relevant to that file but may be
;       useful in reviewing the code here as well.
;
;       * Assembler notation:
;               * Replace register size macros with mine, acc8 acc16 index8 index16 reg8 and reg16
;                 (the few instances where clear carry is included I replaced manually)
;                 *** The 32-bit package has been rewritten with 16-bit registers
;                     throughout, switching to an 8-bit accumulator  only when needed. ***
;               * Register size directives replaced with .a8 .a16 .i8 .i16
;               * DPFPU put in a direct segment with config file changes noted above
;               * Labels need a : in ca65
;               * .SEG. -> ^
;               * .EQU -> =
;               * .DS  -> .res
;               * .DB  -> .byte
;               * .DW  -> .word
;               *  LP  -> .res 3
;               *  $   -> *
;               *  ?   -> @
;               *  !   -> a: f: or .loword() (see below)
;               * I assume negative constants are intended to be byte size based on usage (ca85 defaults to word size symbols)
;               * #'NI' -> #'I' and #'AN' -> #'A' *** TODO: since we're in acc16 could try "AN" ***
;               * strip whitespace between instruction mnemonic and operand with 
;                 "(?<=([a-z][a-z][a-z]))        (?=([<>@#a-z]))" regular expression 
;       * line 3327 stz fexp+1 I assume is stz fexph+1
;       * Added missing ':' to ?kfmt label (perhaps authors assembler doesn't require this, but ca65 does w/o an option at least)
;
;       Though not stated explicitly, it seems the original code was designed to be in Bank 0.
;       Some tranlation is needed with my code in Bank 1.  References to data within
;       the code segment need far reference qualifiers (unless otherwise handled as in all cases
;       where immediate addressing is used to get the address and then long addressing is used with
;       the proper bank byte) and data within direct page need an absolute refererence qualifier.  Thus ! address qualifiers have been
;       replaced with a: or f: qualifiers as appropriate.  Several immediate references 
;       (with or without !) were replaced with .loword as a: doesn't work there. For
;       example in scale10, fexp2, fexp, fexp10.  One instance fcaddr in scale10 needs a far refernce
;       as here we're dereferencing some calculated references.
;
;*****************************************************************************
; Stack Notation:
; I use standard Forth stack notation here, as in ( F: r1 r2 -- r3 ), to represent
; the floating-point values on the stack before and after a function call.
; Here r1 and r2 are the values on the stack before the call and r3 is the value
; on the stack after the call.  r2 is on the top of the stack, or TOS and r1 is
; next on stack, or NOS.  r3 is the result of the function and is on the top of the
; stack.  This means the function has deleted a value on the stack by incrementing
; the floating-point stack pointer in the X register.  You should save this upon 
; return from a fp call and restore it to the X register prior to the next fp call.
;
; The TOS and NOS values can be considered psuedo registers as they are used in
; the various floating-point functions.  The structure of these psuedo registers is:
;
; TOSm:   .res  4         ; mantissa (24 bits including hidden 1) + guard bits (8 bits)
; TOSe:   .word 0         ; biased exponent
; TOSsgn: .byte 0         ; mantissa sign
; TOSst:  .byte 0         ; status of floating-point value
;                               ; *** I haven't paid much attention to the status
;                                     byte so take it with a grain of salt for now.
                                ; <7>: 1 if TOS is invalid (nan or inf)
                                ; <6>: 1 if TOS=inf (with <7>=1)   
                                ;      0 if TOS=nan (with <7>=1)   
                                ; <6>: 1 if TOS=0   (with <7>=0)
                                ; <5>: always '0'

                                ; TOS status for long integer
                                ; <7>: 1 if TOSm will be regarded as 'signed'
                                ; <6>: 1 if TOSm = 0
                                ; <5>: always '1'

; 32-bit floating-point stack offsets
TOSm   = 0
TOSe   = 4
TOSsgn = 6
TOSst  = 7

NOSm   = TOSm   + FP_size
NOSe   = TOSe   + FP_size
NOSsgn = TOSsgn + FP_size
NOSst  = TOSst  + FP_size

;*****************************************************************************
; Variables
;
; The following variables can be located either in the current direct page or data bank

; The following variables are used in routines that could benefit from the faster direct
; page access.  For best performance locate them on the direct page.  If you're trying to
; preserve direct page memory, these can be placed in the current data bank.

.zeropage
;.segment "EXBSS"
tm:             .dword 0               ; .dword
tmsgn:          .word 0
tmpa:           .word 0
tmp1:           .word 0
tmp2:           .word 0
fexph:          .word 0
TOSext:         .word 0
sgncmp:         .word 0

; The following variables are used in str2fp32 only.  You shouldn't see much performance
; improvement locating these on the direct page unless you're converting a lot of strings
; to fp.

;.zeropage
.segment "EXBSS"
tmcnt:          .word 0
tmdot:          .word 0
tesgn:          .word 0
tecnt:          .word 0
strl:           .word 0


;*****************************************************************************
; Constants
; *** TODO: clean this section up ***

; status register
PVFLAG = %01000000        ; Overflow flag
FP_size = 8                     ; bytes per cell in Forth 32-bit floating-point stack

MNTBITS32 = (4*8)                       ; mantissa bits + guard bits
MANTSIZ32 = 4                           ; mantissa size in bytes
MAXBSHIFT32 = .loword(-MNTBITS32 + 1)   ; max. shift mant.

EBIAS32 = $7F           ; shift internal TOSe right 1 bit to get upper two hex digits of IEEE-754 representation
; infinity is all exponent bits - 1
; *** TODO: probably don't need a separate value here ***
INFEXP32 = $FFFF                      ; inf/nan biased exponent
; *** TODO: need to work on these for 32-bit ***
INFSND = $8000          ; infinity high word mantissa
NANSND = $C000          ; nan high word mantissa
MAXEXP32 = $FE          ; max. biased exponent
SNBITS32 = 24           ; significand bits

BIAS8 = (EBIAS32 + 7)   ; bias exponent for 8 bit integer
BIAS16 = (BIAS8 + 8)    ; bias exponent for 16 bit integer
BIAS32 = (BIAS16 + 16)  ; bias exponent for 32 bit integer

.code
;*****************************************************************************
; FP Code

; faddhalf - add 0.5 to TOS
faddhalf:
        jsr push0d5                ; load 0.5 to TOS...
        bra fadd32                ; ...and execute TOS+NOS

; faddone - add 1.0 to TOS
faddone:
        jsr push1                ; load 1.0 to TOS...
        bra fadd32                ; ...and execute TOS+NOS

; fsubone - subtract 1.0 from TOS
fsubone:
        jsr push1                ; load 1.0 to TOS...
        acc8
        lda #$FF
        sta TOSsgn,x                ; ...change sign to arg...
        acc16
        bra fadd32                ; ...and execute TOS+NOS


; fsub32 ( F: r1 r2 -- r3 )
; Subtract r2 from r1, giving r3
fsub32:
        ; *** TODO: consider making sign a word or combining with exponent ***
        ; change sign of r2
        lda TOSsgn,x            ; note we've got the status by here as well
        eor #$0080              ; set msb of low byte, don't change high byte
        sta TOSsgn,x

        ; and execute r1 + (-r2)


; fadd32 ( F: r1 r2 -- r3 )
; Add r1 to r2 giving the sum r3
fadd32:
; The smaller operand is aligned by shifting its mantissa right and
; incrementing the exponent until it is equal to exponent of the larger
; operand. After alignment, the mantissa of TOS is added to mantissa of NOS if
; they have same sign, otherwise the mantissa of the smallest operand will
; be subtracted from mantissa of the larger one (except when the exponents
; are equal when we may need to change the sign of the result).
;
        jsr addtst32            ; operand test: check for same sign, inf,nan, 0
        sec

        ; determine which operand is larger and calculate the number
        ; of right shifts needed to align the mantissas 
        ; (use a negative value to simplify shifting)
        lda NOSe,x
        sbc TOSe,x              ; negative shift amount
        beq @go                 ; same exponents? => already aligned, goto add/sub
        bcc @sNOS               ; NOS < TOS? => shift NOS mantissa

        ; NOS > TOS so shift TOS mantissa
        ; recompute negative shift amount
        ; result has same exponent and sign of NOS, so we don't need to change them
        lda TOSe,x              ; carry is already set
        sbc NOSe,x

        ; shift TOS mantissa to the right
        cmp #MAXBSHIFT32        ; shift out whole mantissa?
        bcs @sTOS               ; no? => goto partial shift
        stz TOSm,x              ; clear whole mantissa
        stz TOSm+2,x
        bra @go                 ; goto add/sub

@sTOS:
;        jsr shrTOSm             ; shift TOS mantissa to right by A
        jsr shrmx32             ; shift TOS mantissa to right by A
        bra @go                 ; goto add/sub

@sNOS:  ; TOS > NOS so shift NOS mantissa
        ; set result's exponent to TOS
        ldy TOSe,x
        sty NOSe,x

        ; shift NOS mantissa to the right
        cmp #MAXBSHIFT32        ; shift out whole mantissa?
        bcs @sNOSm              ; no? => goto partial shift
        stz NOSm,x              ; clear whole mantissa
        stz NOSm+2,x

@sNOSm:
        ; *** we could eliminate shrNOSm code with below,
        ;     but a dedicated routine is fater but code is bigger ***
;        phx                     ; save FPSP
;        tay                     ; save shift amount
;        txa                     ; adjust X to point to NOS
;        clc
;        adc #FP_size
;        tax                     ; set FPSP to NOS
;        tya                     ; retrieve shift amount
;        jsr shrmx32             ; shift NOS mantissa to right by A
;        plx                     ; retrieve FPSP
        jsr shrNOSm             ; shift NOS mantissa to right by A

        ldy sgncmp              ; do TOS & NOS have same sign?
        bpl @add                ; yes? => add mantissas

        ; TOS - NOS --> NOS
        sec
        lda TOSm,x
        sbc NOSm,x
        sta NOSm,x
        lda TOSm+2,x
        sbc NOSm+2,x
        sta NOSm+2,x
        lda TOSsgn,x            ; result has same sign as TOS
        sta NOSsgn,x
        bra normresult          ; drop TOS and normailize result

        ; add/sub aligned mantissas
@go:    ldy sgncmp              ; do TOS & NOS have same sign?
        bpl @add                ; yes? => add mantissas

        ; NOS > TOS or their exponents are equal
        ; NOS - TOS  --> NOS
        sec
        lda NOSm,x
        sbc TOSm,x
        sta NOSm,x
        lda NOSm+2,x
        sbc TOSm+2,x
        sta NOSm+2,x
        bcs normresult          ; NOS > TOS? => drop TOS and normailize result
        
        ; had to borrow so TOS was actually > NOS
        ; need to negate result (currently NOS)

        ; drop TOS so negresult operates on result
        jsr fdrop               ; TOS now points to result of operation

        jmp negresult           ; negate TOS because result changed sign
        
@add:
        clc                     ; add TOS and NOS mantissas
        lda TOSm,x
        adc NOSm,x
        sta NOSm,x
        lda TOSm+2,x
        adc NOSm+2,x
        sta NOSm+2,x
        bcc normresult           ; drop TOS and normalize result

        ; the sum generate a carry so we add carry to the msb of result mantissa
        ; drop TOS so addcf32 operates on result
        jsr fdrop                ; TOS now points to result of operation


; addcf32 - add a carry to TOS mantissa msb
;
;        TOS exponent will be incrementated and mantissa will be shifted
;        one place to right, and mantissa msb set to 1.
;        Note that this operation can cause overflow
;
addcf32:
        lda TOSe,x
        inc                      ; increment exponent
        cmp #INFEXP32            ; overflow?
        bcc @1                   ; no
        jmp setTOSinf               ; yes, so set TOS=inf
@1:     sta TOSe,x
        sec                      ; msb=1
        ror TOSm+2,x             ; shift right mantissa one place
        ror TOSm,x
        clc                      ; return no error condition
        rts


normresult:
        jsr fdrop                ; TOS now points to result of operation

; normTOS
; try to normalize TOS after addition/subtraction or 
; when converting an integer to floting point
;
; The msb of the mantissa in a normalized value is 1.  If this
; isn't possible, the value is called subnormal.
;
normTOS:
        ; shift mantissa left until msb=1 or biased exponent=1
        ; biased exponent is decremented on every shift
        lda TOSe,x
        dec                      ; exp=exp-1
        beq chkz32               ; TOS have minimum biased exponent (1)
        tay                      ; save exponent
        lda TOSm+2,x
        bmi @end                 ; already normalized: nothing to do
        bne @shb                 ; shift bit by bit

        tya                      ; we can shift a whole word
        sec                      ; adjust exponent
        sbc #16
        tay                      ; save updated exponent

        lda TOSm,x               ; shift lsw left
        sta TOSm+2,x
        stz TOSm,x
        bmi @end                 ; already normalized: nothing else to do
        bne @shb                 ; shift bit by bit

        stz TOSe,x               ; at this point TOS=0...
        bra chkz2a               ; ...and set status byte

@cnt:   dey                      ; decrement exponent while bit shifting...
        beq @end                 ; can't shift more (exponent=1)

@shb:
        asl TOSm,x               ; shift toward left one bit at time
        rol                      ; TOSm+2
        bpl @cnt                 ; shift until msb=0
        sta TOSm+2,x
        bmi @end2                ; finish

        ; we have a subnormal value
@end:
        iny                      ; restore exponent...

@end2:
        sty TOSe,x               ; ...and set TOS exponent
        cpy #INFEXP32            ; check overflow condition
        bcc chkz32               ; no overflow: chexck if TOS=0
        jmp setTOSinf            ; set TOS=inf


; chkz32 - TOS = 0? yes, set the status byte
;
chkz32:
        ; if mantissa is 0 then fp value is 0
        lda TOSm,x
        ora TOSm+2,x
        bne chkz3a
        sta TOSe,x              ; set biased exponent = 0
chkz2a: acc8
        lda #$40                ; set status byte for 'zero' condition
        sta TOSst,x
        acc16
chkz3a:
        clc
        rts


negresult:
; this routine is also called after a subtraction that change the sign of the result
        lda TOSsgn,x            ; note we've got the status by here as well
        eor #$0080              ; set msb of low byte, don't change high byte
        sta TOSsgn,x

        ; negate TOS, twos complement
        sec
        lda #0
        sbc TOSm,x
        sta TOSm,x
        lda #0
        sbc TOSm+2,x
        sta TOSm+2,x
        jmp normTOS             ; normalize TOS  


; addtst32 - test operands before addition/subtraction
;
; Test that TOS & NOS are valid, return for any abnormal condition:
;
;        1) return nan if TOS=nan or NOS=nan
;        2) return nan if |TOS|=|NOS|=inf and NOS&TOS have opposites sign
;        3) return +inf or -inf if TOS=NOS=+/-inf
;        4) return +inf or -inf if TOS=+/-inf and NOS is valid
;        5) return +inf or -inf if NOS=+/-inf and TOS is valid
;
addtst32:
        lda TOSsgn,x             ; compare sign
        eor NOSsgn,x
        xba                      ; transfer sign to high byte 
        sta sgncmp               ; ... we'll do a bpl test on this
; *** TODO: above clobbers status, skip validity check for now ***
;        sec                      ; invalid result flag
;        bit TOSst,x                ; test TOS
;        bpl @NOS                 ; TOS is valid, go to check NOS
;        bvc @skp                 ; TOS=nan so result=nan (TOS sign)
;        bit NOSst                ; TOS=inf so check NOS
;        bpl @skp                 ; TOS=inf & NOS=y so result=inf (TOS sign)
;        bvc @mv                  ; TOS=inf & NOS=nan so result=nan (NOS sign)
;        bit sgncmp               ; TOS=inf & NOS=inf so check sign comparison
;        bpl @skp                 ; same sign so result=inf (TOS sign)
;        jsr setTOSnan               ; mismatch signs so result=nan (TOS sign)
;        bra @skp                 ; skip resturn & exit with CF=1
;@NOS:   bit NOSst                ; TOS is valid, so now check NOS
;        bmi @mv                  ; NOS=inf/nan so result=inf/nan (NOS sign)
;        clc                      ; now result is valid
;        bvs @skp                 ; NOS=0 so result=TOS
;        bit TOSst,x                ; TOS=0?
;        bvc @end                 ; no, return to add/sub operation
;@mv:    jsr mvatof               ; move NOS to TOS (preserve CF)
;@skp:   pla                      ; skip return address
;        pla
@end:   rts


; shift the mantissa pointed at by X right by negative shift amount in A
; this will shift the TOS mantissa if called without adjusting X
shrmx32:
        cmp #$fff1               ; can shift entire word?
        bpl @shb                 ; shift right less than 16 bits
        ldy 2,x
        sty 0,x
        stz 2,x
        adc #16
@shb:
        tay                      ; residual bit shift count
        beq @end                 ; nothing to shift
        lda 0,x                  ; lsb+guard bits
@sh:    lsr 2,x                  ; msb=0
        ror                      ; rotate lsb
        iny
        bne @sh
        sta TOSm,x               ; store lsb+guards bits
@end:   rts


; shrNOSm - shift NOS mantissa right by negative shift amount in A
shrNOSm:
        cmp #$fff1               ; can shift entire word?
        bpl @shb                 ; shift right less than 16 bits
        ldy NOSm+2,x
        sty NOSm,x
        stz NOSm+2,x
        adc #16
@shb:
        tay                      ; residual bit shift count
        beq @end                 ; nothing to shift
        lda NOSm,x               ; lsb+guard bits
@sh:    lsr NOSm+2,x             ; msb=0
        ror                      ; rotate lsb
        iny
        bne @sh
        sta NOSm,x               ; store lsb+guards bits
@end:   rts


; shrtmm - shift tm mantissa right by negative shift amount in A
shrtmm:
        cmp #$fff1               ; can shift entire word?
        bpl @shb                 ; shift right less than 16 bits
        ldy tm+2
        sty tm
        stz tm+2
        adc #16
@shb:
        tay                      ; residual bit shift count
        beq @end                 ; nothing to shift
        lda tm                   ; lsb+guard bits
@sh:    lsr tm+2                 ; msb=0
        ror                      ; rotate lsb
        iny
        bne @sh
        sta tm                   ; store lsb+guards bits
@end:   rts


; shlmx32 - shift mantissa pointed by X to left until msb of mantissa equals 1
; and decrement unbiased exponent according with shift amount.
;
;shlmx32:
;        sec
;        lda <16,x                ; C=unbiased exponent
;@lp1:   ldy <14,x                ; shift count < 16?
;        bne @sh                  ; yes
;        sbc #16                  ; 16 bits shift
;        ldy <12,x                ; shift toward left word by word
;        sty <14,x
;        ldy #0
;        sty <12,x
;        cmp #MAXBSHIFT32           ; shifted all whole mantissa?
;        beq @done                ; yes, store exponent
;        bcs @lp1                 ; no, try again
;        bra @done                ; store exponent
;@lp2:   dec                      ; decrement exponent
;        asl <12,x
;        rol <14,x
;@sh:    bpl @lp2                 ; if msb=0 shift to left one place
;@done:  sta <16,x                ; store exponent
;        bit <16,x                ; check exponent sign
;        bpl @end
;        dec <20,x                ; sign extension to 32 bit
;@end:   rts


; fsquare32 ( F: r1 -- r2 )
; r2 is the square of r1
fsquare32:
        jsr decfpsp               ; make room for copy of r1 on top of stack
        jsr NOS2TOS               ; copy NOS to TOS

; fall through to r1 * r1


; fmult32 ( F: r1 r2 -- r3 )
; Multiply r1 by r2 giving r3
fmult32:
        jsr multst               ; operand test
        clc                      ; multiplication flag for addexp32
        jsr addexp32             ; add exponents
        
        ; clear the partial result
        stz tm
        stz tm+2        
        jsr multm                ; multiply the mantissas
        bra movres32             ; move result to TOS and normalize


; fdiv32 ( F: r1 r2 -- r3 )
; Divide r1 by r2, giving the quotient r3
fdiv32:
        jsr divtst               ; operand test
        sec                      ; flag division for addexp32
        jsr addexp32             ; add exponents
        jsr divm                 ; divide mantissas
        
; fall through to move result to TOS and normalize

; movres32 - move the result of multiplication/division to TOS and normalize
;
movres32:
        ldy TOSe,x              ; get result exponent from TOS ...

        ; drop top of fp stack
        jsr fdrop               ; TOS now points to result of operation

        sty TOSe,x              ; ... and store it at new TOS

        ; move the result mantissa (4 bytes) to TOS
        lda tm
        sta TOSm,x
        lda tm+2
        sta TOSm+2,x

        ; normalize result
        ; *** TODO: review and determine how we want to treat overflow ***
        lda fexph               ; operation involved subnormal?

.if SHORT       ; use slower, but shorter mult10 routine

        beq @fn                 ; no
        jsr shrmx32             ; ...because TOS is subnormal
@tz:    jmp chkz32              ; underflow test; check if TOS=0
@fn:                            ; normalize TOS after mult/div
        lda TOSe,x
        cmp #1
        beq @tz                 ; can't normalize: underflow test

.else           ; use faster mult10 routine

        beq fn                  ; no
        jsr shrmx32             ; ...because TOS is subnormal
tz:     jmp chkz32              ; underflow test; check if TOS=0
fn:
        lda TOSe,x
        cmp #1
        beq tz                  ; can't normalize: underflow test

.endif          ; end SHORT

        ldy TOSm+2,x            ; check msb
        bmi @done               ; already normalized
@sh:    cmp #1
        beq @done               ; can't shift more
        dec                     ; decrement exponent at any shift
        asl TOSext
        rol TOSm,x
        rol TOSm+2,x
        bpl @sh                 ; shift until msb=1
@done:  sta TOSe,x              ; store exponent
        cmp #INFEXP32           ; check if overflow
        bcs ovfw                ; overflow
        ldy TOSext              ; if msb=1 we round 32 bit mantissa
        bpl ifx                 ; no rounding bit: done
        jsr chkovf              ; we check exponent for a potential overflow
        bcs ifx                 ; no round is possible (we avoid overflow)        
        inc TOSm,x              ; inc guard bits and mantissa lsb
        bne ifx

        ; lsw of TOS mantissa rolled over
        ; increment msw of TOS mantissa
incTOS:
        inc TOSm+2,x
        bne ifx

        ; msw of TOS mantissa rolled over
        ; shift mantissa and add carry to msb
        jmp addcf32

ifx:
        clc
        rts

; set TOS=inf
ovfw:
        ; overflow
        jmp setTOSinf

; chkovf - check potential TOS overflow due to a roundoff
;
;        return CF=1 if a rounding can cause overflow
;
chkovf:
        cmp #MAXEXP32            ; we check exponent for possible overflow
        bcc @end                 ; ok, no overflow after rounding
        lda #$FFFF               ; check if mantissa is all ones
        cmp TOSm,x
        bne @ok
        cmp TOSm+2,x
@ok:    clc                      ; rounding is possible
        bne @end
        sec                      ; no rounding possible 
@end:   rts


; addexp32
; add exponents of TOS & NOS for multiplication/division
; carry flag cleared for multiplication, set for division
;
; On exit:
;   TOSe = exponent of the result (x*y or x/y)
;   fexph  = negative exponent if result is subnormal,
;            otherwise = 0 and result is normal
; *** TODO: is fexph needed when the 16-bit exponent will never overflow with addition of two 8-bit exponents? 
;       Am I properly accounting for the addition "overflowing" into the upper byte? ***
addexp32:
        php                     ; save carry
        stz fexph               ; clear exponent sign extensions
        stz TOSext              ; extension used with mult/div
; *** TODO: assume for now we enter with normailzed values ***
;        lda TOSm+2,x
;        bmi @a                  ; TOS is normal
;        jsr shlTOSm             ; normalize subnormal TOS
;@a:     lda NOSm+2,x
;        bmi @b                  ; NOS is normal
;        jsr shlNOSm             ; normalize subnormal NOS
@b:     plp                     ; restore carry        
        lda NOSe,x
        bcs @div                ; carry set for division
        adc TOSe,x              ; add exponents
        tay                     ; save result
        lda #0
        adc fexph               ; capture overflow from adding exponents
        pha                     ; save it
        sec
        tya                     ; retrieve sum of exponents
        sbc #EBIAS32-1          ; adjust biased exponent for mult
        tay                     ; save biased exponent
        pla                     ; retrieve exponent addition overflow
        sbc #0                  ; incorporate any borrow from bias adjustment
        bra @tst                ; check exponent

@div:   sbc TOSe,x              ; subtract exponents with sign extension
        tay                     ; save result
        lda #0
        sbc fexph               ; capture borrow from subtracting exponents
        pha
        clc
        tya                     ; retrieve difference of exponents
        adc #EBIAS32            ; adjust biased exponent for div
        tay                     ; save biased exponent
        pla                     ; retrieve exponent subtraction overflow
        adc #0                  ; incorporate any overflow from bias adjustment

        ; A reflects any over or underflow from exponent addition/subtraction
@tst:   bmi @sn                 ; negative exponent so result is subnormal
        tya                     ; retrieve biased exponent
        beq @sn                 ; null exponent so result is subnormal
        sta TOSe,x              ; exp >= 1 so result is normal
        stz fexph
        bra @done

@sn:    dey                     ; negative count of shift toward right
        cpy #MAXBSHIFT32-1
        bcc @z                  ; underflow: set TOS=0
        sty fexph               ; negative count of shift
        lda #1
        sta TOSe,x              ; subnormals have exponent=1
@done:
        rts

@z:     ; underflow: load zero as result and exit

        ; drop top of fp stack
        jsr fdrop

        ; pop fmult32 or fdiv32 from stack
        pla
        jmp setTOS0              ; load zero in TOS and return


; multm
; multiply NOS mantissa with TOS mantissa
;
; classic "shift and add" binary multiplication method with only the high
; order 48 bits of 64 are retained in the result.  Since TOSm and NOSm are
; normalized, the result is always between 1.000000... and 2.ffffff....
;
; *** TODO: check if using Y as a counter is faster, likely not as we need
; to save the multiplier somewhere and then shift that. ***
multm:
        lda TOSm,x
        jsr @mlt
        lda TOSm+2,x            ; multiply msb that never is null *** TODO: verify that I've properly handled 0 before getting here ***
        bra @mlt2

@mlt:   beq @shr                ; 0? => shift partial result right 16 bits
@mlt2:  lsr                     ; shift out multiplicator bit
        ora #$8000              ; set bit to stop iteration after 16 cycles
@lp:    tay                     ; save multiplier with end of loop indicator
        bcc @sh                 ; multiplicator=0 so shift result to right
        clc

        ; add NOS to partial result
        lda tm
        adc NOSm,x
        sta tm
        lda tm+2
        adc NOSm+2,x
        sta tm+2

@sh:    ror tm+2                ; shift any carry into partial result...
        ror tm                  ; ...and shift partial result toward right
        ror TOSext              ; roll any carry into this extension for greater accuracy
        tya                     ; retrieve multiplier with end of loop indicator
        lsr                     ; shift multiplier right, at end of loop when null
        bne @lp
        rts                     ; always return CF=1
        
@shr:
        ; shift partial result right 16 bits
        lda tm
        sta TOSext
        lda tm+2
        sta tm
        stz tm+2
        rts

; divm
; divide the NOS mantissa by the TOS mantissa
;
; Classic fixed point division, using the recurrence equation:
;
; *** TODO: clean this up ***
;        R    =  2*R  -  D*Q  
;         j+1       j       n-(j+1)        
;
;         R   =  V     Q = 1 if V >= D
;          0      n-1
;
; where: V=dividend, D=divisor, R = partial remainder, Q  is the k-th
;                                j                      k
;
; bit of the quotient, starting from the msb: k=n-(j+1), 
; n=130 is the quotient size, j=1..n-1 is the loop index.
; Only 130 bits of quotient are retained.
;
; Since TOSm and NOSm are normalized, the result is always between 0.100000... and 1.ffffff....
;
; *** TODO: ? check that this works for the errors Garth idendified with common Forth division routines at at http://6502.org/source/integers/ummodfix/ummodfix.htm.
;       Is this relevant for normalized fp? maybe for subnormal? ***
; *** TODO: clean this up. see if my 32-bit division routines are better ***
divm:
        acc8
        ldy #MANTSIZ32           ; loop for all bytes of mantissa
        lda #$01                 ; 8 bits quotient -- quotient = 0
@lp1:   jsr @cmp                 ; compare NOSm vs. TOSm
@lp2:   php                      ; save carry (CF=1 if NOSm>=TOSm)
        rol                      ; shift in CF (quotient bit) into lsb
        bcc @sub                 ; bits loop...stop when CF=1
        dey                      ; index of quotient array
        bmi @done                ; end of division
; *** TODO: super hack here, we're only saving to tm and tm+2, why not just expand? ***
        php
        phx
        tyx
        sta tm,x                 ; store this byte of quotient (start with msb)
        plx
        plp
; *** TODO: super hack here ***
        beq @lst                 ; last quotient is 2 bits only
        lda #$01                 ; 8 bits quotient -- quotient = 0
@sub:   plp                      ; restore CF from comparing NOSm vs. TOSm
        acc16
        bcc @sh                  ; quotient bit = 0: no subtraction
        pha                      ; save partial quotient: here CF=1
        lda NOSm,x               ; get the partial remainder...
        sbc TOSm,x               ; ...subtracting the divisor TOSm
        sta NOSm,x
        lda NOSm+2,x
        sbc TOSm+2,x
        sta NOSm+2,x
        pla                      ; restore partial quotient
@sh:    asl NOSm,x               ; now shift NOSm to left (one place)
        rol NOSm+2,x
        acc8
        bcs @lp2                 ; CF=1: quotient bit = 1
        bmi @lp1                 ; CF=0, MSB=1: compare again NOSm vs. TOSm
        bpl @lp2                 ; CF=0, MSB=0: quotient bit = 0
@lst:   lda #$40                 ; 2 last bits quotient for normalitation...
        bra @sub                 ; ...and rounding

        ; *** TODO: review, don't know what's going on here and likely have more ASLs than needed ***
@done:  plp                      ; end of division
        asl                      ; last truncated quotient (00..03)...
        asl                      ; ...shifted to bits 15&14 of TOSext...
        asl                      ; ...to have greater accuracy...
        asl        
        asl        
        asl        
        sta TOSext+1        
        acc16
        rts

.a8
@cmp:   pha
        lda NOSm+2+1,x            ; comparation: NOS mantissa vs. TOS mantissa
        cmp TOSm+2+1,x
        bne @end
        lda NOSm+2,x
        cmp TOSm+2,x
        bne @end        
        lda NOSm+1,x
        cmp TOSm+1,x
        bne @end
        lda NOSm,x
        cmp TOSm,x
        bne @end
@end:   pla
        rts

.a16


; multst - test operands before multiplication
;
; This routine test TOS & NOS for validity, sets the sign of the result,
; and returns to the caller for any abnormal condition:
;
;        1) return nan if TOS=nan or NOS=nan
;        2) return +inf if TOS=+inf and NOS=+inf or NOS>0
;        3) return +inf if TOS=-inf and NOS=-inf or NOS<0
;        4) return -inf if TOS=-inf and NOS=+inf or NOS>0
;        5) return -inf if TOS=+inf and NOS=-inf or NOS<0
;        6) return +inf if NOS=+inf and TOS>0
;        7) return +inf if NOS=-inf and TOS<0
;        8) return -inf if NOS=-inf and TOS>0
;        9) return -inf if NOS=+inf and TOS<0
;       10) return nan if TOS=+/-inf and NOS=0
;       11) return nan if NOS=+/-inf and TOS=0
;
multst:
        lda TOSsgn,x             ; compare sign
        eor NOSsgn,x
        sta TOSsgn,x             ; set result sign
        sta NOSsgn,x
;        sec                      ; invalid result flag
;        bit TOSst,x                ; test TOS
;        bpl @fv                ; TOS is valid
;        bvc @skp                ; TOS=nan so result=nan
;        bit NOSst                ; TOS=inf so check NOS
;        bpl @az                ; TOS=inf & NOS=y so check if NOS=0
;        bvc @mv                ; TOS=inf & NOS=nan so result=nan
;        bra @skp                ; TOS=inf & NOS=inf so result=inf
;@az:        bvc @skp                ; TOS=inf & NOS not null so result=inf
;        bra @nan                ; TOS=inf & NOS=0 so result=nan
;@fv:        bit NOSst                ; TOS is valid, so now check NOS
;        bpl @vv                ; NOS too is valid
;        bvc @mv                ; TOS=x & NOS=nan so result=nan
;        bit TOSst,x                ; TOS=x & NOS=inf so check if TOS=0
;        bvc @mv                ; TOS not null & NOS=inf so result=inf
;@nan:        jsr setTOSnan                ; TOS=0 & NOS=inf so result=nan
;        bra @skp                ; skip resturn & exit with CF=1
;@vv:        clc                      ; now result is valid
;        bvs @mv                ; NOS=0 so result=0
;        bit TOSst,x                ; TOS=0?
;        bvc @end                ; no, return to mult operation
;        jsr setTOS0                ; result=0 (with CF=0)
;        bra @skp
;@mv:        jsr mvatof                ; move NOS to TOS (preserve CF)
;@skp:        pla                      ; skip return address
;        pla
@end:        rts


; divtst - test operands before division
;
; This routine test TOS & NOS for validity, sets the sign of the result,
; and returns to the caller for any abnormal condition:
;
;        1) return nan if TOS=nan or NOS=nan
;        2) return nan if TOS=0 and NOS=0
;        3) return nan if TOS=+/-inf and NOS=+/-inf
;        4) return +inf if NOS=+inf and TOS>=0
;        5) return +inf if NOS=-inf and TOS<0
;        6) return -inf if NOS=-inf and TOS>=0
;        7) return -inf if NOS=+inf and TOS<0
;        8) return +inf if NOS>0 and TOS=0
;        9) return -inf if NOS<0 and TOS=0
;       10) return 0 if NOS=0 and TOS=+/-inf
;
divtst:
        lda TOSsgn,x             ; compare sign
        eor NOSsgn,x
        sta TOSsgn,x             ; set result sign
        sta NOSsgn,x
;        sec                      ; invalid result flag
;        bit TOSst,x                ; test TOS
;        bpl @fv                ; TOS is valid
;        bvc @skp                ; TOS=nan so result=nan
;        bit NOSst                ; TOS=inf so check NOS
;        bmi @nan                ; TOS=inf & NOS=inf/nan so result=nan
;        bra @z                ; TOS=inf & NOS=y so result=0        
;@fv:        lda NOSst                ; TOS is valid, so now check NOS
;        bmi @mv                ; TOS=x & NOS=nan/inf so result=nan/inf
;        and TOSst,x
;        asl a                ; both null?
;        bmi @nan                ; yes so result=nan
;        bit TOSst,x
;        bvs @inf
;        bit NOSst
;        bvc @end
;@z:        jsr setTOS0                ; result=0 (with CF=0)
;        bra @skp
;@nan:        jsr setTOSnan                ; TOS=0 & NOS=0 so result=nan
;        bra @skp                ; skip resturn & exit with CF=1        
;@inf:        jsr setTOSinf
;        bra @skp
;@mv:        jsr mvatof                ; move NOS to TOS (preserve CF)
;@skp:        pla                      ; skip return address
;        pla
@end:        rts


;---------------------------------------------------------------------------
; set and push fp stack with special values and other stack adjustments
;---------------------------------------------------------------------------

; setTOSp1 - set TOS to +1.0
setTOSp1:
        acc8
        stz TOSsgn,x
        acc16
        bra setTOS1

; setTOSm1 - set TOS -1.0
setTOSm1:
        acc8
        lda #$FF
        sta TOSsgn,x
        acc16

setTOS1:
        lda #EBIAS32
        sta TOSe,x
        lda #$8000
        sta TOSm+2,x
        stz TOSm
        acc8
        stz TOSst,x
        acc16
        clc
        rts

; setTOS0 - set TOS to 0.0
setTOS0:
        stz TOSm+2,x        
        stz TOSe,x
        stz TOSm,x
        lda #$4000
        sta TOSsgn,x       ; TOSsgn=0, TOSst=$40
noer:   clc
        rts

; *** TODO: can't have 8-bit index, need to change A and Y here and elsewhere ***
; setTOSnan - set TOS to nan
setTOSnan:
        lda #NANSND
        ldy #$80                 ; nan flag
        bra setTOSinv

; setTOSinf - set TOS to inf
setTOSinf:
        lda #INFSND
        ldy #$C0                 ; inf flag

setTOSinv:
        sta TOSm+2,x             ; set msb
        lda #INFEXP32            ; set invalid exponent
        sta TOSe,x
        stz TOSm,x
        acc8
        sty TOSst,x
        acc16
        sec                      ; return error condition
        rts

; push0d5 - push 0.5 onto the stack
push0d5:
        ldy #EBIAS32-1
        bra pushc

; push1 - push +1.0 onto the stack
push1:
        ldy #EBIAS32
        bra pushc

; push2 - push 2.0 onto the stack
push2:
        ldy #EBIAS32+1

pushc:
        jsr decfpsp               ; make room on top of stack for constant
        sty TOSe,x                ; store exponent
        lda #$8000
        sta TOSm+2,x                ; high word = $8000
        stz TOSm,x                ; reset all remaining bits
        acc8
        stz TOSsgn,x                ; positive sign
        acc16
        clc        
        rts

; pushu32 ( F: -- r1 )
; push r1 onto stack. r1 is the floating-point equivalent of the
; unsigned 32-bit integer, n, in the A and Y regsters (Y-lsw, A=msw)
pushu32:
        pha                     ; save n msw
        jsr decfpsp             ; make room for r1 on top of stack
        jsr setTOS0             ; set TOS to 0
        stz TOSsgn,x            ; also TOSst = 0 for normal TOS <> 0
        pla                     ; recover n msw ...
        sta TOSm+2,x            ; ... and store it in TOS
        tya
        sta TOSm,x              ; store n lsw ...
        ora TOSm+2,x            ; ... and test for 0
        beq okz                 ; was n = 0?
        lda #BIAS32             ; biased exponent for 32 bit value        
        bra setu                ; set biased exponent and normalize

; setTOSu16 - set TOS to the unsigned 16-bit integer, n, in A
setTOSu16:
        tay                     ; save n
        jsr setTOS0             ; set TOS=0
        sty TOSm+2,x
        stz TOSsgn,x            ; also TOSst = 0 for normal TOS <> 0
        tya                     ; retrieve n
        beq okz                 ; test if n=0                
        lda #BIAS16             ; biased exponent for 16 bit value

setu:
        sta TOSe,x              ; store exponent
        jmp normTOS             ; normalize TOS

okz:
        clc
        rts

; Decrement floating-point stack pointer, adding space to the
; top of floating-point stack for one fp item
decfpsp:
        txa
        sec
        sbc #FP_size
        tax                     ; original TOS value is now at NOS
        rts                     ; and current TOS is unititialized

; drop TOS
fdrop:
        txa
        clc
        adc #FP_size
        tax
        rts

; copy NOS to TOS
NOS2TOS:
        lda NOSm,x
        sta TOSm,x
        lda NOSm+2,x
        sta TOSm+2,x
        lda NOSe,x
        sta TOSe,x
        lda NOSsgn,x
        sta TOSsgn,x            ; also status byte
        rts

; copy TOS to NOS
TOS2NOS:
        lda TOSm,x
        sta NOSm,x
        lda TOSm+2,x
        sta NOSm+2,x
        lda TOSe,x
        sta NOSe,x
        lda TOSsgn,x
        sta NOSsgn,x            ; also status byte
        rts

;---------------------------------------------------------------------------


; str2fp32 ( F: -- r )
; Convert the source string to float r and place it on the TOS
;
;        entry:
;               A = address of string in current data bank
;               Y is string length
;
;        exit:
;               CF = 0 if conversion was succesfully done
;               VF = 1 if TOS=inf/nan
;               CF = 1 (VF don't care) if input string is invalid
;
; The string is parsed from left to right.  The expected format is:
;            a decimal ascii string, beginning with an optional '+'
;            or '-' sign, followed by a decimal mantissa consisting of a
;            sequence of decimal digits optionally containing a decimal-point
;            character, '.'. The mantissa may be optionally followed by an 
;            exponent. An exponent consists of an 'E' or 'e' followed by an
;            optional plus or minus sign, followed by a sequence of decimal 
;            digits; the exponent indicates the power of 10 by which the
;            mantissa should be scaled.
;
str2fp32:
        pha                      ; string address for stack relative indirect addressing 
        sty strl

        ; make room on top of fp stack for a new entry
        ; *** TODO: we'll have to delete this if an error ***
        jsr decfpsp

        stz fexph                ; clear exponent
        stz tmdot                ; count of decimal digits (after a dot)
        stz TOSsgn,x             ; clear sign/status
        stz tmsgn                ; sign&dot indicator
        stz tmcnt                ; count of mantissa digits
        stz tesgn                ; sign&exponent indicator
        stz tecnt                ; count of exponent digit
        jsr setTOS0              ; set TOS to 0, status = $40
        ldy #0                   ; init string pointer
        bra @get0

@nx0:   iny
        cpy strl
        beq @eos                 ; we've reached the end of the string, scale value
@get0:
        lda (1,s),y              ; get char
        and #$ff
        cmp #$0d
        beq @eos                 ; end of string

        ; parsing of ascii decimal string
@dec:   cmp #'+'
        beq @nxt                 ; skip '+' sign
        cmp #'-'
        bne @dec2                ; handle decimal digit
        lda #$8000
        sta tmsgn                ; set negative sign flag
@nxt:   iny                      ; next byte
        cpy strl
        beq @eos                 ; we've reached the end of the string, scale value
        lda (1,s),y              ; get char
        and #$ff
@dec2:  sec
        sbc #'0'+10
        clc
        adc #10
        bcc @ndg                 ; is not a digit
        bit tesgn                ; will process exponent digits?
        bvs @edec                ; yes
        inc tmcnt                ; count of mantissa digits 
        jsr @mupd                ; update mantissa (add digit)
        bcc @nxt                 ; next byte
        bcs @ovf                 ; overflow error
@edec:  inc tecnt                ; process exponent digit
        jsr @eupd                ; update exponent (add digit)
        bcc @nxt                 ; next byte
        bcs @ovf                 ; exponent overflow error

@iy:    dey                      ; here when index overflow
        bra @nv                  ; invalid string

        ; end of string or parsing of an invalid char
@eos:
        ldy tmcnt
        beq @nv                  ; no mantissa digits: invalid string
        bit tesgn
        bvc @sc                  ; no exponent: scale TOS according decimals 
        ldy tecnt
        ; *** Forth Standard 12.3.7 allows exponent digit to be optional ***        
;        beq @nv                  ; no exponent digits: invalid string
        bra @sc                  ; scale TOS according to exponent&decimals

        ; handle no-digit character      
        ; *** TODO: need to work on this ***  
@ndg:   adc #'0'                 ; restore character
        cmp #'.'                 ; check if decimal dot
        bne @cke                 ; go to check 'e', 'E'
        lda tmcnt
        beq @nv                  ; no mantissa digits so error
        lda #$4000               ; test&set dot indicator
        tsb tmsgn
        bne @nv                  ; duplicate dot so error
        bra @nxt                 ; next byte
@cke:   cmp #'E'                 ; check exponent
        beq @cke1
        cmp #'e'
        beq @cke1
;        jsr @ginf                ; read INF or NAN string 
; *** TODO: need to set error here and finish ***       
        bcs @eos                 ; invalid string
        jmp @done
@cke1:  lda tmcnt
        beq @nv                  ; no mantissa digits so error
        lda #$4000               ; test&set dot indicator
        tsb tesgn
        bne @nv                  ; duplicate 'E' so error
        iny                      ; get next byte
        cpy strl
        beq @eos                 ; we've reached the end of the string, scale value
        lda (1,s),y              ; get char
        and #$ff
        cmp #'+'
        beq @cke2                ; skip '+' sign
        cmp #'-'
        bne @dec2                ; process this byte
        lda #$8000
        tsb tesgn                ; set negative exponent sign
@cke2:
        jmp @nxt                 ; get next byte

        ; mantissa or exponent overflow
        ; *** TODO: we don't need to load anything, just set error, clean up and return ***
        ; *** TODO: need to adjust FPSP if we've allocated a fp value to TOS ***
@ovf:
        lda tmsgn                ; attual mantissa sign
        acc8
        xba
        sta TOSsgn,x
        acc16
        jsr setTOSinf            ; load inf because overflow
        clc                      ; no error (string is valid)
        sep #PVFLAG              ; VF=1 (overflow)
        bra @done                ; done

        ; duplicate dot, duplicate 'E', no valid digits: invalid string
        ; *** TODO: we don't need to load anything, just set error, clean up and return ***
        ; *** TODO: need to adjust FPSP if we've allocated a fp value to TOS ***
        ; *** TODO: determine what we need for error flags ***
@nv:
        lda tmsgn                ; attual mantissa sign
        xba
        acc8
        sta TOSsgn,x
        acc16
        jsr setTOS0              ; TOS=0
        sec                      ; error: invalid string
        bra @done                ; done

        ; now scale TOS according to decimal digits count & exponent
@sc:    lda tmsgn
        xba
        acc8
        sta TOSsgn,x
        acc16
        sec
        lda #0                   ; change sign to decimal count
        sbc tmdot
        sta tmdot
        lda fexph
        ldy tesgn                ; check exponent sign
        bpl @sc1
        eor #$FFFF               ; change sign to exponent
        inc
@sc1:   clc
        adc tmdot                ; scale TOS with this value
        jsr scale10
        clv                      ; VF=0

        ; *** TODO: hack for now until we work out how I'm handling status ***
        ; clear zero status indicator (I'm assuming if we're here it's not 0 but I'm not certain of that)
        acc8
        stz TOSst,x              ; clear status
        acc16

        bcc @done                ; no overflow
        clc                      ; no error (string is valid)
        sep #PVFLAG              ; VF=1 (overflow)        
@done:
        pla                      ; pull pointer to string
        rts

        ; update mantissa: TOS=(TOS*10)+byte (where A=byte)
@mupd:  sty tmp1                 ; save Y
        sta tmpa                 ; save A
        bit tmsgn                ; digit after a decimal dot?
        bvc @mupd1               ; no
        inc tmdot                ; increment decimal count
                                 ; TODO: consider if we can keep from loading 10 into TOS each loop ***
@mupd1: jsr mult10               ; TOS=TOS*10
        bcs @mupd2               ; invalid
;        jsr mvftoa32             ; move TOS to NOS
        jsr decfpsp                      ; make room on top of stack
        lda tmpa
        jsr setTOSu16               ; load A into TOS
        jsr fadd32               ; TOS=(TOS*10)+A
@mupd2: ldy tmp1                 ; restore string index
        rts                      ; CF=1 if overflow

        ; update exponent: fexph=(10*fexph)+A
@eupd:  sta tmpa                 ; save byte to add
;        stz tmpa+1               ; high byte = 0
        lda fexph
        cmp #$0019               ; check overflow condition
        bcs @eupd1               ; limit exponent to $7F
        sta tmp1
        asl                      ; mult. 10
        asl
        adc tmp1
        asl
        adc tmpa                 ; add byte
        sta fexph                ; update exponent
@eupd1:
        rts                      ; CF=1 if exponent overflow

; 32-bit IEEE-754 Values
;         IEEE            Internal
;                         sgn  exp  mantissa  guard
; 0.1     3DCCCCCD        0    7B   CC CC CC  CC
; 10      41200000        0    82   40
;ieee01m: .word $CCCC, $CCCC
ieee01m: .word $CCCC, $CCCD
ieee01e: .word $007B
ieee10m: .word $A000, $0
ieee10e: .word $0082


; We can either use fmult32 with a constant 10 as the argument or we
; can make this a bit faster hardcoding the multiplication.  Multiplying
; by 10 in binary (%1010) is just three shifts and an add.  It requires
; more code though.  I've opted for speed here though since this is 
; just used for value I/O the improvement probably won't be very noticable
; unless you're inputing/printing a lot of values.  A test of inputing and
; outputing about 40 fp values of varying length showed about a two second
; advantage to the hardcoded routine.

; *** To use the shorter code version, set SHORT to 1 at the top of this file ***
; mult10 (F: r1 -- r2 )
; r2 is equal to r1 * 10
mult10:

.if SHORT       ; use slower, but shorter mult10 routine

        ; make room on top of fp stack for 10
        jsr decfpsp                      ; make room for r1 on top of stack
        jsr setTOS0                     ; initialize it *** TODO: see what original package does, without this we get entry errors ***
        ; *** TODO: need to clear status for some things otherwise the zero check messes things up.  We're likely missing a status transfer that used to happen in fac ***
        stz TOSsgn,x                    ; also TOSst = 0 for normal TOS <> 0

        ; move 10 to top of fp stack
        lda f:ieee10m
        sta TOSm+2,x
        lda f:ieee10m+2
        sta TOSm,x
        lda f:ieee10e
        sta TOSe,x

        jsr fmult32
        rts

.else           ; use faster mult10 routine

        ; *** TODO: I'm missing something here as it works fine
        ; with integers but truncates any fractional part ***
        ldy #0
        clc

        ; multiply TOSm by 10 (%1010)
        ; r1 * 10 = r1 * (8 + 2) = (r1 * 8) + (r1 * 2)
        ; r1 * 2 => Y=lsw, A=msw, tmp2=overflow and TOSm,TOSm+2,TOSext for use later
        lda TOSm,x
        beq @eqz                ; TOS lsw = 0? yes, go check msw
        asl
        tay                     ; lsw
        sta TOSm,x
        lda TOSm+2,x
@nez:
        rol
        sta TOSm+2,x
        phx                     ; save FPSP
        tax                     ; msw
        lda #0                  ; capture any overflow
        rol
        sta tmp2
        sta TOSext

        ; r1 * 4 = tm * 2
        tya                     ; lsw
        asl
        tay
        txa                     ; msw
        rol
        tax
        rol tmp2

        ; r1 * 8 = tm * 2
        tya                     ; lsw
        asl
        tay
        txa                     ; msw
        rol
        tax
        rol tmp2

        tya                     ; lsw
        txy                     ; save msw
        plx                     ; retrieve FPSP

        ; r1 * 10 = tm + TOSm
        ; carry is clear
        adc TOSm,x
        sta tm
        tya                     ; msw 
        adc TOSm+2,x
        sta tm+2
        lda tmp2
        adc TOSext

        ; save product to to TOSm, shifting one byte to right
        acc8
        sta TOSm+3,x
        lda tm+3
        sta TOSm+2,x
        lda tm
        sta TOSext+1
        acc16
        lda tm+1
        sta TOSm,x

        ; we've shifted the product one byte to the right
        ; increase the exponent to compensate
        clc
        lda TOSe,x
        adc #8
        sta TOSe,x
        jsr fn                  ; normalize result
        clc
        rts

@eqz:
        lda TOSm+2,x
        bne @nez
        jmp setTOS0

.endif


div10:
; *** TODO: evaluate if a hardcode version similar to above is possible ***

        ; make room on top of fp stack for 10
        jsr decfpsp             ; make room on top of stack
        jsr setTOS0             ; initialize it *** TODO: see what original package does, without this we get entry errors ***
        stz TOSsgn,x            ; also TOSst = 0 for normal TOS <> 0

        ; move 10 to top of fp stack
        lda f:ieee01m
        sta TOSm+2,x
        lda f:ieee01m+2
        sta TOSm,x
        lda f:ieee01e
        sta TOSe,x

        jsr fmult32

        rts

; scale10 - multiply TOS by a power of ten
;
;         entry:
;                TOS         = x (valid float)
;                A           = n (signed integer)
;
;        exit:
;                TOS         = x * 10^n
;                CF          = 1 if invalid result(inf or nan)
;
; *** TODO: consider something similar to fp package routine, but for now just brute force ***
scale10:
        tay
        beq @done               ; scalar = 0, skip
        ; *** TODO: need to check TOS = 0 as well ***
        bmi @div

@mult:
        phy
        ; we're scaling up
        jsr mult10
        ply
        dey
        bne @mult
        bra @done

@div:
        phy
        ; we're scaling down
        jsr div10
        ply
        iny
        bne @div
@done:
        clc     ; *** TODO: consider appropriate errors here ***
        rts


;***************************************************************************
; Truncation and rounding routines
;
; *** TODO: need to deal with sign and status bytes with all of the 8-bit
;        switching in these functions ***


; uitrunc32 ( F: r -- )
; Return the integral part of r as an unsigned 32 bit integer, A=msw, Y=lsw.
; Carry set if the integral part of |x| will not fit in 32-bits
;
; In overflow condition, or if TOS=nan/inf, tm..tm+2 is set to $FFFFFFFF
; and the carry flag will be set.
;
uitrunc32:
        acc8
        bit TOSst,x             ; valid TOS?
        acc16
        bpl @fv                 ; yes
        
        ; set tm to max
@ovf:   sec                     ; invalid flag
        lda #$FFFF              ; set max.
        bra @set
@z:     lda #0
@z1:    clc                     ; valid flag
@set:   tay
        rts

@fv:
        bvs @z                  ; TOS = 0, so return 0
        lda TOSe,x
        beq @z1                 ; TOS = 0, so return 0
        sec
        sbc #EBIAS32            ; unbias exponent
        bcc @z                  ; TOS < 1, so return 0
        cmp #MNTBITS32          ; limit to 32 bit integer
        bcs @ovf                ; 32 bits integer overflow
        sbc #MNTBITS32-2        ; take in account CF=0 here
        beq @done               ; no shift so exit
        jsr shrmx32             ; align integer with exponent
@done:
        ldy TOSm,x              ; return TOS mantissa
        lda TOSm+2,x
        sta tmpa
        jsr fdrop               ; drop TOS
        lda tmpa
        clc
        rts

;---------------------------------------------------------------------------
; Rounding rules:
;
; "Round to nearest" means round the result of a floating-point operation to
; the representable value nearest the result. If the two nearest representable
; values are equally near the result, the one having zero as its least
; significant bit shall be delivered.
;
; "Round toward zero" means round the result of a floating-point operation
; to the representable value nearest to zero, frequently referred to as
; "truncation".
;
; "Round toward negative infinity" means round the result of a floating-
; point operation to the representable value nearest to and no greater than
; the result.
;---------------------------------------------------------------------------        

; fceil - returns the smallest f.p. integer greater than or equal the argument
;
; This routine truncates toward plus infinity
;
;        entry:
;                TOS = x
;
;         exit:
;                TOS = y = integral part of x truncated toward plus infinity
;                CF = 1 if invalid result(inf or nan)
;
;        fceil(3.0)  =  3.0
;        fceil(2.3)  =  3.0
;        fceil(0.5)  =  1.0
;        fceil(-0.5) =  0.0
;        fceil(-2.3) = -2.0
;        fceil(-3.0) = -3.0
;
fceil:
        acc8
        bit TOSst,x
        acc16
        bpl @fv                 ; TOS is valid
        sec                     ; return invalid flag
        rts

@fv:    bvc @nz                 ; TOS <> 0
        acc8
        stz TOSsgn,x            ; return TOS=0
        acc16
        clc
        rts

@nz:    
        acc8
        lda TOSsgn,x
        eor #$FF                ; fceil(x)=-floor(-x)
        sta TOSsgn,x
        acc16
        jsr floor32
        acc8
        lda TOSsgn,x
        eor #$FF
        sta TOSsgn,x
        acc16
        rts

; fround32 ( F: r1 -- r2 )
; Rounds r1 to an integral value using the "round to nearest" rule, giving r2
;
; - returns the integral value that is nearest to ergument x, 
; with halfway cases rounded away from zero.
;
; This routine truncates toward the nearest integer value
;
;        entry:
;                TOS = x
;
;         exit:
;                TOS = y = integral part of x truncated toward the nearest
;                CF = 1 if invalid result(inf or nan)
;
;        fround(3.8)   =   4.0
;        fround(3.4)   =   3.0
;        fround(0.5)   =   1.0
;        fround(0.4)   =   0.0
;        fround(-0.4)  =   0.0
;        fround(-0.5)  =  -1.0
;        fround(-3.4)  =  -3.0
;        fround(-3.8)  =  -4.0
;
fround32:
        acc8
        bit TOSst,x
        acc16
        bpl @fv                 ; TOS is valid
        sec                     ; return invalid flag
@ret:   rts

@fv:    bvc @nz                 ; TOS <> 0
        acc8
        stz TOSsgn,x            ; return TOS=0
        acc16
        clc
        rts

@nz:    
        acc8
        lda TOSsgn,x
        pha                     ; save TOS sign
        stz TOSsgn,x
        acc16
        jsr faddhalf            ; |x|+0.5
        acc8
        pla
        sta TOSsgn,x            ; restore TOS sign
        acc16
        bcs @ret                ; overflow

        ; return sign(x)*ftrunc(|x|+0.5)
        bmi fceil               ; ftrunc(x)=fceil(x) if x<0
        bra floor32               ; ftrunc(x)=floor(x) if x>0


; ftrunc32 ( F: r1 -- r2 )
; Rounds r1 to an integral value using the "round towards zero" rule, giving r2
; - returns the nearest integral value that is not larger 
; in magnitude than the argument x.
;
; This routine truncates toward zero
;
;        entry:
;                TOS = x
;
;         exit:
;                TOS = y = integral part of x truncated toward zero
;                CF = 1 if invalid result(inf or nan)
;
;        ftrunc(3.0)  =  3.0
;        ftrunc(2.3)  =  2.0
;        ftrunc(0.5)  =  0.0
;        ftrunc(-0.5) =  0.0
;        ftrunc(-2.3) = -2.0
;        ftrunc(-3.0) = -3.0
;
ftrunc32:
        acc8
        bit TOSst,x
        acc16
        bpl @fv                 ; TOS is valid
        sec                     ; return invalid flag
        rts

@fv:    bvc @nz                 ; TOS <> 0
        acc8
        stz TOSsgn,x            ; return TOS=0
        acc16
        clc
        rts

@nz:    acc8
        lda TOSsgn,x
        acc16
        bmi fceil               ; ftrunc(x)=fceil(x) if x<0
                                ; ftrunc(x)=floor(x) if x>0

        ; fall through to floor


; floor32 ( F: r1 -- r2 )
; Round r1 to an integral value using the "round toward negative infinity"
; rule, giving r2
; - returns the largest f.p. integer less than or equal to the argument
;
;                CF = 1 if invalid result(inf or nan)
;
;        floor(3.0)  =  3.0
;        floor(2.3)  =  2.0
;        floor(0.5)  =  0.0
;        floor(-0.5) = -1
;        floor(-2.3) = -3.0
;        floor(-3.0) = -3.0
;
floor32:
        acc8
        bit TOSst,x
        acc16
        bpl @fv                 ; TOS is valid
        sec                     ; return invalid flag
        rts

@fv:    bvc @nz                 ; TOS <> 0
        acc8
        stz TOSsgn,x            ; return TOS=0
        acc16
        clc
        rts

@nz:    jsr frndm32             ; round for guard byte
        lda TOSe,x
        sec
        sbc #EBIAS32
        sta tmpa                ; save unbiased exponent
        bcs @gt1                ; |TOS|>=1
        acc8
        bit TOSsgn,x
        acc16
        bmi @m1                 ; if -1<TOS<0 return TOS=-1...
        jmp setTOS0             ; ...else return TOS=0
@m1:    jmp setTOSm1            ; return TOS=-1

@gt1:
        jsr decfpsp             ; make room for copy of r1 on top of stack
        jsr NOS2TOS             ; copy TOS to NOS for later comparation        
        lda #SNBITS32-1         ; carry flag is set
        sbc tmpa                ; if this is <=0 then TOS already integral
        phx                     ; save FPSP
        bcc @int                ; TOS already integral
        beq @int                ; TOS already integral
        
        ; We can clear the fractional part to get just the integral part
        ; A = count of bits to clear starting from mantissa lsb
        ; We just have three bytes, let's do this manually

        acc8
        cmp #8                  ; clear lsb?
        bcc @bit                ; no, clear less than 8 bits in low byte
        stz TOSm+1,x
        sbc #8                  ; update count
        beq @int                ; done: TOS is integral
        cmp #8                  ; clear middle byte?
        bcc @bitm               ; no, clear less than 8 bits in middle byte
        stz TOSm+2,x
        sbc #8                  ; update count
        beq @int                ; done: TOS is integral
        inx                     ; adjust FPSP to high byte
        inx
        bra @bit                ; clear less than 8 bits in high byte
@bitm:
        inx                     ; adjust FPSP to middle byte

@bit:   inx                     ; adjust FPSP to point to byte to be adjusted
        txy                     ; save adjusted FPSP
        tax                     ; X=count of bits
        dex
        lda f:fmask32,x         ; load bits mask
        tyx                     ; retrieve FPSP
        and TOSm,x              ; mask mantissa byte
        sta TOSm,x

@int:   plx                     ; restore FPSP
        bit TOSsgn,x            ; if TOS>0...
        acc16
        bpl @end                ; ...then done
                                ; ...else we compare if integral part...
                                ; ...is equal to original TOS
        lda TOSm,x
        cmp NOSm,x
        bne @chk
        lda TOSm+2,x
        cmp NOSm+2,x
        beq @end                ; if equal then return it...
@chk:
        jmp fsubone             ; ...otherwise subtract 1

@end:   jsr TOS2NOS             ; copy TOS to NOS
        jsr fdrop               ; drop TOS
        clc
        rts

; bit mask to clear
fmask32:
.byte        $FE,$FC,$F8,$F0,$E0,$C0,$80


; frndm32 - round TOS mantissa to 24-bits
;
; standard rounding method: round to nearest and tie to even
;
;        if guard byte < $80 then round down (truncate)
;        if guard byte > $80 then round up
;        if guard byte = $80 and matissa low bit = 1 then
;                round up, otherwise round down (truncate)
;
; To avoid ovorflow, don't round if exponent equal to $7E and mantissa is $ffffffff
;
frndm32:
        lda TOSm,x              ; mantissa low byte and guard byte
        and #$ff                ; mask guard byte
        acc8
        stz TOSm,x              ; clear guard byte
        cmp #$80                ; guard byte >= $80?
        acc16
        bcc @done               ; no, we're done
        lda TOSm,x              ; mantissa low byte is msb
        and #$0100              ; mask low bit
        beq @done               ; matissa low bit = 1? no, we're done
        lda TOSe,x              ; check exponent for possible overflow
        jsr chkovf
        bcs @done               ; no round is possible (avoid overflow)        
@rnd:
        lda #$0100              ; add 1 ...
        adc TOSm,x              ; ... to mantissa low byte
        sta TOSm,x              ; save it
        bcc @done
        jmp incTOS              ; now this increment never cause overflow
@done:
        rts


