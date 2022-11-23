; share the ax with the shared memory (the other player)
stosw

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

; set the first location for the call far to be at bx with value of (ax - <value>)
mov bx, ax
sub bx, 0x200
mov byte bl, 0xA3 ; set the low byte of bx to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 

; write the first location to the shared memory
mov [0x2], bx
mov word [0x4], 0x1000

mov bp, 2

; switch segments
push es
push ds
pop es
pop ds




; write to the start of the code (ax) - the location of the trap code location (for the zombies)
mov di, ax
add ax, trap
mov [di], ax


mov di, 0xA ; the location in the shared memory for the copy code location
; move si to the location of the code to copy
mov si, ax
sub si, trap-copy
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
mov word [bp + 0x0], 0x1fff

; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
mov sp, bp
add sp, 0x200
; move di to the location of the call far opcode + 1
mov di, bp
inc di
mov cl, (end_of_copy - copy) / 2
mov si, 0xA

; jmp to the call far to start the infinity loop
call far [bx]



copy: ; this part of the code will be copy to the shared memory (for re writing)
rep movsw
sub word [bx], 0x200 ; the size of the next attack
sub word sp, 0x100
mov di, [bx]
inc di
; reset the cl & si for the next copy (cl for the movsw loop; si for the location in the memory of the copy's code)
mov cx, (end_of_copy - copy) / 2 + 1 ; change this to the exact number
mov si, 0xA
; write in the game the opcode 1fff
mov bp, [bx]
mov word [bp + 0x0], 0x1fff
call far [bx]

; final registers:
; bp - the location of the call far opcode (because it's special register)
; bx - the location for the call far in shared memory - currently 0x2
; cx - the amount of times to do movsw
;
;

end_of_copy:
trap: ; from here there is the code that the zombies will run
