push es
pop ds

lodsw
mov bx, ax

push cs
push cs
pop es
pop ss

lea di, [bx + @end]
mov sp, di

mov ax, 0x52AB
mov dx, 0xABAB

push dx
stosw
@end: