; share the ax with the shared memory
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

; int 0x86 if you want

; get the ax from the shared memory
lodsw

; switch segments
push es
push ds
pop es
pop ds

; write to the start of the code - the location of the trap code location (for the zombies)
mov di, ax
add ax, trap
mov [di], ax


mov di, 0xA ; the location in the shared memory for the copy code location
; move si to the location of the copy code
mov si, ax
sub si, trap-copy
; copy all the copy code to the shared memory
mov cx, (end_of_copy - copy) / 2
rep movsw

; move the stack segment to the shared memory for the bp register
push es
pop ss

mov bx, ax
sub bx, 0x200

push es
pop ds
push cs
pop es

; move the stack segment to the fight zone
push cs
pop ss

mov bp, 2
mov [bp], ax

mov di, [bp + 0x0]
mov word [di], 0x1fff


; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
mov sp, [bp]
add sp, 0x200
; move di to the location of the call far opcode + 1
mov di, bp
inc di


; jmp to the call far to start the infinity loop
call far [bx]



copy: ; this part of the code will be copy to the shared memory
db 0x0 ; the segment for the call far
dw 0x10A5 ; the offset for the call far
rep movsw
sub word [bx], 0x200
mov di, [bx]
inc di
mov cl, (end_of_copy - copy) / 2
mov si, 0xA
;may use bp to call far
mov bp, [bx]
mov word [bp + 0x0], 0x1fff
call far[bx]

; final registers:
; bp - the location for the call far (because it's special register)
; bx - the location of the call far opcode
; cx - the amount of times to do movsw
;
;

end_of_copy:
trap: ; from here there is the code that the zombies will run
