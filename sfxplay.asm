FX_NONE               = 0
FX_SLIDE              = 1
FX_STEP               = 2
FX_SLIDE_PING_PONG    = 3

FX_WAVE_TRIANGLE      = 0
FX_WAVE_SAWTOOTH      = 1
FX_WAVE_PULSE         = 2
FX_WAVE_NOISE         = 3


ZP_ADDRESS            = $57

NUM_CHANNELS          = 3

!zone SFXPlay
;a = channel (0 to 2 )
;x = sfx address lo
;y = sfx address hi
;expect 10 bytes, (FFFFFFWW) = Effect + Waveform
;                FX lo/hi, Pulse Lo, Pulse Hi, AD, SR, Effect Delta, Effect Delay, Effect Step
SFXPlay
          stx ZP_ADDRESS
          sty ZP_ADDRESS + 1

          ;lda #0
          sta .CURRENT_CHANNEL
          tax
          lda CHANNEL_OFFSET,x
          sta .CURRENT_VOICE

          ldy #0
          lda (ZP_ADDRESS),y
          lsr
          lsr
          sta EFFECT_TYPE_SETUP,x
          sta EFFECT_TYPE,x

          lda (ZP_ADDRESS),y
          and #$03
          tay

          ;x is now 0,7,14
          ldx .CURRENT_VOICE
          lda WAVE_FORM_TABLE,y
          sta SID_MIRROR + 4,x

          lda #0
          sta SID.FREQUENCY_LO_1 + 4,x

          txa
          clc
          adc #5
          tax
          ldy #5
          lda (ZP_ADDRESS),y
          ;lda #$98
          sta SID_MIRROR,x
          sta SID_MIRROR_SETUP,x
          sta SID.FREQUENCY_LO_1,x

          inx
          ldy #6
          lda (ZP_ADDRESS),y
          ;lda #$b0
          sta SID_MIRROR,x
          sta SID_MIRROR_SETUP,x
          sta SID.FREQUENCY_LO_1,x

          ;copy effect value 1 to 3 to SID registers 0 to 2
          ldx .CURRENT_VOICE
          ldy #1
-

          lda (ZP_ADDRESS),y
          sta SID_MIRROR,x
          sta SID_MIRROR_SETUP,x
          sta SID.FREQUENCY_LO_1,x

          iny
          inx
          cpy #4
          bne -

          ;copy effect data
          ldx .CURRENT_CHANNEL
          ldy #7
          lda (ZP_ADDRESS),y
          sta EFFECT_DELTA,x
          sta EFFECT_DELTA_SETUP,x

          iny
          lda (ZP_ADDRESS),y
          sta EFFECT_DELAY,x
          sta EFFECT_DELAY_SETUP,x

          iny
          lda (ZP_ADDRESS),y
          sta EFFECT_VALUE,x
          sta EFFECT_VALUE_SETUP,x

          ;set wave form
          ldx .CURRENT_VOICE
          lda SID_MIRROR + 4,x
          sta SID_MIRROR_SETUP + 4,x
          sta SID.FREQUENCY_LO_1 + 4,x

          rts


;0,1,2
.CURRENT_CHANNEL
          !byte 0
;0, 7, 14
.CURRENT_VOICE
          !byte 0



!lzone SFXUpdate
          ldy #0
          sty SFXPlay.CURRENT_CHANNEL
.NextChannel
          ldx EFFECT_TYPE,y
          lda FX_TABLE_LO,x
          sta .JumpPos
          lda FX_TABLE_HI,x
          sta .JumpPos + 1

          ldx SFXPlay.CURRENT_CHANNEL
          ldy CHANNEL_OFFSET,x

.JumpPos = * + 1
          jsr $ffff

          inc SFXPlay.CURRENT_CHANNEL
          ldy SFXPlay.CURRENT_CHANNEL
          cpy #3
          bne .NextChannel

          rts



FX_TABLE_LO
          !byte <FXNone
          !byte <FXSlide
          !byte <FXStep
          !byte <FXPingPong

FX_TABLE_HI
          !byte >FXNone
          !byte >FXSlide
          !byte >FXStep
          !byte >FXPingPong


