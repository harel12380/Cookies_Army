; / survivor 1 / ;
; / changeable / ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |                                  defines                                  |

; | Controlled Defines |
%define _jmp_size 0x5100 ; how far away to run after attack
%define _attack_size 0x600 ; how much space to attack
%define _first_attack_amount 0x8000 ; the upper attack amount

; | Spacial Memory Locations |
; sm - shared memory
; st - stack
%define sm_call_far_location 0xC0

; | Spacial Bytes |
%define attackLowerByteLocation 0xA1 ; for last part: 0xA7
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


; REPNZ SCASW
; if possible do 0x87 -> 0xFF1FCCCC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | the early code that will run before the start (not multiple 5 times)|
; | maximum 3 opcodes|
; ax
@eralyCodeStart:
nop
mov si, ax
add [si + @antiCallFarTrap + 1], ax ; write to  @antiCallFarTrap the location of AX
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CODE * 2

jmp @start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

lea ax, [si + @antiCallFarTrap]
mov word [si], ax ; write to the start of the code -> the trap location

mov word [0x10000 - 0x402], 0x5ECC
mov word [0x10000 - 0x400], 0xC681

push es

mov bx, [0x400]
mov word [bx + 0x110], 0x26FF
mov word [bx + 0x112], si
sub word [si], (@antiCallFarTrap - @OST_Karamba)
nop
pop ds


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
; es, ss = 0x1000 (board)
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


add word [bp + si], (@antiCallFarTrap - @OST_Karamba)
mov ax, 0x26FF
mov dx, si
mov di, [bp + 0x206]
sub di, 0x30
int 0x86
mov di, [bp + di + 2]
sub di, 0x30
int 0x86


; writ to the second code, where to jmp to
add si, @secondSurviver
mov word [0x3FE], si
add si, (@antiCallFarTrap - @secondSurviver)
mov word [0x3FC], si


mov bx, ax
mov cx, dx
; for attack zombies
;mov ax, 0x5ECC
;mov dx, 0xC681
; for attack anti call far
mov ax, 0xD4FF
mov dx, 0xCCCC
int 0x87

; kill HRZ_Client0100100


mov si, 0x34
mov byte bl, attackLowerByteLocation
lodsw
mov bh, ah
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |set the first attack location + the sp location|
; set the first location for the call far to be at bx with value of (ax - <value>)
 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx - 0x1000 - 1 + MIN_DISTANCE + 6 + firstAttackAmount + 0x8000]
lea ax, [bx - 0x1000 - 1 + MIN_DISTANCE + MIN_DISTANCE - 0x100 + 0x8000]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;REPNZ SCASW


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup the location of the call far opcode inside the shared memory|
mov bx, sm_call_far_location + 4

@secondSurviver:

; write the first location to the shared memory
mov word [bx], ax
mov word [bx + 0x2], cs

add ax, 8
mov word [bx - 2], attackSegment
mov [bx - 4], ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup last 'variables'|
mov ax, finalAX
mov dx, 0xFC
mov cx, 0x8
mov si, 0x1B
mov di, [bx]
dec di
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec si
movsw
movsw
movsw
sub di, 2

call far [bx]
@end:

@trap:
  push cs
  pop es
  mov ax, 0x1FFF
  mov dx, 0xCCCC
  int 0x87
@endOfTrap:

@locationsToAttack:

dw 0x5ECC
db 0x90
dw 0xC681

dw 0x5ECC
db 0x90
dw 0xC681

; attack anti call far
dw 0xD4FF
db 0x90
dw 0xCCCC
; attack OST_Karamba (and any other basic call far)
dw 0x1FFF
db 0x90
dw 0xCCCC

dw 0x5ECC
db 0x90
dw 0xC681


@OST_Karamba:
  mov word [bx + 0xBF], 0xCCCC

@antiCallFarTrap:
  mov si, @antiCallFarTrap
  mov ax, [si - (@antiCallFarTrap - @locationsToAttack)]
  mov dx, [si - (@antiCallFarTrap - @locationsToAttack) + 3]
  add word [si + 4], 5 ; get to the next attack spot
  
  mov word [0x206], si
  mov cx, 0x26FF

  push cs
  pop es
  mov di, sp
  add di, 0x400

  int 0x87

  jmp $
@endOfAntiCallFarTrap: