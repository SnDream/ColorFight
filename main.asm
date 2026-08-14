INCLUDE "hardware.inc"

DEF BORDER_LOOP = 1 ; not working now

DEF INIT_HRAM = 0
DEF INIT_WRAM = 0

SECTION "Work RAM 0", WRAM0[$C000]
wTileSet:
    ds SCREEN_WIDTH * SCREEN_HEIGHT * TILE_SIZE

wTileEnd:
    ds 2

SECTION "Stack", WRAM0[$D800]
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
hCFCount:
    ds 1
hVblankLoop:
    ds 1
hCenterMark:
    ds 1

SECTION "rst00", ROM0[$00]
; random -> a
; hl -> broken
; bc -> broken
rst00:
GetRandom:
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
DEF VBLANK_LINE = 6
VBlank_2:
    push af
    push bc
    push hl

    xor a
    ldh [hCFCount], a

    ld hl, rLCDC
    set 4, [hl]
    ldh a, [hVblankLoop]
    inc a
    cp a, SCREEN_HEIGHT / VBLANK_LINE
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
    ld hl, TILEBLOCK0
    add hl, bc
    ld a, h
    ldh [rHDMA3], a
    ld a, l
    ldh [rHDMA4], a
    ld a, (SCREEN_WIDTH * VBLANK_LINE) - 1
    ldh [rHDMA5], a

; Random from Joypad
    ldh a, [hRandomOffset]
    inc a
    and a, %00000011
    ldh [hRandomOffset], a
    add a, LOW(hRandomNum)
    ld c, a
    ld a, JOYP_GET_CTRL_PAD
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    cpl
    and $f
    swap a
    ld b, a
    ld a, JOYP_GET_BUTTONS
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
DEF tmp = 0
rept SCREEN_HEIGHT / VBLANK_LINE
    dw TILE_SIZE * SCREEN_WIDTH * VBLANK_LINE * tmp
DEF tmp += 1
endr

SECTION "Header", ROM0[$100]

Start::
    nop
    jp _Start
Header::
    ds $150 - @

SECTION "Init Entry", ROM0

_Start::
    di
    cp a, BOOTUP_A_CGB
    jp nz, .stop
    ld hl, rKEY1
    set 0, [hl]
    xor a
    ldh [rIF], a
    ldh [rIE], a
    ld a, JOYP_GET
    ldh [rJOYP], a
.stop
    stop
    nop

    xor a
    ldh [rSCY], a
    ldh [rSCX], a
    ldh [rNR52], a
    ldh [rIF] , a
    ldh [hVblankLoop], a
    ld a, IE_VBLANK | IE_STAT
    ldh [rIE]  , a
    ld a, 5
    ldh [rTMA], a
    ld a, TAC_START | TAC_262KHZ
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
    nop
    jr .loop

SECTION "Init Random", ROM0

InitRandom:
    ld a, $0A
    ld [rRAMG], a
    ld c, LOW(hRandomNum)

    xor a
    ld [rRTCLATCH], a
    inc a
    ld [rRTCLATCH], a

    ld a, RAMB_RTC_S
.loop
    ld [rRAMB], a
    push af
    ld a, [rRTCREG]
    ldh [c], a
    inc c
    pop af
    inc a
    cp a, RAMB_RTC_DH
    jr c, .loop
    
    ld [rRAMB], a
    nop
    xor a
    ld [rRTCREG], a
 
    xor a
    ld [rRTCLATCH], a
    inc a
    ld [rRTCLATCH], a

    xor a
    ld [rRAMG], a
    ret

SECTION "Init Map", ROM0

InitMap:
    ld hl, TILEMAP0
    ld de, TILEMAP_WIDTH - SCREEN_WIDTH
    ld b, SCREEN_HEIGHT
.writeTileMap1
    ld c, SCREEN_WIDTH
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

SECTION "Init Tile", ROM0

InitTile:
    ld hl, TILEBLOCK0
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT * TILE_SIZE
    ld de, wTileSet - TILEBLOCK0
.writeTileData
    push bc
    push hl
    rst 00
    ; ld a, $FF
    ; xor a
    pop hl
    pop bc
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


SECTION "Init Color", ROM0

MACRO setcolor
    ld a, LOW(\1)
    ldh [rBGPD], a
    ld a, HIGH(\1)
    ldh [rBGPD], a
ENDM

MACRO setcolor_rgb888
DEF _setclor_r = (((\1) >> 16) >> 3) & %11111
DEF _setclor_g = (((\1) >>  8) >> 3) & %11111
DEF _setclor_b = (((\1) >>  0) >> 3) & %11111
DEF _setclor_bgr555 = _setclor_b << 10 | _setclor_g << 5 | _setclor_r
    ld a, LOW(_setclor_bgr555)
    ldh [rBGPD], a
    ld a, HIGH(_setclor_bgr555)
    ldh [rBGPD], a
ENDM

InitColor:
    ld a, %00011011
    ldh [rBGP], a

    ld a, %10000000
    ldh [rBGPI], a

    setcolor_rgb888 $eec39a
    setcolor_rgb888 $5b6ee1
    setcolor_rgb888 $df7126
    setcolor_rgb888 $222034
    ret


SECTION "Color Fight", ROM0
RandomPos:
.retry2
    rst 00
    and $FE
    ld e, a
.retry
    rst 00

DEF POS_MAX = wTileEnd - wTileSet
    ; println "POS_MAX {x:POS_MAX}"
    cp a, HIGH(POS_MAX) << 3 | %000
    jr c, .ok
    cp a, HIGH(POS_MAX) << 3 | %111 + 1
    jr nc, .retry
    bit 7, e
    jr nz, .retry2
.ok
    ld d, a
    and %111
    ld b, a
    xor d
    rrca
    rrca
    rrca
    ld d, a
    ret

GetWayMapPos:
    ld [rROMB], a
    ld l, e
    ld a, d
    or $40
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret

MACRO AlignTable
IF STRLWR("\2") !== "l"
    ld l, \2
ENDC
    ld h, HIGH(\1)
    ld \3, [hl]
ENDM

ColorFight:
.loop
    ld hl, hCFCount
    inc [hl]
    call RandomPos
    ; b -> BitPos
    ; de -> MapPos

    AlignTable BtsTable, b, c
    AlignTable CenterTableSet, b, a
    cp %11000000
    jr nz, .not_mark_left
    set 5, b
.not_mark_left
    cp %00000011
    jr nz, .not_mark_right
    set 4, b
.not_mark_right
    ldh [hCenterMark], a

    ld a, d
    or HIGH(wTileSet) & %11100000
    ld h, a
    ld l, e
    ld a, [hli]
    and c
    jr z, .is0_
.is1_
    ld a, [hld]
    and c
    jp nz, .entry11
    jp .entry10
.is0_
    ld a, [hld]
    and c
    jr nz, .entry01

.entry00
    ldh a, [hCenterMark]
    cpl
    and [hl]
    ld [hli], a
    ldh a, [hCenterMark]
    cpl
    and [hl]
    ld [hld], a

    ld a, BANK(MapPosUp)
    call GetWayMapPos
    ld a, c
    cpl
    and [hl]
    ld [hli], a
    ld a, c
    cpl 
    and [hl]
    ld [hl], a

    ld a, BANK(MapPosDown)
    call GetWayMapPos
    ld a, c
    cpl
    and [hl]
    ld [hli], a
    ld a, c
    cpl 
    and [hl]
    ld [hl], a

    bit 5, b
    jr z, .not_left00
.left00
    ld a, BANK(MapPosLeft)
    call GetWayMapPos
    res 0, [hl]
    inc hl
    res 0, [hl]
.not_left00

    bit 4, b
    jp z, .loop
.right00
    ld a, BANK(MapPosRight)
    call GetWayMapPos
    res 7, [hl]
    inc hl
    res 7, [hl]
    jp .loop

