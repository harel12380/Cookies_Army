; share the ax with the shared memory (the other player)
stosw

; in the future this code will not be the second opcode (because of the jmp opcode)
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
sub ax, 0x200
mov byte al, 0xA3 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 

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
  sub word [bx], 0x200 ; the size of the next attack
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

trap: ; from here there is the code that the zombies will run
