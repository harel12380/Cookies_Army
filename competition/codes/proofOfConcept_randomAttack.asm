push cs
push es
pop ds
pop es
lodsw
push cs
pop ss

sub ax, 0x500
mov al, 0xa3
mov bp, ax

a:

add bp, 0x10
mov bx, [bp]
mov dx, cx
sub dx, word [bp + 2]
mov ax, 0x10
mul dx
sub bl, al
mov di, bx
sub di, 0x2
stosw










jmp a