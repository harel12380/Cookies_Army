; /// survivor 1 /// ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |defines|

; defines for the memory order
; sm - shared memory
; st - stack
%define sm_call_far_location 0xA0

; sizes of parts inside the code
%define copySize (@end_of_copy - @copy)
%define copyStartSize (@copyLoop - @copy)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |get the ax of the second surviver|
push es
pop ds
lodsw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

jmp @start
@start:

mov bx, sm_call_far_location

@copy:
  movsw
  rep movsw
  mov cl, 
  
  mov bp, [bx]

  @copyLoop:
  xor si, si
  
  ; check if I am under attack
  
  mov ax, [bp - 0x]
  cmp ax, [bp + 0x]
  jne @escape
  
  ; check if the second survivor is under attack
  
  ; attack

  loop @copyLoop

  ; once in a while

  ; run away
  @escape:
  mov cl, 
  mov di, 
  jmp di - 2

@end_of_copy:


@trap:
