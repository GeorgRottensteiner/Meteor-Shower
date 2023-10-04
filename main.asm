!src <c64.asm>

!to "Meteor Shower.prg",cbm

BITMAP_LOCATION         = $c000
SCREEN_CHAR             = $e000
SPRITE_LOCATION         = $e400
SCREEN_COLOR            = $d800
CHARSET_PANEL_LOCATION  = $f800


CHAR_ENERGY_FULL        = 80
CHAR_ENERGY_EMPTY       = 81

PANEL_POS_REPULSE       = SCREEN_CHAR + 29 + ( 21 + 2 ) * 40
PANEL_POS_TIMER         = SCREEN_CHAR + 29 + ( 21 + 1 ) * 40
PANEL_POS_SCORE         = SCREEN_CHAR + 20 + ( 21 + 1 ) * 40
PANEL_POS_OXYGEN        = SCREEN_CHAR + 3 + ( 21 + 1 ) * 40
PANEL_POS_HULL          = SCREEN_CHAR + 3 + ( 21 + 2 ) * 40
PANEL_POS_TEXT          = SCREEN_CHAR + 12 + ( 21 + 2 ) * 40

NUM_SPRITES             = 28

;placeholder for various temp parameters
PARAM2                  = $04
PARAM3                  = $05
PARAM4                  = $06
PARAM5                  = $07
PARAM6                  = $08
PARAM7                  = $09
PARAM8                  = $0A
PARAM9                  = $0B
PARAM10                 = $0C
PARAM11                 = $0D

CURRENT_INDEX           = $0E
CURRENT_SUB_INDEX       = $0F

PARAM1                  = $10

;placeholder for zero page pointers
ZEROPAGE_POINTER_1      = $17
ZEROPAGE_POINTER_2      = $19
ZEROPAGE_POINTER_3      = $21
ZEROPAGE_POINTER_4      = $23


* = $0801

!basic
          lda #0
          sta VIC.BACKGROUND_COLOR
          sta VIC.BORDER_COLOR
          sta VIC.SPRITE_ENABLE

          lda #11
          sta VIC.SPRITE_MULTICOLOR_1
          lda #12
          sta VIC.SPRITE_MULTICOLOR_2

          ;Enable char/bitmap multicolour
          lda #$18
          sta VIC.CONTROL_2

          lda #$3B
          sta VIC.CONTROL_1

          ;VIC bank
          lda CIA2.DATA_PORT_A
          and #%11111100
          ora #%00000010
          sta CIA2.DATA_PORT_A


          jsr HandleTitle

          jsr WaitFrame
          lda #$0b
          sta VIC.CONTROL_1


          ;location for bitmap and screen char
          lda #( ( BITMAP_LOCATION % $4000 ) / $400 ) + ( ( SCREEN_CHAR % $4000 ) / 1024 ) * 16
          sta VIC.MEMORY_CONTROL

          sei

          lda #$34
          sta PROCESSOR_PORT

          ;copy bitmap
          lda #<BITMAP_DATA
          sta .Read1
          lda #>BITMAP_DATA
          sta .Read1 + 1
          lda #<BITMAP_LOCATION
          sta .Write1
          lda #>BITMAP_LOCATION
          sta .Write1 + 1

          ldy #0
          ldx #0
-
.Read1 = * + 1
          lda $ffff,y
.Write1 = * + 1
          sta $ffff,y

          iny
          bne -

          inc .Read1 + 1
          inc .Write1 + 1

          inx
          cpx #$1c
          bne -

          lda #$37
          sta PROCESSOR_PORT
          ldx #0
-
          lda BITMAP_COLOR,x
          sta SCREEN_COLOR,x
          lda BITMAP_COLOR + 1 * 250,x
          sta SCREEN_COLOR + 1 * 250,x
          lda BITMAP_COLOR + 2 * 250,x
          sta SCREEN_COLOR + 2 * 250,x
          lda BITMAP_COLOR + 3 * 250,x
          sta SCREEN_COLOR + 3 * 250,x

          lda BITMAP_SCREEN_DATA,x
          sta SCREEN_CHAR,x
          lda BITMAP_SCREEN_DATA + 1 * 250,x
          sta SCREEN_CHAR + 1 * 250,x
          lda BITMAP_SCREEN_DATA + 2 * 250,x
          sta SCREEN_CHAR + 2 * 250,x
          lda BITMAP_SCREEN_DATA + 3 * 250,x
          sta SCREEN_CHAR + 3 * 250,x

          inx
          cpx #250
          bne -

          ldx #0
-
          lda CHARSET_PANEL,x
          sta CHARSET_PANEL_LOCATION,x
          lda CHARSET_PANEL + 1 * 256,x
          sta CHARSET_PANEL_LOCATION + 1 * 256,x
          lda CHARSET_PANEL + 2 * 256,x
          sta CHARSET_PANEL_LOCATION + 2 * 256,x
          lda CHARSET_PANEL + 3 * 256,x
          sta CHARSET_PANEL_LOCATION + 3 * 256,x

          inx
          bne -


          cli

          ldx #0
          ldy #0
-
.ReadSpritePos = * + 1
          lda SPRITES,x
.WriteSpritePos = * + 1
          sta SPRITE_LOCATION,x

          inx
          bne -

          inc .ReadSpritePos + 1
          inc .WriteSpritePos + 1
          iny
          cpy #( NUM_SPRITES + 3 ) / 4
          bne -

          ldx #0
-
          lda PANEL,x
          sta SCREEN_CHAR + 21 * 40,x
          lda PANEL + 4 * 40,x
          sta SCREEN_COLOR + 21 * 40,x
          lda PANEL + 2 * 40,x
          sta SCREEN_CHAR + 2 * 40 + 21 * 40,x
          lda PANEL + 2 * 40 + 4 * 40,x
          sta SCREEN_COLOR + 2 * 40 + 21 * 40,x

          inx
          cpx #2 * 40
          bne -

          lda #15
          sta SID.FILTER_MODE_VOLUME

          jsr InitGameIRQ

          ;VIC bank
          lda CIA2.DATA_PORT_A
          and #%11111100
          ora #%00000000
          sta CIA2.DATA_PORT_A

          lda #$37
          sta PROCESSOR_PORT

          jsr WaitFrame
          lda #$1b
          sta VIC.CONTROL_1

          jmp StartGame


!src "objects.asm"
!src "irq.asm"
!src "util.asm"
!src "game.asm"
!src "sfxplay.asm"
!src "title.asm"


JOY_VALUE
          !byte 0
JOY_VALUE_RELEASED
          !byte 0



BITMAP_DATA
!media "background.graphicscreen",BITMAP

BITMAP_SCREEN_DATA
!media "background.graphicscreen",SCREEN

BITMAP_COLOR
!media "background.graphicscreen",COLOR

CHARSET_PANEL
!media "panel.charscreen",CHARSET,0,128

PANEL
!media "panel.charscreen",CHARCOLOR

SPRITES
!media "sprites.spriteproject",SPRITE,0,NUM_SPRITES

BITMAP_COLOR_TITLE
!media "title.graphicscreen",COLOR

* = $5c00
BITMAP_SCREEN_DATA_TITLE
!media "title.graphicscreen",SCREEN

* = $6000
BITMAP_DATA_TITLE
!media "title.graphicscreen",BITMAP

