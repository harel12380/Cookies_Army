; /  survivor 2  / ;
; / unchangeable / ;
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
; | the early code that will run before the start (not multiple 5 times)|
; | maximum 3 opcodes|
; ax
@eralyCodeStart:
nop
stosw
mov bx, ax
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CODE * 2

jmp @start

db 0xCC
db 0xCC
db 0xCC
xor di, di
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw
push es
pop ds
push cs
push cs
pop es
pop ss
mov word [bx], ax

add ax, 7
mov [bx - 4], ax
mov ax, finalAX

mov dx, 0xFC
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)
mov si, copyThirdPartSMOffset
mov di, [bx]
dec di
movsw
movsw
movsw

call far [bx]
nop
sub di, 4
push ax
push ax
movsw ; write the <rep movsw> (the next line of code)
rep movsw ; write all the @copySecondPartStart
sub sp, dx

les di, [bx]
dec di
mov cl, GET_WORDS_AMOUNT(copySecondPartSize) - 1
xor si, si
movsw
movsw
push cx
dec di
dec di
call far [bx]
push cx
sub sp, dx
call far [bx]
push cx


rep movsw
mov dx, gapSize
sub bx, 4
mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
mov si, 7
rep movsw

db 0xCC
db 0xCC
db 0xCC
nop
xor di, di
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw
push es
pop ds
push cs
push cs
pop es
pop ss
mov word [bx], ax

add ax, 7
mov [bx - 4], ax
mov ax, finalAX
mov dx, 0xFC
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)
mov si, copyThirdPartSMOffset
mov di, [bx]
dec di
movsw
movsw
movsw
sub di, 4
push ax
call far [bx]
push ax
movsw ; write the <rep movsw> (the next line of code)

rep movsw ; write all the @copySecondPartStart
nop
nop
sub sp, dx

les di, [bx]
dec di
mov cl, GET_WORDS_AMOUNT(copySecondPartSize) - 1
xor si, si
movsw
movsw
push cx
dec di
dec di

call far [bx]
push cx
sub sp, dx
call far [bx]
push cx
rep movsw
mov dx, gapSize
sub bx, 4
mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
dec sp
mov si, 7
rep movsw


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | copy the <copy> to the shared memory |
; *** - move si to the location of the code to copy
; reset di
xor di, di
lea si, [bx + @copyStart] ; for ***
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)

rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
; es, ss = 0x1000 (board) 
nop
push es
pop ds
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xchg bx, sp
mov ax, 0xD4FF
mov dx, 0xCCCC

int 0x87
xchg bx, sp

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
; |setup last 'variables'|
mov ax, finalAX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)

mov si, copyThirdPartSMOffset


mov di, [bx]
;les di, [bx] ; set di & es
dec di
movsw
movsw
movsw
sub di, 4

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

db 0xCC
db 0xCC
db 0xCC
xor di, di
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw
push es
pop ds
push cs
push cs
pop es
pop ss
mov word [bx], ax

add ax, 7


mov [bx - 4], ax


mov ax, finalAX
nop
mov dx, 0xFC
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)
mov si, copyThirdPartSMOffset
mov di, [bx]
dec di
movsw
movsw
movsw
sub di, 4
push ax
call far [bx]
push ax
movsw ; write the <rep movsw> (the next line of code)
rep movsw ; write all the @copySecondPartStart
sub sp, dx

les di, [bx]
dec di
mov cl, GET_WORDS_AMOUNT(copySecondPartSize) - 1
xor si, si
movsw
movsw
push cx
dec di
dec di
call far [bx]
push cx

sub sp, dx
call far [bx]

push cx
rep movsw
nop
mov dx, gapSize
sub bx, 4
mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
dec sp
mov si, 7
rep movsw
db 0xCC
db 0xCC
db 0xCC
xor di, di
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw
push es
pop ds
push cs
push cs
pop es
pop ss

mov word [bx], ax

add ax, 7
mov [bx - 4], ax
mov ax, finalAX
mov dx, 0xFC
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)

mov si, copyThirdPartSMOffset
nop
nop
mov di, [bx]
dec di
movsw
movsw
movsw
sub di, 4
push ax
call far [bx]
push ax
movsw ; write the <rep movsw> (the next line of code)
rep movsw ; write all the @copySecondPartStart
sub sp, dx

les di, [bx]
dec di
mov cl, GET_WORDS_AMOUNT(copySecondPartSize) - 1
xor si, si
movsw
movsw
push cx
dec di
dec di
call far [bx]
push cx
sub sp, dx
call far [bx]
push cx
rep movsw
mov dx, gapSize
mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
nop
nop
nop
sub bx, 4
dec sp
mov si, 7
rep movsw

@end:
