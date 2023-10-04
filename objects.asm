SPRITE_CENTER_OFFSET_X  = 8
SPRITE_CENTER_OFFSET_Y  = 11

TYPE_PLAYER                   = 1
TYPE_PLAYER_BOTTOM            = 2
TYPE_METEOR                   = 3
TYPE_EXPLODING_METEOR         = 4

SPRITE_POINTER_BASE           = SCREEN_CHAR + 1016

SPRITE_BASE                   = ( SPRITE_LOCATION % 16384 ) / 64

SPRITE_PLAYER_TOP_1           = SPRITE_BASE + 0
SPRITE_PLAYER_BOT_1           = SPRITE_BASE + 4

SPRITE_PLAYER_SHOOT_TOP_1     = SPRITE_BASE + 20
SPRITE_PLAYER_SHOOT_BOT_1     = SPRITE_BASE + 21

SPRITE_METEOR                 = SPRITE_BASE + 8
SPRITE_EXPLODING_METEOR       = SPRITE_BASE + 12

SPRITE_PLAYER_DEAD_TOP        = SPRITE_BASE + 22

JOY_UP                  = $01
JOY_DOWN                = $02
JOY_LEFT                = $04
JOY_RIGHT               = $08
JOY_FIRE                = $10




!lzone ObjectControl
          ldx #0
          stx CURRENT_INDEX

.ObjectLoop
          ldy SPRITE_ACTIVE,x
          beq .NextObject

          lda SPRITE_HITBACK,x
          beq +
          dec SPRITE_HITBACK,x
          bne +

          lda SPRITE_HITBACK_ORIG_COLOR,x
          sta VIC.SPRITE_COLOR,x

+

          ;enemy is active
          lda SPRITE_BEHAVIOUR_LO,x
          sta .JumpPointer + 1
          lda SPRITE_BEHAVIOUR_HI,x
          sta .JumpPointer + 2

.JumpPointer
          jsr $8000

.NextObject
          inc CURRENT_INDEX
          ldx CURRENT_INDEX
          cpx #8
          bne .ObjectLoop
          rts


;------------------------------------------------------------
;Move Sprite Left
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!lzone MoveSpriteLeft
          dec SPRITE_POS_X,x
          bpl .NoChangeInExtendedFlag

          lda BIT_TABLE,x
          eor #$ff
          and SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoChangeInExtendedFlag
          txa
          asl
          tay

          lda SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Right
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!lzone MoveSpriteRight
          inc SPRITE_POS_X,x
          lda SPRITE_POS_X,x
          bne .NoChangeInExtendedFlag

          lda BIT_TABLE,x
          ora SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoChangeInExtendedFlag
          txa
          asl
          tay

          lda SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Up
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!zone MoveSpriteUp
MoveSpriteUp
          dec SPRITE_POS_Y,x

          txa
          asl
          tay

          lda SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Down
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!zone MoveSpriteDown
MoveSpriteDown
          inc SPRITE_POS_Y,x

          txa
          asl
          tay

          lda SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y
          rts




;------------------------------------------------------------
;CalcSpritePosFromCharPos
;calculates the real sprite coordinates from screen char pos
;and sets them directly
;PARAM1 = char_pos_x
;PARAM2 = char_pos_y
;X      = sprite index
;------------------------------------------------------------
!zone CalcSpritePosFromCharPos
CalcSpritePosFromCharPos

          ;offset screen to border 24,50
          lda BIT_TABLE,x
          eor #$ff
          and SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

          ;need extended x bit?
          lda PARAM1
          sta SPRITE_CHAR_POS_X,x
          cmp #30
          bcc .NoXBit

          lda BIT_TABLE,x
          ora SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoXBit
          ;calculate sprite positions (offset from border)
          txa
          asl
          tay

          ;X = charX * 8 + ( 24 - SPRITE_CENTER_OFFSET_X=8 )
          lda PARAM1
          asl
          asl
          asl
          clc
          adc #( 24 - SPRITE_CENTER_OFFSET_X )
          sta SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y

          ;Y = charY * 8 + ( 50 - SPRITE_CENTER_OFFSET_Y=11 )
          lda PARAM2
          sta SPRITE_CHAR_POS_Y,x
          asl
          asl
          asl
          clc
          adc #( 50 - SPRITE_CENTER_OFFSET_Y )
          sta SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y

          lda #0
          sta SPRITE_CHAR_POS_X_DELTA,x
          sta SPRITE_CHAR_POS_Y_DELTA,x
          rts



;adds object
;PARAM1 = X
;PARAM2 = Y
;PARAM3 = TYPE
;returns a = 0 if no free slot found
!zone AddObject
AddObject
          ldx #0
;adds object
;PARAM1 = X
;PARAM2 = Y
;PARAM3 = TYPE
;returns a = 0 if no free slot found
AddObjectStartingWithSlot
          jsr FindEmptySpriteSlot
          bne +
          lda #0
          tax
          rts
+
          ;PARAM1 and PARAM2 hold x,y already
AddObjectInSlotX
          jsr CalcSpritePosFromCharPos

;requires PARAM3 = type, x/y already initialised
CreateObjectInSlot
          lda PARAM3
          sta SPRITE_ACTIVE,x

          ;enable sprite
          lda BIT_TABLE,x
          ora VIC.SPRITE_ENABLE
          sta VIC.SPRITE_ENABLE

          ;sprite color

          ;disable mc flag
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_MULTICOLOR
          sta VIC.SPRITE_MULTICOLOR

          ldy PARAM3

          ;initialise enemy values
          lda TYPE_START_SPRITE,y
          sta SPRITE_IMAGE,x
          sta SPRITE_BASE_IMAGE,x
          sta SPRITE_POINTER_BASE,x
          lda TYPE_START_HEIGHT_CHARS,y
          sta SPRITE_HEIGHT_CHARS,x
          lda TYPE_START_SPRITE_HP,y
          sta SPRITE_HP,x
          lda TYPE_START_BEHAVIOR_LO,y
          sta SPRITE_BEHAVIOUR_LO,x
          lda TYPE_START_BEHAVIOR_HI,y
          sta SPRITE_BEHAVIOUR_HI,x

          lda #1
          sta SPRITE_WIDTH_CHARS,x
          lda TYPE_START_COLOR,y
          sta VIC.SPRITE_COLOR,x
          bpl +
          ;set MC flag
          lda BIT_TABLE,x
          ora VIC.SPRITE_MULTICOLOR
          sta VIC.SPRITE_MULTICOLOR

+
          txa
          sta SPRITE_MAIN_INDEX,x

          lda #0
          ;look right per default
          sta SPRITE_DIRECTION,x
          sta SPRITE_DIRECTION_Y,x
          sta SPRITE_ANIM_POS,x
          sta SPRITE_ANIM_DELAY,x
          sta SPRITE_MOVE_POS,x
          sta SPRITE_MOVE_POS_Y,x
          sta SPRITE_MOVE_DX_LO,x
          sta SPRITE_MOVE_DX_HI,x
          sta SPRITE_MOVE_DY_LO,x
          sta SPRITE_MOVE_DY_HI,x
          sta SPRITE_FIRE_DELAY,x
          sta SPRITE_STATE,x
          sta SPRITE_STATE_POS,x
          sta SPRITE_HOMING_DELAY,x
          sta SPRITE_LIFETIME,x
          sta SPRITE_SHOT_HIT_COUNT,x
          lda #1
          sta SPRITE_NUM_PARTS,x

          lda TYPE_START_SPRITE_OFFSET_X,y
          sta PARAM4

          lda TYPE_START_SPRITE_FLAGS,y
          and #SF_START_INVINCIBLE
          beq +
          lda #$80
          sta SPRITE_STATE,x

+
          lda PARAM4
.AdjustX
          beq .NoXMovementNeeded
          jsr MoveSpriteRight
          dec PARAM4
          jmp .AdjustX

.NoXMovementNeeded
          ldy SPRITE_ACTIVE,x
          lda TYPE_START_SPRITE_OFFSET_Y,y
          sta PARAM4

          jsr MoveSpriteDown
          lda PARAM4
.AdjustY
          beq AddObject.NoYMovementNeeded

          ;lda SPRITE_POS_Y,x
          ;sec
          ;sbc PARAM4
          ;sta SPRITE_POS_Y,x
          ;txa
          ;asl
          ;tay
          ;sta VIC.SPRITE_Y_POS,y
          ;ldy SPRITE_ACTIVE,x

          jsr MoveSpriteUp
          dec PARAM4
          jmp .AdjustY

.NoYMovementNeeded
          lda #1
          rts



!zone FindEmptySpriteSlot
;Looks for an empty sprite slot, returns in X. Starts with Index X
;#1 in A when empty slot found, #0 when full
FindEmptySpriteSlot
.CheckSlot
          lda SPRITE_ACTIVE,x
          beq .FoundSlot

          inx
          cpx #8
          bne .CheckSlot

          lda #0
          rts

.FoundSlot
          lda #1
          rts


;Removed object from array
;X = index of object
!lzone RemoveObject
          ;remove from array
          lda #0
          sta SPRITE_ACTIVE,x

          ;disable sprite
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_ENABLE
          sta VIC.SPRITE_ENABLE

          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_X
          sta VIC.SPRITE_EXPAND_X

          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_Y
          sta VIC.SPRITE_EXPAND_Y

          rts



!lzone BHNone
          rts



!lzone BHPlayerExit
          lda SPRITE_STATE
          cmp #1
          beq .GoL
          cmp #2
          beq .GoR

          lda SPRITE_CHAR_POS_X
          cmp #19
          bcs .GoR

          lda #1
          sta SPRITE_STATE

.GoL
          jsr PlayerWalkLeft

          lda SPRITE_POS_X
          beq .Done
          rts

.GoR
          lda #2
          sta SPRITE_STATE
          jsr PlayerWalkRight
          lda SPRITE_POS_X
          cmp #120
          beq .Done
          rts


.Done
          pla
          pla
          pla
          pla
          jmp StartRound



!lzone PlayerWalkLeft
          jsr ObjectMoveLeft
          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$03
          bne +
          dec SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          and #$03
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
          clc
          adc #4
          sta SPRITE_IMAGE + 1,x

+
          rts



!lzone PlayerWalkRight
          jsr ObjectMoveRight

          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$03
          bne +
          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          and #$03
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
          clc
          adc #4
          sta SPRITE_IMAGE + 1,x
+
          rts




!lzone BHPlayerDead
          lda SPRITE_ANIM_POS,x
          cmp #3
          bne +

          lda JOY_VALUE
          and #JOY_FIRE
          bne +

          ;fire pressed, restart!
          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED

          pla
          pla
          pla
          pla
          jmp StartGame

+

          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$03
          bne +

          lda SPRITE_ANIM_POS,x
          cmp #3
          beq +

          clc
          adc #SPRITE_PLAYER_DEAD_TOP
          sta SPRITE_IMAGE,x
          clc
          adc #3
          sta SPRITE_IMAGE + 1,x

          inc SPRITE_ANIM_POS,x
+


          rts


!lzone BHPlayer
          lda HULL_STRENGTH
          beq .PlayerKilled

          ;check for collision
          lda #1
          sta CURRENT_SUB_INDEX

-
          ldy CURRENT_SUB_INDEX
          lda SPRITE_ACTIVE,y
          tay
          lda IS_TYPE_ENEMY,y
          cmp #1
          beq +
          jmp .Skip
+
          jsr IsEnemyCollidingWithObject
          bne +
          jmp .Skip
+

.PlayerKilled
          ;colliding!
          lda #1
          sta PLAYER_DEAD

          ldy #SFX_HURT
          jsr PlaySoundEffect

          ldx #0
--
          lda PANEL_TEXT_PLAY,x
          sta PANEL_POS_TEXT,x
          inx
          cpx #16
          bne --

          ldx #0
          lda #<BHPlayerDead
          ldy #>BHPlayerDead
          jmp SetBehaviour


.Skip
          inc CURRENT_SUB_INDEX
          lda CURRENT_SUB_INDEX
          cmp #8
          beq .SkipDone
          jmp -

.SkipDone
          ldx CURRENT_INDEX

          lda JOY_VALUE
          and #JOY_FIRE
          bne .NotFire

          ;released?
          lda JOY_VALUE_RELEASED
          and #JOY_FIRE
          beq .NotReleased

          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED

          lda REPULSE_COUNT
          bne +
          beq .NoAmmo
+
          lda PLAYER_FIRE_POSE
          bne .NoNewPose

          dec REPULSE_COUNT
          ldy REPULSE_COUNT
          lda #CHAR_ENERGY_EMPTY
          sta PANEL_POS_REPULSE,y

          lda #1
          sta PLAYER_FIRE_POSE
          lda #SPRITE_PLAYER_SHOOT_TOP_1
          sta SPRITE_IMAGE,x
          lda #SPRITE_PLAYER_SHOOT_BOT_1
          sta SPRITE_IMAGE + 1,x

          ldy #SFX_BONUS_BLIP
          jsr PlaySoundEffect

          ;check for meteors
          ldx #0
          jsr IsEnemyCollidingWithObject.CalculateSimpleXPos
          sta PARAM1

          ldx #1
-
          stx CURRENT_SUB_INDEX
          lda SPRITE_ACTIVE,x
          cmp #TYPE_METEOR
          bne +

          ;player in front of it?
          jsr IsEnemyCollidingWithObject.CalculateSimpleXPos

          sec
          sbc #8    ;was 4
          ;position X-Anfang Player - 12 Pixel
          cmp PARAM1
          bcs .NotTouching
          adc #16   ;was 8
          cmp PARAM1
          bcc .NotTouching

          ;repulse
          lda SPRITE_STATE,x
          cmp #2
          beq +

          lda #2
          sta SPRITE_STATE,x

          lda #1
          ldy #4
          jsr IncScore

          stx PARAM11

          ldy #SFX_PICK_PLUS
          jsr PlaySoundEffect

          ldx PARAM11

.NotTouching
+
          inx
          cpx #8
          bne -

.NoNewPose
.NotReleased
          rts

.NotFire
.NoAmmo
          lda PLAYER_FIRE_POSE
          beq +
          lda #SPRITE_PLAYER_TOP_1
          sta SPRITE_IMAGE,x
          lda #SPRITE_PLAYER_BOT_1
          sta SPRITE_IMAGE + 1,x
          lda #0
          sta PLAYER_FIRE_POSE
+

          lda JOY_VALUE
          and #JOY_LEFT
          bne .NotLeft

          lda SPRITE_CHAR_POS_X
          cmp #1
          beq .CheckExit

          jsr PlayerWalkLeft
.NotActive
          rts

.CheckExit
          lda PLAYER_EXIT_ACTIVE
          beq .NotActive

          ldx #0
          lda #<BHPlayerExit
          ldy #>BHPlayerExit
          jmp SetBehaviour

.NotLeft
          lda JOY_VALUE
          and #JOY_RIGHT
          bne .NotRight

          lda SPRITE_CHAR_POS_X
          cmp #37
          beq .CheckExit

          jsr PlayerWalkRight

.NotRight
          rts




;move object left
;x = object index
!lzone ObjectMoveLeft
          lda SPRITE_NUM_PARTS,x
          sta PARAM11

-
          lda SPRITE_CHAR_POS_X_DELTA,x
          bne .NoCharStep

          lda #8
          sta SPRITE_CHAR_POS_X_DELTA,x
          dec SPRITE_CHAR_POS_X,x

.NoCharStep
          dec SPRITE_CHAR_POS_X_DELTA,x

          jsr MoveSpriteLeft

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;move object right
;x = object index
!lzone ObjectMoveRight
          lda SPRITE_NUM_PARTS,x
          sta PARAM11

-
          inc SPRITE_CHAR_POS_X_DELTA,x

          lda SPRITE_CHAR_POS_X_DELTA,x
          cmp #8
          bne .NoCharStep

          lda #0
          sta SPRITE_CHAR_POS_X_DELTA,x
          inc SPRITE_CHAR_POS_X,x

.NoCharStep
          jsr MoveSpriteRight
          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;a = DX
!lzone ObjectMoveDX
          beq .NoMove

          sta PARAM2

          bmi +
-
          jsr ObjectMoveRight
          dec PARAM2
          bne -
          rts

+
-
          jsr ObjectMoveLeft
          inc PARAM2
          bne -




.NoMove
          rts


;move object up
;x = object index
!lzone ObjectMoveUp
          lda SPRITE_NUM_PARTS,x
          sta PARAM11
-
          dec SPRITE_CHAR_POS_Y_DELTA,x

          lda SPRITE_CHAR_POS_Y_DELTA,x
          cmp #$ff
          bne .NoCharStep

          dec SPRITE_CHAR_POS_Y,x
          lda #7
          sta SPRITE_CHAR_POS_Y_DELTA,x

.NoCharStep
          jsr MoveSpriteUp

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;move object down
;x = object index
;------------------------------------------------------------
!lzone ObjectMoveDown
          lda SPRITE_NUM_PARTS,x
          sta PARAM11
-
          inc SPRITE_CHAR_POS_Y_DELTA,x

          lda SPRITE_CHAR_POS_Y_DELTA,x
          cmp #8
          bne .NoCharStep

          lda #0
          sta SPRITE_CHAR_POS_Y_DELTA,x
          inc SPRITE_CHAR_POS_Y,x

.NoCharStep
          jsr MoveSpriteDown

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



!lzone BHExplodingMeteor
          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$01
          beq +

          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          cmp #4
          beq .Done

          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
          rts



.Done
          jmp RemoveObject

+
          rts



;state 0 = init
;      1 = fall
;      2 = repulsed
!lzone BHMeteor
          lda SPRITE_STATE,x
          cmp #2
          bne +

          ;repulsed
          jsr ObjectMoveUp
          jsr ObjectMoveUp
          lda SPRITE_POS_Y,x
          cmp #5
          bcs +

          dec METEORS_ALIVE
          jmp RemoveObject


+
          lda SPRITE_STATE,x
          bne .HorzDeltaCalced

          lda #0
          sta PARAM5
          lda #4
          sta PARAM6
          jsr GenerateRangedRandom
          sec
          sbc #2
          sta SPRITE_MOVE_DX_LO,x
          inc SPRITE_STATE,x

.HorzDeltaCalced
          ;base speed
          lda SPRITE_SPEED,x
          lsr
          lsr
          lsr
          sta PARAM1


          ;* 8 offset in speed table
          lda SPRITE_SPEED,x
          and #$7
          asl
          asl
          asl
          clc
          adc SPEED_TABLE_POS
          tay
          lda SPEED_TABLE,y
          clc
          adc PARAM1
          sta PARAM10
          beq .NoMovement

--

          jsr ObjectMoveDown

          ;delta X
          inc SPRITE_MOVE_DX_HI,x
          lda SPRITE_MOVE_DX_HI,x
          and #$07
          bne +

          lda SPRITE_MOVE_DX_LO,x
          jsr ObjectMoveDX

          lda SPRITE_CHAR_POS_X,x
          beq .ExplodeNoHullDamage
          cmp #38
          beq .ExplodeNoHullDamage

+
          dec PARAM10
          bne --


          lda SPRITE_CHAR_POS_Y,x
          cmp #19
          bne +

          lda PLAYER_DEAD
          bne .SkipHullDamages

          lda HULL_STRENGTH
          beq .SkipDecHull

          dec HULL_STRENGTH
          ldy HULL_STRENGTH
          lda #CHAR_ENERGY_EMPTY
          sta PANEL_POS_HULL,y

.SkipHullDamages
.SkipDecHull
.ExplodeNoHullDamage
          dec METEORS_ALIVE

          lda #TYPE_EXPLODING_METEOR
          sta PARAM3
          jsr CreateObjectInSlot

          ldy #SFX_EXPLODE
          jmp PlaySoundEffect

+

          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$03
          bne +

          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          and #$03
          clc
          adc #SPRITE_METEOR
          sta SPRITE_IMAGE,x
+
.NoMovement
          rts


!zone IsEnemyCollidingWithObject


.CalculateSimpleXPos
          ;Returns a with simple x pos (x halved + 128 if > 256)
          ;modifies y
          lda BIT_TABLE,x
          and SPRITE_POS_X_EXTEND
          beq .NoXBit

          lda SPRITE_POS_X,x
          lsr
          clc
          adc #128
          rts

.NoXBit
          lda SPRITE_POS_X,x
          lsr
          rts


;modifies X
;check y pos
;check object collision with other object (object CURRENT_INDEX vs CURRENT_SUB_INDEX)
;return a = 1 when colliding, a = 0 when not
;------------------------------------------------------------
;temp PARAM8 holds height to check in pixels
IsEnemyCollidingWithObject
          ldx CURRENT_SUB_INDEX
          ldy CURRENT_INDEX
          lda SPRITE_HEIGHT_CHARS,y
          asl
          asl
          asl
          sta PARAM8
          lda SPRITE_POS_Y,y
          sta PARAM2

          lda SPRITE_POS_Y,x
          sec
          sbc PARAM8         ;offset to bottom
          cmp PARAM2
          bcs .NotTouching

          ;sprite x is above sprite y
          clc
          adc PARAM8
          sta PARAM1

          lda SPRITE_HEIGHT_CHARS,x
          asl
          asl
          asl
          clc
          adc PARAM1
          cmp PARAM2
          bcc .NotTouching

          ;X = Index in enemy-table
          jsr .CalculateSimpleXPos
          sta PARAM1
          ldx CURRENT_INDEX
          jsr .CalculateSimpleXPos

          sec
          sbc #8    ;was 4
          ;position X-Anfang Player - 12 Pixel
          cmp PARAM1
          bcs .NotTouching
          adc #16   ;was 8
          cmp PARAM1
          bcc .NotTouching


          lda #1
          ;sta VIC.BORDER_COLOR
          rts

.NotTouching
          lda #0
          ;sta VIC.BORDER_COLOR
          rts



;a = lo, y = hi behaviour
!lzone SetBehaviour
          sta SPRITE_BEHAVIOUR_LO,x
          tya
          sta SPRITE_BEHAVIOUR_HI,x

          lda #0
          sta SPRITE_STATE,x
          sta SPRITE_ANIM_POS,x
          sta SPRITE_ANIM_DELAY,x
          rts


;0 = normal, 1 = enemy, 2 = pickup, 3 = special behaviour (sphere), 4 = boss, 5 = check collision (player and player shot), 6 = enemy shot
;            7 = respawnable enemy
IS_TYPE_ENEMY = * - 1
          !byte 5     ;player bottom
          !byte 5     ;player top
          !byte 1     ;meteor
          !byte 0     ;exploding meteor

TYPE_START_SPRITE_OFFSET_X = * - 1
          !byte 0     ;player bottom
          !byte 0     ;player top
          !byte 0     ;meteor
          !byte 0     ;exploding meteor

TYPE_START_SPRITE_OFFSET_Y = * - 1
          !byte 0     ;player bottom
          !byte 3     ;player top
          !byte 0     ;meteor
          !byte 0     ;exploding meteor

TYPE_START_HEIGHT_CHARS = * - 1
          !byte 5     ;player bottom        ;human can jump into walls
          !byte 4     ;player top
          !byte 2     ;meteor
          !byte 2     ;exploding meteor

TYPE_START_SPRITE = * - 1
          !byte SPRITE_PLAYER_TOP_1
          !byte SPRITE_PLAYER_BOT_1
          !byte SPRITE_METEOR
          !byte SPRITE_EXPLODING_METEOR

TYPE_START_COLOR = * - 1
          !byte $80   ;player bottom
          !byte $80   ;player top
          !byte $8f   ;meteor
          !byte $8f   ;exploding meteor

SF_DOUBLE_V             = $01     ;two sprites on top of each other
SF_DOUBLE_H             = $02     ;two sprites beside each other
SF_START_INVINCIBLE     = $04   ;sprite starts out invincible (enemy shots) = SPRITE_STATE is set to $80
SF_EXPAND_X             = $08
SF_EXPAND_Y             = $10
SF_HIDDEN_WITHOUT_GUN   = $20   ;object is not spawned if player has no gun
;SF_DOUBLE_V, SF_DOUBLE_H, SF_START_INVINCIBLE, SF_EXPAND_X, SF_EXPAND_Y, SF_HIDDEN_WITHOUT_GUN
TYPE_START_SPRITE_FLAGS = * - 1
          !byte SF_DOUBLE_V     ;player bottom
          !byte 0     ;player top
          !byte 0     ;meteor
          !byte 0     ;exploding meteor

TYPE_START_SPRITE_HP = * - 1
          !byte 6     ;player bottom
          !byte 6     ;player top
          !byte 1     ;meteor
          !byte 0     ;exploding meteor

TYPE_START_BEHAVIOR_LO = * - 1
          !byte <BHPlayer
          !byte <BHNone
          !byte <BHMeteor
          !byte <BHExplodingMeteor

TYPE_START_BEHAVIOR_HI = * - 1
          !byte >BHPlayer
          !byte >BHNone
          !byte >BHMeteor
          !byte >BHExplodingMeteor

SPRITE_POS_X_EXTEND
          !byte 0

;all these sprite thingies require 8 bytes for copy to work!
SPRITE_POS_X
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_X
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_X_DELTA
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_Y_DELTA
          !byte 0,0,0,0,0,0,0,0
SPRITE_POS_Y
          !byte 0,0,0,0,0,0,0,0

;0 = empty/TYPE_NONE
SPRITE_ACTIVE
          !byte 0,0,0,0,0,0,0,0
;0 = right, 1 = left
SPRITE_DIRECTION
          !byte 0,0,0,0,0,0,0,0
SPRITE_DIRECTION_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_FALLING
          !byte 0,0,0,0,0,0,0,0
SPRITE_ANIM_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_ANIM_DELAY
          !byte 0,0,0,0,0,0,0,0
SPRITE_MOVE_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_MOVE_POS_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_BORDER_1
          !byte 0,0,0,0,0,0,0,0
SPRITE_BASE_IMAGE
          !byte 0,0,0,0,0,0,0,0
SPRITE_STATE
          !byte 0,0,0,0,0,0,0,0
SPRITE_STATE_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_HOMING_DELAY
          !byte 0,0,0,0,0,0,0,0
SPRITE_FIRE_DELAY
          !byte 0,0,0,0,0,0,0,0
SPRITE_WIDTH_CHARS
          !byte 0,0,0,0,0,0,0,0
SPRITE_HEIGHT_CHARS
          !byte 0,0,0,0,0,0,0,0
SPRITE_MAIN_INDEX
          !byte 0,0,0,0,0,0,0,0
SPRITE_NUM_PARTS
          !byte 0,0,0,0,0,0,0,0
SPRITE_IMAGE
          !byte 0,0,0,0,0,0,0,0
SPRITE_HP
          !byte 0,0,0,0,0,0,0,0
SPRITE_HITBACK
          !byte 0,0,0,0,0,0,0,0
SPRITE_HITBACK_ORIG_COLOR
          !byte 0,0,0,0,0,0,0,0
;how many times has a shot hit this enemy
SPRITE_SHOT_HIT_COUNT
          !fill 8
SPRITE_LIFETIME
          !fill 8

SPRITE_SPEED
          !fill 8

SPRITE_BEHAVIOUR_LO
          !fill 8
SPRITE_BEHAVIOUR_HI
          !fill 8


;bresenham members
SPRITE_MOVE_DX_LO
          !fill 8
SPRITE_MOVE_DX_HI
          !fill 8
SPRITE_MOVE_DY_LO
          !fill 8
SPRITE_MOVE_DY_HI
          !fill 8
;$ff = left, 0 = stay, 1 = right
SPRITE_STEP_X
          !fill 8
;$ff = up, 0 = stay, 1 = down
SPRITE_STEP_Y
          !fill 8
SPRITE_FRACTION_LO
          !fill 8
SPRITE_FRACTION_HI
          !fill 8

MOVE_TARGET_X_LO
          !fill 8
MOVE_TARGET_X_HI
          !fill 8
MOVE_TARGET_Y
LAST_SPRITE_ARRAY
          !fill 8

PLAYER_FIRE_POSE
          !byte 0

REPULSE_COUNT
          !byte 0

REPULSE_RELOAD_DELAY
          !byte 0

BIT_TABLE
          !byte 1,2,4,8,16,32,64,128

SPEED_TABLE
          !byte 0,0,0,0,0,0,0,0
          !byte 0,0,0,0,0,0,0,1
          !byte 0,0,0,1,0,0,0,1
          !byte 0,1,0,0,1,0,0,1
          !byte 1,0,1,0,1,0,1,0
          !byte 1,1,0,1,1,0,1,0
          !byte 1,1,1,0,1,1,1,0
          !byte 1,1,1,1,1,1,1,0
          !byte 1,1,1,1,1,1,1,1

SPEED_TABLE_POS
          !byte 0