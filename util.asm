;wait for the raster to reach line $f8
;this is keeping our timing stable

;are we on line $F8 already? if so, wait for the next full screen
;prevents mistimings if called too fast
!lzone WaitFrame
          lda #$ff

          ;wait for raster to reach raster A
WaitForSpecificFrame
          cmp VIC.RASTER_POS
          beq WaitForSpecificFrame

          ;wait for the raster to reach line $f8 (should be closer to the start of this line this way)
.WaitStep2
          cmp VIC.RASTER_POS
          bne .WaitStep2
          rts




!lzone GenerateRandomNumber
          lda $dc04
          eor $dc05
          eor $dd04
          adc $dd05
          eor $dd06
          eor $dd07
          rts



;lower end = PARAM5
;higher end = PARAM6
!lzone GenerateRangedRandom
          lda PARAM6
          sec
          sbc PARAM5
          clc
          adc #1
          sta PARAM6

          jsr GenerateRandomNumber
.CheckValue
          cmp PARAM6
          bcc .ValueOk

          ;too high
          sec
          sbc PARAM6
          jmp .CheckValue

.ValueOk
          clc
          adc PARAM5
          rts