.entry01
    ldh a, [hCenterMark]
    cpl 
    and [hl]
    ld [hli], a
    ldh a, [hCenterMark]
    or [hl]
    ld [hld], a

    ld a, BANK(MapPosUp)
    call GetWayMapPos
    ld a, c
    cpl
    and [hl]
    ld [hli], a
    ld a, c
    or [hl]
    ld [hl], a

    ld a, BANK(MapPosDown)
    call GetWayMapPos
    ld a, c
    cpl
    and [hl]
    ld [hli], a
    ld a, c
    or [hl]
    ld [hl], a

    bit 5, b
    jr z, .not_left01
.left01
    ld a, BANK(MapPosLeft)
    call GetWayMapPos
    res 0, [hl]
    inc hl
    set 0, [hl]
.not_left01

    bit 4, b
    jp z, .loop
.right01
    ld a, BANK(MapPosRight)
    call GetWayMapPos
    res 7, [hl]
    inc hl
    set 7, [hl]
    jp .loop

.entry10
    ldh a, [hCenterMark]
    or [hl]
    ld [hli], a
    ldh a, [hCenterMark]
    cpl 
    and [hl]
    ld [hld], a

    ld a, BANK(MapPosUp)
    call GetWayMapPos
    ld a, c
    or [hl]
    ld [hli], a
    ld a, c
    cpl 
    and [hl]
    ld [hl], a

    ld a, BANK(MapPosDown)
    call GetWayMapPos
    ld a, c
    or [hl]
    ld [hli], a
    ld a, c
    cpl 
    and [hl]
    ld [hl], a

    bit 5, b
    jr z, .not_left10
.left10
    ld a, BANK(MapPosLeft)
    call GetWayMapPos
    set 0, [hl]
    inc hl
    res 0, [hl]
.not_left10

    bit 4, b
    jp z, .loop
.right10
    ld a, BANK(MapPosRight)
    call GetWayMapPos
    set 7, [hl]
    inc hl
    res 7, [hl]
    jp .loop

.entry11
    ldh a, [hCenterMark]
    or [hl]
    ld [hli], a
    ldh a, [hCenterMark]
    or [hl]
    ld [hld], a

    ld a, BANK(MapPosUp)
    call GetWayMapPos
    ld a, c
    or [hl]
    ld [hli], a
    ld a, c 
    or [hl]
    ld [hl], a

    ld a, BANK(MapPosDown)
    call GetWayMapPos
    ld a, c
    or [hl]
    ld [hli], a
    ld a, c
    or [hl]
    ld [hl], a

    bit 5, b
    jr z, .not_left11
.left11
    ld a, BANK(MapPosLeft)
    call GetWayMapPos
    set 0, [hl]
    inc hl
    set 0, [hl]
.not_left11

    bit 4, b
    jp z, .loop
.right11
    ld a, BANK(MapPosRight)
    call GetWayMapPos
    set 7, [hl]
    inc hl
    set 7, [hl]
    jp .loop

SECTION "BTS", ROM0, ALIGN[8]
BtsTable:
DEF tmp = 0
REPT 8
    db 1 << tmp
    DEF tmp += 1
ENDR

SECTION "BTS Reserve", ROM0, ALIGN[8]
BtsTableR:
DEF tmp = 0
REPT 8
    db (1 << tmp) ^ $FF
    DEF tmp += 1
ENDR

SECTION "Center Table Set", ROM0, ALIGN[8]
CenterTableSet:
DEF tmp = 0
REPT 8
    db (((%111) << tmp) >> 1) & $FF
    DEF tmp += 1
ENDR

SECTION "Center Table Unset", ROM0, ALIGN[8]
CenterTableUnset:
DEF tmp = 0
REPT 8
    db ((((%111) << tmp) >> 1) & $FF) ^ $FF
    DEF tmp += 1
ENDR

MACRO TXPY2TileSet
    ; in 1: TILE_X 2: PIXEL_Y
    ; out: POS_ADDR
    DEF POS_ADDR = TILE_WIDTH * \1
    DEF POS_ADDR += \2
    DEF POS_ADDR += 152 * ( \2 / 8 )
    DEF POS_ADDR *= 2
    DEF POS_ADDR += wTileSet
ENDM

