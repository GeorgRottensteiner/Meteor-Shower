BOTTOM_BORDER_RASTER_POS = 219

!lzone InitGameIRQ

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

          lda #BOTTOM_BORDER_RASTER_POS ;nr of rasterline we want our irq occur at
          sta VIC.RASTER_POS

          ;MSB of d011 is the MSB of the requested rasterline
          ;as rastercounter goes from 0-312
          lda VIC.CONTROL_1
          and #$7f
          sta VIC.CONTROL_1

          ;set irq vector to point to our routine
          lda #<IrqSetGame
          sta $0314
          lda #>IrqSetGame
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



!lzone IrqSetGame

          ;acknowledge VIC irq
          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install next state
          lda #<IrqSetPanel
          sta $0314
          lda #>IrqSetPanel
          sta $0315

          ;Enable char/bitmap multicolour
          lda #$18
          sta VIC.CONTROL_2

          lda #$3B
          sta VIC.CONTROL_1

          ;nr of rasterline we want our irq occur at
          lda #BOTTOM_BORDER_RASTER_POS
          sta VIC.RASTER_POS

          ;set charset
          lda #( ( BITMAP_LOCATION % $4000 ) / $400 ) + ( ( SCREEN_CHAR % $4000 ) / 1024 ) * 16
          sta VIC.MEMORY_CONTROL

          lda PROCESSOR_PORT
          pha

          lda #$35
          sta PROCESSOR_PORT

          ldx #0
-
          lda SPRITE_IMAGE,x
          sta SPRITE_POINTER_BASE,x

          inx
          cpx #8
          bne -

          pla
          sta PROCESSOR_PORT

          lda JOYSTICK_PORT_II
          sta JOY_VALUE

          and #$1f
          ora JOY_VALUE_RELEASED
          sta JOY_VALUE_RELEASED

          jsr SFXUpdate

          jmp IRQ_RETURN_KERNAL



!lzone IrqSetPanel
          ;acknowledge VIC irq

          lda PROCESSOR_PORT
          pha

          lda #$35
          sta PROCESSOR_PORT


          lda #$1B
          ;lda BOTTOM_VIC.CONTROL_1
          pha
          nop
          nop
          nop
          nop
          nop

          lda #( ( ( SCREEN_CHAR % 16384 ) / 1024 ) * 16 ) + ( ( CHARSET_PANEL_LOCATION % 16384 ) / $400 )
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

          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install top part
          lda #<IrqSetGame
          sta $0314
          lda #>IrqSetGame
          sta $0315


          ;nr of rasterline we want our irq occur at
          lda #$01
          sta VIC.RASTER_POS

          ;;count time (always PAL)
;          inc PLAY_TIME_FRAME
;          ;ldy KERNAL_PAL
;          ldy #1
;          lda PLAY_TIME_FRAME
;          cmp FRAMES_PER_SECOND,y
;          bne +
;
;          lda #0
;          sta PLAY_TIME_FRAME
;          inc PLAY_TIME_SECONDS
;          lda PLAY_TIME_SECONDS
;          cmp #60
;          bne +
;
;          lda #0
;          sta PLAY_TIME_SECONDS
;          inc PLAY_TIME_MINUTES
;          lda PLAY_TIME_MINUTES
;          cmp #255
;          bne +
;
;          lda #254
;          sta PLAY_TIME_MINUTES
;
;+

          pla
          sta PROCESSOR_PORT

          jmp IRQ_RETURN_KERNAL
