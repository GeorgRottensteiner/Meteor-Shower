!lzone StartGame
          lda #0
          sta WAVE_NO

          lda #2
          sta MAX_METEORS_ON_SCREEN

          lda #'0'
          sta PANEL_POS_SCORE
          sta PANEL_POS_SCORE + 1
          sta PANEL_POS_SCORE + 2
          sta PANEL_POS_SCORE + 3
          sta PANEL_POS_SCORE + 4
          sta PANEL_POS_SCORE + 5

!lzone StartRound
          jsr WaitFrame

          lda WAVE_NO
          cmp #250
          beq +
          inc WAVE_NO
+
          lda #0
          sta VIC.SPRITE_ENABLE

          ldx #0
-
          sta SPRITE_ACTIVE,x
          inx
          cpx #8
          bne -

          lda #20
          sta PARAM1
          lda #16
          sta PARAM2
          lda #TYPE_PLAYER
          sta PARAM3
          jsr AddObject
          lda #2
          sta SPRITE_NUM_PARTS

          lda #19
          sta PARAM2
          lda #TYPE_PLAYER + 1
          sta PARAM3
          jsr AddObject
          lda #0
          sta SPRITE_MAIN_INDEX + 1

          lda #0
          sta PLAYER_FIRE_POSE
          sta REPULSE_RELOAD_DELAY
          sta TIMER_DELAY
          sta METEORS_ALIVE
          sta PLAYER_DEAD
          sta OXYGEN_DELAY
          sta PLAYER_EXIT_ACTIVE
          sta PANEL_TEXT_FLASH_POS
          sta PANEL_TEXT_FLASH_ACTIVE

          lda MAX_METEORS_ON_SCREEN
          cmp #7
          beq +
          inc MAX_METEORS_ON_SCREEN
+

          lda #8
          sta REPULSE_COUNT
          sta TIMER_TO_GO
          sta HULL_STRENGTH
          sta OXYGEN_LEFT

          ldx #0
          lda #CHAR_ENERGY_FULL
-
          sta PANEL_POS_REPULSE,x
          sta PANEL_POS_TIMER,x
          sta PANEL_POS_HULL,x
          sta PANEL_POS_OXYGEN,x

          inx
          cpx #8
          bne -

          ldx #0
-
          lda PANEL_TEXT_DEFEND,x
          sta PANEL_POS_TEXT,x
          lda #12
          sta PANEL_POS_TEXT + SCREEN_COLOR - SCREEN_CHAR,x

          inx
          cpx #16
          bne -


!lzone GameLoop
          jsr WaitFrame

          jsr ObjectControl

          lda PANEL_TEXT_FLASH_ACTIVE
          beq .NoFlash

          inc PANEL_TEXT_FLASH_POS
          lda PANEL_TEXT_FLASH_POS
          and #$0f
          tay

          ldx #0
          lda FLASH_COLOR_TABLE,y
-
          sta PANEL_POS_TEXT + SCREEN_COLOR - SCREEN_CHAR,x
          inx
          cpx #16
          bne -

.NoFlash

          lda PLAYER_DEAD
          bne .SkipGameTimers

          inc REPULSE_RELOAD_DELAY
          lda REPULSE_RELOAD_DELAY
          cmp #32
          bne +

          lda #0
          sta REPULSE_RELOAD_DELAY
          lda REPULSE_COUNT
          cmp #8
          beq +

          ldy REPULSE_COUNT
          lda #CHAR_ENERGY_FULL
          sta PANEL_POS_REPULSE,y
          inc REPULSE_COUNT
+

          inc OXYGEN_DELAY
          bne +

          dec OXYGEN_LEFT
          ldy OXYGEN_LEFT
          lda #CHAR_ENERGY_EMPTY
          sta PANEL_POS_OXYGEN,y
          cpy #0
          bne +

          ldx #0
          jsr BHPlayer.PlayerKilled
          jmp GameLoop

+



          lda TIMER_TO_GO
          beq .TimerDown

          ;timer needs to be a little bit smaller than the oxygen count
          inc TIMER_DELAY
          lda TIMER_DELAY
          cmp #210
          bne +

          lda #0
          sta TIMER_DELAY
          dec TIMER_TO_GO
          bne ++

          ;start exit sequence
          ldx #0
-
          lda PANEL_TEXT_EXIT,x
          sta PANEL_POS_TEXT,x
          inx
          cpx #16
          bne -

          lda #1
          sta PLAYER_EXIT_ACTIVE
          sta PANEL_TEXT_FLASH_ACTIVE

          ldy #SFX_COMPLETE
          jsr PlaySoundEffect

++
          ldy TIMER_TO_GO
          lda #CHAR_ENERGY_EMPTY
          sta PANEL_POS_TIMER,y




+
.TimerDown
.SkipGameTimers

          inc SPEED_TABLE_POS
          lda SPEED_TABLE_POS
          and #$07
          sta SPEED_TABLE_POS

          ;spawn meteors?
          lda METEORS_ALIVE
          cmp MAX_METEORS_ON_SCREEN
          beq .SkipSpawnMeteor

          jsr GenerateRandomNumber
          and #$1f
          bne .SkipSpawnMeteor

          lda #2
          sta PARAM5
          lda #37
          sta PARAM6
          jsr GenerateRangedRandom
          sta PARAM1
          lda #0
          sta PARAM2
          lda #TYPE_METEOR
          sta PARAM3
          jsr AddObject
          beq .NoFreeSlot

          ;shift outside screen
          lda #16
          sta PARAM2
-
          jsr ObjectMoveUp
          dec PARAM2
          bne -

          lda #1
          sta PARAM5
          lda WAVE_NO
          clc
          adc #3
          sta PARAM6
          jsr GenerateRangedRandom
          sta SPRITE_SPEED,x

          ldy #SFX_SEARCH
          jsr PlaySoundEffect

          inc METEORS_ALIVE

.NoFreeSlot
.SkipSpawnMeteor
          jmp GameLoop



;a = value, y = offset
!lzone IncScore
          pha
          lda PROCESSOR_PORT
          sta .TEMP
          lda #$35
          sta PROCESSOR_PORT
          pla
-
          clc
          adc PANEL_POS_SCORE,y
          cmp #58
          bcc +

          ;overflow
          sec
          sbc #10
          sta PANEL_POS_SCORE,y
          dey
          ;total overflow? we've wrapped to 000000
          bmi .Overflow

          lda #1
          jmp -

+
          sta PANEL_POS_SCORE,y

.Overflow
.TEMP = * + 1
          lda #$ff
          sta PROCESSOR_PORT

          rts




METEORS_ALIVE
          !byte 0

MAX_METEORS_ON_SCREEN
          !byte 0

WAVE_NO
          !byte 0

TIMER_DELAY
          !byte 0

TIMER_TO_GO
          !byte 0

OXYGEN_DELAY
          !byte 0

OXYGEN_LEFT
          !byte 0

PLAYER_EXIT_ACTIVE
          !byte 0

HULL_STRENGTH
          !byte 0

PANEL_TEXT_DEFEND
          !scr " repel  meteors ",0

PANEL_TEXT_EXIT
          !scr "   go  inside   ",0

PANEL_TEXT_PLAY
          !scr "   press fire   ",0

PLAYER_DEAD
          !byte 0

PANEL_TEXT_FLASH_ACTIVE
          !byte 0

PANEL_TEXT_FLASH_POS
          !byte 0

FLASH_COLOR_TABLE
          !byte 1,1,1,1,1,1,15,12,11,11,11,11,11,11,12,15