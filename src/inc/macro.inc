; macro.inc

.listbytes unlimited

; 65816 register size selection macros
.macro reg8
.i8
.a8
        sep #$30
.endmacro
.macro reg16
.i16
.a16
        rep #$30
.endmacro
.macro acc8
.a8
        sep #$20
.endmacro
.macro acc16
.a16
        rep #$20
.endmacro
.macro index8
.i8
        sep #$10
.endmacro
.macro index16
.i16
        rep #$10
.endmacro
