; / survivor 1 / ;
; / changeable / ;

; TODO delete this defines:
; defines for us
%define _jmp_size 0x4200
%define _attack_size 0x1000
%define _first_attack_amount 0x4000
%define gapSize (_jmp_size - _attack_size)
%define jmpSize (_jmp_size)
%define jmpSizeMSB (jmpSize / 0x100)
%define finalAX (jmpSize + movswOpcode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |defines|

; spacial bits
%define zombiesSearchJmpSize 0x5
%define movswOpcode 0xA5
%define zombiesJmpSize 0x206

; defines for the memory order
; sm - shared memory
; st - stack
%define sm_call_far_location 0xB0
; sizes of parts inside the code
%define secondCodeCopyBytesSize 0x1A ; change this to the last byte that the second code will change
%define copyStartSize (@copyLoop - @copy)
%define copyThirdPartSize (@copy_third_part_end - @copy_third_part_start)
%define copyToSharedMemorySize  (@end_of_copy - @copy)
%define copyToStackSize (@endOfCopyStack - @copyStack)
%define copyFSize (@endOfCopyStack - @copyFStart)

; general defines
%define ORIGINAL_SEGMENT 0x1000
%define MIN_DISTANCE 0x400
%define GET_WORDS_AMOUNT(BYTES_AMOUNT) ((BYTES_AMOUNT / 2) + (BYTES_AMOUNT % 2))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |get the ax of the second surviver|
; TODO add more opcodes
mov bx, ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start
@start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copy> to the shared memory|
mov di, secondCodeCopyBytesSize
; move si to the location of the code to copy
lea si, [bx + @copy]
; copy all the copy code to the shared memory
mov cl, GET_WORDS_AMOUNT(copyToSharedMemorySize)
rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copyStack> to the stack|
push ss
pop es

mov di, 0
; move si to the location of the code to copy
lea si, [bx + @copyStack]
; copy all the copy code to the shared memory
mov cl, GET_WORDS_AMOUNT(copyToStackSize)
rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


push es
pop ds
mov si, 0x3FC
lodsw
push cs
pop es

push ss
pop ds
; the bp will point to the board
push cs
pop ss

; mov byte [0xB5], GET_WORDS_AMOUNT(copyThirdPartSize)
mov bx, sm_call_far_location

mov di, ax
add di, 0x200

mov si, 0

mov bp, di
mov byte [bp], 0xA5
inc di
jmp si

@copy:
  @copyS_third_part:
  sub sp, dx
  call far [bx]
  rep movsw

  @copy_third_part_start:
  ; read zombies
  ;
  ;
  ;
  ;
  mov cx, zombiesJmpSize / zombiesSearchJmpSize
  lea bp, [bp - MIN_DISTANCE - zombiesJmpSize]

  @copy_read_zombies:
  mov ax, [bp]
  cmp word ax, [bp + 0x2]
  je @end_of_read_zombies ; if the current double word is 0xcccc
  cmp ax, 0xcccc
  jne @skipSwap
  add bp, 2
  mov ax, [bp]
  @skipSwap:
  cmp ah, 0xCC
  je @skipLSBSwap
  cmp ah, 0x0
  je @skipLSBSwap
  xchg al, ah
  @skipLSBSwap:
  xor ah, ah
  mov dx, 0x206
  mul dx
  dec dx
  jnz @skipOverflow
  not ax
  @skipOverflow:
  sub bp, ax
  mov di, [bp - 0x206 + 0x40]
  int 0x86
  mov word [bp - 0x206 + 0x38], 0xFF26
  add bp, ax
  @end_of_read_zombies:
  add bp, zombiesSearchJmpSize
  loop @copy_read_zombies

  ; perform copy_first_part
  mov dx, gapSize
  mov ax, finalAX
  dec sp
  dec sp
  mov si, 1
  mov cl, GET_WORDS_AMOUNT(1)
  inc byte [bx]
  inc byte [bx]
  rep movsw

  @copy_third_part_end:
@end_of_copy:

@copyStack:
  movsw
  rep movsw

  @copyFStart:
  mov cl, GET_WORDS_AMOUNT(copyFSize)
  mov ax, 0x50A5
  mov bp, [bx] ; get the location of the first

  @copyLoop:
  xor si, si
  
  ; check if I am under attack
  
  mov dx, [di + 0x]
  cmp dx, [di + 0x]
  jne @escape
  
  ; check if the second survivor is under attack
  
  mov dx, [bp - 0x]
  cmp dx, [bp + 0x]
  je @attack ; if the second survivor is safe
  
  ; protect the second survivor
  mov byte [bp], 0x5A

  ; attack
  @attack:
  push ax
  sub sp, 0xA ; attack with spaces
  push ax

  jmp @copyLoop

  ; run away
  @escape:
  add di, 0x8000
  stosw
  jmp di ;- 2
@endOfCopyStack:


@trap:
