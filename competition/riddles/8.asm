mov bx,3050h
mov cx,60h
mov dx,15fh
xor ax,ax
b:
call d
call d
cmp al,dl
jl n
inc bx
sub al,dl
sub dl,2
jl d
n:
cmp al,dl
jge l1
inc bh
add al,dh
add dh,2
l1:
loop b
d:
mov [bx],al
push ax
mov ax,6080h
sub ah,bh
mov bh,ah
mov [bx],cl
mov ax,6100h
sub ax,bx
mov bl,al
pop ax
ret
