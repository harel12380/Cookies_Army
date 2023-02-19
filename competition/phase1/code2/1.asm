; / survivor 1 / ;
; / changeable / ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |defines|
%define firstAttackOffset 0x200
%define firstATtackLowerByte 0x5A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NOP
push es
pop ds

push cs
push cs; push es
push cs
pop es

lodsw
mov al, firstATtackLowerByte ; the lower byte for the attack start
xchg bp, ax


pop es
pop ss

lea bp, [bp + firstAttackOffset] ; where the first attack
mov sp, bp
mov di, bp

mov bp, 0xD4FF
mov dx, 0x5355

mov bx, 0xABAB
mov cx, 0x5251

mov ax, 0xABAB ; what I will write foward
;mov di, 0x
;mov si, 0x

@attack:
push bp
push bx
push cx
push dx
call sp

nop
nop
nop
nop

@end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;