; share the ax with the shared memory (the other player)
lodsw

; fill the ax & dx with cccc so that the second code can change it 
mov ax, 0xcccc
mov dx, 0xcccc

; switch segments
push es
push cs
pop es
pop ds

int 0x87

; int 0x86 goes here if you want

; get the ax from the shared memory
lodsw
mov bx, ax

; set the first location for the call far to be at bx with value of (ax - <value>)
;TODO: check if can change this to one row 
sub ah, 0x500
mov byte al, 0xA1 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 

; write the first location to the shared memory
mov [0x2], ax
mov word [0x4], 0x1000

; switch segments
push es
push ds
pop es
pop ds


; write to the start of the code (bx) - the location of the trap code location (for the zombies)
lea dx, [bx + trap]
mov [bx], dx  


mov di, 0xA ; the location in the shared memory for the copy code location
; move si to the location of the code to copy
lea si, [bx + copy]
; copy all the copy code to the shared memory
mov cx, (end_of_copy - copy) / 2
rep movsw ; copy all the copy code to the shared memory


; switch segments
push es
pop ds
push cs
pop es

; move the stack segment to the shared memory for the bp register
push es
pop ss

; put the location in the shared memory that will store the location of the call far opcode
mov bx, 2
mov bp, [bx]
mov word [bp + 0x0], 0xc401
mov word [bp + 0x2], 0x1fff

; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
lea sp, [bp + 0x104] ;;;;;;;;;;;;;;;;;;;
; move di to the location of the call far opcode + 1
mov di, bp
inc di
mov cl, (end_of_copy - copy) / 2
mov si, 0xA
mov dx, (end_of_copy - copy) - 3
mov ax, 0x104
; jmp to the call far to start the infinity loop
call far [bx]


copy: ; this part of the code will be copy to the shared memory (for re writing)
  rep movsw
  mov cx, (end_of_copy - copy) / 2
  add word [bx], dx; the size of the next attack
  add sp, dx
  sub di, 5
  ; reset the cl & si for the next copy (cl for the movsw loop; si for the location in the memory of the copy's code)
  mov si, cx
  ; for the movsw inside the copy
  add sp, ax
  call far [bx]
  
end_of_copy:


; final registers:
; bp - the location of the call far opcode (because it's special register)
; bx - the location for the call far in shared memory - currently 0x2
; cx - the amount of times to do movsw
; dx - TODO: the amount of space between each attack
; ax - TODO: the amount of space between each call far
; si - the location of the opcodes in the shared memory (should be 0 at each start of attack)

; shared memory locations:
; 0 - sizeof(copy - end_of_copy) >> the opcodes for the instructions at the end of an attack
; 0x100 - 0x103  >> the next location in the war zone to attack (used with the register <BX>) for the first warrier
; 0x104 - 0x107  >> the next location in the war zone to attack (used with the register <BX>) for the second warrier
; 

trap: ; from here there is the code that the zombies will run
