mov bx, ax
sub bx, 0x400
mov si, 0x206
start:
sub bx, 0xf
cmp word [bx], 0xcccc
je start
mov ax, [bx]
mul si
mov di, bx
sub di ,ax
mov word [di - 0x206 + 0x38], 0xcccc
jmp start