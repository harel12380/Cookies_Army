push cs
pop es

mov bx, ax
add ax, trap

mov [bx], ax

mov dx, 0x9090
mov ax, 0xFEEB

mov cx, bx
mov bx, 0x26FF

int 0x87

jmp $

trap:
jmp $