; /// survivor 1 /// ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _X_Y = defines for us, shouldn't be used inside the code
; xY = defines for the code
; x_y = defines for memory order
; X_Y = general defines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; defines for us
%define _jmp_size 0x4200
%define _attack_size 0x1000
%define _first_attack_amount 0x4000

; defines for the memory order
; sm - shared memory
; st - stack
%define sm_first_ax_publish_location 0x3FE ; between 0x0 - 0x3FE
%define sm_call_far_location 0xA0

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
  %define copyThirdPartSize (end_of_copy - copy_third_part_start) 
  %define copyFirstPartSize (copy_third_part - copy_first_part_start)
  %define copyToSharedMemorySize (end_of_copy - copy)
  %define copyThirdPartSMOffset (copy_third_part - copy)
  %define copyFirstPartSMOffset (copy_first_part_start - copy)

; general defines
%define ORIGINAL_SEGMENT 0x1000
%define MIN_DISTANCE 0x400
%define GET_WORDS_AMOUNT(BYTES_AMOUNT) ((BYTES_AMOUNT / 2) + (BYTES_AMOUNT % 2))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |send the ax to the second survival|
mov di, sm_first_ax_publish_location
stosw
mov bx, ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start
@start:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |write the location of <@trap>|
; only if attack zombies:
;write to the start of the code (bx) - the location of the @trap code location (for the zombies)
add al, @trap
mov [bx], dx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copy> to the shared memory|
; move si to the location of the code to copy
lea si, [bx + copy_second_part]
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
;TODO: check if can change this to one row 
mov byte bl, attackLowerByteLocation ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx + firstAttackAmount - 1 - MIN_DISTANCE + 6 - segmentSpace]
lea ax, [bx - MIN_DISTANCE - 1 + (gapSize - jmpSize)]
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
;mov dx, gapSize
lea bp, [bx + 1]
mov dx, 0xFC
mov cl, GET_WORDS_AMOUNT(copyThirdPartSize)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov si, copyThirdPartSMOffset
les di, [bx] ; set di & es
movsw
movsw
sub di, 3
;inc byte [bx]


copy: ; this part of the code will be copy to the shared memory (for re writing)
  copy_second_part:
  push ax
  call far [bx]
  push ax

  copy_first_part:
  movsb
  movsw
  rep movsw

  copy_first_part_start:
  sub byte [bx + 1], ah ; the size of the next attack
  ; add di, 0x100
  ; lea sp, [di + bx]
  sub sp, dx
  mov di, [bx]
  dec di
  mov cl, GET_WORDS_AMOUNT(copyFirstPartSize)
  ; write the opcode <call far [bx]> to the next attack location
  xor si, si
  movsw
  movsw
  ; reset the cl & si for the next copy (cl for the movsw loop; si for the location in the memory of the copy's code)

  dec di
  dec di
  
  call far [bx]
  
  copy_third_part:
  sub sp, dx
  call far [bx]
  rep movsw

  copy_third_part_start:
  ; read zombies
  ;
  ;
  ;
  ;


  ; perform copy_first_part
  mov dx, gapSize
  dec sp
  dec sp
  mov si, copyFirstPartSMOffset
  mov cl, GET_WORDS_AMOUNT(copyFirstPartSize)
  inc byte [bx]
  inc byte [bx]
  rep movsw

end_of_copy:

@trap:

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