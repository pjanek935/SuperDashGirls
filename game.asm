  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;;;;;;;;;;;;;;
;; VARIABLES ;;
  .rsset $0000  ;start variables at ram location 0
buttons1   .rs 1
playerXPos .rs 1
playerYPos .rs 1
playerSprite .rs 1
animationCounter .rs 1
;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;
;; CONSTANTS ;;
BUTTON_A         = %10000000
BUTTON_B         = %01000000
BUTTON_SELECT    = %00100000
BUTTON_START     = %00010000
BUTTON_UP        = %00001000
BUTTON_DOWN      = %00000100
BUTTON_LEFT      = %00000010
BUTTON_RIGHT     = %00000001

MOVE_SPEED       = $02
;;;;;;;;;;;;;;;
    
  .bank 0
  .org $C000 
  
VBlankwWait:
  BIT $2002
  BPL VBlankwWait
  RTS

;; Read Controller ;;
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
;;;;;;;;;;;;;;;

;; MoveXLeft ;;
MoveXLeft:
	LDX #$00
	LDA playerXPos
	SEC
	SBC #MOVE_SPEED
	STA playerXPos
	RTS
;;;;;;;;;;;;;;;

;; MoveXRight ;;
MoveXRight:
  LDX #$00
  LDA playerXPos
  CLC
  ADC #MOVE_SPEED
  STA playerXPos
  RTS
;;;;;;;;;;;;;;;

;; MoveYDown ;;
MoveYDown:
  LDX #$00
  LDA playerYPos
  CLC
  ADC #MOVE_SPEED
  STA playerYPos
  RTS
;;;;;;;;;;;;;;;

;; MoveYUp ;;
MoveYUp:
  LDX #$00
  LDA playerYPos
  SEC
  SBC #MOVE_SPEED
  STA playerYPos
  RTS
;;;;;;;;;;;;;;;

LoadSprites:
  LDX #$00
  LDY #$00
LoadSpritesLoop:
  LDA sprites, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA sprites, x
  STA $0201, y
  
  INX
  LDA sprites, x
  STA $0202, y
  
  INX
  LDA sprites, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$24         
  BNE LoadSpritesLoop
  
  RTS
  
LoadSprites2:
  LDX #$00
  LDY #$00
LoadSpritesLoop2:
  LDA sprites2, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA sprites2, x
  STA $0201, y
  
  INX
  LDA sprites2, x
  STA $0202, y
  
  INX
  LDA sprites2, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$24           
  BNE LoadSpritesLoop2
  
  RTS
  
LoadSprites3:
  LDX #$00
  LDY #$00
LoadSpritesLoop3:
  LDA sprites3, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA sprites3, x
  STA $0201, y
  
  INX
  LDA sprites3, x
  STA $0202, y
  
  INX
  LDA sprites3, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$24              
  BNE LoadSpritesLoop3
  
  RTS
  
LoadDash2:
  LDX #$00
  LDY #$00
LoadDashLoop2:
  LDA dash2, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA dash2, x
  STA $0201, y
  
  INX
  LDA dash2, x
  STA $0202, y
  
  INX
  LDA dash2, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$24              
  BNE LoadDashLoop2
  
  RTS
  
LoadDash3:
  LDX #$00
  LDY #$00
LoadDashLoop3:
  LDA dash3, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA dash3, x
  STA $0201, y
  
  INX
  LDA dash3, x
  STA $0202, y
  
  INX
  LDA dash3, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$24              
  BNE LoadDashLoop3
  
  RTS
  
LoadDash1:
  LDX #$00
  LDY #$00
LoadDashLoop1:
  LDA dash, x
  CLC
  ADC playerYPos
  STA $0200, y
  
  INX
  LDA dash, x
  STA $0201, y
  
  INX
  LDA dash, x
  STA $0202, y
  
  INX
  LDA dash, x 
  CLC
  ADC playerXPos
  STA $0203, y
  
  INX
  INY
  INY
  INY
  INY
  
  CPX #$28             
  BNE LoadDashLoop1
  
  RTS
  

  
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

  JSR LoadSprites
  ;JSR RenderDash

  LDA #%11000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001
  
  

Forever:
  JMP Forever
  
 

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer
  
  ;JSR LoadDash1
  ;JMP renderComplete
  
  LDA playerSprite
  CMP #$01
  BEQ renderSprites2
  CMP #$02
  BEQ renderSprites3
  
  JSR LoadSprites
  JMP renderComplete

renderSprites2:
  JSR LoadSprites2
  JMP renderComplete
  
renderSprites3:
  JSR LoadSprites3
  JMP renderComplete
 
  
renderComplete
  JSR ReadController
  
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
  JSR MoveYUp
  
ReadUpDone:

  LDA buttons1
  AND #BUTTON_DOWN
  BEQ ReadDownDone
  JSR MoveYDown
  
ReadDownDone:

  LDA animationCounter
  CLC
  ADC #$20
  STA animationCounter
  
  CMP #$00
  BEQ changesprite
  JMP complete
  
changesprite:
  LDA playerSprite
  CLC
  ADC #$01
  STA playerSprite
  
complete:

  LDA playerSprite
  CLC
  CMP #$08
  BNE done
  LDA #$00
  STA playerSprite
  
done:
  
  RTI             ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $0F,$24,$36,$2C,$0F,$14,$09,$36,$0F,$14,$09,$36,$0F,$14,$09,$36
  .db $0F,$24,$36,$2C,$0F,$14,$09,$36,$0F,$14,$09,$36,$0F,$14,$09,$36

sprites:
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
  
  
sprites2:
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
  
  
sprites3:
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
  
dash:
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
  
dash3:
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
  
dash2:
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
  

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI                     
  .dw RESET               
  .dw 0
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "game.chr"