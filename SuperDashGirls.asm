  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;;;;;;;;;;;;;;
;VARIABLES ;;;
;;;;;;;;;;;;;;
  .rsset $0000  ; start variables at ram location 0
characterState .rs 1
dashCounter .rs 1
direction .rs 1
dashDirection .rs 1
velY .rs 2
helpReg .rs 1
helpReg2 .rs 1
buttons1   .rs 1
playerXPos .rs 1
playerYPos .rs 1
currentAnimationFrame  .rs 2   ; pointer
currentAnimationPointer .rs 2
animationOffset .rs 1
animationCounter .rs 1
generalPurposeFlags .rs 1
;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;; ; should split this into another file
;CONSTANTS ;;;;
;;;;;;;;;;;;;;;
;;;buttons;;;;;
BUTTON_A         = %10000000
BUTTON_B         = %01000000
BUTTON_SELECT    = %00100000
BUTTON_START     = %00010000
BUTTON_UP        = %00001000
BUTTON_DOWN      = %00000100
BUTTON_LEFT      = %00000010
BUTTON_RIGHT     = %00000001
;;;;;;;;;;;;;;
;;;dash;;;;;;
DD_RIGHT = %00000001
DD_LOWER_RIGHT = %00000101
DD_DOWN = %00000100
DD_LOWER_LEFT = %00000110
DD_LEFT = %00000010
DD_UPPER_LEFT = %00001010
DD_UP = %00001000
DD_UPPER_RIGHT = %00001001
DD_MASK =  %00001111
;;;;;;;;;;;;;;
;;;others;;;;;
FULL_BYTE 		 = $FF
MOVE_SPEED       = $02
GRAVITY			 = $30
JUMP_FORCE       = $03
;;;;;;;;;;;;;;
;;;animations;
ANIM_IDLE		 = $01
ANIM_WALK		 = $02
ANIM_DASH		 = $03
ANIM_JUMP		 = $04
ANIM_LAND		 = $05
;;;;;;;;;;;;;;;
;;;flags;;;;;;;
END_OF_SPRITE_DATA = $FE
;;;;;;;;;;;;;;;
;;;general purpose flags
NMI_FINISHED	 = %00000001
;;;;;;;;;;;;;;;
STATE_GROUNDED = $00
STATE_IN_AIR = $01
STATE_DASH = $02
DIRECTION_RIGHT = $00
DIRECTION_LEFT = $01
;;;;;;;;;;;;;;;;;;;;;;;;
;PROGRAM SPACE;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
  .bank 0
  .org $C000 
  
;;;VBlankWait;;;;;;;;;;;
VBlankwWait:
  BIT $2002
  BPL VBlankwWait
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;Read Controller;;;;;;
ReadController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadControllerLoop:
  LDA $4016
  LSR A           ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;Dash;;;;;;;;;;;;;;;;;
Dash:
  LDA characterState
  CMP #STATE_DASH
  BEQ DashDone
  LDA buttons1
  AND #DD_MASK
  STA dashDirection
  CMP #$00
  BEQ DashDone ; if no direction button is pressed - exit
  LDA #STATE_DASH
  STA characterState
  LDA #$80
  LDX #$01
  STA velY
  STA velY, x
DashDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;MoveXLeft;;;;;;;;;;;;
MoveXLeft:
  LDA characterState
  CMP #STATE_DASH
  BEQ MoveXLeftDone
  LDA playerXPos
  SEC
  SBC #MOVE_SPEED
  STA playerXPos
  LDA #DIRECTION_LEFT
  STA direction
MoveXLeftDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;MoveXRight;;;;;;;;;;;
MoveXRight:
  LDA characterState
  CMP #STATE_DASH
  BEQ MoveXRightDone
  LDA playerXPos
  CLC
  ADC #MOVE_SPEED
  STA playerXPos
  LDA #DIRECTION_RIGHT
  STA direction
MoveXRightDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;

;;;MoveYDown;;;;;;;;;;;;
MoveYDown:
  LDA playerYPos
  CLC
  ADC #MOVE_SPEED
  STA playerYPos
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;MoveYUp;;;;;;;;;;;;;;
MoveYUp:
  LDA playerYPos
  SEC
  SBC #MOVE_SPEED
  STA playerYPos
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;

;;;Jump;;;;;;;;;;;;;;;;
Jump:
  LDA characterState
  CMP #STATE_IN_AIR
  BEQ JumpDone
  LDX #$01
  LDA #$80
  SEC
  SBC #JUMP_FORCE
  STA velY, x
  LDA #$80
  STA velY
  LDA #STATE_IN_AIR
  STA characterState
JumpDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;

;;;LoadCurrentCharacterFrame
LoadCurrentCharacterFrame:
  LDX #$00
  LDY #$01 ; skip first byte of frame data - its frame length
LoadCurrentCharacterFrameLoop:
  LDA [currentAnimationFrame], y
  CMP #END_OF_SPRITE_DATA
  BEQ LoadCurrentCharacterFrameComplete
  CLC
  ADC playerYPos
  STA $0200, x
  INY
  LDA [currentAnimationFrame], y
  STA $0201, x
  INY
  LDA direction
  CMP #DIRECTION_RIGHT
  BEQ directionRight
directionLeft:
  LDA #%01000000
  STA $0202, x
  INY
  LDA playerXPos
  SEC
  SBC [currentAnimationFrame], y
  STA $0203, x
  JMP directionDone
directionRight:
  LDA #%00000000
  STA $0202, x
  INY
  LDA [currentAnimationFrame], y
  CLC
  ADC playerXPos
  STA $0203, x
directionDone:
  INY
  INX
  INX
  INX
  INX           
  JMP LoadCurrentCharacterFrameLoop
LoadCurrentCharacterFrameComplete:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;PushAll;;;;;;;;;;;;;;;;;;;;;
PushAll:
  PHP ; push processor status
  PHA ; push accumulator
  TXA ; tranfer x to accumulator...
  PHA ; ...and push x
  TYA ; transfer y to accumulator
  PHA ; ...and push y
  JMP PushAllDone
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;PullAll;;;;;;;;;;;;;;;;;;;;; PushAll in reverse order
PullAll:
  PLA ; y
  TAY
  PLA ; x
  TAX 
  PLA ; accumulator
  PLP ; status
  JMP PullAllDone
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;UpdateAnimation;;;;;;;;;;;;
UpdateAnimation:
  LDA animationCounter
  CLC
  ADC #$01
  STA animationCounter
  LDY #$00
  CMP [currentAnimationFrame], y ; first byte is a frame length
  BNE UpdateAnimationDone
  
  LDA #$00
  STA animationCounter ; reset animation counter
  
  LDA animationOffset ; increase curren animation frame index
  CLC
  ADC #$02
  CMP #$08 ; TODO this should be a parameter
  BNE SaveAnimationOffset
  LDA #$00 ; reset current frame index
SaveAnimationOffset:
  STA animationOffset
UpdateAnimationDone:

  LDX animationOffset ; update pointer to current animation frame
  LDY #$00
  LDA anim_run, x
  STA currentAnimationFrame, y
  INX
  INY
  LDA anim_run, x
  STA currentAnimationFrame, y

  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;InAirState;;;;;;;;;;;;;;;;;
InAirState:
  LDA velY ; add gravity to velocity
  CLC
  ADC #$20
  STA velY
  LDX #$01
  LDA velY, x
  ADC #$00
  STA velY, x
; Update Y position
  CMP #$80
  BCC SubstractVel ; branch if less or equal
AddVel:
  SEC
  SBC #$80
  CLC
  ADC playerYPos
  STA playerYPos
  JMP UpdateYPosDone
SubstractVel:
  STA helpReg
  LDA #$80
  SEC
  SBC helpReg
  STA helpReg
  LDA playerYPos
  SEC
  SBC helpReg
  STA playerYPos
UpdateYPosDone:
  CMP #$B0
  BCC InAirStateDone; jump i less or equal
  LDA #STATE_GROUNDED
  STA characterState
  LDA #$80
  STA velY
  STA velY, x
InAirStateDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;GroundedState;;;;;;;;;;;;;;
GroundedState:
  LDA playerYPos
  CMP #$B0
  BCC SetInAirState ; jump if less or equal
  JMP GroundedStateDone
SetInAirState:
  LDA #STATE_IN_AIR
  STA characterState
GroundedStateDone:  
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DashState:
  LDA dashCounter
  CLC
  ADC #$01
  CMP #$0A
  STA dashCounter
  BNE ContinueDash
ExitDash:
  LDA #$00
  STA dashCounter
  LDA #STATE_IN_AIR
  STA characterState
  JMP DashComplete
ContinueDash:
  LDA dashDirection
  CMP #DD_RIGHT
  BEQ DashRight
  LDA dashDirection
  CMP #DD_LEFT
  BEQ DashLeft
  JMP ExitDash
DashLeft:
  LDA playerXPos
  SEC
  SBC #$07
  STA playerXPos
  JMP DashComplete
DashRight:
  LDA playerXPos
  CLC
  ADC #$07
  STA playerXPos
DashComplete:
  RTS
;;;DashState;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;UpdateCharacterState;;;;;;;
UpdateCharacterState:
  LDA characterState
  CMP #STATE_IN_AIR
  BEQ GoToInAirState
  LDA characterState
  CMP #STATE_DASH
  BEQ GoToDashState
  JSR GroundedState
  JMP UpdateCharacterStateAllDone
GoToDashState:
  JSR DashState
  JMP UpdateCharacterStateAllDone
GoToInAirState:
  JSR InAirState
UpdateCharacterStateAllDone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;UpdateCharacterPos;;;;;;;;
UpdateCharacterPos:
  LDA buttons1
  AND #BUTTON_LEFT
  BEQ ReadLeftDone
  JSR MoveXLeft
  
ReadLeftDone:
   
  LDA buttons1
  AND #BUTTON_RIGHT
  BEQ ReadRightDone
  JSR MoveXRight
  
ReadRightDone:

  LDA buttons1
  AND #BUTTON_UP
  BEQ ReadUpDone
  JSR Jump
  
ReadUpDone:

  LDA buttons1
  AND #BUTTON_DOWN
  BEQ ReadDownDone
  JSR Jump
  
ReadDownDone:

  LDA buttons1
  AND #BUTTON_A
  BEQ ReadADone
  JSR Dash
  
ReadADone:
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;RESET;;;;;;;;;;;;;;;;;;;;;;; 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

  JSR VBlankwWait
  
clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
  JSR VBlankwWait
  
LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

  
  LDA #$80
  STA playerXPos
  STA playerYPos
  LDX #$01
  STA velY
  STA velY, x
  
  LDA #STATE_IN_AIR
  STA characterState
  
  LDA #$00
  STA animationCounter
  STA animationOffset
  STA helpReg
  
  LDX animationOffset
  LDY #$00
  LDA anim_dash, x
  STA currentAnimationFrame, y
  INX
  INY
  LDA anim_dash, x
  STA currentAnimationFrame, y

  LDA #%11000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

;;;Main Loop;;;;;;;;;;;;;;;
MainLoop:

  JSR ReadController
  JSR UpdateCharacterPos
  JSR UpdateAnimation
  JSR UpdateCharacterState
  
WaitForNMIToFinish:
  LDA generalPurposeFlags
  AND #NMI_FINISHED
  BEQ WaitForNMIToFinish
  
  LDA #NMI_FINISHED ; set NMI_FINISHED flag back to 0
  EOR #FULL_BYTE
  AND generalPurposeFlags
  STA generalPurposeFlags
  
  JMP MainLoop
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;NMI;;;;;;;;;;;;;;;;;;;;;
NMI:

  JMP PushAll
PushAllDone:
  
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer
  
  JSR LoadCurrentCharacterFrame
  
  LDA generalPurposeFlags ; set NMI_FINISHED bit to 1
  ORA #NMI_FINISHED
  STA generalPurposeFlags 

  JMP PullAll
PullAllDone:
  
  
  
  RTI             ; return from interrupt
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;; ; should split this into another file
;DATA SPACE;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
  .bank 1
  .org $E000
  
palette:
  .db $0F,$24,$36,$2C,$0F,$14,$09,$36,$0F,$14,$09,$36,$0F,$14,$09,$36
  .db $0F,$24,$36,$2C,$0F,$14,$09,$36,$0F,$14,$09,$36,$0F,$14,$09,$36

frame_idle_1:
  .db $50 ; frame length (time)
      ;Y   tile attr  X
  .db $10, $32, $00, $00
  .db $00, $00, $00, $00   
  .db $00, $01, $00, $08   
  .db $08, $10, $00, $00   
  .db $08, $11, $00, $08   
  .db $10, $20, $00, $00   
  .db $10, $21, $00, $08
  .db $18, $30, $00, $00
  .db $18, $31, $00, $08
  .db END_OF_SPRITE_DATA
  
frame_idle_2:
  .db $10 ; frame length (time)
      ;Y   tile attr  X
  .db $11, $32, $00, $00
  .db $01, $12, $00, $00   
  .db $01, $02, $00, $08   
  .db $09, $10, $00, $00   
  .db $09, $11, $00, $08   
  .db $11, $20, $00, $00   
  .db $11, $21, $00, $08
  .db $18, $30, $00, $00
  .db $18, $31, $00, $08
  .db END_OF_SPRITE_DATA
  
frame_idle_3:
  .db $18 ; frame length (time)
      ;Y   tile attr  X
  .db $11, $32, $00, $00
  .db $01, $00, $00, $00   
  .db $01, $01, $00, $08   
  .db $09, $10, $00, $00   
  .db $09, $11, $00, $08   
  .db $11, $20, $00, $00   
  .db $11, $21, $00, $08
  .db $18, $30, $00, $00
  .db $18, $31, $00, $08
  .db END_OF_SPRITE_DATA
  
frame_dash_1:
  .db $50 ; frame length (time)
      ;Y   tile attr  X
  .db $15, $32, $00, $09
  .db $06, $00, $00, $08   
  .db $06, $01, $00, $10      
  .db $0B, $16, $00, $01   
  .db $09, $03, $00, $09   
  .db $11, $04, $00, $09   
  .db $0E, $15, $00, $11
  .db $19, $25, $00, $05
  .db $18, $35, $00, $0D
  .db END_OF_SPRITE_DATA
  
frame_dash_2:
  .db $50 ; frame length (time)
      ;Y   tile attr  X
  .db $15, $05, $00, $10
  .db $06, $00, $00, $08   
  .db $06, $01, $00, $10      
  .db $09, $13, $00, $01   
  .db $09, $03, $00, $09   
  .db $11, $04, $00, $09   
  .db $0E, $34, $00, $11
  .db $19, $14, $00, $03
  .db $19, $24, $00, $10
  .db END_OF_SPRITE_DATA
  
frame_dash_3:
  .db $50 ; frame length (time)
      ;Y   tile attr  X
  .db $06, $00, $00, $08   
  .db $06, $01, $00, $10      
  .db $09, $13, $00, $01   
  .db $09, $03, $00, $09   
  .db $11, $04, $00, $09   
  .db $09, $23, $00, $11
  .db $0C, $33, $00, $14
  .db $0C, $22, $00, $1C
  .db $19, $14, $00, $03
  .db $19, $24, $00, $10
  .db END_OF_SPRITE_DATA
  
frame_run_1:
  .db $0F ; frame length (time)
      ;Y   tile attr  X
  .db $0F, $32, $00, $02
  .db $00, $40, $00, $06
  .db $08, $50, $00, $06   
  .db $0F, $60, $00, $06  
  .db $12, $42, $00, $0A 
  .db $10, $52, $00, $00  
  .db $07, $62, $00, $0D
  .db END_OF_SPRITE_DATA
  
frame_run_2:
  .db $08 ; frame length (time)
      ;Y   tile attr  X
  .db $10, $32, $00, $02
  .db $01, $40, $00, $06
  .db $09, $50, $00, $06   
  .db $10, $60, $00, $06  
  .db $13, $41, $00, $07 
  .db $0D, $51, $00, $04  
  .db $15, $61, $00, $04  
  .db END_OF_SPRITE_DATA
  
frame_run_3:
  .db $0F ; frame length (time)
      ;Y   tile attr  X
  .db $0F, $32, $00, $02
  .db $00, $40, $00, $06
  .db $08, $50, $00, $06   
  .db $0F, $60, $00, $06  
  .db $12, $42, $00, $0A 
  .db $10, $52, $00, $00  
  .db $07, $70, $00, $00 
  .db END_OF_SPRITE_DATA
  
anim_dash:
	.dw frame_dash_1
	.dw frame_dash_2
	.dw frame_dash_3
	
anim_idle:
	.dw frame_idle_1
	.dw frame_idle_2
	.dw frame_idle_3
	
anim_run:
	.dw frame_run_1
	.dw frame_run_2
	.dw frame_run_3
	.dw frame_run_2


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI                     
  .dw RESET               
  .dw 0
  
;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .bank 2
  .org $0000
  .incbin "game.chr"