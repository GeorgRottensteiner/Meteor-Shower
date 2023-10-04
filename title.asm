BITMAP_TITLE_LOCATION = BITMAP_DATA_TITLE
SCREEN_CHAR_TITLE     = BITMAP_SCREEN_DATA_TITLE

TITLE_BOTTOM_BORDER_RASTER_POS = 177

!lzone InitTitleIRQ

          ;wait for exact frame so we don't end up on the wrong
          ;side of the raster
          jsr WaitFrame
          sei

          lda #$35 ; make sure that IO regs at $dxxx
          sta PROCESSOR_PORT ;are visible

          lda #$7f ;disable cia #1 generating timer irqs
          sta CIA1.IRQ_CONTROL  ;which are used by the system to flash cursor, etc

          lda #$01 ;tell VIC we want him generate raster irqs
          sta VIC.IRQ_MASK

          lda #TITLE_BOTTOM_BORDER_RASTER_POS ;nr of rasterline we want our irq occur at
          sta VIC.RASTER_POS

          ;MSB of d011 is the MSB of the requested rasterline
          ;as rastercounter goes from 0-312
          lda VIC.CONTROL_1
          and #$7f
          sta VIC.CONTROL_1

          ;set irq vector to point to our routine
          lda #<IrqSetLogoDisplay
          sta $0314
          lda #>IrqSetLogoDisplay
          sta $0315

          ;nr of rasterline we want our irq occur at
          lda #$01
          sta VIC.RASTER_POS

          ;acknowledge any pending cia timer interrupts
          ;this is just so we're 100% safe
          lda CIA1.IRQ_CONTROL
          lda CIA2.NMI_CONTROL

          lda #$37
          sta PROCESSOR_PORT

          cli
          rts



!lzone IrqSetLogoDisplay

          ;acknowledge VIC irq
          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install next state
          lda #<IrqSetLowerTitleDisplay
          sta $0314
          lda #>IrqSetLowerTitleDisplay
          sta $0315

          ;Enable char/bitmap multicolour
          lda #$18
          sta VIC.CONTROL_2

          lda TITLE_DONE
          bne +

          lda #$3B
          sta VIC.CONTROL_1
+

          ;nr of rasterline we want our irq occur at
          lda #TITLE_BOTTOM_BORDER_RASTER_POS
          sta VIC.RASTER_POS

          ;set charset
          lda #( ( BITMAP_TITLE_LOCATION % $4000 ) / $400 ) + ( ( SCREEN_CHAR_TITLE % $4000 ) / 1024 ) * 16
          sta VIC.MEMORY_CONTROL

          lda CIA2.DATA_PORT_A
          and #%11111100
          ora #%00000010
          sta CIA2.DATA_PORT_A

          lda JOYSTICK_PORT_II
          sta JOY_VALUE

          and #$1f
          ora JOY_VALUE_RELEASED
          sta JOY_VALUE_RELEASED

          jsr SFXUpdate

          jmp IRQ_RETURN_KERNAL



!lzone IrqSetLowerTitleDisplay
          ;acknowledge VIC irq

          lda PROCESSOR_PORT
          pha

          lda #$35
          sta PROCESSOR_PORT

          lda TITLE_DONE
          bne .Skip

          lda #$1B
          pha
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop

          lda CIA2.DATA_PORT_A
          and #%11111100
          ora #%00000011
          sta CIA2.DATA_PORT_A

          lda #$14
          ldx #7 ;BOTTOM_CHARSET_MULTICOLOR_1
          ldy #6 ;BOTTOM_CHARSET_MULTICOLOR_2

          ;set panel charset
          sta VIC.MEMORY_CONTROL

          pla
          sta VIC.CONTROL_1
          stx VIC.CHARSET_MULTICOLOR_1
          sty VIC.CHARSET_MULTICOLOR_2

          lda #$08
          sta VIC.CONTROL_2

.Skip
          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install top part
          lda #<IrqSetLogoDisplay
          sta $0314
          lda #>IrqSetLogoDisplay
          sta $0315


          ;nr of rasterline we want our irq occur at
          lda #$01
          sta VIC.RASTER_POS

          pla
          sta PROCESSOR_PORT

          jmp IRQ_RETURN_KERNAL



!lzone HandleTitle
          ldx #0
-
          lda BITMAP_COLOR_TITLE,x
          sta SCREEN_COLOR,x
          lda BITMAP_COLOR_TITLE + 1 * 200,x
          sta SCREEN_COLOR + 1 * 200,x
          lda BITMAP_COLOR_TITLE + 2 * 200,x
          sta SCREEN_COLOR + 2 * 200,x
          lda #12
          sta SCREEN_COLOR + 3 * 200,x
          lda #1
          sta SCREEN_COLOR + 4 * 200,x

          lda #32
          sta $0400 + 3 * 200,x
          sta $0400 + 4 * 200,x

          inx
          cpx #200
          bne -


          ;location for bitmap and screen char
          lda #( ( BITMAP_TITLE_LOCATION % $4000 ) / $400 ) + ( ( SCREEN_CHAR_TITLE % $4000 ) / 1024 ) * 16
          sta VIC.MEMORY_CONTROL


          ldx #0
-
          lda TITLE_LINE_1,x
          sta $0400 + 5 + 17 * 40,x
          lda TITLE_LINE_2,x
          sta $0400 + 5 + 19 * 40,x
          lda TITLE_LINE_3,x
          sta $0400 + 5 + 22 * 40,x
          inx
          cpx #30
          bne -

          ldx #0
-
          lda MEGASTYLE_LOGO,x
          sta $400 + 22 * 40,x
          lda MEGASTYLE_LOGO + 3,x
          sta $400 + 23 * 40,x
          lda MEGASTYLE_LOGO + 6,x
          sta $400 + 24 * 40,x
          inx
          cpx #3
          bne -



          jsr InitTitleIRQ



!lzone TitleLoop
          jsr WaitFrame

          lda JOY_VALUE
          and #JOY_FIRE
          bne TitleLoop

-
          jsr WaitFrame

          lda JOY_VALUE
          and #JOY_FIRE
          beq -

          jsr WaitFrame
          lda #$0b
          sta VIC.CONTROL_1

          lda #1
          sta TITLE_DONE

          rts


TITLE_LINE_1
          !scr "     a ludum dare 54 game     "

TITLE_LINE_2
          !scr "written by georg rottensteiner"

TITLE_LINE_3
          !scr "      press fire to play      "

TITLE_DONE
          !byte 0

MEGASTYLE_LOGO
          !byte $cf,$f7,$f7,$cc,$cc,$cc,$20,$cc,$ef