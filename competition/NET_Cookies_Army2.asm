; /  survivor 2  / ;
; / unchangeable / ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |                                  notes                                     |

; 1. The code in this file is adapted to the Codeguru Xtreme 18 competition.

; 2. All nop codes in this code are part of Codeguru Xtreme 18 rules.
;    Which states that for any N bytes, the 'nop' opcode should appear.
;    Where N is different for each state in the competition.

; 3. Not all settings are used in the code itself.
;    That is because this code is built to be dynamic,
;    and therefore needs to adapt to different types of gameplay

; 4. At the beginning and the end of the code there is a comment like this:
;    `CODE * 2 + protection` - in thoes areas goes our decoys & protection
;    this is neccessary for blocking any `int 0x87` attacks.
;    We used the byte 0xCC six times together with copies of the code in order
;    to protect our code.
;    Please note that there are other ways of protecting the code from `int 0x87`
;    and this is just how we decided to implement the protection.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |                                  defines                                  |

; | Controlled Defines |
%define _jmp_size 0x5100 ; how far away to run after attack
%define _attack_size 0x600 ; how much space to attack
%define _first_attack_amount 0x8000 ; the upper attack amount
%define _honeypot_padding 0x50

; | Spacial Memory Locations |
; sm - shared memory
; st - stack
%define sm_call_far_location 0xB0

; | Spacial Bytes |
%define attackLowerByteLocation 0xA2
%define attackSegment 0x0FFB ; the original segment is 0x1000
%define movswOpcode 0xA5
%define segmentSpace ((ORIGINAL_SEGMENT - attackSegment) * 0x10)
%define finalAX (jmpSize + movswOpcode)


; | Specific Sizes |
; for the attack
%define gapSize (_jmp_size - _attack_size + 0x2)
%define jmpSize (_jmp_size)
%define jmpSizeMSB (jmpSize / 0x100)
%define firstAttackAmount _first_attack_amount ; the amount of lines to attack in the first attack - MSB*2 for calculate the steps amount
%define firstAttackSpace (MIN_DISTANCE - 0x1000 - 1)
%define honeypotBeforePadding (-_honeypot_padding-_honeypot_padding)
%define honeypotAfterPadding (_honeypot_padding)


; sizes of parts inside the code
%define copyToSharedMemorySize (@copyEnd - @copyStart)
%define copySecondPartSize (@copyThirdPart - @copySecondPartStart)
%define copyThirdPartSize (@copyEnd - @copyThirdPartStart)
; | Specific Locations |
%define copySecondPartSMOffset (@copySecondPart - @copyStart)
%define copyThirdPartSMOffset (@copyThirdPart - @copyStart)

; | Consts |
%define ORIGINAL_SEGMENT 0x1000
%define MIN_DISTANCE 0x400
; | Macros |
%define GET_WORDS_AMOUNT(BYTES_AMOUNT) ((BYTES_AMOUNT / 2) + (BYTES_AMOUNT % 2))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | the early code that will run before the start (not multiple 5 times) |
; | maximum 3 opcodes |
@eralyCodeStart:
nop
stosw
mov bx, ax
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start

; CODE * 2 + protection - see notes for more information

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | copy the <copy> to the shared memory |
xor di, di
lea si, [bx + @copyStart] ; move si to the location of the code to copy
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)

rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | switch segments |
; set es & ss to 0x1000 (the board)
nop
push es
pop ds
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | specific attack |
; attack using smart bomb
xchg bx, sp
mov ax, 0xD4FF
mov dx, 0xCCCC
int 0x87
xchg bx, sp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | set the first attack location + the sp location |
; set the low byte of al to <attackLowerByteLocation> so when the loop overwrite itself it will be in the location of the a writing (MOVSW, MOVSB, etc.) opcode
mov byte bl, attackLowerByteLocation
; move the sp(stack pointer) to the location of the call far opcode
lea sp, [bx + firstAttackSpace + 6 + firstAttackAmount]
lea ax, [bx + firstAttackSpace + MIN_DISTANCE - 0x100]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | setup the location of the call far opcode inside the shared memory |
mov bx, sm_call_far_location + 4

; write the first location to the shared memory
mov word [bx], ax

mov word [bx + 0x2], ORIGINAL_SEGMENT
add ax, 7
mov [bx - 4], ax
xor dx, dx
mov dl, 0xFC
nop
mov word [bx - 2], attackSegment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | setup last 'variables' |
mov ax, finalAX
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)
mov si, copyThirdPartSMOffset
mov di, [bx]
dec di
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write the attacking bytes of the first attack to the board
movsw
movsw
movsw
sub di, 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@copyStart:

@copyFirstPart:
  push ax
  call far [bx]
  push ax

@copySecondPart:
  movsw ; write the <rep movsw> (the next line of code)
  rep movsw ; write all the @copySecondPartStart

@copySecondPartStart:
  sub byte [bx + 1], ah ; the size of the next attack

  sub sp, dx
  
  les di, [bx]
  dec di
  mov cl, GET_WORDS_AMOUNT(copySecondPartSize) - 1
  xor si, si
  
  ; write the opcode <call far [bx]> to the next attack location
  movsw
  movsw

  push cx

  dec di
  dec di
  
  call far [bx]
  nop

@copyThirdPart:
  push cx
  sub sp, dx
  call far [bx]
  push cx
  rep movsw
  
  @copyThirdPartStart:

  mov dx, gapSize
  
  sub bx, 4
  mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
  dec sp
  mov si, 7
  rep movsw

@copyEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@end:

; CODE * 2 + protection - see notes for more information