MACRO TileSet2TXPY
    ; in: POS_ADDR
    ; out: TILE_X PIXEL_Y
    DEF POS_ADDR = \1
    DEF POS_ADDR -= wTileSet
    DEF POS_ADDR /= 2
    ; PRINTLN "{d:POS_ADDR}"

    DEF TILE_X = (POS_ADDR / 8) % 20
    DEF PIXEL_Y = 8 * ((POS_ADDR / 8 ) / 20) + (POS_ADDR % 8)
ENDM

SECTION "MapPosLeft", ROMX[$4000]
MapPosLeft:
DEF POS_CUR = wTileSet
REPT (wTileEnd - wTileSet) / 2
    DEF POS_ADDR = POS_CUR
    TileSet2TXPY POS_ADDR
    ; PRINTLN "TXPY {d:TILE_X} {d:PIXEL_Y}"
    IF TILE_X == 0
    DEF TILE_X = SCREEN_WIDTH
    ENDC
    DEF TILE_X -= 1
    TXPY2TileSet TILE_X, PIXEL_Y
    
    ; PRINTLN "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    IF POS_ADDR < wTileSet || POS_ADDR >= wTileEnd
    FAIL "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    ENDC
    dw POS_ADDR
    DEF POS_CUR += 2
ENDR
REPT ($8000 - @) / 2
    dw wTileEnd
ENDR

SECTION "MapPosRight", ROMX[$4000]
MapPosRight:
DEF POS_CUR = wTileSet
REPT (wTileEnd - wTileSet) / 2
    DEF POS_ADDR = POS_CUR
    TileSet2TXPY POS_ADDR
    ; PRINTLN "TXPY {d:TILE_X} {d:PIXEL_Y}"
    DEF TILE_X += 1
    IF TILE_X == SCREEN_WIDTH
    DEF TILE_X = 0
    ENDC
    TXPY2TileSet TILE_X, PIXEL_Y

    ; PRINTLN "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    IF POS_ADDR < wTileSet || POS_ADDR >= wTileEnd
    FAIL "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    ENDC
    dw POS_ADDR
    DEF POS_CUR += 2
ENDR
REPT ($8000 - @) / 2
    dw wTileEnd
ENDR

SECTION "MapPosUp", ROMX[$4000]
MapPosUp:
DEF POS_CUR = wTileSet
REPT (wTileEnd - wTileSet) / 2
    DEF POS_ADDR = POS_CUR
    TileSet2TXPY POS_ADDR
    ; PRINTLN "TXPY {d:TILE_X} {d:PIXEL_Y}"
    IF PIXEL_Y == 0
    DEF PIXEL_Y = SCREEN_HEIGHT_PX
    ENDC
    DEF PIXEL_Y -= 1
    TXPY2TileSet TILE_X , PIXEL_Y

    ; PRINTLN "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    IF POS_ADDR < wTileSet || POS_ADDR >= wTileEnd
    FAIL "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    ENDC
    dw POS_ADDR
    DEF POS_CUR += 2
ENDR
REPT ($8000 - @) / 2
    dw wTileEnd
ENDR

SECTION "MapPosDown", ROMX[$4000]
MapPosDown:
DEF POS_CUR = wTileSet
REPT (wTileEnd - wTileSet) / 2
    DEF POS_ADDR = POS_CUR
    TileSet2TXPY POS_ADDR
    ; PRINTLN "TXPY {d:TILE_X} {d:PIXEL_Y}"
    DEF PIXEL_Y += 1
    IF PIXEL_Y == SCREEN_HEIGHT_PX
    DEF PIXEL_Y = 0
    ENDC
    TXPY2TileSet TILE_X, PIXEL_Y

    ; PRINTLN "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    IF POS_ADDR < wTileSet || POS_ADDR >= wTileEnd
    FAIL "CHAR {d:TILE_X} {d:PIXEL_Y} {x:POS_ADDR}"
    ENDC
    dw POS_ADDR
    DEF POS_CUR += 2
ENDR
REPT ($8000 - @) / 2
    dw wTileEnd
ENDR
