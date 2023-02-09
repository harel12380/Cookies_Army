push ds
pop es

mov cx, 0xff
label:
stosw
add di, 0xFF
loop label