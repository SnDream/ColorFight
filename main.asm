INCLUDE "gbhw.asm"

BORDER_LOOP EQU 1

INIT_HRAM EQU 0
INIT_WRAM EQU 0

DEBUG EQU 0

SECTION "Work RAM 0", WRAM0
wTileSet:
    ds $1000

SECTION "Work RAM 1", WRAMX
wTileSet_wram1:
    ds SCREEN_X * SCREEN_Y * TILE_SIZE - $1000

; wTileSet_pad:
;     ds $18 * TILE_SIZE

SECTION "Stack", WRAMX[$DF00]
wStackBottom::
    ds $100 - 1
wStack::
wStackTop::
    ds 1

SECTION "High RAM", HRAM
hRandomNum:
    ds 4
hRandomOffset:
    ds 1
hCFScreenPixelX:
    ds 1
hCFScreenPixelY:
    ds 1
hCFColor1:
    ds 1
hCFColor2:
    ds 1
hCFCount:
    ds 1
hVblankLoop:
    ds 1

SECTION "rst00", ROM0[$00]
rst00:
GetRandom:
    push bc
    push hl
    ld hl, rDIV
    ld c, LOW(hRandomNum)

    ldh a, [c]
    adc a, [hl]
    ldh [c], a
    inc c

    ldh a, [c]
    sbc a, [hl]
    ldh [c], a
    inc c

    ld b, a
    inc hl ; rTIMA

    ldh a, [c]
    adc a, [hl]
    ldh [c], a
    inc c

    ldh a, [c]
    sbc a, [hl]
    ldh [c], a
    inc c

    xor a, b

    pop hl
    pop bc
    ret

SECTION "rst38", ROM0[$38]
    rst $38
    
SECTION "vblank", ROM0[$40]
VBlank:
    jr VBlank_2

SECTION "lcd", ROM0[$48]
LCD:
    push hl
    ld hl, rLCDC
    res 4, [hl]
    pop hl
    reti

SECTION "timer", ROM0[$50]
    rst $38

SECTION "serial", ROM0[$58]
    rst $38

SECTION "joypad", ROM0[$60]
    rst $38

SECTION "vblank_2", ROM0[$68]
VBLANK_LINE EQU 6
VBlank_2:
    push af
    push bc
    push hl

    ld hl, rLCDC
    set 4, [hl]
    ldh a, [hVblankLoop]
    inc a
    cp a, SCREEN_Y / VBLANK_LINE
    jr c, .not_border
    xor a
.not_border
    ldh [hVblankLoop], a
    add a, a
    ld hl, .y_addr
    ld b, 0
    ld c, a
    add hl, bc
    ld a, [hli]
    ld b, [hl]
    ld c, a
    ld hl, wTileSet
    add hl, bc
    ld a, h
    ldh [rHDMA1], a
    ld a, l
    ldh [rHDMA2], a
    ld hl, TILE_SET
    add hl, bc
    ld a, h
    ldh [rHDMA3], a
    ld a, l
    ldh [rHDMA4], a
    ld a, (SCREEN_X * VBLANK_LINE) - 1
    ldh [rHDMA5], a

; Random from Joypad
    ldh a, [hRandomOffset]
    inc a
    and a, %00000011
    ldh [hRandomOffset], a
    add a, LOW(hRandomNum)
    ld c, a
    ld a, R_DPAD
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    cpl
    and $f
    swap a
    ld b, a
    ld a, R_BUTTONS
    ldh [rJOYP], a
rept 6
    ldh a, [rJOYP]
endr
    cpl
    and $f
    or b
    ld b, a
    ldh a, [c]
    xor b
    ldh [c], a

    pop hl
    pop bc
    pop af
    reti
.y_addr
tmp set 0
rept SCREEN_Y / VBLANK_LINE
    dw TILE_SIZE * SCREEN_X * VBLANK_LINE * tmp
tmp set tmp + 1
endr

SECTION "Header", ROM0[$100]

Start::
    nop
    jp _Start

SECTION "Home", ROM0[$150]

_Start::
    di
    cp a, $11
    jp nz, .stop
    ld hl, rKEY1
    set 0, [hl]
    xor a
    ldh [rIF], a
    ldh [rIE], a
    ld a, $30
    ldh [rJOYP], a
.stop
    stop ; rgbasm adds a nop after this instruction by default

    xor a
    ldh [rSCY], a
    ldh [rSCX], a
    ldh [rNR52], a
    ldh [rIF] , a
    ldh [hCFScreenPixelX], a
    ldh [hCFScreenPixelY], a
    ldh [hVblankLoop], a
    ld a, 1 << VBLANK | 1 << LCD_STAT
    ldh [rIE]  , a
    ld a, 5
    ldh [rTMA], a
    ld a, 1 << rTAC_ON | rTAC_262144_HZ
    ldh [rTAC], a
    ld sp, wStack

if INIT_HRAM == 1
; Init HRAM
    xor a
    ld c, $FE
.hram_loop
    ldh [c], a
    dec c
    bit 7, c
    jr nz, .hram_loop
endc

if INIT_WRAM == 1
; Init WRAM
    ld hl, $C000
    ld bc, $2000
.wram_loop
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz,.wram_loop
endc

.waitVBlank
    ldh a, [rLY]
    cp a, $90
    jr c, .waitVBlank
    
    xor a
    ldh [rLCDC], a
    ldh [rLY], a

; RandomInit
    call InitRandom
; Map Init
    call InitMap
; Tile Init
    call InitTile
; Color Init
    call InitColor

    ld a, 72
    ldh [rLYC], a
    ld a, %01000000
    ldh [rSTAT], a
    ld a, %10010001
    ldh [rLCDC], a
    
    ei
    jp ColorFight
.loop
    halt
    jr .loop

InitRandom:
    ld a, $0A
    ld [MBC3SRamEnable], a
    ld c, LOW(hRandomNum)

    xor a
    ld [MBC3LatchClock], a
    inc a
    ld [MBC3LatchClock], a

    ld a, RTC_S
.loop
    ld [MBC3SRamBank], a
    push af
    ld a, [MBC3RTC]
    ldh [c], a
    inc c
    pop af
    inc a
    cp a, RTC_DH
    jr c, .loop
    
    ld [MBC3SRamBank], a
    nop
    xor a
    ld [MBC3RTC], a
 
    xor a
    ld [MBC3LatchClock], a
    inc a
    ld [MBC3LatchClock], a

    xor a
    ld [MBC3SRamEnable], a
    ret

InitMap:
    ld hl, MAP_SET
    ld de, MAP_SET_X - SCREEN_X
    ld b, SCREEN_Y
.writeTileMap1
    ld c, SCREEN_X
.writeTileMap2
    push af
    ld a, 1
    ldh [rVBK], a
    xor a
    ld [hl], a
    ldh [rVBK], a
    pop af
    ld [hli], a
    inc a
    dec c
    jr nz, .writeTileMap2
    add hl, de
    dec b
    jr nz, .writeTileMap1
    ret

InitTile:
    ld hl, TILE_SET
    ld bc, SCREEN_X * SCREEN_Y * TILE_SIZE
    ld de, wTileSet - TILE_SET
.writeTileData
    rst 00
    ; ld a, $FF
    ; xor a
    push hl
    add hl, de
    ld [hl], a
    pop hl
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .writeTileData
    ret

setcolor: MACRO
    ld a, LOW(\1)
    ldh [rBGPD], a
    ld a, HIGH(\1)
    ldh [rBGPD], a
ENDM

InitColor:
    ld a, %00011011
    ldh [rBGP], a

    ld a, %10000000
    ldh [rBGPI], a

    setcolor %0000000000011111 ; Red
    setcolor %0000001111100000 ; Green
    setcolor %0111110000000000 ; Blue
    setcolor %0000001111111111 ; Yellow

    ret

GetRandomPoint:
.loop1
    rst 00
    cp a, SCREEN_PIXEL_X
    jr nc, .loop1
    ldh [hCFScreenPixelX], a
    ld b, a
.loop2
    rst 00
    cp a, SCREEN_PIXEL_Y
    jr nc, .loop2
    ldh [hCFScreenPixelY], a
    ld c, a
    ret

Point2TileSet:
    ld a, c
    and a, %11111000
    rrca
    rrca
    ld d, 0
    ld e, a
    ld hl, .y_addr
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, b
    and a, %01111000
    rlca
    ld e, a
    ld a, b
    and a, %10000000
    rlca
    ld d, a
    add hl, de
    ld a, c
    and a, %00000111
    rlca
    ld d, 0
    ld e, a
    add hl, de
    push hl
    ld a, b
    and a, %00000111
    ; ld d, 0
    ld e, a
    ld hl, .x_mask
    add hl, de
    ld a, [hl]
    ld b, a
    cpl
    ld c, a
    pop hl
    ret
.y_addr
tmp set 0
rept 18
    dw wTileSet + TILE_SIZE * SCREEN_X * tmp
tmp set tmp + 1
endr
.x_mask
tmp set 0
rept 8
    db 1 << (7 - tmp)
tmp set tmp + 1
endr

Point2Color:
    call Point2TileSet
    ld a, [hli]
    and b
    ldh [hCFColor1], a
    ld a, [hl]
    and b
    ldh [hCFColor2], a
    ret

Color2Point:
    push de
    call Point2TileSet
    pop de
    ld a, [hl]
    and c
    or d
    ld [hli], a
    ld a, [hl]
    and c
    or e
    ld [hl], a
    ret

PointUp:
    ldh a, [hCFScreenPixelY]
    sub a, 1
    jr nc, .not_border
if BORDER_LOOP == 0
    xor a
else
    ld a, SCREEN_PIXEL_Y - 1
endc
.not_border
    ld c, a
    ldh a, [hCFScreenPixelX]
    ld b, a
    ldh a, [hCFColor1]
    ld d, a
    ldh a, [hCFColor2]
    ld e, a
    ret

PointDown:
    ldh a, [hCFScreenPixelY]
    inc a
    cp a, SCREEN_PIXEL_Y
    jr c, .not_border
if BORDER_LOOP == 0
    dec a
else
    xor a
endc
.not_border
    ld c, a
    ldh a, [hCFScreenPixelX]
    ld b, a
    ldh a, [hCFColor1]
    ld d, a
    ldh a, [hCFColor2]
    ld e, a
    ret

PointLeft:
    ldh a, [hCFScreenPixelX]
    sub a, 1
    jr nc, .not_border
if BORDER_LOOP == 0
    xor a
    ld b, a
    ldh a, [hCFScreenPixelY]
    ld c, a
    ldh a, [hCFColor1]
    ld d, a
    ldh a, [hCFColor2]
    ld e, a
    ret
else
    ld a, SCREEN_PIXEL_X - 1
endc
.not_border
    ld b, a
    ldh a, [hCFScreenPixelY]
    ld c, a
    ldh a, [hCFColor1]
    rlca
    ld d, a
    ldh a, [hCFColor2]
    rlca
    ld e, a
    ret

PointRight:
    ldh a, [hCFScreenPixelX]
    inc a
    cp a, SCREEN_PIXEL_X
    jr c, .not_border
if BORDER_LOOP == 0
    dec a
    ld b, a
    ldh a, [hCFScreenPixelY]
    ld c, a
    ldh a, [hCFColor1]
    ld d, a
    ldh a, [hCFColor2]
    ld e, a
    ret
else
    xor a
endc
.not_border
    ld b, a
    ldh a, [hCFScreenPixelY]
    ld c, a
    ldh a, [hCFColor1]
    rrca
    ld d, a
    ldh a, [hCFColor2]
    rrca
    ld e, a
    ret

ColorFight:
.loop
    call GetRandomPoint
    call Point2Color
    call PointUp
    call Color2Point
    call PointLeft
    call Color2Point
    call PointRight
    call Color2Point
    call PointDown
    call Color2Point
    ld hl, hCFCount
    inc [hl]
    jr .loop
