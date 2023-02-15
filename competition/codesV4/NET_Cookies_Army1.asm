; / survivor 1 / ;
; / changeable / ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |defines|

%define secondCodeMaxSM 0x28

%define copyToStackSize (@copyStackEnd - @copyStackStart)
%define SharedMemoryRepSize (@copyLoop - @copyFStart)

; general defines
%define ORIGINAL_SEGMENT 0x1000
%define MIN_DISTANCE 0x400
%define GET_WORDS_AMOUNT(BYTES_AMOUNT) ((BYTES_AMOUNT / 2) + (BYTES_AMOUNT % 2))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | the early code that will run before the start (not multiple 5 times)|
; | maximum 3 opcodes|
@eralyCodeStart:
mov bx, ax
lodsw
@eralyCodeEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copyStack> to the stack|
mov di, 0x200
; move si to the location of the code to copy
lea si, [bx + @copyStackStart]
; copy all the copy code to the shared memory
mov cl, GET_WORDS_AMOUNT(copyToStackSize)
rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add word [bx + @zombiesAreaLive], bx

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | Switch Segments |
; CS - 1000
; DS - SS
; SS - 1000
; ES - 1000
push es
pop ds
push cs
pop es
push cs
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



mov di, ax
add bx, (@attackZombies + 0x50)
mov word [0x3FE], bx ; write to second player, where to jmp to

mov si, ((0x206 / 2) + secondCodeMaxSM)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; | attack zombies |
@attackZombies:
  mov cl, (0x206 / 2 / 4)
  dw 0xC581 ; add bp, (0x0000 - secondCodeMaxSM)
  @zombiesAreaLive:
  dw 0x0

  
  @readZombies:

    mov di, si
    
  loop @readZombies


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@copyStart:

@copyEnd:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@copyStackStart:
  movsw
  rep movsw

  @copyFStart:
  
  mov cl, 0x30
  @getEnergy:
  wait
  wait
  loop @getEnergy

  ; setup the next attack
  mov cl, GET_WORDS_AMOUNT(SharedMemoryRepSize)
  mov ax, 0x50A5
  mov bp, [bx] ; get the location of the first


  
  @copyLoop:
  movsw
  movsw
  xor si, si
  
  ; check if I am under attack
  movsw
  movsw
  mov di, [bx + 0x]
  movsw
  movsw
  cmp di, [bx + 0x]
  movsw
  movsw
  jne @escape

  ; check if the second survivor is under attack
  movsw
  movsw
  mov di, [bp - 0x]
  movsw
  movsw
  cmp di, [bp + 0x]
  je @attack ; if the second survivor is safe
  movsw
  movsw
  ; protect the second survivor
  mov byte [bp], 0x5A
  movsw
  movsw
  ; attack
  @attack:
  push ax
  movsw
  movsw
  sub sp, 0xA ; attack with spaces
  movsw
  movsw
  push ax
  movsw
  movsw
  mov si, 0x200
  jmp @copyLoop

  ; run away
  @escape:
  movsw
  movsw
  int 0x86 ; try to attack the surviver who change [bx]
  movsw
  movsw
  movsw
  movsw
  add di, 0x8000
  stosw
  jmp di ;- 2
@copyStackEnd:

@end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;