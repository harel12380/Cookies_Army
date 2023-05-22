; /  survivor 2  / ;
; / unchangeable / ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |                                  defines                                  |

; | Controlled Defines |
%define _jmp_size 0x5100 ; how far away to run after attack
%define _attack_size 0x600 ; how much space to attack
%define _first_attack_amount 0x8000 ; the upper attack amount

; | Spacial Memory Locations |
; sm - shared memory
; st - stack
%define sm_call_far_location 0xB0

; | Spacial Bytes |
%define attackLowerByteLocation 0xA1
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
; | the early code that will run before the start (not multiple 5 times)|
; | maximum 3 opcodes|
; ax
@eralyCodeStart:
nop
mov si, ax
add si, @copyStart
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CODE * 2

jmp @start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | copy the <copy> to the shared memory |
; *** - move si to the location of the code to copy
; reset di
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)

rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stosw
mov bx, ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
; es, ss = 0x1000 (board) 
push es
pop ds
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xchg bx, sp
mov di, [bp + 0x206]
int 0x86

std
mov cx, [0x3FC]
mov word [bp + 0x206], cx
mov cx, 0x26FF
mov ax, 0x5ECC
mov dx, 0xC681
mov di, 0x10000 - 0x40A
int 0x87
cld

mov di, [bp + di]
int 0x86
xchg bx, sp


mov byte [bp + 0x207], 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |set the first attack location + the sp location|
; set the first location for the call far to be at bx with value of (ax - <value>)
mov byte bl, attackLowerByteLocation ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx - 0x1000 - 1 + MIN_DISTANCE + 6 + firstAttackAmount]
lea ax, [bx - 0x1000 - 1 + MIN_DISTANCE + MIN_DISTANCE - 0x100]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup the location of the call far opcode inside the shared memory|
mov bx, sm_call_far_location + 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp [0x3FE]

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
  
@copyThirdPart:
  push cx
  sub sp, dx
  call far [bx]
  push cx
  movsw
  rep movsw
  
  @copyThirdPartStart:

  mov dx, gapSize
  
  sub bl, 4
  mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
  mov si, 7
  sub sp, 2
  rep movsw

@copyEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@end:
