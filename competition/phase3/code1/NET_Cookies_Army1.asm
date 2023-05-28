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
%define attackLowerByteLocation 0xA7 ; for last part: 0xA7
%define attackSegment 0x0FFB ; the original segment is 0x1000
%define movswOpcode 0xA4
%define segmentSpace ((ORIGINAL_SEGMENT - attackSegment) * 0x10)
%define finalAX (jmpSize + movswOpcode)


; | Specific Sizes |
; for the attack
%define gapSize (_jmp_size - _attack_size)
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
mov word [0x402], 0x5ECC
mov word [0x400], 0xC681
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CODE * 2

jmp @start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

mov si, ax
add ax, @trap
mov word [si], ax
xchg si, ax
mov word [si], ax
xchg si, ax

push cs
push cs
push es

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
; es, ss = 0x1000 (board)
pop ds
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


mov ax, 0x26FF
mov dx, si
mov di, [bp + 0x206]
sub di, 0x30
int 0x86
mov di, [bp + di + 2]
sub di, 0x30
int 0x86

mov word [bp + si - 0x1000], si
mov word [bp + si - 0x1000 - 2], 0x26FF
mov cx, ax
mov ax, 0x5ECC
mov dx, 0xC681
int 0x87


mov bx, 0x26FF
mov cx, si

; writ to the second code, where to jmp to
add si, @secondSurviver
mov word [0x3FE], si
mov word [0x3FC], si

; for attack zombies
;mov ax, 0x5ECC
;mov dx, 0xC681
; for attack anti call far
mov ax, 0xD4FF
mov dx, 0xCCCC
int 0x87


; kill HRZ_Client0100100


mov si, 0x30
mov byte bl, attackLowerByteLocation
lodsw
mov bh, ah

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |set the first attack location + the sp location|
; set the first location for the call far to be at bx with value of (ax - <value>)
 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx - 0x1000 - 1 + MIN_DISTANCE + 6 + firstAttackAmount + 0x8000 - 2]
lea ax, [bx - 0x1000 - 1 + MIN_DISTANCE + MIN_DISTANCE - 0x100 + 0x8000]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;REPNZ SCASW


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup the location of the call far opcode inside the shared memory|
mov bx, sm_call_far_location + 4
jmp skipFirst
@secondSurviver:

mov di, ax
mov ax, 0x1FFF
mov dx, 0xCCCC
int 0x87
mov ax, di

skipFirst:
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
mov cx, 0x7
mov si, 0x19
mov di, [bx]
mov bp, 0x2
dec di ; for the byte before the call far (currently 0x90)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

movsw
movsw
movsw
sub di, 4

call far [bx]
@end:

@trap:

mov ax, 0x9090
mov dx, 0x9090

mov si, [0x]
add si, copy - @trap


mov di, 0xA ; the location in the shared memory for the copy code location
mov cx, (end_of_copy - copy) / 2
rep movsw ; copy all the copy code to the shared memory

mov ax, 0xcccc
mov dx, 0xcccc

; switch segments
push es
push cs
pop es

int 0x87

; set the first location for the call far to be at bx with value of (ax - <value>)
;TODO: check if can change this to one row 
sub ax, 0x200
mov byte al, 0xA3 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 

; write the first location to the shared memory


; switch segments
pop ds

mov [0x2], ax
mov word [0x4], 0x1000

; move the stack segment to the shared memory for the bp register
push cs
pop ss

; put the location in the shared memory that will store the location of the call far opcode
mov bx, 2
mov sp, [bx]

; if you need space:
; inc sp
; inc sp
; if you need run time:
add sp, 2

;mov word [bp + 0x0], 0x1fff

; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
;lea sp, [bp + 0x200]
; move di to the location of the call far opcode + 1
;lea di, [bp + 1]
;mov cl, (end_of_copy - copy) / 2 - 2
mov si, (0xA + copy_opcode - copy)
call near start_running

copy: ; this part of the code will be copy to the shared memory (for re writing)
  rep movsw
start_running:
  sub word [bx], 0x5100 ; the size of the next attack
  sub sp, (0x5100 - 0x500)
  mov di, [bx]
  mov cx, (end_of_copy - copy) / 2 - 2
  ; write the opcode <call far [bx]> to the next attack location
  movsw
  dec di
  ; reset the cl & si for the next copy (cl for the movsw loop; si for the location in the memory of the copy's code)
  mov si, 0xA
  call far [bx]
  ; for the movsw inside the copy
copy_opcode:
  call far [bx]
end_of_copy:
