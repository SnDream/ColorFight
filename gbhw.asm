; Graciously aped from http://nocash.emubase.de/pandocs.htm .

; Joypad
DEF A_BUTTON_F = 0
DEF B_BUTTON_F = 1
DEF SELECT_F   = 2
DEF START_F    = 3
DEF D_RIGHT_F  = 4
DEF D_LEFT_F   = 5
DEF D_UP_F     = 6
DEF D_DOWN_F   = 7
DEF NO_INPUT   = %00000000
DEF A_BUTTON   = 1 << A_BUTTON_F
DEF B_BUTTON   = 1 << B_BUTTON_F
DEF SELECT     = 1 << SELECT_F
DEF START      = 1 << START_F
DEF D_RIGHT    = 1 << D_RIGHT_F
DEF D_LEFT     = 1 << D_LEFT_F
DEF D_UP       = 1 << D_UP_F
DEF D_DOWN     = 1 << D_DOWN_F

DEF BUTTONS    = A_BUTTON | B_BUTTON | SELECT | START
DEF D_PAD      = D_RIGHT | D_LEFT | D_UP | D_DOWN

DEF R_DPAD     = %00100000
DEF R_BUTTONS  = %00010000

; VRAM
DEF TILE_SIZE      = $10
DEF TILE_PIXEL_X   = 8
DEF TILE_PIXEL_Y   = 8
DEF SCREEN_X       = 20
DEF SCREEN_Y       = 18
DEF SCREEN_PIXEL_X = SCREEN_X * TILE_PIXEL_X
DEF SCREEN_PIXEL_Y = SCREEN_Y * TILE_PIXEL_Y

DEF TILE_SET  = $8000
DEF MAP_SET   = $9800
DEF MAP_SET_X = $20
DEF MAP_SET_Y = $20

; MBC3
DEF MBC3SRamEnable = $0000
DEF MBC3RomBank    = $2000
DEF MBC3SRamBank   = $4000
DEF MBC3LatchClock = $6000
DEF MBC3RTC        = $a000

DEF SRAM_DISABLE = $00
DEF SRAM_ENABLE  = $0a

DEF NUM_SRAM_BANKS = 4

DEF RTC_S  = $08 ; Seconds   0-59 (0-3Bh)
DEF RTC_M  = $09 ; Minutes   0-59 (0-3Bh)
DEF RTC_H  = $0a ; Hours     0-23 (0-17h)
DEF RTC_DL = $0b ; Lower 8 bits of Day Counter (0-FFh)
DEF RTC_DH = $0c ; Upper 1 bit of Day Counter, Carry Bit, Halt Flag
        ; Bit 0  Most significant bit of Day Counter (Bit 8)
        ; Bit 6  Halt (0=Active, 1=Stop Timer)
        ; Bit 7  Day Counter Carry Bit (1=Counter Overflow)

; interrupt flags
DEF VBLANK   = 0
DEF LCD_STAT = 1
DEF TIMER    = 2
DEF SERIAL   = 3
DEF JOYPAD   = 4

; OAM attribute flags
DEF OAM_PALETTE   = %111
DEF OAM_TILE_BANK = 3
DEF OAM_OBP_NUM   = 4 ; Non CGB Mode Only
DEF OAM_X_FLIP    = 5
DEF OAM_Y_FLIP    = 6
DEF OAM_PRIORITY  = 7 ; 0: OBJ above BG, 1: OBJ behind BG (colors 1-3)


; Hardware registers
DEF rJOYP       = $ff00 ; Joypad (R/W)
DEF rSB         = $ff01 ; Serial transfer data (R/W)
DEF rSC         = $ff02 ; Serial Transfer Control (R/W)
DEF rSC_ON    = 7
DEF rSC_CGB   = 1
DEF rSC_CLOCK = 0
DEF rDIV        = $ff04 ; Divider Register (R/W)
DEF rTIMA       = $ff05 ; Timer counter (R/W)
DEF rTMA        = $ff06 ; Timer Modulo (R/W)
DEF rTAC        = $ff07 ; Timer Control (R/W)
DEF rTAC_ON        = 2
DEF rTAC_4096_HZ   = 0
DEF rTAC_262144_HZ = 1
DEF rTAC_65536_HZ  = 2
DEF rTAC_16384_HZ  = 3
DEF rIF         = $ff0f ; Interrupt Flag (R/W)
DEF rNR10       = $ff10 ; Channel 1 Sweep register (R/W)
DEF rNR11       = $ff11 ; Channel 1 Sound length/Wave pattern duty (R/W)
DEF rNR12       = $ff12 ; Channel 1 Volume Envelope (R/W)
DEF rNR13       EQU $ff13 ; Channel 1 Fr=ency lo (Write Only)
DEF rNR14       EQU $ff14 ; Channel 1 Fr=ency hi (R/W)
DEF rNR20       = $ff15 ; Channel 2 Sweep register (R/W)
DEF rNR21       = $ff16 ; Channel 2 Sound Length/Wave Pattern Duty (R/W)
DEF rNR22       = $ff17 ; Channel 2 Volume Envelope (R/W)
DEF rNR23       EQU $ff18 ; Channel 2 Fr=ency lo data (W)
DEF rNR24       EQU $ff19 ; Channel 2 Fr=ency hi data (R/W)
DEF rNR30       = $ff1a ; Channel 3 Sound on/off (R/W)
DEF rNR31       = $ff1b ; Channel 3 Sound Length
DEF rNR32       = $ff1c ; Channel 3 Select output level (R/W)
DEF rNR33       EQU $ff1d ; Channel 3 Fr=ency's lower data (W)
DEF rNR34       EQU $ff1e ; Channel 3 Fr=ency's higher data (R/W)
DEF rNR40       = $ff1f ; Channel 4 Sweep register (R/W)
DEF rNR41       = $ff20 ; Channel 4 Sound Length (R/W)
DEF rNR42       = $ff21 ; Channel 4 Volume Envelope (R/W)
DEF rNR43       = $ff22 ; Channel 4 Polynomial Counter (R/W)
DEF rNR44       = $ff23 ; Channel 4 Counter/consecutive; Inital (R/W)
DEF rNR50       = $ff24 ; Channel control / ON-OFF / Volume (R/W)
DEF rNR51       = $ff25 ; Selection of Sound output terminal (R/W)
DEF rNR52       = $ff26 ; Sound on/off
DEF rWave_0     = $ff30
DEF rWave_1     = $ff31
DEF rWave_2     = $ff32
DEF rWave_3     = $ff33
DEF rWave_4     = $ff34
DEF rWave_5     = $ff35
DEF rWave_6     = $ff36
DEF rWave_7     = $ff37
DEF rWave_8     = $ff38
DEF rWave_9     = $ff39
DEF rWave_a     = $ff3a
DEF rWave_b     = $ff3b
DEF rWave_c     = $ff3c
DEF rWave_d     = $ff3d
DEF rWave_e     = $ff3e
DEF rWave_f     = $ff3f
DEF rLCDC       = $ff40 ; LCD Control (R/W)
DEF rSTAT       = $ff41 ; LCDC Status (R/W)
DEF rSCY        = $ff42 ; Scroll Y (R/W)
DEF rSCX        = $ff43 ; Scroll X (R/W)
DEF rLY         = $ff44 ; LCDC Y-Coordinate (R)
DEF rLYC        = $ff45 ; LY Compare (R/W)
DEF rDMA        = $ff46 ; DMA Transfer and Start Address (W)
DEF rBGP        = $ff47 ; BG Palette Data (R/W) - Non CGB Mode Only
DEF rOBP0       = $ff48 ; Object Palette 0 Data (R/W) - Non CGB Mode Only
DEF rOBP1       = $ff49 ; Object Palette 1 Data (R/W) - Non CGB Mode Only
DEF rWY         = $ff4a ; Window Y Position (R/W)
DEF rWX         = $ff4b ; Window X Position minus 7 (R/W)
DEF rLCDMODE    = $ff4c
DEF rKEY1       = $ff4d ; CGB Mode Only - Prepare Speed Switch
DEF rVBK        = $ff4f ; CGB Mode Only - VRAM Bank
DEF rBLCK       = $ff50
DEF rHDMA1      = $ff51 ; CGB Mode Only - New DMA Source, High
DEF rHDMA2      = $ff52 ; CGB Mode Only - New DMA Source, Low
DEF rHDMA3      = $ff53 ; CGB Mode Only - New DMA Destination, High
DEF rHDMA4      = $ff54 ; CGB Mode Only - New DMA Destination, Low
DEF rHDMA5      = $ff55 ; CGB Mode Only - New DMA Length/Mode/Start
DEF rRP         = $ff56 ; CGB Mode Only - Infrared Communications Port
DEF rBGPI       = $ff68 ; CGB Mode Only - Background Palette Index
DEF rBGPD       = $ff69 ; CGB Mode Only - Background Palette Data
DEF rOBPI       = $ff6a ; CGB Mode Only - Sprite Palette Index
DEF rOBPD       = $ff6b ; CGB Mode Only - Sprite Palette Data
DEF rUNKNOWN1   = $ff6c ; (FEh) Bit 0 (Read/Write) - CGB Mode Only
DEF rSVBK       = $ff70 ; CGB Mode Only - WRAM Bank
DEF rUNKNOWN2   = $ff72 ; (00h) - Bit 0-7 (Read/Write)
DEF rUNKNOWN3   = $ff73 ; (00h) - Bit 0-7 (Read/Write)
DEF rUNKNOWN4   = $ff74 ; (00h) - Bit 0-7 (Read/Write) - CGB Mode Only
DEF rUNKNOWN5   = $ff75 ; (8Fh) - Bit 4-6 (Read/Write)
DEF rUNKNOWN6   = $ff76 ; (00h) - Always 00h (Read Only)
DEF rUNKNOWN7   = $ff77 ; (00h) - Always 00h (Read Only)
DEF rIE         = $ffff ; Interrupt Enable (R/W)