!zone FXSlide
FXSlide
          ;x = channel
          ;y = channel offset
          dec EFFECT_DELAY,x
          beq FXOff

          lda EFFECT_DELTA,x
          bpl .Up

          lda SID_MIRROR + 1,y
          clc
          adc EFFECT_DELTA,x
          bcc .Overflow
          jmp +


.Up
          lda SID_MIRROR + 1,y
          clc
          adc EFFECT_DELTA,x
          bcs .Overflow
+
          sta SID_MIRROR + 1,y
          sta SID.FREQUENCY_LO_1 + 1,y
          rts

.Overflow

FXOff
          ;x = channel
          ;y = channel offset
          lda #0
          sta EFFECT_DELTA,x
          sta SID.CONTROL_WAVE_FORM_1,y
          rts



!zone FXNone
FXNone
          ;x = channel
          ;y = channel offset
          dec EFFECT_DELAY,x
          beq FXOff
          rts



!zone FXStep
FXStep
          ;x = channel
          ;y = channel offset
          dec EFFECT_DELAY,x
          bne .NoStep

          ;step, switch to slide
          lda SID_MIRROR + 1,y
          clc
          adc EFFECT_VALUE,x
          sta SID_MIRROR + 1,y
          sta SID.FREQUENCY_LO_1 + 1,y

          lda #0
          sta EFFECT_DELTA,x
          lda EFFECT_DELAY_SETUP,x
          sta EFFECT_DELAY,x

          lda #FX_SLIDE
          sta EFFECT_TYPE,x

.NoStep
          rts



!zone FXPingPong
FXPingPong
          ;x = channel
          ;y = channel offset
          dec EFFECT_VALUE,x
          bne .GoSlide

          lda EFFECT_VALUE_SETUP,x
          sta EFFECT_VALUE,x

          lda EFFECT_DELTA,x
          eor #$ff
          clc
          adc #1
          sta EFFECT_DELTA,x

.GoSlide
          jmp FXSlide





WAVE_FORM_TABLE
          !byte 17,33,65,129

CHANNEL_OFFSET
          !byte 0,7,14

SID_MIRROR
          !fill 7 * NUM_CHANNELS
SID_MIRROR_SETUP
          !fill 7 * NUM_CHANNELS

EFFECT_TYPE
          !fill NUM_CHANNELS
EFFECT_TYPE_SETUP
          !fill NUM_CHANNELS

EFFECT_DELTA
          !fill NUM_CHANNELS
EFFECT_DELTA_SETUP
          !fill NUM_CHANNELS

EFFECT_DELAY
          !fill NUM_CHANNELS
EFFECT_DELAY_SETUP
          !fill NUM_CHANNELS
EFFECT_VALUE
          !fill NUM_CHANNELS
EFFECT_VALUE_SETUP
          !fill NUM_CHANNELS



!zone PlaySoundEffect
PlaySoundEffectInChannel0
          lda #0

;y = SFX_...
;a = channel 0,1,2
PlaySoundEffectInChannel
          pha
          ldx SFX_TABLE_LO,y
          lda SFX_TABLE_HI,y
          tay
          pla
          jmp SFXPlay

;y = SFX_...
PlaySoundEffect
          ;lda MUSIC_ACTIVE
;          beq +
;          rts
;+

          inc .LAST_USED_CHANNEL
          lda .LAST_USED_CHANNEL
          cmp #3
          bne +

          lda #0
          sta .LAST_USED_CHANNEL
+
          jmp PlaySoundEffectInChannel



.LAST_USED_CHANNEL
          !byte 0



SFX_PICK_PLUS     = 0
SFX_PICK_MINUS    = 1
SFX_COMPLETE      = 2
SFX_LOSE          = 3
SFX_BOMB          = 4
SFX_BONUS_BLIP    = 5
SFX_POWER_UP      = 6
SFX_FLATTEN_ENEMY = 7
SFX_COMPUTER      = 8
SFX_BLIP          = 9
SFX_DOOR          = 10
SFX_EXPLODE       = 11
SFX_SHOOT         = 12
SFX_GUN_EMPTY     = 13
SFX_SEARCH        = 14
SFX_CHARGE        = 15
SFX_HURT          = 16

SFX_TABLE_LO
          !byte <FX_PICK_PLUS
          !byte <FX_PICK_MINUS
          !byte <FX_COMPLETE
          !byte <FX_LOSE
          !byte <FX_BOMB
          !byte <FX_BONUS_BLIP
          !byte <FX_POWER_UP
          !byte <FX_JUMP_AT_ENEMY
          !byte <FX_COMPUTER
          !byte <FX_BLIP
          !byte <FX_DOOR
          !byte <FX_EXPLODE
          !byte <FX_SHOOT
          !byte <FX_GUN_EMPTY
          !byte <FX_SEARCH
          !byte <FX_CHARGE
          !byte <FX_HURT

SFX_TABLE_HI
          !byte >FX_PICK_PLUS
          !byte >FX_PICK_MINUS
          !byte >FX_COMPLETE
          !byte >FX_LOSE
          !byte >FX_BOMB
          !byte >FX_BONUS_BLIP
          !byte >FX_POWER_UP
          !byte >FX_JUMP_AT_ENEMY
          !byte >FX_COMPUTER
          !byte >FX_BLIP
          !byte >FX_DOOR
          !byte >FX_EXPLODE
          !byte >FX_SHOOT
          !byte >FX_GUN_EMPTY
          !byte >FX_SEARCH
          !byte >FX_CHARGE
          !byte >FX_HURT



FX_PICK_PLUS
          ;FX lo/hi, Pulse Lo, Pulse Hi, AD, SR, Effect Delta, Effect Delay, Effect Step
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_TRIANGLE
          !hex f40d257d95ad0308c5

FX_PICK_MINUS
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_TRIANGLE
          !hex f423257d95adfd08c5

FX_COMPLETE
          !byte ( FX_SLIDE_PING_PONG << 2 ) | FX_WAVE_SAWTOOTH
          !hex 1c446c9412e4174e0d

FX_LOSE
          !byte ( FX_NONE << 2 ) | FX_WAVE_SAWTOOTH
          !hex ed045c748ca4040bfc

FX_BOMB
          !byte ( FX_NONE << 2 ) | FX_WAVE_NOISE
          !hex fd052a4205b20317ca

FX_BONUS_BLIP
          !byte ( FX_SLIDE_PING_PONG << 2 ) | FX_WAVE_TRIANGLE
          !hex e60f375f87af1cf8d7

FX_POWER_UP
          !byte ( FX_SLIDE_PING_PONG << 2 ) | FX_WAVE_SAWTOOTH
          !hex 0a70ba82ea31122c04

FX_JUMP_AT_ENEMY
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_NOISE
          !hex 8017d0075f77fc948f

FX_COMPUTER
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_PULSE
          !hex 076fb79fe7cf037a16

          ;FX lo/hi, Pulse Lo, Pulse Hi, AD, SR, Effect Delta, Effect Delay, Effect Step
FX_BLIP
          !byte ( FX_STEP << 2 ) | FX_WAVE_TRIANGLE
          !hex 1931496159d10104e9

FX_DOOR
          !byte ( FX_NONE << 2 ) | FX_WAVE_NOISE
          !hex 326a42ba92ca040a23

FX_EXPLODE
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_NOISE
          !hex b903c92b2074030c4d

FX_SHOOT
          !byte ( FX_SLIDE_PING_PONG << 2 ) | FX_WAVE_TRIANGLE
          !hex 4b169bf328000d5478

FX_GUN_EMPTY
          !byte ( FX_NONE << 2 ) | FX_WAVE_PULSE
          !hex 60016fd77b420209d3

FX_SEARCH
          !byte ( FX_NONE << 2 ) | FX_WAVE_NOISE
          !hex 44ac94fc270f035b77

FX_CHARGE
          !byte ( FX_SLIDE_PING_PONG << 2 ) | FX_WAVE_TRIANGLE
          !hex e301305880a811b006

FX_HURT
          !byte ( FX_SLIDE << 2 ) | FX_WAVE_NOISE
          !hex bc0dcc271f77fd9baf