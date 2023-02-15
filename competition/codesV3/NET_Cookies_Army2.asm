; /  survivor 2  /;
; / unchangeable /;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _X_Y = defines for us, shouldn't be used inside the code
; xY = defines for the code
; x_y = defines for memory order
; X_Y = general defines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |defines|

; defines for us
%define _jmp_size 0x4200
%define _attack_size 0x1000
%define _first_attack_amount 0x4000

; defines for the memory order
; sm - shared memory
; st - stack
%define sm_call_far_location 0xB0

; defines for the code

  ; calculate sizes of the attacks
  %define gapSize (_jmp_size - _attack_size)
  %define jmpSize (_jmp_size)
  %define jmpSizeMSB (jmpSize / 0x100)
  %define firstAttackAmount _first_attack_amount ; the amount of lines to attack in the first attack - MSB*2 for calculate the steps amount

  ; spacial bits
  %define attackLowerByteLocation 0xA7
  %define attackSegment 0x0FFB ; the original segment is 0x1000
  %define movswOpcode 0xA5
  %define segmentSpace ((ORIGINAL_SEGMENT - attackSegment) * 0x10)
  %define finalAX (jmpSize + movswOpcode)

  ; sizes of parts inside the code
  ; %define copyThirdPartSize (@end_of_copy - @copy_third_part_start) 
  %define copySecondPartSize (@end_of_copy - @copyS_second_part_start)
  %define copyToSharedMemorySize (@end_of_copy - @copy)
  %define copyThirdPartSMOffset (@end_of_copy - @copy)
  %define copyFirstPartSMOffset (@copy_first_part_start - @copy)

; defines for the first survivor
%define locFirstSpacialPush @copy_second_part
%define locSecondSpacialPush @copy_second_part + 0x3

; general defines
%define ORIGINAL_SEGMENT 0x1000
%define MIN_DISTANCE 0x400
%define GET_WORDS_AMOUNT(BYTES_AMOUNT) ((BYTES_AMOUNT / 2) + (BYTES_AMOUNT % 2))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |send the ax to the second survival|
;stosw
;mov bx, ax
mov di, 0x3FE
mov bx, ax
lea si, [bx + @copy] ; for ***
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start
@start:

stosw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |write the location of <@trap>|
; only if attack zombies:
;write to the start of the code (bx) - the location of the @trap code location (for the zombies)
; ***
add al, @trap
mov [bx], ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copy> to the shared memory|
; move si to the location of the code to copy
xor di, di
; copy all the copy code to the shared memory
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
push es
pop ds ; ds = shared memory
; es, ss = 0x1000 (board)
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |set the first attack location + the sp location|
; set the first location for the call far to be at bx with value of (ax - <value>)
mov byte bl, attackLowerByteLocation ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx - 1 + MIN_DISTANCE + 6 - segmentSpace + firstAttackAmount]
lea ax, [bx - 1 + MIN_DISTANCE + MIN_DISTANCE - 0x100]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup the location of the call far opcode inside the shared memory|
mov bx, sm_call_far_location

; write the first location to the shared memory
mov [bx], ax
mov word [bx + 0x2], attackSegment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup last 'variables'|
mov ax, finalAX
mov dx, gapSize
lea bp, [bx + 1]
mov dx, 0xFC
mov cl, [bx + 5]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov si, copyThirdPartSMOffset
les di, [bx] ; set di & es
movsw
movsw
sub di, 3
;inc byte [bx]

@copy:
  ; S - second surviver
  ; F - first surviver
  @copyS:

  @copyS_first_part:
  push ax
  call far [bx]
  push ax

  @copyS_second_part:
  movsw
  rep movsw

  @copyS_second_part_start:
  sub byte [bx + 1], ah ; the size of the next attack

  sub sp, dx
  mov di, [bx]
  dec di
  mov cl, GET_WORDS_AMOUNT(copySecondPartSize)
  xor si, si
  
  ; write the opcode <call far [bx]> to the next attack location
  movsw
  movsw
  
  dec di
  dec di

  call far [bx]
@end_of_copy:

@trap:

@end_of_trap:
; @trap:
; push ds
; pop ss
; push cs
; pop es

; mov di, ax
; add di, @end_of_trap
; lea sp, [di + 8]
; mov ax, 0x5052
; mov dx, 0xFAEB
; push ax
; push ds
; @end_of_trap:
; final registers - me
; 
; 
; 
; 
; 
; 
; final registers - zombies
;
;
;
;
;
;